# Terraform Backend S3 Setup Guide

## 📖 What is Terraform Backend S3?

**Terraform Backend** is where Terraform stores its **state file** - a file that tracks all the infrastructure resources Terraform manages.

### Why S3 Backend?

1. **Centralized State**: State file stored in S3 (not on your local machine)
2. **Team Collaboration**: Multiple people can work on the same infrastructure
3. **State Locking**: DynamoDB prevents conflicts when multiple people run Terraform at the same time
4. **Backup & Safety**: State is automatically backed up in S3
5. **CI/CD Friendly**: Works with automated pipelines

### What You Need

- **S3 Bucket**: `yushan-terraform-state` - stores the state file
- **DynamoDB Table**: `yushan-terraform-locks` - provides state locking

## 🚀 Quick Setup (Automated)

Run the setup script:

```bash
cd AWS_Deployment
./scripts/setup-terraform-backend.sh
```

This script will:
- ✅ Create S3 bucket with versioning and encryption
- ✅ Create DynamoDB table for state locking
- ✅ Configure proper security settings

## 📝 Manual Setup

If you prefer to create resources manually:

### Step 1: Create S3 Bucket

```bash
# Create bucket
aws s3api create-bucket \
    --bucket yushan-terraform-state \
    --region ap-southeast-1 \
    --create-bucket-configuration LocationConstraint=ap-southeast-1 \
    --profile yushan

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket yushan-terraform-state \
    --versioning-configuration Status=Enabled \
    --profile yushan

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket yushan-terraform-state \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }' \
    --profile yushan

# Block public access
aws s3api put-public-access-block \
    --bucket yushan-terraform-state \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --profile yushan
```

### Step 2: Create DynamoDB Table

```bash
aws dynamodb create-table \
    --table-name yushan-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ap-southeast-1 \
    --profile yushan

# Wait for table to be active
aws dynamodb wait table-exists \
    --table-name yushan-terraform-locks \
    --profile yushan
```

## 🔄 After Setup

Once S3 bucket and DynamoDB table are created:

```bash
cd terraform
terraform init
```

Terraform will automatically:
- Connect to S3 backend
- Use DynamoDB for state locking
- Store state file in S3

## ⚠️ Alternative: Use Local Backend (Temporary)

If you want to start working **before** creating S3 backend:

1. **Comment out backend block** in `versions.tf`:

```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    # ... providers ...
  }

  # backend "s3" {
  #   bucket         = "yushan-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   encrypt        = true
  #   dynamodb_table = "yushan-terraform-locks"
  #   profile        = "yushan"
  # }
}
```

2. **Initialize with local backend**:

```bash
terraform init
```

3. **Later, migrate to S3 backend**:

```bash
# Uncomment backend block in versions.tf
# Then run:
terraform init -migrate-state
```

## 💰 Cost

- **S3 Bucket**: ~$0.023/GB/month (state file is tiny, ~few KB)
- **DynamoDB**: Pay-per-request, ~$0.25 per million requests (very cheap for state locking)

**Total**: ~$0.01-0.05/month (practically free)

## 🔐 Security Notes

- State file contains **sensitive information** (resource IDs, sometimes passwords)
- S3 bucket has **public access blocked**
- State file is **encrypted** at rest
- Only IAM user `terraform-deployment` has access (via profile `yushan`)

## 📚 References

- [Terraform S3 Backend Documentation](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS S3 Pricing](https://aws.amazon.com/s3/pricing/)
- [DynamoDB Pricing](https://aws.amazon.com/dynamodb/pricing/)

