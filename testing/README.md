# DevOps Pipeline Testing & Validation

This directory contains comprehensive testing and validation infrastructure for the entire DevOps pipeline, providing end-to-end validation of all components across development, staging, and production environments.

## 🎯 Overview

The testing framework validates all aspects of the DevOps pipeline:

- **Infrastructure**: Kubernetes/OpenShift cluster health, namespace configuration, RBAC
- **Security**: Network policies, pod security standards, compliance validation
- **Microservices**: End-to-end API testing, health checks, performance validation
- **Observability**: Monitoring stack validation, metrics collection, alerting
- **Governance**: Resource management, access controls, policy enforcement

## 📁 Structure

```
testing/
├── scripts/                    # Test orchestration and setup scripts
│   ├── setup-testing.sh       # Infrastructure setup script
│   └── run-all-tests.sh       # Main test orchestrator
├── e2e/                        # End-to-end microservice tests
│   └── microservice-tests.yaml
├── infrastructure/             # Infrastructure validation tests
│   └── infrastructure-tests.yaml
├── security/                   # Security and compliance tests
│   └── security-tests.yaml
├── results/                    # Test execution results (auto-generated)
└── README.md                   # This file
```

## 🚀 Quick Start

### 1. Setup Testing Infrastructure

```bash
# Set up the complete testing infrastructure
./testing/scripts/setup-testing.sh

# Preview changes without applying (dry run)
./testing/scripts/setup-testing.sh --dry-run

# Use specific storage class
./testing/scripts/setup-testing.sh --storage-class fast-ssd
```

### 2. Run All Tests

```bash
# Execute complete test suite
./testing/scripts/run-all-tests.sh

# Run with verbose output
./testing/scripts/run-all-tests.sh --verbose

# Skip specific test categories
./testing/scripts/run-all-tests.sh --skip-tests security,performance
```

### 3. View Results

```bash
# Check test execution status
kubectl get jobs -n testing

# View test logs
kubectl logs -n testing job/<job-name>

# Access test dashboard
kubectl port-forward -n observability svc/grafana 3000:3000
# Navigate to http://localhost:3000 and import the test dashboard
```

## 🧪 Test Categories

### 1. Infrastructure Tests

**Purpose**: Validate Kubernetes/OpenShift cluster infrastructure and configuration

**Coverage**:
- Cluster node health and readiness
- Required namespaces and their configuration
- RBAC roles and bindings
- Resource quotas and limit ranges
- Network policies implementation
- Storage classes and persistent volumes

**Execution**:
```bash
kubectl apply -f testing/infrastructure/infrastructure-tests.yaml
```

### 2. Security Tests

**Purpose**: Validate security policies, compliance, and threat protection

**Coverage**:
- Network security policies
- Pod security standards enforcement
- RBAC access controls
- Container security contexts
- Image security scanning
- Runtime security monitoring

**Execution**:
```bash
kubectl apply -f testing/security/security-tests.yaml
```

### 3. Microservice E2E Tests

**Purpose**: End-to-end validation of microservice functionality

**Coverage**:
- Health check endpoints (`/healthz`, `/ready`)
- API functionality testing (`/api/v1/hello`)
- Metrics endpoint validation (`/metrics`)
- Error handling and edge cases
- Security headers validation
- Performance and load testing

**Test Environments**:
- Development: `microservice-demo-dev`
- Staging: `microservice-demo-staging`
- Production: `microservice-demo-prod`

**Execution**:
```bash
kubectl apply -f testing/e2e/microservice-tests.yaml
```

### 4. Observability Tests

**Purpose**: Validate monitoring, logging, and alerting infrastructure

**Coverage**:
- Prometheus server health
- Grafana dashboard availability
- Loki log aggregation
- ServiceMonitor configuration
- Alert rule validation
- Metrics collection verification

### 5. Governance Tests

**Purpose**: Validate resource management and policy enforcement

**Coverage**:
- Resource quota enforcement
- LimitRange configuration
- Network policy compliance
- Security tool deployment
- Admission controller validation

## 🔧 Test Configuration

### Test Runner RBAC

The testing framework uses a dedicated service account with minimal required permissions:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test-runner-sa
  namespace: testing
```

### Resource Management

Testing namespace includes resource quotas to prevent resource exhaustion:

```yaml
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "5"
    pods: "20"
```

### Network Security

Dedicated network policies ensure secure test execution:

- Default deny all traffic
- Explicit allow rules for test requirements
- Cross-namespace communication controls
- External access restrictions

## 📊 Test Results and Reporting

### Result Storage

Test results are stored in:
- **Persistent Volume**: `/testing/results/` (for cluster storage)
- **Local Directory**: `./testing/results/YYYYMMDD_HHMMSS/`

### Report Formats

1. **Console Output**: Real-time test execution status
2. **JSON Results**: Machine-readable test results
3. **HTML Report**: Comprehensive visual test report
4. **Grafana Dashboard**: Real-time test metrics visualization

### Sample Report Structure

```
testing/results/20241201_143022/
├── logs/
│   ├── infrastructure-tests.log
│   ├── security-tests.log
│   ├── microservice-tests.log
│   ├── observability-tests.log
│   └── governance-tests.log
├── reports/
│   └── test-report.html
└── test-execution-summary.json
```

## 🔍 Test Execution Details

### Infrastructure Tests Example

```bash
=== Infrastructure Validation Tests ===
✅ Cluster nodes are ready
✅ All required namespaces exist
✅ Custom RBAC roles configured: 5
✅ Resource quotas configured: 3
✅ Network policies configured: 8
```

### Security Tests Example

```bash
=== Security Validation Tests ===
✅ Network policies configured: 8
✅ Production namespace has restricted pod security
⚠️  Security scanning tools not found
✅ Service accounts configured: 3
```

### Microservice Tests Example

```bash
=== Microservice E2E Tests ===
Testing microservice-demo-dev:
  ✅ Liveness Probe (45ms)
  ✅ Readiness Probe (32ms)
  ✅ Hello API Basic (67ms)
  ✅ Prometheus Metrics (89ms)
