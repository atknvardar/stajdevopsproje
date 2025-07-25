#!/bin/bash

echo "=== Testing Lightweight Logging Stack ==="
echo ""

# Test Loki
echo "1. Testing Loki health..."
LOKI_POD=$(oc get pod -n logging-lite -l app=loki -o jsonpath='{.items[0].metadata.name}')
oc exec -n logging-lite $LOKI_POD -- wget -q -O- http://localhost:3100/ready && echo "✅ Loki is ready" || echo "❌ Loki not ready"

echo ""
echo "2. Testing Grafana access..."
echo "Grafana URL: https://grafana-logging-lite.apps-crc.testing"
echo "Default credentials: admin/admin"

echo ""
echo "3. Checking weather-app logs in Loki..."
oc exec -n logging-lite $LOKI_POD -- wget -q -O- "http://localhost:3100/loki/api/v1/query?query={app=\"weather-app\"}" | grep -q "values" && echo "✅ Logs found in Loki" || echo "⚠️  No logs found yet"

echo ""
echo "4. Current resource usage:"
echo "Logging-lite namespace:"
oc top pods -n logging-lite 2>/dev/null || echo "Metrics not available"

echo ""
echo "5. Log collection status:"
oc logs -n logging-lite daemonset/promtail --tail=5

echo ""
echo "6. To view logs in Grafana:"
echo "   - Open https://grafana-logging-lite.apps-crc.testing"
echo "   - Login with admin/admin"
echo "   - Go to Explore"
echo "   - Select Loki datasource"
echo "   - Query: {app=\"weather-app\"}"

echo ""
echo "7. Quick log query via CLI:"
cat > query-loki.sh << 'EOF'
#!/bin/bash
LOKI_POD=$(oc get pod -n logging-lite -l app=loki -o jsonpath='{.items[0].metadata.name}')
QUERY="${1:-{app=\"weather-app\"}}"

echo "Querying Loki with: $QUERY"
oc exec -n logging-lite $LOKI_POD -- wget -q -O- \
  "http://localhost:3100/loki/api/v1/query_range?query=$QUERY&limit=10" | \
  python3 -m json.tool 2>/dev/null || echo "No results or invalid JSON"
EOF

chmod +x query-loki.sh
echo "Created query-loki.sh - Usage: ./query-loki.sh '{app=\"weather-app\"} |= \"error\"'"