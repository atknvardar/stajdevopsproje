#!/bin/bash

echo "=== OpenShift Native Logging Guide ==="
echo ""
echo "Since the cluster has resource constraints, here's how to use OpenShift's built-in logging:"
echo ""

# Check if weather-app is running
echo "1. Checking weather-app pods..."
oc get pods -n weather-app

echo ""
echo "2. View logs for a specific pod:"
echo "   oc logs -n weather-app <pod-name>"
echo ""

echo "3. View logs with timestamps:"
echo "   oc logs -n weather-app <pod-name> --timestamps"
echo ""

echo "4. Follow logs in real-time:"
echo "   oc logs -n weather-app <pod-name> -f"
echo ""

echo "5. View logs from all containers in a pod:"
echo "   oc logs -n weather-app <pod-name> --all-containers"
echo ""

echo "6. Export logs to a file:"
echo "   oc logs -n weather-app <pod-name> > weather-app-logs.txt"
echo ""

echo "7. Search for errors in logs:"
echo "   oc logs -n weather-app <pod-name> | grep -i error"
echo ""

echo "8. View logs from previous container instance:"
echo "   oc logs -n weather-app <pod-name> --previous"
echo ""

echo "9. Using OpenShift Console:"
echo "   - Open the OpenShift web console"
echo "   - Navigate to Workloads → Pods"
echo "   - Select your namespace (weather-app)"
echo "   - Click on a pod"
echo "   - Go to the Logs tab"
echo ""

echo "10. Create a simple log aggregation script:"
cat > collect-weather-logs.sh << 'EOF'
#!/bin/bash
# Simple script to collect weather-app logs

NAMESPACE="weather-app"
OUTPUT_DIR="weather-logs-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "Collecting logs from $NAMESPACE namespace..."

# Get all pods in namespace
for pod in $(oc get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}'); do
    echo "Collecting logs from pod: $pod"
    oc logs -n $NAMESPACE $pod --all-containers > "$OUTPUT_DIR/$pod.log" 2>&1
    
    # Try to get previous logs if available
    oc logs -n $NAMESPACE $pod --previous --all-containers > "$OUTPUT_DIR/$pod-previous.log" 2>&1
done

echo "Logs collected in $OUTPUT_DIR/"

# Create summary
echo "=== Log Summary ===" > "$OUTPUT_DIR/summary.txt"
echo "Collection Date: $(date)" >> "$OUTPUT_DIR/summary.txt"
echo "Namespace: $NAMESPACE" >> "$OUTPUT_DIR/summary.txt"
echo "" >> "$OUTPUT_DIR/summary.txt"

# Count errors and warnings
for logfile in $OUTPUT_DIR/*.log; do
    if [ -s "$logfile" ]; then
        echo "File: $(basename $logfile)" >> "$OUTPUT_DIR/summary.txt"
        echo "  Total lines: $(wc -l < $logfile)" >> "$OUTPUT_DIR/summary.txt"
        echo "  Errors: $(grep -i error $logfile | wc -l)" >> "$OUTPUT_DIR/summary.txt"
        echo "  Warnings: $(grep -i warn $logfile | wc -l)" >> "$OUTPUT_DIR/summary.txt"
        echo "" >> "$OUTPUT_DIR/summary.txt"
    fi
done

echo "Summary saved in $OUTPUT_DIR/summary.txt"
EOF

chmod +x collect-weather-logs.sh

echo ""
echo "Created collect-weather-logs.sh script"
echo "Run it with: ./collect-weather-logs.sh"
echo ""

# Check if OpenShift Logging Operator is available
echo "=== Checking for OpenShift Logging Operator ==="
if oc get csv -n openshift-logging 2>/dev/null | grep -q cluster-logging; then
    echo "✅ OpenShift Logging Operator is installed"
    echo "   You can configure centralized logging through the operator"
else
    echo "ℹ️  OpenShift Logging Operator is not installed"
    echo "   Using oc logs commands is the recommended approach"
fi

echo ""
echo "=== Alternative: Using stern for multi-pod log tailing ==="
echo "If you have stern installed, you can tail logs from multiple pods:"
echo "  stern -n weather-app weather-app"
echo ""
echo "To install stern:"
echo "  wget https://github.com/stern/stern/releases/download/v1.22.0/stern_1.22.0_linux_amd64.tar.gz"
echo "  tar xzf stern_1.22.0_linux_amd64.tar.gz"
echo "  sudo mv stern /usr/local/bin/"