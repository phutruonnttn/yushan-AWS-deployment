# AWS Deployment - Yushan Platform

This repository contains Terraform infrastructure as code for deploying the Yushan Platform microservices to AWS. This is part of **Phase 3: Kubernetes & AWS Deployment** of the Yushan Platform project.

## 📁 Folder Structure

```
AWS_Deployment/
├── README.md                          # This file (overview + migration guide)
├── AWS_DEPLOYMENT_PREREQUISITES.md   # Prerequisites checklist and IAM User setup
├── AWS_ARCHITECTURE.md               # Architecture, cost, and resource management
└── scripts/
    └── check-prerequisites.sh         # Prerequisites check script
```

---

## 🚀 Quick Start

### 1. Check Prerequisites

```bash
# Run prerequisites check script
./scripts/check-prerequisites.sh
```

### 2. Setup AWS IAM User (Free Tier Compatible)

Follow guide: [AWS_DEPLOYMENT_PREREQUISITES.md](./AWS_DEPLOYMENT_PREREQUISITES.md)

```bash
# Configure IAM User credentials with profile: yushan
aws configure --profile yushan

# Enter:
# - Access Key ID
# - Secret Access Key
# - Default region: ap-southeast-1 (selected region)
# - Output format: json

# Verify
aws sts get-caller-identity --profile yushan
```

### 3. Review Prerequisites

Read: [AWS_DEPLOYMENT_PREREQUISITES.md](./AWS_DEPLOYMENT_PREREQUISITES.md)

### 4. Understand Architecture & Cost

Read: [AWS_ARCHITECTURE.md](./AWS_ARCHITECTURE.md)

---

## 📋 Task Progress

### Task 1: Deploy to AWS

- [x] **Subtask 1**: Prerequisites Check - Documentation and scripts created
- [x] **Subtask 2**: Create AWS Terraform Structure - Terraform folder structure, providers, variables, and configuration files created
- [x] **Subtask 3**: Setup VPC Infrastructure - VPC, subnets (public/private), Internet Gateway, NAT Gateway, Route Tables created
- [x] **Subtask 4**: Setup Security Groups - Security groups for ALB, EKS, RDS, ElastiCache, and Kafka created
- [x] **Subtask 5**: Create EKS Cluster - EKS cluster with managed node groups, IAM roles, OIDC provider, and networking configured
- [x] **Subtask 6**: Setup RDS PostgreSQL - 5x RDS PostgreSQL instances (Database-per-Service pattern) with Multi-AZ, encryption, and backups configured
- [x] **Subtask 7**: Setup ElastiCache Redis - 5x ElastiCache Redis clusters (Database-per-Service pattern) with Multi-AZ, automatic failover, and encryption configured
- [x] **Subtask 8**: Setup EC2 Kafka Cluster - 3x EC2 Kafka brokers (t3.small, Multi-AZ) with EBS volumes, IAM roles, and userdata script configured
- [x] **Subtask 9**: Setup S3 Buckets - S3 bucket for content storage with versioning, encryption, CORS, bucket policies, and lifecycle policies configured
- [x] **Subtask 10**: Setup Application Load Balancer - ALB with HTTPS/HTTP listeners, target groups, and AWS Load Balancer Controller integration configured
- [x] **Subtask 11**: Create ECR Repositories - ECR repositories for all 6 microservices with image scanning, encryption, lifecycle policies, and EKS access policies
- [x] **Subtask 12**: Update Service Configs - Created SERVICE_CONFIGS_GUIDE.md with detailed instructions, example configs, and extract-aws-endpoints.sh script for extracting Terraform outputs
- [x] **Subtask 13**: Create K8s Manifests - Created Kubernetes manifests for all 6 services (Deployments, Services, Ingress), ConfigMaps, Secrets templates, and comprehensive README
- [x] **Subtask 14**: Testing & Validation - Created TESTING_VALIDATION_GUIDE.md with comprehensive testing procedures and validate-deployment.sh script for automated validation

---

## 📚 Documentation

