#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# Destroy Script — Image Processor Pipeline
# Usage: ./scripts/destroy.sh <environment>
# Example: ./scripts/destroy.sh dev
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

ENV=${1:-""}

if [[ -z "$ENV" ]]; then
  echo "❌ Error: Environment required"
  echo "Usage: ./scripts/destroy.sh <dev|qa|prod>"
  exit 1
fi

if [[ ! "$ENV" =~ ^(dev|qa|prod)$ ]]; then
  echo "❌ Error: Invalid environment '$ENV'. Must be: dev, qa, prod"
  exit 1
fi

echo "⚠️  DESTROYING Image Processor — Environment: $ENV"
echo "=================================================="
echo "This will DELETE all resources for the '$ENV' environment."
echo ""

read -p "Are you sure? Type 'yes' to confirm: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "❌ Aborted."
  exit 0
fi

cd "$(dirname "$0")/../terraform"

echo ""
echo "🔧 Initializing Terraform..."
terraform init

echo ""
echo "🗑️  Destroying infrastructure..."
terraform destroy -var-file="environments/${ENV}.tfvars" -auto-approve

echo ""
echo "✅ All '$ENV' resources have been destroyed!"
echo "=================================================="
echo ""
echo "📸 Don't forget to take screenshots of the destroy output for your PDF!"
