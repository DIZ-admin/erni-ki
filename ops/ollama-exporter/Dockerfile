FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py ./

# Create non-root user
RUN useradd -r -u 1001 -g root appuser
USER appuser

EXPOSE 9778
CMD ["python", "app.py"]
