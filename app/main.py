"""
Real-Time Weather Data Aggregator
FastAPI-based microservice for aggregating weather data from multiple sources
"""
import asyncio
import logging
import os
import time
from contextlib import asynccontextmanager
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import statistics

from fastapi import FastAPI, Response, HTTPException, Request, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST, CollectorRegistry, REGISTRY
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
import structlog
import httpx
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger

from config import settings
from models import (
    WeatherData, WeatherResponse, AggregatedWeatherResponse,
    WeatherTrendResponse, HealthResponse, WeatherAPIStatus,
    DataQualityMetrics
)
from weather_service import WeatherService

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Prometheus metrics
def create_or_get_metric(metric_class, name, description, labelnames=None, registry=REGISTRY):
    """Create a metric or return existing one if already registered"""
    try:
        if labelnames:
            return metric_class(name, description, labelnames, registry=registry)
        else:
            return metric_class(name, description, registry=registry)
    except ValueError as e:
        if "Duplicated timeseries" in str(e):
            for collector in registry._collector_to_names:
                if hasattr(collector, '_name') and collector._name == name:
                    return collector
            test_registry = CollectorRegistry()
            if labelnames:
                return metric_class(name, description, labelnames, registry=test_registry)
            else:
                return metric_class(name, description, registry=test_registry)
        raise

