# Testing & Validation Guide - AWS Deployment

## 📋 Overview

This guide provides comprehensive testing and validation procedures for the Yushan Platform AWS deployment. It covers infrastructure validation, service connectivity, database connections, and end-to-end API testing.

## ✅ Pre-Deployment Validation

### 1. Terraform Validation

```bash
cd terraform

# Validate Terraform configuration
terraform validate

# Plan deployment (dry-run)
terraform plan

# Check for any warnings or errors
terraform fmt -check
```

### 2. AWS Credentials Verification

```bash
# Verify AWS credentials
aws sts get-caller-identity --profile yushan

# Verify AWS region
aws configure get region --profile yushan

# Test AWS CLI access
aws ec2 describe-regions --profile yushan
```

### 3. Kubernetes Access Verification

```bash
# Verify kubectl is configured
kubectl cluster-info

# Verify EKS cluster access
kubectl get nodes

# Verify namespace exists
kubectl get namespace yushan
```

## 🏗️ Infrastructure Validation

### 1. VPC and Networking

```bash
# Get VPC ID
terraform output vpc_id

# Verify subnets
terraform output public_subnet_ids
terraform output private_subnet_ids

# Test connectivity from EKS nodes
kubectl run test-pod --image=busybox --rm -it --restart=Never --namespace=yushan -- ping -c 3 <rds-endpoint>
```

### 2. RDS PostgreSQL Validation

```bash
# Get RDS endpoints
terraform output rds_user_service_endpoint
terraform output rds_content_service_endpoint
terraform output rds_engagement_service_endpoint
terraform output rds_gamification_service_endpoint
terraform output rds_analytics_service_endpoint

# Test connectivity from EKS pod
kubectl run postgres-test --image=postgres:15 --rm -it --restart=Never --namespace=yushan -- \
  psql -h <rds-endpoint> -U postgres -d user_service -c "SELECT version();"

# Verify database exists
kubectl exec -it <user-service-pod> -n yushan -- \
  psql -h <rds-endpoint> -U postgres -d user_service -c "\l"
```

### 3. ElastiCache Redis Validation

```bash
# Get Redis endpoints
terraform output elasticache_user_service_endpoint
terraform output elasticache_content_service_endpoint
terraform output elasticache_engagement_service_endpoint
terraform output elasticache_gamification_service_endpoint
terraform output elasticache_analytics_service_endpoint

# Test connectivity from EKS pod
kubectl run redis-test --image=redis:7 --rm -it --restart=Never --namespace=yushan -- \
  redis-cli -h <redis-endpoint> ping

# Test Redis operations
kubectl exec -it <user-service-pod> -n yushan -- \
  redis-cli -h <redis-endpoint> SET test-key "test-value" && \
  redis-cli -h <redis-endpoint> GET test-key
```

### 4. Kafka Validation

```bash
# Get Kafka bootstrap servers
terraform output kafka_bootstrap_servers

# Test connectivity from EKS pod
kubectl run kafka-test --image=confluentinc/cp-kafka:7.4.0 --rm -it --restart=Never --namespace=yushan -- \
  kafka-broker-api-versions --bootstrap-server <kafka-bootstrap-servers>

# List Kafka topics
kubectl exec -it <content-service-pod> -n yushan -- \
  kafka-topics --bootstrap-server <kafka-bootstrap-servers> --list
```

### 5. S3 Validation

```bash
# Get S3 bucket name
terraform output s3_content_storage_bucket_name

# Test S3 access
aws s3 ls s3://$(terraform output -raw s3_content_storage_bucket_name) --profile yushan

# Test upload
echo "test content" | aws s3 cp - s3://$(terraform output -raw s3_content_storage_bucket_name)/test.txt --profile yushan

# Test download
aws s3 cp s3://$(terraform output -raw s3_content_storage_bucket_name)/test.txt - --profile yushan
```

### 6. ECR Validation

```bash
# Get ECR repository URLs
terraform output ecr_repository_urls

# Verify ECR access
aws ecr describe-repositories --region ap-southeast-1 --profile yushan

# Test image pull (from EKS node)
kubectl run ecr-test --image=$(terraform output -json ecr_repository_urls | jq -r '.["api-gateway"]') --rm -it --restart=Never --namespace=yushan -- echo "ECR image pulled successfully"
```

### 7. ALB Validation

```bash
# Get ALB DNS name
terraform output alb_dns_name

# Test ALB health
curl -I http://$(terraform output -raw alb_dns_name)/actuator/health

# Test HTTPS (if SSL certificate configured)
curl -I https://$(terraform output -raw alb_dns_name)/actuator/health
```

## 🚀 Service Deployment Validation

### 1. Pod Status Check

