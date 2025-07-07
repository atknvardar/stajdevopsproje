q# 🔧 API Documentation

This document provides comprehensive documentation for the Enterprise DevOps Pipeline microservice API, including endpoint specifications, authentication, examples, and best practices.

## 📋 Table of Contents

- [API Overview](#api-overview)
- [Authentication](#authentication)
- [Health Check Endpoints](#health-check-endpoints)
- [Business Logic Endpoints](#business-logic-endpoints)
- [Metrics Endpoint](#metrics-endpoint)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [SDK and Examples](#sdk-and-examples)

## 🎯 API Overview

### Base Information

- **Base URL**: `http://your-domain.com` (production) or `http://localhost:8080` (development)
- **API Version**: v1
- **Protocol**: HTTP/HTTPS
- **Content Type**: `application/json`
- **OpenAPI Specification**: Available at `/docs` (Swagger UI) and `/redoc` (ReDoc)

### API Characteristics

- **RESTful Design**: Follows REST architectural principles
- **JSON Communication**: All requests and responses use JSON format
- **Stateless**: Each request contains all necessary information
- **Idempotent**: GET, PUT, DELETE operations are idempotent
- **Versioned**: API version specified in URL path
- **Self-Documenting**: Interactive documentation available

### Response Format

All API responses follow a consistent structure:

```json
{
  "message": "Response message",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0",
  "data": {
    // Response data (optional)
  }
}
```

## 🔐 Authentication

### Current Status

The current implementation does not require authentication for demonstration purposes. However, the architecture supports adding authentication mechanisms.

### Future Authentication Options

#### JWT Token Authentication
```http
Authorization: Bearer <jwt-token>
```

#### API Key Authentication
```http
X-API-Key: <api-key>
```

#### Basic Authentication
```http
Authorization: Basic <base64-encoded-credentials>
```

### Security Headers

All responses include security headers:

```http
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
```

## 🏥 Health Check Endpoints

Health check endpoints are used by Kubernetes for liveness and readiness probes.

### Liveness Probe

**Endpoint**: `GET /healthz`

**Purpose**: Indicates whether the application is alive and should receive traffic.

**Request**:
```http
GET /healthz HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Response Codes**:
- `200 OK`: Application is healthy
- `503 Service Unavailable`: Application is unhealthy

**Example cURL**:
```bash
curl -X GET http://localhost:8080/healthz
```

### Readiness Probe

**Endpoint**: `GET /ready`

**Purpose**: Indicates whether the application is ready to handle requests.

**Request**:
```http
GET /ready HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "status": "ready",
  "timestamp": "2024-01-15T10:30:00Z",
  "dependencies": "healthy"
}
```

**Response Codes**:
- `200 OK`: Application is ready
- `503 Service Unavailable`: Application is not ready

**Example cURL**:
```bash
curl -X GET http://localhost:8080/ready
```

## 🚀 Business Logic Endpoints

### Hello API - GET

**Endpoint**: `GET /api/v1/hello`

**Purpose**: Basic greeting endpoint with optional personalization.

**Parameters**:
- `name` (query, optional): Name to include in greeting

**Request**:
```http
GET /api/v1/hello?name=John HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "message": "Hello John from microservice!",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

**Example Requests**:

Without name parameter:
```bash
curl -X GET http://localhost:8080/api/v1/hello
```

Response:
```json
{
  "message": "Hello from microservice!",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

With name parameter:
```bash
curl -X GET "http://localhost:8080/api/v1/hello?name=DevOps%20Engineer"
```

Response:
```json
{
  "message": "Hello DevOps Engineer from microservice!",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

### Hello API - POST

**Endpoint**: `POST /api/v1/hello`

**Purpose**: Greeting endpoint that accepts name in request body.

**Request Body**:
```json
{
  "name": "string"
}
```

**Request**:
```http
POST /api/v1/hello HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "name": "DevOps Team"
}
```

**Response**:
```json
{
  "message": "Hello DevOps Team from microservice!",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

**Example cURL**:
```bash
curl -X POST http://localhost:8080/api/v1/hello \
  -H "Content-Type: application/json" \
  -d '{"name": "DevOps Team"}'
```

**Validation Rules**:
- `name`: String, maximum 100 characters
- Request body must be valid JSON

## 📊 Metrics Endpoint

**Endpoint**: `GET /metrics`

**Purpose**: Prometheus metrics exposition endpoint for monitoring.

**Request**:
```http
GET /metrics HTTP/1.1
Host: localhost:8080
```

**Response Format**: Prometheus text format

**Example Response**:
```text
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",endpoint="/api/v1/hello"} 42

# HELP http_request_duration_seconds HTTP request duration in seconds
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{method="GET",endpoint="/api/v1/hello",le="0.1"} 40
http_request_duration_seconds_bucket{method="GET",endpoint="/api/v1/hello",le="0.5"} 42
http_request_duration_seconds_bucket{method="GET",endpoint="/api/v1/hello",le="+Inf"} 42
http_request_duration_seconds_sum{method="GET",endpoint="/api/v1/hello"} 2.5
http_request_duration_seconds_count{method="GET",endpoint="/api/v1/hello"} 42

# HELP app_info Application information
# TYPE app_info gauge
app_info{version="1.0.0"} 1

# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds
# TYPE process_cpu_seconds_total counter
process_cpu_seconds_total 0.15
```

**Available Metrics**:
- `http_requests_total`: Total HTTP requests by method and endpoint
- `http_request_duration_seconds`: Request duration histogram
- `app_info`: Application metadata
- `process_*`: Process-level metrics (CPU, memory, etc.)

**Example cURL**:
```bash
curl -X GET http://localhost:8080/metrics
```

## ❌ Error Handling

### Error Response Format

All error responses follow a consistent structure:

```json
{
  "detail": "Error description",
  "type": "error_type",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### HTTP Status Codes

| Status Code | Description | Example |
|-------------|-------------|---------|
| `200 OK` | Successful request | Normal API responses |
| `400 Bad Request` | Invalid request format | Malformed JSON |
| `404 Not Found` | Endpoint not found | Invalid URL path |
| `405 Method Not Allowed` | HTTP method not supported | POST to GET-only endpoint |
| `422 Unprocessable Entity` | Validation error | Invalid input data |
| `500 Internal Server Error` | Server error | Unexpected application error |
| `503 Service Unavailable` | Service unhealthy | During startup or shutdown |

### Error Examples

#### 404 Not Found
```http
GET /api/v1/nonexistent HTTP/1.1
```

Response:
```json
{
  "detail": "Not Found"
}
```

#### 405 Method Not Allowed
```http
DELETE /api/v1/hello HTTP/1.1
```

Response:
```json
{
  "detail": "Method Not Allowed"
}
```

#### 422 Validation Error
```http
POST /api/v1/hello HTTP/1.1
Content-Type: application/json

{
  "name": ""
}
```

Response:
```json
{
  "detail": [
    {
      "loc": ["body", "name"],
      "msg": "ensure this value has at least 1 characters",
      "type": "value_error.any_str.min_length"
    }
  ]
}
```

## 🚦 Rate Limiting

### Current Implementation

The current implementation does not include rate limiting, but the architecture supports adding it.

### Future Rate Limiting

#### Per-IP Rate Limiting
- Default: 100 requests per minute per IP
- Burst: Up to 200 requests in 1 minute

#### Per-User Rate Limiting (with authentication)
- Default: 1000 requests per hour per user
- Premium: 10000 requests per hour per user

#### Rate Limit Headers
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642248600
```

## 📚 SDK and Examples

### Python SDK Example

```python
import requests
from typing import Optional, Dict, Any

class MicroserviceClient:
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
    
    def health_check(self) -> Dict[str, Any]:
        """Check service health status."""
        response = self.session.get(f"{self.base_url}/healthz")
        response.raise_for_status()
        return response.json()
    
    def readiness_check(self) -> Dict[str, Any]:
        """Check service readiness status."""
        response = self.session.get(f"{self.base_url}/ready")
        response.raise_for_status()
        return response.json()
    
    def say_hello(self, name: Optional[str] = None) -> Dict[str, Any]:
        """Get personalized greeting."""
        url = f"{self.base_url}/api/v1/hello"
        
        if name:
            # Use POST with body
            response = self.session.post(
                url,
                json={"name": name},
                headers={"Content-Type": "application/json"}
            )
        else:
            # Use GET without parameters
            response = self.session.get(url)
        
        response.raise_for_status()
        return response.json()
    
    def get_metrics(self) -> str:
        """Get Prometheus metrics."""
        response = self.session.get(f"{self.base_url}/metrics")
        response.raise_for_status()
        return response.text

# Usage example
client = MicroserviceClient("http://localhost:8080")

# Health checks
print(client.health_check())
print(client.readiness_check())

# API calls
print(client.say_hello())
print(client.say_hello("DevOps Engineer"))

# Metrics
metrics = client.get_metrics()
print(f"Metrics length: {len(metrics)} characters")
```

### JavaScript/Node.js Example

```javascript
const axios = require('axios');

class MicroserviceClient {
    constructor(baseUrl = 'http://localhost:8080') {
        this.baseUrl = baseUrl.replace(/\/$/, '');
        this.client = axios.create({
            baseURL: this.baseUrl,
            timeout: 30000,
            headers: {
                'Content-Type': 'application/json'
            }
        });
    }

    async healthCheck() {
        const response = await this.client.get('/healthz');
        return response.data;
    }

    async readinessCheck() {
        const response = await this.client.get('/ready');
        return response.data;
    }

    async sayHello(name = null) {
        if (name) {
            const response = await this.client.post('/api/v1/hello', { name });
            return response.data;
        } else {
            const response = await this.client.get('/api/v1/hello');
            return response.data;
        }
    }

    async getMetrics() {
        const response = await this.client.get('/metrics');
        return response.data;
    }
}

// Usage example
async function example() {
    const client = new MicroserviceClient('http://localhost:8080');
    
    try {
        // Health checks
        console.log(await client.healthCheck());
        console.log(await client.readinessCheck());
        
        // API calls
        console.log(await client.sayHello());
        console.log(await client.sayHello('DevOps Engineer'));
        
        // Metrics
        const metrics = await client.getMetrics();
        console.log(`Metrics length: ${metrics.length} characters`);
        
    } catch (error) {
        console.error('API call failed:', error.response?.data || error.message);
    }
}

example();
```

### Bash/cURL Examples

```bash
#!/bin/bash

# Configuration
BASE_URL="http://localhost:8080"
API_VERSION="v1"

# Health check function
health_check() {
    echo "Checking service health..."
    curl -s -f "$BASE_URL/healthz" | jq '.'
}

# Readiness check function
readiness_check() {
    echo "Checking service readiness..."
    curl -s -f "$BASE_URL/ready" | jq '.'
}

# Hello API function
say_hello() {
    local name="$1"
    
    if [[ -n "$name" ]]; then
        echo "Saying hello to $name..."
        curl -s -X POST "$BASE_URL/api/$API_VERSION/hello" \
             -H "Content-Type: application/json" \
             -d "{\"name\": \"$name\"}" | jq '.'
    else
        echo "Saying hello..."
        curl -s "$BASE_URL/api/$API_VERSION/hello" | jq '.'
    fi
}

# Metrics function
get_metrics() {
    echo "Getting metrics..."
    curl -s "$BASE_URL/metrics" | head -20
}

# Load testing function
load_test() {
    local requests="${1:-10}"
    local concurrency="${2:-5}"
    
    echo "Running load test with $requests requests and $concurrency concurrency..."
    
    # Using Apache Bench if available
    if command -v ab &> /dev/null; then
        ab -n "$requests" -c "$concurrency" "$BASE_URL/api/$API_VERSION/hello"
    else
        echo "Apache Bench (ab) not found, using simple loop..."
        for i in $(seq 1 "$requests"); do
            curl -s "$BASE_URL/api/$API_VERSION/hello" > /dev/null &
            if (( i % concurrency == 0 )); then
                wait
            fi
        done
        wait
        echo "Load test completed!"
    fi
}

# Main function
main() {
    echo "=== Microservice API Test Suite ==="
    echo ""
    
    health_check
    echo ""
    
    readiness_check
    echo ""
    
    say_hello
    echo ""
    
    say_hello "DevOps Team"
    echo ""
    
    get_metrics
    echo ""
    
    load_test 20 3
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 🔍 Testing and Validation

### API Testing with Postman

Import this collection for comprehensive API testing:

```json
{
    "info": {
        "name": "DevOps Microservice API",
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    },
    "item": [
        {
            "name": "Health Check",
            "request": {
                "method": "GET",
                "header": [],
                "url": {
                    "raw": "{{base_url}}/healthz",
                    "host": ["{{base_url}}"],
                    "path": ["healthz"]
                }
            }
        },
        {
            "name": "Readiness Check",
            "request": {
                "method": "GET",
                "header": [],
                "url": {
                    "raw": "{{base_url}}/ready",
                    "host": ["{{base_url}}"],
                    "path": ["ready"]
                }
            }
        },
        {
            "name": "Hello API - GET",
            "request": {
                "method": "GET",
                "header": [],
                "url": {
                    "raw": "{{base_url}}/api/v1/hello?name=Postman",
                    "host": ["{{base_url}}"],
                    "path": ["api", "v1", "hello"],
                    "query": [
                        {
                            "key": "name",
                            "value": "Postman"
                        }
                    ]
                }
            }
        },
        {
            "name": "Hello API - POST",
            "request": {
                "method": "POST",
                "header": [
                    {
                        "key": "Content-Type",
                        "value": "application/json"
                    }
                ],
                "body": {
                    "mode": "raw",
                    "raw": "{\n    \"name\": \"Postman User\"\n}"
                },
                "url": {
                    "raw": "{{base_url}}/api/v1/hello",
                    "host": ["{{base_url}}"],
                    "path": ["api", "v1", "hello"]
                }
            }
        },
        {
            "name": "Metrics",
            "request": {
                "method": "GET",
                "header": [],
                "url": {
                    "raw": "{{base_url}}/metrics",
                    "host": ["{{base_url}}"],
                    "path": ["metrics"]
                }
            }
        }
    ],
    "variable": [
        {
            "key": "base_url",
            "value": "http://localhost:8080"
        }
    ]
}
```

### Performance Benchmarks

Expected performance characteristics:

| Metric | Development | Staging | Production |
|--------|------------|---------|------------|
| **Response Time (95th percentile)** | < 200ms | < 150ms | < 100ms |
| **Throughput** | 100 RPS | 500 RPS | 1000+ RPS |
| **Memory Usage** | < 256MB | < 512MB | < 1GB |
| **CPU Usage** | < 0.5 cores | < 1 core | < 2 cores |

## 📞 Support and Feedback

### Interactive Documentation

- **Swagger UI**: Available at `/docs` endpoint
- **ReDoc**: Available at `/redoc` endpoint
- **OpenAPI Spec**: Available at `/openapi.json` endpoint

### Getting Help

- **GitHub Issues**: Report bugs or request features
- **Documentation**: Comprehensive guides in `/docs` directory
- **Examples**: Working code examples in this document

### API Versioning Strategy

- **Current Version**: v1
- **Backward Compatibility**: Maintained for at least 2 major versions
- **Deprecation Policy**: 6 months notice for breaking changes
- **Version Header**: Optional `API-Version` header support

---

**📝 API Documentation Complete**

This API documentation provides everything needed to integrate with the DevOps Pipeline microservice. For additional information, refer to the interactive documentation at `/docs` or the comprehensive project documentation. 