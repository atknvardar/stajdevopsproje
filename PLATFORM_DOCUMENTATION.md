# OpenShift Microservices Platform - Complete Documentation

## 🏗️ Platform Architecture

### Overview
Production-ready microservices platform on OpenShift with complete DevOps lifecycle implementation.

### Components Deployed

#### 1. **Microservice Application**
- **Weather API**: RESTful microservice with health checks
- **Deployment**: 2 replicas with auto-scaling (2-10 pods)
- **Service**: ClusterIP service on port 8080
- **Route**: TLS-enabled external access
- **ConfigMap**: Environment configuration
- **ServiceAccount**: RBAC-enabled service account

#### 2. **CI/CD Pipeline**
- **BuildConfig**: Native OpenShift builds from Git
- **ImageStream**: Container image management
- **Pipeline Operator**: OpenShift Pipelines (Tekton) subscription
- **Build Triggers**: Webhook and configuration change triggers

#### 3. **Monitoring Stack**
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization dashboards
- **Service Discovery**: Automatic pod discovery via annotations

#### 4. **Logging Stack (EFK)**
- **Elasticsearch**: Log storage and indexing
- **Fluentd**: Log collection from all pods
- **Kibana**: Log visualization and search

#### 5. **Resource Management**
- **ResourceQuota**: CPU/Memory limits per namespace
- **LimitRange**: Default container resource constraints
- **HorizontalPodAutoscaler**: CPU/Memory based auto-scaling

## 📋 Access URLs

### Applications
- **Weather API**: https://weather-api-microservices-dev.apps-crc.testing
- **OpenShift Console**: https://console-openshift-console.apps-crc.testing

### Monitoring
- **Prometheus**: https://prometheus-microservices-monitoring.apps-crc.testing
- **Grafana**: https://grafana-microservices-monitoring.apps-crc.testing (admin/admin)
- **Kibana**: https://kibana-microservices-monitoring.apps-crc.testing

## 🚀 Quick Start Guide

### 1. Check Platform Status
```bash
./view-platform.sh
```

### 2. View Application Logs
```bash
oc logs -f deployment/weather-api -n microservices-dev
```

### 3. Trigger New Build
```bash
oc start-build weather-api-build -n microservices-cicd
```

### 4. Scale Application
```bash
oc scale deployment/weather-api --replicas=5 -n microservices-dev
```

### 5. View Metrics
```bash
oc exec -n microservices-monitoring deployment/prometheus -- wget -qO- http://localhost:9090/api/v1/targets
```

## 📊 Namespace Structure

| Namespace | Purpose | Key Resources |
|-----------|---------|---------------|
| microservices-dev | Development environment | Weather API deployment |
| microservices-stage | Staging environment | (Ready for deployment) |
| microservices-prod | Production environment | (Ready for deployment) |
| microservices-cicd | CI/CD tools | BuildConfigs, Pipelines |
| microservices-monitoring | Observability stack | Prometheus, Grafana, EFK |

## 🔒 Security Configuration

### RBAC Setup
- **ServiceAccount**: `microservice-sa` with edit permissions
- **ClusterRole**: Prometheus with pod/service read access
- **ResourceQuota**: Namespace resource limits enforced

### Network Security
- **TLS Routes**: All external routes use edge termination
- **Pod Security**: Running with restricted SCC where possible

## 📈 Resource Limits

### Development Environment
- **CPU Request**: 4 cores total
- **CPU Limit**: 8 cores total
- **Memory Request**: 8Gi total
- **Memory Limit**: 16Gi total
- **PVC Limit**: 10 volumes

### Per Container Defaults
- **CPU Request**: 200m
- **CPU Limit**: 500m
- **Memory Request**: 256Mi
- **Memory Limit**: 512Mi

## 🛠️ Maintenance Commands

### Health Checks
```bash
# Check all pods
oc get pods --all-namespaces | grep microservices

# Check resource usage
oc adm top pods -n microservices-dev

# Check build status
oc get builds -n microservices-cicd
```

### Troubleshooting
```bash
# View pod events
oc describe pod <pod-name> -n microservices-dev

# Check logs
oc logs <pod-name> -n microservices-dev --previous

# Access pod shell
oc exec -it <pod-name> -n microservices-dev -- /bin/bash
```

## 📝 CI/CD Workflow

1. **Code Push** → Git repository
2. **Webhook Trigger** → OpenShift BuildConfig
3. **Build Process** → Docker build in OpenShift
4. **Image Push** → Internal registry
5. **Deployment** → Rolling update to pods
6. **Health Check** → Readiness/Liveness probes
7. **Monitoring** → Metrics exposed to Prometheus

## 🎯 Key Features Implemented

✅ **Microservice Architecture**: Containerized REST API  
✅ **CI/CD Pipeline**: Automated build and deploy  
✅ **Auto-scaling**: HPA based on CPU/Memory  
✅ **Monitoring**: Prometheus + Grafana dashboards  
✅ **Logging**: Centralized EFK stack  
✅ **Resource Management**: Quotas and limits  
✅ **RBAC**: Proper access controls  
✅ **Multi-environment**: Dev/Stage/Prod separation  
✅ **Health Checks**: Liveness and readiness probes  
✅ **Configuration Management**: ConfigMaps for env configs  

## 📸 Platform Validation

Run the complete validation:
```bash
./validate-platform.sh
```

This will check:
- All pods are running
- Routes are accessible
- Metrics are being collected
- Logs are being aggregated
- Resource limits are enforced