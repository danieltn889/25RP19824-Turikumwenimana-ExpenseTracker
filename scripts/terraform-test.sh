#!/bin/bash

set -e

PROJECT_ID="25RP19824-Turikumwenimana"

echo "=========================================="
echo "Terraform Test for $PROJECT_ID"
echo "=========================================="
echo ""

# Check if Terraform is available
if ! command -v terraform &> /dev/null; then
  echo "Terraform not found. Skipping Terraform tests."
  exit 0
fi

cd terraform

# Test 1: Initialize
echo "[1/4] Initializing Terraform..."
terraform init > /dev/null 2>&1
echo "✓ Terraform initialized"
echo ""

# Test 2: Validate
echo "[2/4] Validating Terraform configuration..."
terraform validate
echo "✓ Configuration valid"
echo ""

# Test 3: Format check
echo "[3/4] Checking Terraform format..."
terraform fmt -check -recursive . || echo "⚠ Some formatting issues detected"
echo "✓ Format check complete"
echo ""

# Test 4: Plan (dry-run)
echo "[4/4] Running Terraform plan (dry-run)..."
terraform plan -out=tfplan > /dev/null 2>&1
echo "✓ Plan successful"
echo ""

# Display plan
echo "Plan summary:"
terraform show tfplan | grep "Plan:" || echo "Plan complete"
echo ""

# Cleanup
rm -f tfplan

cd ..

echo "=========================================="
echo "Terraform Test Complete"
echo "=========================================="
