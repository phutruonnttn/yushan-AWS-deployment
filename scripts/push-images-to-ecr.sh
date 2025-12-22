#!/bin/bash
# Script to build and push Docker images to ECR
# Usage: ./scripts/push-images-to-ecr.sh

set -e

AWS_ACCOUNT_ID="245872626968"
AWS_REGION="ap-southeast-1"
AWS_PROFILE="yushan"

echo "=========================================="
echo "Push Docker Images to ECR"
echo "=========================================="
echo ""

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION --profile $AWS_PROFILE | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Services to build and push
SERVICES=(
  "api-gateway"
  "user-service"
  "content-service"
  "engagement-service"
  "gamification-service"
  "analytics-service"
)

for SERVICE in "${SERVICES[@]}"; do
  echo ""
  echo "=========================================="
  echo "Building and pushing: $SERVICE"
  echo "=========================================="
  
  # Navigate to service directory
  SERVICE_DIR="../yushan-microservices-${SERVICE}"
  if [ ! -d "$SERVICE_DIR" ]; then
    echo "⚠️  Service directory not found: $SERVICE_DIR"
    echo "   Skipping $SERVICE..."
    continue
  fi
  
  cd "$SERVICE_DIR"
  
  # Build Docker image
  echo "Building Docker image..."
  docker build -t $SERVICE:latest .
  
  # Tag for ECR
  ECR_IMAGE="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/yushan-development-${SERVICE}:latest"
  docker tag $SERVICE:latest $ECR_IMAGE
  
  # Push to ECR
  echo "Pushing to ECR..."
  docker push $ECR_IMAGE
  
  echo "✅ $SERVICE pushed successfully"
  
  cd - > /dev/null
done

echo ""
echo "=========================================="
echo "✅ All images pushed successfully!"
echo "=========================================="
