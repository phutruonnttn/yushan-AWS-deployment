# Terraform Configuration for Yushan Platform AWS Deployment

This directory contains Terraform configurations for deploying the Yushan Platform to AWS.

## 📁 Structure

```
terraform/
├── main.tf                    # Main configuration - providers and locals
├── variables.tf                # Variable definitions
├── outputs.tf                 # Output definitions
├── versions.tf                # Provider version constraints and backend config
├── terraform.tfvars           # Variable values (DO NOT COMMIT SECRETS)
├── terraform.tfvars.example   # Example variable values template
├── .gitignore                 # Git ignore rules for Terraform files
└── README.md                  # This file
```

## 🚀 Quick Start

### 1. Prerequisites

- AWS CLI configured with profile `yushan`
- Terraform >= 1.5.0 installed
- **S3 Backend Setup**: Run `./scripts/setup-terraform-backend.sh` to create S3 bucket and DynamoDB table (or see [BACKEND_SETUP.md](./BACKEND_SETUP.md) for manual setup)

### 2. Setup S3 Backend (Required)

**Option A: Automated Setup (Recommended)**
```bash
cd AWS_Deployment
./scripts/setup-terraform-backend.sh
```

**Option B: Manual Setup**
See [BACKEND_SETUP.md](./BACKEND_SETUP.md) for detailed instructions.

**Option C: Use Local Backend Temporarily**
If you want to start before creating S3 backend, comment out the `backend "s3"` block in `versions.tf` and use local backend. You can migrate to S3 later.

### 3. Initialize Terraform

```bash
cd terraform
terraform init
```

**Note**: If S3 backend is not set up, Terraform will fail. Either:
- Run the setup script first (recommended)
- Or comment out backend block to use local backend temporarily

### 4. Validate Configuration

```bash
terraform validate
```

### 5. Plan Changes

```bash
terraform plan
```

### 6. Apply Changes

```bash
terraform apply
```

## 📋 Configuration

### Variables

All variables are defined in `variables.tf` with default values. Override them in `terraform.tfvars`.

### Key Variables

- **aws_region**: `ap-southeast-1` (Singapore)
- **aws_profile**: `yushan` (AWS CLI profile)
- **environment**: `development`
- **project_name**: `yushan`

### Architecture Pattern

- **Database-per-Service**: Each microservice has its own RDS and Redis instance
- **Multi-AZ**: All critical services deployed across multiple availability zones
- **Production-Standard**: Using production-grade configurations

## 🔐 Backend Configuration

Terraform state is stored in S3 with DynamoDB for state locking:

- **S3 Bucket**: `yushan-terraform-state`
- **DynamoDB Table**: `yushan-terraform-locks`
- **Region**: `ap-southeast-1`

**Important**: 
- Run `./scripts/setup-terraform-backend.sh` to create S3 bucket and DynamoDB table
- Or see [BACKEND_SETUP.md](./BACKEND_SETUP.md) for manual setup
- Or use local backend temporarily (comment out backend block in `versions.tf`)

## 📝 Notes

- **terraform.tfvars**: Contains actual values (may contain secrets - review before committing)
- **terraform.tfvars.example**: Template file (safe to commit)
- **State files**: Never commit `*.tfstate` files (already in .gitignore)
- **Secrets**: Store sensitive values in AWS Secrets Manager (Task 3)

## 🔗 Related Documentation

- [BACKEND_SETUP.md](./BACKEND_SETUP.md) - Detailed guide for setting up S3 backend
- [AWS_ARCHITECTURE.md](../AWS_ARCHITECTURE.md) - Architecture decisions and cost breakdown
- [AWS_DEPLOYMENT_PREREQUISITES.md](../AWS_DEPLOYMENT_PREREQUISITES.md) - Prerequisites checklist

