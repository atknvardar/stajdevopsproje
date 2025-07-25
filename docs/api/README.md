q# 🔧 API Documentation

This document provides comprehensive documentation for the Enterprise DevOps Pipeline microservice API, including endpoint specifications, authentication, examples, and best practices.

## 📋 Table of Contents

- [API Overview](#api-overview)
- [Authentication](#authentication)
- [Health Check Endpoints](#health-check-endpoints)
- [Business Logic Endpoints](#business-logic-endpoints)
- [🔴 Chaos Engineering Endpoints](#-chaos-engineering-endpoints)
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

## 🔴 Chaos Engineering Endpoints

The chaos engineering system allows you to intentionally inject failures into your application to test resilience and self-healing capabilities. This follows Netflix's Chaos Monkey principles.

> ⚠️ **WARNING**: Only use chaos engineering in development/testing environments or with proper safeguards in production!

### 🎛️ Interactive Chaos Control Panel

Use these ready-to-copy commands to control chaos scenarios:

#### 🔴 **INJECT CHAOS BUTTONS** - Click to copy!

```bash
# 💾 Memory Leak Injection
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=memory_leak"
```

```bash
# 🐌 Slow Response Injection  
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=slow_responses"
```

```bash
# ⚠️ Error Injection
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=error_injection"
```

```bash
# 🔥 CPU Spike Injection
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=cpu_spike"
```

```bash
# 🎲 Random Chaos
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=random"
```

#### ✅ **HEALING BUTTONS** - Emergency Recovery!

```bash
# 🛡️ HEAL ALL CHAOS - Emergency Stop!
curl -X POST "http://localhost:8080/admin/chaos/heal"
```

```bash
# 📊 Check Chaos Status
curl -X GET "http://localhost:8080/admin/chaos/status"
```

```bash
# 📈 View Healing Reports
curl -X GET "http://localhost:8080/admin/healing-reports"
```

### Chaos Injection Endpoint

**Endpoint**: `POST /admin/chaos/inject`

**Purpose**: Inject specific chaos scenarios into the running application.

**Parameters**:
- `chaos_type` (query, required): Type of chaos to inject

**Available Chaos Types**:
- `memory_leak`: Gradual memory consumption increase (~1MB/second)
- `slow_responses`: Artificial delays in responses (2-5 seconds)
- `error_injection`: Random 500 errors (30% failure rate)
- `cpu_spike`: High CPU usage burst (30 seconds)
- `random`: Randomly select one of the above

**Request**:
```http
POST /admin/chaos/inject?chaos_type=memory_leak HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "chaos_type": "memory_leak",
  "status": "activated",
  "timestamp": "2024-01-15T10:30:00Z",
  "details": "Memory leak started - will consume ~1MB/second"
}
```

**Response Codes**:
- `200 OK`: Chaos successfully injected
- `400 Bad Request`: Invalid chaos type
- `503 Service Unavailable`: Service unhealthy, chaos injection disabled

**Chaos Scenarios Details**:

#### 💾 Memory Leak Chaos
- **Effect**: Gradual memory allocation
- **Rate**: ~1MB per second
- **Limit**: Maximum 100MB to prevent system crash
- **Detection**: Memory usage alerts trigger at >80% usage

#### 🐌 Slow Response Chaos
- **Effect**: Artificial delays in API responses
- **Delay Range**: 2-5 seconds randomly
- **Scope**: All API endpoints except admin/health/metrics
- **Detection**: Response time alerts trigger at >1 second

#### ⚠️ Error Injection Chaos
- **Effect**: Random HTTP 500 errors
- **Rate**: 30% of requests fail
- **Scope**: All API endpoints except admin/health/metrics
- **Detection**: Error rate alerts trigger at >5% error rate

#### 🔥 CPU Spike Chaos
- **Effect**: Intensive CPU calculations
- **Duration**: 30 seconds
- **Impact**: High CPU utilization
- **Detection**: CPU usage alerts trigger at >80% usage

### Chaos Healing Endpoint

**Endpoint**: `POST /admin/chaos/heal`

**Purpose**: Stop all active chaos scenarios and restore normal operation.

**Request**:
```http
POST /admin/chaos/heal HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "status": "healed",
  "actions_taken": [
    "memory_leak_stopped",
    "slow_responses_stopped",
    "error_injection_stopped",
    "cpu_spike_stopped"
  ],
  "timestamp": "2024-01-15T10:30:00Z",
  "message": "All chaos scenarios stopped"
}
```

**Healing Actions**:
- **Memory Leak**: Clear allocated objects and force garbage collection
- **Slow Responses**: Disable artificial delays
- **Error Injection**: Disable random errors
- **CPU Spike**: Stop intensive calculations

### Chaos Status Endpoint

**Endpoint**: `GET /admin/chaos/status`

**Purpose**: Get real-time status of all chaos scenarios.

**Request**:
```http
GET /admin/chaos/status HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "active_chaos": ["memory_leak", "slow_responses"],
  "chaos_count": 2,
  "memory_objects_count": 45,
  "recent_events": [
    {
      "timestamp": "2024-01-15T10:30:00Z",
      "event_type": "memory_leak",
      "details": "Memory leak injection started"
    },
    {
      "timestamp": "2024-01-15T10:31:00Z", 
      "event_type": "slow_responses",
      "details": "Slow response injection activated"
    }
  ],
  "system_impact": {
    "any_chaos_active": true,
    "estimated_memory_usage_mb": 45,
    "performance_degraded": true
  }
}
```

### Healing Reports Endpoint

**Endpoint**: `POST /admin/healing-report`

**Purpose**: Store healing reports from automated n8n workflows.

**Request Body**:
```json
{
  "workflow_id": "healing_workflow_123",
  "original_alert": {
    "chaos_type": "memory_leak",
    "severity": "critical"
  },
  "overall_status": "success",
  "healing_steps": [
    {
      "step": "analysis",
      "status": "completed",
      "duration": "5s"
    },
    {
      "step": "healing",
      "status": "completed", 
      "duration": "2s"
    }
  ]
}
```

**Response**:
```json
{
  "status": "stored",
  "report_id": "healing_workflow_123",
  "chaos_type": "memory_leak",
  "timestamp": "2024-01-15T10:35:00Z"
}
```

### Get Healing Reports Endpoint

**Endpoint**: `GET /admin/healing-reports`

**Purpose**: Retrieve stored healing reports and success metrics.

**Response**:
```json
{
  "total_reports": 25,
  "reports": [
    {
      "workflow_id": "healing_workflow_123",
      "chaos_type": "memory_leak",
      "overall_status": "success",
      "stored_at": "2024-01-15T10:35:00Z"
    }
  ],
  "summary": {
    "successful_healings": 20,
    "partial_healings": 3, 
    "failed_healings": 2
  }
}
```

### 🚨 Chaos Safety Features

#### Health Check Protection
- Chaos injection is **disabled** when service is unhealthy
- Health checks (`/healthz`, `/ready`) are **never affected** by chaos
- Metrics endpoint (`/metrics`) remains **always accessible**

#### Resource Limits
- **Memory Leak**: Limited to 100MB maximum allocation
- **CPU Spike**: Limited to 30-second duration
- **Automatic Cleanup**: Background threads clean up resources

#### Event Logging
- All chaos events are logged with timestamps
- History limited to last 50 events to prevent memory leaks
- Prometheus metrics track chaos activity

### 🎯 Chaos Engineering Best Practices

#### Pre-Chaos Checklist
1. ✅ **Monitor Setup**: Ensure monitoring/alerting is configured
2. ✅ **Backup Plan**: Have healing mechanisms ready
3. ✅ **Time Window**: Run during low-traffic periods
4. ✅ **Team Notification**: Alert team before starting chaos
5. ✅ **Resource Limits**: Verify safety limits are in place

#### During Chaos Testing
1. 📊 **Monitor Dashboards**: Watch system metrics closely
2. ⏰ **Time Limits**: Don't run chaos for extended periods
3. 🚨 **Alert Response**: Test if alerts fire as expected
4. 🔍 **Log Analysis**: Monitor logs for error patterns
5. ⚡ **Quick Recovery**: Be ready to heal immediately

#### Post-Chaos Analysis
1. 📈 **Metrics Review**: Analyze performance impact
2. 🐛 **Issue Discovery**: Document any weaknesses found
3. 🛠️ **Improvements**: Plan resilience improvements
4. 📝 **Documentation**: Update runbooks based on learnings
5. 🎯 **Next Steps**: Plan follow-up chaos experiments

### 🤖 Automated Self-Healing Integration

The chaos engineering system integrates with n8n workflow automation for **automated detection and healing**:

#### Self-Healing Workflow
1. **🔴 Chaos Injection** → Prometheus metrics change
2. **📊 Alert Detection** → Alertmanager sends webhook to n8n
3. **🧠 AI Analysis** → Cursor AI analyzes the problem
4. **🔧 Automated Healing** → n8n triggers healing endpoint
5. **🧪 Validation** → System tests confirm recovery
6. **📋 Reporting** → Healing report stored for analysis

#### n8n Webhook Endpoint
```bash
# n8n receives alerts at this endpoint
POST http://n8n:5678/webhook/chaos-alert
```

#### Example Alert Payload
```json
{
  "alerts": [
    {
      "labels": {
        "alertname": "ChaosMemoryLeak",
        "chaos_type": "memory_leak",
        "severity": "critical"
      },
      "annotations": {
        "description": "Memory usage increased significantly",
        "runbook_url": "https://docs.company.com/runbooks/memory"
      }
    }
  ]
}
```

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