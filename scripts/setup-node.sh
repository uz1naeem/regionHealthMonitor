#!/bin/bash
set -e

echo "=== Installing kind ==="
if ! command -v kind &> /dev/null; then
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
fi

echo "=== Installing kubectl ==="
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
fi

echo "=== Creating kind cluster ==="
if ! kind get clusters | grep -q health-monitor; then
    kind create cluster --name health-monitor
fi

echo "=== Cluster ready ==="
kubectl get nodes
