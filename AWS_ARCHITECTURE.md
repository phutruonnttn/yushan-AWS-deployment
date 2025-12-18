# AWS Architecture & Cost Guide - Yushan Platform

## 🎯 Overview

This document defines the **production-standard architecture** for AWS deployment optimized for **7-day learning sessions (12 hours/day)** with **$100 AWS credit**. The architecture uses **Database-per-Service pattern** for both RDS and Redis, prioritizing production best practices including Multi-AZ deployment, high availability, and true microservices isolation while staying within budget.

---

## ✅ Final Architecture Decisions

### Infrastructure Components

| Component | Decision | Rationale |
|-----------|----------|-----------|
| **IAM User** | `terraform-deployment` (Admin) | Simple, free tier compatible |
| **AWS Profile** | `yushan` | Consistent naming |
| **Region** | `ap-southeast-1` (Singapore) | Selected region |
| **Environment** | `development` | Learning environment |
| **EKS** | ✅ Yes | Required for K8s orchestration |
| **EKS Nodes** | 2x t3.small | Minimum for HA, production-ready |
| **RDS** | ✅ 5x db.t3.micro Multi-AZ (Database-per-Service) | Production-standard pattern |
| **Redis** | ✅ 5x cache.t3.micro Multi-AZ (Database-per-Service) | Production-standard pattern |
| **Kafka** | ✅ 3x EC2 t3.small | Production-standard (3 brokers) |
| **ALB** | ✅ Yes | Production-standard load balancer |
| **Ingress** | ✅ AWS Load Balancer Controller | ALB Ingress Controller for EKS |
| **Multi-AZ** | ✅ Yes | Production-standard High Availability |

### What We're NOT Using

- ❌ **IAM Identity Center (SSO)**: Not used, using IAM User instead

---

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│   Production-Standard Architecture (Database-per-Service) │
├─────────────────────────────────────────────────┤
│                                                 │
│  EKS Cluster ($2.43/day - always-on)           │
│  └─ Node Group: 2x t3.small ($0.50/day - 12h) │
│     - Multi-AZ deployment                       │
│     - Auto-scaling: 2-4 nodes                  │
│                                                 │
│  RDS PostgreSQL Multi-AZ ($2.04/day - 12h)    │
│  ├─ user_service: db.t3.micro Multi-AZ         │
│  ├─ content_service: db.t3.micro Multi-AZ      │
│  ├─ analytics_service: db.t3.micro Multi-AZ    │
│  ├─ engagement_service: db.t3.micro Multi-AZ   │
│  └─ gamification_service: db.t3.micro Multi-AZ│
│     - Each: Primary + Standby (automatic failover) │
│     - Automated backups (7 days)              │
│     - Encryption at rest                       │
│                                                 │
│  ElastiCache Redis Multi-AZ ($1.02/day - 12h)  │
│  ├─ user_service: cache.t3.micro Multi-AZ      │
│  ├─ content_service: cache.t3.micro Multi-AZ   │
│  ├─ analytics_service: cache.t3.micro Multi-AZ│
│  ├─ engagement_service: cache.t3.micro Multi-AZ│
│  └─ gamification_service: cache.t3.micro Multi-AZ│
│     - Each: Primary + Replica (automatic failover) │
│     - Complete service isolation               │
│                                                 │
│  EC2 Kafka Cluster ($0.75/day - 12h)           │
│  └─ 3x t3.small (3 brokers)                    │
│     - Multi-AZ deployment                      │
│     - Replication factor: 3                    │
│     - ✅ High Availability (can lose 1 broker)│
│     - ✅ Production-grade load handling        │
│     - ✅ Production-grade reliability          │
│     - ⚠️ NOT using 1x t3.micro (learning only)│
│                                                 │
│  ALB (Application Load Balancer)               │
│  └─ $0.54/day (~$16.20/month - always-on)     │
│     - SSL/TLS termination                      │
│     - Path-based routing                       │
│     - Health checks                            │
│     - Integration with EKS                     │
│                                                 │
│  S3 (FREE)                                      │
│  └─ 5GB storage                                │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 🎯 Production-Standard Architecture Decisions

### 1. RDS PostgreSQL - Database-per-Service Pattern

