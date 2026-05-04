#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# Deploy Script — Image Processor Pipeline
# Usage: ./scripts/deploy.sh <environment>
# Example: ./scripts/deploy.sh dev
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

ENV=${1:-""}

if [[ -z "$ENV" ]]; then
  echo "❌ Error: Environment required"
  echo "Usage: ./scripts/deploy.sh <dev|qa|prod>"
  exit 1
fi

if [[ ! "$ENV" =~ ^(dev|qa|prod)$ ]]; then
  echo "❌ Error: Invalid environment '$ENV'. Must be: dev, qa, prod"
  exit 1
fi

echo "🚀 Deploying Image Processor — Environment: $ENV"
echo "=================================================="

# Navigate to terraform directory
cd "$(dirname "$0")/../terraform"

# Install Lambda dependencies
echo ""
echo "📦 Installing Lambda dependencies..."
cd ../lambdas/upload && npm ci --production && cd ../../terraform
cd ../lambdas/crop && npm ci --production && cd ../../terraform

# Initialize Terraform
echo ""
echo "🔧 Initializing Terraform..."
terraform init

# Plan
echo ""
echo "📋 Planning infrastructure changes..."
terraform plan -var-file="environments/${ENV}.tfvars" -out="tfplan-${ENV}"

# Apply
echo ""
echo "🏗️  Applying infrastructure..."
terraform apply "tfplan-${ENV}"

# Show outputs
echo ""
echo "✅ Deployment complete!"
echo "=================================================="
terraform output

echo ""
echo "🧪 Test your API with:"
echo "   curl -X POST \$(terraform output -raw upload_url) \\"
echo "     -F 'image=@test-image.jpg'"
