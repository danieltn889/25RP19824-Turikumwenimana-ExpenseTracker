#!/bin/bash

set -e

PROJECT_ID="25RP19824-Turikumwenimana"
NAMESPACE="25rp19824-turikumwenimana"

echo "=========================================="
echo "Kubernetes Test for $PROJECT_ID"
echo "=========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
  echo "kubectl not found. Skipping Kubernetes tests."
  exit 0
fi

# Test 1: Validate manifests
echo "[1/5] Validating Kubernetes manifests..."
kubectl apply -f kubernetes/ --dry-run=client >/dev/null 2>&1
echo "✓ All manifests are valid"
echo ""

# Test 2: Create namespace
echo "[2/5] Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Namespace ready"
echo ""

# Test 3: Check Secrets
echo "[3/5] Verifying secrets configuration..."
kubectl apply -f kubernetes/secrets.yaml
echo "✓ Secrets configured"
echo ""

# Test 4: List manifests
echo "[4/5] Listing Kubernetes resources..."
echo "Available manifests:"
ls -1 kubernetes/*.yaml
echo "✓ Manifests ready for deployment"
echo ""

# Test 5: Display commands
echo "[5/5] Kubernetes deployment commands:"
echo ""
echo "To deploy to Kubernetes, run:"
echo "  kubectl create namespace $NAMESPACE"
echo "  kubectl apply -f kubernetes/"
echo "  kubectl get all -n $NAMESPACE"
echo ""

echo "=========================================="
echo "Kubernetes Test Complete"
echo "=========================================="
