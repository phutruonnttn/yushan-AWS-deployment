#!/bin/bash

# Script to setup Terraform S3 Backend
# This creates the S3 bucket and DynamoDB table needed for Terraform state storage

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BUCKET_NAME="yushan-terraform-state"
DYNAMODB_TABLE="yushan-terraform-locks"
REGION="ap-southeast-1"
PROFILE="yushan"

echo "=========================================="
echo "Terraform S3 Backend Setup"
echo "=========================================="
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗${NC} AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

# Check AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity --profile $PROFILE &> /dev/null; then
    echo -e "${RED}✗${NC} AWS credentials not configured for profile: $PROFILE"
    echo "Run: aws configure --profile $PROFILE"
    exit 1
fi
echo -e "${GREEN}✓${NC} AWS credentials configured"
echo ""

# Create S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME..."
if aws s3 ls "s3://$BUCKET_NAME" --profile $PROFILE &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} S3 bucket already exists: $BUCKET_NAME"
else
    # Create bucket (us-east-1 doesn't need LocationConstraint)
    if [ "$REGION" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket $BUCKET_NAME \
            --region $REGION \
            --profile $PROFILE
    else
        aws s3api create-bucket \
            --bucket $BUCKET_NAME \
            --region $REGION \
            --create-bucket-configuration LocationConstraint=$REGION \
            --profile $PROFILE
    fi
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket $BUCKET_NAME \
        --versioning-configuration Status=Enabled \
        --profile $PROFILE
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket $BUCKET_NAME \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }' \
        --profile $PROFILE
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket $BUCKET_NAME \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --profile $PROFILE
    
    echo -e "${GREEN}✓${NC} S3 bucket created: $BUCKET_NAME"
fi
echo ""

# Create DynamoDB table
echo "Creating DynamoDB table: $DYNAMODB_TABLE..."
if aws dynamodb describe-table --table-name $DYNAMODB_TABLE --profile $PROFILE &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} DynamoDB table already exists: $DYNAMODB_TABLE"
else
    aws dynamodb create-table \
        --table-name $DYNAMODB_TABLE \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region $REGION \
        --profile $PROFILE
    
    # Wait for table to be active
    echo "Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists \
        --table-name $DYNAMODB_TABLE \
        --profile $PROFILE
    
    echo -e "${GREEN}✓${NC} DynamoDB table created: $DYNAMODB_TABLE"
fi
echo ""

# Summary
echo "=========================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo "Region: $REGION"
echo ""
echo "Next steps:"
echo "1. Run: cd terraform"
echo "2. Run: terraform init"
echo "3. Terraform will use S3 backend automatically"
echo ""