```

## 🚨 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Check RBAC permissions
   kubectl auth can-i create jobs --as=system:serviceaccount:testing:test-runner-sa
   
   # Verify service account exists
   kubectl get serviceaccount test-runner-sa -n testing
   ```

2. **Test Timeout**
   ```bash
   # Check pod resource limits
   kubectl describe pod -n testing <test-pod-name>
   
   # Verify network connectivity
   kubectl exec -n testing <test-pod-name> -- nslookup kubernetes.default
   ```

3. **Missing Test Results**
   ```bash
   # Check PVC status
   kubectl get pvc test-results-pvc -n testing
   
   # Verify mount permissions
   kubectl exec -n testing <test-pod-name> -- ls -la /results
   ```

### Debug Mode

Enable verbose logging for detailed troubleshooting:

```bash
# Run setup with verbose output
VERBOSE=true ./testing/scripts/setup-testing.sh

# Run tests with debug information
./testing/scripts/run-all-tests.sh --verbose
```

## ⚙️ Configuration Options

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DRY_RUN` | Preview changes without applying | `false` |
| `VERBOSE` | Enable detailed logging | `false` |
| `STORAGE_CLASS` | Storage class for PVCs | `default` |
| `ENVIRONMENTS` | Test environments to validate | `dev,staging,prod` |
| `SKIP_TESTS` | Test categories to skip | `""` |

### Customization

#### Adding New Test Categories

1. Create test configuration in appropriate directory
2. Add ConfigMap with test definitions
3. Update test orchestrator script
4. Add validation logic

#### Modifying Test Environments

Update the environment configuration in `microservice-tests.yaml`:

```yaml
environments:
  - name: custom-env
    base_url: "http://microservice.custom-namespace.svc.cluster.local:8080"
    namespace: custom-namespace
```

## 📈 Monitoring and Metrics

### Test Metrics

The framework exposes custom metrics for monitoring:

- `test_executions_total`: Total test executions
- `test_success_total`: Successful test executions
- `test_duration_seconds`: Test execution duration
- `test_failure_reasons`: Categorized failure reasons

### Grafana Dashboard

Import the test dashboard configuration:

1. Access Grafana: `kubectl port-forward -n observability svc/grafana 3000:3000`
2. Navigate to Import Dashboard
3. Load configuration from: `kubectl get configmap test-dashboard-config -n testing -o yaml`

### Alerting

Configure alerts for test failures:

```yaml
groups:
- name: testing.rules
  rules:
  - alert: TestSuiteFailure
    expr: increase(test_failures_total[5m]) > 0
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: "Test suite failure detected"
```

## 🔗 Integration

### CI/CD Pipeline Integration

Integrate testing into Tekton pipeline:

```yaml
- name: run-tests
  taskRef:
    name: run-validation-tests
  params:
    - name: test-categories
      value: "infrastructure,security,microservice"
```

### Scheduled Testing

Enable periodic validation with CronJob:

```yaml
spec:
  schedule: "0 */6 * * *"  # Every 6 hours
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: test-runner
            image: python:3.9-slim
            command: ["/tests/run-all-tests.sh"]
```

## 🎯 Best Practices

### Test Design

1. **Idempotent Tests**: Tests should be repeatable without side effects
2. **Isolated Environments**: Each test should be independent
3. **Clear Assertions**: Test outcomes should be unambiguous
4. **Comprehensive Coverage**: Test all critical functionality
5. **Performance Awareness**: Include performance validation

### Security Considerations

1. **Minimal Permissions**: Test runners use least-privilege access
2. **Network Isolation**: Tests run in isolated network segments
3. **Secret Management**: No hardcoded credentials in test code
4. **Resource Limits**: Prevent resource exhaustion during testing

### Operational Guidelines

1. **Regular Execution**: Run tests on every deployment
2. **Trend Analysis**: Monitor test performance over time
3. **Failure Investigation**: Document and track test failures
4. **Continuous Improvement**: Regularly update test coverage

## 📝 Contributing

### Adding New Tests

1. Create test configuration in appropriate directory
2. Follow existing naming conventions
3. Include comprehensive documentation
4. Add validation for new test category
5. Update this README with new test information

### Test Development Guidelines

1. Use descriptive test names
2. Include setup and teardown logic
3. Implement proper error handling
4. Add metrics and logging
5. Follow security best practices

## 🆘 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review test logs in `testing/results/`
3. Verify cluster connectivity and permissions
4. Check resource quotas and limits
5. Validate network policies

## 📄 License

This testing framework is part of the comprehensive DevOps pipeline implementation and follows the same licensing as the main project.

---

**Next Phase**: [Documentation & Presentation](../docs/README.md)

This testing framework provides comprehensive validation of the entire DevOps pipeline, ensuring reliability, security, and performance across all environments. The automated testing approach enables continuous validation and early detection of issues, supporting a robust DevOps practice. 