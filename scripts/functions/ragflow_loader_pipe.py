"""
Pipe: automatic document ingestion via ragflow-bridge.

Chain: upload_and_parse -> export_md -> upload_md_to_owui_tool.
Uses ragflow-bridge OpenAPI (mcposerver:8000/ragflow-bridge).
"""

import os
from typing import Any

import requests


class Pipe:
    def __init__(self):
        self.type = "pipe"
        self.id = "ragflow_loader"
        self.name = "Ragflow Loader"
        self._base = os.getenv("RAGFLOW_BRIDGE_BASE", "http://mcposerver:8000/ragflow-bridge")
        self._timeout = int(os.getenv("RAGFLOW_BRIDGE_TIMEOUT", "300"))
        # Optional: OWUI token for upload_md_to_owui_tool if not configured on the server
        self._owui_token = os.getenv("OWUI_API_TOKEN", "")

    # ------------------------------------------------------------------ helpers
    def _post(self, path: str, payload: dict[str, Any]) -> dict[str, Any]:
        url = f"{self._base}{path}"
        r = requests.post(url, json=payload, timeout=self._timeout)
        if r.status_code != 200:
            raise RuntimeError(f"{path} failed: {r.status_code} {r.text}")
        data = r.json() or {}
        # ragflow-bridge returns {"markdown": "..."} or {"document_id": "..."} etc.
        return data

    def _upload_and_parse(self, file_path: str, user_id: str | None) -> dict[str, Any]:
        payload = {"file_path": file_path, "user_id": user_id}
        return self._post("/upload_and_parse", payload)

    def _export_md(
        self, dataset_id: str | None, document_id: str | None, user_id: str | None
    ) -> str:
        payload = {
            "dataset_id": dataset_id,
            "document_id": document_id,
            "user_id": user_id,
            "question": "export document content",
        }
        data = self._post("/export_md", payload)
        md = data.get("markdown") or data.get("md") or ""
        if not md:
            raise RuntimeError("export_md returned empty markdown")
        return md

    def _upload_md_to_owui(self, md: str, filename: str) -> dict[str, Any]:
        payload = {
            "md": md,
            "filename": filename,
            "unique_suffix": True,
        }
        if self._owui_token:
            payload["owui_token"] = self._owui_token
        return self._post("/upload_md_to_owui_tool", payload)

    # ------------------------------------------------------------------ main
    def pipe(self, body: dict[str, Any], __user__: dict[str, Any]):
        files: list[dict[str, Any]] = body.get("files") or []
        if not files:
            return "No attached files; skipping ragflow loader."

        user_id = (__user__ or {}).get("id") or (__user__ or {}).get("email")
        results = []

        for f in files:
            path = f.get("path")
            name = f.get("name") or os.path.basename(path or "")
            if not path:
                results.append(f"⚠️ Skipped file without path: {name}")
                continue

            try:
                # 1) upload + parse
                up = self._upload_and_parse(path, user_id)
                dataset_id = up.get("dataset_id")
                document_id = up.get("document_id")

                # 2) export markdown
                md = self._export_md(dataset_id, document_id, user_id)

                # 3) upload md to OWUI for indexing
                md_name = f"{name}.md"
                upload_res = self._upload_md_to_owui(md, md_name)
                owui_path = upload_res.get("path") or upload_res.get("file") or "uploaded"

                results.append(
                    f"✅ {name}: dataset={dataset_id}, doc={document_id}, md={owui_path}"
                )
            except Exception as e:  # noqa: BLE001
                results.append(f"❌ {name}: {e}")

        return "\n".join(results)
