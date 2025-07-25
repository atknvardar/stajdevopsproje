"""
Integration tests for the microservice application
"""
import pytest
import asyncio
import time
from fastapi.testclient import TestClient
from unittest.mock import patch

from app.main import app, app_state


@pytest.fixture
def client():
    """Test client fixture for integration tests"""
    return TestClient(app)


@pytest.fixture
def reset_state():
    """Reset application state for integration tests"""
    app_state["ready"] = True
    app_state["healthy"] = True
    app_state["startup_time"] = time.time()
    yield
    app_state["ready"] = True
    app_state["healthy"] = True


class TestFullApplicationWorkflow:
    """Test complete application workflows"""
    
    def test_startup_to_ready_workflow(self, client, reset_state):
        """Test complete startup workflow"""
        # Simulate application not ready initially
        app_state["ready"] = False
        
        # Readiness should fail
        response = client.get("/ready")
        assert response.status_code == 503
        
        # Liveness should still work
        response = client.get("/healthz")
        assert response.status_code == 200
        
        # Simulate startup completion
        app_state["ready"] = True
        
        # Now readiness should work
        response = client.get("/ready")
        assert response.status_code == 200
        
        # API should work when ready
        response = client.get("/api/v1/hello")
        assert response.status_code == 200
    
    def test_health_failure_workflow(self, client, reset_state):
        """Test health failure and recovery workflow"""
        # Initially healthy
        response = client.get("/healthz")
        assert response.status_code == 200
        
        # Trigger health failure via admin endpoint
        response = client.post("/admin/health/toggle")
        assert response.status_code == 200
        assert response.json()["healthy"] is False
        
        # Health check should now fail
        response = client.get("/healthz")
        assert response.status_code == 503
        
        # API should still work (only affects liveness)
        response = client.get("/api/v1/hello")
        assert response.status_code == 200
        
        # Restore health
        response = client.post("/admin/health/toggle")
        assert response.status_code == 200
        assert response.json()["healthy"] is True
        
        # Health check should work again
        response = client.get("/healthz")
        assert response.status_code == 200
    
    def test_metrics_collection_workflow(self, client, reset_state):
        """Test that metrics are properly collected across requests"""
        # Get initial metrics
        metrics_response = client.get("/metrics")
        initial_metrics = metrics_response.text
        
        # Make several API requests
        for i in range(5):
            client.get(f"/api/v1/hello?name=User{i}")
        
        # Make some health check requests
        for i in range(3):
            client.get("/healthz")
        
        # Get updated metrics
        metrics_response = client.get("/metrics")
        updated_metrics = metrics_response.text
        
        # Verify metrics have been updated
        assert "http_requests_total" in updated_metrics
        assert "http_request_duration_seconds" in updated_metrics
        
        # Check that request counts have increased
        assert updated_metrics != initial_metrics
    
    def test_api_consistency_workflow(self, client, reset_state):
        """Test API consistency across multiple requests"""
        # Make multiple requests to the same endpoint
        responses = []
        for i in range(10):
            response = client.get("/api/v1/hello?name=TestUser")
            responses.append(response)
        
        # All should be successful
        for response in responses:
            assert response.status_code == 200
            data = response.json()
            assert data["message"] == "Hello, TestUser!"
            assert data["version"] == "1.0.0"
            assert "timestamp" in data
    
    def test_concurrent_requests_workflow(self, client, reset_state):
        """Test handling of concurrent requests"""
        import threading
        import queue
        
        results = queue.Queue()
        
        def make_request():
            try:
                response = client.get("/api/v1/hello")
                results.put(response.status_code)
            except Exception as e:
                results.put(str(e))
        
        # Create multiple threads making concurrent requests
        threads = []
        for i in range(10):
            thread = threading.Thread(target=make_request)
            threads.append(thread)
            thread.start()
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
        
        # Check that all requests succeeded
        while not results.empty():
            result = results.get()
            assert result == 200
    
    def test_error_handling_workflow(self, client, reset_state):
        """Test error handling across different scenarios"""
        # Test with application not ready
        app_state["ready"] = False
        response = client.get("/ready")
        assert response.status_code == 503
        assert "detail" in response.json()
        
        # Test with application unhealthy
        app_state["ready"] = True
        app_state["healthy"] = False
        response = client.get("/healthz")
        assert response.status_code == 503
        assert "detail" in response.json()
        
        # Test that API documentation is accessible
        app_state["healthy"] = True
        response = client.get("/docs")
        assert response.status_code == 200
        
        # Test OpenAPI schema
        response = client.get("/openapi.json")
        assert response.status_code == 200
        schema = response.json()
        assert "paths" in schema
        assert "/healthz" in schema["paths"]
        assert "/ready" in schema["paths"]
        assert "/metrics" in schema["paths"]
        assert "/api/v1/hello" in schema["paths"]


class TestEnvironmentConfiguration:
    """Test environment-specific configurations"""
    
    @patch("app.config.settings.LOG_LEVEL", "DEBUG")
    def test_debug_environment_behavior(self, client, reset_state):
        """Test behavior in debug environment"""
        response = client.get("/api/v1/status")
        data = response.json()
        
        # Should have environment information
        assert "log_level" in data
        assert "environment" in data
    
    def test_production_like_behavior(self, client, reset_state):
        """Test production-like behavior"""
        # Properly mock the settings in the main module where it's imported
        with patch("app.main.settings.ENVIRONMENT", "production"):
            response = client.get("/api/v1/status")
            data = response.json()
            assert data["environment"] == "production"


class TestApplicationLifecycle:
    """Test application lifecycle events"""
    
    def test_application_info_consistency(self, client, reset_state):
        """Test that application info is consistent across endpoints"""
        # Get version from different endpoints
        root_response = client.get("/")
        hello_response = client.get("/api/v1/hello")
        health_response = client.get("/healthz")
        status_response = client.get("/api/v1/status")
        
        # All should return version 1.0.0
        assert root_response.json()["version"] == "1.0.0"
        assert hello_response.json()["version"] == "1.0.0"
        assert health_response.json()["version"] == "1.0.0"
        assert status_response.json()["version"] == "1.0.0"
    
    def test_uptime_tracking(self, client, reset_state):
        """Test that uptime is properly tracked"""
        # Get initial uptime
        response1 = client.get("/ready")
        uptime1 = response1.json()["uptime"]
        
        # Wait a bit
        time.sleep(0.1)
        
        # Get uptime again
        response2 = client.get("/ready")
        uptime2 = response2.json()["uptime"]
        
        # Second uptime should be greater
        assert uptime2 > uptime1 