# S3 Buckets Configuration

# Main S3 Bucket for Content Storage (novel covers, images)
resource "aws_s3_bucket" "content_storage" {
  bucket = "${local.name_prefix}-content-storage"

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-content-storage"
      Purpose     = "content-storage"
      Service     = "content-service"
      Environment = var.environment
    }
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "content_storage" {
  count  = var.s3_versioning ? 1 : 0
  bucket = aws_s3_bucket.content_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "content_storage" {
  count  = var.s3_encryption ? 1 : 0
  bucket = aws_s3_bucket.content_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# S3 Bucket Public Access Block (security - block all public access)
resource "aws_s3_bucket_public_access_block" "content_storage" {
  bucket = aws_s3_bucket.content_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket CORS Configuration (for frontend access)
resource "aws_s3_bucket_cors_configuration" "content_storage" {
  bucket = aws_s3_bucket.content_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    allowed_origins = var.s3_cors_allowed_origins
    expose_headers  = ["ETag", "Content-Length", "Content-Type"]
    max_age_seconds = 3600
  }
}

# S3 Bucket Policy (allow EKS nodes and services to access)
resource "aws_s3_bucket_policy" "content_storage" {
  bucket = aws_s3_bucket.content_storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      var.eks_cluster_enabled ? [
        {
          Sid    = "AllowEKSNodeAccess"
          Effect = "Allow"
          Principal = {
            AWS = try(aws_iam_role.eks_node_group[0].arn, "*")
          }
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]
          Resource = [
            aws_s3_bucket.content_storage.arn,
            "${aws_s3_bucket.content_storage.arn}/*"
          ]
        },
        {
          Sid    = "AllowEKSClusterAccess"
          Effect = "Allow"
          Principal = {
            AWS = try(aws_iam_role.eks_cluster[0].arn, "*")
          }
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]
          Resource = [
            aws_s3_bucket.content_storage.arn,
            "${aws_s3_bucket.content_storage.arn}/*"
          ]
        }
      ] : []
    )
  })

  depends_on = [aws_s3_bucket_public_access_block.content_storage]
}

# S3 Bucket Lifecycle Configuration (cost optimization)
resource "aws_s3_bucket_lifecycle_configuration" "content_storage" {
  count  = var.s3_lifecycle_policies ? 1 : 0
  bucket = aws_s3_bucket.content_storage.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# S3 Bucket Notification Configuration (optional - for event-driven processing)
# Can be used to trigger Lambda functions on file uploads
resource "aws_s3_bucket_notification" "content_storage" {
  count  = var.s3_notifications_enabled ? 1 : 0
  bucket = aws_s3_bucket.content_storage.id

  # Example: CloudWatch Events (can be extended for Lambda triggers)
  # cloudwatch_configuration {
  #   cloudwatch_configuration_id = "content-upload-events"
  #   events                      = ["s3:ObjectCreated:*"]
  # }
}

