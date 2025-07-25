#!/bin/bash

# Observability Stack Setup Script
# This script sets up the complete monitoring, logging, and alerting stack

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-local}
MODE=${2:-docker}  # docker or kubernetes
NAMESPACE=${3:-observability}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OBSERVABILITY_DIR="$(dirname "$SCRIPT_DIR")"

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if [[ "$MODE" == "docker" ]]; then
        if ! command -v docker &> /dev/null; then
            log_error "Docker is not installed or not in PATH"
            exit 1
        fi
        
        if ! command -v docker-compose &> /dev/null; then
            log_error "Docker Compose is not installed or not in PATH"
            exit 1
        fi
    fi
    
    if [[ "$MODE" == "kubernetes" ]]; then
        if ! command -v kubectl &> /dev/null; then
            log_error "kubectl is not installed or not in PATH"
            exit 1
        fi
        
        if ! command -v helm &> /dev/null; then
            log_warning "Helm is not installed. Some components may require manual installation."
        fi
    fi
    
    log_success "Prerequisites check passed"
}

# Setup Docker-based observability stack
setup_docker_stack() {
    log_info "Setting up Docker-based observability stack..."
    
    cd "$OBSERVABILITY_DIR"
    
    # Create necessary directories
    mkdir -p data/{prometheus,grafana,loki,alertmanager}
    
    # Set proper permissions
    sudo chown -R 472:472 data/grafana
    sudo chown -R 65534:65534 data/prometheus
    sudo chown -R 10001:10001 data/loki
    sudo chown -R 65534:65534 data/alertmanager
    
    # Start the stack
    log_info "Starting observability stack with Docker Compose..."
    docker-compose up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    wait_for_service "Prometheus" "http://localhost:9090/-/ready" 60
    wait_for_service "Grafana" "http://localhost:3000/api/health" 60
    wait_for_service "Loki" "http://localhost:3100/ready" 60
    wait_for_service "AlertManager" "http://localhost:9093/-/ready" 60
    
    log_success "Docker observability stack is running!"
    print_docker_urls
}

# Setup Kubernetes-based observability stack
setup_kubernetes_stack() {
    log_info "Setting up Kubernetes-based observability stack..."
    
    # Create namespace
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Prometheus Operator (if using Helm)
    if command -v helm &> /dev/null; then
        log_info "Installing Prometheus Operator with Helm..."
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
        
        helm upgrade --install prometheus-operator prometheus-community/kube-prometheus-stack \
            --namespace "$NAMESPACE" \
            --set grafana.adminPassword=admin123 \
            --set prometheus.prometheusSpec.retention=15d \
            --wait
    else
        log_info "Installing observability components manually..."
        kubectl apply -f k8s/ -n "$NAMESPACE"
    fi
    
    # Wait for pods to be ready
    log_info "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod --all -n "$NAMESPACE" --timeout=300s
    
    log_success "Kubernetes observability stack is running!"
    print_kubernetes_urls
}

# Wait for service to be ready
wait_for_service() {
    local service_name=$1
    local url=$2
    local timeout=$3
    local count=0
    
    log_info "Waiting for $service_name to be ready..."
    
    while [[ $count -lt $timeout ]]; do
        if curl -sf "$url" > /dev/null 2>&1; then
            log_success "$service_name is ready!"
            return 0
        fi
        
        sleep 2
        ((count += 2))
        echo -n "."
    done
    
    log_error "$service_name failed to become ready within $timeout seconds"
    return 1
}

# Print Docker service URLs
print_docker_urls() {
    echo ""
    echo "==============================================="
    echo "🎯 Observability Stack URLs (Docker)"
    echo "==============================================="
    echo "📊 Grafana:           http://localhost:3000"
    echo "   └── User: admin, Password: admin123"
    echo ""
    echo "📈 Prometheus:        http://localhost:9090"
    echo "🚨 AlertManager:      http://localhost:9093"
    echo "📋 Loki:             http://localhost:3100"
    echo "🔍 Jaeger:           http://localhost:16686"
    echo "📦 cAdvisor:         http://localhost:8080"
    echo "🖥️  Node Exporter:    http://localhost:9100"
    echo "🏃 Blackbox Exporter: http://localhost:9115"
    echo ""
    echo "📱 Microservice:     http://localhost:8080"
    echo "   ├── Health:       http://localhost:8080/healthz"
    echo "   ├── Ready:        http://localhost:8080/ready"
    echo "   └── Metrics:      http://localhost:8080/metrics"
    echo "==============================================="
}

