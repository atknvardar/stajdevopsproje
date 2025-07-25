# EFK Stack Deployment and Operations Guide

## Overview
This guide covers the deployment, configuration, and management of the EFK (Elasticsearch, Fluentd, Kibana) stack for centralized logging in OpenShift/Kubernetes.

## Architecture
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Application │────▶│   Fluentd   │────▶│Elasticsearch│
│    Pods     │     │ (DaemonSet) │     │ (StatefulSet)│
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                                         ┌─────────────┐
                                         │   Kibana    │
                                         │(Deployment) │
                                         └─────────────┘
```

## Quick Start

### 1. Deploy the EFK Stack
```bash
# Deploy all components
./deploy-efk-stack.sh

# Or manually
kubectl apply -f efk-stack-complete.yaml
```

### 2. Verify Deployment
```bash
# Check all pods are running
kubectl get pods -n logging

# Check Elasticsearch health
kubectl exec -n logging elasticsearch-0 -- curl -s http://localhost:9200/_cluster/health?pretty

# Check Fluentd logs
kubectl logs -n logging -l app=fluentd --tail=50
```

### 3. Access Kibana
```bash
# For OpenShift
oc get route kibana -n logging

# For Kubernetes
kubectl port-forward -n logging svc/kibana 5601:5601
# Access at http://localhost:5601
```

## Configuration

### Elasticsearch Configuration
- **Memory**: Set via `ES_JAVA_OPTS` environment variable
- **Storage**: Uses PersistentVolumeClaim (10Gi by default)
- **Performance**: Single-node setup for development, scale for production

### Fluentd Configuration
Key configuration areas in the ConfigMap:
1. **Input Sources**: Container logs from `/var/log/containers`
2. **Parsing**: Multi-format parser for JSON and text logs
3. **Filtering**: Kubernetes metadata enrichment
4. **Output**: Elasticsearch with logstash format

### Kibana Configuration
- Default index pattern: `kubernetes-*`
- Time field: `@timestamp`
- Accessible via OpenShift Route with TLS

## Application Integration

### 1. Structured Logging (Recommended)
Configure your application to output JSON logs:

```python
import json
import logging

# Python example
logger = logging.getLogger(__name__)
logger.info(json.dumps({
    "message": "User logged in",
    "user_id": "12345",
    "action": "login",
    "timestamp": datetime.utcnow().isoformat()
}))
```

### 2. Log Annotations
Add annotations to your pods:
```yaml
metadata:
  annotations:
    fluentd.io/parser: json
    fluentd.io/exclude: "false"
```

### 3. Environment Variables
Include context in logs:
```yaml
env:
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
```

## Kibana Usage

### Creating Index Patterns
1. Navigate to Stack Management → Index Patterns
2. Create pattern: `kubernetes-*`
3. Select `@timestamp` as time field

### Creating Dashboards
1. Go to Dashboard → Create new
2. Add visualizations:
   - Log volume over time
   - Top error messages
   - Logs by namespace
   - Response time percentiles

### Useful Queries
```
# All errors
level:ERROR OR level:error

# Specific namespace
kubernetes.namespace_name:"weather-app"

# Specific pod
kubernetes.pod_name:"weather-app-*"

# Time range with error
@timestamp:[now-1h TO now] AND level:ERROR

# Specific service errors
kubernetes.labels.app:"weather-app" AND level:ERROR
```

## Troubleshooting

### Elasticsearch Issues
```bash
# Check cluster health
kubectl exec -n logging elasticsearch-0 -- curl -s http://localhost:9200/_cluster/health?pretty

# Check indices
kubectl exec -n logging elasticsearch-0 -- curl -s http://localhost:9200/_cat/indices?v

# Check disk usage
kubectl exec -n logging elasticsearch-0 -- df -h

# View Elasticsearch logs
kubectl logs -n logging elasticsearch-0
```

### Fluentd Issues
```bash
# Check Fluentd status
kubectl get daemonset -n logging fluentd

