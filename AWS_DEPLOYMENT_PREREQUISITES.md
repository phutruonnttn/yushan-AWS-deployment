# AWS Deployment - Prerequisites Checklist

## ✅ AWS Account Setup

### 1. AWS Account
- [ ] AWS Account created and verified
- [ ] Billing enabled and payment method added
- [ ] Account email verified

### 2. IAM User Setup (Free Tier Compatible)

**Why IAM User for Free Tier?**
- ✅ **Free Tier Compatible**: IAM Identity Center (SSO) may require paid features
- ✅ **Simple Setup**: No additional services needed
- ✅ **Suitable for Development**: Perfect for AWS Free Tier $100 credit
- ⚠️ **Security Note**: Enable MFA and rotate access keys regularly

**⚠️ IMPORTANT: IAM Identity Center (SSO) is NOT used**
- IAM Identity Center (SSO) is **NOT used** for this setup
- Reason: Unnecessary complexity for short-term learning (5-7 days)
- **IAM User + Access Key** is used instead
- This approach is simpler and sufficient for learning purposes

**Setup Steps:**

1. **Create IAM User**
   - [ ] Go to AWS Console → IAM → Users
   - [ ] Click "Add users"
   - [ ] Username: `terraform-deployment` (exact name as specified)
   - [ ] Access type: Select "Programmatic access" (for AWS CLI/Terraform)
   - [ ] Click "Next: Permissions"

2. **Attach Permissions**
   - [ ] Select "Attach policies directly"
   - [ ] Search and select: `AdministratorAccess` (for full access)
     - **OR** Create custom policy with only required permissions (more secure)
   - [ ] Click "Next: Tags" (optional)
   - [ ] Click "Next: Review"
   - [ ] Click "Create user"

3. **Save Access Keys**
   - [ ] **IMPORTANT**: Copy and save securely:
     - Access Key ID
     - Secret Access Key
   - [ ] ⚠️ **Warning**: Secret Access Key is shown only once!
   - [ ] Store in password manager or secure location
   - [ ] Click "Close"

4. **Enable MFA (Recommended)**
   - [ ] Go to IAM → Users → Select your user
   - [ ] Security credentials tab
   - [ ] Click "Assign MFA device"
   - [ ] Choose "Virtual MFA device" (use authenticator app)
   - [ ] Follow setup instructions

**Required AWS Permissions (for IAM User Policy):**
- EC2 (VPC, Security Groups, Instances)
- EKS (Cluster management, Node groups)
- RDS (Database instances)
- ElastiCache (Redis clusters)
- S3 (Bucket creation, policies)
- IAM (Roles, policies)
- MSK (Kafka clusters) - Optional
- Application Load Balancer (ALB)
- Route53 (DNS) - Optional
- ACM (SSL Certificates) - Optional
- CloudWatch (Logging, Metrics)

### 3. AWS CLI Installation & Configuration

```bash
# Install AWS CLI (macOS)
brew install awscli

# Or download from: https://aws.amazon.com/cli/

# Verify installation
aws --version
```

**Configure AWS CLI with IAM User:**

```bash
# Configure AWS credentials
aws configure

# Enter the following when prompted:
# AWS Access Key ID: <your-access-key-id>
# AWS Secret Access Key: <your-secret-access-key>
# Default region name: ap-southeast-1 (or us-east-1 for better free tier)
# Default output format: json

# Verify configuration
aws sts get-caller-identity

# Should output your IAM user ARN
```

**Using Named Profile (Required for this deployment)**

```bash
# Configure with profile name: yushan
aws configure --profile yushan

# Enter the following when prompted:
# AWS Access Key ID: <your-access-key-id>
# AWS Secret Access Key: <your-secret-access-key>
# Default region name: ap-southeast-1
# Default output format: json

# Use specific profile
aws sts get-caller-identity --profile yushan

# Set as default (optional)
export AWS_PROFILE=yushan
```

### 4. kubectl Installation

```bash
# Install kubectl (macOS)
brew install kubectl

# Verify installation
kubectl version --client
```

### 5. eksctl Installation (for EKS cluster management)

```bash
# Install eksctl (macOS)
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# Verify installation
eksctl version
```

### 6. Terraform Installation

```bash
# Install Terraform (macOS)
brew install terraform

# Verify installation
terraform version
```

### 7. Docker Installation

