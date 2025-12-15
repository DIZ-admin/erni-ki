"""
RAGFlow External Document Loader Adapter for OpenWebUI.

Converts OpenWebUI external document loader PUT /process requests
to RAGFlow document upload API.
"""

import asyncio
import logging
import os
import secrets
import tempfile
import time
from urllib.parse import unquote

import aiofiles  # type: ignore[import-untyped]
import httpx
from fastapi import FastAPI, Header, HTTPException, Request, status
from fastapi.responses import JSONResponse

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","message":"%(message)s"}',
)
logger = logging.getLogger(__name__)

app = FastAPI(title="RAGFlow Adapter", version="1.1.0")

# Configuration from environment
RAGFLOW_BASE_URL = os.getenv("RAGFLOW_BASE_URL", "http://localhost:19090")
RAGFLOW_API_KEY = os.getenv("RAGFLOW_API_KEY", "")
RAGFLOW_DATASET_ID = os.getenv("RAGFLOW_DATASET_ID", "")
POLL_INTERVAL = int(os.getenv("POLL_INTERVAL", "5"))
MAX_POLL_ATTEMPTS = int(os.getenv("MAX_POLL_ATTEMPTS", "60"))  # Reduced default
PROCESS_TIMEOUT = int(os.getenv("PROCESS_TIMEOUT", "300"))  # 5 min absolute timeout
MAX_FILE_SIZE = int(os.getenv("MAX_FILE_SIZE", str(100 * 1024 * 1024)))  # 100MB default
API_KEY = os.getenv("ADAPTER_API_KEY", "")  # Optional auth for this adapter

# Allowed MIME types for document processing
ALLOWED_MIME_TYPES = {
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "application/vnd.ms-powerpoint",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "text/plain",
    "text/markdown",
    "text/csv",
    "text/html",
    "application/json",
    "application/octet-stream",  # Fallback
}


def get_ragflow_headers() -> dict[str, str]:
    """Get headers for RAGFlow API requests."""
    return {"Authorization": f"Bearer {RAGFLOW_API_KEY}"}


def verify_api_key(authorization: str | None) -> None:
    """
    Verify the incoming API key if ADAPTER_API_KEY is configured.

    Raises HTTPException 401 if key is missing or invalid.
    """
    if not API_KEY:
        # No auth configured - allow all (internal network only)
        return

    if not authorization:
        logger.warning("auth_failed: missing authorization header")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Support both "Bearer <token>" and raw token
    token = authorization
    if authorization.lower().startswith("bearer "):
        token = authorization[7:]

    # Constant-time comparison to prevent timing attacks
    if not secrets.compare_digest(token, API_KEY):
        logger.warning("auth_failed: invalid api key")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
            headers={"WWW-Authenticate": "Bearer"},
        )


def validate_content_type(content_type: str | None) -> str:
    """
    Validate and normalize content type.

    Returns normalized MIME type or raises HTTPException.
    """
    if not content_type:
        return "application/octet-stream"

    # Extract base MIME type (remove charset etc.)
    mime_type = content_type.split(";")[0].strip().lower()

    if mime_type not in ALLOWED_MIME_TYPES:
        logger.warning(f"invalid_content_type: {mime_type}")
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported content type: {mime_type}",
        )

    return mime_type


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "ok", "version": "1.1.0"}


@app.put("/process")
async def process_document(
    request: Request,
    content_type: str | None = Header(None),
    x_filename: str | None = Header(None, alias="X-Filename"),
    authorization: str | None = Header(None),
    content_length: int | None = Header(None, alias="Content-Length"),
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
    request_id = secrets.token_hex(8)
    start_time = time.monotonic()

    # 1. Verify authorization
    verify_api_key(authorization)

    # 2. Check configuration
    if not RAGFLOW_API_KEY:
        logger.error(f"[{request_id}] config_error: RAGFLOW_API_KEY not configured")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="RAGFLOW_API_KEY not configured",
        )

    if not RAGFLOW_DATASET_ID:
        logger.error(f"[{request_id}] config_error: RAGFLOW_DATASET_ID not configured")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="RAGFLOW_DATASET_ID not configured",
        )

    # 3. Validate content type
    mime_type = validate_content_type(content_type)

    # 4. Check content length before reading
    if content_length is not None and content_length > MAX_FILE_SIZE:
        logger.warning(
            f"[{request_id}] file_too_large: {content_length} bytes (max: {MAX_FILE_SIZE})"
        )
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File too large. Maximum size: {MAX_FILE_SIZE // (1024 * 1024)}MB",
        )

    # 5. Read file content with size limit
    file_bytes = b""
    async for chunk in request.stream():
        file_bytes += chunk
        if len(file_bytes) > MAX_FILE_SIZE:
            logger.warning(f"[{request_id}] file_too_large: exceeded {MAX_FILE_SIZE} bytes")
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File too large. Maximum size: {MAX_FILE_SIZE // (1024 * 1024)}MB",
            )

    if not file_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No file content",
        )

    # 6. Get filename
    filename = "document"
    if x_filename:
        filename = unquote(x_filename)

    logger.info(
        f"[{request_id}] process_start: filename={filename}, "
        f"size={len(file_bytes)}, mime={mime_type}"
    )

    # 7. Create temp file
    suffix = ""
    if "." in filename:
        suffix = "." + filename.rsplit(".", 1)[-1]

    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(file_bytes)
            tmp_path = tmp.name

        # Process with absolute timeout
        result = await asyncio.wait_for(
            _process_with_ragflow(request_id, tmp_path, filename, mime_type),
            timeout=PROCESS_TIMEOUT,
        )

        elapsed = time.monotonic() - start_time
        logger.info(
            f"[{request_id}] process_complete: chunks={result['metadata']['chunk_count']}, "
            f"elapsed={elapsed:.2f}s"
        )

        return JSONResponse(result)

    except TimeoutError:
        elapsed = time.monotonic() - start_time
        logger.error(f"[{request_id}] process_timeout: elapsed={elapsed:.2f}s")
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail=f"Processing timeout after {PROCESS_TIMEOUT}s",
        ) from None

    finally:
        # Cleanup temp file
        if tmp_path and os.path.exists(tmp_path):
            os.unlink(tmp_path)