# HTTP metrics
REQUEST_COUNT = create_or_get_metric(Counter, 'http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = create_or_get_metric(Histogram, 'http_request_duration_seconds', 'HTTP request duration')
ACTIVE_REQUESTS = create_or_get_metric(Gauge, 'http_requests_in_flight', 'Active HTTP requests')

# Weather API metrics
WEATHER_API_REQUESTS = create_or_get_metric(Counter, 'weather_api_requests_total', 'Total weather API requests', ['api', 'status'])
WEATHER_API_RESPONSE_TIME = create_or_get_metric(Histogram, 'weather_api_response_seconds', 'Weather API response time', ['api'])
WEATHER_API_FAILURES = create_or_get_metric(Counter, 'weather_api_failures_total', 'Total weather API failures', ['api', 'error_type'])
WEATHER_API_RATE_LIMIT = create_or_get_metric(Gauge, 'weather_api_rate_limit_remaining', 'Remaining API rate limit', ['api'])

# Data processing metrics
DATA_PROCESSING_TIME = create_or_get_metric(Histogram, 'weather_data_processing_seconds', 'Time to process weather data')
DATA_QUALITY_SCORE = create_or_get_metric(Gauge, 'weather_data_quality_score', 'Data quality score (0-100)')
ACTIVE_LOCATIONS = create_or_get_metric(Gauge, 'weather_active_locations', 'Number of actively monitored locations')
CACHED_DATA_SIZE = create_or_get_metric(Gauge, 'weather_cached_data_size', 'Size of cached weather data')

# Application metrics
APPLICATION_READY = create_or_get_metric(Gauge, 'application_ready', 'Application readiness status')
APPLICATION_HEALTHY = create_or_get_metric(Gauge, 'application_healthy', 'Application health status')

# Application state
app_state = {
    "startup_time": time.time(),
    "ready": False,
    "healthy": True,
    "version": "2.2.2",
    "weather_cache": {},
    "api_health": {},
    "data_quality_metrics": {}
}

# Weather service instance
weather_service = None

# Scheduler for background tasks
scheduler = AsyncIOScheduler()

def setup_tracing():
    """Configure OpenTelemetry tracing"""
    if settings.TRACING_ENABLED:
        resource = Resource(attributes={
            SERVICE_NAME: "weather-aggregator"
        })
        
        provider = TracerProvider(resource=resource)
        
        if settings.JAEGER_ENDPOINT:
            jaeger_exporter = JaegerExporter(
                agent_host_name=settings.JAEGER_ENDPOINT,
                agent_port=6831,
            )
            span_processor = BatchSpanProcessor(jaeger_exporter)
            provider.add_span_processor(span_processor)
        
        trace.set_tracer_provider(provider)

async def fetch_weather_periodically():
    """Background task to fetch weather data periodically"""
    logger.info("Starting periodic weather data fetch")
    
    try:
        # Fetch weather for configured locations
        for location in settings.DEFAULT_LOCATIONS:
            try:
                weather_data = await weather_service.get_aggregated_weather(
                    location["lat"], 
                    location["lon"]
                )
                
                # Cache the data
                cache_key = f"{location['lat']},{location['lon']}"
                app_state["weather_cache"][cache_key] = {
                    "data": weather_data,
                    "timestamp": datetime.now(),
                    "location_name": location.get("name", "Unknown")
                }
                
                # Update metrics
                ACTIVE_LOCATIONS.set(len(app_state["weather_cache"]))
                CACHED_DATA_SIZE.set(len(str(app_state["weather_cache"])))
                
            except Exception as e:
                logger.error(f"Failed to fetch weather for location {location}", error=str(e))
                
    except Exception as e:
        logger.error("Error in periodic weather fetch", error=str(e))

async def monitor_api_health():
    """Monitor health of weather APIs"""
    logger.info("Checking weather API health")
    
    try:
        health_status = await weather_service.check_api_health()
        app_state["api_health"] = health_status
        
        # Update rate limit metrics
        for api, status in health_status.items():
            if status.get("rate_limit_remaining") is not None:
                WEATHER_API_RATE_LIMIT.labels(api=api).set(status["rate_limit_remaining"])
                
    except Exception as e:
        logger.error("Error monitoring API health", error=str(e))

async def calculate_data_quality():
    """Calculate and update data quality metrics"""
    try:
        if app_state["weather_cache"]:
            # Calculate quality metrics
            total_score = 0
            metrics = {
                "completeness": 0,
                "freshness": 0,
                "consistency": 0,
                "availability": 0
            }
            
            for cache_key, cache_data in app_state["weather_cache"].items():
                data = cache_data["data"]
                timestamp = cache_data["timestamp"]
                
                # Completeness: Check if all expected fields are present
                expected_fields = ["temperature", "humidity", "pressure", "wind_speed"]
                present_fields = sum(1 for field in expected_fields if data.get(field) is not None)
                completeness = (present_fields / len(expected_fields)) * 100
                
                # Freshness: Data should be less than 10 minutes old
                age = (datetime.now() - timestamp).total_seconds()
                freshness = max(0, 100 - (age / 600) * 100)
                
                # Add to totals
                metrics["completeness"] += completeness
                metrics["freshness"] += freshness
                
            # Average the metrics
            num_locations = len(app_state["weather_cache"])
            for key in metrics:
                metrics[key] /= num_locations
                
            # Calculate overall score
            overall_score = sum(metrics.values()) / len(metrics)
            DATA_QUALITY_SCORE.set(overall_score)
            
            app_state["data_quality_metrics"] = {
                "overall_score": overall_score,
                "metrics": metrics,
                "last_updated": datetime.now().isoformat()
            }
            
    except Exception as e:
        logger.error("Error calculating data quality", error=str(e))

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    global weather_service
    
    # Startup
    logger.info("Starting weather data aggregator", version=app_state["version"])
    setup_tracing()
    
    # Initialize weather service
    weather_service = WeatherService()
    
    # Start scheduler
    scheduler.add_job(
        fetch_weather_periodically,
        IntervalTrigger(seconds=settings.WEATHER_FETCH_INTERVAL),
        id="weather_fetch",
        replace_existing=True
    )
    
    scheduler.add_job(
        monitor_api_health,
        IntervalTrigger(seconds=300),  # Every 5 minutes
        id="api_health_check",
        replace_existing=True
    )
    
    scheduler.add_job(
        calculate_data_quality,
        IntervalTrigger(seconds=60),  # Every minute
        id="data_quality_check",
        replace_existing=True
    )
    
    scheduler.start()
    
    # Simulate startup delay
    await asyncio.sleep(2)
    app_state["ready"] = True
    APPLICATION_READY.set(1)
    APPLICATION_HEALTHY.set(1)
    
    logger.info("Application ready", startup_time=app_state["startup_time"])
    
    yield
    
    # Shutdown
    logger.info("Shutting down application")
    scheduler.shutdown()
    app_state["ready"] = False
    APPLICATION_READY.set(0)

# Create FastAPI application
app = FastAPI(
    title="Weather Data Aggregator",
    description="Real-time weather data aggregation from multiple sources",
    version=app_state["version"],
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Instrument FastAPI with OpenTelemetry
if settings.TRACING_ENABLED:
    FastAPIInstrumentor.instrument_app(app)

@app.middleware("http")
async def metrics_middleware(request, call_next):
    """Middleware to collect Prometheus metrics"""
    start_time = time.time()
    ACTIVE_REQUESTS.inc()
    
    try:
        response = await call_next(request)
        duration = time.time() - start_time
        
        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=request.url.path,
            status=response.status_code
        ).inc()
        
        REQUEST_DURATION.observe(duration)
        
        return response
    finally:
        ACTIVE_REQUESTS.dec()

# Health check endpoints
@app.get("/healthz", response_model=HealthResponse, tags=["Health"])
async def liveness_check():
    """Liveness probe endpoint"""
    logger.debug("Liveness check requested")
    
    if not app_state["healthy"]:
        raise HTTPException(status_code=503, detail="Application unhealthy")
    
    return HealthResponse(
        status="healthy",
        timestamp=time.time(),
        version=app_state["version"]
    )

@app.get("/ready", response_model=HealthResponse, tags=["Health"])
async def readiness_check():
    """Readiness probe endpoint"""
    logger.debug("Readiness check requested")
    
    if not app_state["ready"]:
        raise HTTPException(status_code=503, detail="Application not ready")
    
    return HealthResponse(
        status="ready",
        timestamp=time.time(),
        version=app_state["version"],
        uptime=time.time() - app_state["startup_time"]
    )

# Metrics endpoint
@app.get("/metrics", tags=["Monitoring"])
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )

