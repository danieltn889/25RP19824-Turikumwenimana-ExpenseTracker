#!/bin/bash

set -e

PROJECT_ID="25RP19824-Turikumwenimana"

echo "=========================================="
echo "Docker Compose Test for $PROJECT_ID"
echo "=========================================="
echo ""

# Test 1: Validate docker-compose.yml
echo "[1/5] Validating docker-compose.yml..."
docker-compose config > /dev/null
echo "✓ Configuration valid"
echo ""

# Test 2: Build images
echo "[2/5] Building Docker images..."
docker-compose build
echo "✓ Images built"
echo ""

# Test 3: Start services
echo "[3/5] Starting services..."
docker-compose up -d
echo "✓ Services started"
echo ""

# Test 4: Wait and verify
echo "[4/5] Verifying services..."
sleep 10

STATUS=$(docker-compose ps)
echo "$STATUS"

if echo "$STATUS" | grep -q "Up"; then
  echo "✓ Services are running"
else
  echo "✗ Some services are not running"
  docker-compose logs
  exit 1
fi
echo ""

# Test 5: Cleanup
echo "[5/5] Cleaning up..."
docker-compose down
echo "✓ Cleanup completed"
echo ""

echo "=========================================="
echo "Docker Compose Test Complete"
echo "=========================================="
