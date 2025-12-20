#!/bin/bash

set -e

PROJECT_ID="25RP19824-Turikumwenimana"
DOCKER_USER="danieltn889"
PASS=0
FAIL=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Testing $PROJECT_ID - Complete Test Suite"
echo "=========================================="
echo ""

# Function to print test results
test_result() {
  if [ $1 -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}: $2"
    ((PASS++))
  else
    echo -e "${RED}✗ FAIL${NC}: $2"
    ((FAIL++))
  fi
}

# ==================== TEST 1: PREREQUISITES ====================
echo -e "${YELLOW}[TEST 1/8] Checking Prerequisites${NC}"
echo "---"

# Check Docker
command -v docker >/dev/null 2>&1
test_result $? "Docker installed"

# Check Docker Compose
command -v docker-compose >/dev/null 2>&1
test_result $? "Docker Compose installed"

# Check curl
command -v curl >/dev/null 2>&1
test_result $? "curl installed"

echo ""

# ==================== TEST 2: ENVIRONMENT ====================
echo -e "${YELLOW}[TEST 2/8] Checking Environment Configuration${NC}"
echo "---"

# Check .env file
[ -f .env ]
test_result $? ".env file exists"

# Check required environment variables
grep -q "PROJECT_ID" .env
test_result $? "PROJECT_ID configured"

grep -q "DOCKER_USERNAME" .env
test_result $? "DOCKER_USERNAME configured"

grep -q "DB_USER" .env
test_result $? "DB_USER configured"

echo ""

# ==================== TEST 3: FILE STRUCTURE ====================
echo -e "${YELLOW}[TEST 3/8] Checking Project Structure${NC}"
echo "---"

[ -d "api-service" ]
test_result $? "API service directory exists"

[ -d "frontend-service" ]
test_result $? "Frontend service directory exists"

[ -d "kubernetes" ]
test_result $? "Kubernetes directory exists"

[ -d "terraform" ]
test_result $? "Terraform directory exists"

[ -d "ansible" ]
test_result $? "Ansible directory exists"

[ -d "monitoring" ]
test_result $? "Monitoring directory exists"

[ -d "scripts" ]
test_result $? "Scripts directory exists"

[ -f "docker-compose.yml" ]
test_result $? "docker-compose.yml exists"

[ -f "init-db.sql" ]
test_result $? "init-db.sql exists"

echo ""

# ==================== TEST 4: DOCKER IMAGES ====================
echo -e "${YELLOW}[TEST 4/8] Checking Docker Images${NC}"
echo "---"

# Check if docker-compose can build
docker-compose build --dry-run >/dev/null 2>&1
test_result $? "Docker Compose configuration valid"

# Check Dockerfiles exist
[ -f "api-service/Dockerfile" ]
test_result $? "API Dockerfile exists"

[ -f "frontend-service/Dockerfile" ]
test_result $? "Frontend Dockerfile exists"

echo ""

# ==================== TEST 5: DOCKER COMPOSE ====================
echo -e "${YELLOW}[TEST 5/8] Testing Docker Compose Deployment${NC}"
echo "---"

# Start services
echo "Starting services (this may take a minute)..."
docker-compose up -d 2>&1 | grep -q "Starting\|Creating"
test_result $? "Services started successfully"

# Wait for services to be ready
echo "Waiting for services to initialize..."
sleep 10

# Check if containers are running
docker-compose ps | grep -q "25rp19824-turikumwenimana-db"
test_result $? "Database container running"

docker-compose ps | grep -q "25rp19824-turikumwenimana-api"
test_result $? "API container running"

docker-compose ps | grep -q "25rp19824-turikumwenimana-frontend"
test_result $? "Frontend container running"

echo ""

# ==================== TEST 6: SERVICE CONNECTIVITY ====================
echo -e "${YELLOW}[TEST 6/8] Testing Service Connectivity${NC}"
echo "---"

# Test API health
for i in {1..30}; do
  if curl -s http://localhost:3000/health >/dev/null 2>&1; then
    API_HEALTH=$(curl -s http://localhost:3000/health)
    echo "$API_HEALTH" | grep -q "healthy"
    test_result $? "API health check passed"
    break
  fi
  if [ $i -eq 30 ]; then
    test_result 1 "API health check passed"
  fi
  sleep 1
done

# Test Frontend health
for i in {1..30}; do
  if curl -s http://localhost/health >/dev/null 2>&1; then
    test_result $? "Frontend health check passed"
    break
  fi
  if [ $i -eq 30 ]; then
    test_result 1 "Frontend health check passed"
  fi
  sleep 1
done

# Test Database connection
docker exec 25rp19824-turikumwenimana-db pg_isready -U expenseuser >/dev/null 2>&1
test_result $? "Database connection working"

echo ""

# ==================== TEST 7: API FUNCTIONALITY ====================
echo -e "${YELLOW}[TEST 7/8] Testing API Functionality${NC}"
echo "---"

# Test GET /api/v1/expenses
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/expenses)
[ "$HTTP_CODE" = "200" ]
test_result $? "GET /api/v1/expenses returns 200"

