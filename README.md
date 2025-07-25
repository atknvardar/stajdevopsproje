# OpenShift-Based Microservice CI/CD and Observability Platform

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/python-v3.9+-blue.svg)](https://www.python.org/)
[![OpenShift](https://img.shields.io/badge/OpenShift-4.x-red.svg)](https://www.openshift.com/)
[![Tekton](https://img.shields.io/badge/Tekton-CI%2FCD-blue.svg)](https://tekton.dev/)

A comprehensive DevOps platform for a microservice application running on OpenShift, featuring CI/CD pipelines, container orchestration, monitoring, logging, and security capabilities.

🇹🇷 [Türkçe README için tıklayın](README-TR.md)

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [API Documentation](#api-documentation)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Logging](#monitoring--logging)
- [Security](#security)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Project Overview

This project provides a complete DevOps platform including:

- **Weather Data Aggregator Microservice**: FastAPI-based RESTful API that aggregates weather data from multiple sources
- **CI/CD Pipeline**: Tekton-based automated build, test, and deployment processes
- **Container Orchestration**: High availability and scalability on OpenShift/Kubernetes
- **Observability Stack**: Full observability with Prometheus, Grafana, Loki, and Jaeger
- **Security**: RBAC, Network Policies, Security Scanning, and Container Security

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer / Route                     │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                     OpenShift Cluster                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  Microservice Pod                     │   │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │   │
│  │  │ Weather API │  │ Prometheus   │  │   Jaeger   │ │   │
│  │  │  (FastAPI)  │  │   Metrics    │  │  Tracing   │ │   │
│  │  └─────────────┘  └──────────────┘  └────────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐   │
│  │  Prometheus  │  │   Grafana    │  │   Loki/EFK     │   │
│  │   Server     │  │  Dashboards  │  │  Log Storage   │   │
│  └──────────────┘  └──────────────┘  └────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Tekton CI/CD Pipeline                    │  │
│  │  Build → Test → Security Scan → Deploy → E2E Test    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## ✨ Features

### 🚀 Microservice Application
- FastAPI-based RESTful API
- Multiple weather API integration (OpenWeatherMap, WeatherAPI, etc.)
- Asynchronous data processing
- Prometheus metrics
- OpenTelemetry distributed tracing
- Health check and readiness probes

### 🔄 CI/CD Pipeline
- **Tekton** based cloud-native CI/CD
- Automated build and deployment
- Multi-stage Docker builds
- Security scanning (Trivy, Bandit)
- Automated test execution
- GitOps integration

### 📊 Monitoring & Observability
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki/EFK Stack**: Log aggregation and analysis
- **Jaeger**: Distributed tracing
- **AlertManager**: Alert management

### 🔒 Security
- Container security scanning
- RBAC (Role-Based Access Control)
- Network Policies
- Secret management
- Non-root container execution
- Security scanning in CI/CD

### 🧪 Test Automation
- Unit tests (pytest)
- Integration tests
- End-to-end tests
- Performance tests
- Security tests

## 🚀 Installation

### Requirements

- OpenShift 4.x cluster or OpenShift Local (CRC)
- `oc` CLI tool
- Docker or Podman
- Python 3.9+
- Git

### Quick Start

1. **Clone the repository:**
```bash
git clone https://github.com/yourusername/stajdevopsproje.git
cd stajdevopsproje
```

2. **Login to OpenShift:**
```bash
oc login -u developer -p developer https://api.crc.testing:6443
```

3. **Create a namespace:**
```bash
oc new-project microservice-demo
```

4. **Deploy the platform:**
```bash
./deploy-all-environments.sh
```

### Detailed Installation

For detailed installation steps, see [DEPLOYMENT_EXPLANATION.md](DEPLOYMENT_EXPLANATION.md).

## 📖 Usage

### API Endpoints

The Weather Data Aggregator API provides the following endpoints:

- `GET /` - API information and endpoint list
- `GET /healthz` - Liveness probe
- `GET /ready` - Readiness probe
- `GET /metrics` - Prometheus metrics
- `GET /api/v1/weather/current?lat={lat}&lon={lon}` - Current weather for specific location
- `GET /api/v1/weather/aggregated?lat={lat}&lon={lon}` - Aggregated data from all sources
- `GET /api/v1/weather/trends?lat={lat}&lon={lon}&hours={hours}` - Weather trends
- `GET /api/v1/weather/locations` - Actively monitored locations
- `GET /api/v1/status/apis` - API status
- `GET /api/v1/status/quality` - Data quality metrics
- `POST /api/v1/weather/refresh` - Manual data refresh

### Example Usage

```bash
# Get current weather data
curl "http://microservice-demo.apps.openshift.local/api/v1/weather/current?lat=41.0082&lon=28.9784"

# View Prometheus metrics
curl "http://microservice-demo.apps.openshift.local/metrics"

# Health check
curl "http://microservice-demo.apps.openshift.local/healthz"
```

## 📁 Project Structure

```
stajdevopsproje/
├── app/                      # Microservice application code
│   ├── main.py              # FastAPI main application
│   ├── weather_service.py   # Weather service
│   ├── models.py            # Pydantic models
│   ├── config.py            # Configuration
│   └── tests/               # Test files
├── cicd/                    # CI/CD pipeline definitions
│   ├── pipelines/          # Tekton pipeline YAMLs
│   ├── tasks/              # Tekton task definitions
│   └── scripts/            # Helper scripts
├── openshift/              # OpenShift manifest files
│   ├── base/               # Base Kubernetes/OpenShift resources
│   └── overlays/           # Environment-specific configurations
├── observability/          # Monitoring and logging configurations
│   ├── prometheus/         # Prometheus configuration
│   ├── grafana/           # Grafana dashboards
│   └── loki/              # Loki log aggregation
├── governance/            # RBAC and security policies
├── testing/               # Test scenarios and scripts
└── docs/                  # Documentation
```

## 🔄 CI/CD Pipeline

The Tekton-based CI/CD pipeline includes the following stages:

1. **Git Clone**: Source code checkout
2. **Unit Test**: Run unit tests
3. **Build Image**: Build container image
4. **Security Scan**: Security scanning
5. **Deploy Dev**: Deploy to development environment
6. **E2E Test**: Run end-to-end tests
7. **Deploy Prod**: Deploy to production (with manual approval)

To trigger the pipeline:

```bash
./run-cicd-pipeline.sh
```

## 📊 Monitoring & Logging

### Prometheus & Grafana

Access Grafana dashboards:
```bash
oc get route grafana -n observability
```

### Log Viewing

```bash
# View pod logs
oc logs -f deployment/microservice-demo

# Query logs via Loki
./cicd/scripts/collect-weather-logs.sh
```

## 🔒 Security

The project includes the following security features:

- **Container Security**: Non-root user, read-only root filesystem
- **Network Policies**: Pod-to-pod communication control
- **RBAC**: Role-based access control
- **Security Scanning**: Security scans during build phase
- **Secret Management**: Sensitive data management with OpenShift secrets

## 🧪 Testing

### Running Unit Tests

```bash
cd app
python -m pytest tests/ -v
```

### Integration Tests

```bash
./testing/scripts/run-all-tests.sh
```

## 🤝 Contributing

We welcome contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md).

## 📝 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 📚 Additional Resources

- [OpenShift Console Guide](OPENSHIFT_CONSOLE_GUIDE.md)
- [Architecture Guide](ARCHITECTURE_GUIDE.md)
- [Hands-on Tutorial](HANDS_ON_TUTORIAL.md)
- [API Documentation](docs/api/README.md)
- [Troubleshooting Guide](docs/troubleshooting.md)

## 👥 Contact

For questions or suggestions:
- GitHub Issues: [Project Issues](https://github.com/yourusername/stajdevopsproje/issues)
- Email: your.email@example.com

---

**Note**: This project was developed for educational purposes and may require additional security and performance optimizations for production use.