```bash
# Install Docker Desktop (macOS)
# Download from: https://www.docker.com/products/docker-desktop

# Verify installation
docker --version
docker compose version
```

---

## 📋 Information to Prepare

### AWS Configuration
- **AWS Region**: `ap-southeast-1` (Singapore) - **Selected for this deployment**
  - Alternatives: `us-east-1` (N. Virginia), `eu-west-1` (Ireland)
- **Environment**: `development` (optimized for free tier)
- **IAM User Name**: `terraform-deployment`
- **AWS CLI Profile**: `yushan`

### Domain & SSL (Optional)
- [ ] Domain name (if using custom domain)
- [ ] SSL certificate via AWS Certificate Manager (ACM)

### Secrets & Credentials
- [ ] Database passwords (for 5 PostgreSQL instances - Database-per-Service pattern)
- [ ] Redis passwords
- [ ] JWT secret keys
- [ ] Email SMTP credentials (if needed)
- [ ] GitHub Container Registry credentials (or ECR)

### Cost Estimation - AWS Free Tier Optimized

**Free Tier Eligible Services (First 12 Months):**

⚠️ **CRITICAL: Free Tier is per ACCOUNT, not per instance!**

| Service | Free Tier Limit | Our Usage | Cost |
|---------|----------------|-----------|------|
| **EC2** | 750 hours/month total (account-level) | 1x t3.micro (Kafka, single-AZ) | **$0** (free tier) |
| **RDS PostgreSQL** | N/A (using production-grade instances) | **5x db.t3.micro Multi-AZ** (Database-per-Service) | **$2.04/day** (12 hours) |
| **ElastiCache Redis** | N/A (using production-grade instances) | **5x cache.t3.micro Multi-AZ** (Database-per-Service) | **$1.02/day** (12 hours) |
| **S3** | 5GB storage, 20K GET requests | ~2GB storage | **$0** (free tier) |
| **EBS** | 30GB storage | 20GB for databases | **$0** (free tier) |
| **Data Transfer** | 15GB outbound/month | <15GB | **$0** (free tier) |

**⚠️ IMPORTANT Architecture Decisions:**

1. **RDS PostgreSQL - Database-per-Service Pattern**: 
   - ✅ **Production-Standard**: **5x db.t3.micro Multi-AZ** (one database per service)
   - ✅ **Benefits**: Complete service isolation, independent scaling, independent deployment
   - ✅ **High Availability**: Multi-AZ with automatic failover
   - ⚠️ **Cost**: $2.04/day (12 hours runtime) - NOT free tier (using production-grade pattern)
   - ❌ **NOT using**: 1 shared instance with multiple schemas (not production-standard)

2. **ElastiCache Redis - Database-per-Service Pattern**:
   - ✅ **Production-Standard**: **5x cache.t3.micro Multi-AZ** (one cluster per service)
   - ✅ **Benefits**: Complete service isolation, no key prefix conflicts, independent scaling
   - ✅ **High Availability**: Multi-AZ with automatic failover
   - ⚠️ **Cost**: $1.02/day (12 hours runtime) - NOT free tier (using production-grade pattern)
   - ❌ **NOT using**: 1 shared cluster with key prefixes (not production-standard)

3. **EC2 Kafka - Production-Standard**:
   - ✅ **Production-Standard**: **3x t3.small Multi-AZ** (3 brokers for HA)
   - ✅ **Benefits**: High availability, production-grade load handling, replication factor 3
   - ⚠️ **Cost**: $0.75/day (12 hours runtime)
   - ❌ **NOT using**: 1x t3.micro (learning only, no HA, cannot handle production load)

**Paid Services (Not in Free Tier):**

| Service | Configuration | Estimated Cost |
|---------|--------------|----------------|
| **EKS Cluster** | 1 cluster | ~$73/month (~$2.43/day) |
| **EKS Node Group** | 2x t3.small (Multi-AZ, 12 hours/day) | ~$0.50/day |
| **RDS PostgreSQL** | 5x db.t3.micro Multi-AZ (12 hours/day) | **$2.04/day** |
| **ElastiCache Redis** | 5x cache.t3.micro Multi-AZ (12 hours/day) | **$1.02/day** |
| **Kafka Cluster** | 3x t3.small Multi-AZ (12 hours/day) | **$0.75/day** |
| **ALB** | ✅ **USED** - Application Load Balancer (production-standard) | **$0.54/day** |
| **Data Transfer** | >15GB outbound | ~$0.10/day |
| **CloudWatch** | Logs/metrics (beyond free tier) | ~$0.10/day |
| **Total Paid** | | **~$7.48/day** |

