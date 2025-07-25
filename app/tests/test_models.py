"""
Unit tests for Pydantic models
"""
import pytest
from pydantic import ValidationError

from app.models import HelloResponse, HealthResponse


class TestHelloResponse:
    """Test HelloResponse model"""
    
    def test_valid_hello_response(self):
        """Test creating valid HelloResponse"""
        response = HelloResponse(
            message="Hello, Test!",
            timestamp=1640995200.0,
            version="1.0.0"
        )
        
        assert response.message == "Hello, Test!"
        assert response.timestamp == 1640995200.0
        assert response.version == "1.0.0"
    
    def test_hello_response_json_serialization(self):
        """Test JSON serialization of HelloResponse"""
        response = HelloResponse(
            message="Hello, World!",
            timestamp=1640995200.0,
            version="1.0.0"
        )
        
        json_data = response.model_dump()
        assert json_data["message"] == "Hello, World!"
        assert json_data["timestamp"] == 1640995200.0
        assert json_data["version"] == "1.0.0"
    
    def test_hello_response_missing_fields(self):
        """Test HelloResponse with missing required fields"""
        with pytest.raises(ValidationError) as exc_info:
            HelloResponse(message="Hello!")
        
        errors = exc_info.value.errors()
        error_fields = [error["loc"][0] for error in errors]
        assert "timestamp" in error_fields
        assert "version" in error_fields
    
    def test_hello_response_invalid_types(self):
        """Test HelloResponse with invalid field types"""
        with pytest.raises(ValidationError):
            HelloResponse(
                message=123,  # Should be string
                timestamp="invalid",  # Should be float
                version=1.0  # Should be string
            )


class TestHealthResponse:
    """Test HealthResponse model"""
    
    def test_valid_health_response_minimal(self):
        """Test creating valid HealthResponse with minimal fields"""
        response = HealthResponse(
            status="healthy",
            timestamp=1640995200.0,
            version="1.0.0"
        )
        
        assert response.status == "healthy"
        assert response.timestamp == 1640995200.0
        assert response.version == "1.0.0"
        assert response.uptime is None
    
    def test_valid_health_response_with_uptime(self):
        """Test creating valid HealthResponse with uptime"""
        response = HealthResponse(
            status="ready",
            timestamp=1640995200.0,
            version="1.0.0",
            uptime=3600.0
        )
        
        assert response.status == "ready"
        assert response.timestamp == 1640995200.0
        assert response.version == "1.0.0"
        assert response.uptime == 3600.0
    
    def test_health_response_json_serialization(self):
        """Test JSON serialization of HealthResponse"""
        response = HealthResponse(
            status="healthy",
            timestamp=1640995200.0,
            version="1.0.0",
            uptime=1800.0
        )
        
        json_data = response.model_dump()
        assert json_data["status"] == "healthy"
        assert json_data["timestamp"] == 1640995200.0
        assert json_data["version"] == "1.0.0"
        assert json_data["uptime"] == 1800.0
    
    def test_health_response_missing_fields(self):
        """Test HealthResponse with missing required fields"""
        with pytest.raises(ValidationError) as exc_info:
            HealthResponse(status="healthy")
        
        errors = exc_info.value.errors()
        error_fields = [error["loc"][0] for error in errors]
        assert "timestamp" in error_fields
        assert "version" in error_fields
    
    def test_health_response_optional_uptime(self):
        """Test that uptime is optional in HealthResponse"""
        # Should work without uptime
        response = HealthResponse(
            status="healthy",
            timestamp=1640995200.0,
            version="1.0.0"
        )
        assert response.uptime is None
        
        # Should work with uptime as None
        response = HealthResponse(
            status="healthy",
            timestamp=1640995200.0,
            version="1.0.0",
            uptime=None
        )
        assert response.uptime is None
    
    def test_health_response_example_schema(self):
        """Test that model has proper schema example"""
        schema = HealthResponse.model_config.get("json_schema_extra", {})
        example = schema.get("example", {})
        
        assert "status" in example
        assert "timestamp" in example
        assert "version" in example
        assert "uptime" in example 