async def _process_with_ragflow(
    request_id: str,
    tmp_path: str,
    filename: str,
    mime_type: str,
) -> dict:
    """
    Internal function to process document through RAGFlow API.

    Handles upload, parsing, polling, and chunk retrieval.
    """
    async with httpx.AsyncClient(timeout=60.0) as client:
        # 1. Upload document to RAGFlow
        upload_url = f"{RAGFLOW_BASE_URL}/api/v1/datasets/{RAGFLOW_DATASET_ID}/documents"

        logger.info(f"[{request_id}] ragflow_upload: url={upload_url}")

        async with aiofiles.open(tmp_path, "rb") as f:
            content = await f.read()
            files = {"file": (filename, content, mime_type)}
            resp = await client.post(
                upload_url,
                files=files,
                headers=get_ragflow_headers(),
            )

        if resp.status_code != 200:
            logger.error(
                f"[{request_id}] ragflow_upload_failed: "
                f"status={resp.status_code}, response={resp.text[:500]}"
            )
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"RAGFlow upload failed: {resp.status_code}",
            )

        upload_data = resp.json()
        if upload_data.get("code") != 0:
            error_msg = upload_data.get("message", "Unknown error")
            logger.error(f"[{request_id}] ragflow_upload_error: {error_msg}")
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"RAGFlow upload error: {error_msg}",
            )

        # Get document ID from response
        docs = upload_data.get("data", [])
        if not docs:
            logger.error(f"[{request_id}] ragflow_no_doc_id")
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="No document ID returned from RAGFlow",
            )

        doc_id = docs[0].get("id")
        logger.info(f"[{request_id}] ragflow_uploaded: doc_id={doc_id}")

        # 2. Start parsing
        parse_url = (
            f"{RAGFLOW_BASE_URL}/api/v1/datasets/{RAGFLOW_DATASET_ID}/documents/{doc_id}/run"
        )
        resp = await client.post(parse_url, headers=get_ragflow_headers())
        logger.info(f"[{request_id}] ragflow_parse_started: doc_id={doc_id}")

        # 3. Wait for parsing to complete (non-blocking)
        status_url = f"{RAGFLOW_BASE_URL}/api/v1/datasets/{RAGFLOW_DATASET_ID}/documents"

        for attempt in range(MAX_POLL_ATTEMPTS):
            resp = await client.get(
                status_url,
                params={"id": doc_id},
                headers=get_ragflow_headers(),
            )

            if resp.status_code == 200:
                data = resp.json()
                docs_data = data.get("data", {}).get("docs", [])
                if docs_data:
                    doc = docs_data[0]
                    run_status = doc.get("run", "")
                    progress = doc.get("progress", 0)

                    if run_status == "DONE" or progress >= 1.0:
                        logger.info(
                            f"[{request_id}] ragflow_parse_complete: "
                            f"doc_id={doc_id}, attempts={attempt + 1}"
                        )
                        break

                    if run_status in ("FAIL", "CANCEL"):
                        error_msg = doc.get("progress_msg", "Unknown error")
                        logger.error(
                            f"[{request_id}] ragflow_parse_failed: "
                            f"status={run_status}, msg={error_msg}"
                        )
                        raise HTTPException(
                            status_code=status.HTTP_502_BAD_GATEWAY,
                            detail=f"RAGFlow parsing failed: {error_msg}",
                        )

            # Non-blocking sleep
            await asyncio.sleep(POLL_INTERVAL)
        else:
            logger.error(
                f"[{request_id}] ragflow_parse_timeout: "
                f"doc_id={doc_id}, attempts={MAX_POLL_ATTEMPTS}"
            )
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail="RAGFlow parsing timeout",
            )

        # 4. Get chunks/content
        chunks_url = (
            f"{RAGFLOW_BASE_URL}/api/v1/datasets/{RAGFLOW_DATASET_ID}/documents/{doc_id}/chunks"
        )
        resp = await client.get(chunks_url, headers=get_ragflow_headers())

        if resp.status_code != 200:
            logger.error(
                f"[{request_id}] ragflow_chunks_failed: "
                f"status={resp.status_code}, response={resp.text[:500]}"
            )
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Failed to get chunks: {resp.status_code}",
            )

        chunks_data = resp.json()
        chunks = chunks_data.get("data", {}).get("chunks", [])

        # Combine chunks into page_content
        page_content = "\n\n".join(chunk.get("content", "") for chunk in chunks)

        return {
            "page_content": page_content,
            "metadata": {
                "source": filename,
                "ragflow_doc_id": doc_id,
                "ragflow_dataset_id": RAGFLOW_DATASET_ID,
                "chunk_count": len(chunks),
            },
        }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8090)  # noqa: S104 - Docker container
