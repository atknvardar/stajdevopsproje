"""
Unit tests for main FastAPI application
"""
import pytest
import time
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock

from app.main import app, app_state


@pytest.fixture
def client():
    """Test client fixture"""
    return TestClient(app)


@pytest.fixture
def reset_app_state():
    """Reset application state before each test"""
    app_state["ready"] = True
    app_state["healthy"] = True
    app_state["startup_time"] = time.time()
    yield
    app_state["ready"] = True
    app_state["healthy"] = True


class TestHealthEndpoints:
    """Test health check endpoints"""
    
    def test_liveness_check_healthy(self, client, reset_app_state):
        """Test liveness check when application is healthy"""
        response = client.get("/healthz")
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "healthy"
        assert data["version"] == "1.0.0"
        assert "timestamp" in data
    
    def test_liveness_check_unhealthy(self, client, reset_app_state):
        """Test liveness check when application is unhealthy"""
        app_state["healthy"] = False
        
        response = client.get("/healthz")
        assert response.status_code == 503
        assert "Application unhealthy" in response.json()["detail"]
    
    def test_readiness_check_ready(self, client, reset_app_state):
        """Test readiness check when application is ready"""
        response = client.get("/ready")
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "ready"
        assert data["version"] == "1.0.0"
        assert "timestamp" in data
        assert "uptime" in data
    
    def test_readiness_check_not_ready(self, client, reset_app_state):
        """Test readiness check when application is not ready"""
        app_state["ready"] = False
        
        response = client.get("/ready")
        assert response.status_code == 503
        assert "Application not ready" in response.json()["detail"]


class TestMetricsEndpoint:
    """Test metrics endpoint"""
    
    def test_metrics_endpoint(self, client):
        """Test metrics endpoint returns Prometheus format"""
        response = client.get("/metrics")
        assert response.status_code == 200
        assert "text/plain" in response.headers["content-type"]
        
        # Check for expected metrics
        content = response.text
        assert "http_requests_total" in content
        assert "http_request_duration_seconds" in content
        assert "application_ready" in content
        assert "application_healthy" in content


class TestAPIEndpoints:
    """Test API endpoints"""
    
    def test_hello_world_default(self, client):
        """Test hello endpoint with default parameter"""
        response = client.get("/api/v1/hello")
        assert response.status_code == 200
        
        data = response.json()
        assert data["message"] == "Hello, World!"
        assert data["version"] == "1.0.0"
        assert "timestamp" in data
    
    def test_hello_world_custom_name(self, client):
        """Test hello endpoint with custom name"""
        response = client.get("/api/v1/hello?name=Alice")
        assert response.status_code == 200
        
        data = response.json()
        assert data["message"] == "Hello, Alice!"
        assert data["version"] == "1.0.0"
        assert "timestamp" in data
    
    def test_application_status(self, client, reset_app_state):
        """Test application status endpoint"""
        response = client.get("/api/v1/status")
        assert response.status_code == 200
        
        data = response.json()
        assert data["application"] == "microservice-demo"
        assert data["version"] == "1.0.0"
        assert data["status"] == "running"
        assert "uptime" in data
        assert "environment" in data
        assert "log_level" in data


class TestAdminEndpoints:
    """Test admin endpoints"""
    
    def test_toggle_health(self, client, reset_app_state):
        """Test health toggle endpoint"""
        # Initial state should be healthy
        assert app_state["healthy"] is True
        
        # Toggle health
        response = client.post("/admin/health/toggle")
        assert response.status_code == 200
        assert response.json()["healthy"] is False
        assert app_state["healthy"] is False
        
        # Toggle back
        response = client.post("/admin/health/toggle")
        assert response.status_code == 200
        assert response.json()["healthy"] is True
        assert app_state["healthy"] is True


class TestRootEndpoint:
    """Test root endpoint"""
    
    def test_root_endpoint(self, client):
        """Test root endpoint returns service information"""
        response = client.get("/")
        assert response.status_code == 200
        
        data = response.json()
        assert data["service"] == "microservice-demo"
        assert data["version"] == "1.0.0"
        assert "endpoints" in data
        
        endpoints = data["endpoints"]
        assert endpoints["health"] == "/healthz"
        assert endpoints["readiness"] == "/ready"
        assert endpoints["metrics"] == "/metrics"
        assert endpoints["api"] == "/api/v1/hello"
        assert endpoints["docs"] == "/docs"


class TestMiddleware:
    """Test middleware functionality"""
    
    def test_metrics_middleware_increments_counters(self, client):
        """Test that middleware properly increments metrics"""
        # Make a request to trigger middleware
        response = client.get("/api/v1/hello")
        assert response.status_code == 200
        
        # Check metrics endpoint for incremented counters
        metrics_response = client.get("/metrics")
        content = metrics_response.text
        
        # Should contain request count and duration metrics
        assert 'http_requests_total{endpoint="/api/v1/hello"' in content
        assert "http_request_duration_seconds" in content


@pytest.mark.asyncio
class TestAsyncFunctionality:
    """Test async functionality"""
    
    async def test_async_endpoints(self):
        """Test async endpoints work correctly"""
        from app.main import hello_world, liveness_check, readiness_check
        
        # Test hello endpoint
        result = await hello_world("Test")
        assert result.message == "Hello, Test!"
        
        # Test health endpoints (when app is healthy and ready)
        app_state["healthy"] = True
        app_state["ready"] = True
        
        health_result = await liveness_check()
        assert health_result.status == "healthy"
        
        ready_result = await readiness_check()
        assert ready_result.status == "ready" 