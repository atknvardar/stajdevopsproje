#!/bin/bash

# 🎭 Chaos Engineering + AI Healing Demo Script
# This script demonstrates the complete chaos → detection → healing cycle

set -e

# Configuration
MICROSERVICE_URL="${MICROSERVICE_URL:-http://localhost:8080}"
N8N_URL="${N8N_URL:-http://localhost:5678}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}" 
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $1${NC}"
}

log_info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] ✅ $1${NC}"
}

# Check if services are running
check_service() {
    local url="$1"
    local name="$2"
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        log_success "$name is running ($url)"
        return 0
    else
        log_error "$name is not accessible ($url)"
        return 1
    fi
}

# Wait for condition with timeout
wait_for_condition() {
    local condition_func="$1"
    local timeout="$2"
    local message="$3"
    
    log_info "Waiting for: $message"
    
    local count=0
    while ! $condition_func && [ $count -lt $timeout ]; do
        sleep 1
        count=$((count + 1))
        if [ $((count % 10)) -eq 0 ]; then
            log_info "Still waiting... ($count/${timeout}s)"
        fi
    done
    
    if [ $count -ge $timeout ]; then
        log_error "Timeout waiting for: $message"
        return 1
    fi
    
    log_success "Condition met: $message"
    return 0
}

# Check if metrics show chaos is active
check_chaos_active() {
    local chaos_status
    chaos_status=$(curl -s "$MICROSERVICE_URL/admin/chaos/status" | jq -r '.chaos_count // 0' 2>/dev/null || echo "0")
    [ "$chaos_status" -gt 0 ]
}

# Check if metrics show chaos is healed
check_chaos_healed() {
    local chaos_status
    chaos_status=$(curl -s "$MICROSERVICE_URL/admin/chaos/status" | jq -r '.chaos_count // 0' 2>/dev/null || echo "0")
    [ "$chaos_status" -eq 0 ]
}

# Inject chaos scenario
inject_chaos() {
    local chaos_type="$1"
    
    log "🔴 STEP 1: Injecting chaos scenario: $chaos_type"
    
    local response
    response=$(curl -s -X POST "$MICROSERVICE_URL/admin/chaos/inject?chaos_type=$chaos_type")
    
    if echo "$response" | jq -e '.status' > /dev/null 2>&1; then
        local status
        status=$(echo "$response" | jq -r '.status')
        local details
        details=$(echo "$response" | jq -r '.details // "No details"')
        
        if [ "$status" = "activated" ]; then
            log_success "Chaos injected: $chaos_type"
            log_info "Details: $details"
        else
            log_warning "Chaos injection status: $status"
        fi
    else
        log_error "Failed to inject chaos: $response"
        return 1
    fi
}

# Monitor system metrics
monitor_metrics() {
    log "📊 STEP 2: Monitoring system metrics for chaos detection..."
    
    # Show current chaos status
    local status
    status=$(curl -s "$MICROSERVICE_URL/admin/chaos/status")
    echo "$status" | jq '.system_impact' 2>/dev/null || echo "Could not parse system impact"
    
    # Wait for monitoring to detect the issue
    log_info "Waiting for monitoring system to detect the issue..."
    sleep 10
    
    # Check Prometheus metrics (if available)
    if check_service "$PROMETHEUS_URL" "Prometheus" > /dev/null 2>&1; then
        log_info "Prometheus is available - checking for alerts"
        # You could add actual Prometheus query here
    fi
}

# Simulate n8n workflow (since we might not have it fully running)
simulate_healing_workflow() {
    log "🤖 STEP 3: Simulating automated healing workflow..."
    
    # Simulate the n8n workflow steps
    log_info "🚨 Alert received by n8n webhook"
    sleep 2
    
    log_info "📊 Parsing alert data and checking service status"
    local service_status
    service_status=$(curl -s "$MICROSERVICE_URL/admin/chaos/status")
    echo "Current chaos state: $(echo "$service_status" | jq -r '.active_chaos[]' 2>/dev/null || echo 'none')"
    sleep 2
    
    log_info "🎯 Determining healing strategy"
    sleep 1
    
    log_info "🧠 Running Cursor AI analysis..."
    # Run our actual Cursor analysis script
    if [ -f "automation/scripts/cursor-analyze.sh" ]; then
        local chaos_type
        chaos_type=$(echo "$service_status" | jq -r '.active_chaos[0] // "unknown"' 2>/dev/null)
        log_info "Analyzing chaos type: $chaos_type"
        
        # Run the actual script (but capture output)
        automation/scripts/cursor-analyze.sh "$chaos_type" "Automated healing analysis" "$(pwd)" > /tmp/cursor-analysis.json 2>&1 || true
        
        if [ -f /tmp/cursor-analysis.json ]; then
            log_info "Cursor analysis completed - recommendations available"
        fi
    fi
    sleep 3
    
    log_info "🔧 Preparing healing actions based on AI analysis"
    sleep 1
    
    log_info "✅ Executing healing endpoint..."
}

