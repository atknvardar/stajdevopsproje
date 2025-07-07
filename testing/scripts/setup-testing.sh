#!/bin/bash

set -euo pipefail

# DevOps Pipeline Testing Setup Script
# This script sets up the complete testing infrastructure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTING_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$TESTING_DIR")"
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}" >&2
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

info() {
    echo -e "${CYAN}[INFO] $1${NC}" >&2
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites for testing setup..."
    
    local missing_tools=()
    
    # Check required CLI tools
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v python3 &> /dev/null; then
        missing_tools+=("python3")
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
        return 1
    fi
    
    # Check if we have necessary permissions
    if ! kubectl auth can-i create namespace &> /dev/null; then
        error "Insufficient permissions to create namespaces"
        return 1
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    success "Prerequisites check passed"
}

# Create testing namespace
create_testing_namespace() {
    log "Creating testing namespace..."
    
    if [ "$DRY_RUN" = "true" ]; then
        info "DRY RUN: Would create testing namespace"
        return 0
    fi
    
    # Create namespace manifest
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: testing
  labels:
    name: testing
    testing: enabled
    security-validation: enabled
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/warn: baseline
  annotations:
    openshift.io/description: "Testing and validation namespace for DevOps pipeline"
    openshift.io/display-name: "Testing"
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: testing-quota
  namespace: testing
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "5"
    pods: "20"
    services: "10"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: testing-limits
  namespace: testing
spec:
  limits:
  - default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
EOF
    
    success "Testing namespace created"
}

