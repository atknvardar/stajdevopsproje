"""
Microservice Demo Application
FastAPI-based REST API with health checks, metrics, and tracing
"""
import asyncio
import logging
import os
import time
import math
from contextlib import asynccontextmanager
from typing import Dict, Any
import threading
import random
import gc
from datetime import datetime, timedelta

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

# Chaos Engineering State
chaos_state = {
    "memory_leak_active": False,
    "slow_responses_active": False,
    "error_injection_active": False,
    "cpu_spike_active": False,
    "memory_objects": [],
    "chaos_history": []
}

# Chaos Engineering Metrics
chaos_events_counter = Counter('chaos_events_total', 'Total number of chaos events', ['chaos_type', 'event_type'])
chaos_healing_counter = Counter('chaos_healing_total', 'Total number of healing events', ['chaos_type', 'source'])
chaos_memory_usage = Gauge('chaos_memory_usage_mb', 'Current memory usage from chaos scenarios')
healing_reports_storage = []

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

@app.post("/admin/chaos/inject", tags=["chaos"])
async def inject_chaos(chaos_type: str = "random"):
    """
    🔴 CHAOS ENGINEERING: Inject problems into the system
    
    Available chaos types:
    - memory_leak: Gradual memory consumption increase
    - slow_responses: Artificial delays in responses  
    - error_injection: Random 500 errors
    - cpu_spike: High CPU usage burst
    - random: Randomly select one of the above
    """
    if not app_state["healthy"]:
        raise HTTPException(status_code=503, detail="Service unhealthy, chaos injection disabled")
    
    if chaos_type == "random":
        chaos_type = random.choice(["memory_leak", "slow_responses", "error_injection", "cpu_spike"])
    
    result = {"chaos_type": chaos_type, "status": "activated", "timestamp": datetime.now().isoformat()}
    
    if chaos_type == "memory_leak":
        if not chaos_state["memory_leak_active"]:
            chaos_state["memory_leak_active"] = True
            threading.Thread(target=memory_leak_thread, daemon=True).start()
            log_chaos_event("memory_leak", "Memory leak injection started")
            result["details"] = "Memory leak started - will consume ~1MB/second"
        else:
            result["status"] = "already_active"
            
    elif chaos_type == "slow_responses":
        chaos_state["slow_responses_active"] = True
        log_chaos_event("slow_responses", "Slow response injection activated")
        result["details"] = "Response delays activated - 2-5 second delays"
        
    elif chaos_type == "error_injection":
        chaos_state["error_injection_active"] = True
        log_chaos_event("error_injection", "Error injection activated")
        result["details"] = "Random 500 errors activated - 30% failure rate"
        
    elif chaos_type == "cpu_spike":
        if not chaos_state["cpu_spike_active"]:
            chaos_state["cpu_spike_active"] = True
            threading.Thread(target=cpu_spike_thread, daemon=True).start()
            log_chaos_event("cpu_spike", "CPU spike injection started")
            result["details"] = "CPU spike started - 30 seconds of high CPU usage"
        else:
            result["status"] = "already_active"
    else:
        raise HTTPException(status_code=400, detail=f"Unknown chaos type: {chaos_type}")
    
    return result

@app.post("/admin/chaos/heal", tags=["chaos"])
async def heal_chaos():
    """
    ✅ CHAOS HEALING: Stop all chaos engineering problems
    """
    healing_actions = []
    
    if chaos_state["memory_leak_active"]:
        chaos_state["memory_leak_active"] = False
        chaos_state["memory_objects"].clear()
        gc.collect()  # Force garbage collection
        healing_actions.append("memory_leak_stopped")
        log_chaos_event("healing", "Memory leak stopped and memory cleared")
    
    if chaos_state["slow_responses_active"]:
        chaos_state["slow_responses_active"] = False
        healing_actions.append("slow_responses_stopped")
        log_chaos_event("healing", "Slow responses disabled")
    
    if chaos_state["error_injection_active"]:
        chaos_state["error_injection_active"] = False
        healing_actions.append("error_injection_stopped")
        log_chaos_event("healing", "Error injection disabled")
    
    if chaos_state["cpu_spike_active"]:
        chaos_state["cpu_spike_active"] = False
        healing_actions.append("cpu_spike_stopped")
        log_chaos_event("healing", "CPU spike stopped")
    
    return {
        "status": "healed",
        "actions_taken": healing_actions,
        "timestamp": datetime.now().isoformat(),
        "message": "All chaos scenarios stopped"
    }

