output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "Availability zones used"
  value       = local.azs
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "eks_cluster_security_group_id" {
  description = "EKS Cluster Security Group ID"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_security_group_id" {
  description = "EKS Nodes Security Group ID"
  value       = aws_security_group.eks_nodes.id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "elasticache_security_group_id" {
  description = "ElastiCache Security Group ID"
  value       = aws_security_group.elasticache.id
}

output "kafka_security_group_id" {
  description = "Kafka Security Group ID"
  value       = aws_security_group.kafka.id
}

output "eks_cluster_id" {
  description = "EKS Cluster ID"
  value       = var.eks_cluster_enabled ? try(aws_eks_cluster.main[0].id, null) : null
}

output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = var.eks_cluster_enabled ? try(aws_eks_cluster.main[0].name, null) : null
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = var.eks_cluster_enabled ? try(aws_eks_cluster.main[0].endpoint, null) : null
}

output "eks_cluster_version" {
  description = "EKS Cluster Kubernetes version"
  value       = var.eks_cluster_enabled ? try(aws_eks_cluster.main[0].version, null) : null
}

output "eks_cluster_arn" {
  description = "EKS Cluster ARN"
  value       = var.eks_cluster_enabled ? try(aws_eks_cluster.main[0].arn, null) : null
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS Cluster certificate authority data (for kubectl config)"
  value       = var.eks_cluster_enabled ? try(aws_eks_cluster.main[0].certificate_authority[0].data, null) : null
}

output "eks_cluster_oidc_issuer_url" {
  description = "EKS Cluster OIDC issuer URL (for AWS Load Balancer Controller)"
  value       = var.eks_cluster_enabled ? try(aws_eks_cluster.main[0].identity[0].oidc[0].issuer, null) : null
}

output "eks_node_group_id" {
  description = "EKS Node Group ID"
  value       = var.eks_cluster_enabled ? try(aws_eks_node_group.main[0].id, null) : null
}

output "eks_node_group_arn" {
  description = "EKS Node Group ARN"
  value       = var.eks_cluster_enabled ? try(aws_eks_node_group.main[0].arn, null) : null
}

output "rds_instance_endpoints" {
  description = "RDS instance endpoints (Database-per-Service)"
  value = var.rds_database_per_service ? {
    for db in var.rds_databases : db.name => try(aws_db_instance.main[db.name].endpoint, null)
  } : {}
}

output "rds_instance_addresses" {
  description = "RDS instance addresses (Database-per-Service)"
  value = var.rds_database_per_service ? {
    for db in var.rds_databases : db.name => try(aws_db_instance.main[db.name].address, null)
  } : {}
}

output "rds_instance_ids" {
  description = "RDS instance IDs (Database-per-Service)"
  value = var.rds_database_per_service ? {
    for db in var.rds_databases : db.name => try(aws_db_instance.main[db.name].id, null)
  } : {}
}

output "rds_instance_arns" {
  description = "RDS instance ARNs (Database-per-Service)"
  value = var.rds_database_per_service ? {
    for db in var.rds_databases : db.name => try(aws_db_instance.main[db.name].arn, null)
  } : {}
}

output "elasticache_cluster_endpoints" {
  description = "ElastiCache cluster endpoints (Database-per-Service)"
  value = var.elasticache_database_per_service ? {
    for cluster in var.elasticache_clusters : cluster.name => try(aws_elasticache_replication_group.main[cluster.name].configuration_endpoint_address, aws_elasticache_replication_group.main[cluster.name].primary_endpoint_address, null)
  } : {}
}

output "elasticache_cluster_primary_endpoints" {
  description = "ElastiCache cluster primary endpoints (Database-per-Service)"
  value = var.elasticache_database_per_service ? {
    for cluster in var.elasticache_clusters : cluster.name => try(aws_elasticache_replication_group.main[cluster.name].primary_endpoint_address, null)
  } : {}
}

