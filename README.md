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
- [ ] **Subtask 6**: Setup RDS PostgreSQL (5x instances - Database-per-Service)
- [ ] **Subtask 7**: Setup ElastiCache Redis (5x clusters - Database-per-Service)
- [ ] **Subtask 8**: Setup EC2 Kafka Cluster (3 brokers Multi-AZ)
- [ ] **Subtask 9**: Setup S3 Buckets
- [ ] **Subtask 10**: Setup Application Load Balancer (ALB)
- [ ] **Subtask 11**: Create ECR Repositories
- [ ] **Subtask 12**: Update Service Configs
- [ ] **Subtask 13**: Create K8s Manifests
- [ ] **Subtask 14**: Testing & Validation

---

## 📚 Documentation

- [AWS_DEPLOYMENT_PREREQUISITES.md](./AWS_DEPLOYMENT_PREREQUISITES.md) - Prerequisites checklist and IAM User setup
- [AWS_ARCHITECTURE.md](./AWS_ARCHITECTURE.md) - Production-standard architecture with Database-per-Service pattern, cost breakdown (12 hours/day), and resource lifecycle

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
6. ⏳ Setup RDS PostgreSQL (5x instances - Database-per-Service)
7. ⏳ Setup ElastiCache Redis (5x clusters - Database-per-Service)
8. ⏳ Setup EC2 Kafka Cluster (3 brokers Multi-AZ)
9. ⏳ Setup S3 Buckets
10. ⏳ Setup Application Load Balancer (ALB)
11. ⏳ Create ECR Repositories
12. ⏳ Update Service Configs
13. ⏳ Create K8s Manifests
14. ⏳ Testing & Validation

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
- Data Transfer & CloudWatch: ~$0.20/day

**Total: ~$7.48/day × 7 days = ~$52.36** ✅ (within $100 credit, 48% remaining)

**Schedule:** 8 AM - 8 PM (12 hours/day)

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

**Phase 3 Progress**: 65% Complete
- ✅ Rich Domain Model refactoring
- ✅ Inter-service communication optimization
- ✅ Hybrid idempotency implementation
- ✅ Repository Pattern (all services)
- ✅ Aggregate Boundaries & Domain Events
- ✅ Gateway-Level JWT Authentication with HMAC Signature
- ✅ Circuit Breakers & Rate Limiters
- ✅ SAGA Pattern for distributed transactions
- ⏳ **In Progress**: Kubernetes orchestration, AWS deployment (this repository)

For complete Phase 3 documentation, see: [Phase 3 README](https://github.com/phutruonnttn/yushan-platform-docs/blob/main/docs/phase3-kubernetes/README.md)

---

**Status**: ✅ Subtask 5 Complete - Ready for Subtask 6 (RDS PostgreSQL)

**Repository**: [yushan-AWS-deployment](https://github.com/phutruonnttn/yushan-AWS-deployment)

