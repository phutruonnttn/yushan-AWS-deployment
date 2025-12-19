# EKS Cluster Configuration

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  count = var.eks_cluster_enabled ? 1 : 0
  name  = "${local.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eks-cluster-role"
    }
  )
}

# Attach AWS managed policy for EKS Cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.eks_cluster_enabled ? 1 : 0
  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_group" {
  count = var.eks_cluster_enabled ? 1 : 0
  name  = "${local.name_prefix}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eks-node-group-role"
    }
  )
}

# Attach AWS managed policies for EKS Node Group
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  count      = var.eks_cluster_enabled ? 1 : 0
  role       = aws_iam_role.eks_node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count      = var.eks_cluster_enabled ? 1 : 0
  role       = aws_iam_role.eks_node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  count      = var.eks_cluster_enabled ? 1 : 0
  role       = aws_iam_role.eks_node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  count    = var.eks_cluster_enabled ? 1 : 0
  name     = "${local.name_prefix}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster[0].arn
  version  = "1.28" # Latest stable version

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"] # Allow public access for kubectl
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Enable control plane logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Encryption configuration
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks[0].arn
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks_cluster[0],
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eks-cluster"
    }
  )
}

# KMS Key for EKS encryption
resource "aws_kms_key" "eks" {
  count       = var.eks_cluster_enabled ? 1 : 0
  description = "KMS key for EKS cluster encryption"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eks-kms-key"
    }
  )
}

resource "aws_kms_alias" "eks" {
  count         = var.eks_cluster_enabled ? 1 : 0
  name          = "alias/${local.name_prefix}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks_cluster" {
  count             = var.eks_cluster_enabled ? 1 : 0
  name              = "/aws/eks/${local.name_prefix}-eks-cluster/cluster"
  retention_in_days = 7

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eks-cluster-logs"
    }
  )
}

# EKS OIDC Identity Provider (for AWS Load Balancer Controller and other addons)
data "tls_certificate" "eks" {
  count = var.eks_cluster_enabled ? 1 : 0
  url   = aws_eks_cluster.main[0].identity[0].oidc[0].issuer

  depends_on = [aws_eks_cluster.main]
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.eks_cluster_enabled ? 1 : 0
  url   = aws_eks_cluster.main[0].identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [data.tls_certificate.eks[0].certificates[0].sha1_fingerprint]

  depends_on = [data.tls_certificate.eks]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eks-oidc-provider"
    }
  )
}

# EKS Node Group (Managed Node Group)
resource "aws_eks_node_group" "main" {
  count           = var.eks_cluster_enabled ? 1 : 0
  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${local.name_prefix}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group[0].arn
  subnet_ids      = aws_subnet.private[*].id

  # Instance configuration
  instance_types = [var.eks_node_instance_type]
  capacity_type  = var.eks_use_spot_instances ? "SPOT" : "ON_DEMAND"

  # Scaling configuration
  scaling_config {
    desired_size = var.eks_node_count
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
  }

  # Update configuration
  update_config {
    max_unavailable = 1
  }

  # Remote access (SSH access to nodes - optional, for debugging)
  dynamic "remote_access" {
    for_each = var.eks_node_ssh_key_name != "" ? [1] : []
    content {
      ec2_ssh_key               = var.eks_node_ssh_key_name
      source_security_group_ids = [aws_security_group.eks_nodes.id]
    }
  }

  # Labels and taints
  labels = {
    Environment = var.environment
    NodeGroup   = "main"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eks-node-group"
    }
  )
}


