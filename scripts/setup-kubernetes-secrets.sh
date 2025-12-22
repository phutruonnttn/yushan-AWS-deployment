#!/bin/bash

# Kubernetes Secrets Setup Script
# This script creates all required Kubernetes secrets for Yushan Platform deployment

set -e

echo "=========================================="
echo "Kubernetes Secrets Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="yushan"

# Function to check if secret exists
secret_exists() {
    local secret_name=$1
    kubectl get secret "$secret_name" -n "$NAMESPACE" &> /dev/null
}

# Function to create secret interactively
create_secret_interactive() {
    local secret_name=$1
    local key=$2
    local prompt=$3
    local is_password=${4:-false}
    
    if secret_exists "$secret_name"; then
        echo -e "${YELLOW}⚠${NC} Secret '$secret_name' already exists. Skipping..."
        return 0
    fi
    
    if [ "$is_password" = true ]; then
        read -sp "$prompt: " value
        echo ""
    else
        read -p "$prompt: " value
    fi
    
    if [ -z "$value" ]; then
        echo -e "${RED}✗${NC} Value cannot be empty. Skipping..."
        return 1
    fi
    
    if secret_exists "$secret_name"; then
        # Add to existing secret
        kubectl patch secret "$secret_name" -n "$NAMESPACE" -p "{\"data\":{\"$key\":\"$(echo -n "$value" | base64)\"}}"
    else
        # Create new secret
        kubectl create secret generic "$secret_name" \
            --from-literal="$key=$value" \
            --namespace="$NAMESPACE"
    fi
    
    echo -e "${GREEN}✓${NC} Secret '$secret_name' created/updated"
}

# Function to add key to existing secret
add_to_secret() {
    local secret_name=$1
    local key=$2
    local prompt=$3
    local is_password=${4:-false}
    
    if [ "$is_password" = true ]; then
        read -sp "$prompt: " value
        echo ""
    else
        read -p "$prompt: " value
    fi
    
    if [ -z "$value" ]; then
        echo -e "${RED}✗${NC} Value cannot be empty. Skipping..."
        return 1
    fi
    
    # Check if key already exists
    if kubectl get secret "$secret_name" -n "$NAMESPACE" -o jsonpath="{.data.$key}" &> /dev/null; then
        echo -e "${YELLOW}⚠${NC} Key '$key' already exists in secret '$secret_name'. Updating..."
    fi
    
    # Patch secret to add/update key
    kubectl patch secret "$secret_name" -n "$NAMESPACE" \
        --type='json' \
        -p="[{\"op\":\"add\",\"path\":\"/data/$key\",\"value\":\"$(echo -n "$value" | base64)\"}]" 2>/dev/null || \
    kubectl patch secret "$secret_name" -n "$NAMESPACE" \
        --type='json' \
        -p="[{\"op\":\"replace\",\"path\":\"/data/$key\",\"value\":\"$(echo -n "$value" | base64)\"}]"
    
    echo -e "${GREEN}✓${NC} Added/updated key '$key' in secret '$secret_name'"
}

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo -e "${RED}✗${NC} Namespace '$NAMESPACE' does not exist. Please create it first:"
    echo "   kubectl create namespace $NAMESPACE"
    exit 1
fi

echo -e "${BLUE}📋 Setting up Kubernetes Secrets for namespace: $NAMESPACE${NC}"
echo ""

# --- Database Secrets ---
echo -e "${BLUE}1. Database Secrets${NC}"
echo "----------------------------------------"
if secret_exists "database-secrets"; then
    echo -e "${YELLOW}⚠${NC} Secret 'database-secrets' already exists"
    read -p "Do you want to update it? (y/N): " update_db
    if [[ "$update_db" =~ ^[Yy]$ ]]; then
        add_to_secret "database-secrets" "username" "Database username" false
        add_to_secret "database-secrets" "password" "Database password" true
    fi
else
    create_secret_interactive "database-secrets" "username" "Database username" false
    add_to_secret "database-secrets" "password" "Database password" true
fi
echo ""

# --- Gateway Secrets ---
echo -e "${BLUE}2. Gateway Secrets (HMAC and JWT)${NC}"
echo "----------------------------------------"
if secret_exists "gateway-secrets"; then
    echo -e "${YELLOW}⚠${NC} Secret 'gateway-secrets' already exists"
    read -p "Do you want to update it? (y/N): " update_gw
    if [[ "$update_gw" =~ ^[Yy]$ ]]; then
        add_to_secret "gateway-secrets" "hmac-secret" "Gateway HMAC secret" true
        add_to_secret "gateway-secrets" "jwt-secret" "JWT secret" true
    fi
else
    create_secret_interactive "gateway-secrets" "hmac-secret" "Gateway HMAC secret" true
    add_to_secret "gateway-secrets" "jwt-secret" "JWT secret" true
fi
echo ""

# --- Mail Secrets ---
echo -e "${BLUE}3. Mail Secrets (for email verification)${NC}"
echo "----------------------------------------"
echo "For Gmail, you need to generate an App Password:"
echo "1. Go to: https://myaccount.google.com/apppasswords"
echo "2. Enable 2-Step Verification if not already enabled"
echo "3. Generate App Password for 'Mail'"
echo "4. Copy the 16-character password"
echo ""
if secret_exists "mail-secrets"; then
    echo -e "${YELLOW}⚠${NC} Secret 'mail-secrets' already exists"
    read -p "Do you want to update it? (y/N): " update_mail
    if [[ "$update_mail" =~ ^[Yy]$ ]]; then
        add_to_secret "mail-secrets" "username" "Email address (e.g., your-email@gmail.com)" false
        add_to_secret "mail-secrets" "password" "Email App Password (16 characters for Gmail)" true
    fi
else
    create_secret_interactive "mail-secrets" "username" "Email address (e.g., your-email@gmail.com)" false
    add_to_secret "mail-secrets" "password" "Email App Password (16 characters for Gmail)" true
fi
echo ""

# --- AWS Secrets (Optional) ---
echo -e "${BLUE}4. AWS Secrets (for S3 access - Optional)${NC}"
echo "----------------------------------------"
read -p "Do you want to setup AWS secrets for S3 access? (y/N): " setup_aws
if [[ "$setup_aws" =~ ^[Yy]$ ]]; then
    if secret_exists "aws-secrets"; then
        echo -e "${YELLOW}⚠${NC} Secret 'aws-secrets' already exists"
        read -p "Do you want to update it? (y/N): " update_aws
        if [[ "$update_aws" =~ ^[Yy]$ ]]; then
            add_to_secret "aws-secrets" "access-key-id" "AWS Access Key ID" false
            add_to_secret "aws-secrets" "secret-access-key" "AWS Secret Access Key" true
        fi
    else
        create_secret_interactive "aws-secrets" "access-key-id" "AWS Access Key ID" false
        add_to_secret "aws-secrets" "secret-access-key" "AWS Secret Access Key" true
    fi
else
    echo -e "${YELLOW}⚠${NC} Skipping AWS secrets setup"
fi
echo ""

# --- Summary ---
echo "=========================================="
echo -e "${GREEN}Secrets Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Created/Updated Secrets:"
kubectl get secrets -n "$NAMESPACE" | grep -E "(database-secrets|gateway-secrets|mail-secrets|aws-secrets)" || echo "No secrets found"
echo ""
echo "To verify secrets:"
echo "  kubectl get secrets -n $NAMESPACE"
echo "  kubectl describe secret <secret-name> -n $NAMESPACE"
echo ""

