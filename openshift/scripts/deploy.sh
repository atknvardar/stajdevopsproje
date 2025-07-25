#!/bin/bash

# OpenShift Deployment Script for Microservice Demo
# Usage: ./deploy.sh [environment] [namespace]

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-dev}
NAMESPACE=${2:-microservice-demo-${ENVIRONMENT}}
DRY_RUN=${DRY_RUN:-false}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENSHIFT_DIR="$(dirname "$SCRIPT_DIR")"

# Supported environments
VALID_ENVIRONMENTS=("dev" "staging" "prod")

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
validate_environment() {
    if [[ ! " ${VALID_ENVIRONMENTS[@]} " =~ " ${ENVIRONMENT} " ]]; then
        log_error "Invalid environment: $ENVIRONMENT"
        log_info "Valid environments: ${VALID_ENVIRONMENTS[*]}"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if oc CLI is available
    if ! command -v oc &> /dev/null; then
        log_error "OpenShift CLI (oc) is not installed or not in PATH"
        exit 1
    fi
    
    # Check if kustomize is available
    if ! command -v kustomize &> /dev/null; then
        log_error "Kustomize is not installed or not in PATH"
        exit 1
    fi
    
    # Check if logged into OpenShift
    if ! oc whoami &> /dev/null; then
        log_error "Not logged into OpenShift cluster. Please run 'oc login'"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create namespace if it doesn't exist
create_namespace() {
    log_info "Checking namespace: $NAMESPACE"
    
    if ! oc get namespace "$NAMESPACE" &> /dev/null; then
        log_info "Creating namespace: $NAMESPACE"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would create namespace: $NAMESPACE"
        else
            oc create namespace "$NAMESPACE"
            
            # Label the namespace
            oc label namespace "$NAMESPACE" \
                environment="$ENVIRONMENT" \
                app.kubernetes.io/name=microservice-demo \
                app.kubernetes.io/part-of=microservice-platform
        fi
    else
        log_info "Namespace $NAMESPACE already exists"
    fi
}

# Apply security manifests
apply_security() {
    log_info "Applying security manifests..."
    
    local security_dir="$OPENSHIFT_DIR/security"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would apply security manifests"
        oc apply -f "$security_dir" -n "$NAMESPACE" --dry-run=client
    else
        oc apply -f "$security_dir" -n "$NAMESPACE"
    fi
    
    log_success "Security manifests applied"
}

# Apply monitoring manifests
apply_monitoring() {
    log_info "Applying monitoring manifests..."
    
    local monitoring_dir="$OPENSHIFT_DIR/monitoring"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would apply monitoring manifests"
        oc apply -f "$monitoring_dir" -n "$NAMESPACE" --dry-run=client
    else
        oc apply -f "$monitoring_dir" -n "$NAMESPACE"
    fi
    
    log_success "Monitoring manifests applied"
}

# Deploy application using kustomize
deploy_application() {
    log_info "Deploying application for environment: $ENVIRONMENT"
    
    local overlay_dir="$OPENSHIFT_DIR/overlays/$ENVIRONMENT"
    
    if [[ ! -d "$overlay_dir" ]]; then
        log_error "Overlay directory not found: $overlay_dir"
        exit 1
    fi
    
    # Generate and apply manifests
    log_info "Generating manifests with kustomize..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would apply the following manifests:"
        kustomize build "$overlay_dir"
    else
        kustomize build "$overlay_dir" | oc apply -f - -n "$NAMESPACE"
    fi
    
    log_success "Application deployed"
}

# Wait for deployment to be ready
wait_for_deployment() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would wait for deployment to be ready"
        return
    fi
    
    log_info "Waiting for deployment to be ready..."
    
    local deployment_name="microservice-demo"
    if [[ "$ENVIRONMENT" != "dev" ]]; then
        deployment_name="microservice-demo-$ENVIRONMENT"
    fi
    
    # Wait for deployment to be available
    if oc rollout status deployment/"$deployment_name" -n "$NAMESPACE" --timeout=300s; then
        log_success "Deployment is ready"
    else
        log_error "Deployment failed to become ready within timeout"
        
        # Show recent events for debugging
        log_info "Recent events:"
        oc get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -10
        
        exit 1
    fi
}

