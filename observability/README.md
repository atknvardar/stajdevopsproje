# Observability Stack

A comprehensive monitoring, logging, and alerting solution for the microservice demo application, featuring Prometheus, Grafana, Loki, and AlertManager.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Microservice   │    │   Node Exporter │    │     cAdvisor    │
│      Demo       │────▶│   (System)      │────▶│  (Containers)   │
│   (App Metrics) │    │    Metrics      │    │    Metrics      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                         PROMETHEUS                              │
│                    (Metrics Collection)                         │
└─────────────────────────────────────────────────────────────────┘
         │                                               │
         ▼                                               ▼
┌─────────────────┐                             ┌─────────────────┐
│   AlertManager  │                             │     Grafana     │
│   (Alerting)    │                             │ (Visualization) │
└─────────────────┘                             └─────────────────┘
         │                                               │
         ▼                                               ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      Email      │    │     Slack       │    │   Dashboards    │
│  Notifications  │    │  Notifications  │    │    & Alerts     │
└─────────────────┘    └─────────────────┘    └─────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Application    │    │   Container     │    │     System      │
│      Logs       │────▶│     Logs        │────▶│      Logs       │
│                 │    │   (Promtail)    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                           LOKI                                  │
│                    (Log Aggregation)                            │
└─────────────────────────────────────────────────────────────────┘
```

## 📦 Components

### Core Monitoring Stack
- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization and dashboarding  
- **Loki** - Log aggregation and storage
- **AlertManager** - Alert handling and routing
- **Promtail** - Log shipping agent

### Exporters and Collectors
- **Node Exporter** - System-level metrics
- **cAdvisor** - Container resource metrics
- **Blackbox Exporter** - Endpoint monitoring and probing

### Optional Components
- **Jaeger** - Distributed tracing (optional)
- **Grafana Image Renderer** - Dashboard PDF/PNG export

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose (for local development)
- kubectl and Helm (for Kubernetes deployment)
- 8GB RAM and 4 CPU cores recommended

### Local Development (Docker)

```bash
# Start the complete observability stack
./scripts/setup-observability.sh local docker

# Access the services
# Grafana:    http://localhost:3000 (admin/admin123)
# Prometheus: http://localhost:9090
# Loki:       http://localhost:3100
# AlertMgr:   http://localhost:9093
```

### Production (Kubernetes)

```bash
# Deploy to Kubernetes with Helm
./scripts/setup-observability.sh prod kubernetes observability

# Or manual deployment
kubectl apply -f k8s/ -n observability
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Deployment environment | `local` |
| `LOG_LEVEL` | Application log level | `INFO` |
| `METRICS_ENABLED` | Enable metrics collection | `true` |
| `TRACING_ENABLED` | Enable distributed tracing | `false` |

### Prometheus Configuration
Located in `prometheus/prometheus.yaml`:
- **Scrape interval**: 15s
- **Retention**: 15 days
- **Storage**: Local TSDB

### Grafana Configuration
Located in `grafana/grafana.ini`:
- **Admin user**: admin
- **Admin password**: admin123
- **Dashboards**: Auto-provisioned

### AlertManager Configuration
Located in `alertmanager/alertmanager.yml`:
- **Email notifications**: Configured for critical alerts
- **Slack integration**: Multiple channels by severity
- **Routing**: Environment and component-based

## 📊 Dashboards

### Microservice Overview Dashboard
- **Request Rate**: HTTP requests per second by endpoint
- **Error Rate**: HTTP 5xx error percentage  
- **Response Time**: p50, p95, p99 latency percentiles
- **Resource Usage**: CPU and memory consumption
- **Service Availability**: Uptime and health status

### Infrastructure Dashboard
- **Node Metrics**: CPU, memory, disk, network usage
- **Container Metrics**: Resource usage per container
- **Cluster Health**: Pod status and resource quotas

### Application Dashboard
- **Business Metrics**: Custom application KPIs
- **User Experience**: Response times and error rates
- **Performance**: Throughput and latency trends

## 🚨 Alerting Rules

### Critical Alerts (Immediate Response)
- **Service Down**: Any instance unavailable > 1 minute
- **High Error Rate**: >10% 5xx errors for 2 minutes
- **Critical Resource Usage**: >95% memory or CPU
- **Pod Crash Loop**: Container restarting repeatedly

### Warning Alerts (Monitor Closely)
- **High Resource Usage**: >85% memory/CPU for 10 minutes
- **Elevated Error Rate**: >5% 5xx errors for 5 minutes
- **Slow Response Time**: p95 latency >1s for 10 minutes
- **Pod Restarts**: Frequent restarts detected

### Info Alerts (Awareness)
- **Deployment Events**: New versions deployed
- **Configuration Changes**: Config updates applied
- **Scaling Events**: HPA scaling actions

## 📋 Log Management

### Log Sources
- **Application Logs**: Structured JSON logs from microservice
- **Container Logs**: Docker container stdout/stderr
- **System Logs**: Operating system logs
- **Audit Logs**: Security and compliance events

