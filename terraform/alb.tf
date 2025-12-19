# Application Load Balancer (ALB) Configuration

# ALB (Application Load Balancer)
resource "aws_lb" "main" {
  count              = var.alb_enabled ? 1 : 0
  name               = "${local.name_prefix}-alb"
  internal           = var.alb_internal
  load_balancer_type = var.alb_type
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false # Disabled for learning environment

  enable_cross_zone_load_balancing = true
  enable_http2                    = true
  idle_timeout                    = 60

  # Access logs (optional, for monitoring)
  dynamic "access_logs" {
    for_each = var.alb_access_logs_enabled ? [1] : []
    content {
      bucket  = aws_s3_bucket.alb_logs[0].id
      enabled = true
      prefix  = "alb-access-logs"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb"
    }
  )
}

# S3 Bucket for ALB Access Logs (optional)
resource "aws_s3_bucket" "alb_logs" {
  count  = var.alb_enabled && var.alb_access_logs_enabled ? 1 : 0
  bucket = "${local.name_prefix}-alb-access-logs"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-access-logs"
    }
  )
}

# S3 Bucket Policy for ALB Access Logs
resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.alb_enabled && var.alb_access_logs_enabled ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObjectAcl"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
      }
    ]
  })
}

# ALB HTTPS Listener (port 443)
resource "aws_lb_listener" "https" {
  count             = var.alb_enabled && var.alb_ssl_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.alb_ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway[0].arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-https-listener"
    }
  )
}

# ALB HTTP Listener (port 80)
resource "aws_lb_listener" "http" {
  count             = var.alb_enabled ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  # If SSL certificate is provided, redirect to HTTPS; otherwise forward to target group
  default_action {
    type = var.alb_ssl_certificate_arn != "" ? "redirect" : "forward"
    dynamic "redirect" {
      for_each = var.alb_ssl_certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    target_group_arn = var.alb_ssl_certificate_arn == "" ? aws_lb_target_group.api_gateway[0].arn : null
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-http-listener"
    }
  )
}

# Target Group for API Gateway (default target group)
# Note: This will be connected to EKS API Gateway service via AWS Load Balancer Controller
resource "aws_lb_target_group" "api_gateway" {
  count                = var.alb_enabled ? 1 : 0
  name                 = "${local.name_prefix}-api-gateway-tg"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip" # For EKS pods (IP targets)
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  # Stickiness (session affinity) - optional
  stickiness {
    enabled         = false
    type            = "lb_cookie"
    cookie_duration = 86400
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-api-gateway-tg"
    }
  )
}

# Note: Additional target groups for other services will be created automatically
# by AWS Load Balancer Controller when Kubernetes Ingress resources are created.
# The ALB is ready to be used with AWS Load Balancer Controller.

