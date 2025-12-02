"""
Ragflow MCP bridge for erni-ki.

Tools:
- upload_and_parse(file_path, dataset_id?): upload to Ragflow, parse, poll until DONE.
- export_md(dataset_id?, document_id?, question?): fetch chunks via /api/v1/retrieval and
  render markdown with doc/page links.
- upload_md_to_owui(md, filename?, owui_base?, owui_token?): push a markdown file to
  OpenWebUI for embedding.

Defaults are driven by env vars:
- RAGFLOW_BASE_URL (default: http://localhost:19090)
- RAGFLOW_API_KEY (required)
- RAGFLOW_DATASET_ID (default: 3ade126ccb7811f0b6bca21184c8b456)
- OWUI_BASE_URL (default: http://openwebui:8080)
- OWUI_API_TOKEN (optional fallback for upload_md_to_owui)
"""

from __future__ import annotations

import contextlib
import os
import time
from pathlib import Path
from typing import Any

import requests
from mcp.server.fastmcp import FastMCP

# --------------------------- Configuration ---------------------------
DEFAULT_DATASET_ID = os.getenv("RAGFLOW_DATASET_ID", "3ade126ccb7811f0b6bca21184c8b456")
RAGFLOW_BASE_URL = os.getenv("RAGFLOW_BASE_URL", "http://localhost:19090")
RAGFLOW_API_KEY = os.getenv("RAGFLOW_API_KEY", "")

OWUI_BASE_URL = os.getenv("OWUI_BASE_URL", "http://openwebui:8080")
OWUI_API_TOKEN = os.getenv("OWUI_API_TOKEN", "")

# cache for per-user datasets
_USER_DATASET_CACHE: dict[str, str] = {}


def _api_base() -> str:
    base = RAGFLOW_BASE_URL.rstrip("/")
    if not base.endswith("/api") and "/api/" not in base:
        base = base + "/api/v1"
    elif (base.endswith("/api") or "/api/" in base) and not base.rstrip("/").endswith("api/v1"):
        base = base.rstrip("/") + "/v1"
    return base


def _headers() -> dict[str, str]:
    if not RAGFLOW_API_KEY:
        raise RuntimeError("RAGFLOW_API_KEY is not set")
    return {"Authorization": f"Bearer {RAGFLOW_API_KEY}"}


def _get(url: str, **kwargs) -> requests.Response:
    return requests.get(url, headers=_headers(), timeout=30, **kwargs)


def _post(url: str, **kwargs) -> requests.Response:
    headers = kwargs.pop("headers", {})
    merged = {**_headers(), **headers}
    return requests.post(url, headers=merged, timeout=60, **kwargs)


def _normalize_dataset(dataset_id: str | None) -> str:
    return dataset_id or DEFAULT_DATASET_ID


# --------------------------- Dataset helpers ---------------------------
def list_datasets(name: str | None = None) -> list[dict[str, Any]]:
    url = f"{_api_base()}/datasets"
    params = {"page": 1, "page_size": 100}
    if name:
        params["name"] = name
    resp = _get(url, params=params)
    if resp.status_code != 200:
        raise RuntimeError(f"List datasets failed ({resp.status_code}): {resp.text}")
    data = resp.json()
    if data.get("code") != 0:
        raise RuntimeError(f"List datasets error: {data}")
    return data.get("data") or data.get("datasets") or []


def create_dataset(name: str) -> str:
    url = f"{_api_base()}/datasets"
    payload = {"name": name}
    resp = _post(url, json=payload)
    if resp.status_code != 200:
        raise RuntimeError(f"Create dataset failed ({resp.status_code}): {resp.text}")
    data = resp.json()
    if data.get("code") != 0:
        raise RuntimeError(f"Create dataset error: {data}")
    ds_id = (data.get("data") or data).get("id") or data.get("dataset_id")
    if not ds_id:
        raise RuntimeError(f"Create dataset did not return id: {data}")
    return ds_id


