# Multi-stage Dockerfile for erni-ki auth service
# Optimized build with dependency caching

# Stage 1: Application Build
FROM golang:1.24.11-alpine3.21 AS builder

# Install necessary build packages
RUN apk add --no-cache \
  git \
  ca-certificates \
  tzdata

# Create user for security
RUN adduser -D -s /bin/sh -u 1001 appuser

# Set working directory
WORKDIR /build

# Copy dependency files for layer caching
COPY go.mod go.sum ./

# Download dependencies (cached if go.mod/go.sum unchanged)
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Run tests (optional); disabled by default to speed up CI build
ARG SKIP_TESTS=true
RUN if [ "$SKIP_TESTS" = "false" ]; then go test -v ./...; fi

# Build application with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
  -ldflags='-w -s -extldflags "-static"' \
  -a -installsuffix cgo \
  -o main .

# Stage 2: Final Image
FROM gcr.io/distroless/static-debian12:nonroot

# Copy certificates for HTTPS requests
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy timezone info
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy compiled application
COPY --from=builder /build/main /app/main

# Distroless image already uses unprivileged nonroot user
# Note: Health checks should be configured at orchestration layer (K8s/Docker Compose)

# Expose port
EXPOSE 9090

# Image metadata
LABEL maintainer="erni-ki-team" \
  version="1.0.0" \
  description="JWT Authentication service for erni-ki project" \
  org.opencontainers.image.source="https://github.com/DIZ-admin/erni-ki" \
  org.opencontainers.image.documentation="https://github.com/DIZ-admin/erni-ki/blob/main/README.md"

# Enforce non-root user (distroless nonroot provides this user)
USER nonroot

# Run application
ENTRYPOINT ["/app/main"]