- [AWS_DEPLOYMENT_PREREQUISITES.md](./AWS_DEPLOYMENT_PREREQUISITES.md) - Prerequisites checklist and IAM User setup
- [AWS_ARCHITECTURE.md](./AWS_ARCHITECTURE.md) - Production-standard architecture with Database-per-Service pattern, cost breakdown (12 hours/day), and resource lifecycle
- [SERVICE_URLS.md](./SERVICE_URLS.md) - **Service URLs and Swagger UI access** (updated with current LoadBalancer URLs)
- [KUBERNETES_SERVICE_TYPES.md](./KUBERNETES_SERVICE_TYPES.md) - Explanation of LoadBalancer vs ClusterIP service types

---

## 📋 Migration Overview

### Current Infrastructure (Digital Ocean)
- 12 Droplets (~$144/month)
- Docker containers
- Self-managed databases (PostgreSQL, Redis, Elasticsearch)
- Self-managed Kafka

### Target Infrastructure (AWS) - Production-Standard
- EKS Cluster (Kubernetes orchestration, Multi-AZ)
- RDS PostgreSQL (5x db.t3.micro Multi-AZ - Database-per-Service pattern)
- ElastiCache Redis (5x cache.t3.micro Multi-AZ - Database-per-Service pattern)
- EC2 Kafka Cluster (3x t3.small Multi-AZ - 3 brokers)
- S3 (Object storage)
- Application Load Balancer (ALB)
- Runtime: 12 hours/day (8 AM - 8 PM)

### Migration Phases

**Phase 1: Infrastructure Setup (Current Task - Task 1: Deploy to AWS)**
1. ✅ Prerequisites Check
2. ✅ Create AWS Terraform Structure
3. ✅ Setup VPC Infrastructure
4. ✅ Setup Security Groups
5. ✅ Create EKS Cluster (Multi-AZ)
6. ✅ Setup RDS PostgreSQL (5x instances - Database-per-Service)
7. ✅ Setup ElastiCache Redis (5x clusters - Database-per-Service)
8. ✅ Setup EC2 Kafka Cluster (3 brokers Multi-AZ)
9. ✅ Setup S3 Buckets
10. ✅ Setup Application Load Balancer (ALB)
11. ✅ Create ECR Repositories
12. ✅ Update Service Configs
13. ✅ Create K8s Manifests
14. ✅ Testing & Validation

**Phase 2: Kubernetes Migration (Task 2)**
- Remove Eureka (replace with Kubernetes Service Discovery)
- Deploy services to K8s
- Implement HPA (Horizontal Pod Autoscaler)
- Setup Ingress (ALB Ingress Controller)

**Phase 3: Configuration Management (Task 3)**
- Migrate from Config Server to AWS AppConfig/Parameter Store/Secrets Manager
- Replace Spring Cloud Config Server with AWS managed services

**Phase 4: Observability (Task 4)**
- Implement Distributed Tracing (Jaeger/Zipkin)
- Enhanced monitoring and observability

### Migration Strategy

**Blue-Green Deployment:**
1. Blue (Current): Digital Ocean infrastructure (keep running)
2. Green (New): AWS infrastructure (deploy in parallel)
3. Migration: Gradually migrate traffic
4. Cutover: Switch DNS to AWS
5. Cleanup: Decommission Digital Ocean resources

**Data Migration:**
1. Database: Use pg_dump/pg_restore or AWS DMS
2. Files: Sync from Digital Ocean Spaces to S3
3. Kafka: Replay events or use MirrorMaker

---

## 🔗 Related Repositories

