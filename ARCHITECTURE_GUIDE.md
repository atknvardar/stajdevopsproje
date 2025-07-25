# OpenShift Weather App - Complete Architecture Guide

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            OpenShift Cluster (CRC)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌──────────────────┐  │
│  │   weather-app NS    │  │  logging-lite NS    │  │  openshift-*     │  │
│  │                     │  │                     │  │   (System NS)     │  │
│  │  ┌───────────────┐  │  │  ┌──────────────┐  │  │                  │  │
│  │  │  Weather App  │  │  │  │     Loki     │  │  │  ┌────────────┐  │  │
│  │  │   (FastAPI)   │  │  │  │  (Log Store) │  │  │  │ Prometheus │  │  │
│  │  └───────┬───────┘  │  │  └──────▲───────┘  │  │  └──────▲─────┘  │  │
│  │          │          │  │         │           │  │         │        │  │
│  │  ┌───────▼───────┐  │  │  ┌─────┴────────┐  │  │         │        │  │
│  │  │    Service    │  │  │  │   Promtail   │  │  │  ┌──────┴─────┐  │  │
│  │  │  (ClusterIP)  │  │  │  │ (Log Shipper)│  │  │  │   Metrics  │  │  │
│  │  └───────┬───────┘  │  │  └──────────────┘  │  │  │  Exporter  │  │  │
│  │          │          │  │                     │  │  └────────────┘  │  │
│  │  ┌───────▼───────┐  │  │  ┌──────────────┐  │  │                  │  │
│  │  │     Route     │  │  │  │   Grafana    │  │  │                  │  │
│  │  │   (Ingress)   │  │  │  │ (Dashboards) │  │  │                  │  │
│  │  └───────────────┘  │  │  └──────────────┘  │  │                  │  │
│  └─────────────────────┘  └─────────────────────┘  └──────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
                              External Access via Routes
                    weather-app-weather-app.apps-crc.testing
                    grafana-logging-lite.apps-crc.testing
```

## 📚 Component Deep Dive

### 1. Application Layer

#### Weather App (Microservice)
- **Technology**: Python FastAPI
- **Purpose**: RESTful API for weather data aggregation
- **Key Features**:
  - Multiple weather source integration
  - JSON structured logging
  - Health checks and metrics endpoints
  - Environment-based configuration

```python
# Main endpoints:
GET /                        # Service info
GET /healthz                 # Health check
GET /ready                   # Readiness check
GET /metrics                 # Prometheus metrics
GET /api/v1/weather/current  # Current weather data
GET /api/v1/weather/aggregated # Aggregated weather
```

### 2. Container Layer

#### Docker Configuration
```dockerfile
# Multi-stage build for optimization
FROM python:3.11-slim as builder
# Dependencies installation
FROM python:3.11-slim
# Security: Non-root user
USER appuser
# Health check
HEALTHCHECK CMD curl -f http://localhost:8080/healthz
```

### 3. OpenShift Resources

#### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: weather-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: weather-app
  template:
    spec:
      containers:
      - name: weather-app
        image: weather-app:latest
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
```

#### Service & Route
```yaml
# Service - Internal load balancing
apiVersion: v1
kind: Service
metadata:
  name: weather-app
spec:
  selector:
    app: weather-app
  ports:
  - port: 8080
    targetPort: 8080

# Route - External access
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: weather-app
spec:
  to:
    kind: Service
    name: weather-app
  tls:
    termination: edge
```

### 4. CI/CD Pipeline

#### Build Process
```
┌────────────┐    ┌─────────────┐    ┌──────────────┐    ┌────────────┐
│ Git Push   │───▶│ Webhook     │───▶│ BuildConfig  │───▶│ ImageStream│
└────────────┘    └─────────────┘    └──────────────┘    └────────────┘
                                              │
                                              ▼
                                      ┌──────────────┐
                                      │ Deployment   │
                                      │   Trigger    │
                                      └──────────────┘
```

#### Pipeline Stages (Tekton/OpenShift Pipelines)
1. **Clone Repository**
2. **Run Tests** (Unit, Integration)
3. **Security Scan** (Bandit for Python)
4. **Build Image**
5. **Push to Registry**
6. **Deploy to Environment**
7. **Run Health Checks**

### 5. Monitoring Stack

