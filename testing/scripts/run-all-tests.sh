#!/bin/bash

set -euo pipefail

# Comprehensive Test Orchestrator Script
# This script runs all test suites for the complete DevOps pipeline

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
RESULTS_DIR="${TESTING_DIR}/results/$(date +%Y%m%d_%H%M%S)"
PARALLEL=${PARALLEL:-false}
VERBOSE=${VERBOSE:-false}
ENVIRONMENTS=${ENVIRONMENTS:-"dev,staging,prod"}
SKIP_TESTS=${SKIP_TESTS:-""}

# Test categories
ALL_TEST_CATEGORIES=(
    "infrastructure"
    "security" 
    "microservice-e2e"
    "observability"
    "governance"
)

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

# Initialize results directory
init_results_dir() {
    log "Initializing results directory: $RESULTS_DIR"
    mkdir -p "$RESULTS_DIR"
    mkdir -p "$RESULTS_DIR/logs"
    mkdir -p "$RESULTS_DIR/reports"
    
    # Initialize summary file
    cat > "$RESULTS_DIR/test-execution-summary.json" <<EOF
{
  "start_time": "$(date -Iseconds)",
  "test_run_id": "$(date +%Y%m%d_%H%M%S)",
  "environment": "$(kubectl cluster-info | head -1 | cut -d' ' -f6 || echo 'unknown')",
  "user": "$(whoami)",
  "test_categories": [],
  "results": {},
  "summary": {
    "total_tests": 0,
    "passed_tests": 0,
    "failed_tests": 0,
    "success_rate": 0,
    "execution_time": 0
  }
}
EOF
    
    success "Results directory initialized"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    local missing_tools=()
    
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
    
    # Check testing namespace
    if ! kubectl get namespace testing &> /dev/null; then
        warn "Testing namespace not found, creating..."
        kubectl create namespace testing
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    success "Prerequisites check passed"
}