### Phase 3 Microservices (Development Repositories)
- [yushan-microservices-api-gateway](https://github.com/phutruonnttn/yushan-microservices-api-gateway) - API Gateway (Phase 3 development)
- [yushan-microservices-user-service](https://github.com/phutruonnttn/yushan-microservices-user-service) - User Service (Phase 3 development)
- [yushan-microservices-content-service](https://github.com/phutruonnttn/yushan-microservices-content-service) - Content Service (Phase 3 development)
- [yushan-microservices-engagement-service](https://github.com/phutruonnttn/yushan-microservices-engagement-service) - Engagement Service (Phase 3 development)
- [yushan-microservices-gamification-service](https://github.com/phutruonnttn/yushan-microservices-gamification-service) - Gamification Service (Phase 3 development)
- [yushan-microservices-analytics-service](https://github.com/phutruonnttn/yushan-microservices-analytics-service) - Analytics Service (Phase 3 development)

### Infrastructure & Deployment
- [Digital_Ocean_Deployment_with_Terraform](https://github.com/phutruonnttn/Digital_Ocean_Deployment_with_Terraform) - Current Digital Ocean deployment (Phase 2, to be migrated)
- [yushan-platform-docs](https://github.com/phutruonnttn/yushan-platform-docs) - Complete platform documentation

### Phase 2 Original Repositories (Production - Digital Ocean)
- [yushan-api-gateway](https://github.com/maugus0/yushan-api-gateway) - API Gateway (Phase 2, deployed on Digital Ocean)
- [yushan-user-service](https://github.com/maugus0/yushan-user-service) - User Service (Phase 2, deployed on Digital Ocean)
- [yushan-content-service](https://github.com/maugus0/yushan-content-service) - Content Service (Phase 2, deployed on Digital Ocean)
- [yushan-engagement-service](https://github.com/maugus0/yushan-engagement-service) - Engagement Service (Phase 2, deployed on Digital Ocean)
- [yushan-gamification-service](https://github.com/maugus0/yushan-gamification-service) - Gamification Service (Phase 2, deployed on Digital Ocean)
- [yushan-analytics-service](https://github.com/maugus0/yushan-analytics-service) - Analytics Service (Phase 2, deployed on Digital Ocean)

---

## 💰 Cost Summary (7 days × 12 hours/day)

**Daily Cost Breakdown:**
- EKS Cluster: $2.43/day (always-on)
- EKS Nodes: $0.50/day (12 hours)
- RDS PostgreSQL (5x db.t3.micro Multi-AZ): $2.04/day (12 hours)
- ElastiCache Redis (5x cache.t3.micro Multi-AZ): $1.02/day (12 hours)
- Kafka Cluster (3x t3.small Multi-AZ): $0.75/day (12 hours)
  - ✅ High Availability (3 brokers, can lose 1)
  - ✅ Production-grade load handling
  - ⚠️ NOT using 1x t3.micro (learning only, no HA, cannot handle load)
- ALB: $0.54/day (always-on)
- **LoadBalancers (6x)**: ~$4.00/day (always-on) ⚠️ **Temporary for testing**
- Data Transfer & CloudWatch: ~$0.20/day

**Current Total: ~$11.48/day × 7 days = ~$80.36** ⚠️ (with 6 LoadBalancers for testing)

**Recommended Total (ClusterIP): ~$7.48/day × 7 days = ~$52.36** ✅ (within $100 credit, 48% remaining)

**Schedule:** 8 AM - 8 PM (12 hours/day)

**Note**: Current setup uses 6 LoadBalancers for testing Swagger UI. Switch to ClusterIP after testing to save ~$28/week.

---

## 📝 Notes

- All AWS deployment files are centralized in this folder
- Terraform configurations are in `terraform/` subfolder
- Kubernetes manifests will be created in `kubernetes/` subfolder (Subtask 13)
- All Terraform state is stored in S3 backend (`yushan-terraform-state` bucket)
- All secrets should be stored in AWS Secrets Manager (Task 3)
- **Architecture**: Database-per-Service pattern (production-standard)
- **Runtime**: 12 hours/day (8 AM - 8 PM) for cost optimization
- **Region**: ap-southeast-1 (Singapore)
- **Environment**: development (optimized for learning)

## 🎯 Phase 3 Context

This AWS deployment is part of **Phase 3: Kubernetes & AWS Deployment** of the Yushan Platform project. Phase 3 focuses on:

- **Cloud-Native Architecture**: Kubernetes-native service discovery (replacing Eureka)
- **Production-Standard Infrastructure**: AWS managed services (RDS, ElastiCache, ALB)
- **Database-per-Service Pattern**: Complete service isolation with independent databases
- **High Availability**: Multi-AZ deployment for all critical services
- **Cost Optimization**: 12 hours/day runtime for learning purposes

**Phase 3 Progress**: 75% Complete
- ✅ Rich Domain Model refactoring
- ✅ Inter-service communication optimization
- ✅ Hybrid idempotency implementation
- ✅ Repository Pattern (all services)
- ✅ Aggregate Boundaries & Domain Events
- ✅ Gateway-Level JWT Authentication with HMAC Signature
- ✅ Circuit Breakers & Rate Limiters
- ✅ SAGA Pattern for distributed transactions
- ✅ **AWS Infrastructure Deployment** (Task 1 Complete) - All services deployed and running on AWS EKS
- ⏳ **In Progress**: Kubernetes migration (Task 2), Configuration management (Task 3), Distributed tracing (Task 4)

For complete Phase 3 documentation, see: [Phase 3 README](https://github.com/phutruonnttn/yushan-platform-docs/blob/main/docs/phase3-kubernetes/README.md)

---

## 🚀 Deployment Status

### Current Deployment Configuration

**Services Deployed:**
- ✅ API Gateway: 1 replica, LoadBalancer
- ✅ User Service: 1 replica, LoadBalancer (temporary for testing)
- ✅ Content Service: 1 replica, LoadBalancer (temporary for testing)
- ✅ Analytics Service: 1 replica, LoadBalancer (temporary for testing)
- ✅ Engagement Service: 1 replica, LoadBalancer (temporary for testing)
- ✅ Gamification Service: 1 replica, LoadBalancer (temporary for testing)

**Service Types:**
- ⚠️ **Temporary Setup**: All services are exposed via LoadBalancer for testing Swagger UI
- 💰 **Cost Impact**: ~$120/month for 6 LoadBalancers (not recommended for production)
- ✅ **Recommended**: Use ClusterIP for microservices, only API Gateway as LoadBalancer (~$20/month)

**Access URLs:**
- See [SERVICE_URLS.md](./SERVICE_URLS.md) for all Swagger UI URLs and service endpoints
- All 6/6 Swagger UIs are accessible and working ✅
- All APIs are functional with Kafka enabled ✅

**Configuration:**
- All services use `docker` Spring profile (same as Digital Ocean deployment)
- Database-per-Service pattern: 5x RDS PostgreSQL instances ✅
- Redis-per-Service pattern: 5x ElastiCache Redis clusters ✅
- Kafka: 3 brokers (t3.small, Multi-AZ) - Installed, configured, and running ✅
- Zookeeper: Running on broker 1 (standalone mode) ✅
- Elasticsearch: Deployed and running for Content Service ✅
- Kubernetes Service Discovery (Eureka replaced) ✅

**Infrastructure:**
- EKS Cluster: 2 nodes (t3.small) - 4GB total memory ✅
- All services running simultaneously ✅
- Kafka connectivity: Accessible from EKS pods ✅
- All APIs tested and working ✅

**Logging:**
- CloudWatch Logs: Available for EKS cluster and RDS instances
- View logs via: `kubectl logs -n yushan -l app=<service-name>`
- CloudWatch Log Groups: `/aws/eks/yushan-development-eks-cluster/cluster`

**Note**: After testing, consider switching microservices back to ClusterIP to save costs. See [KUBERNETES_SERVICE_TYPES.md](./KUBERNETES_SERVICE_TYPES.md) for details.

---

**Status**: ✅ **Task 1 Complete - AWS Deployment Fully Operational!** 🎉  
**Deployment**: ✅ All services deployed, running, and tested
- ✅ All infrastructure subtasks (1-14) completed
- ✅ All 6 microservices deployed and accessible
- ✅ Kafka installed, configured, and running
- ✅ All APIs functional with Kafka enabled
- ✅ All Swagger UIs accessible (6/6)

**Repository**: [yushan-AWS-deployment](https://github.com/phutruonnttn/yushan-AWS-deployment)

