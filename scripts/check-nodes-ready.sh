#!/bin/bash

# Script to check if EKS nodes are ready

set -e

echo "=========================================="
echo "Checking EKS Nodes Status"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CLUSTER_NAME="yushan-development-eks-cluster"
NODEGROUP_NAME="yushan-development-node-group"
PROFILE="yushan"
REGION="ap-southeast-1"

# Check Node Group Status
echo "📊 Node Group Status:"
NODEGROUP_STATUS=$(aws eks describe-nodegroup \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "$NODEGROUP_NAME" \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'nodegroup.status' \
  --output text 2>/dev/null)

if [ "$NODEGROUP_STATUS" = "ACTIVE" ]; then
  echo -e "${GREEN}✅ Node Group: ACTIVE${NC}"
elif [ "$NODEGROUP_STATUS" = "CREATING" ]; then
  echo -e "${YELLOW}⏳ Node Group: CREATING (in progress)${NC}"
else
  echo -e "${RED}❌ Node Group: $NODEGROUP_STATUS${NC}"
fi

# Check Kubernetes Nodes
echo ""
echo "☸️  Kubernetes Nodes:"
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$NODE_COUNT" -gt 0 ]; then
  echo -e "${GREEN}✅ Found $NODE_COUNT node(s)${NC}"
  kubectl get nodes -o wide
  echo ""
  
  # Check if nodes are Ready
  READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
  if [ "$READY_NODES" -eq "$NODE_COUNT" ]; then
    echo -e "${GREEN}✅ All nodes are Ready!${NC}"
  else
    echo -e "${YELLOW}⏳ $READY_NODES/$NODE_COUNT nodes are Ready${NC}"
  fi
else
  echo -e "${YELLOW}⏳ No nodes found yet${NC}"
fi

# Check Pods Status
echo ""
echo "🚀 Pods Status:"
RUNNING_PODS=$(kubectl get pods -n yushan --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
PENDING_PODS=$(kubectl get pods -n yushan --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l | tr -d ' ')
TOTAL_PODS=$(kubectl get pods -n yushan --no-headers 2>/dev/null | wc -l | tr -d ' ')

echo "Running: $RUNNING_PODS"
echo "Pending: $PENDING_PODS"
echo "Total: $TOTAL_PODS"

if [ "$RUNNING_PODS" -gt 0 ]; then
  echo -e "${GREEN}✅ Some pods are running!${NC}"
elif [ "$PENDING_PODS" -gt 0 ]; then
  echo -e "${YELLOW}⏳ All pods are pending (waiting for nodes)${NC}"
fi

echo ""
echo "=========================================="
if [ "$NODEGROUP_STATUS" = "ACTIVE" ] && [ "$NODE_COUNT" -gt 0 ] && [ "$READY_NODES" -eq "$NODE_COUNT" ]; then
  echo -e "${GREEN}✅ Nodes are ready!${NC}"
  exit 0
else
  echo -e "${YELLOW}⏳ Nodes are not ready yet. Please wait...${NC}"
  exit 1
fi