### Log Formats
```json
{
  "timestamp": "2023-12-01T10:00:00.000Z",
  "level": "INFO",
  "message": "Request processed successfully",
  "module": "api",
  "trace_id": "abc123",
  "span_id": "def456",
  "method": "GET",
  "path": "/api/v1/hello",
  "status": 200,
  "duration": 0.025
}
```

### Log Queries (LogQL)
```logql
# Error logs from microservice
{job="microservice-demo"} |= "level=ERROR"

# High latency requests
{job="microservice-demo"} | json | duration > 1.0

# Requests by status code
rate({job="microservice-demo"} | json | status="200" [5m])
```

## 🔍 Monitoring Queries (PromQL)

### Application Metrics
```promql
# Request rate
rate(http_requests_total{job="microservice-demo"}[5m])

# Error rate
rate(http_requests_total{job="microservice-demo",status=~"5.."}[5m]) / 
rate(http_requests_total{job="microservice-demo"}[5m])

# Response time percentiles
histogram_quantile(0.95, 
  rate(http_request_duration_seconds_bucket{job="microservice-demo"}[5m])
)

# Service availability
up{job="microservice-demo"}
```

### Infrastructure Metrics
```promql
# CPU usage by pod
rate(container_cpu_usage_seconds_total{container="microservice-demo"}[5m])

# Memory usage by pod
container_memory_usage_bytes{container="microservice-demo"}

# Disk usage
(node_filesystem_size_bytes - node_filesystem_free_bytes) / 
node_filesystem_size_bytes
```

## 🛠️ Maintenance

### Daily Tasks
- Monitor dashboard for anomalies
- Review critical alerts
- Check log volumes and retention
- Validate backup processes

### Weekly Tasks
- Review and tune alerting thresholds
- Analyze performance trends
- Update dashboard queries
- Clean up old data if needed

### Monthly Tasks
- Review monitoring coverage
- Update alerting rules
- Optimize query performance
- Assess storage usage

## 🐛 Troubleshooting

### Common Issues

#### Prometheus Not Scraping Metrics
```bash
# Check target status
curl http://localhost:9090/api/v1/targets

# Verify service discovery
curl http://localhost:9090/api/v1/label/__name__/values

# Test connectivity
curl http://microservice-demo:8080/metrics
```

#### Grafana Dashboard Not Loading
```bash
# Check datasource connection
curl http://localhost:3000/api/datasources/proxy/1/api/v1/query?query=up

# Verify permissions
docker logs grafana

# Reset admin password
docker exec -it grafana grafana-cli admin reset-admin-password admin123
```

#### Loki Not Receiving Logs
```bash
# Check Promtail status
curl http://localhost:9080/targets

# Verify log path permissions
ls -la /var/log/

# Test Loki API
curl http://localhost:3100/ready
```

#### AlertManager Not Sending Alerts
```bash
# Check configuration
curl http://localhost:9093/api/v1/status

# Verify routing
curl http://localhost:9093/api/v1/receivers

# Test webhook
curl -X POST http://localhost:9093/api/v1/alerts
```

### Performance Optimization

#### Prometheus Optimization
```yaml
# Reduce scrape interval for high-volume metrics
scrape_interval: 30s

# Increase retention for long-term analysis
retention.time: 30d

# Configure recording rules for complex queries
rules:
  - record: job:http_requests:rate5m
    expr: rate(http_requests_total[5m])
```

#### Grafana Optimization
```yaml
# Enable query caching
query_cache_enabled: true

# Limit concurrent queries
max_concurrent_queries: 20

# Use dashboard folders for organization
folders: true
```

### Data Retention Policies
- **Metrics**: 15 days (adjustable based on storage)
- **Logs**: 7 days (configurable per log level)
- **Traces**: 24 hours (for performance analysis)

## 🔐 Security

### Authentication and Authorization
- **Grafana**: Admin/viewer roles, LDAP integration
- **Prometheus**: Basic auth with reverse proxy
- **AlertManager**: Webhook authentication

### Network Security
- **TLS**: Enabled for external communications
- **Firewall**: Restricted port access
- **VPN**: Required for production access

### Data Protection
- **Encryption**: At rest and in transit
- **Backup**: Regular automated backups
- **Retention**: Compliant data lifecycle

## 📈 Scaling

### Horizontal Scaling
- **Prometheus**: Federation for multi-cluster
- **Grafana**: Load balancer with session affinity
- **Loki**: Microservices mode for high volume

### Vertical Scaling
- **Memory**: Increase for larger retention
- **CPU**: Scale for query performance
- **Storage**: SSD for better performance

## 🔗 Integration

### CI/CD Pipeline Integration
- Automated dashboard deployment
- Alert rule validation
- Performance regression detection

### External Services
- **PagerDuty**: Critical alert escalation
- **Slack**: Team notifications
- **Email**: Management reporting

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [LogQL Tutorial](https://grafana.com/docs/loki/latest/logql/)

## 🆘 Support

For issues and questions:
1. Check troubleshooting section above
2. Review logs in Grafana Explore
3. Consult component documentation
4. Contact the DevOps team

---

**Last Updated**: December 2023  
**Version**: 1.0.0  
**Maintainer**: DevOps Team 