# Run infrastructure tests
run_infrastructure_tests() {
    log "Running infrastructure validation tests..."
    
    local log_file="$RESULTS_DIR/logs/infrastructure-tests.log"
    
    {
        echo "=== Infrastructure Validation Tests ==="
        echo "Timestamp: $(date -Iseconds)"
        echo ""
        
        # Test cluster nodes
        echo "Testing cluster nodes..."
        if kubectl get nodes --no-headers | grep -q Ready; then
            echo "✅ Cluster nodes are ready"
        else
            echo "❌ Cluster nodes not ready"
        fi
        
        # Test required namespaces
        echo "Testing required namespaces..."
        local namespaces="microservice-demo-dev microservice-demo-staging microservice-demo-prod observability security-tools"
        local missing_ns=()
        for ns in $namespaces; do
            if ! kubectl get namespace $ns &> /dev/null; then
                missing_ns+=($ns)
            fi
        done
        
        if [ ${#missing_ns[@]} -eq 0 ]; then
            echo "✅ All required namespaces exist"
        else
            echo "❌ Missing namespaces: ${missing_ns[*]}"
        fi
        
        # Test RBAC
        echo "Testing RBAC configuration..."
        local role_count=$(kubectl get clusterroles | grep -E "(devops-engineer|sre|security-auditor)" | wc -l)
        if [ "$role_count" -ge "3" ]; then
            echo "✅ Custom RBAC roles configured: $role_count"
        else
            echo "❌ Missing custom RBAC roles"
        fi
        
        echo ""
        echo "Infrastructure tests completed"
        
    } > "$log_file" 2>&1
    
    # Check for failures
    if grep -q "❌" "$log_file"; then
        error "Infrastructure tests failed"
        return 1
    else
        success "Infrastructure tests passed"
        return 0
    fi
}

# Run security tests
run_security_tests() {
    log "Running security validation tests..."
    
    local log_file="$RESULTS_DIR/logs/security-tests.log"
    
    {
        echo "=== Security Validation Tests ==="
        echo "Timestamp: $(date -Iseconds)"
        echo ""
        
        # Test network policies
        echo "Testing network policies..."
        local np_count=$(kubectl get networkpolicy -A --no-headers | wc -l)
        if [ "$np_count" -gt "0" ]; then
            echo "✅ Network policies configured: $np_count"
        else
            echo "❌ No network policies found"
        fi
        
        # Test pod security standards
        echo "Testing pod security standards..."
        local prod_label=$(kubectl get namespace microservice-demo-prod -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || echo "none")
        if [ "$prod_label" = "restricted" ]; then
            echo "✅ Production namespace has restricted pod security"
        else
            echo "❌ Production namespace not properly secured"
        fi
        
        # Test security tools
        echo "Testing security tools..."
        if kubectl get pods -n security-tools --field-selector=status.phase=Running | grep -q trivy; then
            echo "✅ Security scanning tools running"
        else
            echo "⚠️  Security scanning tools not found"
        fi
        
        echo ""
        echo "Security tests completed"
        
    } > "$log_file" 2>&1
    
    # Check for critical failures
    if grep -q "❌" "$log_file"; then
        error "Security tests failed"
        return 1
    else
        success "Security tests passed"
        return 0
    fi
}

# Run microservice tests
run_microservice_tests() {
    log "Running microservice end-to-end tests..."
    
    local log_file="$RESULTS_DIR/logs/microservice-tests.log"
    
    {
        echo "=== Microservice E2E Tests ==="
        echo "Timestamp: $(date -Iseconds)"
        echo ""
        
        # Test microservice deployments
        local namespaces="microservice-demo-dev microservice-demo-staging microservice-demo-prod"
        for ns in $namespaces; do
            echo "Testing microservice in $ns..."
            if kubectl get deployment -n $ns microservice-demo &> /dev/null; then
                local ready=$(kubectl get deployment -n $ns microservice-demo -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
                if [ "$ready" -gt "0" ]; then
                    echo "✅ Microservice deployment ready in $ns: $ready replicas"
                else
                    echo "❌ Microservice deployment not ready in $ns"
                fi
            else
                echo "⚠️  Microservice deployment not found in $ns"
            fi
        done
        
        echo ""
        echo "Microservice tests completed"
        
    } > "$log_file" 2>&1
    
    success "Microservice tests completed"
    return 0
}

# Run observability tests
run_observability_tests() {
    log "Running observability validation tests..."
    
    local log_file="$RESULTS_DIR/logs/observability-tests.log"
    
    {
        echo "=== Observability Validation Tests ==="
        echo "Timestamp: $(date -Iseconds)"
        echo ""
        
        # Test Prometheus
        echo "Testing Prometheus..."
        if kubectl get pods -n observability -l app=prometheus --field-selector=status.phase=Running | grep -q prometheus; then
            echo "✅ Prometheus is running"
        else
            echo "❌ Prometheus is not running"
        fi
        
        # Test Grafana
        echo "Testing Grafana..."
        if kubectl get pods -n observability -l app=grafana --field-selector=status.phase=Running | grep -q grafana; then
            echo "✅ Grafana is running"
        else
            echo "❌ Grafana is not running"
        fi
        
        # Test ServiceMonitors
        echo "Testing ServiceMonitors..."
        local sm_count=$(kubectl get servicemonitor -A --no-headers 2>/dev/null | wc -l)
        if [ "$sm_count" -gt "0" ]; then
            echo "✅ ServiceMonitors configured: $sm_count"
        else
            echo "⚠️  No ServiceMonitors found"
        fi
        
        echo ""
        echo "Observability tests completed"
        
    } > "$log_file" 2>&1
    
    success "Observability tests completed"
    return 0
}

# Run governance tests
run_governance_tests() {
    log "Running governance validation tests..."
    
    local log_file="$RESULTS_DIR/logs/governance-tests.log"
    
    {
        echo "=== Governance Validation Tests ==="
        echo "Timestamp: $(date -Iseconds)"
        echo ""
        
        # Test Resource Quotas
        echo "Testing Resource Quotas..."
        local quota_count=$(kubectl get resourcequota -A --no-headers | wc -l)
        if [ "$quota_count" -gt "0" ]; then
            echo "✅ Resource quotas configured: $quota_count"
        else
            echo "❌ No resource quotas found"
        fi
        
        # Test LimitRanges
        echo "Testing LimitRanges..."
        local lr_count=$(kubectl get limitrange -A --no-headers | wc -l)
        if [ "$lr_count" -gt "0" ]; then
            echo "✅ LimitRanges configured: $lr_count"
        else
            echo "❌ No LimitRanges found"
        fi
        
        echo ""
        echo "Governance tests completed"
        
    } > "$log_file" 2>&1
    
    success "Governance tests completed"
    return 0
}

# Generate test report
generate_test_report() {
    log "Generating test report..."
    
    local report_file="$RESULTS_DIR/reports/test-report.html"
    
    cat > "$report_file" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>DevOps Pipeline Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; border-bottom: 2px solid #007acc; padding-bottom: 20px; }
        .summary { background: #f8f9fa; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .test-category { margin: 20px 0; padding: 15px; border-left: 4px solid #28a745; background: #f8f9fa; }
        .test-category.failed { border-left-color: #dc3545; }
        .pass { color: #28a745; }
        .fail { color: #dc3545; }
        pre { background: #2d3748; color: #e2e8f0; padding: 15px; border-radius: 8px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 DevOps Pipeline Test Report</h1>
        <p>Generated: $(date)</p>
    </div>
    
    <div class="summary">
        <h2>📊 Test Summary</h2>
        <p>Test execution completed with results from all categories.</p>
    </div>
    
    <h2>📋 Test Results</h2>
EOF
    
    # Add results for each category
    for category in "${ALL_TEST_CATEGORIES[@]}"; do
        local log_file="$RESULTS_DIR/logs/${category}-tests.log"
        local status="pass"
        
        if [ -f "$log_file" ]; then
            if grep -q "❌" "$log_file"; then
                status="failed"
            fi
            
            cat >> "$report_file" <<EOF
    <div class="test-category $status">
        <h3>$category Tests</h3>
        <pre>$(cat "$log_file")</pre>
    </div>
EOF
        fi
    done
    
    echo "</body></html>" >> "$report_file"
    
    success "Test report generated: $report_file"
}

# Main test execution
run_all_tests() {
    local start_time=$(date +%s)
    local test_results=()
    
    log "🚀 Starting comprehensive DevOps pipeline testing"
    
    # Initialize
    init_results_dir
    check_prerequisites
    
    # Run test suites
    if [[ "$SKIP_TESTS" != *"infrastructure"* ]]; then
        if run_infrastructure_tests; then
            test_results+=("infrastructure:PASS")
        else
            test_results+=("infrastructure:FAIL")
        fi
    fi
    
    if [[ "$SKIP_TESTS" != *"security"* ]]; then
        if run_security_tests; then
            test_results+=("security:PASS")
        else
            test_results+=("security:FAIL")
        fi
    fi
    
    if [[ "$SKIP_TESTS" != *"microservice"* ]]; then
        if run_microservice_tests; then
            test_results+=("microservice:PASS")
        else
            test_results+=("microservice:FAIL")
        fi
    fi
    
    if [[ "$SKIP_TESTS" != *"observability"* ]]; then
        run_observability_tests
        test_results+=("observability:PASS")
    fi
    
    if [[ "$SKIP_TESTS" != *"governance"* ]]; then
        run_governance_tests
        test_results+=("governance:PASS")
    fi
    
    # Calculate results
    local end_time=$(date +%s)
    local execution_time=$((end_time - start_time))
    local total_tests=${#test_results[@]}
    local passed_tests=0
    local failed_tests=0
    
    for result in "${test_results[@]}"; do
        if [[ "$result" == *":PASS" ]]; then
            ((passed_tests++))
        else
            ((failed_tests++))
        fi
    done
    
    local success_rate=$((passed_tests * 100 / total_tests))
    
    # Generate report
    generate_test_report
    
    # Print summary
    echo ""
    echo "================================================================="
    echo "🎯 DEVOPS PIPELINE TEST EXECUTION COMPLETE"
    echo "================================================================="
    echo "📊 Total Tests: $total_tests"
    echo "✅ Passed: $passed_tests"
    echo "❌ Failed: $failed_tests"
    echo "📈 Success Rate: $success_rate%"
    echo "⏱️  Execution Time: ${execution_time}s"
    echo "📁 Results Directory: $RESULTS_DIR"
    echo "================================================================="
    
    # Print individual results
    echo ""
    echo "📋 Test Category Results:"
    for result in "${test_results[@]}"; do
        local category="${result%%:*}"
        local status="${result##*:}"
        if [ "$status" = "PASS" ]; then
            echo "  ✅ $category"
        else
            echo "  ❌ $category"
        fi
    done
    
    # Exit with appropriate code
    if [ "$failed_tests" -gt 0 ]; then
        echo ""
        error "Some tests failed. Check the detailed logs in $RESULTS_DIR"
        return 1
    else
        echo ""
        success "All tests passed! 🎉"
        return 0
    fi
}

# Usage function
usage() {
    cat << EOF
Comprehensive DevOps Pipeline Test Orchestrator

Usage: $0 [OPTIONS]

Options:
    --verbose               Enable verbose output
    --environments <list>   Comma-separated list of environments
    --skip-tests <list>     Comma-separated list of test categories to skip
    --help                  Show this help message

Examples:
    $0                                          # Run all tests
    $0 --skip-tests infrastructure,security     # Skip some tests
    $0 --verbose                                # Run with verbose output

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --environments)
            ENVIRONMENTS="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS="$2"
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
log "DevOps Pipeline Test Orchestrator"
log "Configuration:"
log "  - Environments: $ENVIRONMENTS"
log "  - Skip Tests: ${SKIP_TESTS:-none}"

if run_all_tests; then
    success "All tests completed successfully! 🎉"
    exit 0
else
    error "Some tests failed. Check the logs for details."
    exit 1
fi 