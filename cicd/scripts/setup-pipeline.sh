#!/bin/bash
set -euo pipefail

# CI/CD Pipeline Setup Script for OpenShift
# This script sets up the complete Tekton pipeline infrastructure

# Configuration
NAMESPACE="${NAMESPACE:-$(oc project -q)}"
APP_NAME="microservice-demo"
GITHUB_USER="${GITHUB_USER:-user}"
GITHUB_REPO="${GITHUB_REPO:-stajdevopsproje}"
REGISTRY_URL="${REGISTRY_URL:-ghcr.io}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if oc is available
    if ! command -v oc &> /dev/null; then
        log_error "OpenShift CLI (oc) is not installed"
        exit 1
    fi
    
    # Check if logged in to OpenShift
    if ! oc whoami &> /dev/null; then
        log_error "Not logged in to OpenShift. Please run 'oc login' first"
        exit 1
    fi
    
    # Check if current project exists
    if ! oc project "${NAMESPACE}" &> /dev/null; then
        log_error "Project ${NAMESPACE} does not exist or is not accessible"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

# Install Tekton Operators if needed
install_tekton_operators() {
    log_step "Checking Tekton Operators..."
    
    # Check if Tekton Pipelines is installed
    if ! oc get crd pipelines.tekton.dev &> /dev/null; then
        log_warn "Tekton Pipelines not found. Please install OpenShift Pipelines Operator"
        log_info "Go to: Operators > OperatorHub > Search for 'OpenShift Pipelines'"
        read -p "Press Enter after installing the operator..."
    fi
    
    # Check if Tekton Triggers is available
    if ! oc get crd eventlisteners.triggers.tekton.dev &> /dev/null; then
        log_warn "Tekton Triggers not found. It should be included with OpenShift Pipelines"
    fi
    
    log_info "Tekton components are available"
}

# Create namespace if it doesn't exist
setup_namespace() {
    log_step "Setting up namespace: ${NAMESPACE}"
    
    if ! oc get namespace "${NAMESPACE}" &> /dev/null; then
        log_info "Creating namespace: ${NAMESPACE}"
        oc new-project "${NAMESPACE}"
    else
        log_info "Using existing namespace: ${NAMESPACE}"
        oc project "${NAMESPACE}"
    fi
}

# Apply RBAC and core resources
apply_core_resources() {
    log_step "Applying core pipeline resources..."
    
    # Apply all the core resources
    log_info "Creating service account and RBAC..."
    oc apply -f cicd/pipelines/triggers/event-listener.yaml
    
    # Wait for resources to be created
    sleep 5
    
    # Link secrets to service account
    log_info "Linking secrets to service account..."
    oc secrets link pipeline-sa registry-secret --for=pull,mount || log_warn "Registry secret linking failed"
    
    log_info "Core resources applied successfully"
}

