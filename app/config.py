"""
Application Configuration
Using Pydantic Settings for environment-based configuration
"""
from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from typing import Optional


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # Server configuration
    PORT: int = 8080
    HOST: str = "0.0.0.0"
    
    # Application configuration
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"
    VERSION: str = "1.0.0"
    
    # Monitoring configuration
    METRICS_ENABLED: bool = True
    TRACING_ENABLED: bool = True
    
    # OpenTelemetry configuration
    JAEGER_ENDPOINT: Optional[str] = None
    JAEGER_PORT: int = 6831
    
    # Health check configuration
    STARTUP_DELAY: int = 2
    
    model_config = ConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True
    )


# Global settings instance
settings = Settings() 