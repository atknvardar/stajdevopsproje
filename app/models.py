"""
Pydantic Models for Weather Data Aggregator API
"""
from pydantic import BaseModel
from typing import Optional, Dict, List, Any
from datetime import datetime


class WeatherData(BaseModel):
    """Weather data model"""
    temperature: Optional[float] = None
    feels_like: Optional[float] = None
    temperature_min: Optional[float] = None
    temperature_max: Optional[float] = None
    pressure: Optional[int] = None
    humidity: Optional[int] = None
    wind_speed: Optional[float] = None
    wind_direction: Optional[int] = None
    clouds: Optional[int] = None
    visibility: Optional[int] = None
    description: Optional[str] = None
    icon: Optional[str] = None
    
    class Config:
        """Pydantic configuration"""
        json_schema_extra = {
            "example": {
                "temperature": 20.5,
                "feels_like": 19.2,
                "humidity": 65,
                "pressure": 1013,
                "wind_speed": 5.2,
                "description": "partly cloudy"
            }
        }


class LocationInfo(BaseModel):
    """Location information model"""
    lat: float
    lon: float
    name: Optional[str] = ""
    country: Optional[str] = ""
    timezone: Optional[str] = ""


class WeatherResponse(BaseModel):
    """Response model for weather endpoint"""
    location: Dict[str, Any]
    data: WeatherData
    timestamp: str
    source: str
    
    class Config:
        """Pydantic configuration"""
        json_schema_extra = {
            "example": {
                "location": {"lat": 40.7128, "lon": -74.0060, "name": "New York"},
                "data": {
                    "temperature": 20.5,
                    "humidity": 65,
                    "pressure": 1013
                },
                "timestamp": "2024-01-01T12:00:00",
                "source": "api"
            }
        }


class AggregatedWeatherResponse(BaseModel):
    """Response model for aggregated weather data"""
    location: Dict[str, Any]
    aggregated_data: Dict[str, Any]
    source_data: Dict[str, WeatherData]
    timestamp: str
    
    class Config:
        """Pydantic configuration"""
        json_schema_extra = {
            "example": {
                "location": {"lat": 40.7128, "lon": -74.0060},
                "aggregated_data": {
                    "temperature": 20.5,
                    "temperature_min": 19.0,
                    "temperature_max": 22.0,
                    "humidity": 65,
                    "sources_count": 3,
                    "sources": ["openweather", "weatherapi", "openmeteo"]
                },
                "source_data": {
                    "openweather": {"temperature": 20.5, "humidity": 65},
                    "weatherapi": {"temperature": 20.8, "humidity": 64}
                },
                "timestamp": "2024-01-01T12:00:00"
            }
        }


class WeatherTrendResponse(BaseModel):
    """Response model for weather trends"""
    location: Dict[str, Any]
    trends: Dict[str, Any]
    timestamp: str
    
    class Config:
        """Pydantic configuration"""
        json_schema_extra = {
            "example": {
                "location": {"lat": 40.7128, "lon": -74.0060},
                "trends": {
                    "temperature_trend": "increasing",
                    "humidity_trend": "stable",
                    "pressure_trend": "decreasing",
                    "period_hours": 24,
                    "data_points": 24
                },
                "timestamp": "2024-01-01T12:00:00"
            }
        }


class WeatherAPIStatus(BaseModel):
    """Status model for weather API health"""
    api_name: str
    is_healthy: bool
    response_time_ms: float
    error_rate: float
    rate_limit_remaining: Optional[int] = None
    last_checked: str
    
    class Config:
        """Pydantic configuration"""
        json_schema_extra = {
            "example": {
                "api_name": "openweather",
                "is_healthy": True,
                "response_time_ms": 250.5,
                "error_rate": 0.02,
                "rate_limit_remaining": 950,
                "last_checked": "2024-01-01T12:00:00"
            }
        }


class DataQualityMetrics(BaseModel):
    """Data quality metrics model"""
    overall_score: float
    completeness: float
    freshness: float
    consistency: float
    availability: float
    last_updated: str
    
    class Config:
        """Pydantic configuration"""
        json_schema_extra = {
            "example": {
                "overall_score": 85.5,
                "completeness": 90.0,
                "freshness": 88.0,
                "consistency": 82.0,
                "availability": 82.0,
                "last_updated": "2024-01-01T12:00:00"
            }
        }


class HealthResponse(BaseModel):
    """Response model for health check endpoints"""
    status: str
    timestamp: float
    version: str
    uptime: Optional[float] = None
    
    class Config:
        """Pydantic configuration"""
        json_schema_extra = {
            "example": {
                "status": "healthy",
                "timestamp": 1640995200.0,
                "version": "2.0.0",
                "uptime": 3600.0
            }
        }