# Test POST /api/v1/expenses
RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/expenses \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Test expense",
    "amount": 50.00,
    "category": "Food"
  }')

echo "$RESPONSE" | grep -q "id"
test_result $? "POST /api/v1/expenses creates expense"

# Extract ID from response
EXPENSE_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ ! -z "$EXPENSE_ID" ]; then
  # Test GET specific expense
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/expenses/$EXPENSE_ID)
  [ "$HTTP_CODE" = "200" ]
  test_result $? "GET /api/v1/expenses/:id returns 200"

  # Test PUT update expense
  UPDATED=$(curl -s -X PUT http://localhost:3000/api/v1/expenses/$EXPENSE_ID \
    -H "Content-Type: application/json" \
    -d '{
      "description": "Updated test expense",
      "amount": 75.00
    }')
  
  echo "$UPDATED" | grep -q "Updated test expense"
  test_result $? "PUT /api/v1/expenses/:id updates correctly"

  # Test DELETE expense
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE http://localhost:3000/api/v1/expenses/$EXPENSE_ID)
  [ "$HTTP_CODE" = "200" ]
  test_result $? "DELETE /api/v1/expenses/:id returns 200"
fi

# Test GET /api/v1/summary
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/summary)
[ "$HTTP_CODE" = "200" ]
test_result $? "GET /api/v1/summary returns 200"

echo ""

# ==================== TEST 8: CONFIGURATION FILES ====================
echo -e "${YELLOW}[TEST 8/8] Checking Configuration Files${NC}"
echo "---"

# Check Kubernetes manifests
[ -f "kubernetes/namespace.yaml" ]
test_result $? "Kubernetes namespace manifest exists"

[ -f "kubernetes/database-statefulset.yaml" ]
test_result $? "Kubernetes database StatefulSet exists"

[ -f "kubernetes/api-deployment.yaml" ]
test_result $? "Kubernetes API deployment exists"

[ -f "kubernetes/frontend-deployment.yaml" ]
test_result $? "Kubernetes frontend deployment exists"

# Check Terraform files
[ -f "terraform/main.tf" ]
test_result $? "Terraform main.tf exists"

[ -f "terraform/variables.tf" ]
test_result $? "Terraform variables.tf exists"

[ -f "terraform/outputs.tf" ]
test_result $? "Terraform outputs.tf exists"

# Check Ansible files
[ -f "ansible/deploy.yml" ]
test_result $? "Ansible deploy.yml exists"

[ -f "ansible/inventory.ini" ]
test_result $? "Ansible inventory.ini exists"

# Check Monitoring config
[ -f "monitoring/prometheus.yml" ]
test_result $? "Prometheus configuration exists"

[ -f "monitoring/alerts.yml" ]
test_result $? "Alert rules exist"

# Check GitHub Actions
[ -f ".github/workflows/ci-cd.yml" ]
test_result $? "CI/CD pipeline configuration exists"

# Check scripts
[ -f "scripts/setup.sh" ]
test_result $? "Setup script exists"

[ -f "scripts/deploy-k8s.sh" ]
test_result $? "Kubernetes deployment script exists"

[ -f "scripts/health-check.sh" ]
test_result $? "Health check script exists"

echo ""

# ==================== TEST SUMMARY ====================
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Total Passed: ${GREEN}$PASS${NC}"
echo -e "Total Failed: ${RED}$FAIL${NC}"

TOTAL=$((PASS + FAIL))
PERCENTAGE=$((PASS * 100 / TOTAL))

echo "Success Rate: $PERCENTAGE%"
echo ""

if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
  echo "=========================================="
  echo "System Status: HEALTHY"
  echo "=========================================="
  
  # Cleanup
  echo ""
  echo "Stopping services..."
  docker-compose down
  
  exit 0
else
  echo -e "${RED}✗ SOME TESTS FAILED${NC}"
  echo "=========================================="
  
  # Show container logs for debugging
  echo ""
  echo "Container Logs for Debugging:"
  echo "---"
  docker-compose logs
  
  exit 1
fi
