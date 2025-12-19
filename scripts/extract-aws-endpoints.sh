#!/bin/bash

# Extract AWS Endpoints from Terraform Outputs
# This script helps extract all necessary endpoints for service configuration

set -e

echo "=========================================="
echo "Extracting AWS Endpoints from Terraform"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Change to terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

if [ ! -d "$TERRAFORM_DIR" ]; then
    echo -e "${RED}✗${NC} Terraform directory not found: $TERRAFORM_DIR"
    exit 1
fi

cd "$TERRAFORM_DIR"

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}⚠${NC} Terraform not initialized. Running terraform init..."
    terraform init
fi

echo -e "${BLUE}📋 Extracting Terraform outputs...${NC}"
echo ""

# Function to extract output value
extract_output() {
    local output_name=$1
    terraform output -raw "$output_name" 2>/dev/null || echo "N/A"
}

# RDS Endpoints
echo -e "${GREEN}📊 RDS PostgreSQL Endpoints:${NC}"
echo "----------------------------------------"
echo "User Service RDS:        $(extract_output rds_user_service_endpoint)"
echo "Content Service RDS:     $(extract_output rds_content_service_endpoint)"
echo "Engagement Service RDS:  $(extract_output rds_engagement_service_endpoint)"
echo "Gamification Service RDS: $(extract_output rds_gamification_service_endpoint)"
echo "Analytics Service RDS:   $(extract_output rds_analytics_service_endpoint)"
echo ""

# ElastiCache Endpoints
echo -e "${GREEN}📊 ElastiCache Redis Endpoints:${NC}"
echo "----------------------------------------"
echo "User Service Redis:        $(extract_output elasticache_user_service_endpoint)"
echo "Content Service Redis:     $(extract_output elasticache_content_service_endpoint)"
echo "Engagement Service Redis:  $(extract_output elasticache_engagement_service_endpoint)"
echo "Gamification Service Redis: $(extract_output elasticache_gamification_service_endpoint)"
echo "Analytics Service Redis:   $(extract_output elasticache_analytics_service_endpoint)"
echo ""

# Kafka Endpoints
echo -e "${GREEN}📊 Kafka Bootstrap Servers:${NC}"
echo "----------------------------------------"
KAFKA_ENDPOINTS=$(extract_output kafka_bootstrap_servers)
if [ "$KAFKA_ENDPOINTS" != "N/A" ]; then
    echo "$KAFKA_ENDPOINTS"
else
    echo "Kafka endpoints not available (may need to extract from EC2 instances)"
fi
echo ""

# S3 Buckets
echo -e "${GREEN}📊 S3 Buckets:${NC}"
echo "----------------------------------------"
echo "Content Storage Bucket: $(extract_output s3_content_storage_bucket_name)"
echo ""

# ECR Repositories
echo -e "${GREEN}📊 ECR Repository URLs:${NC}"
echo "----------------------------------------"
echo "API Gateway ECR:     $(extract_output ecr_repository_urls | jq -r '.["api-gateway"]' 2>/dev/null || echo "N/A")"
echo "User Service ECR:    $(extract_output ecr_repository_urls | jq -r '.["user-service"]' 2>/dev/null || echo "N/A")"
echo "Content Service ECR: $(extract_output ecr_repository_urls | jq -r '.["content-service"]' 2>/dev/null || echo "N/A")"
echo "Engagement Service ECR: $(extract_output ecr_repository_urls | jq -r '.["engagement-service"]' 2>/dev/null || echo "N/A")"
echo "Gamification Service ECR: $(extract_output ecr_repository_urls | jq -r '.["gamification-service"]' 2>/dev/null || echo "N/A")"
echo "Analytics Service ECR: $(extract_output ecr_repository_urls | jq -r '.["analytics-service"]' 2>/dev/null || echo "N/A")"
echo ""

# ALB DNS
echo -e "${GREEN}📊 Application Load Balancer:${NC}"
echo "----------------------------------------"
echo "ALB DNS Name: $(extract_output alb_dns_name)"
echo ""

# AWS Region
echo -e "${GREEN}📊 AWS Configuration:${NC}"
echo "----------------------------------------"
echo "AWS Region:    $(extract_output aws_region)"
echo "AWS Account ID: $(extract_output aws_account_id)"
echo ""

# Export to JSON file
OUTPUT_FILE="$SCRIPT_DIR/../configs/terraform-outputs.json"
mkdir -p "$(dirname "$OUTPUT_FILE")"

echo -e "${BLUE}💾 Exporting outputs to JSON file...${NC}"
terraform output -json > "$OUTPUT_FILE" 2>/dev/null || echo -e "${YELLOW}⚠${NC} Could not export JSON outputs"

if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${GREEN}✓${NC} Outputs exported to: $OUTPUT_FILE"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Extraction Complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review the endpoints above"
echo "2. Update service configs in yushan-microservices-config-data repository"
echo "3. See SERVICE_CONFIGS_GUIDE.md for detailed instructions"
echo ""

