"""
Application Configuration for Weather Data Aggregator
Using Pydantic Settings for environment-based configuration
"""
from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from typing import Optional, List, Dict
import json


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # Server configuration
    PORT: int = 8080
    HOST: str = "0.0.0.0"
    
    # Application configuration
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"
    VERSION: str = "2.0.0"
    
    # Monitoring configuration
    METRICS_ENABLED: bool = True
    TRACING_ENABLED: bool = True
    
    # OpenTelemetry configuration
    JAEGER_ENDPOINT: Optional[str] = None
    JAEGER_PORT: int = 6831
    
    # Weather API configuration
    OPENWEATHER_API_KEY: Optional[str] = None
    WEATHERAPI_KEY: Optional[str] = None
    OPENMETEO_API_KEY: Optional[str] = None  # Open-Meteo doesn't require API key
    
    # Weather API endpoints
    OPENWEATHER_BASE_URL: str = "https://api.openweathermap.org/data/2.5"
    WEATHERAPI_BASE_URL: str = "https://api.weatherapi.com/v1"
    OPENMETEO_BASE_URL: str = "https://api.open-meteo.com/v1"
    
    # Weather data configuration
    WEATHER_FETCH_INTERVAL: int = 300  # 5 minutes
    CACHE_TTL: int = 600  # 10 minutes
    MAX_RETRIES: int = 3
    REQUEST_TIMEOUT: int = 30
    
    # Default locations to monitor (can be overridden via env)
    DEFAULT_LOCATIONS_JSON: str = '[{"lat": 40.7128, "lon": -74.0060, "name": "New York"}, {"lat": 51.5074, "lon": -0.1278, "name": "London"}, {"lat": 48.8566, "lon": 2.3522, "name": "Paris"}]'
    
    @property
    def DEFAULT_LOCATIONS(self) -> List[Dict]:
        """Parse default locations from JSON string"""
        try:
            return json.loads(self.DEFAULT_LOCATIONS_JSON)
        except:
            return []
    
    # Rate limiting configuration
    OPENWEATHER_RATE_LIMIT: int = 60  # calls per minute
    WEATHERAPI_RATE_LIMIT: int = 1000000  # calls per month
    
    # Data quality thresholds
    DATA_QUALITY_MIN_SOURCES: int = 2  # Minimum sources for quality data
    DATA_QUALITY_MAX_AGE_MINUTES: int = 10  # Maximum age for fresh data
    
    # Alert configuration
    ALERT_ON_API_FAILURE: bool = True
    ALERT_ON_RATE_LIMIT: bool = True
    ALERT_WEBHOOK_URL: Optional[str] = None
    
    model_config = ConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True
    )


# Global settings instance
settings = Settings()