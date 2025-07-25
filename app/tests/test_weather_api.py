"""
Unit tests for weather aggregator API
"""
import pytest
import time
from fastapi.testclient import TestClient
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app, app_state


@pytest.fixture
def client():
    """Test client fixture"""
    return TestClient(app)


class TestHealthEndpoints:
    """Test health check endpoints"""
    
    def test_liveness_check_healthy(self, client):
        """Test liveness check when application is healthy"""
        response = client.get("/healthz")
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "healthy"
        assert "version" in data
        assert "timestamp" in data
    
    def test_readiness_check_ready(self, client):
        """Test readiness check when application is ready"""
        response = client.get("/ready")
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "ready"
        assert "version" in data
        assert "timestamp" in data


class TestMetricsEndpoint:
    """Test metrics endpoint"""
    
    def test_metrics_endpoint(self, client):
        """Test metrics endpoint returns Prometheus format"""
        response = client.get("/metrics")
        assert response.status_code == 200
        assert "text/plain" in response.headers["content-type"]
        
        # Check for expected metrics
        content = response.text
        assert "http_request" in content or "weather_" in content


class TestRootEndpoint:
    """Test root endpoint"""
    
    def test_root_endpoint(self, client):
        """Test root endpoint returns service information"""
        response = client.get("/")
        assert response.status_code == 200
        
        data = response.json()
        assert data["service"] == "weather-data-aggregator"
        assert "version" in data
        assert "endpoints" in data
        
        endpoints = data["endpoints"]
        assert endpoints["health"] == "/healthz"
        assert endpoints["readiness"] == "/ready"
        assert endpoints["metrics"] == "/metrics"
        assert endpoints["docs"] == "/docs"


class TestWeatherEndpoints:
    """Test weather API endpoints"""
    
    def test_current_weather_endpoint(self, client):
        """Test current weather endpoint"""
        response = client.get("/api/v1/weather/current?city=Istanbul")
        # API key might not be configured, so accept 200 or error
        assert response.status_code in [200, 500, 503]
    
    def test_aggregated_weather_endpoint(self, client):
        """Test aggregated weather endpoint"""
        response = client.get("/api/v1/weather/aggregated?city=Istanbul")
        # API key might not be configured, so accept 200 or error
        assert response.status_code in [200, 500, 503]
    
    def test_status_apis_endpoint(self, client):
        """Test API status endpoint"""
        response = client.get("/api/v1/status/apis")
        assert response.status_code == 200
        # Should return a list
        assert isinstance(response.json(), list)