#### Prometheus Configuration
```yaml
# ServiceMonitor for metrics collection
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: weather-app-monitor
spec:
  selector:
    matchLabels:
      app: weather-app
  endpoints:
  - port: web
    interval: 30s
    path: /metrics
```

#### Key Metrics
- Request rate and latency
- Error rate
- Resource usage (CPU/Memory)
- Application-specific metrics

### 6. Logging Stack

#### Loki + Promtail + Grafana
```
┌──────────┐     ┌──────────┐     ┌─────────┐     ┌─────────┐
│   Apps   │────▶│ Promtail │────▶│  Loki   │◀────│ Grafana │
│  (Logs)  │     │(Collector)│     │(Storage)│     │  (UI)   │
└──────────┘     └──────────┘     └─────────┘     └─────────┘
```

#### Log Format (Structured JSON)
```json
{
  "timestamp": "2024-01-24T12:00:00Z",
  "level": "INFO",
  "logger": "weather_service",
  "event": "Weather data fetched",
  "source": "openweather",
  "latency_ms": 234
}
```

### 7. Security & Governance

#### RBAC Configuration
```yaml
# ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: weather-app-sa

# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: weather-app-view
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: weather-app-sa
```

#### Resource Management
```yaml
# ResourceQuota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: weather-app-quota
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "10"

# HorizontalPodAutoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: weather-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: weather-app
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## 🎓 Step-by-Step Learning Path

### Step 1: Understanding the Application
1. **Explore the code**: `app/main.py`
2. **Run locally**: `docker-compose up`
3. **Test endpoints**: Use curl or Postman

### Step 2: Container Basics
1. **Build image**: `docker build -t weather-app .`
2. **Run container**: `docker run -p 8080:8080 weather-app`
3. **Check logs**: `docker logs <container-id>`

### Step 3: OpenShift Deployment
1. **Login**: `oc login -u developer`
2. **Create project**: `oc new-project weather-app`
3. **Deploy**: `oc apply -k openshift/base/`
4. **Check status**: `oc get all`

### Step 4: CI/CD Pipeline
1. **View BuildConfig**: `oc get bc`
2. **Start build**: `oc start-build weather-app`
3. **Follow logs**: `oc logs -f bc/weather-app`

### Step 5: Monitoring
1. **Access Grafana**: https://grafana-logging-lite.apps-crc.testing
2. **Import dashboard**: Use provided JSON
3. **Create alerts**: Based on metrics

### Step 6: Troubleshooting
```bash
# Check pod logs
oc logs <pod-name>

# Describe pod for events
oc describe pod <pod-name>

# Execute into pod
oc exec -it <pod-name> -- /bin/bash

# Check resource usage
oc top pods

# View events
oc get events --sort-by=.metadata.creationTimestamp
```

## 🔧 Configuration Management

### Environment Variables
```yaml
env:
- name: LOG_LEVEL
  value: "INFO"
- name: ENVIRONMENT
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: environment
```

### ConfigMaps
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  environment: "production"
  api_timeout: "30"
  cache_ttl: "300"
```

### Secrets (for sensitive data)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-keys
type: Opaque
stringData:
  openweather_key: "your-api-key"
  weatherapi_key: "your-api-key"
```

## 📊 Best Practices

### 1. **12-Factor App Principles**
- Config in environment
- Stateless processes
- Port binding
- Disposability

### 2. **Container Best Practices**
- Minimal base images
- Non-root user
- Health checks
- Resource limits

### 3. **OpenShift Best Practices**
- Use ImageStreams
- Implement proper RBAC
- Set resource quotas
- Use liveness/readiness probes

### 4. **Security**
- Regular vulnerability scans
- Network policies
- Pod security standards
- Secret management

## 🚀 Next Steps

1. **Implement GitOps**: Use ArgoCD or Flux
2. **Add Service Mesh**: Istio/OpenShift Service Mesh
3. **Implement Backup**: Velero for disaster recovery
4. **Advanced Monitoring**: Custom metrics and dashboards
5. **Multi-cluster**: Federation and multi-region deployment

## 📖 Resources

- [OpenShift Documentation](https://docs.openshift.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Container Security Guide](https://www.redhat.com/en/topics/security/container-security)

---

This architecture provides a production-ready microservice deployment with full observability, security, and scalability features on OpenShift.