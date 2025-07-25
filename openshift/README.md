# OpenShift Deployment Manifests

This directory contains Kubernetes/OpenShift manifests and deployment scripts for the microservice demo application, organized using Kustomize for environment-specific configurations.

## Directory Structure

```
openshift/
├── base/                          # Base Kubernetes manifests
│   ├── deployment.yaml           # Application deployment
│   ├── service.yaml              # Service definition
│   ├── route.yaml                # OpenShift route for external access
│   ├── configmap.yaml            # Application configuration
│   ├── serviceaccount.yaml       # Service account for RBAC
│   └── kustomization.yaml        # Base kustomization
├── overlays/                      # Environment-specific overlays
│   ├── dev/                      # Development environment
│   │   ├── kustomization.yaml    # Dev overlay configuration
│   │   ├── deployment-patch.yaml # Dev-specific deployment patches
│   │   └── configmap-patch.yaml  # Dev-specific config patches
│   ├── staging/                  # Staging environment
│   │   ├── kustomization.yaml    # Staging overlay configuration
│   │   ├── deployment-patch.yaml # Staging-specific patches
│   │   └── configmap-patch.yaml  # Staging-specific config
│   └── prod/                     # Production environment
│       ├── kustomization.yaml    # Production overlay configuration
│       ├── deployment-patch.yaml # Production-specific patches
│       ├── configmap-patch.yaml  # Production-specific config
│       ├── route-patch.yaml      # Production TLS configuration
│       ├── hpa.yaml              # Horizontal Pod Autoscaler
│       └── pdb.yaml              # Pod Disruption Budget
├── security/                     # Security and governance manifests
│   ├── rbac.yaml                 # RBAC roles and bindings
│   ├── network-policy.yaml       # Network policies
│   └── resource-quota.yaml       # Resource quotas and limits
├── monitoring/                   # Monitoring configuration
│   └── service-monitor.yaml      # Prometheus ServiceMonitor and alerts
├── scripts/                      # Deployment and utility scripts
│   └── deploy.sh                 # Main deployment script
└── README.md                     # This file
```

## Environment Configurations

### Development (dev)
- **Replicas**: 1
- **Resources**: Minimal (64Mi RAM, 50m CPU)
- **Logging**: DEBUG level
- **Features**: Debug mode enabled, hot reload
- **Security**: Basic security context
- **Monitoring**: Development metrics

### Staging (staging)
- **Replicas**: 2
- **Resources**: Moderate (128Mi RAM, 100m CPU)
- **Logging**: INFO level
- **Features**: Performance monitoring enabled
- **Security**: Service mesh injection (Istio)
- **Monitoring**: Production-like monitoring

### Production (prod)
- **Replicas**: 3 (with HPA: 3-10)
- **Resources**: Production-ready (256Mi-1Gi RAM, 200m-1000m CPU)
- **Logging**: WARN level
- **Features**: Security headers, audit logging
- **Security**: Full security context, pod anti-affinity
- **Monitoring**: Comprehensive monitoring and alerting
- **Availability**: Pod Disruption Budget

## Security Features

### RBAC (Role-Based Access Control)
- Dedicated service account with minimal permissions
- Role limited to reading ConfigMaps, Secrets, and own resources
- No cluster-wide permissions

### Network Policies
- Restricted ingress from OpenShift ingress and monitoring
- Limited egress for DNS and monitoring
- Default deny-all policy

### Resource Governance
- ResourceQuota for compute and storage limits
- LimitRange for default and maximum resource constraints
- Pod Security Standards compliance

### Container Security
- Non-root user execution
- Read-only root filesystem
- Dropped capabilities
- Security context constraints

## Monitoring and Observability

### Prometheus Integration
- ServiceMonitor for metrics collection
- Custom alerting rules for:
  - Application availability
  - High error rates
  - Resource utilization
  - Performance degradation

### Health Checks
- Liveness probe (`/healthz`)
- Readiness probe (`/ready`)
- Startup probe for graceful initialization

### Logging
- Structured JSON logging
- Environment-specific log levels
- Centralized log aggregation ready

## Deployment

### Prerequisites
1. OpenShift CLI (`oc`) installed and configured
2. Kustomize installed
3. Access to OpenShift cluster
4. Appropriate RBAC permissions