# View Fluentd logs
kubectl logs -n logging -l app=fluentd --tail=100

# Check buffer status
kubectl exec -n logging -l app=fluentd -- ls -la /var/log/fluentd-buffers/

# Test Fluentd configuration
kubectl exec -n logging -l app=fluentd -- fluentd --dry-run -c /fluentd/etc/fluent.conf
```

### Kibana Issues
```bash
# Check Kibana logs
kubectl logs -n logging -l app=kibana --tail=100

# Test Elasticsearch connectivity from Kibana
kubectl exec -n logging -l app=kibana -- curl -s http://elasticsearch:9200/
```

## Performance Tuning

### Elasticsearch
```yaml
# Increase heap size
env:
- name: ES_JAVA_OPTS
  value: "-Xms2g -Xmx2g"

# Enable persistent storage
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    accessModes: [ "ReadWriteOnce" ]
    resources:
      requests:
        storage: 50Gi
```

### Fluentd
```yaml
# Adjust buffer settings
<buffer>
  @type memory
  flush_mode interval
  flush_interval 10s
  flush_thread_count 4
  chunk_limit_size 5M
  queue_limit_length 16
</buffer>
```

## Maintenance

### Log Rotation
```bash
# Create index lifecycle policy
curl -X PUT "localhost:9200/_ilm/policy/kubernetes-policy" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_size": "50GB",
            "max_age": "7d"
          }
        }
      },
      "delete": {
        "min_age": "30d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'
```

### Backup
```bash
# Create snapshot repository
curl -X PUT "localhost:9200/_snapshot/backup" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/backup"
  }
}'

# Create snapshot
curl -X PUT "localhost:9200/_snapshot/backup/snapshot_1?wait_for_completion=true"
```

## Security Considerations

1. **Network Policies**: Restrict traffic between components
2. **RBAC**: Limit Fluentd permissions to required resources
3. **TLS**: Enable TLS for Elasticsearch and Kibana
4. **Authentication**: Configure Kibana authentication
5. **Log Sanitization**: Remove sensitive data before logging

## Monitoring the EFK Stack

### Prometheus Metrics
```yaml
# ServiceMonitor for Elasticsearch
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: elasticsearch-monitor
  namespace: logging
spec:
  selector:
    matchLabels:
      app: elasticsearch
  endpoints:
  - port: rest
    path: /_prometheus/metrics
```

### Key Metrics to Monitor
- Elasticsearch cluster health
- Index size and count
- Fluentd buffer queue length
- Kibana response time
- Log ingestion rate

## Common Issues and Solutions

### Issue: Logs not appearing in Kibana
1. Check Fluentd is running on all nodes
2. Verify Elasticsearch is receiving data
3. Ensure index pattern is created correctly
4. Check application is producing logs

### Issue: Elasticsearch disk full
1. Implement index lifecycle management
2. Increase PVC size
3. Delete old indices
4. Adjust retention policy

### Issue: High memory usage
1. Tune Java heap sizes
2. Limit Fluentd buffer size
3. Implement log sampling
4. Scale horizontally

## Best Practices

1. **Use structured logging** (JSON format)
2. **Include correlation IDs** in logs
3. **Set appropriate log levels** per environment
4. **Monitor EFK stack health**
5. **Implement log retention policies**
6. **Use index templates** for consistent mapping
7. **Regular backups** of Elasticsearch data
8. **Security hardening** in production

## Useful Commands

```bash
# Get all EFK resources
kubectl get all -n logging

# Restart Fluentd (to reload config)
kubectl rollout restart daemonset/fluentd -n logging

# Scale Elasticsearch
kubectl scale statefulset elasticsearch --replicas=3 -n logging

# Delete old indices
curl -X DELETE "localhost:9200/kubernetes-2024.01.*"

# Check Fluentd buffer
kubectl exec -n logging daemonset/fluentd -- du -sh /var/log/fluentd-buffers/
```