def ensure_user_dataset(user_id: str | None, default_dataset: str | None = None) -> str:
    """
    Return dataset id for given user_id.
    If user_id is None -> fallback to default_dataset or DEFAULT_DATASET_ID.
    If dataset not exists, create it with name 'user-{user_id}'.
    """
    if not user_id:
        return default_dataset or DEFAULT_DATASET_ID

    if user_id in _USER_DATASET_CACHE:
        return _USER_DATASET_CACHE[user_id]

    name = f"user-{user_id}"
    # try to find existing
    with contextlib.suppress(Exception):
        existing = list_datasets(name=name)
        for ds in existing:
            if ds.get("name") == name:
                ds_id = ds.get("id") or ds.get("dataset_id")
                if ds_id:
                    _USER_DATASET_CACHE[user_id] = ds_id
                    return ds_id

    ds_id = create_dataset(name)
    _USER_DATASET_CACHE[user_id] = ds_id
    return ds_id


# --------------------------- Helpers ---------------------------
def upload_document(dataset_id: str, file_path: Path) -> dict[str, Any]:
    url = f"{_api_base()}/datasets/{dataset_id}/documents"
    with file_path.open("rb") as f:
        files = {"file": (file_path.name, f)}
        resp = _post(url, files=files)
    if resp.status_code != 200:
        raise RuntimeError(f"Upload failed ({resp.status_code}): {resp.text}")
    data = resp.json()
    if data.get("code") != 0:
        raise RuntimeError(f"Upload error: {data}")
    docs = data.get("data") or []
    if not docs:
        raise RuntimeError("Upload succeeded but no document returned")
    return docs[0]


def trigger_parse(dataset_id: str, doc_id: str) -> None:
    url = f"{_api_base()}/datasets/{dataset_id}/chunks"
    payload = {"document_ids": [doc_id]}
    resp = _post(url, json=payload)
    if resp.status_code != 200:
        raise RuntimeError(f"Parse trigger failed ({resp.status_code}): {resp.text}")
    data = resp.json()
    if data.get("code") not in (0, None):
        raise RuntimeError(f"Parse trigger returned error: {data}")


def fetch_doc_status(dataset_id: str, doc_id: str) -> dict[str, Any]:
    url = f"{_api_base()}/datasets/{dataset_id}/documents"
    resp = _get(url, params={"id": doc_id})
    if resp.status_code != 200:
        raise RuntimeError(f"Status fetch failed ({resp.status_code}): {resp.text}")
    data = resp.json()
    docs = (data.get("data") or {}).get("docs") or data.get("data") or []
    for d in docs:
        if d.get("id") == doc_id:
            return d
    raise RuntimeError(f"Document {doc_id} not found in status response: {data}")


def poll_until_done(
    dataset_id: str, doc_id: str, timeout: int = 180, interval: int = 4
) -> dict[str, Any]:
    deadline = time.time() + timeout
    last = {}
    while time.time() < deadline:
        last = fetch_doc_status(dataset_id, doc_id)
        run = (last.get("run") or "").upper()
        if run in ("DONE", "FINISHED", "SUCCESS"):
            return last
        if run in ("FAILED", "ERROR"):
            raise RuntimeError(f"Parsing failed: {last}")
        time.sleep(interval)
    raise TimeoutError(f"Timed out waiting for document {doc_id} to finish: last={last}")


def retrieval(
    dataset_id: str,
    document_id: str | None,
    question: str,
    page_size: int = 200,
    keyword: bool = True,
    similarity_threshold: float = 0.0,
    vector_similarity_weight: float = 0.1,
) -> dict[str, Any]:
    url = f"{_api_base()}/retrieval"
    payload = {
        "question": question or "export document content",
        "dataset_ids": [dataset_id],
        "document_ids": [document_id] if document_id else [],
        "page": 1,
        "page_size": page_size,
        "highlight": False,
        "keyword": keyword,
        "similarity_threshold": similarity_threshold,
        "vector_similarity_weight": vector_similarity_weight,
    }
    resp = _post(url, json=payload)
    if resp.status_code != 200:
        raise RuntimeError(f"Retrieval failed ({resp.status_code}): {resp.text}")
    data = resp.json()
    if data.get("code") != 0:
        raise RuntimeError(f"Retrieval error: {data}")
    return data


def chunks_to_markdown(chunks: list[dict[str, Any]]) -> str:
    lines = []
    for idx, ch in enumerate(chunks, 1):
        doc_name = ch.get("document_name") or ch.get("doc_name") or "Document"
        doc_id = ch.get("document_id") or ch.get("doc_id") or ""
        page = ch.get("page_no") or ch.get("page") or ch.get("page_number")
        try:
            page = int(page) if page is not None else None
        except Exception:
            page = None
        content = (ch.get("content") or "").strip()
        link = f"{RAGFLOW_BASE_URL.rstrip('/')}/document/{doc_id}"
        if page:
            link = f"{link}#page={page}"
        head = f"### Chunk {idx} — {doc_name}"
        if doc_id:
            head = f"### Chunk {idx} — [{doc_name}]({link})"
        if page:
            head += f" (p.{page})"
        lines.append(head)
        if content:
            lines.append(content)
        else:
            lines.append("_empty chunk_")
        lines.append("")
    return "\n".join(lines).strip()


