#!/bin/bash

# AWS Deployment Prerequisites Check Script
# This script verifies all required tools and AWS access are configured

set -e

echo "=========================================="
echo "AWS Deployment Prerequisites Check"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track failures
FAILURES=0

# Function to check command
check_command() {
    local cmd=$1
    local name=$2
    
    if command -v $cmd &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n 1)
        echo -e "${GREEN}✓${NC} $name: $version"
        return 0
    else
        echo -e "${RED}✗${NC} $name: NOT INSTALLED"
        FAILURES=$((FAILURES + 1))
        return 1
    fi
}

# Check AWS CLI
echo "Checking AWS CLI..."
if check_command "aws" "AWS CLI"; then
    AWS_VERSION_FULL=$(aws --version 2>&1)
    # Extract version using sed (works on macOS)
    AWS_VERSION=$(echo "$AWS_VERSION_FULL" | sed -E 's/.*aws-cli\/([0-9]+\.[0-9]+).*/\1/' | head -n 1)
    if [ -n "$AWS_VERSION" ]; then
        MAJOR_VERSION=$(echo $AWS_VERSION | cut -d. -f1)
        if [ -n "$MAJOR_VERSION" ] && [ "$MAJOR_VERSION" -ge 2 ]; then
            echo -e "  ${GREEN}✓${NC} AWS CLI v2 detected"
        else
            echo -e "  ${YELLOW}⚠${NC} AWS CLI v1 detected. Consider upgrading to v2"
        fi
    else
        echo -e "  ${GREEN}✓${NC} AWS CLI installed"
    fi
    
    echo "  Checking AWS credentials..."
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        AWS_IDENTITY=$(aws sts get-caller-identity --query Arn --output text)
        echo -e "  ${GREEN}✓${NC} AWS credentials configured"
        echo "  Account ID: $AWS_ACCOUNT"
        echo "  Identity: $AWS_IDENTITY"
        
        # Check if using IAM User or Role
        if echo "$AWS_IDENTITY" | grep -q "assumed-role"; then
            echo -e "  ${GREEN}✓${NC} Using IAM Role"
        elif echo "$AWS_IDENTITY" | grep -q "user"; then
            echo -e "  ${GREEN}✓${NC} Using IAM User (Free Tier compatible)"
        fi
        
        # Check default region
        AWS_REGION=$(aws configure get region)
        if [ -z "$AWS_REGION" ]; then
            echo -e "  ${YELLOW}⚠${NC} Default region not set. Run: aws configure set region <region>"
            echo -e "  ${YELLOW}⚠${NC} Recommended: us-east-1 for better free tier availability"
        else
            echo "  Default region: $AWS_REGION"
            if [ "$AWS_REGION" != "us-east-1" ]; then
                echo -e "  ${YELLOW}⚠${NC} Consider using us-east-1 for better free tier availability"
            fi
        fi
        
        # Check for free tier eligibility
        echo "  Checking free tier eligibility..."
        ACCOUNT_CREATION=$(aws iam get-account-summary 2>/dev/null | grep '"AccountCreationDate"' | sed -E 's/.*"AccountCreationDate": "([^"]*)".*/\1/' || echo "")
        if [ -n "$ACCOUNT_CREATION" ]; then
            echo -e "  ${GREEN}✓${NC} AWS account found"
            echo "  Note: Free tier is available for first 12 months"
        fi
    else
        echo -e "  ${RED}✗${NC} AWS credentials not configured or invalid"
        echo ""
        echo "  Setup IAM User (Free Tier compatible):"
        echo "  1. Create IAM User in AWS Console"
        echo "  2. Attach AdministratorAccess policy"
        echo "  3. Create access keys"
        echo "  4. Run: aws configure"
        echo "  5. Enter Access Key ID and Secret Access Key"
        FAILURES=$((FAILURES + 1))
    fi
fi
echo ""

# Check Terraform
echo "Checking Terraform..."
check_command "terraform" "Terraform"
echo ""

# Check kubectl
echo "Checking kubectl..."
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client 2>&1 | grep -E "Client Version|GitVersion" | head -n 1 | sed -E 's/.*GitVersion:"([^"]*)".*/\1/' || echo "installed")
    if [ "$KUBECTL_VERSION" = "installed" ]; then
        KUBECTL_VERSION=$(kubectl version --client 2>&1 | head -n 1)
    fi
    echo -e "${GREEN}✓${NC} kubectl: $KUBECTL_VERSION"
else
    echo -e "${RED}✗${NC} kubectl: NOT INSTALLED"
    FAILURES=$((FAILURES + 1))
fi
echo ""

# Check eksctl
echo "Checking eksctl..."
if command -v eksctl &> /dev/null; then
    EKSCTL_VERSION=$(eksctl version 2>&1 | head -n 1)
    echo -e "${GREEN}✓${NC} eksctl: $EKSCTL_VERSION"
else
    echo -e "${RED}✗${NC} eksctl: NOT INSTALLED"
    FAILURES=$((FAILURES + 1))
fi
echo ""

# Check Docker
echo "Checking Docker..."
if check_command "docker" "Docker"; then
    if docker ps &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Docker daemon is running"
    else
        echo -e "  ${YELLOW}⚠${NC} Docker daemon is not running"
        echo -e "  ${YELLOW}⚠${NC} Please start Docker Desktop before proceeding"
        echo -e "  ${YELLOW}⚠${NC} This is required for building and pushing Docker images"
        # Don't count as failure - user can start Docker when needed
    fi
fi
echo ""

# Check Docker Compose
echo "Checking Docker Compose..."
if command -v docker &> /dev/null; then
    # Check for docker compose (modern plugin, preferred)
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version 2>&1 | head -n 1)
        echo -e "${GREEN}✓${NC} Docker Compose (plugin): $COMPOSE_VERSION"
    # Fallback to docker-compose (legacy standalone)
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version 2>&1 | head -n 1)
        echo -e "${GREEN}✓${NC} Docker Compose (standalone): $COMPOSE_VERSION"
        echo -e "  ${YELLOW}⚠${NC} Consider using 'docker compose' (plugin) instead of 'docker-compose' (standalone)"
    else
        echo -e "${RED}✗${NC} Docker Compose: NOT FOUND"
        echo -e "  ${YELLOW}⚠${NC} Install Docker Desktop (includes compose plugin) or docker-compose standalone"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo -e "${RED}✗${NC} Docker Compose: Docker not installed"
    FAILURES=$((FAILURES + 1))
fi
echo ""

# Check Git
echo "Checking Git..."
check_command "git" "Git"
echo ""

# Summary
echo "=========================================="
if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}All prerequisites are met!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review AWS_DEPLOYMENT_PREREQUISITES.md"
    echo "2. Verify AWS account billing is enabled"
    echo "3. Proceed to Subtask 2: Create AWS Terraform Structure"
    exit 0
else
    echo -e "${RED}Found $FAILURES missing prerequisite(s)${NC}"
    echo ""
    echo "Please install missing tools and configure AWS access."
    echo "See AWS_DEPLOYMENT_PREREQUISITES.md for detailed instructions."
    exit 1
fi

