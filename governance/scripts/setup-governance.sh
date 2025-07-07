#!/bin/bash

set -euo pipefail

# Governance Framework Setup Script
# This script deploys comprehensive RBAC, resource management, and security policies

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOVERNANCE_DIR="$(dirname "$SCRIPT_DIR")"
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}" >&2
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}" >&2
}

# Check if running on OpenShift
check_openshift() {
    log "Checking OpenShift environment..."
    if oc version --client &>/dev/null && oc cluster-info &>/dev/null; then
        log "OpenShift environment detected"
        return 0
    else
        warn "OpenShift CLI not available or not connected to cluster"
        return 1
    fi
}

# Check if running on Kubernetes
check_kubernetes() {
    log "Checking Kubernetes environment..."
    if kubectl version --client &>/dev/null && kubectl cluster-info &>/dev/null; then
        log "Kubernetes environment detected"
        return 0
    else
        warn "Kubernetes CLI not available or not connected to cluster"
        return 1
    fi
}

# Apply manifest with error handling
apply_manifest() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]]; then
        error "Manifest file not found: $file"
        return 1
    fi
    
    log "Applying $description..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: Would apply $file"
        return 0
    fi
    
    if check_openshift; then
        if oc apply -f "$file"; then
            success "Applied $description"
        else
            error "Failed to apply $description from $file"
        fi
    elif check_kubernetes; then
        if kubectl apply -f "$file"; then
            success "Applied $description"
        else
            error "Failed to apply $description from $file"
        fi
    else
        error "Neither OpenShift nor Kubernetes CLI available"
    fi
}

# Create namespace if it doesn't exist
create_namespace() {
    local namespace="$1"
    local description="$2"
    
    log "Creating namespace: $namespace"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: Would create namespace $namespace"
        return 0
    fi
    
    if check_openshift; then
        oc create namespace "$namespace" --dry-run=client -o yaml | oc apply -f -
    elif check_kubernetes; then
        kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
    fi
    
    success "Namespace $namespace ready"
}

# Add labels to namespace
label_namespace() {
    local namespace="$1"
    local labels="$2"
    
    log "Labeling namespace $namespace with: $labels"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: Would label namespace $namespace"
        return 0
    fi
    
    if check_openshift; then
        oc label namespace "$namespace" $labels --overwrite
    elif check_kubernetes; then
        kubectl label namespace "$namespace" $labels --overwrite
    fi
    
    success "Namespace $namespace labeled"
}

# Wait for deployment to be ready
wait_for_deployment() {
    local namespace="$1"
    local deployment="$2"
    local timeout="${3:-300}"
    
    log "Waiting for deployment $deployment in namespace $namespace to be ready..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: Would wait for deployment $deployment"
        return 0
    fi
    
    if check_openshift; then
        oc rollout status deployment/"$deployment" -n "$namespace" --timeout="${timeout}s"
    elif check_kubernetes; then
        kubectl rollout status deployment/"$deployment" -n "$namespace" --timeout="${timeout}s"
    fi
    
    success "Deployment $deployment is ready"
}

# Validate RBAC setup
validate_rbac() {
    log "Validating RBAC configuration..."
    
    local test_user="test-user@company.com"
    local test_namespace="microservice-demo-dev"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: Would validate RBAC"
        return 0
    fi
    
    if check_openshift; then
        # Test if user can access development namespace
        if oc auth can-i get pods --as="$test_user" -n "$test_namespace" &>/dev/null; then
            success "RBAC validation passed for development access"
        else
            warn "RBAC validation failed - users may need proper group membership"
        fi
    fi
}

# Main deployment function
deploy_governance() {
    log "Starting Governance Framework Deployment"
    
    # Create required namespaces
    create_namespace "security-tools" "Security Tools"
    create_namespace "microservice-demo-dev" "Development Environment"
    create_namespace "microservice-demo-staging" "Staging Environment"
    create_namespace "microservice-demo-prod" "Production Environment"
    create_namespace "observability" "Observability Stack"
    create_namespace "ci-cd" "CI/CD Pipeline"
    create_namespace "shared-services" "Shared Services"
    create_namespace "network-tools" "Network Tools"
    
    # Label namespaces for Pod Security Standards
    label_namespace "microservice-demo-dev" "pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/audit=restricted pod-security.kubernetes.io/warn=restricted environment=development monitoring=enabled"
    label_namespace "microservice-demo-staging" "pod-security.kubernetes.io/enforce=baseline pod-security.kubernetes.io/audit=restricted pod-security.kubernetes.io/warn=restricted environment=staging monitoring=enabled"
    label_namespace "microservice-demo-prod" "pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/audit=restricted pod-security.kubernetes.io/warn=restricted environment=production monitoring=enabled"
    label_namespace "observability" "pod-security.kubernetes.io/enforce=baseline monitoring=enabled name=observability"
    label_namespace "security-tools" "pod-security.kubernetes.io/enforce=baseline security-validation=enabled"
    label_namespace "ci-cd" "pod-security.kubernetes.io/enforce=baseline name=ci-cd"
    
    # Deploy RBAC
    log "Deploying RBAC policies..."
    apply_manifest "$GOVERNANCE_DIR/rbac/roles.yaml" "RBAC Roles"
    apply_manifest "$GOVERNANCE_DIR/rbac/rolebindings.yaml" "RBAC Role Bindings"
    
    # Deploy Resource Management
    log "Deploying resource management policies..."
    apply_manifest "$GOVERNANCE_DIR/resources/resource-quotas.yaml" "Resource Quotas"
    apply_manifest "$GOVERNANCE_DIR/resources/limit-ranges.yaml" "Limit Ranges"
    
    # Deploy Security Policies
    log "Deploying security policies..."
    apply_manifest "$GOVERNANCE_DIR/security/network-policies.yaml" "Network Policies"
    apply_manifest "$GOVERNANCE_DIR/security/pod-security-standards.yaml" "Pod Security Standards"
    
    # Deploy Security Tools
    log "Deploying security scanning tools..."
    apply_manifest "$GOVERNANCE_DIR/security/security-scanning.yaml" "Security Scanning Tools"
    
    # Wait for critical deployments
    if [[ "$DRY_RUN" != "true" ]]; then
        wait_for_deployment "security-tools" "trivy-scanner" 300
        wait_for_deployment "security-tools" "security-metrics-exporter" 180
    fi
    
    # Validate deployment
    validate_rbac
    
    success "Governance Framework deployment completed!"
}