**✅ Production-Standard Configuration:**
- **5x db.t3.micro Multi-AZ** (Database-per-Service pattern)
  - `user_service` → `yushan-user-db` (db.t3.micro Multi-AZ)
  - `content_service` → `yushan-content-db` (db.t3.micro Multi-AZ)
  - `analytics_service` → `yushan-analytics-db` (db.t3.micro Multi-AZ)
  - `engagement_service` → `yushan-engagement-db` (db.t3.micro Multi-AZ)
  - `gamification_service` → `yushan-gamification-db` (db.t3.micro Multi-AZ)
- **Benefits**:
  - Complete service isolation
  - Independent scaling per service
  - Independent deployment (schema changes don't affect other services)
  - Automatic failover (< 60 seconds) per database
  - Synchronous replication
  - Zero data loss
  - Production-grade reliability
  - True microservices pattern

### 2. ElastiCache Redis - Database-per-Service Pattern

**✅ Production-Standard Configuration:**
- **5x cache.t3.micro Multi-AZ** (Database-per-Service pattern)
  - `user_service` → `yushan-user-redis` (cache.t3.micro Multi-AZ)
  - `content_service` → `yushan-content-redis` (cache.t3.micro Multi-AZ)
  - `analytics_service` → `yushan-analytics-redis` (cache.t3.micro Multi-AZ)
  - `engagement_service` → `yushan-engagement-redis` (cache.t3.micro Multi-AZ)
  - `gamification_service` → `yushan-gamification-redis` (cache.t3.micro Multi-AZ)
- **Benefits**:
  - Complete service isolation
  - Independent scaling per service
  - No key prefix conflicts
  - Automatic failover per cluster
  - Read replicas for scaling
  - Production-grade reliability
  - True microservices pattern

### 3. Kafka - 3 Brokers for Production Reliability

**✅ Production-Standard Configuration:**
- **3x t3.small brokers** (Multi-AZ deployment)
- Replication factor: 3
- **Benefits**:
  - ✅ **High Availability**: Can lose 1 broker without service interruption
  - ✅ **Production-Grade Load Handling**: Can handle production workloads
  - ✅ **Data Replication**: Data replicated across AZs
  - ✅ **Automatic Failover**: Broker failure automatically handled
  - ✅ **Suitable for Production**: Production-grade reliability

**⚠️ WARNING: Kafka 1 Broker t3.micro (Learning Only - NOT Recommended)**

**❌ NOT Used in This Architecture:**
- **1x t3.micro broker** (single instance)
- **Limitations**:
  - ❌ **No High Availability**: Single point of failure
  - ❌ **Cannot Handle Production Load**: Insufficient resources
  - ❌ **No Replication**: Data loss risk
  - ❌ **No Failover**: Service interruption on failure
- **✅ Only Suitable For**:
  - Learning event flow patterns
  - Understanding topic/consumer group concepts
  - Architecture demos
  - **NOT for production workloads**

**✅ This Architecture Uses: 3x t3.small Multi-AZ (Production-Standard)**

---

## 💰 Cost Breakdown

### Free Tier Usage (First 12 Months)

| Service | Free Tier Limit | Our Usage | Cost |
|---------|----------------|-----------|------|
| **S3** | 5GB storage | ~2GB | **$0** |
| **EBS** | 30GB storage | 20GB | **$0** |
| **Data Transfer** | 15GB/month | <15GB | **$0** |

**Note**: We're using production-grade instances (t3.small) which are not free tier eligible, but provide production-standard reliability.

### Paid Services (Production-Standard - 12 hours/day)

| Service | Configuration | Hours/Day | Cost/Hour | Daily Cost |
|---------|--------------|-----------|-----------|------------|
| **EKS Cluster** | 1 cluster | 24 (always-on) | $0.101 | $2.43/day |
| **EKS Node Group** | 2x t3.small (Multi-AZ) | 12 | $0.0416 | $0.50/day |
| **RDS PostgreSQL** | 5x db.t3.micro Multi-AZ | 12 | $0.034 | $2.04/day |
| **ElastiCache Redis** | 5x cache.t3.micro Multi-AZ | 12 | $0.017 | $1.02/day |
| **Kafka Cluster** | 3x t3.small (Multi-AZ) | 12 | $0.0208 | $0.75/day |
| **ALB** | 1 Application Load Balancer | 24 (always-on) | $0.0225 | $0.54/day |
| **Data Transfer** | >15GB (if applicable) | Variable | Variable | ~$0.10/day |
| **CloudWatch** | Logs/metrics (beyond free tier) | Variable | Variable | ~$0.10/day |

**Total Daily Cost: ~$7.48/day (12 hours runtime)**

### Cost for 7 Days Usage (12 hours/day)

**Daily Cost Breakdown (12 hours runtime):**
- EKS Cluster: $2.43/day (always-on)
- EKS Nodes (2x t3.small Multi-AZ): $0.50/day (12 hours)
- RDS PostgreSQL (5x db.t3.micro Multi-AZ): $2.04/day (12 hours)
- ElastiCache Redis (5x cache.t3.micro Multi-AZ): $1.02/day (12 hours)
- Kafka Cluster (3x t3.small Multi-AZ): $0.75/day (12 hours)
- ALB: $0.54/day (always-on)
- Data Transfer & CloudWatch: ~$0.20/day
- S3: $0/day (free tier)

**Total Daily Cost: ~$7.48/day**

**Cost for Learning Sessions (7 days × 12 hours/day):**
- **7 days**: **~$52.36** ✅ (within $100 credit, 48% remaining)
- **$100 credit duration**: ~13.4 days (at 12 hours/day)

**✅ Perfect for 7-day learning session with Database-per-Service pattern!**

---

## 🔧 Terraform Configuration

```yaml
# Terraform variables - Final approved configuration
region: ap-southeast-1  # Singapore (selected region)
environment: development  # Learning environment
iam_user_name: terraform-deployment  # IAM User name
aws_profile: yushan  # AWS CLI profile name

# EKS - Production-Standard
eks_cluster_enabled: true
eks_node_instance_type: t3.small  # Production-grade instance
eks_node_count: 2  # Minimum for HA
eks_node_min_size: 2
eks_node_max_size: 4  # Auto-scaling enabled
eks_multi_az: true  # ✅ Production-standard: Multi-AZ deployment
eks_use_spot_instances: false  # Stable for production-like learning
eks_runtime_hours: 12  # Run 12 hours per day (cost optimization)

# RDS - Database-per-Service Pattern (Production-Standard)
rds_instance_type: db.t3.micro  # Cost-optimized for 12 hours/day
rds_multi_az: true  # ✅ Production-standard: Multi-AZ for HA
rds_backup_retention: 7  # Production-like backups
rds_database_per_service: true  # ✅ Production-standard: Database-per-Service pattern
rds_storage_encrypted: true  # Production security
rds_databases:  # One database per service
  - name: user_service
    identifier: yushan-user-db
  - name: content_service
    identifier: yushan-content-db
  - name: analytics_service
    identifier: yushan-analytics-db
  - name: engagement_service
    identifier: yushan-engagement-db
  - name: gamification_service
    identifier: yushan-gamification-db

# ElastiCache - Database-per-Service Pattern (Production-Standard)
elasticache_node_type: cache.t3.micro  # Cost-optimized for 12 hours/day
elasticache_multi_az: true  # ✅ Production-standard: Multi-AZ for HA
elasticache_cluster_mode: false  # Single node with replica (Multi-AZ)
elasticache_database_per_service: true  # ✅ Production-standard: Database-per-Service pattern
elasticache_clusters:  # One cluster per service
  - name: user_service
    identifier: yushan-user-redis
  - name: content_service
    identifier: yushan-content-redis
  - name: analytics_service
    identifier: yushan-analytics-redis
  - name: engagement_service
    identifier: yushan-engagement-redis
  - name: gamification_service
    identifier: yushan-gamification-redis

# Kafka - Production-Standard 3 Brokers (HA & Load Handling)
kafka_instance_type: t3.small  # ✅ Production-grade instance (NOT t3.micro)
kafka_count: 3  # ✅ Production-standard: 3 brokers for HA
kafka_multi_az: true  # ✅ Production-standard: Multi-AZ deployment
kafka_replication_factor: 3  # Production-grade replication
kafka_suitable_for: production  # ✅ Production-grade reliability & load handling
kafka_runtime_hours: 12  # Run 12 hours per day (cost optimization)

# ⚠️ WARNING: Do NOT use 1x t3.micro broker (learning only, no HA, cannot handle load)
# ❌ kafka_instance_type: t3.micro  # NOT recommended for production
# ❌ kafka_count: 1  # NOT recommended - no HA, single point of failure
# ❌ Limitations of 1x t3.micro:
#    - No High Availability (single point of failure)
#    - Cannot handle production load (insufficient resources)
#    - No replication (data loss risk)
#    - No failover (service interruption on failure)
# ✅ Only suitable for: learning event flow, topic/consumer group demos, architecture demos

# ALB - Production-standard load balancer
alb_enabled: true  # ✅ USED - Application Load Balancer
alb_type: application  # Application Load Balancer (Layer 7)
alb_internal: false  # Internet-facing
alb_ssl_certificate: arn:aws:acm:...  # SSL/TLS certificate ARN
alb_listeners:
  - port: 443
    protocol: HTTPS
    default_action: forward
  - port: 80
    protocol: HTTP
    default_action: redirect_to_https

# AWS Load Balancer Controller for EKS
alb_ingress_controller_enabled: true  # AWS Load Balancer Controller
alb_ingress_class: alb  # Ingress class name

# S3
s3_versioning: true  # Production feature
s3_lifecycle_policies: true  # Cost optimization
s3_encryption: true  # Production security

# CloudWatch
cloudwatch_logs_retention: 7  # 7 days retention
cloudwatch_alarms_enabled: true  # Production monitoring
```

---

## 🚀 Resource Lifecycle Management

### Start/Stop Strategy

**When Starting Learning Session (12 hours/day):**
1. Start EKS cluster (always-on)
2. Start EKS nodes (12 hours)
3. Start all 5 RDS instances (12 hours)
4. Start all 5 ElastiCache clusters (12 hours)
5. Start Kafka cluster (12 hours)
6. ALB is always-on (AWS managed service)
7. AWS Load Balancer Controller starts automatically (runs on EKS nodes)
8. Total cost: ~$7.48/day

**When Stopping (End of 12-hour Session):**
1. Stop EKS nodes → Saves $0.50/day (EKS cluster remains, but no compute cost)
2. Stop all 5 RDS instances → Saves $2.04/day (can restart with Terraform)
3. Delete all 5 ElastiCache clusters → Saves $1.02/day (can recreate with Terraform)
4. Stop Kafka instances → Saves $0.75/day (can restart with Terraform)
5. ALB remains (always-on, $0.54/day)
6. EKS cluster remains (always-on, $2.43/day)
7. AWS Load Balancer Controller stops automatically (no additional cost)
8. Total cost when stopped: ~$2.97/day (only EKS cluster + ALB running)

### Quick Start/Stop Scripts

**Start All Resources (12 hours/day):**
```bash
# Start EKS nodes
eksctl scale nodegroup --cluster=yushan-cluster --nodes=2 --name=ng-1

# Start all 5 RDS instances
aws rds start-db-instance --db-instance-identifier yushan-user-db
aws rds start-db-instance --db-instance-identifier yushan-content-db
aws rds start-db-instance --db-instance-identifier yushan-analytics-db
aws rds start-db-instance --db-instance-identifier yushan-engagement-db
aws rds start-db-instance --db-instance-identifier yushan-gamification-db

# Start Kafka instances (if stopped)
aws ec2 start-instances --instance-ids <kafka-instance-ids>

# Create ALB (if deleted)
terraform apply -target=aws_lb.main

# Create all 5 ElastiCache clusters (if deleted)
terraform apply -target=aws_elasticache_replication_group.user
terraform apply -target=aws_elasticache_replication_group.content
terraform apply -target=aws_elasticache_replication_group.analytics
terraform apply -target=aws_elasticache_replication_group.engagement
terraform apply -target=aws_elasticache_replication_group.gamification

# AWS Load Balancer Controller starts automatically (deployed on EKS nodes)

# Verify all services are running
kubectl get nodes
kubectl get ingress -A
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `yushan`)].LoadBalancerName'
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]' --output table
aws elasticache describe-replication-groups --query 'ReplicationGroups[*].[ReplicationGroupId,Status]' --output table
```

**Stop All Resources (After 12 hours - Save Costs):**
```bash
# Scale down EKS nodes to 0 (saves $0.50/day)
eksctl scale nodegroup --cluster=yushan-cluster --nodes=0 --name=ng-1

# Stop all 5 RDS instances (saves $2.04/day)
aws rds stop-db-instance --db-instance-identifier yushan-user-db
aws rds stop-db-instance --db-instance-identifier yushan-content-db
aws rds stop-db-instance --db-instance-identifier yushan-analytics-db
aws rds stop-db-instance --db-instance-identifier yushan-engagement-db
aws rds stop-db-instance --db-instance-identifier yushan-gamification-db

# Stop Kafka instances (saves $0.75/day)
aws ec2 stop-instances --instance-ids <kafka-instance-ids>

# Delete all 5 ElastiCache clusters (saves $1.02/day)
terraform destroy -target=aws_elasticache_replication_group.user
terraform destroy -target=aws_elasticache_replication_group.content
terraform destroy -target=aws_elasticache_replication_group.analytics
terraform destroy -target=aws_elasticache_replication_group.engagement
terraform destroy -target=aws_elasticache_replication_group.gamification

# ALB remains (always-on, $0.54/day)
# EKS cluster remains (always-on, $2.43/day)

# AWS Load Balancer Controller stops automatically (no action needed)
```

### Typical Learning Session Workflow (12 hours/day)

**Day 1: Setup & Infrastructure**
- Morning (8 AM): Start all resources (~$7.48 for 12 hours)
- Activities: Deploy infrastructure, setup EKS, configure ALB, Database-per-Service RDS/Redis, Multi-AZ Kafka
- Evening (8 PM): Stop compute resources, keep EKS cluster + ALB running

**Day 2-6: Development & Learning**
- Daily (8 AM - 8 PM): Resources running 12 hours (~$7.48/day)
- Activities: Deploy microservices, test Database-per-Service isolation, test Multi-AZ failover, learn production patterns
- Total for 5 days: ~$37.40

**Day 7: Testing & Cleanup**
- Morning (8 AM - 8 PM): Final testing (production-grade scenarios)
- Evening (8 PM): Stop all resources
- Total for 7 days: ~$52.36 ✅ (within $100 credit, 48% remaining)

---

## 💡 Cost-Saving Tips

1. **Stop When Not in Use (After 12 hours)**
   - EKS Nodes: Scale to 0 (saves $0.50/day, cluster remains)
   - RDS: Stop all 5 instances (saves $2.04/day)
   - Kafka: Stop all 3 instances (saves $0.75/day)
   - ElastiCache: Delete all 5 clusters (saves $1.02/day)
   - ALB: Remains always-on ($0.54/day)
   - EKS Cluster: Remains always-on ($2.43/day)

2. **Use Spot Instances (Optional)**
   - EKS nodes: 90% discount
   - Risk: Instances can be terminated
   - Total with Spot: ~$2.53/day

3. **Schedule Resources (Automated)**
   - Auto-start at 8 AM, auto-stop at 8 PM (12 hours/day)
   - Use AWS EventBridge + Lambda for automation
   - Daily cost: ~$7.48/day (12 hours runtime)
   - Total 7 days: ~$52.36

---

## 📋 Naming Conventions

| Item | Name | Notes |
|------|------|-------|
| IAM User | `terraform-deployment` | Exact name |
| AWS Profile | `yushan` | CLI profile name |
| Environment | `development` | Learning environment |
| Region | `ap-southeast-1` | Singapore |
| Repository | `AWS_Deployment/` | Folder name |

---

## ✅ Key Decisions Summary

1. **Database-per-Service RDS**: 5x db.t3.micro Multi-AZ (one per service) - True microservices pattern
2. **Database-per-Service Redis**: 5x cache.t3.micro Multi-AZ (one per service) - True microservices pattern
3. **Kafka 3 Brokers Multi-AZ**: 3x t3.small brokers across multiple AZs (production-standard with HA & load handling)
   - ⚠️ **NOT using 1x t3.micro** (learning only, no HA, cannot handle production load)
4. **ALB**: Using Application Load Balancer (production-standard)
5. **Multi-AZ Deployment**: All critical services deployed Multi-AZ (production-standard)
6. **12 Hours Runtime**: Optimized for learning sessions (12 hours/day, 7 days)
7. **IAM User**: Not using SSO (simpler for learning)

---

## 📚 Additional Resources

- [AWS Free Tier Details](https://aws.amazon.com/free/)
- [AWS Cost Calculator](https://calculator.aws/)
- [EKS Pricing](https://aws.amazon.com/eks/pricing/)
- [RDS Free Tier](https://aws.amazon.com/rds/free/)

---

**Next Step**: Proceed to Subtask 2: Create AWS Terraform Structure

