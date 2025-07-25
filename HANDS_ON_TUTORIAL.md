# 🚀 Hands-On OpenShift Tutorial: Weather App Deployment

## Prerequisites
- OpenShift CLI (`oc`) installed
- Access to OpenShift cluster (CRC or shared cluster)
- Git installed
- Basic knowledge of terminal commands

## 📋 Table of Contents
1. [Setting Up Your Environment](#1-setting-up-your-environment)
2. [Understanding the Application](#2-understanding-the-application)
3. [Building and Containerizing](#3-building-and-containerizing)
4. [Deploying to OpenShift](#4-deploying-to-openshift)
5. [Setting Up CI/CD](#5-setting-up-cicd)
6. [Monitoring and Logging](#6-monitoring-and-logging)
7. [Troubleshooting Guide](#7-troubleshooting-guide)

---

## 1. Setting Up Your Environment

### Step 1.1: Login to OpenShift
```bash
# Login to your OpenShift cluster
oc login -u developer -p developer https://api.crc.testing:6443

# Verify connection
oc whoami
oc version
```

### Step 1.2: Create Your Project
```bash
# Create a new project
oc new-project my-weather-app \
  --display-name="My Weather Application" \
  --description="Learning OpenShift with Weather App"

# Verify you're in the right project
oc project
```

### Step 1.3: Clone the Repository
```bash
# Clone the project
git clone <your-repo-url>
cd stajdevopsproje

# Check the structure
ls -la
```

## 2. Understanding the Application

### Step 2.1: Explore the Application Code
```bash
# Look at the main application
cat app/main.py

# Key components:
# - FastAPI application
# - Weather data aggregation from multiple sources
# - Health check endpoints
# - Prometheus metrics
```

### Step 2.2: Run Locally (Optional)
```bash
# Using Docker Compose
docker-compose up -d

# Test the application
curl http://localhost:8080/
curl http://localhost:8080/healthz

# Stop when done
docker-compose down
```

### Step 2.3: Application Architecture
```
Weather App
├── API Endpoints
│   ├── / (Service Info)
│   ├── /healthz (Health Check)
│   ├── /ready (Readiness)
│   ├── /metrics (Prometheus)
│   └── /api/v1/weather/* (Weather Data)
├── External Services
│   ├── OpenWeatherMap API
│   ├── WeatherAPI
│   └── Open-Meteo
└── Features
    ├── Caching
    ├── Error Handling
    └── Structured Logging
```

## 3. Building and Containerizing

### Step 3.1: Understanding the Dockerfile
```dockerfile
# Review the Dockerfile
cat Dockerfile

# Key concepts:
# - Multi-stage build (smaller images)
# - Non-root user (security)
# - Health checks
# - Proper layer caching
```

### Step 3.2: Build Locally
```bash
# Build the Docker image
docker build -t weather-app:local .

# Run the container
docker run -p 8080:8080 weather-app:local

# Check logs
docker logs <container-id>
```

### Step 3.3: OpenShift Build
```bash
# Create a BuildConfig using source-to-image
oc new-build --name=weather-app \
  --binary=true \
  --strategy=docker

# Start a build from local directory
oc start-build weather-app --from-dir=. --follow

# Check the build status
oc get builds
oc logs -f bc/weather-app
```

## 4. Deploying to OpenShift

### Step 4.1: Deploy Using Manifests
```bash
# Apply base resources
oc apply -k openshift/base/

# This creates:
# - Deployment
# - Service
# - Route
# - ConfigMap
# - ServiceAccount
```

### Step 4.2: Verify Deployment
```bash
# Check all resources
oc get all

# Get detailed pod information
oc get pods
oc describe pod <pod-name>

# Check logs
oc logs -f deployment/weather-app
```

### Step 4.3: Access the Application
```bash
# Get the route
oc get route
ROUTE_URL=$(oc get route weather-app -o jsonpath='{.spec.host}')

# Test the application
curl http://$ROUTE_URL/
curl http://$ROUTE_URL/healthz
curl "http://$ROUTE_URL/api/v1/weather/current?lat=51.5074&lon=-0.1278"
```

### Step 4.4: Scale the Application
```bash
# Manual scaling
oc scale deployment/weather-app --replicas=3

# Check scaling
oc get pods -w

# Set up autoscaling
oc autoscale deployment/weather-app \
  --min=1 --max=5 --cpu-percent=70
```

## 5. Setting Up CI/CD

### Step 5.1: Configure GitHub Webhook (Optional)
```bash
# Get webhook URL
oc describe bc/weather-app | grep Webhook

# Add to GitHub repository settings
# Settings → Webhooks → Add webhook
```

### Step 5.2: Trigger Builds
```bash
# Manual build trigger
oc start-build weather-app

# From Git
oc start-build weather-app --from-repo=<git-url>

# Watch build logs
oc logs -f bc/weather-app
```

### Step 5.3: Deployment Pipeline
```bash
# Apply Tekton pipeline (if Tekton is installed)
oc apply -f tekton-pipeline.yaml

# Or use OpenShift Pipelines
oc apply -f cicd/pipelines/pipeline.yaml
```

## 6. Monitoring and Logging

### Step 6.1: Deploy Logging Stack
```bash
# Deploy Loki + Grafana
oc apply -f logging/loki-stack-lightweight.yaml

# Check deployment
oc get pods -n logging-lite

# Get Grafana route
oc get route -n logging-lite
```

### Step 6.2: View Application Logs
```bash
# Using oc logs
oc logs deployment/weather-app --tail=50

# Stream logs
oc logs -f deployment/weather-app

# Logs from all pods
oc logs -l app=weather-app --tail=20
```

### Step 6.3: Access Grafana
```bash
# Get Grafana URL
GRAFANA_URL=$(oc get route grafana -n logging-lite -o jsonpath='https://{.spec.host}')
echo "Grafana URL: $GRAFANA_URL"

# Default credentials: admin/admin
# 
# In Grafana:
# 1. Go to Explore
# 2. Select Loki datasource
# 3. Query: {app="weather-app"}
```

### Step 6.4: Metrics with Prometheus
```bash
# Check if ServiceMonitor is created
oc get servicemonitor

# View metrics endpoint
curl http://$ROUTE_URL/metrics
```

## 7. Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: Pod Not Starting
```bash
# Check pod status
oc get pods
oc describe pod <pod-name>

# Check events
oc get events --sort-by='.lastTimestamp'

# Common causes:
# - Image pull errors
# - Resource limits
# - Configuration issues
```

#### Issue 2: Application Errors
```bash
# Check logs
oc logs <pod-name> --tail=100

# Execute into pod
oc exec -it <pod-name> -- /bin/bash

# Inside pod:
# - Check environment variables: env
# - Test connectivity: curl localhost:8080/healthz
# - Check file permissions: ls -la
```

#### Issue 3: Route Not Working
```bash
# Check route status
oc get route
oc describe route weather-app

# Test service directly
oc port-forward service/weather-app 8080:8080
curl localhost:8080/
```

#### Issue 4: Build Failures
```bash
# Check build logs
oc logs -f bc/weather-app

# Common issues:
# - Dockerfile syntax
# - Network access (for package installation)
# - Resource limits
```

### Useful Debugging Commands
```bash
# Get pod details
oc get pod <pod-name> -o yaml

# Check resource usage
oc top pods
oc describe resourcequota

# View container logs from previous run
oc logs <pod-name> --previous

# Get shell access
oc rsh <pod-name>

# Copy files from pod
oc cp <pod-name>:/path/to/file ./local-file
```

## 📚 Advanced Topics

### Environment-Specific Deployments
```bash
# Deploy to different environments
oc apply -k openshift/overlays/dev/
oc apply -k openshift/overlays/staging/
oc apply -k openshift/overlays/prod/
```

### Security Scanning
```bash
# Run security scan
python security-scan.py

# Apply security policies
oc apply -f governance/security/
```

### Backup and Restore
```bash
# Export resources
oc get all -o yaml > backup.yaml

# Export specific resource
oc get deployment weather-app -o yaml > deployment-backup.yaml
```

## 🎯 Practice Exercises

### Exercise 1: Update the Application
1. Modify `app/main.py` to add a new endpoint
2. Rebuild and redeploy
3. Test the new endpoint

### Exercise 2: Configure Environment Variables
1. Create a new ConfigMap with custom settings
2. Mount it in the deployment
3. Verify the application uses new config

### Exercise 3: Implement Blue-Green Deployment
1. Create a new version of the app
2. Deploy alongside the current version
3. Switch traffic between versions

### Exercise 4: Set Up Monitoring Alert
1. Create a PrometheusRule for high error rate
2. Configure AlertManager
3. Test the alert

## 🔗 Useful Resources

- **OpenShift Console**: Access via web browser for GUI management
- **Documentation**: 
  - [OpenShift Docs](https://docs.openshift.com/)
  - [Kubernetes Docs](https://kubernetes.io/docs/)
- **Commands Cheatsheet**: Keep `oc help` handy

## 💡 Tips for Success

1. **Always check logs first** when troubleshooting
2. **Use labels** to organize and select resources
3. **Set resource limits** to prevent resource exhaustion
4. **Implement health checks** for better reliability
5. **Use ConfigMaps and Secrets** for configuration
6. **Monitor resource usage** regularly
7. **Practice rollback procedures** before production

---

## 🎉 Congratulations!

You've successfully deployed a microservice application on OpenShift with:
- ✅ Container orchestration
- ✅ CI/CD pipeline
- ✅ Monitoring and logging
- ✅ Auto-scaling
- ✅ Security best practices

Keep experimenting and building! 🚀