# Kafka Setup Guide

## Current Status
- Kafka brokers: 3x EC2 instances (t3.small) running
- Zookeeper: Not installed/started
- Kafka service: Not started

## Setup Steps

### Option 1: Manual Setup via SSH

1. Get Kafka instance IP:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=yushan-development-kafka-broker-1" \
  --profile yushan --region ap-southeast-1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

2. SSH into the instance:
```bash
ssh -i <your-key.pem> ec2-user@<KAFKA_IP>
```

3. Run the setup script:
```bash
cd /opt/kafka
sudo bash setup-kafka.sh
```

### Option 2: Use AWS Systems Manager (SSM)

The SSM approach failed due to script execution issues. Manual setup is recommended.

## Verification

After setup, verify Kafka is running:

```bash
# Check Kafka port
sudo netstat -tlnp | grep 9092

# Check Kafka service status
sudo systemctl status kafka

# Test from EKS pod
kubectl exec -n yushan <pod-name> -- nc -zv <KAFKA_IP> 9092
```

## Enable Kafka for Services

After Kafka is running, enable it for all services:

```bash
# Remove Kafka disable env vars
kubectl set env deployment/user-service -n yushan \
  SPRING_KAFKA_BOOTSTRAP_SERVERS- \
  SPRING_AUTOCONFIGURE_EXCLUDE-

# Restart services
kubectl rollout restart deployment -n yushan
```
