"""
RAGFlow External Document Loader Adapter for OpenWebUI.

Converts OpenWebUI external document loader PUT /process requests
to RAGFlow document upload API.
"""

import os
import tempfile
import time
from urllib.parse import unquote

import httpx
from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.responses import JSONResponse

app = FastAPI(title="RAGFlow Adapter", version="1.0.0")

RAGFLOW_BASE_URL = os.getenv("RAGFLOW_BASE_URL", "http://localhost:19090")
RAGFLOW_API_KEY = os.getenv("RAGFLOW_API_KEY", "")
RAGFLOW_DATASET_ID = os.getenv("RAGFLOW_DATASET_ID", "")
POLL_INTERVAL = int(os.getenv("POLL_INTERVAL", "5"))
MAX_POLL_ATTEMPTS = int(os.getenv("MAX_POLL_ATTEMPTS", "120"))


def get_headers():
    return {"Authorization": f"Bearer {RAGFLOW_API_KEY}"}


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.put("/process")
async def process_document(
    request: Request,
    content_type: str = Header(None),
    x_filename: str = Header(None, alias="X-Filename"),
    authorization: str = Header(None),
):
    """
    Process document through RAGFlow.

    OpenWebUI sends:
    - PUT /process
    - Body: raw file bytes
    - Headers: Content-Type, X-Filename, Authorization

    Returns:
    - JSON with page_content and metadata
    """
    if not RAGFLOW_API_KEY:
        raise HTTPException(status_code=500, detail="RAGFLOW_API_KEY not configured")

    if not RAGFLOW_DATASET_ID:
        raise HTTPException(status_code=500, detail="RAGFLOW_DATASET_ID not configured")

    # Get file content
    file_bytes = await request.body()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="No file content")

    # Get filename
    filename = "document"
    if x_filename:
        filename = unquote(x_filename)

    # Create temp file
    suffix = ""
    if "." in filename:
        suffix = "." + filename.rsplit(".", 1)[-1]

    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(file_bytes)
        tmp_path = tmp.name

    try:
        async with httpx.AsyncClient(timeout=300.0) as client:
            # 1. Upload document to RAGFlow
            upload_url = f"{RAGFLOW_BASE_URL}/api/v1/datasets/{RAGFLOW_DATASET_ID}/documents"

            with open(tmp_path, "rb") as f:
                files = {"file": (filename, f, content_type or "application/octet-stream")}
                resp = await client.post(
                    upload_url,
                    files=files,
                    headers=get_headers(),
                )

            if resp.status_code != 200:
                raise HTTPException(
                    status_code=resp.status_code, detail=f"RAGFlow upload failed: {resp.text}"
                )

            upload_data = resp.json()
            if upload_data.get("code") != 0:
                raise HTTPException(
                    status_code=500, detail=f"RAGFlow upload error: {upload_data.get('message')}"
                )

            # Get document ID from response
            docs = upload_data.get("data", [])
            if not docs:
                raise HTTPException(status_code=500, detail="No document ID returned")

            doc_id = docs[0].get("id")

            # 2. Start parsing
            parse_url = (
                f"{RAGFLOW_BASE_URL}/api/v1/datasets/{RAGFLOW_DATASET_ID}/documents/{doc_id}/run"
            )
            resp = await client.post(parse_url, headers=get_headers())

            # 3. Wait for parsing to complete
            status_url = f"{RAGFLOW_BASE_URL}/api/v1/datasets/{RAGFLOW_DATASET_ID}/documents"

            for _ in range(MAX_POLL_ATTEMPTS):
                resp = await client.get(
                    status_url,
                    params={"id": doc_id},
                    headers=get_headers(),
                )

                if resp.status_code == 200:
                    data = resp.json()
                    docs_data = data.get("data", {}).get("docs", [])
                    if docs_data:
                        doc = docs_data[0]
                        run_status = doc.get("run", "")
                        progress = doc.get("progress", 0)

                        if run_status == "DONE" or progress >= 1.0:
                            break
                        elif run_status in ("FAIL", "CANCEL"):
                            raise HTTPException(
                                status_code=500,
                                detail=f"Parsing failed: {doc.get('progress_msg', '')}",
                            )

                time.sleep(POLL_INTERVAL)
            else:
                raise HTTPException(status_code=504, detail="Parsing timeout")

            # 4. Get chunks/content
            chunks_url = (
                f"{RAGFLOW_BASE_URL}/api/v1/datasets/{RAGFLOW_DATASET_ID}/documents/{doc_id}/chunks"
            )
            resp = await client.get(chunks_url, headers=get_headers())

            if resp.status_code != 200:
                raise HTTPException(
                    status_code=resp.status_code, detail=f"Failed to get chunks: {resp.text}"
                )

            chunks_data = resp.json()
            chunks = chunks_data.get("data", {}).get("chunks", [])

            # Combine chunks into page_content
            page_content = "\n\n".join(chunk.get("content", "") for chunk in chunks)

            return JSONResponse(
                {
                    "page_content": page_content,
                    "metadata": {
                        "source": filename,
                        "ragflow_doc_id": doc_id,
                        "ragflow_dataset_id": RAGFLOW_DATASET_ID,
                        "chunk_count": len(chunks),
                    },
                }
            )

    finally:
        # Cleanup temp file
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8090)  # noqa: S104 - Docker container
