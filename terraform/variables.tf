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

variable "eks_node_ssh_key_name" {
  description = "EC2 Key Pair name for SSH access to EKS nodes (optional, leave empty for no SSH access)"
  type        = string
  default     = ""
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

variable "rds_master_username" {
  description = "Master username for RDS instances"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "rds_master_password" {
  description = "Master password for RDS instances (should be set via terraform.tfvars or environment variable)"
  type        = string
  sensitive   = true
  default     = "" # Must be provided via terraform.tfvars
}

variable "rds_allocated_storage" {
  description = "Initial allocated storage for RDS instances (GB)"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for RDS instances (GB) - enables autoscaling"
  type        = number
  default     = 100
}

variable "rds_performance_insights_enabled" {
  description = "Enable Performance Insights for RDS instances"
  type        = bool
  default     = false # Disabled for cost optimization (learning environment)
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection for RDS instances"
  type        = bool
  default     = false # Disabled for learning environment (can be enabled for production)
}

variable "rds_enhanced_monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 = disabled, 60 = 1 minute)"
  type        = number
  default     = 0 # Disabled for cost optimization (learning environment)
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

variable "elasticache_snapshot_retention_limit" {
  description = "Number of days to retain ElastiCache snapshots"
  type        = number
  default     = 7
}

variable "elasticache_snapshot_window" {
  description = "Daily time range for ElastiCache snapshots (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "elasticache_maintenance_window" {
  description = "Weekly maintenance window for ElastiCache (UTC)"
  type        = string
  default     = "mon:05:00-mon:07:00"
}

variable "elasticache_at_rest_encryption_enabled" {
  description = "Enable encryption at rest for ElastiCache"
  type        = bool
  default     = true
}

variable "elasticache_transit_encryption_enabled" {
  description = "Enable encryption in transit (TLS) for ElastiCache"
  type        = bool
  default     = false # Disabled by default (requires auth token, adds complexity)
}

variable "elasticache_log_delivery_enabled" {
  description = "Enable CloudWatch log delivery for ElastiCache slow logs"
  type        = bool
  default     = false # Disabled for cost optimization (learning environment)
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

variable "kafka_version" {
  description = "Kafka version to install"
  type        = string
  default     = "3.6.0"
}

variable "kafka_ebs_volume_size" {
  description = "EBS volume size for Kafka data storage (GB)"
  type        = number
  default     = 50
}

variable "kafka_root_volume_size" {
  description = "Root EBS volume size for Kafka instances (GB)"
  type        = number
  default     = 20
}

variable "kafka_enhanced_monitoring" {
  description = "Enable enhanced monitoring for Kafka instances"
  type        = bool
  default     = false # Disabled for cost optimization (learning environment)
}

variable "kafka_use_elastic_ip" {
  description = "Use Elastic IPs for Kafka brokers (for stable IPs)"
  type        = bool
  default     = false # Not needed for private subnets, disabled by default
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

variable "alb_access_logs_enabled" {
  description = "Enable access logs for ALB (stored in S3)"
  type        = bool
  default     = false # Disabled for cost optimization (learning environment)
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

variable "s3_cors_allowed_origins" {
  description = "Allowed origins for S3 CORS configuration"
  type        = list(string)
  default     = ["*"] # Should be restricted to specific domains in production
}

variable "s3_notifications_enabled" {
  description = "Enable S3 bucket notifications (for event-driven processing)"
  type        = bool
  default     = false # Disabled by default (can be enabled for Lambda triggers)
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

variable "ecr_image_scanning_enabled" {
  description = "Enable image scanning on push for ECR repositories"
  type        = bool
  default     = true
}

variable "ecr_encryption_enabled" {
  description = "Enable encryption for ECR repositories"
  type        = bool
  default     = true
}

variable "ecr_image_retention_count" {
  description = "Number of images to retain in ECR repositories (old images will be deleted)"
  type        = number
  default     = 10
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

