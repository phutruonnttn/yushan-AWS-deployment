# ElastiCache Redis Configuration (Database-per-Service Pattern)

# ElastiCache Subnet Group (for Multi-AZ deployment in private subnets)
resource "aws_elasticache_subnet_group" "main" {
  count      = var.elasticache_database_per_service && length(var.elasticache_clusters) > 0 ? 1 : 0
  name       = "${local.name_prefix}-elasticache-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-elasticache-subnet-group"
    }
  )
}

# ElastiCache Parameter Group (for Redis configuration)
resource "aws_elasticache_parameter_group" "redis" {
  count  = var.elasticache_database_per_service && length(var.elasticache_clusters) > 0 ? 1 : 0
  family = "redis7"
  name   = "${local.name_prefix}-redis-params"

  # Redis configuration parameters
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru" # Evict least recently used keys when memory is full
  }

  parameter {
    name  = "timeout"
    value = "300" # Close idle connections after 5 minutes
  }

  parameter {
    name  = "tcp-keepalive"
    value = "60" # TCP keepalive interval
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-redis-params"
    }
  )
}

# ElastiCache Replication Groups (Database-per-Service Pattern)
# Using Replication Group for Multi-AZ with automatic failover
resource "aws_elasticache_replication_group" "main" {
  for_each = var.elasticache_database_per_service ? {
    for cluster in var.elasticache_clusters : cluster.name => cluster
  } : {}

  replication_group_id       = "${var.project_name}-${var.environment}-${replace(each.value.name, "_", "-")}"
  description                = "ElastiCache Redis cluster for ${each.value.name} (Database-per-Service)"
  num_cache_clusters          = var.elasticache_multi_az ? 2 : 1 # Primary + Replica for Multi-AZ
  automatic_failover_enabled  = var.elasticache_multi_az
  multi_az_enabled           = var.elasticache_multi_az
  node_type                   = var.elasticache_node_type
  engine                      = "redis"
  engine_version              = "7.0"
  port                        = 6379

  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.main[0].name
  security_group_ids = [aws_security_group.elasticache.id]

  # Parameter group
  parameter_group_name = aws_elasticache_parameter_group.redis[0].name

  # Snapshot configuration
  snapshot_retention_limit = var.elasticache_snapshot_retention_limit
  snapshot_window         = var.elasticache_snapshot_window

  # Maintenance window
  maintenance_window = var.elasticache_maintenance_window

  # Automatic minor version upgrade
  auto_minor_version_upgrade = true

  # At-rest encryption
  at_rest_encryption_enabled = var.elasticache_at_rest_encryption_enabled

  # In-transit encryption (TLS)
  transit_encryption_enabled = var.elasticache_transit_encryption_enabled

  # Log delivery configuration (CloudWatch Logs)
  # Note: Log delivery requires IAM role with proper permissions
  # Disabled by default for cost optimization
  dynamic "log_delivery_configuration" {
    for_each = var.elasticache_log_delivery_enabled ? [1] : []
    content {
      destination      = aws_cloudwatch_log_group.elasticache[0].arn
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "slow-log"
    }
  }

  # Tags
  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-${each.value.identifier}"
      Service     = each.value.name
      Database    = "redis"
      Environment = var.environment
    }
  )

  depends_on = [
    aws_elasticache_subnet_group.main,
    aws_elasticache_parameter_group.redis,
  ]
}

# CloudWatch Log Group for ElastiCache (optional, for slow log delivery)
resource "aws_cloudwatch_log_group" "elasticache" {
  count             = var.elasticache_database_per_service && length(var.elasticache_clusters) > 0 && var.elasticache_log_delivery_enabled ? 1 : 0
  name              = "/aws/elasticache/${local.name_prefix}-redis/slow-log"
  retention_in_days = 7

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-elasticache-slow-log"
    }
  )
}

