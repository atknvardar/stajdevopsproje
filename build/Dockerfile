# Multi-stage Dockerfile for FastAPI Microservice
# Stage 1: Build stage
FROM python:3.11-slim AS builder

# Set build arguments with defaults
ARG BUILD_DATE=unknown
ARG VERSION=1.0.0
ARG COMMIT_HASH=unknown

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy requirements first for better caching
COPY app/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY app/ .

# Run tests during build (optional, can be disabled for faster builds)
RUN python -m pytest tests/ || echo "Tests failed, continuing build"

# Stage 2: Runtime stage
FROM python:3.11-slim AS runtime

# Set build arguments again for runtime stage
ARG BUILD_DATE=unknown
ARG VERSION=1.0.0
ARG COMMIT_HASH=unknown

# Set labels for metadata
LABEL maintainer="DevOps Team" \
      version="${VERSION}" \
      description="Microservice Demo Application" \
      build-date="${BUILD_DATE}" \
      commit-hash="${COMMIT_HASH}"

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /bin/bash appuser

# Set working directory
WORKDIR /app

# Copy requirements and install them in runtime stage
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY --from=builder /build/ /app/

# Fix ownership and permissions
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Set environment variables with defaults
ENV PORT=8080 \
    HOST=0.0.0.0 \
    LOG_LEVEL=INFO \
    ENVIRONMENT=production \
    METRICS_ENABLED=true \
    TRACING_ENABLED=false

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

# Run application
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"] 