### Quick Start

```bash
# Login to OpenShift
oc login https://your-openshift-cluster.com

# Deploy to development
./scripts/deploy.sh dev

# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh prod
```

### Manual Deployment

```bash
# Create namespace
oc create namespace microservice-demo-dev

# Apply security manifests
oc apply -f security/ -n microservice-demo-dev

# Apply monitoring manifests
oc apply -f monitoring/ -n microservice-demo-dev

# Deploy application
kustomize build overlays/dev | oc apply -f - -n microservice-demo-dev
```

### Dry Run

```bash
# Test deployment without applying changes
DRY_RUN=true ./scripts/deploy.sh prod
```

## Kustomize Usage

### View Generated Manifests

```bash
# Development environment
kustomize build overlays/dev

# Production environment
kustomize build overlays/prod
```

### Customize for Your Environment

1. **Update base configuration**: Modify files in `base/`
2. **Environment-specific changes**: Edit overlay files in `overlays/{env}/`
3. **Add new environments**: Create new overlay directory with kustomization.yaml

## Configuration Management

### Environment Variables
Application configuration is managed through ConfigMaps and environment variables:

- `LOG_LEVEL`: Logging level (DEBUG, INFO, WARN, ERROR)
- `ENVIRONMENT`: Current environment (development, staging, production)
- `TRACING_ENABLED`: Enable/disable distributed tracing
- `METRICS_ENABLED`: Enable/disable metrics collection

### Secrets Management
Sensitive data should be stored in Kubernetes Secrets:

```bash
# Create secret
oc create secret generic microservice-demo-secret \
  --from-literal=database-password=yourpassword \
  --from-literal=api-key=yourapikey
```

## Scaling and Performance

### Horizontal Pod Autoscaler (HPA)
Production environment includes HPA configuration:
- **Min replicas**: 3
- **Max replicas**: 10
- **CPU target**: 70%
- **Memory target**: 80%

### Pod Disruption Budget (PDB)
Ensures availability during cluster maintenance:
- **Min available**: 2 pods
- Prevents unnecessary downtime

### Resource Optimization
- Resource requests and limits tuned per environment
- Quality of Service (QoS) class: Burstable
- Node affinity and anti-affinity rules

## Troubleshooting

### Common Issues

1. **ImagePullBackOff**: Check image name and registry access
2. **CrashLoopBackOff**: Check application logs and health endpoints
3. **Service Unavailable**: Verify service and route configuration

### Debugging Commands

```bash
# Check pod status
oc get pods -l app=microservice-demo

# View pod logs
oc logs -l app=microservice-demo -f

# Describe deployment
oc describe deployment microservice-demo

# Check events
oc get events --sort-by='.lastTimestamp'

# Test connectivity
oc port-forward svc/microservice-demo 8080:8080
curl http://localhost:8080/healthz
```

### Health Check Endpoints

- `GET /healthz` - Liveness probe
- `GET /ready` - Readiness probe
- `GET /metrics` - Prometheus metrics
- `GET /api/v1/hello` - Application endpoint

## Integration with CI/CD

These manifests are designed to integrate with the Tekton CI/CD pipeline:

1. **Pipeline triggers**: Automatic deployment on successful builds
2. **Environment promotion**: Staged deployment through dev → staging → prod
3. **Rollback support**: Easy rollback using deployment history
4. **Security scanning**: Integrated security validation

## Best Practices Implemented

- **Infrastructure as Code**: All configurations version controlled
- **Environment Parity**: Consistent configuration across environments
- **Security by Default**: Minimal permissions and security contexts
- **Observability**: Comprehensive monitoring and logging
- **Scalability**: Auto-scaling and resource management
- **Reliability**: Health checks and disruption budgets

## Next Steps

1. **Phase 5**: Set up observability stack (Prometheus, Grafana, Loki)
2. **Phase 6**: Implement comprehensive RBAC and security policies
3. **Phase 7**: Create end-to-end tests and validation
4. **Phase 8**: Complete documentation and deployment guides

## References

- [Kustomize Documentation](https://kustomize.io/)
- [OpenShift Documentation](https://docs.openshift.com/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Prometheus Operator](https://prometheus-operator.dev/) 