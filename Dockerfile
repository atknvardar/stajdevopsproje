FROM python:3.10-slim AS builder

WORKDIR /app

# Copy requirements first for better caching
COPY app/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ .

# Final stage - minimal runtime image
FROM python:3.10-slim

WORKDIR /app

# Install only production dependencies
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    # Create non-root user
    useradd -m -u 1000 -s /bin/bash appuser && \
    # Create necessary directories with proper permissions
    mkdir -p /app/logs /app/tmp && \
    chown -R appuser:appuser /app

# Copy application from builder
COPY --from=builder --chown=appuser:appuser /app .

# Security hardening
RUN apt-get purge -y --auto-remove gcc python3-dev || true && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip && \
    chmod -R 755 /app

# Switch to non-root user
USER appuser

# Use specific port (non-privileged)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8080/healthz').raise_for_status()"

# Run with minimal privileges
CMD ["python", "-u", "main.py"]
