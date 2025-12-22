#!/bin/bash

# Cleanup All Billing Resources Script
# This script removes ALL resources that can incur charges across ALL regions

set -e

echo "=========================================="
echo "Cleanup All Billing Resources"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This script will DELETE resources that can incur charges!"
echo "⚠️  Make sure you want to delete ALL billing resources!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROFILE="yushan"
REGIONS=("ap-southeast-1" "us-east-1" "us-west-2" "eu-west-1")

# Function to cleanup resources in a region
cleanup_region() {
    local region=$1
    echo ""
    echo "=========================================="
    echo "Cleaning up region: $region"
    echo "=========================================="
    
    # 1. Stop and terminate EC2 instances
    echo "1. EC2 Instances..."
    INSTANCES=$(aws ec2 describe-instances --profile "$PROFILE" --region "$region" \
        --query 'Reservations[*].Instances[?State.Name==`running` || State.Name==`stopped`].InstanceId' \
        --output text 2>&1)
    if [ -n "$INSTANCES" ] && [ "$INSTANCES" != "None" ]; then
        echo "$INSTANCES" | tr '\t' '\n' | while read instance; do
            [ -n "$instance" ] && echo "   Terminating: $instance" && \
            aws ec2 terminate-instances --instance-ids "$instance" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    else
        echo "   ✓ No EC2 instances"
    fi
    
    # 2. Delete EBS volumes (available)
    echo "2. EBS Volumes (available)..."
    VOLUMES=$(aws ec2 describe-volumes --profile "$PROFILE" --region "$region" \
        --filters "Name=status,Values=available" \
        --query 'Volumes[*].VolumeId' \
        --output text 2>&1)
    if [ -n "$VOLUMES" ] && [ "$VOLUMES" != "None" ]; then
        echo "$VOLUMES" | tr '\t' '\n' | while read volume; do
            [ -n "$volume" ] && echo "   Deleting: $volume" && \
            aws ec2 delete-volume --volume-id "$volume" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    else
        echo "   ✓ No available EBS volumes"
    fi
    
    # 3. Release Elastic IPs
    echo "3. Elastic IPs..."
    EIPS=$(aws ec2 describe-addresses --profile "$PROFILE" --region "$region" \
        --query 'Addresses[?AssociationId==`null`].AllocationId' \
        --output text 2>&1)
    if [ -n "$EIPS" ] && [ "$EIPS" != "None" ]; then
        echo "$EIPS" | tr '\t' '\n' | while read eip; do
            [ -n "$eip" ] && echo "   Releasing: $eip" && \
            aws ec2 release-address --allocation-id "$eip" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    else
        echo "   ✓ No unattached Elastic IPs"
    fi
    
    # 4. Delete NAT Gateways
    echo "4. NAT Gateways..."
    NATS=$(aws ec2 describe-nat-gateways --profile "$PROFILE" --region "$region" \
        --query 'NatGateways[?State==`available`].NatGatewayId' \
        --output text 2>&1)
    if [ -n "$NATS" ] && [ "$NATS" != "None" ]; then
        echo "$NATS" | tr '\t' '\n' | while read nat; do
            [ -n "$nat" ] && echo "   Deleting: $nat" && \
            aws ec2 delete-nat-gateway --nat-gateway-id "$nat" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    else
        echo "   ✓ No NAT Gateways"
    fi
    
    # 5. Delete Load Balancers
    echo "5. Load Balancers..."
    # ALB/NLB
    ALBS=$(aws elbv2 describe-load-balancers --profile "$PROFILE" --region "$region" \
        --query 'LoadBalancers[*].LoadBalancerArn' \
        --output text 2>&1)
    if [ -n "$ALBS" ] && [ "$ALBS" != "None" ]; then
        echo "$ALBS" | tr '\t' '\n' | while read alb; do
            [ -n "$alb" ] && echo "   Deleting ALB: $alb" && \
            aws elbv2 delete-load-balancer --load-balancer-arn "$alb" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    fi
    # Classic ELB
    CLBS=$(aws elb describe-load-balancers --profile "$PROFILE" --region "$region" \
        --query 'LoadBalancerDescriptions[*].LoadBalancerName' \
        --output text 2>&1)
    if [ -n "$CLBS" ] && [ "$CLBS" != "None" ]; then
        echo "$CLBS" | tr '\t' '\n' | while read clb; do
            [ -n "$clb" ] && echo "   Deleting Classic ELB: $clb" && \
            aws elb delete-load-balancer --load-balancer-name "$clb" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    fi
    if [ -z "$ALBS" ] && [ -z "$CLBS" ] || ([ "$ALBS" == "None" ] && [ "$CLBS" == "None" ]); then
        echo "   ✓ No Load Balancers"
    fi
    
    # 6. Delete RDS instances
    echo "6. RDS Instances..."
    RDS=$(aws rds describe-db-instances --profile "$PROFILE" --region "$region" \
        --query 'DBInstances[*].DBInstanceIdentifier' \
        --output text 2>&1)
    if [ -n "$RDS" ] && [ "$RDS" != "None" ]; then
        echo "$RDS" | tr '\t' '\n' | while read db; do
            [ -n "$db" ] && echo "   Deleting RDS: $db" && \
            aws rds delete-db-instance --db-instance-identifier "$db" --skip-final-snapshot --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    else
        echo "   ✓ No RDS instances"
    fi
    
    # 7. Delete ElastiCache clusters
    echo "7. ElastiCache Clusters..."
    # Cache Clusters
    CACHE=$(aws elasticache describe-cache-clusters --profile "$PROFILE" --region "$region" \
        --query 'CacheClusters[*].CacheClusterId' \
        --output text 2>&1)
    if [ -n "$CACHE" ] && [ "$CACHE" != "None" ]; then
        echo "$CACHE" | tr '\t' '\n' | while read cache; do
            [ -n "$cache" ] && echo "   Deleting Cache Cluster: $cache" && \
            aws elasticache delete-cache-cluster --cache-cluster-id "$cache" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    fi
    # Replication Groups
    REPL=$(aws elasticache describe-replication-groups --profile "$PROFILE" --region "$region" \
        --query 'ReplicationGroups[*].ReplicationGroupId' \
        --output text 2>&1)
    if [ -n "$REPL" ] && [ "$REPL" != "None" ]; then
        echo "$REPL" | tr '\t' '\n' | while read repl; do
            [ -n "$repl" ] && echo "   Deleting Replication Group: $repl" && \
            aws elasticache delete-replication-group --replication-group-id "$repl" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    fi
    if [ -z "$CACHE" ] && [ -z "$REPL" ] || ([ "$CACHE" == "None" ] && [ "$REPL" == "None" ]); then
        echo "   ✓ No ElastiCache clusters"
    fi
    
    # 8. Delete EKS clusters
    echo "8. EKS Clusters..."
    EKS=$(aws eks list-clusters --profile "$PROFILE" --region "$region" \
        --query 'clusters[*]' \
        --output text 2>&1)
    if [ -n "$EKS" ] && [ "$EKS" != "None" ]; then
        echo "$EKS" | tr '\t' '\n' | while read cluster; do
            [ -n "$cluster" ] && echo "   Deleting EKS Cluster: $cluster" && \
            aws eks delete-cluster --name "$cluster" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    else
        echo "   ✓ No EKS clusters"
    fi
    
    # 9. Delete VPC Endpoints (Interface endpoints)
    echo "9. VPC Endpoints..."
    VPC_ENDPOINTS=$(aws ec2 describe-vpc-endpoints --profile "$PROFILE" --region "$region" \
        --query 'VpcEndpoints[?VpcEndpointType==`Interface`].VpcEndpointId' \
        --output text 2>&1)
    if [ -n "$VPC_ENDPOINTS" ] && [ "$VPC_ENDPOINTS" != "None" ]; then
        echo "$VPC_ENDPOINTS" | tr '\t' '\n' | while read endpoint; do
            [ -n "$endpoint" ] && echo "   Deleting VPC Endpoint: $endpoint" && \
            aws ec2 delete-vpc-endpoint --vpc-endpoint-id "$endpoint" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    else
        echo "   ✓ No VPC Endpoints"
    fi
    
    # 10. Delete Lambda functions
    echo "10. Lambda Functions..."
    LAMBDAS=$(aws lambda list-functions --profile "$PROFILE" --region "$region" \
        --query 'Functions[*].FunctionName' \
        --output text 2>&1)
    if [ -n "$LAMBDAS" ] && [ "$LAMBDAS" != "None" ]; then
        echo "$LAMBDAS" | tr '\t' '\n' | while read func; do
            [ -n "$func" ] && echo "   Deleting Lambda: $func" && \
            aws lambda delete-function --function-name "$func" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    else
        echo "   ✓ No Lambda functions"
    fi
    
    # 11. Delete EventBridge Rules
    echo "11. EventBridge Rules..."
    RULES=$(aws events list-rules --profile "$PROFILE" --region "$region" \
        --query 'Rules[*].Name' \
        --output text 2>&1)
    if [ -n "$RULES" ] && [ "$RULES" != "None" ]; then
        echo "$RULES" | tr '\t' '\n' | while read rule; do
            [ -n "$rule" ] && echo "   Deleting Rule: $rule" && \
            aws events delete-rule --name "$rule" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    else
        echo "   ✓ No EventBridge Rules"
    fi
    
    echo ""
    echo -e "${GREEN}✓ Cleanup completed for region: $region${NC}"
}