**Total Cost (12 hours/day): ~$7.48/day**
- **5 days**: ~$37.40
- **7 days**: ~$52.36 ✅ (within $100 credit, 48% remaining)
- **$100 credit duration**: ~13.4 days (at 12 hours/day)

**Optimization Strategies (Production-Standard Architecture):**

1. **Database-per-Service Pattern (Production-Standard):**
   - ✅ **RDS**: 5x db.t3.micro Multi-AZ (one per service) - $2.04/day (12 hours)
   - ✅ **ElastiCache**: 5x cache.t3.micro Multi-AZ (one per service) - $1.02/day (12 hours)
   - ✅ **S3**: 5GB storage - FREE
   - ✅ **Kafka**: 3x t3.small Multi-AZ (3 brokers for HA) - $0.75/day (12 hours)

2. **Production-Standard Services:**
   - ✅ EKS: Required for K8s (~$2.43/day always-on)
   - ✅ EKS Nodes: 2x t3.small Multi-AZ (~$0.50/day, 12 hours)
   - ✅ **ALB: USED** - Application Load Balancer with AWS Load Balancer Controller (production-standard)
   - ✅ Multi-AZ deployment for all critical services (HA)

3. **Cost Optimization (12 hours/day runtime):**
   - ✅ Run compute resources only 12 hours/day (8 AM - 8 PM)
   - ✅ Stop RDS instances when not in use (saves $2.04/day)
   - ✅ Delete ElastiCache clusters when not in use (saves $1.02/day)
   - ✅ Stop Kafka instances when not in use (saves $0.75/day)
   - ✅ Scale EKS nodes to 0 when not in use (saves $0.50/day)
   - ✅ ALB and EKS cluster remain always-on (required for production-like setup)
   - ✅ Multi-AZ deployment for HA (production-standard)
   - ✅ Stop resources when not in use
   - ✅ Set up AWS Budget alerts at $20, $50, $75

4. **Architecture Notes:**
   - ✅ Using **Database-per-Service pattern** (production-standard)
   - ✅ **5x RDS instances** (one per service) - NOT using shared database
   - ✅ **5x Redis clusters** (one per service) - NOT using shared cluster
   - ✅ **Multi-AZ deployment** for all critical services (HA)
   - ✅ **12 hours/day runtime** (8 AM - 8 PM) for cost optimization
   - ⚠️ Monitor usage in AWS Cost Explorer to avoid bill shock

---

## 🔐 Security Best Practices

### 1. IAM Best Practices
- [ ] **Enable MFA for IAM user** - Required for security
- [ ] **Rotate access keys regularly** - Every 90 days recommended
- [ ] Enable MFA for root account
- [ ] Use least privilege principle (custom policies instead of AdministratorAccess if possible)
- [ ] Enable CloudTrail for audit logging (free tier: 1 trail)
- [ ] Don't commit access keys to Git
- [ ] Use IAM roles for EC2/EKS instances (not access keys)

### 2. Network Security
- [ ] Use private subnets for databases
- [ ] Restrict security groups to minimum required ports
- [ ] Enable VPC Flow Logs for monitoring

### 3. Secrets Management
- [ ] Store secrets in AWS Secrets Manager (will be done in Task 3)
- [ ] Never commit secrets to Git
- [ ] Use environment variables or parameter store
- [ ] **Rotate access keys regularly** - Set reminder for 90 days
- [ ] Use IAM roles for services (not access keys in code)

---

## 📝 Next Steps

After completing all prerequisites:
1. Run prerequisites check script: `./scripts/check-prerequisites.sh`
2. Verify AWS CLI can connect: `aws sts get-caller-identity`
3. Verify Terraform is installed: `terraform version`
4. Verify kubectl and eksctl are installed
5. Proceed to Subtask 2: Create AWS Terraform Structure

---

## 🔗 Useful Links

- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS Pricing Calculator](https://calculator.aws/)
- [EKS Pricing](https://aws.amazon.com/eks/pricing/)
- [RDS Pricing](https://aws.amazon.com/rds/pricing/)
- [ElastiCache Pricing](https://aws.amazon.com/elasticache/pricing/)

