"""
Microservice Demo Application
FastAPI-based REST API with health checks, metrics, and tracing
"""
import asyncio
import logging
import os
import time
from contextlib import asynccontextmanager
from typing import Dict, Any

from fastapi import FastAPI, Response, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
import structlog

from config import settings
from models import HelloResponse, HealthResponse

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
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')
ACTIVE_REQUESTS = Gauge('http_requests_in_flight', 'Active HTTP requests')
APPLICATION_READY = Gauge('application_ready', 'Application readiness status')
APPLICATION_HEALTHY = Gauge('application_healthy', 'Application health status')

# Application state
app_state = {
    "startup_time": time.time(),
    "ready": False,
    "healthy": True,
    "version": "1.0.0"
}

def setup_tracing():
    """Configure OpenTelemetry tracing"""
    if settings.TRACING_ENABLED:
        resource = Resource(attributes={
            SERVICE_NAME: "microservice-demo"
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

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    logger.info("Starting microservice demo application", version=app_state["version"])
    setup_tracing()
    
    # Simulate startup delay
    await asyncio.sleep(2)
    app_state["ready"] = True
    APPLICATION_READY.set(1)
    APPLICATION_HEALTHY.set(1)
    
    logger.info("Application ready", startup_time=app_state["startup_time"])
    
    yield
    
    # Shutdown
    logger.info("Shutting down application")
    app_state["ready"] = False
    APPLICATION_READY.set(0)

# Create FastAPI application
app = FastAPI(
    title="Microservice Demo",
    description="A demo microservice with health checks, metrics, and tracing",
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

# API endpoints
@app.get("/api/v1/hello", response_model=HelloResponse, tags=["API"])
async def hello_world(name: str = "World"):
    """Hello world API endpoint"""
    tracer = trace.get_tracer(__name__)
    
    with tracer.start_as_current_span("hello_request") as span:
        span.set_attribute("user.name", name)
        
        logger.info("Hello request received", name=name)
        
        response = HelloResponse(
            message=f"Hello, {name}!",
            timestamp=time.time(),
            version=app_state["version"]
        )
        
        span.set_attribute("response.message", response.message)
        
        return response

@app.get("/api/v1/status", tags=["API"])
async def application_status():
    """Application status endpoint"""
    return {
        "application": "microservice-demo",
        "version": app_state["version"],
        "status": "running" if app_state["ready"] else "starting",
        "uptime": time.time() - app_state["startup_time"],
        "environment": settings.ENVIRONMENT,
        "log_level": settings.LOG_LEVEL
    }

# Admin endpoints
@app.post("/admin/health/toggle", tags=["Admin"])
async def toggle_health():
    """Toggle application health status (for testing)"""
    app_state["healthy"] = not app_state["healthy"]
    APPLICATION_HEALTHY.set(1 if app_state["healthy"] else 0)
    
    logger.warning("Health status toggled", healthy=app_state["healthy"])
    
    return {"healthy": app_state["healthy"]}

@app.get("/", tags=["Root"])
async def root():
    """Root endpoint"""
    return {
        "service": "microservice-demo",
        "version": app_state["version"],
        "endpoints": {
            "health": "/healthz",
            "readiness": "/ready",
            "metrics": "/metrics",
            "api": "/api/v1/hello",
            "docs": "/docs"
        }
    }

if __name__ == "__main__":
    import uvicorn
    import asyncio
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=settings.PORT,
        log_level=settings.LOG_LEVEL.lower(),
        reload=settings.ENVIRONMENT == "development"
    ) 