@app.get("/admin/chaos/status", tags=["chaos"])
async def chaos_status():
    """
    📊 Get current chaos engineering status
    """
    active_chaos = []
    if chaos_state["memory_leak_active"]:
        active_chaos.append("memory_leak")
    if chaos_state["slow_responses_active"]:
        active_chaos.append("slow_responses")
    if chaos_state["error_injection_active"]:
        active_chaos.append("error_injection")
    if chaos_state["cpu_spike_active"]:
        active_chaos.append("cpu_spike")
    
    return {
        "active_chaos": active_chaos,
        "chaos_count": len(active_chaos),
        "memory_objects_count": len(chaos_state["memory_objects"]),
        "recent_events": chaos_state["chaos_history"][-10:],  # Last 10 events
        "system_impact": {
            "any_chaos_active": len(active_chaos) > 0,
            "estimated_memory_usage_mb": len(chaos_state["memory_objects"]),
            "performance_degraded": chaos_state["slow_responses_active"] or chaos_state["cpu_spike_active"]
        }
    }

@app.post("/admin/healing-report", tags=["chaos"])
async def store_healing_report(report: dict):
    """
    📤 Store healing report from n8n workflow
    """
    report["stored_at"] = datetime.now().isoformat()
    healing_reports_storage.append(report)
    
    # Keep only last 100 reports
    if len(healing_reports_storage) > 100:
        healing_reports_storage[:] = healing_reports_storage[-100:]
    
    # Update metrics
    chaos_type = report.get("original_alert", {}).get("chaos_type", "unknown")
    chaos_healing_counter.labels(chaos_type=chaos_type, source="n8n_workflow").inc()
    
    log_chaos_event("healing_report", f"Stored healing report for {chaos_type}")
    
    return {
        "status": "stored",
        "report_id": report.get("workflow_id"),
        "chaos_type": chaos_type,
        "timestamp": report["stored_at"]
    }

@app.get("/admin/healing-reports", tags=["chaos"])
async def get_healing_reports():
    """
    📊 Get all stored healing reports
    """
    return {
        "total_reports": len(healing_reports_storage),
        "reports": healing_reports_storage[-10:],  # Last 10 reports
        "summary": {
            "successful_healings": len([r for r in healing_reports_storage if r.get("overall_status") == "success"]),
            "partial_healings": len([r for r in healing_reports_storage if r.get("overall_status") == "partial_success"]),
            "failed_healings": len([r for r in healing_reports_storage if r.get("overall_status") == "failed"])
        }
    }

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

# Add chaos middleware to inject problems into responses
@app.middleware("http")
async def chaos_middleware(request: Request, call_next):
    """Middleware to inject chaos into responses"""
    
    # Skip chaos for admin and monitoring endpoints
    if request.url.path.startswith(("/admin", "/healthz", "/ready", "/metrics")):
        response = await call_next(request)
        return response
    
    # Error injection chaos
    if chaos_state["error_injection_active"] and random.random() < 0.3:  # 30% chance
        log_chaos_event("error_injection", f"Injected 500 error for {request.url.path}")
        raise HTTPException(status_code=500, detail="Chaos-induced server error")
    
    # Slow response chaos
    if chaos_state["slow_responses_active"]:
        delay = random.uniform(2, 5)  # 2-5 second delay
        await asyncio.sleep(delay)
        log_chaos_event("slow_responses", f"Injected {delay:.2f}s delay for {request.url.path}")
    
    response = await call_next(request)
    return response

def log_chaos_event(event_type: str, details: str):
    """Log chaos engineering events"""
    chaos_state["chaos_history"].append({
        "timestamp": datetime.now().isoformat(),
        "event_type": event_type,
        "details": details
    })
    # Keep only last 50 events
    if len(chaos_state["chaos_history"]) > 50:
        chaos_state["chaos_history"] = chaos_state["chaos_history"][-50:]
    
    # Update Prometheus metrics
    chaos_events_counter.labels(chaos_type="general", event_type=event_type).inc()
    
    # Update memory usage gauge
    chaos_memory_usage.set(len(chaos_state["memory_objects"]))

def memory_leak_thread():
    """Create a memory leak by allocating objects"""
    while chaos_state["memory_leak_active"]:
        # Allocate 1MB of data every second
        data = ["x" * 1024 for _ in range(1024)]
        chaos_state["memory_objects"].append(data)
        time.sleep(1)
        if len(chaos_state["memory_objects"]) > 100:  # Limit to ~100MB
            chaos_state["memory_objects"] = chaos_state["memory_objects"][-50:]

def cpu_spike_thread():
    """Create CPU spike by running intensive calculations"""
    end_time = time.time() + 30  # Run for 30 seconds
    while chaos_state["cpu_spike_active"] and time.time() < end_time:
        # Intensive calculation
        for i in range(100000):
            math.sqrt(i * random.random())
    chaos_state["cpu_spike_active"] = False

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