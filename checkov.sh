#!/bin/bash
# Complete Checkov + Terraform workflow

# Navigate to project
cd /path/to/your/cybersecurity-lab

# 1. Validate Terraform
echo "Step 1: Validating Terraform configuration..."
terraform init
terraform validate || exit 1

# 2. Scan static code
echo "Step 2: Scanning Terraform code..."
checkov -d . --framework terraform --compact

# 3. Create plan
echo "Step 3: Creating Terraform plan..."
terraform plan -out=tfplan

# 4. Convert to JSON
echo "Step 4: Converting plan to JSON..."
terraform show -json tfplan > tfplan.json

# 5. Scan plan
echo "Step 5: Scanning Terraform plan..."
checkov -f tfplan.json --framework terraform_plan

# 6. Generate reports
echo "Step 6: Generating reports..."
checkov -f tfplan.json --framework terraform_plan \
  --output cli \
  --output json \
  --output junitxml \
  --output-file-path ./checkov-reports

echo "✅ Complete! Reports in ./checkov-reports/"