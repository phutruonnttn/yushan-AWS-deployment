# ECR (Elastic Container Registry) Repositories Configuration

# List of services that need ECR repositories
locals {
  ecr_repositories = [
    "api-gateway",
    "user-service",
    "content-service",
    "engagement-service",
    "gamification-service",
    "analytics-service"
  ]
}

# ECR Repositories for all microservices
resource "aws_ecr_repository" "main" {
  for_each = toset(local.ecr_repositories)
  name     = "${local.name_prefix}-${each.value}"

  image_tag_mutability = "MUTABLE" # Allow overwriting tags

  # Image scanning configuration (for security)
  image_scanning_configuration {
    scan_on_push = var.ecr_image_scanning_enabled
  }

  # Encryption configuration
  encryption_configuration {
    encryption_type = "AES256" # Always encrypted
  }

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-${each.value}"
      Service     = each.value
      Environment = var.environment
    }
  )
}

# ECR Lifecycle Policy (cost optimization - delete old images)
resource "aws_ecr_lifecycle_policy" "main" {
  for_each   = toset(local.ecr_repositories)
  repository = aws_ecr_repository.main[each.value].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description   = "Keep last ${var.ecr_image_retention_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policy (allow EKS nodes to pull images)
resource "aws_ecr_repository_policy" "main" {
  for_each   = toset(local.ecr_repositories)
  repository = aws_ecr_repository.main[each.value].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      var.eks_cluster_enabled ? [
        {
          Sid    = "AllowEKSNodePull"
          Effect = "Allow"
          Principal = {
            AWS = try(aws_iam_role.eks_node_group[0].arn, "*")
          }
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetAuthorizationToken"
          ]
        },
        {
          Sid    = "AllowEKSClusterAccess"
          Effect = "Allow"
          Principal = {
            AWS = try(aws_iam_role.eks_cluster[0].arn, "*")
          }
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetAuthorizationToken"
          ]
        }
      ] : []
    )
  })
}