# Execute healing
execute_healing() {
    log "✅ STEP 4: Executing automated healing..."
    
    local healing_response
    healing_response=$(curl -s -X POST "$MICROSERVICE_URL/admin/chaos/heal")
    
    if echo "$healing_response" | jq -e '.status' > /dev/null 2>&1; then
        local status
        status=$(echo "$healing_response" | jq -r '.status')
        local actions
        actions=$(echo "$healing_response" | jq -r '.actions_taken[]' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
        
        if [ "$status" = "healed" ]; then
            log_success "Healing executed successfully"
            log_info "Actions taken: $actions"
        else
            log_warning "Healing status: $status"
        fi
    else
        log_error "Failed to execute healing: $healing_response"
        return 1
    fi
}

# Verify healing success
verify_healing() {
    log "🧪 STEP 5: Verifying healing success..."
    
    # Wait for chaos to be fully healed
    if wait_for_condition check_chaos_healed 30 "Chaos scenarios to be stopped"; then
        log_success "All chaos scenarios have been stopped"
    else
        log_warning "Some chaos scenarios may still be active"
    fi
    
    # Test all endpoints
    local endpoints=("/healthz" "/ready" "/api/v1/hello" "/metrics")
    local passed=0
    local total=${#endpoints[@]}
    
    log_info "Testing service endpoints..."
    
    for endpoint in "${endpoints[@]}"; do
        if curl -s -f "$MICROSERVICE_URL$endpoint" > /dev/null 2>&1; then
            log_success "✓ $endpoint - OK"
            passed=$((passed + 1))
        else
            log_error "✗ $endpoint - FAILED"
        fi
    done
    
    log_info "Endpoint test results: $passed/$total passed"
    
    if [ $passed -eq $total ]; then
        log_success "All endpoints are healthy - healing successful!"
        return 0
    else
        log_warning "Some endpoints failed - partial healing"
        return 1
    fi
}

# Generate healing report
generate_report() {
    log "📊 STEP 6: Generating healing report..."
    
    local report="{
        \"demo_id\": \"$(date +%s)\",
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"demo_type\": \"automated_chaos_healing\",
        \"chaos_scenario\": \"$1\",
        \"healing_success\": $2,
        \"endpoints_tested\": 4,
        \"test_summary\": \"Demo completed successfully\"
    }"
    
    # Store the report
    curl -s -X POST "$MICROSERVICE_URL/admin/healing-report" \
        -H "Content-Type: application/json" \
        -d "$report" > /dev/null || true
    
    log_success "Healing report generated and stored"
}

# Main demo function
run_demo() {
    local chaos_type="${1:-random}"
    
    echo -e "${PURPLE}"
    echo "🎭 CHAOS ENGINEERING + AI HEALING DEMO"
    echo "======================================="
    echo -e "${NC}"
    
    log "Starting automated chaos engineering and healing demonstration"
    log_info "Chaos scenario: $chaos_type"
    log_info "Target service: $MICROSERVICE_URL"
    
    # Pre-flight checks
    log "🔍 Pre-flight checks..."
    if ! check_service "$MICROSERVICE_URL/healthz" "Microservice"; then
        log_error "Microservice is not running. Please start with: docker-compose up"
        exit 1
    fi
    
    # Steps
    inject_chaos "$chaos_type" || exit 1
    sleep 2
    
    monitor_metrics || exit 1
    sleep 2
    
    simulate_healing_workflow || exit 1
    sleep 2
    
    execute_healing || exit 1
    sleep 2
    
    if verify_healing; then
        healing_success="true"
    else
        healing_success="false"
    fi
    
    generate_report "$chaos_type" "$healing_success"
    
    # Final summary
    echo -e "${PURPLE}"
    echo "🎯 DEMO COMPLETED!"
    echo "================="
    echo -e "${NC}"
    
    if [ "$healing_success" = "true" ]; then
        log_success "✅ Complete chaos → detection → healing cycle successful!"
    else
        log_warning "⚠️  Demo completed with partial success"
    fi
    
    log_info "View healing reports: $MICROSERVICE_URL/admin/healing-reports"
    log_info "Monitor metrics: $GRAFANA_URL"
    log_info "Check logs: docker-compose logs microservice"
    
    echo ""
    echo -e "${CYAN}🚀 Try different chaos scenarios:${NC}"
    echo -e "${CYAN}  ./automation/scripts/demo-chaos-healing.sh memory_leak${NC}"
    echo -e "${CYAN}  ./automation/scripts/demo-chaos-healing.sh slow_responses${NC}"
    echo -e "${CYAN}  ./automation/scripts/demo-chaos-healing.sh error_injection${NC}"
    echo -e "${CYAN}  ./automation/scripts/demo-chaos-healing.sh cpu_spike${NC}"
}

# Help function
show_help() {
    echo "🎭 Chaos Engineering + AI Healing Demo"
    echo ""
    echo "Usage: $0 [CHAOS_TYPE]"
    echo ""
    echo "CHAOS_TYPE can be:"
    echo "  memory_leak     - Simulate memory leak"
    echo "  slow_responses  - Add artificial delays"
    echo "  error_injection - Inject random 500 errors"
    echo "  cpu_spike       - Create CPU intensive load"
    echo "  random          - Randomly select scenario (default)"
    echo ""
    echo "Example:"
    echo "  $0 memory_leak"
    echo ""
}

# Main execution
case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    *)
        run_demo "$1"
        ;;
esac 