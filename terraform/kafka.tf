# EC2 Kafka Cluster Configuration (3 Brokers Multi-AZ)

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for Kafka EC2 instances
resource "aws_iam_role" "kafka" {
  name = "${local.name_prefix}-kafka-role"

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
      Name = "${local.name_prefix}-kafka-role"
    }
  )
}

# IAM Instance Profile for Kafka EC2 instances
resource "aws_iam_instance_profile" "kafka" {
  name = "${local.name_prefix}-kafka-instance-profile"
  role = aws_iam_role.kafka.name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-kafka-instance-profile"
    }
  )
}

# Attach CloudWatch Agent policy (for monitoring)
resource "aws_iam_role_policy_attachment" "kafka_cloudwatch_agent" {
  role       = aws_iam_role.kafka.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach SSM Managed Instance Core policy (for Systems Manager access)
resource "aws_iam_role_policy_attachment" "kafka_ssm" {
  role       = aws_iam_role.kafka.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EBS volumes for Kafka data storage (one per broker)
resource "aws_ebs_volume" "kafka_data" {
  count             = var.kafka_count
  availability_zone = var.kafka_multi_az ? local.azs[count.index % length(local.azs)] : local.azs[0]
  size              = var.kafka_ebs_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-kafka-data-${count.index + 1}"
      KafkaBroker = count.index + 1
    }
  )
}

# EC2 Instances for Kafka brokers
resource "aws_instance" "kafka" {
  count         = var.kafka_count
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.kafka_instance_type

  # Multi-AZ distribution
  availability_zone = var.kafka_multi_az ? local.azs[count.index % length(local.azs)] : local.azs[0]

  # Network configuration
  subnet_id              = aws_subnet.private[count.index % length(aws_subnet.private)].id
  vpc_security_group_ids = [aws_security_group.kafka.id]

  # IAM role
  iam_instance_profile = aws_iam_instance_profile.kafka.name

  # Storage - root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = var.kafka_root_volume_size
    encrypted   = true

    tags = merge(
      local.common_tags,
      {
        Name        = "${local.name_prefix}-kafka-root-${count.index + 1}"
        KafkaBroker = count.index + 1
      }
    )
  }

  # User data script to install and configure Kafka
  # Note: Zookeeper connect string will be configured via a separate script after all instances are created
  # This is because we cannot reference other instances' IPs in userdata during creation
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    yum update -y
    
    # Install Java 17 (required for Kafka)
    yum install -y java-17-amazon-corretto
    
    # Install Kafka
    KAFKA_VERSION="${var.kafka_version}"
    KAFKA_DIR="/opt/kafka"
    mkdir -p $$KAFKA_DIR
    cd /tmp
    wget -q https://downloads.apache.org/kafka/$$KAFKA_VERSION/kafka_2.13-$$KAFKA_VERSION.tgz
    tar -xzf kafka_2.13-$$KAFKA_VERSION.tgz -C $$KAFKA_DIR --strip-components=1
    rm kafka_2.13-$$KAFKA_VERSION.tgz
    
    # Format and mount data volume
    DATA_DEVICE="/dev/xvdf"
    if [ -b $$DATA_DEVICE ]; then
      mkfs.ext4 -F $$DATA_DEVICE
      mkdir -p /data/kafka
      mount $$DATA_DEVICE /data/kafka
      echo "$$DATA_DEVICE /data/kafka ext4 defaults,nofail 0 2" >> /etc/fstab
      chown -R ec2-user:ec2-user /data/kafka
    fi
    
    # Configure Kafka
    BROKER_ID=${count.index}
    PRIVATE_IP=$$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    
    # Create Kafka config (Zookeeper connect will be updated later via script)
    cat > $$KAFKA_DIR/config/server.properties <<KAFKA_CONFIG
    broker.id=$$BROKER_ID
    listeners=PLAINTEXT://0.0.0.0:9092
    advertised.listeners=PLAINTEXT://$$PRIVATE_IP:9092
    log.dirs=/data/kafka/kafka-logs
    zookeeper.connect=localhost:2181
    num.network.threads=8
    num.io.threads=8
    socket.send.buffer.bytes=102400
    socket.receive.buffer.bytes=102400
    socket.request.max.bytes=104857600
    log.retention.hours=168
    log.segment.bytes=1073741824
    log.retention.check.interval.ms=300000
    KAFKA_CONFIG
    
    # Note: Zookeeper connect string needs to be updated after all brokers are created
    # This can be done manually or via a configuration management script
    # For now, using localhost:2181 as placeholder
    
    # Create systemd service for Kafka
    cat > /etc/systemd/system/kafka.service <<SERVICE
    [Unit]
    Description=Apache Kafka
    After=network.target
    
    [Service]
    Type=simple
    User=ec2-user
    Group=ec2-user
    ExecStart=$$KAFKA_DIR/bin/kafka-server-start.sh $$KAFKA_DIR/config/server.properties
    Restart=on-failure
    RestartSec=10
    
    [Install]
    WantedBy=multi-user.target
    SERVICE
    
    # Note: Kafka service should be started after Zookeeper connect is configured
    # systemctl daemon-reload
    # systemctl enable kafka
    # systemctl start kafka
    EOF
  )

  # Enable detailed monitoring
  monitoring = var.kafka_enhanced_monitoring

  # Disable API termination protection for learning environment
  disable_api_termination = false

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-kafka-broker-${count.index + 1}"
      KafkaBroker = count.index + 1
      Role        = "kafka"
    }
  )

  depends_on = [aws_ebs_volume.kafka_data]
}

# Attach EBS volumes to Kafka instances
resource "aws_volume_attachment" "kafka_data" {
  count       = var.kafka_count
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.kafka_data[count.index].id
  instance_id = aws_instance.kafka[count.index].id
}

# Elastic IPs for Kafka brokers (optional, for stable IPs)
resource "aws_eip" "kafka" {
  count  = var.kafka_use_elastic_ip ? var.kafka_count : 0
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.name_prefix}-kafka-eip-${count.index + 1}"
      KafkaBroker = count.index + 1
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Associate Elastic IPs with Kafka instances (if enabled)
resource "aws_eip_association" "kafka" {
  count       = var.kafka_use_elastic_ip ? var.kafka_count : 0
  instance_id = aws_instance.kafka[count.index].id
  allocation_id = aws_eip.kafka[count.index].id
}