output "elasticache_cluster_reader_endpoints" {
  description = "ElastiCache cluster reader endpoints (Database-per-Service) - for Multi-AZ read replicas"
  value = var.elasticache_database_per_service ? {
    for cluster in var.elasticache_clusters : cluster.name => try(aws_elasticache_replication_group.main[cluster.name].reader_endpoint_address, null)
  } : {}
}

output "elasticache_cluster_ids" {
  description = "ElastiCache cluster IDs (Database-per-Service)"
  value = var.elasticache_database_per_service ? {
    for cluster in var.elasticache_clusters : cluster.name => try(aws_elasticache_replication_group.main[cluster.name].id, null)
  } : {}
}

output "elasticache_cluster_arns" {
  description = "ElastiCache cluster ARNs (Database-per-Service)"
  value = var.elasticache_database_per_service ? {
    for cluster in var.elasticache_clusters : cluster.name => try(aws_elasticache_replication_group.main[cluster.name].arn, null)
  } : {}
}

output "kafka_broker_ips" {
  description = "Kafka broker private IPs"
  value       = aws_instance.kafka[*].private_ip
}

output "kafka_broker_private_dns" {
  description = "Kafka broker private DNS names"
  value       = aws_instance.kafka[*].private_dns
}

output "kafka_broker_ids" {
  description = "Kafka broker EC2 instance IDs"
  value       = aws_instance.kafka[*].id
}

output "kafka_broker_endpoints" {
  description = "Kafka broker endpoints (for bootstrap servers configuration)"
  value       = [for instance in aws_instance.kafka : "${instance.private_ip}:9092"]
}

output "kafka_broker_arns" {
  description = "Kafka broker EC2 instance ARNs"
  value       = aws_instance.kafka[*].arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = var.alb_enabled ? try(aws_lb.main[0].dns_name, null) : null
}

output "alb_arn" {
  description = "ALB ARN"
  value       = var.alb_enabled ? try(aws_lb.main[0].arn, null) : null
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = var.alb_enabled ? try(aws_lb.main[0].zone_id, null) : null
}

output "alb_target_group_arn" {
  description = "ALB target group ARN for API Gateway"
  value       = var.alb_enabled ? try(aws_lb_target_group.api_gateway[0].arn, null) : null
}

output "alb_https_listener_arn" {
  description = "ALB HTTPS listener ARN"
  value       = var.alb_enabled && var.alb_ssl_certificate_arn != "" ? try(aws_lb_listener.https[0].arn, null) : null
}

output "alb_http_listener_arn" {
  description = "ALB HTTP listener ARN"
  value       = var.alb_enabled ? try(aws_lb_listener.http[0].arn, null) : null
}

output "s3_bucket_names" {
  description = "S3 bucket names"
  value       = [aws_s3_bucket.content_storage.id]
}

output "s3_content_storage_bucket_name" {
  description = "S3 content storage bucket name"
  value       = aws_s3_bucket.content_storage.id
}

output "s3_content_storage_bucket_arn" {
  description = "S3 content storage bucket ARN"
  value       = aws_s3_bucket.content_storage.arn
}

output "s3_content_storage_bucket_domain_name" {
  description = "S3 content storage bucket domain name"
  value       = aws_s3_bucket.content_storage.bucket_domain_name
}

output "s3_content_storage_bucket_regional_domain_name" {
  description = "S3 content storage bucket regional domain name"
  value       = aws_s3_bucket.content_storage.bucket_regional_domain_name
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value = {
    for repo in local.ecr_repositories : repo => try(aws_ecr_repository.main[repo].repository_url, null)
  }
}

output "ecr_repository_arns" {
  description = "ECR repository ARNs"
  value = {
    for repo in local.ecr_repositories : repo => try(aws_ecr_repository.main[repo].arn, null)
  }
}

output "ecr_repository_names" {
  description = "ECR repository names"
  value = {
    for repo in local.ecr_repositories : repo => try(aws_ecr_repository.main[repo].name, null)
  }
}

