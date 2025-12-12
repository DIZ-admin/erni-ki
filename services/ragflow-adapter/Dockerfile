FROM python:3.12-slim

ENV APP_USER=appuser APP_UID=1000 APP_GID=1000

RUN groupadd --gid "$APP_GID" "$APP_USER" \
    && useradd --uid "$APP_UID" --gid "$APP_GID" --create-home --shell /bin/bash "$APP_USER"

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir fastapi uvicorn httpx python-multipart aiofiles

COPY main.py .

USER $APP_UID:$APP_GID

EXPOSE 8090

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8090"]
