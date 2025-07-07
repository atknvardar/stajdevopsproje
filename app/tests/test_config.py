"""
Unit tests for configuration module
"""
import pytest
import os
from unittest.mock import patch

from app.config import Settings


class TestSettings:
    """Test Settings class"""
    
    def test_default_values(self):
        """Test default configuration values"""
        settings = Settings()
        
        assert settings.PORT == 8080
        assert settings.HOST == "0.0.0.0"
        assert settings.ENVIRONMENT == "development"
        assert settings.LOG_LEVEL == "INFO"
        assert settings.VERSION == "1.0.0"
        assert settings.METRICS_ENABLED is True
        assert settings.TRACING_ENABLED is True
        assert settings.JAEGER_ENDPOINT is None
        assert settings.JAEGER_PORT == 6831
        assert settings.STARTUP_DELAY == 2
    
    @patch.dict(os.environ, {
        "PORT": "9000",
        "ENVIRONMENT": "production",
        "LOG_LEVEL": "ERROR",
        "METRICS_ENABLED": "false",
        "JAEGER_ENDPOINT": "jaeger.example.com"
    })
    def test_environment_variable_override(self):
        """Test that environment variables override defaults"""
        settings = Settings()
        
        assert settings.PORT == 9000
        assert settings.ENVIRONMENT == "production"
        assert settings.LOG_LEVEL == "ERROR"
        assert settings.METRICS_ENABLED is False
        assert settings.JAEGER_ENDPOINT == "jaeger.example.com"
    
    def test_settings_case_sensitive(self):
        """Test that settings are case sensitive"""
        with patch.dict(os.environ, {"port": "9000"}):  # lowercase
            settings = Settings()
            # Should use default since environment var is lowercase
            assert settings.PORT == 8080
    
    @patch.dict(os.environ, {"TRACING_ENABLED": "true"})
    def test_boolean_conversion(self):
        """Test boolean value conversion from environment"""
        settings = Settings()
        assert settings.TRACING_ENABLED is True
        
        with patch.dict(os.environ, {"TRACING_ENABLED": "false"}):
            settings = Settings()
            assert settings.TRACING_ENABLED is False 