def upload_md_to_openwebui(
    md: str, filename: str, owui_base: str, owui_token: str
) -> dict[str, Any]:
    url = f"{owui_base.rstrip('/')}/api/v1/files/"
    headers = {}
    if owui_token:
        headers["Authorization"] = f"Bearer {owui_token}"
    files = {"file": (filename, md.encode("utf-8"), "text/markdown")}
    resp = requests.post(url, headers=headers, files=files, timeout=60)
    if resp.status_code not in (200, 201):
        raise RuntimeError(f"OWUI upload failed ({resp.status_code}): {resp.text}")
    return resp.json()


# --------------------------- MCP Server ---------------------------
server = FastMCP(
    name="ragflow-bridge",
    instructions=(
        "Bridge to Ragflow dataset ingestion and export. "
        "Set RAGFLOW_API_KEY/RAGFLOW_BASE_URL/RAGFLOW_DATASET_ID env vars. "
        "upload_and_parse -> parse PDF/doc into dataset; export_md -> get chunks; "
        "upload_md_to_owui -> push markdown back to OpenWebUI."
    ),
)


@server.tool()
def upload_and_parse(
    file_path: str,
    dataset_id: str | None = None,
    user_id: str | None = None,
    wait_seconds: int = 180,
    poll_interval: int = 4,
) -> dict[str, Any]:
    """
    Upload a file to Ragflow dataset, trigger parsing, and wait until DONE.
    """
    ds_id = ensure_user_dataset(user_id, default_dataset=_normalize_dataset(dataset_id))
    path = Path(file_path).expanduser().resolve()
    if not path.exists():
        raise FileNotFoundError(f"{path} not found")
    doc = upload_document(ds_id, path)
    doc_id = doc.get("id")
    trigger_parse(ds_id, doc_id)
    final = poll_until_done(ds_id, doc_id, timeout=wait_seconds, interval=poll_interval)
    return {"dataset_id": ds_id, "document_id": doc_id, "status": final.get("run"), "meta": final}


@server.tool()
def export_md(
    dataset_id: str | None = None,
    document_id: str | None = None,
    user_id: str | None = None,
    question: str = "export document content",
    page_size: int = 200,
    keyword: bool = True,
    similarity_threshold: float = 0.0,
    vector_similarity_weight: float = 0.1,
) -> dict[str, Any]:
    """
    Retrieve chunks from Ragflow and render as Markdown with doc/page links.
    """
    ds_id = ensure_user_dataset(user_id, default_dataset=_normalize_dataset(dataset_id))
    data = retrieval(
        ds_id,
        document_id,
        question,
        page_size=page_size,
        keyword=keyword,
        similarity_threshold=similarity_threshold,
        vector_similarity_weight=vector_similarity_weight,
    )
    chunks = (data.get("data") or {}).get("chunks") or []
    md = chunks_to_markdown(chunks)
    return {"markdown": md, "chunks_count": len(chunks), "raw": data}


@server.tool()
def upload_md_to_owui_tool(
    md: str,
    filename: str = "ragflow-export.md",
    unique_suffix: bool = True,
    owui_base: str | None = None,
    owui_token: str | None = None,
) -> dict[str, Any]:
    """
    Upload a markdown string to OpenWebUI for indexing.
    """
    base = owui_base or OWUI_BASE_URL
    token = owui_token or OWUI_API_TOKEN
    if not token:
        raise RuntimeError("OWUI token is required (set OWUI_API_TOKEN or pass owui_token)")
    if unique_suffix:
        stem, dot, ext = filename.partition(".")
        from uuid import uuid4

        filename = f"{stem}_{uuid4().hex}{dot}{ext}" if dot else f"{stem}_{uuid4().hex}"
    resp = upload_md_to_openwebui(md, filename, base, token)
    return {"uploaded": True, "response": resp}


if __name__ == "__main__":
    server.run()