# Weather API endpoints
@app.get("/api/v1/weather/current", response_model=WeatherResponse, tags=["Weather"])
async def get_current_weather(lat: float, lon: float):
    """Get current weather for a specific location"""
    tracer = trace.get_tracer(__name__)
    
    with tracer.start_as_current_span("get_weather") as span:
        span.set_attribute("location.lat", lat)
        span.set_attribute("location.lon", lon)
        
        try:
            # Check cache first
            cache_key = f"{lat},{lon}"
            if cache_key in app_state["weather_cache"]:
                cached = app_state["weather_cache"][cache_key]
                if (datetime.now() - cached["timestamp"]).seconds < settings.CACHE_TTL:
                    logger.info("Returning cached weather data", location=cache_key)
                    return WeatherResponse(
                        location={"lat": lat, "lon": lon, "name": cached.get("location_name", "")},
                        data=cached["data"],
                        timestamp=cached["timestamp"].isoformat(),
                        source="cache"
                    )
            
            # Fetch fresh data
            weather_data = await weather_service.get_aggregated_weather(lat, lon)
            
            # Update cache
            app_state["weather_cache"][cache_key] = {
                "data": weather_data,
                "timestamp": datetime.now()
            }
            
            return WeatherResponse(
                location={"lat": lat, "lon": lon},
                data=weather_data,
                timestamp=datetime.now().isoformat(),
                source="api"
            )
            
        except Exception as e:
            logger.error("Failed to get weather data", error=str(e))
            raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/weather/aggregated", response_model=AggregatedWeatherResponse, tags=["Weather"])