# Cleanup all regions
for region in "${REGIONS[@]}"; do
    cleanup_region "$region"
done

# Cleanup S3 buckets (global)
echo ""
echo "=========================================="
echo "Cleaning up S3 Buckets (Global)"
echo "=========================================="
BUCKETS=$(aws s3 ls --profile "$PROFILE" 2>&1 | awk '{print $3}')
if [ -n "$BUCKETS" ]; then
    echo "$BUCKETS" | while read bucket; do
        [ -n "$bucket" ] && echo "   Deleting bucket: $bucket" && \
        aws s3 rb s3://$bucket --force --profile "$PROFILE" 2>&1 | grep -v "^\s*$" || true
    done
else
    echo "   ✓ No S3 buckets"
fi

# Cleanup DynamoDB tables (all regions)
echo ""
echo "=========================================="
echo "Cleaning up DynamoDB Tables"
echo "=========================================="
for region in "${REGIONS[@]}"; do
    TABLES=$(aws dynamodb list-tables --profile "$PROFILE" --region "$region" \
        --query 'TableNames[*]' \
        --output text 2>&1)
    if [ -n "$TABLES" ] && [ "$TABLES" != "None" ]; then
        echo "$TABLES" | tr '\t' '\n' | while read table; do
            [ -n "$table" ] && echo "   Deleting table: $table (region: $region)" && \
            aws dynamodb delete-table --table-name "$table" --profile "$PROFILE" --region "$region" 2>&1 | grep -v "^\s*$" || true
        done
    fi
done

echo ""
echo "=========================================="
echo -e "${GREEN}Cleanup Complete!${NC}"
echo "=========================================="
echo ""
echo "⚠️  Note: Some resources may take time to fully delete."
echo "⚠️  Check AWS Console after a few minutes to confirm."
echo ""
echo "To check remaining resources:"
echo "  aws resourcegroupstaggingapi get-resources --profile $PROFILE --region ap-southeast-1"

