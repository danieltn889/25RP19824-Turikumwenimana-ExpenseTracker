#!/bin/bash

PROJECT_ID="25RP19824-Turikumwenimana"

echo "=========================================="
echo "Health Check for $PROJECT_ID"
echo "=========================================="

# Check API health
echo "[1/4] Checking API Health..."
if curl -s http://localhost:3000/health | jq . 2>/dev/null; then
  echo "✓ API is healthy"
else
  echo "✗ API is not responding"
fi

# Check Frontend health
echo ""
echo "[2/4] Checking Frontend Health..."
if curl -s http://localhost/health 2>/dev/null | grep -q "healthy"; then
  echo "✓ Frontend is healthy"
else
  echo "✗ Frontend is not responding"
fi

# Check Database connection
echo ""
echo "[3/4] Checking Database..."
if docker exec 25rp19824-turikumwenimana-db pg_isready -U expenseuser >/dev/null 2>&1; then
  echo "✓ Database is ready"
else
  echo "✗ Database is not responding"
fi

# Display Docker containers
echo ""
echo "[4/4] Container Status:"
docker-compose ps

echo ""
echo "=========================================="
echo "Health Check Complete"
echo "=========================================="
