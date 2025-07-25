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
