#!/bin/bash

set -e

PROJECT_ID="25RP19824-Turikumwenimana"
NAMESPACE="25rp19824-turikumwenimana"

echo "=========================================="
echo "Deploying $PROJECT_ID to Kubernetes"
echo "=========================================="

# Create namespace
echo "[1/7] Creating namespace..."
kubectl create namespace $NAMESPACE || echo "Namespace already exists"
echo "✓ Namespace ready: $NAMESPACE"

# Apply secrets and configs
echo "[2/7] Applying secrets and configs..."
kubectl apply -f kubernetes/secrets.yaml
echo "✓ Secrets and configs applied"

# Deploy database
echo "[3/7] Deploying database..."
kubectl apply -f kubernetes/database-statefulset.yaml
kubectl wait --for=condition=ready pod -l app=25rp19824-turikumwenimana-db -n $NAMESPACE --timeout=300s || true
echo "✓ Database deployed"

# Deploy API
echo "[4/7] Deploying API..."
kubectl apply -f kubernetes/api-deployment.yaml
kubectl wait --for=condition=available --timeout=300s deployment/25rp19824-turikumwenimana-api -n $NAMESPACE || true
echo "✓ API deployed"

# Deploy Frontend
echo "[5/7] Deploying frontend..."
kubectl apply -f kubernetes/frontend-deployment.yaml
kubectl wait --for=condition=available --timeout=300s deployment/25rp19824-turikumwenimana-frontend -n $NAMESPACE || true
echo "✓ Frontend deployed"

# Apply ingress
echo "[6/7] Applying ingress..."
kubectl apply -f kubernetes/ingress.yaml || echo "Ingress already exists"
echo "✓ Ingress applied"

# Display status
echo "[7/7] Displaying deployment status..."
kubectl get all -n $NAMESPACE
echo ""
echo "=========================================="
echo "✓ Kubernetes Deployment Complete!"
echo "=========================================="
kubectl get svc -n $NAMESPACE
echo "=========================================="