# Print Kubernetes service URLs
print_kubernetes_urls() {
    echo ""
    echo "==============================================="
    echo "🎯 Observability Stack URLs (Kubernetes)"
    echo "==============================================="
    echo "📊 Grafana:"
    kubectl get service -n "$NAMESPACE" | grep grafana
    echo ""
    echo "📈 Prometheus:"
    kubectl get service -n "$NAMESPACE" | grep prometheus
    echo ""
    echo "🚨 AlertManager:"
    kubectl get service -n "$NAMESPACE" | grep alertmanager
    echo "==============================================="
}

# Validate observability stack
validate_stack() {
    log_info "Validating observability stack..."
    
    if [[ "$MODE" == "docker" ]]; then
        # Check if containers are running
        local containers=("prometheus" "grafana" "loki" "alertmanager" "microservice-demo")
        for container in "${containers[@]}"; do
            if docker ps --format "table {{.Names}}" | grep -q "$container"; then
                log_success "$container container is running"
            else
                log_error "$container container is not running"
            fi
        done
        
        # Test service endpoints
        test_endpoint "Prometheus" "http://localhost:9090/-/ready"
        test_endpoint "Grafana" "http://localhost:3000/api/health"
        test_endpoint "Microservice" "http://localhost:8080/healthz"
        
    elif [[ "$MODE" == "kubernetes" ]]; then
        # Check pod status
        kubectl get pods -n "$NAMESPACE"
        
        # Check if services are accessible
        kubectl get services -n "$NAMESPACE"
    fi
    
    log_success "Observability stack validation completed!"
}

# Test service endpoint
test_endpoint() {
    local service_name=$1
    local url=$2
    
    if curl -sf "$url" > /dev/null 2>&1; then
        log_success "$service_name endpoint is responding"
    else
        log_warning "$service_name endpoint is not responding"
    fi
}

# Configure Grafana dashboards
configure_grafana() {
    log_info "Configuring Grafana dashboards..."
    
    if [[ "$MODE" == "docker" ]]; then
        # Grafana is configured via provisioning in docker-compose
        log_info "Grafana dashboards are automatically provisioned via Docker volumes"
    else
        # For Kubernetes, dashboards might need to be imported manually
        log_info "For Kubernetes deployment, dashboards may need manual import"
    fi
    
    log_success "Grafana configuration completed"
}

# Setup alerting rules
setup_alerting() {
    log_info "Setting up alerting rules..."
    
    if [[ "$MODE" == "docker" ]]; then
        # Reload Prometheus configuration
        curl -X POST http://localhost:9090/-/reload
        log_success "Prometheus configuration reloaded"
    else
        # For Kubernetes, rules are applied via ConfigMaps
        kubectl apply -f k8s/prometheus-rules.yaml -n "$NAMESPACE"
        log_success "Prometheus rules applied"
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up observability stack..."
    
    if [[ "$MODE" == "docker" ]]; then
        cd "$OBSERVABILITY_DIR"
        docker-compose down -v
        log_success "Docker stack cleaned up"
    else
        kubectl delete namespace "$NAMESPACE" --ignore-not-found
        log_success "Kubernetes resources cleaned up"
    fi
}

# Print usage
print_usage() {
    echo "Usage: $0 [environment] [mode] [namespace]"
    echo ""
    echo "Arguments:"
    echo "  environment    Target environment (local|dev|staging|prod) [default: local]"
    echo "  mode          Deployment mode (docker|kubernetes) [default: docker]"
    echo "  namespace     Kubernetes namespace [default: observability]"
    echo ""
    echo "Commands:"
    echo "  setup         Set up the observability stack"
    echo "  validate      Validate the observability stack"
    echo "  cleanup       Clean up the observability stack"
    echo ""
    echo "Examples:"
    echo "  $0 local docker"
    echo "  $0 dev kubernetes observability"
    echo "  $0 cleanup"
}

# Main execution
main() {
    local command=${1:-setup}
    
    case $command in
        "setup")
            log_info "Starting observability stack setup..."
            log_info "Environment: $ENVIRONMENT"
            log_info "Mode: $MODE"
            log_info "Namespace: $NAMESPACE"
            echo ""
            
            check_prerequisites
            
            if [[ "$MODE" == "docker" ]]; then
                setup_docker_stack
            else
                setup_kubernetes_stack
            fi
            
            configure_grafana
            setup_alerting
            validate_stack
            
            log_success "Observability stack setup completed successfully!"
            ;;
        "validate")
            validate_stack
            ;;
        "cleanup")
            cleanup
            ;;
        "-h"|"--help")
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown command: $command"
            print_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 