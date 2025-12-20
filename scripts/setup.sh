#!/bin/bash

set -e

PROJECT_ID="25RP19824-Turikumwenimana"
DOCKER_USER="danieltn889"

echo "=========================================="
echo "Setting up $PROJECT_ID DevOps Project"
echo "=========================================="

# Check prerequisites
echo "[1/7] Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "Docker not found. Please install Docker."; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "Docker Compose not found. Please install Docker Compose."; exit 1; }
echo "✓ Docker and Docker Compose found"

# Create logs directory
echo "[2/7] Creating logs directory..."
mkdir -p logs
echo "✓ Logs directory created"

# Build Docker images
echo "[3/7] Building Docker images..."
docker-compose build --no-cache
echo "✓ Docker images built"

# Start services
echo "[4/7] Starting services..."
docker-compose up -d
echo "✓ Services started"

# Wait for database to be ready
echo "[5/7] Waiting for database to be ready..."
for i in {1..30}; do
  if docker exec 25rp19824-turikumwenimana-db pg_isready -U expenseuser >/dev/null 2>&1; then
    echo "✓ Database is ready"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 2
done

# Wait for API to be ready
echo "[6/7] Waiting for API to be ready..."
for i in {1..30}; do
  if curl -s http://localhost:3000/health >/dev/null 2>&1; then
    echo "✓ API is ready"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 2
done

# Display status
echo "[7/7] Displaying service status..."
docker-compose ps
echo ""
echo "=========================================="
echo "✓ Setup Complete!"
echo "=========================================="
echo "API:       http://localhost:3000"
echo "Frontend:  http://localhost"
echo "Database:  localhost:5432"
echo "=========================================="