# Cleanup function
cleanup_governance() {
    log "Cleaning up Governance Framework..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: Would cleanup governance framework"
        return 0
    fi
    
    local manifests=(
        "$GOVERNANCE_DIR/security/security-scanning.yaml"
        "$GOVERNANCE_DIR/security/pod-security-standards.yaml"
        "$GOVERNANCE_DIR/security/network-policies.yaml"
        "$GOVERNANCE_DIR/resources/limit-ranges.yaml"
        "$GOVERNANCE_DIR/resources/resource-quotas.yaml"
        "$GOVERNANCE_DIR/rbac/rolebindings.yaml"
        "$GOVERNANCE_DIR/rbac/roles.yaml"
    )
    
    for manifest in "${manifests[@]}"; do
        if [[ -f "$manifest" ]]; then
            log "Removing $manifest..."
            if check_openshift; then
                oc delete -f "$manifest" --ignore-not-found=true
            elif check_kubernetes; then
                kubectl delete -f "$manifest" --ignore-not-found=true
            fi
        fi
    done
    
    # Remove namespaces (optional - commented out for safety)
    # local namespaces=("security-tools")
    # for ns in "${namespaces[@]}"; do
    #     log "Removing namespace $ns..."
    #     oc delete namespace "$ns" --ignore-not-found=true
    # done
    
    success "Governance Framework cleanup completed!"
}

# Health check function
health_check() {
    log "Performing governance framework health check..."
    
    local exit_code=0
    
    # Check namespaces
    local namespaces=("security-tools" "microservice-demo-prod" "microservice-demo-staging" "microservice-demo-dev")
    for ns in "${namespaces[@]}"; do
        if check_openshift; then
            if oc get namespace "$ns" &>/dev/null; then
                success "Namespace $ns exists"
            else
                error "Namespace $ns missing"
                exit_code=1
            fi
        elif check_kubernetes; then
            if kubectl get namespace "$ns" &>/dev/null; then
                success "Namespace $ns exists"
            else
                error "Namespace $ns missing"
                exit_code=1
            fi
        fi
    done
    
    # Check security tools
    if [[ "$DRY_RUN" != "true" ]]; then
        local deployments=("trivy-scanner" "security-metrics-exporter")
        for deployment in "${deployments[@]}"; do
            if check_openshift; then
                if oc get deployment "$deployment" -n security-tools &>/dev/null; then
                    success "Deployment $deployment exists"
                else
                    error "Deployment $deployment missing"
                    exit_code=1
                fi
            elif check_kubernetes; then
                if kubectl get deployment "$deployment" -n security-tools &>/dev/null; then
                    success "Deployment $deployment exists"
                else
                    error "Deployment $deployment missing"
                    exit_code=1
                fi
            fi
        done
    fi
    
    if [[ $exit_code -eq 0 ]]; then
        success "Health check passed!"
    else
        error "Health check failed!"
    fi
    
    return $exit_code
}

# Usage function
usage() {
    cat << EOF
Governance Framework Setup Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    deploy      Deploy the complete governance framework
    cleanup     Remove all governance framework components
    health      Perform health check on deployed components
    validate    Validate RBAC and security policies

Options:
    --dry-run   Show what would be done without executing
    --verbose   Enable verbose output
    --help      Show this help message

Environment Variables:
    DRY_RUN     Set to 'true' for dry run mode
    VERBOSE     Set to 'true' for verbose output

Examples:
    $0 deploy                    # Deploy governance framework
    $0 deploy --dry-run          # Show what would be deployed
    $0 cleanup                   # Remove governance framework
    $0 health                    # Check deployment health
    DRY_RUN=true $0 deploy       # Dry run deployment

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        deploy)
            COMMAND="deploy"
            shift
            ;;
        cleanup)
            COMMAND="cleanup"
            shift
            ;;
        health)
            COMMAND="health"
            shift
            ;;
        validate)
            COMMAND="validate"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
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
case "${COMMAND:-deploy}" in
    deploy)
        deploy_governance
        ;;
    cleanup)
        cleanup_governance
        ;;
    health)
        health_check
        ;;
    validate)
        validate_rbac
        ;;
    *)
        error "Unknown command: ${COMMAND}"
        usage
        exit 1
        ;;
esac

log "Script execution completed successfully!" 