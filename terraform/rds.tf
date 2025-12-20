# RDS PostgreSQL Configuration (Database-per-Service Pattern)

# RDS Subnet Group (for Multi-AZ deployment in private subnets)
resource "aws_db_subnet_group" "main" {
  count      = var.rds_database_per_service && length(var.rds_databases) > 0 ? 1 : 0
  name       = "${local.name_prefix}-rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-subnet-group"
    }
  )
}

# RDS Parameter Group (for PostgreSQL configuration)
resource "aws_db_parameter_group" "postgresql" {
  count  = var.rds_database_per_service && length(var.rds_databases) > 0 ? 1 : 0
  family = "postgres15"
  name   = "${local.name_prefix}-postgresql-params"

  # PostgreSQL configuration parameters
  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # Log queries taking longer than 1 second
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-postgresql-params"
    }
  )
}

# RDS Instances (Database-per-Service Pattern)
resource "aws_db_instance" "main" {
  for_each = var.rds_database_per_service ? {
    for db in var.rds_databases : db.name => db
  } : {}

  identifier = "${local.name_prefix}-${each.value.identifier}"

  # Engine configuration
  engine         = "postgres"
  engine_version = "15.15" # Latest PostgreSQL 15 version available in ap-southeast-1
  instance_class = var.rds_instance_type

  # Database configuration
  db_name  = each.value.name
  username = var.rds_master_username
  password = var.rds_master_password
  port     = 5432

  # Storage configuration
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = var.rds_storage_encrypted

  # Multi-AZ configuration
  multi_az = var.rds_multi_az

  # Backup configuration
  # Free Tier limit: 1 day backup retention (not 7 days)
  # Set to 1 for free tier, or 7 for production (requires account upgrade)
  # Free Tier limit: 1 day backup retention (not 7 days)
  # For free tier accounts, set to 1. For production, can use 7 (requires account upgrade)
  backup_retention_period = var.rds_backup_retention > 1 ? 1 : var.rds_backup_retention > 1 ? 1 : var.rds_backup_retention
  backup_window          = "03:00-04:00" # UTC time
  maintenance_window     = "mon:04:00-mon:05:00" # UTC time

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # Always in private subnets

  # Parameter group
  parameter_group_name = aws_db_parameter_group.postgresql[0].name

  # Performance Insights (optional, for monitoring)
  performance_insights_enabled = var.rds_performance_insights_enabled

  # Deletion protection (prevent accidental deletion)
  deletion_protection = var.rds_deletion_protection
  skip_final_snapshot = !var.rds_deletion_protection

  # Final snapshot name (if deletion protection is enabled)
  # Note: final_snapshot_identifier will be set when deletion protection is enabled
  # Using a static name to avoid changes on every plan
  final_snapshot_identifier = var.rds_deletion_protection ? "${local.name_prefix}-${each.value.identifier}-final-snapshot" : null

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval            = var.rds_enhanced_monitoring_interval
  monitoring_role_arn            = var.rds_enhanced_monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  # Tags
  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-${each.value.identifier}"
      Service     = each.value.name
      Database    = "postgresql"
      Environment = var.environment
    }
  )

  depends_on = [
    aws_db_subnet_group.main,
    aws_db_parameter_group.postgresql,
  ]
}

# IAM Role for RDS Enhanced Monitoring (optional)
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.rds_database_per_service && length(var.rds_databases) > 0 && var.rds_enhanced_monitoring_interval > 0 ? 1 : 0
  name  = "${local.name_prefix}-rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-enhanced-monitoring-role"
    }
  )
}

# Attach AWS managed policy for RDS Enhanced Monitoring
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.rds_database_per_service && length(var.rds_databases) > 0 && var.rds_enhanced_monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

