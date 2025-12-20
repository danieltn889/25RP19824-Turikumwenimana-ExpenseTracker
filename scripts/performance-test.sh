#!/bin/bash

PROJECT_ID="25RP19824-Turikumwenimana"

echo "=========================================="
echo "Performance Tests for $PROJECT_ID"
echo "=========================================="
echo ""

# Wait for services to be ready
echo "Waiting for services..."
sleep 5

# Test 1: API Response Time
echo "[1/4] Testing API Response Time..."
echo "Running 10 requests..."
for i in {1..10}; do
  TIME=$(curl -w "%{time_total}" -o /dev/null -s http://localhost:3000/health)
  echo "Request $i: ${TIME}s"
done
echo "✓ Completed"
echo ""

# Test 2: Create Multiple Expenses
echo "[2/4] Testing Create Expense Performance..."
echo "Creating 5 expenses..."
for i in {1..5}; do
  curl -s -X POST http://localhost:3000/api/v1/expenses \
    -H "Content-Type: application/json" \
    -d "{
      \"description\": \"Expense $i\",
      \"amount\": $((10 + i)),
      \"category\": \"Food\"
    }" > /dev/null
  echo "Created expense $i"
done
echo "✓ Completed"
echo ""

# Test 3: List Expenses Performance
echo "[3/4] Testing List Expenses Performance..."
TIME=$(curl -w "%{time_total}" -o /dev/null -s http://localhost:3000/api/v1/expenses)
echo "Response time: ${TIME}s"
echo "✓ Completed"
echo ""

# Test 4: Summary Statistics Performance
echo "[4/4] Testing Summary Statistics Performance..."
TIME=$(curl -w "%{time_total}" -o /dev/null -s http://localhost:3000/api/v1/summary)
echo "Response time: ${TIME}s"
echo "✓ Completed"
echo ""

echo "=========================================="
echo "Performance Test Complete"
echo "=========================================="
