#!/bin/bash

echo "🚀 Deploying EFK Stack for Logging..."

# Check if running on OpenShift or Kubernetes
if command -v oc &> /dev/null; then
    KUBECTL="oc"
    echo "✅ Detected OpenShift environment"
else
    KUBECTL="kubectl"
    echo "✅ Detected Kubernetes environment"
fi

# Function to wait for deployment
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    local timeout=${3:-300}
    
    echo "⏳ Waiting for $deployment to be ready..."
    $KUBECTL wait --for=condition=available --timeout=${timeout}s deployment/$deployment -n $namespace
}

# Function to wait for statefulset
wait_for_statefulset() {
    local namespace=$1
    local statefulset=$2
    local timeout=${3:-300}
    
    echo "⏳ Waiting for $statefulset to be ready..."
    $KUBECTL rollout status statefulset/$statefulset -n $namespace --timeout=${timeout}s
}

# Function to wait for daemonset
wait_for_daemonset() {
    local namespace=$1
    local daemonset=$2
    local timeout=${3:-300}
    
    echo "⏳ Waiting for $daemonset to be ready..."
    $KUBECTL rollout status daemonset/$daemonset -n $namespace --timeout=${timeout}s
}

# Create namespace if it doesn't exist
echo "📁 Creating logging namespace..."
$KUBECTL create namespace logging --dry-run=client -o yaml | $KUBECTL apply -f -

# Apply the EFK stack
echo "📦 Deploying EFK components..."
$KUBECTL apply -f efk-stack-complete.yaml

# Wait for Elasticsearch to be ready
echo "🔍 Waiting for Elasticsearch..."
wait_for_statefulset logging elasticsearch 600

# Check Elasticsearch health
echo "🏥 Checking Elasticsearch health..."
$KUBECTL exec -n logging elasticsearch-0 -- curl -s http://localhost:9200/_cluster/health?pretty

# Wait for Kibana
echo "🎨 Waiting for Kibana..."
wait_for_deployment logging kibana 300

# Wait for Fluentd
echo "📝 Waiting for Fluentd..."
wait_for_daemonset logging fluentd 300

# Get Kibana route (OpenShift) or create port-forward (Kubernetes)
if [ "$KUBECTL" = "oc" ]; then
    echo "🌐 Getting Kibana route..."
    KIBANA_URL=$($KUBECTL get route kibana -n logging -o jsonpath='{.spec.host}')
    echo "✅ Kibana is accessible at: https://$KIBANA_URL"
else
    echo "🌐 Creating port-forward for Kibana..."
    echo "Run the following command to access Kibana:"
    echo "$KUBECTL port-forward -n logging svc/kibana 5601:5601"
    echo "Then access Kibana at: http://localhost:5601"
fi

# Display status
echo ""
echo "📊 EFK Stack Status:"
echo "===================="
$KUBECTL get all -n logging

echo ""
echo "✅ EFK Stack deployment complete!"
echo ""
echo "📝 Next steps:"
echo "1. Access Kibana and create index patterns"
echo "2. Configure your applications to send logs to Fluentd"
echo "3. Monitor logs in Kibana dashboards"

# Create index pattern helper
cat > create-kibana-index.sh << 'EOF'
#!/bin/bash
# Helper script to create Kibana index pattern

KIBANA_URL=${1:-"http://localhost:5601"}

# Wait for Kibana to be fully ready
echo "Waiting for Kibana to be ready..."
until curl -s "$KIBANA_URL/api/status" | grep -q '"level":"available"'; do
    sleep 5
done

# Create index pattern
echo "Creating index pattern..."
curl -X POST "$KIBANA_URL/api/saved_objects/index-pattern/kubernetes-*" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "kubernetes-*",
      "timeFieldName": "@timestamp"
    }
  }'

echo "Index pattern created successfully!"
EOF

chmod +x create-kibana-index.sh

echo ""
echo "💡 To automatically create Kibana index pattern, run:"
echo "./create-kibana-index.sh <kibana-url>"