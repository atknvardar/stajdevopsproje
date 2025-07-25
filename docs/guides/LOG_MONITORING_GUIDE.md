# 📋 Complete Log Monitoring Guide

## 🐳 Docker Container Logs

### Basic Log Commands

```bash
# 🚀 Microservice Logs (Chaos Engineering + API)
docker-compose logs -f microservice                 # Follow live logs
docker-compose logs --tail=100 microservice         # Last 100 lines
docker-compose logs --since=1h microservice         # Logs from last hour

# 🤖 n8n Workflow Automation Logs  
docker-compose logs -f n8n                          # Follow n8n workflow logs
docker-compose logs --tail=50 n8n                   # Last 50 lines

# 📊 Prometheus Monitoring Logs
docker-compose logs -f prometheus                   # Follow Prometheus logs
docker-compose logs --tail=50 prometheus            # Recent Prometheus activity

# 📈 Grafana Dashboard Logs
docker-compose logs -f grafana                      # Follow Grafana logs
docker-compose logs --tail=50 grafana               # Recent dashboard activity

# 🚨 Alertmanager Logs
docker-compose logs -f alertmanager                 # Follow alert processing logs
docker-compose logs --tail=50 alertmanager          # Recent alerts

# 🔍 Jaeger Tracing Logs
docker-compose logs -f jaeger                       # Follow distributed tracing logs
docker-compose logs --tail=50 jaeger                # Recent tracing activity

# 📋 All Services Together
docker-compose logs -f                              # Follow all services
docker-compose logs --tail=200                      # Last 200 lines from all
docker-compose logs --since=30m                     # All logs from last 30 minutes
```

### Advanced Log Filtering

```bash
# Filter by log level (if service supports it)
docker-compose logs microservice | grep ERROR
docker-compose logs microservice | grep WARNING
docker-compose logs microservice | grep INFO

# Search for specific events
docker-compose logs microservice | grep chaos
docker-compose logs microservice | grep healing
docker-compose logs microservice | grep n8n
docker-compose logs n8n | grep webhook
```

## 🌐 Web-Based Log Interfaces

### 1. **Grafana Dashboard** - http://localhost:3000
- **Login**: admin / admin
- **Location**: Explore → Logs
- **Features**: 
  - Real-time log streaming
  - Log correlation with metrics
  - Custom dashboards
  - Alert history

### 2. **Jaeger Tracing UI** - http://localhost:16686  
- **Features**:
  - Distributed trace logs
  - Request flow visualization
  - Performance analysis
  - Error tracking

### 3. **Prometheus Targets** - http://localhost:9090/targets
- **Features**:
  - Service health status
  - Scraping logs
  - Target discovery logs

### 4. **n8n Workflow Executions** - http://localhost:5678
- **Login**: admin / admin123
- **Location**: Executions tab
- **Features**:
  - Workflow execution logs
  - Node-by-node execution details
  - Error logs and debugging
  - Webhook request logs

## 📊 Application-Specific Logs

### 🚀 Microservice Application Logs

**View recent API activity:**
```bash
curl http://localhost:8081/admin/chaos/status | jq '.recent_events'
```

**View healing reports:**
```bash
curl http://localhost:8081/admin/healing-reports | jq '.reports'
```

**View chaos history:**
```bash
curl http://localhost:8081/admin/chaos/status | jq '.recent_events[-10:]'
```

### 🤖 Automation Pipeline Logs

**Chaos healing pipeline logs:**
```bash
# Run with verbose output
./automation/scripts/auto-chaos-healing-pipeline.sh memory_leak

# Check Cursor AI analysis logs
ls -la /tmp/cursor-analysis-*.log

# View pipeline execution history
curl http://localhost:8081/admin/healing-reports | jq '.summary'
```

## 🔍 Real-Time Monitoring Commands

### Live Chaos Engineering Activity
```bash
# Monitor chaos events in real-time
while true; do 
  echo "=== $(date) ==="
  curl -s http://localhost:8081/admin/chaos/status | jq '.active_chaos'
  sleep 5
done
```

### Live n8n Webhook Activity  
```bash
# Monitor n8n webhook logs
docker-compose logs -f n8n | grep webhook
```

