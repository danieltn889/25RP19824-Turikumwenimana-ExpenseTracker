#!/bin/bash

PROJECT_ID="25RP19824-Turikumwenimana"
DOCKER_USER="danieltn889"

echo "=========================================="
echo "Security Scan for $PROJECT_ID"
echo "=========================================="
echo ""

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
  echo "Installing Trivy..."
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
fi

echo "[1/3] Scanning API Image..."
trivy image --severity HIGH,CRITICAL $DOCKER_USER/25rp19824-turikumwenimana-api:latest || echo "Scan completed with warnings"
echo ""

echo "[2/3] Scanning Frontend Image..."
trivy image --severity HIGH,CRITICAL $DOCKER_USER/25rp19824-turikumwenimana-frontend:latest || echo "Scan completed with warnings"
echo ""

echo "[3/3] Scanning Filesystem..."
trivy fs --severity HIGH,CRITICAL . || echo "Scan completed with warnings"
echo ""

echo "=========================================="
echo "Security Scan Complete"
echo "=========================================="