```bash
# Check all pods are running
kubectl get pods -n yushan

# Check pod status in detail
kubectl get pods -n yushan -o wide

# Check pod events
kubectl describe pod <pod-name> -n yushan
```

### 2. Service Endpoints Check

```bash
# Check all services
kubectl get services -n yushan

# Check service endpoints
kubectl get endpoints -n yushan

# Verify service DNS resolution
kubectl run dns-test --image=busybox --rm -it --restart=Never --namespace=yushan -- \
  nslookup api-gateway.yushan.svc.cluster.local
```

### 3. ConfigMap and Secrets Validation

```bash
# Verify ConfigMaps
kubectl get configmaps -n yushan
kubectl get configmap database-config -n yushan -o yaml
kubectl get configmap redis-config -n yushan -o yaml
kubectl get configmap kafka-config -n yushan -o yaml

# Verify Secrets (check if they exist, don't print values)
kubectl get secrets -n yushan
kubectl describe secret database-secrets -n yushan
kubectl describe secret gateway-secrets -n yushan
```

## 🔌 Connectivity Testing

### 1. Database Connectivity Test

```bash
# Test from user-service pod
kubectl exec -it deployment/user-service -n yushan -- \
  sh -c 'echo "SELECT 1;" | psql -h $DB_HOST -U $DB_USERNAME -d $DB_NAME'

# Test from content-service pod
kubectl exec -it deployment/content-service -n yushan -- \
  sh -c 'echo "SELECT 1;" | psql -h $DB_HOST -U $DB_USERNAME -d $DB_NAME'
```

### 2. Redis Connectivity Test

```bash
# Test from user-service pod
kubectl exec -it deployment/user-service -n yushan -- \
  redis-cli -h $REDIS_HOST ping

# Test Redis operations
kubectl exec -it deployment/user-service -n yushan -- \
  redis-cli -h $REDIS_HOST SET test-key "test-value" && \
  redis-cli -h $REDIS_HOST GET test-key
```

### 3. Kafka Connectivity Test

```bash
# Test from content-service pod
kubectl exec -it deployment/content-service -n yushan -- \
  kafka-topics --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS --list

# Test Kafka producer (from pod)
kubectl exec -it deployment/content-service -n yushan -- \
  kafka-console-producer --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS --topic test-topic
```

### 4. Inter-Service Communication Test

```bash
# Test API Gateway → User Service
kubectl exec -it deployment/api-gateway -n yushan -- \
  curl -s http://user-service:8081/actuator/health

# Test API Gateway → Content Service
kubectl exec -it deployment/api-gateway -n yushan -- \
  curl -s http://content-service:8082/actuator/health

# Test User Service → Content Service (via OpenFeign)
kubectl exec -it deployment/user-service -n yushan -- \
  curl -s http://content-service:8082/actuator/health
```

## 🌐 API Gateway Testing

### 1. Health Check Endpoints

```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test API Gateway health
curl -v http://$ALB_DNS/actuator/health

# Test individual service health (via API Gateway)
curl -v http://$ALB_DNS/api/v1/health
```

### 2. Public Endpoints (No Authentication)

```bash
# Test public endpoints
curl -v http://$ALB_DNS/api/v1/novels
curl -v http://$ALB_DNS/api/v1/categories
curl -v http://$ALB_DNS/api/v1/ranking
```

### 3. Authentication Endpoints

```bash
# Test registration
curl -X POST http://$ALB_DNS/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!@#",
    "username": "testuser"
  }'

# Test login
curl -X POST http://$ALB_DNS/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!@#"
  }'

# Save token
TOKEN=$(curl -s -X POST http://$ALB_DNS/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "Test123!@#"}' \
  | jq -r '.data.accessToken')
```

### 4. Authenticated Endpoints

```bash
# Test authenticated endpoint
curl -v http://$ALB_DNS/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"

# Test library endpoint
curl -v http://$ALB_DNS/api/v1/library \
  -H "Authorization: Bearer $TOKEN"
```

### 5. Service Routing Test

```bash
# Test User Service routes
curl -v http://$ALB_DNS/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"

# Test Content Service routes
curl -v http://$ALB_DNS/api/v1/novels

# Test Engagement Service routes
curl -v http://$ALB_DNS/api/v1/comments?novelId=1

# Test Gamification Service routes
curl -v http://$ALB_DNS/api/v1/gamification/stats \
  -H "Authorization: Bearer $TOKEN"

# Test Analytics Service routes
curl -v http://$ALB_DNS/api/v1/ranking/novels
```

## 📊 Performance Testing

### 1. Load Testing (Optional)