# Create RBAC for test runner
create_test_rbac() {
    log "Creating RBAC for test runner..."
    
    if [ "$DRY_RUN" = "true" ]; then
        info "DRY RUN: Would create test runner RBAC"
        return 0
    fi
    
    cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test-runner-sa
  namespace: testing
  labels:
    app.kubernetes.io/name: testing
    app.kubernetes.io/component: service-account
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: test-runner
  labels:
    app.kubernetes.io/name: testing
    app.kubernetes.io/component: rbac
rules:
  - apiGroups: [""]
    resources: ["nodes", "namespaces", "pods", "services", "endpoints", "serviceaccounts", "persistentvolumeclaims", "secrets"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["clusterroles", "clusterrolebindings", "roles", "rolebindings"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["resourcequotas", "limitranges"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: ["monitoring.coreos.com"]
    resources: ["servicemonitors", "prometheusrules"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["security.openshift.io"]
    resources: ["securitycontextconstraints"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["route.openshift.io"]
    resources: ["routes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["authorization.k8s.io"]
    resources: ["subjectaccessreviews"]
    verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: test-runner
  labels:
    app.kubernetes.io/name: testing
    app.kubernetes.io/component: rbac
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: test-runner
subjects:
  - kind: ServiceAccount
    name: test-runner-sa
    namespace: testing
EOF
    
    success "Test runner RBAC created"
}

# Create storage for test results
create_test_storage() {
    log "Creating persistent storage for test results..."
    
    if [ "$DRY_RUN" = "true" ]; then
        info "DRY RUN: Would create test storage"
        return 0
    fi
    
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-results-pvc
  namespace: testing
  labels:
    app.kubernetes.io/name: testing
    app.kubernetes.io/component: storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ${STORAGE_CLASS:-default}
EOF
    
    success "Test storage created"
}

# Deploy test configurations
deploy_test_configs() {
    log "Deploying test configurations..."
    
    if [ "$DRY_RUN" = "true" ]; then
        info "DRY RUN: Would deploy test configurations"
        return 0
    fi
    
    # Deploy microservice tests
    if [ -f "$TESTING_DIR/e2e/microservice-tests.yaml" ]; then
        kubectl apply -f "$TESTING_DIR/e2e/microservice-tests.yaml"
        success "Microservice E2E tests deployed"
    else
        warn "Microservice test configuration not found"
    fi
    
    # Deploy infrastructure tests
    if [ -f "$TESTING_DIR/infrastructure/infrastructure-tests.yaml" ]; then
        kubectl apply -f "$TESTING_DIR/infrastructure/infrastructure-tests.yaml"
        success "Infrastructure tests deployed"
    else
        warn "Infrastructure test configuration not found"
    fi
    
    # Deploy security tests
    if [ -f "$TESTING_DIR/security/security-tests.yaml" ]; then
        kubectl apply -f "$TESTING_DIR/security/security-tests.yaml"
        success "Security tests deployed"
    else
        warn "Security test configuration not found"
    fi
}

# Create test network policies
create_test_network_policies() {
    log "Creating network policies for testing namespace..."
    
    if [ "$DRY_RUN" = "true" ]; then
        info "DRY RUN: Would create test network policies"
        return 0
    fi
    
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: testing-network-policy
  namespace: testing
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: testing
    - namespaceSelector:
        matchLabels:
          name: microservice-demo-dev
    - namespaceSelector:
        matchLabels:
          name: microservice-demo-staging
    - namespaceSelector:
        matchLabels:
          name: microservice-demo-prod
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          name: microservice-demo-dev
  - to:
    - namespaceSelector:
        matchLabels:
          name: microservice-demo-staging
  - to:
    - namespaceSelector:
        matchLabels:
          name: microservice-demo-prod
  - to:
    - namespaceSelector:
        matchLabels:
          name: observability
  - to: []
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 6443
EOF
    
    success "Test network policies created"
}

# Validate test infrastructure
validate_test_infrastructure() {
    log "Validating test infrastructure..."
    
    local validation_errors=()
    
    # Check namespace
    if ! kubectl get namespace testing &> /dev/null; then
        validation_errors+=("Testing namespace not found")
    fi
    
    # Check service account
    if ! kubectl get serviceaccount test-runner-sa -n testing &> /dev/null; then
        validation_errors+=("Test runner service account not found")
    fi
    
    # Check RBAC
    if ! kubectl get clusterrole test-runner &> /dev/null; then
        validation_errors+=("Test runner cluster role not found")
    fi
    
    # Check PVC
    if ! kubectl get pvc test-results-pvc -n testing &> /dev/null; then
        validation_errors+=("Test results PVC not found")
    fi
    
    # Check ConfigMaps
    local expected_configs=("microservice-e2e-tests" "infrastructure-validation-tests" "security-validation-tests")
    for config in "${expected_configs[@]}"; do
        if ! kubectl get configmap "$config" -n testing &> /dev/null; then
            validation_errors+=("ConfigMap $config not found")
        fi
    done
    
    if [ ${#validation_errors[@]} -eq 0 ]; then
        success "Test infrastructure validation passed"
        return 0
    else
        error "Test infrastructure validation failed:"
        for error in "${validation_errors[@]}"; do
            error "  - $error"
        done
        return 1
    fi
}

# Create test dashboard
create_test_dashboard() {
    log "Creating test dashboard configuration..."
    
    if [ "$DRY_RUN" = "true" ]; then
        info "DRY RUN: Would create test dashboard"
        return 0
    fi
    
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-dashboard-config
  namespace: testing
  labels:
    app.kubernetes.io/name: testing
    app.kubernetes.io/component: dashboard
data:
  dashboard.json: |
    {
      "dashboard": {
        "id": null,
        "title": "DevOps Pipeline Testing Dashboard",
        "tags": ["testing", "devops"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Test Execution Status",
            "type": "stat",
            "targets": [
              {
                "expr": "sum(rate(test_executions_total[5m]))",
                "legendFormat": "Test Executions/sec"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "color": {
                  "mode": "thresholds"
                },
                "thresholds": {
                  "steps": [
                    {"color": "green", "value": null},
                    {"color": "red", "value": 0.8}
                  ]
                }
              }
            },
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "Test Success Rate",
            "type": "gauge",
            "targets": [
              {
                "expr": "sum(rate(test_success_total[5m])) / sum(rate(test_executions_total[5m])) * 100",
                "legendFormat": "Success Rate %"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "min": 0,
                "max": 100,
                "unit": "percent",
                "thresholds": {
                  "steps": [
                    {"color": "red", "value": 0},
                    {"color": "yellow", "value": 70},
                    {"color": "green", "value": 90}
                  ]
                }
              }
            },
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
EOF
    
    success "Test dashboard configuration created"
}

# Main setup function
setup_testing_infrastructure() {
    log "🚀 Setting up DevOps Pipeline Testing Infrastructure"
    
    if [ "$DRY_RUN" = "true" ]; then
        warn "Running in DRY RUN mode - no changes will be made"
    fi
    
    # Step 1: Prerequisites
    check_prerequisites
    
    # Step 2: Create testing namespace
    create_testing_namespace
    
    # Step 3: Set up RBAC
    create_test_rbac
    
    # Step 4: Create storage
    create_test_storage
    
    # Step 5: Deploy test configurations
    deploy_test_configs
    
    # Step 6: Create network policies
    create_test_network_policies
    
    # Step 7: Create dashboard
    create_test_dashboard
    
    # Step 8: Validate infrastructure
    if ! validate_test_infrastructure; then
        error "Test infrastructure validation failed"
        return 1
    fi
    
    # Step 9: Make scripts executable
    chmod +x "$TESTING_DIR/scripts/"*.sh
    
    success "Testing infrastructure setup completed successfully!"
    
    # Print next steps
    echo ""
    echo "================================================================="
    echo "🎯 TESTING INFRASTRUCTURE READY"
    echo "================================================================="
    echo ""
    echo "📋 What was created:"
    echo "  ✅ Testing namespace with resource quotas"
    echo "  ✅ Test runner service account with RBAC"
    echo "  ✅ Persistent storage for test results"
    echo "  ✅ Test configurations and network policies"
    echo "  ✅ Test dashboard configuration"
    echo ""
    echo "🚀 Next steps:"
    echo "  1. Run all tests:"
    echo "     $TESTING_DIR/scripts/run-all-tests.sh"
    echo ""
    echo "  2. Run specific test categories:"
    echo "     $TESTING_DIR/scripts/run-all-tests.sh --skip-tests security,performance"
    echo ""
    echo "  3. View test results:"
    echo "     kubectl get jobs -n testing"
    echo "     kubectl logs -n testing job/<job-name>"
    echo ""
    echo "  4. Access test dashboard:"
    echo "     kubectl port-forward -n observability svc/grafana 3000:3000"
    echo "     # Then import the dashboard configuration"
    echo ""
    echo "================================================================="
}

# Usage function
usage() {
    cat << EOF
DevOps Pipeline Testing Infrastructure Setup

Usage: $0 [OPTIONS]

Options:
    --dry-run               Show what would be done without making changes
    --verbose               Enable verbose output
    --storage-class <name>  Specify storage class for PVCs (default: default)
    --help                  Show this help message

Environment Variables:
    DRY_RUN                Set to 'true' for dry run mode
    VERBOSE                Set to 'true' for verbose output
    STORAGE_CLASS          Storage class for persistent volumes

Examples:
    $0                      # Set up testing infrastructure
    $0 --dry-run            # Preview changes without applying
    $0 --verbose            # Show detailed output
    $0 --storage-class fast # Use specific storage class

This script will create:
  - Testing namespace with resource quotas and limits
  - Service account and RBAC for test runners
  - Persistent storage for test results
  - Network policies for secure test execution
  - Test configurations for all test categories
  - Grafana dashboard for test monitoring

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --storage-class)
            STORAGE_CLASS="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Set verbose mode
if [[ "$VERBOSE" == "true" ]]; then
    set -x
fi

# Main execution
if setup_testing_infrastructure; then
    success "Testing infrastructure setup completed successfully! 🎉"
    exit 0
else
    error "Testing infrastructure setup failed."
    exit 1
fi 