### Live System Health
```bash
# Monitor all endpoints
watch -n 5 'curl -s http://localhost:8081/healthz && echo " | " && curl -s http://localhost:5678/healthz'
```

## 📁 Log File Locations

### Inside Containers
```bash
# Access container filesystem
docker-compose exec microservice /bin/bash
docker-compose exec n8n /bin/sh
docker-compose exec prometheus /bin/sh

# Microservice log files (inside container)
docker-compose exec microservice ls -la /app/logs/        # If configured
docker-compose exec microservice tail -f /app/uvicorn.log # If configured

# n8n log files (inside container)  
docker-compose exec n8n ls -la ~/.n8n/logs/
```

### Host System Logs
```bash
# Docker daemon logs (macOS)
tail -f ~/Library/Containers/com.docker.docker/Data/log/host/docker.log

# Container logs on host (Linux/macOS)
find /var/lib/docker/containers -name "*.log" | grep microservice
```

## 🚨 Emergency Debugging

### When Services are Down
```bash
# Check container status
docker-compose ps

# Check container health
docker-compose exec microservice curl localhost:8080/healthz

# Restart problematic service
docker-compose restart microservice

# Full restart with logs
docker-compose down && docker-compose up -d && docker-compose logs -f
```

### Debug Specific Issues

**Chaos Engineering Issues:**
```bash
# Check chaos state
curl http://localhost:8081/admin/chaos/status | jq '.'

# Force heal all chaos
curl -X POST http://localhost:8081/admin/chaos/heal

# Check healing history
curl http://localhost:8081/admin/healing-reports | jq '.reports[-5:]'
```

**n8n Workflow Issues:**
```bash
# Check n8n health
curl http://localhost:5678/healthz

# Check webhook endpoint
curl -X POST http://localhost:5678/webhook/chaos-alert -H "Content-Type: application/json" -d '{"test": true}'

# View n8n execution logs
docker-compose logs n8n | grep -A 10 -B 10 "workflow"
```

**Network Issues:**
```bash
# Test service connectivity
docker-compose exec microservice curl http://n8n:5678/healthz
docker-compose exec n8n curl http://microservice:8080/healthz

# Check Docker networks
docker network ls
docker network inspect stajdevopsproje_monitoring
```

## 📊 Structured Logging Examples

### JSON Log Parsing
```bash
# Parse microservice structured logs
docker-compose logs microservice | grep -o '{.*}' | jq '.'

# Extract error logs only
docker-compose logs microservice | grep ERROR | tail -20

# Parse chaos events
curl -s http://localhost:8081/admin/chaos/status | jq '.recent_events[] | select(.event_type == "healing")'
```

### Performance Monitoring
```bash
# Monitor response times
while true; do
  time curl -s http://localhost:8081/api/v1/hello > /dev/null
  sleep 1
done

# Monitor memory usage in chaos scenarios
watch -n 2 'curl -s http://localhost:8081/admin/chaos/status | jq ".system_impact"'
```

## 🎯 Quick Reference Commands

```bash
# Essential log monitoring commands
alias logs-micro='docker-compose logs -f microservice'
alias logs-n8n='docker-compose logs -f n8n'  
alias logs-all='docker-compose logs -f --tail=100'
alias status-chaos='curl -s http://localhost:8081/admin/chaos/status | jq "."'
alias status-healing='curl -s http://localhost:8081/admin/healing-reports | jq ".summary"'

# Pipeline monitoring
alias run-pipeline='./automation/scripts/auto-chaos-healing-pipeline.sh'
alias check-health='curl -s http://localhost:8081/healthz && curl -s http://localhost:5678/healthz'
```

---

## 🚀 Pro Tips

1. **Use multiple terminals** - Run logs in different terminals for parallel monitoring
2. **Save frequently used commands** as aliases or scripts
3. **Monitor trends** - Look for patterns in chaos scenarios and healing success rates
4. **Set up alerts** - Configure Grafana alerts for critical log events
5. **Regular log rotation** - Prevent log files from growing too large
6. **Correlation** - Use timestamps to correlate events across different services

This guide covers all the essential locations and methods for monitoring your complete DevOps automation stack! 🎉 