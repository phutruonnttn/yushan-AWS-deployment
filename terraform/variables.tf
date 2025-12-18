variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile name"
  type        = string
  default     = "yushan"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "yushan"
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
}

variable "eks_cluster_enabled" {
  description = "Enable EKS cluster creation"
  type        = bool
  default     = true
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS node group"
  type        = string
  default     = "t3.small"
}

variable "eks_node_count" {
  description = "Number of nodes in EKS node group"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in EKS node group"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in EKS node group"
  type        = number
  default     = 4
}

variable "eks_multi_az" {
  description = "Enable Multi-AZ deployment for EKS"
  type        = bool
  default     = true
}

variable "eks_use_spot_instances" {
  description = "Use Spot instances for EKS node group"
  type        = bool
  default     = false
}

variable "eks_runtime_hours" {
  description = "Number of hours per day to run EKS nodes (for cost optimization)"
  type        = number
  default     = 12
}

variable "rds_instance_type" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = true
}

variable "rds_backup_retention" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_storage_encrypted" {
  description = "Enable encryption for RDS storage"
  type        = bool
  default     = true
}

variable "rds_database_per_service" {
  description = "Use Database-per-Service pattern (one database per service)"
  type        = bool
  default     = true
}

variable "rds_databases" {
  description = "List of RDS databases (Database-per-Service pattern)"
  type = list(object({
    name       = string
    identifier = string
  }))
  default = [
    {
      name       = "user_service"
      identifier = "yushan-user-db"
    },
    {
      name       = "content_service"
      identifier = "yushan-content-db"
    },
    {
      name       = "analytics_service"
      identifier = "yushan-analytics-db"
    },
    {
      name       = "engagement_service"
      identifier = "yushan-engagement-db"
    },
    {
      name       = "gamification_service"
      identifier = "yushan-gamification-db"
    }
  ]
}

variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_multi_az" {
  description = "Enable Multi-AZ deployment for ElastiCache"
  type        = bool
  default     = true
}

variable "elasticache_cluster_mode" {
  description = "Enable cluster mode for ElastiCache (disabled = single node with replica)"
  type        = bool
  default     = false
}

variable "elasticache_database_per_service" {
  description = "Use Database-per-Service pattern for ElastiCache (one cluster per service)"
  type        = bool
  default     = true
}

variable "elasticache_clusters" {
  description = "List of ElastiCache clusters (Database-per-Service pattern)"
  type = list(object({
    name       = string
    identifier = string
  }))
  default = [
    {
      name       = "user_service"
      identifier = "yushan-user-redis"
    },
    {
      name       = "content_service"
      identifier = "yushan-content-redis"
    },
    {
      name       = "analytics_service"
      identifier = "yushan-analytics-redis"
    },
    {
      name       = "engagement_service"
      identifier = "yushan-engagement-redis"
    },
    {
      name       = "gamification_service"
      identifier = "yushan-gamification-redis"
    }
  ]
}

variable "kafka_instance_type" {
  description = "EC2 instance type for Kafka brokers"
  type        = string
  default     = "t3.small"
}

variable "kafka_count" {
  description = "Number of Kafka brokers (production-standard: 3 for HA)"
  type        = number
  default     = 3
}

variable "kafka_multi_az" {
  description = "Enable Multi-AZ deployment for Kafka"
  type        = bool
  default     = true
}

variable "kafka_replication_factor" {
  description = "Kafka replication factor"
  type        = number
  default     = 3
}

variable "kafka_runtime_hours" {
  description = "Number of hours per day to run Kafka brokers (for cost optimization)"
  type        = number
  default     = 12
}

variable "alb_enabled" {
  description = "Enable Application Load Balancer"
  type        = bool
  default     = true
}

variable "alb_type" {
  description = "ALB type (application or network)"
  type        = string
  default     = "application"
}

variable "alb_internal" {
  description = "Create internal ALB (false = internet-facing)"
  type        = bool
  default     = false
}

variable "alb_ssl_certificate_arn" {
  description = "ARN of SSL certificate for ALB HTTPS listener"
  type        = string
  default     = ""
}

variable "alb_ingress_controller_enabled" {
  description = "Enable AWS Load Balancer Controller for EKS"
  type        = bool
  default     = true
}

variable "alb_ingress_class" {
  description = "Ingress class name for ALB"
  type        = string
  default     = "alb"
}

variable "s3_versioning" {
  description = "Enable versioning for S3 buckets"
  type        = bool
  default     = true
}

variable "s3_lifecycle_policies" {
  description = "Enable lifecycle policies for S3 buckets"
  type        = bool
  default     = true
}

variable "s3_encryption" {
  description = "Enable encryption for S3 buckets"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 7
}

variable "cloudwatch_alarms_enabled" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway for cost optimization (not HA)"
  type        = bool
  default     = false
}

