#!/bin/bash
# Remove Docker images older than the last 3 builds to manage disk space
echo "=== Cleaning up old Docker images ==="
docker images --filter "reference=*/region-health-monitor" --format "{{.ID}} {{.Tag}}" | \
    sort -t' ' -k2 -rn | \
    tail -n +4 | \
    awk '{print $1}' | \
    xargs -r docker rmi -f
echo "=== Cleanup complete ==="
docker images --filter "reference=*/region-health-monitor"