# Validate deployment
validate_deployment() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would validate deployment"
        return
    fi
    
    log_info "Validating deployment..."
    
    # Check if pods are running
    local running_pods
    running_pods=$(oc get pods -n "$NAMESPACE" -l app=microservice-demo --field-selector=status.phase=Running --no-headers | wc -l)
    
    if [[ $running_pods -gt 0 ]]; then
        log_success "$running_pods pod(s) are running"
    else
        log_error "No running pods found"
        oc get pods -n "$NAMESPACE" -l app=microservice-demo
        exit 1
    fi
    
    # Check if service is accessible
    local service_name="microservice-demo"
    if [[ "$ENVIRONMENT" != "dev" ]]; then
        service_name="microservice-demo-$ENVIRONMENT"
    fi
    
    if oc get service "$service_name" -n "$NAMESPACE" &> /dev/null; then
        log_success "Service $service_name is accessible"
    else
        log_error "Service $service_name is not accessible"
        exit 1
    fi
    
    # Get route URL if available
    local route_name="microservice-demo"
    if [[ "$ENVIRONMENT" != "dev" ]]; then
        route_name="microservice-demo-$ENVIRONMENT"
    fi
    
    if oc get route "$route_name" -n "$NAMESPACE" &> /dev/null; then
        local route_url
        route_url=$(oc get route "$route_name" -n "$NAMESPACE" -o jsonpath='{.spec.host}')
        log_success "Application is accessible at: https://$route_url"
    fi
}

# Show deployment info
show_deployment_info() {
    if [[ "$DRY_RUN" == "true" ]]; then
        return
    fi
    
    log_info "Deployment Information:"
    echo "========================"
    echo "Environment: $ENVIRONMENT"
    echo "Namespace: $NAMESPACE"
    echo ""
    
    log_info "Pods:"
    oc get pods -n "$NAMESPACE" -l app=microservice-demo
    echo ""
    
    log_info "Services:"
    oc get services -n "$NAMESPACE" -l app=microservice-demo
    echo ""
    
    log_info "Routes:"
    oc get routes -n "$NAMESPACE" -l app=microservice-demo
}

# Cleanup function
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Deployment failed with exit code $exit_code"
        
        if [[ "$DRY_RUN" != "true" ]]; then
            log_info "Recent events for debugging:"
            oc get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -20
        fi
    fi
    exit $exit_code
}

# Print usage
print_usage() {
    echo "Usage: $0 [environment] [namespace]"
    echo ""
    echo "Arguments:"
    echo "  environment    Target environment (dev|staging|prod) [default: dev]"
    echo "  namespace      Target namespace [default: microservice-demo-{environment}]"
    echo ""
    echo "Environment variables:"
    echo "  DRY_RUN        Set to 'true' for dry run mode [default: false]"
    echo ""
    echo "Examples:"
    echo "  $0                          # Deploy to dev environment"
    echo "  $0 staging                  # Deploy to staging environment"
    echo "  $0 prod microservice-prod   # Deploy to prod environment in custom namespace"
    echo "  DRY_RUN=true $0 prod        # Dry run for prod deployment"
}

# Main execution
main() {
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        print_usage
        exit 0
    fi
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    log_info "Starting deployment process..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Namespace: $NAMESPACE"
    log_info "Dry Run: $DRY_RUN"
    echo ""
    
    validate_environment
    check_prerequisites
    create_namespace
    apply_security
    apply_monitoring
    deploy_application
    wait_for_deployment
    validate_deployment
    show_deployment_info
    
    log_success "Deployment completed successfully!"
}

# Run main function with all arguments
main "$@" 