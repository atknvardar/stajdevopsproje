"""
Weather Service Module
Handles weather data aggregation from multiple sources
"""
import asyncio
import logging
import random
from typing import Dict, Any, Optional, List
from datetime import datetime
import httpx
from models import WeatherData
from config import settings

logger = logging.getLogger(__name__)

class WeatherService:
    """Service for aggregating weather data from multiple sources"""
    
    def __init__(self):
        self.sources = {
            "openweathermap": self._fetch_openweathermap,
            "weatherapi": self._fetch_weatherapi,
            "mock": self._fetch_mock_data
        }
        self.client = httpx.AsyncClient(timeout=10.0)
        
    async def __aenter__(self):
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.client.aclose()
        
    async def get_aggregated_weather(self, lat: float, lon: float) -> Dict[str, Any]:
        """Get aggregated weather data from all available sources"""
        tasks = []
        for source_name, fetch_func in self.sources.items():
            if source_name == "mock" or self._is_api_key_configured(source_name):
                tasks.append(self._fetch_with_fallback(source_name, fetch_func, lat, lon))
                
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Filter out errors and aggregate data
        valid_results = []
        for result in results:
            if isinstance(result, dict) and not isinstance(result, Exception):
                valid_results.append(result)
                
        if not valid_results:
            # Return mock data if all APIs fail
            return await self._fetch_mock_data(lat, lon)
            
        # Average the values
        return self._aggregate_results(valid_results)
        
    async def get_all_sources_data(self, lat: float, lon: float) -> Dict[str, Dict[str, Any]]:
        """Get weather data from all sources separately"""
        all_data = {}
        
        for source_name, fetch_func in self.sources.items():
            if source_name == "mock" or self._is_api_key_configured(source_name):
                try:
                    data = await fetch_func(lat, lon)
                    all_data[source_name] = data
                except Exception as e:
                    logger.error(f"Error fetching from {source_name}: {e}")
                    all_data[source_name] = {"error": str(e)}
                    
        return all_data
        
    async def check_api_health(self) -> Dict[str, Dict[str, Any]]:
        """Check health status of all weather APIs"""
        health_status = {}
        
        for source_name in self.sources.keys():
            if source_name == "mock":
                health_status[source_name] = {
                    "is_healthy": True,
                    "response_time_ms": 1,
                    "rate_limit_remaining": 999999
                }
                continue
                
            if self._is_api_key_configured(source_name):
                start_time = datetime.now()
                try:
                    # Test with London coordinates
                    await self.sources[source_name](51.5074, -0.1278)
                    response_time = (datetime.now() - start_time).total_seconds() * 1000
                    
                    health_status[source_name] = {
                        "is_healthy": True,
                        "response_time_ms": response_time,
                        "error_rate": 0,
                        "last_checked": datetime.now().isoformat()
                    }
                except Exception as e:
                    health_status[source_name] = {
                        "is_healthy": False,
                        "error": str(e),
                        "last_checked": datetime.now().isoformat()
                    }
            else:
                health_status[source_name] = {
                    "is_healthy": False,
                    "error": "API key not configured",
                    "last_checked": datetime.now().isoformat()
                }
                
        return health_status
        
    async def _fetch_with_fallback(self, source_name: str, fetch_func, lat: float, lon: float) -> Dict[str, Any]:
        """Fetch data with error handling"""
        try:
            return await fetch_func(lat, lon)
        except Exception as e:
            logger.error(f"Error fetching from {source_name}: {e}")
            return {}
            
    async def _fetch_openweathermap(self, lat: float, lon: float) -> Dict[str, Any]:
        """Fetch weather data from OpenWeatherMap API"""
        api_key = settings.OPENWEATHER_API_KEY
        if not api_key:
            raise ValueError("OpenWeatherMap API key not configured")
            
        url = f"https://api.openweathermap.org/data/2.5/weather"
        params = {
            "lat": lat,
            "lon": lon,
            "appid": api_key,
            "units": "metric"
        }
        
        response = await self.client.get(url, params=params)
        response.raise_for_status()
        data = response.json()
        
        return {
            "temperature": data["main"]["temp"],
            "feels_like": data["main"]["feels_like"],
            "humidity": data["main"]["humidity"],
            "pressure": data["main"]["pressure"],
            "wind_speed": data["wind"]["speed"],
            "wind_direction": data["wind"]["deg"],
            "description": data["weather"][0]["description"],
            "source": "openweathermap"
        }
        
    async def _fetch_weatherapi(self, lat: float, lon: float) -> Dict[str, Any]:
        """Fetch weather data from WeatherAPI"""
        api_key = settings.WEATHERAPI_KEY
        if not api_key:
            raise ValueError("WeatherAPI key not configured")
            
        url = "https://api.weatherapi.com/v1/current.json"
        params = {
            "key": api_key,
            "q": f"{lat},{lon}"
        }
        
        response = await self.client.get(url, params=params)
        response.raise_for_status()
        data = response.json()
        
        return {
            "temperature": data["current"]["temp_c"],
            "feels_like": data["current"]["feelslike_c"],
            "humidity": data["current"]["humidity"],
            "pressure": data["current"]["pressure_mb"],
            "wind_speed": data["current"]["wind_kph"] / 3.6,  # Convert to m/s
            "wind_direction": data["current"]["wind_degree"],
            "description": data["current"]["condition"]["text"],
            "source": "weatherapi"
        }
        
    async def _fetch_mock_data(self, lat: float, lon: float) -> Dict[str, Any]:
        """Generate mock weather data for testing"""
        # Simulate some variance based on coordinates
        base_temp = 20 + (lat / 10) + (lon / 20)
        
        return {
            "temperature": round(base_temp + random.uniform(-5, 5), 1),
            "feels_like": round(base_temp + random.uniform(-3, 3), 1),
            "humidity": random.randint(40, 80),
            "pressure": random.randint(1000, 1020),
            "wind_speed": round(random.uniform(0, 15), 1),
            "wind_direction": random.randint(0, 360),
            "description": random.choice(["clear sky", "few clouds", "scattered clouds", "broken clouds"]),
            "source": "mock"
        }
        
    def _aggregate_results(self, results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Aggregate weather data from multiple sources"""
        if not results:
            return {}
            
        # Calculate averages for numeric fields
        aggregated = {
            "temperature": round(sum(r.get("temperature", 0) for r in results) / len(results), 1),
            "feels_like": round(sum(r.get("feels_like", 0) for r in results) / len(results), 1),
            "humidity": round(sum(r.get("humidity", 0) for r in results) / len(results)),
            "pressure": round(sum(r.get("pressure", 0) for r in results) / len(results)),
            "wind_speed": round(sum(r.get("wind_speed", 0) for r in results) / len(results), 1),
            "wind_direction": round(sum(r.get("wind_direction", 0) for r in results) / len(results)),
            "sources": [r.get("source", "unknown") for r in results],
            "description": results[0].get("description", "Unknown")  # Use first source's description
        }
        
        return aggregated
        
    def _is_api_key_configured(self, source: str) -> bool:
        """Check if API key is configured for a given source"""
        if source == "openweathermap":
            return bool(settings.OPENWEATHER_API_KEY)
        elif source == "weatherapi":
            return bool(settings.WEATHERAPI_KEY)
        return False