# Apply pipeline tasks
apply_tasks() {
    log_step "Applying pipeline tasks..."
    
    for task_file in cicd/pipelines/tasks/*.yaml; do
        if [ -f "$task_file" ]; then
            log_info "Applying $(basename "$task_file")"
            oc apply -f "$task_file"
        fi
    done
    
    log_info "Pipeline tasks applied successfully"
}

# Apply main pipeline
apply_pipeline() {
    log_step "Applying main pipeline..."
    
    log_info "Applying main pipeline definition"
    oc apply -f cicd/pipelines/pipeline.yaml
    
    log_info "Main pipeline applied successfully"
}

# Apply triggers
apply_triggers() {
    log_step "Applying pipeline triggers..."
    
    log_info "Applying trigger bindings"
    oc apply -f cicd/pipelines/triggers/trigger-binding.yaml
    
    log_info "Applying trigger templates"
    oc apply -f cicd/pipelines/triggers/trigger-template.yaml
    
    log_info "Pipeline triggers applied successfully"
}

# Update secrets with user input
update_secrets() {
    log_step "Updating secrets configuration..."
    
    # GitHub webhook secret
    read -s -p "Enter GitHub webhook secret (or press Enter to skip): " GITHUB_WEBHOOK_SECRET
    echo
    
    if [ -n "${GITHUB_WEBHOOK_SECRET}" ]; then
        log_info "Updating GitHub webhook secret..."
        oc patch secret github-secret -p "{\"data\":{\"secretToken\":\"$(echo -n "${GITHUB_WEBHOOK_SECRET}" | base64 -w 0)\"}}"
    else
        log_warn "GitHub webhook secret not updated. Update manually later."
    fi
    
    # Registry credentials
    read -p "Enter container registry username (or press Enter to skip): " REGISTRY_USER
    if [ -n "${REGISTRY_USER}" ]; then
        read -s -p "Enter container registry password/token: " REGISTRY_PASS
        echo
        
        log_info "Updating registry credentials..."
        oc delete secret registry-secret --ignore-not-found
        oc create secret docker-registry registry-secret \
            --docker-server="${REGISTRY_URL}" \
            --docker-username="${REGISTRY_USER}" \
            --docker-password="${REGISTRY_PASS}"
    else
        log_warn "Registry credentials not updated. Update manually later."
    fi
    
    # SonarQube token (optional)
    read -s -p "Enter SonarQube token (optional, press Enter to skip): " SONARQUBE_TOKEN
    echo
    
    if [ -n "${SONARQUBE_TOKEN}" ]; then
        log_info "Updating SonarQube token..."
        oc patch secret sonarqube-secret -p "{\"data\":{\"token\":\"$(echo -n "${SONARQUBE_TOKEN}" | base64 -w 0)\"}}"
    else
        log_info "SonarQube token not provided (optional)"
    fi
}

# Get webhook URL
get_webhook_url() {
    log_step "Getting webhook URL..."
    
    # Wait for route to be created
    sleep 10
    
    WEBHOOK_URL=$(oc get route github-webhook-listener -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
    
    if [ -n "${WEBHOOK_URL}" ]; then
        log_info "Webhook URL: https://${WEBHOOK_URL}"
        echo
        echo "Configure this URL in your GitHub repository:"
        echo "1. Go to your GitHub repository"
        echo "2. Navigate to Settings > Webhooks"
        echo "3. Click 'Add webhook'"
        echo "4. Set Payload URL to: https://${WEBHOOK_URL}"
        echo "5. Set Content type to: application/json"
        echo "6. Set Secret to your webhook secret"
        echo "7. Select 'Just the push event' and 'Pull requests'"
        echo "8. Click 'Add webhook'"
    else
        log_warn "Could not get webhook URL. Check route creation manually."
    fi
}

# Test pipeline
test_pipeline() {
    log_step "Testing pipeline setup..."
    
    log_info "Running a test pipeline..."
    
    # Create a test pipeline run
    cat << EOF | oc apply -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: test-pipeline-
  labels:
    app: microservice-demo
    test: setup-validation
spec:
  pipelineRef:
    name: microservice-pipeline
  params:
    - name: git-url
      value: https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git
    - name: git-revision
      value: main
    - name: image-name
      value: ${REGISTRY_URL}/${GITHUB_USER}/${APP_NAME}
    - name: target-namespace
      value: ${NAMESPACE}
  workspaces:
    - name: shared-workspace
      persistentVolumeClaim:
        claimName: pipeline-workspace-pvc
    - name: docker-config
      secret:
        secretName: registry-secret
  serviceAccountName: pipeline-sa
EOF
    
    # Get the pipeline run name
    PIPELINE_RUN=$(oc get pipelinerun -l test=setup-validation --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "${PIPELINE_RUN}" ]; then
        log_info "Test pipeline run created: ${PIPELINE_RUN}"
        log_info "Monitor with: oc logs -f pipelinerun/${PIPELINE_RUN}"
        log_info "Or view in OpenShift Console: Pipelines section"
    else
        log_warn "Could not create test pipeline run"
    fi
}

# Main execution
main() {
    echo "🚀 OpenShift CI/CD Pipeline Setup"
    echo "=================================="
    echo
    echo "This script will set up the complete Tekton pipeline infrastructure"
    echo "Namespace: ${NAMESPACE}"
    echo "App: ${APP_NAME}"
    echo "Registry: ${REGISTRY_URL}"
    echo
    
    read -p "Continue with setup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    
    check_prerequisites
    install_tekton_operators
    setup_namespace
    apply_core_resources
    apply_tasks
    apply_pipeline
    apply_triggers
    update_secrets
    get_webhook_url
    
    echo
    log_info "🎉 Pipeline setup completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Configure GitHub webhook with the provided URL"
    echo "2. Update any remaining secrets if needed"
    echo "3. Push to your repository to trigger the pipeline"
    echo "4. Monitor pipeline execution in OpenShift Console"
    echo
    echo "Useful commands:"
    echo "  oc get pipelinerun                    # List pipeline runs"
    echo "  oc logs -f pipelinerun/<name>        # Follow pipeline logs"
    echo "  oc delete pipelinerun --all          # Clean up test runs"
    echo
    
    read -p "Run a test pipeline? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_pipeline
    fi
}

# Execute main function
main "$@" 