# Microservice Application

This directory contains the source code for the RESTful microservice.

## Features

- Health check endpoints (`/healthz`, `/ready`)
- REST API endpoints (`/api/v1/hello`)
- Prometheus metrics exposure (`/metrics`)
- OpenTelemetry tracing support
- Comprehensive unit and integration tests (≥80% coverage)

## Technology Stack

**Option A: Java with Quarkus**
- Lightweight, cloud-native framework
- Built-in health checks and metrics
- Fast startup and low memory footprint

**Option B: Python with FastAPI**
- Modern, fast web framework
- Automatic API documentation
- Built-in validation and serialization

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/healthz` | GET | Liveness probe |
| `/ready` | GET | Readiness probe |
| `/metrics` | GET | Prometheus metrics |
| `/api/v1/hello` | GET | Hello world API |

## Development

```bash
# Install dependencies
make install

# Run tests
make test

# Start development server
make dev

# Build for production
make build
```

## Testing

- Unit tests with mocking
- Integration tests with test containers
- Code coverage reporting
- Static code analysis

## Configuration

Environment variables:
- `PORT`: Application port (default: 8080)
- `LOG_LEVEL`: Logging level (default: INFO)
- `METRICS_ENABLED`: Enable metrics endpoint (default: true) 