"""
Pydantic Models for API Responses
"""
from pydantic import BaseModel
from typing import Optional


class HelloResponse(BaseModel):
    """Response model for hello endpoint"""
    message: str
    timestamp: float
    version: str
    
    class Config:
        """Pydantic configuration"""
        json_schema_extra = {
            "example": {
                "message": "Hello, World!",
                "timestamp": 1640995200.0,
                "version": "1.0.0"
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
                "version": "1.0.0",
                "uptime": 3600.0
            }
        } 