```bash
# Install Apache Bench (if not installed)
# macOS: brew install httpd
# Linux: apt-get install apache2-utils

# Test API Gateway with load
ab -n 1000 -c 10 http://$ALB_DNS/actuator/health

# Test public endpoint
ab -n 500 -c 5 http://$ALB_DNS/api/v1/novels
```

### 2. Response Time Monitoring

```bash
# Test response times
for i in {1..10}; do
  time curl -s http://$ALB_DNS/actuator/health > /dev/null
done
```

## 🔍 Logging and Debugging

### 1. View Service Logs

```bash
# View API Gateway logs
kubectl logs -f deployment/api-gateway -n yushan

# View User Service logs
kubectl logs -f deployment/user-service -n yushan

# View logs from specific pod
kubectl logs -f <pod-name> -n yushan

# View logs from all pods in deployment
kubectl logs -f deployment/user-service -n yushan --all-containers=true
```

### 2. Debug Pod Issues

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n yushan

# Check pod environment variables
kubectl exec <pod-name> -n yushan -- env | grep -E "DB_|REDIS_|KAFKA_"

# Execute shell in pod
kubectl exec -it <pod-name> -n yushan -- sh
```

### 3. Network Debugging

```bash
# Test DNS resolution
kubectl run dns-debug --image=busybox --rm -it --restart=Never --namespace=yushan -- \
  nslookup user-service.yushan.svc.cluster.local

# Test network connectivity
kubectl run net-debug --image=busybox --rm -it --restart=Never --namespace=yushan -- \
  wget -O- http://user-service:8081/actuator/health
```

## ✅ Validation Checklist

### Infrastructure
- [ ] VPC and subnets created
- [ ] Security groups configured
- [ ] EKS cluster accessible
- [ ] RDS instances accessible
- [ ] ElastiCache clusters accessible
- [ ] Kafka brokers accessible
- [ ] S3 bucket accessible
- [ ] ECR repositories accessible
- [ ] ALB DNS name resolvable

### Services
- [ ] All pods running (Ready: 2/2)
- [ ] All services have endpoints
- [ ] ConfigMaps populated with correct values
- [ ] Secrets created and accessible
- [ ] Health checks passing
- [ ] No pod restarts (unless expected)

### Connectivity
- [ ] Services can connect to RDS
- [ ] Services can connect to Redis
- [ ] Services can connect to Kafka
- [ ] Services can access S3
- [ ] Inter-service communication working
- [ ] API Gateway routing correctly

### API Testing
- [ ] Health endpoints responding
- [ ] Public endpoints accessible
- [ ] Authentication working
- [ ] Authenticated endpoints working
- [ ] Service routing correct
- [ ] Error handling working

## 🚨 Common Issues and Solutions

### Issue: Pods Not Starting

**Symptoms**: Pods in `Pending` or `CrashLoopBackOff` state

**Solutions**:
```bash
# Check pod events
kubectl describe pod <pod-name> -n yushan

# Check resource limits
kubectl top pods -n yushan

# Check image pull errors
kubectl describe pod <pod-name> -n yushan | grep -i "image"
```

### Issue: Database Connection Failed

**Symptoms**: Services cannot connect to RDS

**Solutions**:
```bash
# Verify RDS endpoint in ConfigMap
kubectl get configmap database-config -n yushan -o yaml

# Test connectivity from pod
kubectl run db-test --image=postgres:15 --rm -it --restart=Never --namespace=yushan -- \
  psql -h <rds-endpoint> -U postgres

# Check security group rules
aws ec2 describe-security-groups --group-ids <rds-sg-id> --profile yushan
```

### Issue: Redis Connection Failed

**Symptoms**: Services cannot connect to ElastiCache

**Solutions**:
```bash
# Verify Redis endpoint in ConfigMap
kubectl get configmap redis-config -n yushan -o yaml

# Test connectivity from pod
kubectl run redis-test --image=redis:7 --rm -it --restart=Never --namespace=yushan -- \
  redis-cli -h <redis-endpoint> ping

# Check security group rules
aws ec2 describe-security-groups --group-ids <redis-sg-id> --profile yushan
```

### Issue: API Gateway Not Routing

**Symptoms**: 404 or 502 errors from ALB

**Solutions**:
```bash
# Check Ingress status
kubectl get ingress -n yushan
kubectl describe ingress api-gateway-ingress -n yushan

# Check ALB target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn> --profile yushan

# Check service endpoints
kubectl get endpoints api-gateway -n yushan
```

## 📚 References

- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [AWS EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
- [Terraform Outputs](../terraform/README.md#outputs)
- [Service Configs Guide](./SERVICE_CONFIGS_GUIDE.md)
- [Kubernetes Manifests](./kubernetes/README.md)

