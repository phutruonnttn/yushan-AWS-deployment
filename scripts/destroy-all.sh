#!/bin/bash

# Script to destroy all AWS resources to avoid charges

set -e

echo "=========================================="
echo "Destroying All AWS Resources"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will destroy ALL resources!"
echo "Press Ctrl+C within 5 seconds to cancel..."
echo ""

sleep 5

cd "$(dirname "$0")/../terraform" || exit 1

echo "Running terraform destroy..."
terraform destroy -auto-approve

echo ""
echo "=========================================="
echo "✅ Destroy complete!"
echo "=========================================="
echo ""
echo "All AWS resources have been destroyed."
echo "No charges will be incurred while resources are destroyed."
echo ""
echo "To recreate everything, run:"
echo "  cd terraform && terraform apply"

