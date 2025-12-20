#!/bin/bash

set -e

PROJECT_ID="25RP19824-Turikumwenimana"

echo "=========================================="
echo "Destroying $PROJECT_ID Infrastructure"
echo "=========================================="

read -p "Are you sure? This will delete all containers and data. (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Cancelled."
  exit 0
fi

echo "[1/3] Stopping and removing containers..."
docker-compose down -v || echo "Docker Compose not running"
echo "✓ Containers removed"

echo "[2/3] Removing Docker images..."
docker rmi -f danieltn889/25rp19824-turikumwenimana-api:latest 2>/dev/null || true
docker rmi -f danieltn889/25rp19824-turikumwenimana-frontend:latest 2>/dev/null || true
echo "✓ Images removed"

echo "[3/3] Cleaning up volumes..."
docker volume prune -f || true
echo "✓ Volumes cleaned"

echo "=========================================="
echo "✓ Cleanup Complete!"
echo "=========================================="