async def get_aggregated_weather(lat: float, lon: float):
    """Get aggregated weather data from all sources"""
    try:
        all_data = await weather_service.get_all_sources_data(lat, lon)
        
        # Calculate aggregated values
        temps = [d["temperature"] for d in all_data.values() if d.get("temperature")]
        humidities = [d["humidity"] for d in all_data.values() if d.get("humidity")]
        
        aggregated = {
            "temperature": statistics.mean(temps) if temps else None,
            "temperature_min": min(temps) if temps else None,
            "temperature_max": max(temps) if temps else None,
            "humidity": statistics.mean(humidities) if humidities else None,
            "sources_count": len(all_data),
            "sources": list(all_data.keys())
        }
        
        return AggregatedWeatherResponse(
            location={"lat": lat, "lon": lon},
            aggregated_data=aggregated,
            source_data=all_data,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error("Failed to get aggregated weather data", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/weather/trends", response_model=WeatherTrendResponse, tags=["Weather"])
async def get_weather_trends(lat: float, lon: float, hours: int = 24):
    """Get weather trends for a location"""
    try:
        # For demo purposes, return mock trend data
        # In production, this would query historical data
        trends = {
            "temperature_trend": "increasing",
            "humidity_trend": "stable",
            "pressure_trend": "decreasing",
            "period_hours": hours,
            "data_points": 24
        }
        
        return WeatherTrendResponse(
            location={"lat": lat, "lon": lon},
            trends=trends,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error("Failed to get weather trends", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/weather/locations", tags=["Weather"])
async def get_monitored_locations():
    """Get list of actively monitored locations"""
    locations = []
    for cache_key, cache_data in app_state["weather_cache"].items():
        lat, lon = cache_key.split(",")
        locations.append({
            "lat": float(lat),
            "lon": float(lon),
            "name": cache_data.get("location_name", "Unknown"),
            "last_updated": cache_data["timestamp"].isoformat()
        })
    
    return {
        "locations": locations,
        "count": len(locations)
    }

# API monitoring endpoints
@app.get("/api/v1/status/apis", response_model=List[WeatherAPIStatus], tags=["Monitoring"])
async def get_api_status():
    """Get status of all weather APIs"""
    statuses = []
    for api, health in app_state["api_health"].items():
        statuses.append(WeatherAPIStatus(
            api_name=api,
            is_healthy=health.get("is_healthy", False),
            response_time_ms=health.get("response_time_ms", 0),
            error_rate=health.get("error_rate", 0),
            rate_limit_remaining=health.get("rate_limit_remaining"),
            last_checked=health.get("last_checked", datetime.now().isoformat())
        ))
    
    return statuses

@app.get("/api/v1/status/quality", response_model=DataQualityMetrics, tags=["Monitoring"])
async def get_data_quality_metrics():
    """Get data quality metrics"""
    metrics = app_state.get("data_quality_metrics", {})
    
    return DataQualityMetrics(
        overall_score=metrics.get("overall_score", 0),
        completeness=metrics.get("metrics", {}).get("completeness", 0),
        freshness=metrics.get("metrics", {}).get("freshness", 0),
        consistency=metrics.get("metrics", {}).get("consistency", 0),
        availability=metrics.get("metrics", {}).get("availability", 0),
        last_updated=metrics.get("last_updated", datetime.now().isoformat())
    )

@app.post("/api/v1/weather/refresh", tags=["Weather"])
async def refresh_weather_data(background_tasks: BackgroundTasks):
    """Manually trigger weather data refresh"""
    background_tasks.add_task(fetch_weather_periodically)
    
    return {
        "status": "refresh_initiated",
        "message": "Weather data refresh has been triggered",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/", tags=["Root"])
async def root():
    """Root endpoint"""
    return {
        "service": "weather-data-aggregator",
        "version": app_state["version"],
        "endpoints": {
            "health": "/healthz",
            "readiness": "/ready",
            "metrics": "/metrics",
            "current_weather": "/api/v1/weather/current",
            "aggregated_weather": "/api/v1/weather/aggregated",
            "weather_trends": "/api/v1/weather/trends",
            "api_status": "/api/v1/status/apis",
            "data_quality": "/api/v1/status/quality",
            "docs": "/docs"
        }
    }

@app.get("/info", tags=["Info"])
async def info():
    """Service information endpoint"""
    return {
        "service": "weather-data-aggregator",
        "version": app_state["version"],
        "build_info": {
            "environment": settings.ENVIRONMENT,
            "deployed_at": datetime.now().isoformat(),
            "features": ["weather-aggregation", "metrics", "health-checks", "caching"]
        },
        "message": "Security Fix Applied - v2.2.0"
    }

if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=settings.PORT,
        log_level=settings.LOG_LEVEL.lower(),
        reload=settings.ENVIRONMENT == "development"
    )