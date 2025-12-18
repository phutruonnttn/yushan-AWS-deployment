# AWS Deployment - Yushan Platform

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
- [ ] **Subtask 5**: Create EKS Cluster
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

**Phase 1: Infrastructure Setup (Current Task)**
1. ✅ Prerequisites Check
2. ⏳ Create AWS Terraform Structure
3. ⏳ Setup VPC Infrastructure
4. ⏳ Setup Security Groups
5. ⏳ Create EKS Cluster (Multi-AZ)
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
- Remove Eureka
- Deploy services to K8s
- Implement HPA
- Setup Ingress

**Phase 3: Configuration Management (Task 3)**
- Migrate to AWS AppConfig/Parameter Store/Secrets Manager

**Phase 4: Observability (Task 4)**
- Implement Distributed Tracing

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

## 🔗 Related Folders

- `Digital_Ocean_Deployment_with_Terraform/` - Current Digital Ocean deployment (to be migrated)
- `yushan-microservices-*/` - Individual microservices (will be updated for AWS)

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
- Terraform configurations will be created in `terraform/` subfolder (Subtask 2)
- Kubernetes manifests will be created in `kubernetes/` subfolder (Subtask 13)
- All Terraform state will be stored in S3 backend
- All secrets should be stored in AWS Secrets Manager (Task 3)
- **Architecture**: Database-per-Service pattern (production-standard)
- **Runtime**: 12 hours/day (8 AM - 8 PM) for cost optimization

---

**Status**: ✅ Subtask 4 Complete - Ready for Subtask 5 (EKS Cluster)

