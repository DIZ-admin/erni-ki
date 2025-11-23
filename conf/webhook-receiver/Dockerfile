# ERNI-KI Webhook Receiver Dockerfile
FROM python:3.11-slim

# Metadata
LABEL maintainer="ERNI-KI Team"
LABEL description="Webhook receiver for ERNI-KI monitoring alerts"
LABEL version="1.0.0"

# Working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY webhook-receiver.py .
COPY scripts/ ./scripts/

# Create directories
RUN mkdir -p /app/logs /app/scripts

# Permissions
RUN chmod +x webhook-receiver.py
RUN chmod +x scripts/*.sh 2>/dev/null || true

# Non-root user
RUN useradd -r -s /bin/false webhook && \
    chown -R webhook:webhook /app
USER webhook

# Environment variables
ENV WEBHOOK_PORT=9093
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=production

# Port
EXPOSE 9093

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9093/health || exit 1

# Run
CMD ["python", "webhook-receiver.py"]
