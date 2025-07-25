# 🔴 Chaos Engineering Documentation

Welcome to the Chaos Engineering documentation! This system implements Netflix-style chaos engineering with AI-powered self-healing capabilities.

## 📋 Table of Contents

- [Overview](#overview)
- [🎛️ Quick Start Control Panel](#-quick-start-control-panel)
- [Chaos Scenarios](#chaos-scenarios)
- [Self-Healing System](#self-healing-system)
- [Monitoring & Alerting](#monitoring--alerting)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

### What is Chaos Engineering?

Chaos Engineering is the discipline of experimenting on a system to build confidence in the system's capability to withstand turbulent conditions in production.

**Core Principles:**
1. **Hypothesize** about steady state behavior
2. **Vary** real-world events to test hypothesis
3. **Minimize** blast radius of experiments
4. **Automate** experiments to run continuously

### Our Implementation

- 🔴 **4 Chaos Scenarios**: Memory leak, slow responses, error injection, CPU spike
- 🤖 **AI-Powered Healing**: Automated detection and recovery using n8n + Cursor AI
- 📊 **Real-time Monitoring**: Prometheus metrics and Grafana dashboards
- 🛡️ **Safety Mechanisms**: Resource limits and health protection
- 🎯 **Production-Ready**: Configurable limits and emergency stops

## 🎛️ Quick Start Control Panel

### 🚀 **1-CLICK CHAOS INJECTION** 

Copy and paste these commands to inject chaos scenarios:

#### 💾 Memory Leak Attack
```bash
# Inject memory leak (1MB/second)
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=memory_leak"

# Expected Response:
# {
#   "chaos_type": "memory_leak",
#   "status": "activated",
#   "details": "Memory leak started - will consume ~1MB/second"
# }
```

#### 🐌 Slow Response Attack  
```bash
# Inject slow responses (2-5 second delays)
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=slow_responses"

# Test the slow responses:
curl -w "@curl-format.txt" "http://localhost:8080/api/v1/hello?name=Test"
```

#### ⚠️ Error Injection Attack
```bash
# Inject random 500 errors (30% failure rate)
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=error_injection"

# Test multiple requests to see random failures:
for i in {1..10}; do curl -s -o /dev/null -w "%{http_code}\n" "http://localhost:8080/api/v1/hello"; done
```

#### 🔥 CPU Spike Attack
```bash
# Inject CPU spike (30 seconds high CPU)
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=cpu_spike"

# Monitor CPU usage:
top -p $(pgrep -f "python.*main.py")
```

#### 🎲 Random Chaos (Surprise Attack!)
```bash
# Let the system choose a random chaos scenario
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=random"
```

### 🛡️ **EMERGENCY HEALING CONTROLS**

#### ⚡ Immediate Recovery
```bash
# STOP ALL CHAOS IMMEDIATELY!
curl -X POST "http://localhost:8080/admin/chaos/heal"

# Expected Response:
# {
#   "status": "healed",
#   "actions_taken": ["memory_leak_stopped", "slow_responses_stopped"],
#   "message": "All chaos scenarios stopped"
# }
```

#### 📊 Status Monitoring
```bash
# Check current chaos status
curl -X GET "http://localhost:8080/admin/chaos/status" | jq

# Check system health
curl -X GET "http://localhost:8080/healthz"
curl -X GET "http://localhost:8080/ready"
```

### 📈 **MONITORING DASHBOARD LINKS**

Open these in your browser to monitor chaos effects:

```bash
# Grafana Dashboards (if running with docker-compose)
echo "🎯 Main Dashboard: http://localhost:3000/d/microservice-overview"
echo "📊 Prometheus: http://localhost:9090/graph" 
echo "🚨 Alertmanager: http://localhost:9093/#/alerts"
echo "⚙️  n8n Workflows: http://localhost:5678"
```

## Chaos Scenarios

### 💾 Memory Leak Scenario

**Purpose**: Test memory monitoring and automatic memory management.

**How it works**:
1. Background thread allocates 1MB every second
2. Memory objects stored in application state
3. Prometheus `chaos_memory_usage_mb` metric increases
4. Alert triggers when memory usage > threshold

**Safety Limits**:
- Maximum 100MB allocation
- Automatic cleanup after 100 objects
- Force garbage collection on healing

**Monitoring**:
```bash
# Watch memory metrics in real-time
watch -n 1 'curl -s http://localhost:8080/metrics | grep chaos_memory_usage_mb'

# Check memory objects count
curl -s http://localhost:8080/admin/chaos/status | jq '.memory_objects_count'
```

### 🐌 Slow Response Scenario

**Purpose**: Test response time monitoring and timeout handling.

**How it works**:
1. Middleware adds 2-5 second delays to API requests
2. Only affects non-admin endpoints
3. Random delay for each request
4. Response time metrics increase

**Testing Commands**:
```bash
# Test response time (install curl-format.txt first)
cat > curl-format.txt << 'EOF'
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
EOF

# Test slow API responses
curl -w "@curl-format.txt" "http://localhost:8080/api/v1/hello"

# Admin endpoints should remain fast
curl -w "@curl-format.txt" "http://localhost:8080/admin/chaos/status"
```

### ⚠️ Error Injection Scenario

**Purpose**: Test error monitoring and error handling resilience.

**How it works**:
1. 30% of API requests return HTTP 500 errors
2. Admin and health endpoints are protected
3. Random selection per request
4. Error rate metrics increase

**Testing Commands**:
```bash
# Test error rate with multiple requests
for i in {1..20}; do 
  status=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/api/v1/hello")
  echo "Request $i: HTTP $status"
done

# Count success vs error rates
echo "Success rate test:"
success=0; total=20
for i in $(seq 1 $total); do
  if curl -s -f "http://localhost:8080/api/v1/hello" > /dev/null; then
    ((success++))
  fi
done
echo "Success: $success/$total ($(($success * 100 / $total))%)"
```

### 🔥 CPU Spike Scenario

**Purpose**: Test CPU monitoring and resource management.

**How it works**:
1. Background thread runs intensive calculations
2. Duration limited to 30 seconds
3. CPU usage increases significantly
4. Automatic cleanup after timeout

**Monitoring Commands**:
```bash
# Monitor CPU usage during spike
echo "Starting CPU monitoring..."
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=cpu_spike"

# Watch CPU usage (macOS)
top -l 5 -s 2 -pid $(pgrep -f "python.*main.py") | grep "CPU usage"

# Watch CPU usage (Linux)
top -b -n 10 -d 2 -p $(pgrep -f "python.*main.py") | grep "Cpu(s)"
```

## Self-Healing System

### Architecture Overview

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Chaos     │───▶│  Prometheus  │───▶│ Alertmanager│
│ Engineering │    │   Metrics    │    │   Rules     │
└─────────────┘    └──────────────┘    └─────────────┘
                                              │
                                              ▼
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Healing   │◀───│     n8n      │◀───│   Webhook   │
│   Report    │    │  Workflow    │    │   Alert     │
└─────────────┘    └──────────────┘    └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │  Cursor AI  │
                   │  Analysis   │
                   └─────────────┘
```

### n8n Workflow Steps

1. **📥 Webhook Reception**: Receives Prometheus alerts
2. **🔍 Alert Analysis**: Parses alert data and chaos type
3. **💚 Health Check**: Verifies service status
4. **🎯 Strategy Selection**: Chooses healing approach
5. **🧠 AI Analysis**: Runs Cursor AI for recommendations
6. **🔧 Healing Execution**: Calls healing endpoints
7. **🧪 Health Validation**: Tests multiple endpoints
8. **📊 Report Generation**: Creates comprehensive report
9. **💾 Report Storage**: Stores results for analysis
10. **✅ Completion**: Marks workflow as complete

### Automated Healing Demo

Run the complete chaos → detection → healing cycle:

```bash
# 1. Start the complete observability stack
docker-compose up -d

# 2. Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# 3. Run the full demo script
./automation/scripts/demo-chaos-healing.sh memory_leak

# The script will:
# - Inject memory leak chaos
# - Wait for Prometheus alerts
# - Trigger n8n healing workflow  
# - Show real-time healing progress
# - Display final healing report
```

### Manual Healing Workflow Test

```bash
# 1. Inject chaos
curl -X POST "http://localhost:8080/admin/chaos/inject?chaos_type=memory_leak"

# 2. Wait for alerts (check Alertmanager)
curl -s "http://localhost:9093/api/v1/alerts" | jq '.data[] | select(.labels.alertname=="ChaosMemoryLeak")'

# 3. Trigger n8n workflow manually
curl -X POST "http://localhost:5678/webhook/chaos-alert" \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [{
      "labels": {
        "alertname": "ChaosMemoryLeak",
        "chaos_type": "memory_leak",
        "severity": "critical"
      }
    }]
  }'

# 4. Check healing reports
curl -s "http://localhost:8080/admin/healing-reports" | jq
```

## Monitoring & Alerting

### Prometheus Metrics

The system exposes chaos-specific metrics:

```prometheus
# Chaos event counter
chaos_events_total{chaos_type="general",event_type="memory_leak"} 5

# Healing event counter  
chaos_healing_total{chaos_type="memory_leak",source="n8n_workflow"} 2

# Current memory usage from chaos
chaos_memory_usage_mb 45

# Standard HTTP metrics also affected
http_requests_total{method="GET",endpoint="/api/v1/hello",status="500"} 15
http_request_duration_seconds_sum{method="GET",endpoint="/api/v1/hello"} 125.5
```

### Alert Rules

Key alerts configured in Prometheus:

```yaml
# Memory leak detection
- alert: ChaosMemoryLeak
  expr: chaos_memory_usage_mb > 50
  for: 30s
  labels:
    chaos_type: memory_leak
    severity: critical

# High error rate detection  
- alert: ChaosHighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
  for: 1m
  labels:
    chaos_type: error_injection
    severity: warning

# Slow response detection
- alert: ChaosSlowResponses
  expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
  for: 2m
  labels:
    chaos_type: slow_responses
    severity: warning

# High CPU usage detection
- alert: ChaosCPUSpike
  expr: rate(process_cpu_seconds_total[1m]) > 0.8
  for: 30s
  labels:
    chaos_type: cpu_spike
    severity: critical
```

### Grafana Dashboard Queries

Example dashboard queries for chaos monitoring:

```prometheus
# Memory usage trend
chaos_memory_usage_mb

# Error rate percentage
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100

# Response time 95th percentile
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Active chaos count
count by (chaos_type) (chaos_events_total)

# Healing success rate
rate(chaos_healing_total[1h])
```

## Best Practices

### 🎯 Planning Chaos Experiments

#### Hypothesis-Driven Testing
```markdown
**Hypothesis**: "If memory usage increases rapidly, our monitoring will detect it within 2 minutes and automatically trigger healing"

**Experiment**: Inject memory leak chaos for 5 minutes
**Success Criteria**: 
- Alert fires within 2 minutes
- Automated healing triggered within 3 minutes  
- System recovered within 5 minutes
- No service downtime for end users
```

#### Blast Radius Control
- ✅ **Start Small**: Test single chaos scenario first
- ✅ **Time Limits**: Set maximum experiment duration
- ✅ **Resource Limits**: Use built-in safety mechanisms
- ✅ **Rollback Ready**: Have healing procedures tested
- ✅ **Team Coordination**: Notify team before experiments

### 🛡️ Safety Guidelines

#### Pre-Experiment Checklist
```bash
# 1. Verify monitoring is working
curl -s "http://localhost:9090/api/v1/query?query=up" | jq '.data.result[] | select(.metric.job=="microservice")'

# 2. Test healing endpoints
curl -X POST "http://localhost:8080/admin/chaos/heal"

# 3. Check system health
curl "http://localhost:8080/healthz" && curl "http://localhost:8080/ready"

# 4. Verify n8n workflow exists
curl -s "http://localhost:5678/webhook/chaos-alert" -d '{"test": true}'

# 5. Check alert manager
curl -s "http://localhost:9093/api/v1/status" | jq '.status'
```

#### During Experiments
- 📊 **Monitor Continuously**: Watch dashboards actively
- ⏰ **Time Boxing**: Set strict time limits
- 👥 **Team Awareness**: Keep team informed
- 📝 **Document Observations**: Record all findings
- 🚨 **Quick Response**: Be ready to heal immediately

#### Post-Experiment Analysis
```bash
# 1. Collect healing reports
curl -s "http://localhost:8080/admin/healing-reports" | jq '.summary'

# 2. Analyze metrics
curl -s "http://localhost:9090/api/v1/query_range?query=chaos_events_total&start=$(date -d '1 hour ago' +%s)&end=$(date +%s)&step=60"

# 3. Review logs
docker logs microservice-app | grep -i chaos | tail -20

# 4. Check for any lingering effects
curl -s "http://localhost:8080/admin/chaos/status" | jq '.active_chaos'
```

### 📈 Metrics and KPIs

#### Chaos Engineering Success Metrics
```bash
# Mean Time To Detection (MTTD)
# Time from chaos injection to alert firing
grep "chaos.*injection" logs | head -1
grep "alert.*firing" alertmanager-logs | head -1

# Mean Time To Recovery (MTTR)  
# Time from alert to full system recovery
grep "healing.*complete" logs | tail -1

# Success Rate
# Percentage of chaos experiments that heal successfully
curl -s "http://localhost:8080/admin/healing-reports" | jq '.summary.successful_healings / .total_reports * 100'

# False Positive Rate
# Percentage of alerts that were not caused by actual issues
# (Manual review required)
```

#### Service Resilience Metrics
- **Availability**: Percentage uptime during chaos
- **Performance**: Response time degradation
- **Error Rate**: Increase in failed requests
- **Recovery Time**: Time to return to baseline

## Troubleshooting

### Common Issues

#### 1. Chaos Not Injecting

**Symptoms**: Chaos injection returns success but no effects observed

**Diagnosis**:
```bash
# Check service health
curl "http://localhost:8080/healthz"

# Check chaos status
curl "http://localhost:8080/admin/chaos/status" | jq '.active_chaos'

# Check application logs
docker logs microservice-app | grep -i chaos | tail -10
```

**Solutions**:
- Ensure service is healthy before injecting chaos
- Verify chaos type is spelled correctly
- Check if chaos was already active (`already_active` status)

#### 2. Alerts Not Firing

**Symptoms**: Chaos active but no Prometheus alerts

**Diagnosis**:
```bash
# Check Prometheus targets
curl -s "http://localhost:9090/api/v1/targets" | jq '.data.activeTargets[] | select(.job=="microservice")'

# Check specific metrics
curl -s "http://localhost:9090/api/v1/query?query=chaos_memory_usage_mb"

# Check alert rules
curl -s "http://localhost:9090/api/v1/rules" | jq '.data.groups[] | select(.name=="chaos-alerts")'
```

**Solutions**:
- Verify Prometheus is scraping metrics endpoint
- Check alert rule thresholds are appropriate
- Ensure sufficient time has passed for alert evaluation

#### 3. n8n Workflow Not Triggering

**Symptoms**: Alerts firing but n8n workflow not executing

**Diagnosis**:
```bash
# Check alertmanager webhook configuration
curl -s "http://localhost:9093/api/v1/status" | jq '.config.route'

# Test webhook endpoint directly
curl -X POST "http://localhost:5678/webhook/chaos-alert" \
  -H "Content-Type: application/json" \
  -d '{"test": "webhook"}'

# Check n8n workflow status
curl -s "http://localhost:5678/webhook/chaos-alert" | jq
```

**Solutions**:
- Verify alertmanager webhook URL is correct
- Check n8n service is running and accessible
- Ensure workflow is activated in n8n
- Review n8n execution logs

#### 4. Healing Not Working

**Symptoms**: Healing endpoint called but chaos continues

**Diagnosis**:
```bash
# Check healing response
curl -X POST "http://localhost:8080/admin/chaos/heal" | jq

# Verify chaos status after healing
curl "http://localhost:8080/admin/chaos/status" | jq '.active_chaos'

# Check background threads
ps aux | grep -i python | grep -v grep
```

**Solutions**:
- Wait a few seconds for background threads to stop
- Check for multiple chaos injection (race conditions)
- Restart the application if threads are stuck

### Emergency Procedures

#### Complete System Reset

If chaos experiments go wrong, use this emergency reset:

```bash
#!/bin/bash
echo "🚨 EMERGENCY CHAOS RESET 🚨"

# 1. Stop all chaos immediately
echo "1. Stopping all chaos..."
curl -X POST "http://localhost:8080/admin/chaos/heal"

# 2. Restart the application
echo "2. Restarting application..."
docker-compose restart microservice

# 3. Wait for health checks
echo "3. Waiting for health checks..."
for i in {1..30}; do
  if curl -sf "http://localhost:8080/healthz" > /dev/null; then
    echo "✅ Service healthy after $i seconds"
    break
  fi
  echo "⏳ Waiting for health... ($i/30)"
  sleep 1
done

# 4. Verify clean state
echo "4. Verifying clean state..."
curl -s "http://localhost:8080/admin/chaos/status" | jq '.active_chaos'

echo "🎯 Emergency reset complete!"
```

#### Monitoring Stack Reset

If monitoring isn't working:

```bash
#!/bin/bash
echo "🔄 MONITORING STACK RESET 🔄"

# Restart observability services
docker-compose restart prometheus grafana alertmanager n8n

# Wait for services
sleep 30

# Verify each service
services=("prometheus:9090" "grafana:3000" "alertmanager:9093" "n8n:5678")
for service in "${services[@]}"; do
  host=${service%:*}
  port=${service#*:}
  if curl -sf "http://localhost:$port" > /dev/null; then
    echo "✅ $host is healthy"
  else
    echo "❌ $host is not responding"
  fi
done

echo "🎯 Monitoring reset complete!"
```

### Getting Help

#### Debug Information Collection

When reporting issues, collect this information:

```bash
#!/bin/bash
echo "📋 CHAOS ENGINEERING DEBUG INFO 📋"

# System information
echo "=== SYSTEM INFO ==="
uname -a
docker --version
docker-compose --version

# Service status
echo "=== SERVICE STATUS ==="
docker-compose ps

# Current chaos state
echo "=== CHAOS STATUS ==="
curl -s "http://localhost:8080/admin/chaos/status" | jq

# Recent healing reports
echo "=== HEALING REPORTS ==="
curl -s "http://localhost:8080/admin/healing-reports" | jq '.summary'

# Prometheus targets
echo "=== PROMETHEUS TARGETS ==="
curl -s "http://localhost:9090/api/v1/targets" | jq '.data.activeTargets[] | {job: .job, health: .health}'

# Active alerts
echo "=== ACTIVE ALERTS ==="
curl -s "http://localhost:9093/api/v1/alerts" | jq '.data[] | {alertname: .labels.alertname, state: .status.state}'

# Recent logs
echo "=== RECENT LOGS ==="
docker logs microservice-app --tail 20

echo "📧 Please include this information when reporting issues!"
```

Save this information and share it when seeking help with chaos engineering issues.

---

**🎯 Ready to embrace chaos!** Start with small experiments and gradually increase complexity. Remember: the goal is to build confidence in your system's resilience, not to break things! 🛡️ 