# Testing Guide - 25RP19824-Turikumwenimana

## Overview
Comprehensive testing suite to verify all DevOps components are working correctly.

## Test Scripts Available

### 1. Complete Test Suite
**File:** `scripts/test-all.sh`
**Purpose:** Run all tests in sequence

```bash
bash scripts/test-all.sh
```

**Tests Included:**
- Prerequisites (Docker, Docker Compose, curl)
- Environment configuration
- Project structure
- Docker images
- Docker Compose deployment
- Service connectivity
- API functionality
- Configuration files

**Expected Output:**
```
✓ PASS: Docker installed
✓ PASS: Docker Compose installed
...
✓ ALL TESTS PASSED!
System Status: HEALTHY
```

---

### 2. Unit Tests
**File:** `scripts/unit-tests.sh`
**Purpose:** Run code unit tests

```bash
bash scripts/unit-tests.sh
```

**Tests Included:**
- API endpoint tests
- Health check tests
- Error handling

---

### 3. Performance Tests
**File:** `scripts/performance-test.sh`
**Purpose:** Measure system performance

```bash
bash scripts/performance-test.sh
```

**Tests Included:**
- API response time
- Create expense performance
- List expenses performance
- Summary statistics performance

**Expected Results:**
- API response time: <100ms
- Create expense: <200ms
- List expenses: <100ms
- Summary: <100ms

---

### 4. Security Scan
**File:** `scripts/security-scan.sh`
**Purpose:** Scan for vulnerabilities

```bash
bash scripts/security-scan.sh
```

**Tests Included:**
- Docker image vulnerability scan
- Filesystem scanning
- Dependency scanning

**Note:** Requires Trivy to be installed

---

### 5. Docker Compose Test
**File:** `scripts/docker-compose-test.sh`
**Purpose:** Test Docker Compose setup

```bash
bash scripts/docker-compose-test.sh
```

**Tests Included:**
- docker-compose.yml validation
- Image building
- Service startup
- Service verification

---

### 6. Kubernetes Test
**File:** `scripts/kubernetes-test.sh`
**Purpose:** Validate Kubernetes manifests

```bash
bash scripts/kubernetes-test.sh
```

**Tests Included:**
- Manifest validation (dry-run)
- Namespace creation
- Secrets configuration
- Resource verification

**Requirements:** kubectl installed and configured

---

### 7. Terraform Test
**File:** `scripts/terraform-test.sh`
**Purpose:** Validate Terraform configuration

```bash
bash scripts/terraform-test.sh
```

**Tests Included:**
- Terraform initialization
- Configuration validation
- Format checking
- Plan generation

**Requirements:** Terraform installed

---

## Quick Test Execution

### All Tests at Once
```bash
bash scripts/test-all.sh
```

### Individual Tests
```bash
# Docker Compose
bash scripts/docker-compose-test.sh

# Kubernetes
bash scripts/kubernetes-test.sh

# Terraform
bash scripts/terraform-test.sh

# Security
bash scripts/security-scan.sh

# Performance
bash scripts/performance-test.sh
```

---

## Manual Testing

### API Testing

#### Health Check
```bash
curl http://localhost:3000/health | jq
```

Expected Response:
```json
{
  "status": "healthy",
  "service": "25rp19824-turikumwenimana-api",
  "timestamp": "2025-12-20T10:30:00.000Z",
  "uptime": 123.45
}
```

#### Create Expense
```bash
curl -X POST http://localhost:3000/api/v1/expenses \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Test expense",
    "amount": 50.00,
    "category": "Food"
  }' | jq
```

#### List Expenses
```bash
curl http://localhost:3000/api/v1/expenses | jq
```

#### Get Summary
```bash
curl http://localhost:3000/api/v1/summary | jq
```

---

### Frontend Testing

#### Access Frontend
```bash
curl http://localhost/
```

#### Health Check
```bash
curl http://localhost/health
```

---

### Database Testing

#### Test Connection
```bash
docker exec 25rp19824-turikumwenimana-db pg_isready -U expenseuser
```

#### Query Data
```bash
docker exec 25rp19824-turikumwenimana-db psql -U expenseuser -d expensedb -c "SELECT COUNT(*) FROM expenses;"
```

---

## Test Results Interpretation

### Success Indicators
✅ All tests pass
✅ Services are healthy
✅ API responds correctly
✅ Database is connected
✅ No critical vulnerabilities
✅ Performance is acceptable

### Failure Indicators
❌ Services not starting
❌ API returning errors
❌ Database connection issues
❌ Security vulnerabilities found
❌ Performance degradation

---

## Troubleshooting Failed Tests

### Services Not Starting
```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart

# Check for port conflicts
lsof -i :3000
lsof -i :5432
lsof -i :80
```

### Database Connection Issues
```bash
# Check database container
docker-compose logs db

# Test connection manually
docker exec 25rp19824-turikumwenimana-db psql -U expenseuser -d expensedb -c "SELECT 1;"
```

### API Not Responding
```bash
# Check API logs
docker-compose logs api

# Check if API is listening
docker exec 25rp19824-turikumwenimana-api curl http://localhost:3000/health
```

### Frontend Issues
```bash
# Check frontend logs
docker-compose logs frontend

# Check Nginx configuration
docker exec 25rp19824-turikumwenimana-frontend cat /etc/nginx/conf.d/default.conf
```

---

## Continuous Testing

### Automated Testing with Cron
```bash
# Add to crontab
0 2 * * * /home/daniel/25RP19824-Turikumwenimana-Project/scripts/test-all.sh >> /var/log/devops-test.log 2>&1
```

### GitHub Actions
Tests run automatically on:
- Push to main/develop branches
- Pull requests
- Manual workflow trigger

---

## Test Coverage

| Component | Test Type | Status |
|-----------|-----------|--------|
| Docker Setup | Integration | ✅ |
| Docker Compose | Integration | ✅ |
| Kubernetes | Configuration | ✅ |
| Terraform | Plan | ✅ |
| API Services | Functional | ✅ |
| Database | Connectivity | ✅ |
| Security | Scanning | ✅ |
| Performance | Load | ✅ |

---

## Reporting

### Test Report Format
```
Date: 2025-12-20
Tests Run: 50
Tests Passed: 50
Tests Failed: 0
Success Rate: 100%
Status: HEALTHY
```

### Save Test Results
```bash
bash scripts/test-all.sh | tee test-results-$(date +%Y%m%d).log
```

---

## Support

For issues or failed tests, refer to:
- TROUBLESHOOTING.md
- Logs in docker-compose output
- GitHub Actions CI/CD logs
