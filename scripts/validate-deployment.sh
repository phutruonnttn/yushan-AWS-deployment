#!/bin/bash

# Deployment Validation Script
# This script validates the AWS deployment and service connectivity

set -e

echo "=========================================="
echo "Yushan Platform - Deployment Validation"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="yushan"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to print result
print_result() {
    local status=$1
    local message=$2
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED++))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}✗${NC} $message"
        ((FAILED++))
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
        ((WARNINGS++))
    fi
}

# Function to check command exists
check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Check prerequisites
echo -e "${BLUE}📋 Checking Prerequisites...${NC}"
echo "----------------------------------------"

if check_command kubectl; then
    print_result "PASS" "kubectl installed"
else
    print_result "FAIL" "kubectl not found"
    exit 1
fi

if check_command aws; then
    print_result "PASS" "AWS CLI installed"
else
    print_result "FAIL" "AWS CLI not found"
    exit 1
fi

if check_command terraform; then
    print_result "PASS" "Terraform installed"
else
    print_result "FAIL" "Terraform not found"
    exit 1
fi

echo ""

# Check Kubernetes access
echo -e "${BLUE}🔌 Checking Kubernetes Access...${NC}"
echo "----------------------------------------"

if kubectl cluster-info &> /dev/null; then
    print_result "PASS" "Kubernetes cluster accessible"
    CLUSTER_NAME=$(kubectl config current-context)
    echo "  Cluster: $CLUSTER_NAME"
else
    print_result "FAIL" "Cannot access Kubernetes cluster"
    exit 1
fi

if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    print_result "PASS" "Namespace '$NAMESPACE' exists"
else
    print_result "FAIL" "Namespace '$NAMESPACE' not found"
    exit 1
fi

echo ""

# Check Pods
echo -e "${BLUE}🚀 Checking Service Pods...${NC}"
echo "----------------------------------------"

SERVICES=("api-gateway" "user-service" "content-service" "engagement-service" "gamification-service" "analytics-service")

for service in "${SERVICES[@]}"; do
    if kubectl get deployment "$service" -n "$NAMESPACE" &> /dev/null; then
        READY=$(kubectl get deployment "$service" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        DESIRED=$(kubectl get deployment "$service" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        
        if [ "$READY" = "$DESIRED" ] && [ "$READY" != "0" ]; then
            print_result "PASS" "$service: $READY/$DESIRED replicas ready"
        else
            print_result "FAIL" "$service: $READY/$DESIRED replicas ready (expected $DESIRED)"
        fi
    else
        print_result "FAIL" "$service: Deployment not found"
    fi
done

echo ""

# Check Services
echo -e "${BLUE}🌐 Checking Services...${NC}"
echo "----------------------------------------"

for service in "${SERVICES[@]}"; do
    if kubectl get service "$service" -n "$NAMESPACE" &> /dev/null; then
        ENDPOINTS=$(kubectl get endpoints "$service" -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w)
        if [ "$ENDPOINTS" -gt 0 ]; then
            print_result "PASS" "$service: Service has $ENDPOINTS endpoint(s)"
        else
            print_result "WARN" "$service: Service has no endpoints"
        fi
    else
        print_result "FAIL" "$service: Service not found"
    fi
done

echo ""

# Check ConfigMaps
echo -e "${BLUE}⚙️  Checking ConfigMaps...${NC}"
echo "----------------------------------------"

CONFIGMAPS=("database-config" "redis-config" "kafka-config" "s3-config")

for cm in "${CONFIGMAPS[@]}"; do
    if kubectl get configmap "$cm" -n "$NAMESPACE" &> /dev/null; then
        # Check if ConfigMap has placeholder values
        if kubectl get configmap "$cm" -n "$NAMESPACE" -o yaml | grep -q "REPLACE_WITH"; then
            print_result "WARN" "$cm: Contains placeholder values (needs update)"
        else
            print_result "PASS" "$cm: ConfigMap exists"
        fi
    else
        print_result "FAIL" "$cm: ConfigMap not found"
    fi
done

echo ""

# Check Secrets
echo -e "${BLUE}🔐 Checking Secrets...${NC}"
echo "----------------------------------------"

SECRETS=("database-secrets" "gateway-secrets" "aws-secrets")

for secret in "${SECRETS[@]}"; do
    if kubectl get secret "$secret" -n "$NAMESPACE" &> /dev/null; then
        print_result "PASS" "$secret: Secret exists"
    else
        print_result "WARN" "$secret: Secret not found (may need to create)"
    fi
done

echo ""

# Check Health Endpoints
echo -e "${BLUE}🏥 Checking Health Endpoints...${NC}"
echo "----------------------------------------"

for service in "${SERVICES[@]}"; do
    case "$service" in
        "api-gateway")
            PORT="8080"
            ;;
        "user-service")
            PORT="8081"
            ;;
        "content-service")
            PORT="8082"
            ;;
        "analytics-service")
            PORT="8083"
            ;;
        "engagement-service")
            PORT="8084"
            ;;
        "gamification-service")
            PORT="8085"
            ;;
        *)
            PORT="8080"
            ;;
    esac
    
    POD=$(kubectl get pod -n "$NAMESPACE" -l app="$service" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$POD" ]; then
        if kubectl exec "$POD" -n "$NAMESPACE" -- curl -sf "http://localhost:$PORT/actuator/health" &> /dev/null; then
            print_result "PASS" "$service: Health endpoint responding"
        else
            print_result "WARN" "$service: Health endpoint not responding"
        fi
    else
        print_result "WARN" "$service: No pod found to test"
    fi
done

echo ""

# Check Terraform Outputs
echo -e "${BLUE}📊 Checking Terraform Outputs...${NC}"
echo "----------------------------------------"

if [ -d "$TERRAFORM_DIR" ]; then
    cd "$TERRAFORM_DIR"
    
    if terraform output alb_dns_name &> /dev/null; then
        ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null)
        if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "null" ]; then
            print_result "PASS" "ALB DNS name available: $ALB_DNS"
        else
            print_result "WARN" "ALB DNS name not available"
        fi
    else
        print_result "WARN" "Terraform outputs not available (may need to run terraform apply)"
    fi
    
    cd - > /dev/null
else
    print_result "WARN" "Terraform directory not found"
fi

echo ""

# Summary
echo "=========================================="
echo -e "${BLUE}📊 Validation Summary${NC}"
echo "=========================================="
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Failed:${NC} $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed!${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠ Validation passed with warnings${NC}"
        exit 0
    fi
else
    echo -e "${RED}✗ Validation failed. Please fix the issues above.${NC}"
    exit 1
fi

