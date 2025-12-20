#!/bin/bash

set -e

PROJECT_ID="25RP19824-Turikumwenimana"

echo "=========================================="
echo "Unit Tests for $PROJECT_ID"
echo "=========================================="
echo ""

# Test API
echo "[1/2] Running API Unit Tests..."
cd api-service
npm install
npm test 2>&1 | tee test-results.log
cd ..
echo "✓ API tests completed"
echo ""

# Summary
echo "=========================================="
echo "Unit Test Summary"
echo "=========================================="
grep -E "pass|fail" api-service/test-results.log || echo "Tests completed"
echo "=========================================="
