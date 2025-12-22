# Kubernetes Manifests for Yushan Platform

## 📋 Overview

This directory contains Kubernetes manifests for deploying Yushan Platform microservices to AWS EKS.

## 📁 Directory Structure

```
kubernetes/
├── namespace.yaml                    # Yushan namespace
├── configmaps.yaml                   # ConfigMaps for AWS endpoints
├── secrets.yaml.example              # Example secrets (DO NOT commit actual secrets)
├── README.md                         # This file
├── api-gateway/
│   ├── deployment.yaml              # API Gateway deployment
│   ├── service.yaml                 # API Gateway service
│   └── ingress.yaml                 # ALB Ingress for API Gateway
├── user-service/
│   ├── deployment.yaml              # User Service deployment
│   └── service.yaml                 # User Service service
├── content-service/
│   ├── deployment.yaml              # Content Service deployment
│   └── service.yaml                 # Content Service service
├── engagement-service/
│   ├── deployment.yaml              # Engagement Service deployment
│   └── service.yaml                 # Engagement Service service
├── gamification-service/
│   ├── deployment.yaml              # Gamification Service deployment
│   └── service.yaml                 # Gamification Service service
└── analytics-service/
    ├── deployment.yaml              # Analytics Service deployment
    └── service.yaml                 # Analytics Service service
```

## 🚀 Quick Start

### Prerequisites

1. **EKS Cluster**: Deploy infrastructure using Terraform (see `../terraform/`)
2. **kubectl**: Configured to connect to EKS cluster
3. **AWS Load Balancer Controller**: Installed in EKS cluster
4. **ECR Images**: Docker images pushed to ECR repositories

### Step 1: Create Kubernetes Secrets

```bash
# Setup all required secrets (database, gateway, mail, aws)
cd ../scripts
./setup-kubernetes-secrets.sh
```

This script will interactively prompt you for:
- Database credentials (username, password)
- Gateway secrets (HMAC secret, JWT secret)
- Mail credentials (email address, App Password)
- AWS credentials (optional, for S3 access)

**Note**: For Gmail, you need to generate an App Password:
1. Go to: https://myaccount.google.com/apppasswords
2. Enable 2-Step Verification
3. Generate App Password for 'Mail'
4. Copy the 16-character password

### Step 2: Get AWS Endpoints

```bash
# Extract AWS endpoints from Terraform outputs
cd ../scripts
./extract-aws-endpoints.sh
```

### Step 3: Update ConfigMaps

Edit `configmaps.yaml` and replace placeholder values with actual AWS endpoints:

```bash
# Get RDS endpoints
terraform output rds_user_service_endpoint
terraform output rds_content_service_endpoint
# ... etc

# Get Redis endpoints
terraform output elasticache_user_service_endpoint
# ... etc

# Get Kafka bootstrap servers
terraform output kafka_bootstrap_servers

# Get S3 bucket name
terraform output s3_content_storage_bucket_name
```

### Step 3: Create Secrets (Alternative - Manual)

**IMPORTANT**: Never commit actual secrets to Git!

If you prefer to create secrets manually instead of using the script:

```bash
# Create database secrets
kubectl create secret generic database-secrets \
  --from-literal=username=postgres \
  --from-literal=password=your-secure-password \
  --namespace=yushan

# Create gateway secrets
kubectl create secret generic gateway-secrets \
  --from-literal=hmac-secret=your-hmac-secret-key \
  --from-literal=jwt-secret=your-jwt-secret-key \
  --namespace=yushan

# Create mail secrets (for email verification)
kubectl create secret generic mail-secrets \
  --from-literal=username=your-email@gmail.com \
  --from-literal=password=your-app-password \
  --namespace=yushan

# Create AWS secrets (for S3 access - optional)
kubectl create secret generic aws-secrets \
  --from-literal=access-key-id=your-aws-access-key \
  --from-literal=secret-access-key=your-aws-secret-key \
  --namespace=yushan
```

### Step 4: Update ECR Image URLs

Update all `deployment.yaml` files with actual ECR repository URLs:

```bash
# Get ECR URLs
terraform output ecr_repository_urls

# Example: Replace in deployment.yaml
# image: 123456789.dkr.ecr.ap-southeast-1.amazonaws.com/yushan-development-api-gateway:latest
```

### Step 5: Deploy to Kubernetes

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Apply ConfigMaps
kubectl apply -f configmaps.yaml

# Deploy all services
kubectl apply -f api-gateway/
kubectl apply -f user-service/
kubectl apply -f content-service/
kubectl apply -f engagement-service/
kubectl apply -f gamification-service/
kubectl apply -f analytics-service/

# Or apply all at once
kubectl apply -f .
```

### Step 6: Verify Deployment

```bash
# Check pods
kubectl get pods -n yushan

# Check services
kubectl get services -n yushan

# Check ingress
kubectl get ingress -n yushan

# View logs
kubectl logs -f deployment/api-gateway -n yushan
```

## 🔧 Configuration

### Resource Limits

All services use the following resource limits:
- **Requests**: 512Mi memory, 250m CPU
- **Limits**: 1Gi memory, 500m CPU

### Replicas

All services are configured with **2 replicas** for high availability.

### Health Checks

All services include:
- **Liveness Probe**: `/actuator/health/liveness`
- **Readiness Probe**: `/actuator/health/readiness`
- **Startup Probe**: `/actuator/health`

### Ports

| Service | Port |
|---------|------|
| API Gateway | 8080 |
| User Service | 8081 |
| Content Service | 8082 |
| Analytics Service | 8083 |
| Engagement Service | 8084 |
| Gamification Service | 8085 |

## 🔐 Security

### Secrets Management

- **Never commit secrets to Git**
- Use `kubectl create secret` or AWS Secrets Manager
- Consider using External Secrets Operator for production

### Image Pull Policy

All deployments use `imagePullPolicy: Always` to ensure latest images are pulled.

## 📊 Monitoring

### Health Endpoints

All services expose health endpoints:
- `/actuator/health` - Overall health
- `/actuator/health/liveness` - Liveness check
- `/actuator/health/readiness` - Readiness check

### Metrics

All services expose Prometheus metrics at `/actuator/prometheus`.

## 🔄 Updates

### Update Image Version

```bash
# Update deployment with new image
kubectl set image deployment/api-gateway \
  api-gateway=123456789.dkr.ecr.ap-southeast-1.amazonaws.com/yushan-development-api-gateway:v1.1.0 \
  -n yushan

# Or edit deployment
kubectl edit deployment/api-gateway -n yushan
```

### Rollback

```bash
# View rollout history
kubectl rollout history deployment/api-gateway -n yushan

# Rollback to previous version
kubectl rollout undo deployment/api-gateway -n yushan
```

## 🚨 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n yushan

# Check logs
kubectl logs <pod-name> -n yushan

# Check events
kubectl get events -n yushan --sort-by='.lastTimestamp'
```

### Image Pull Errors

```bash
# Verify ECR repository exists
aws ecr describe-repositories --region ap-southeast-1

# Check EKS node IAM role has ECR permissions
# See terraform/eks.tf for IAM role configuration
```

### Database Connection Issues

```bash
# Verify ConfigMap has correct endpoints
kubectl get configmap database-config -n yushan -o yaml

# Test connectivity from pod
kubectl exec -it <pod-name> -n yushan -- nc -zv <rds-endpoint> 5432
```

## 📚 References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Service Configs Guide](../SERVICE_CONFIGS_GUIDE.md)

