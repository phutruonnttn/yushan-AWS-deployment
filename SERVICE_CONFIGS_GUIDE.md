# Service Configuration Guide - AWS Endpoints

## 📋 Overview

This guide explains how to update service configurations with AWS endpoints after infrastructure deployment. Services use **Spring Cloud Config Server** which reads configurations from the Git repository `yushan-microservices-config-data`.

## 🏗️ Architecture

```
Services → Config Server → Config Repo (Git) → AWS Resources
```

- **Config Repo**: [yushan-microservices-config-data](https://github.com/phutruonnttn/yushan-microservices-config-data)
- **Config Server**: Reads from Git repo and serves via REST API
- **Services**: Pull config from Config Server on startup

## 📝 Steps to Update Service Configs

### Step 1: Get AWS Endpoints from Terraform Outputs

After running `terraform apply`, get the endpoints:

```bash
cd terraform
terraform output
```

Key outputs you'll need:
- RDS endpoints (for each service)
- ElastiCache endpoints (for each service)
- Kafka broker endpoints
- S3 bucket names
- ECR repository URLs
- ALB DNS name

### Step 2: Update Config Files in Config Repo

Edit configuration files in `yushan-microservices-config-data` repository:

1. **Clone the config repo**:
   ```bash
   git clone https://github.com/phutruonnttn/yushan-microservices-config-data.git
   cd yushan-microservices-config-data
   ```

2. **Update each service config file** in `configs/` directory:
   - `user-service.yml`
   - `content-service.yml`
   - `engagement-service.yml`
   - `gamification-service.yml`
   - `analytics-service.yml`

3. **Commit and push**:
   ```bash
   git add configs/
   git commit -m "Update service configs with AWS endpoints"
   git push origin main
   ```

4. **Config Server** will automatically fetch the new configs (refresh rate: 300 seconds)

5. **Restart services** to apply new configurations

## 🔧 Configuration Template

### Database Configuration (RDS PostgreSQL)

```yaml
spring:
  datasource:
    url: jdbc:postgresql://${RDS_ENDPOINT:user-service-db.xxxxx.ap-southeast-1.rds.amazonaws.com}:5432/${DB_NAME:user_service}
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:your-secure-password}
    driver-class-name: org.postgresql.Driver
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
```

### Redis Configuration (ElastiCache)

```yaml
spring:
  data:
    redis:
      host: ${REDIS_ENDPOINT:user-service-redis.xxxxx.cache.amazonaws.com}
      port: 6379
      password: ${REDIS_PASSWORD:}
      timeout: 2000ms
      lettuce:
        pool:
          max-active: 8
          max-idle: 8
          min-idle: 0
```

### Kafka Configuration

```yaml
spring:
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:kafka-broker-1:9092,kafka-broker-2:9092,kafka-broker-3:9092}
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
      acks: all
      retries: 3
    consumer:
      group-id: ${spring.application.name}
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      auto-offset-reset: earliest
      enable-auto-commit: false
```

### S3 Configuration (for Content Service)

```yaml
aws:
  s3:
    bucket-name: ${S3_BUCKET_NAME:yushan-development-content-storage}
    region: ${AWS_REGION:ap-southeast-1}
    access-key: ${AWS_ACCESS_KEY_ID:}
    secret-key: ${AWS_SECRET_ACCESS_KEY:}
```

### Service Discovery (Kubernetes Native)

```yaml
# Replace Eureka with Kubernetes Service Discovery
spring:
  cloud:
    kubernetes:
      discovery:
        enabled: true
      loadbalancer:
        enabled: true

# Remove Eureka configuration
# eureka:
#   client:
#     service-url:
#       defaultZone: http://eureka:8761/eureka/
```

### OpenFeign Client URLs (Kubernetes Service Names)

```yaml
services:
  user:
    url: http://user-service:8081
  content:
    url: http://content-service:8082
  engagement:
    url: http://engagement-service:8084
  gamification:
    url: http://gamification-service:8085
  analytics:
    url: http://analytics-service:8083
```

## 📋 Service-Specific Configurations

### User Service (`user-service.yml`)

```yaml
spring:
  datasource:
    url: jdbc:postgresql://${RDS_USER_SERVICE_ENDPOINT}:5432/user_service
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  
  data:
    redis:
      host: ${REDIS_USER_SERVICE_ENDPOINT}
      port: 6379

spring:
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS}
```

### Content Service (`content-service.yml`)

```yaml
spring:
  datasource:
    url: jdbc:postgresql://${RDS_CONTENT_SERVICE_ENDPOINT}:5432/content_service
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  
  data:
    redis:
      host: ${REDIS_CONTENT_SERVICE_ENDPOINT}
      port: 6379

aws:
  s3:
    bucket-name: ${S3_CONTENT_STORAGE_BUCKET}
    region: ${AWS_REGION}

spring:
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS}

# Elasticsearch (if using AWS OpenSearch)
spring:
  elasticsearch:
    uris: ${ELASTICSEARCH_ENDPOINT:http://localhost:9200}
```

### Engagement Service (`engagement-service.yml`)

```yaml
spring:
  datasource:
    url: jdbc:postgresql://${RDS_ENGAGEMENT_SERVICE_ENDPOINT}:5432/engagement_service
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  
  data:
    redis:
      host: ${REDIS_ENGAGEMENT_SERVICE_ENDPOINT}
      port: 6379

spring:
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS}

services:
  content:
    url: http://content-service:8082
  user:
    url: http://user-service:8081
  gamification:
    url: http://gamification-service:8085
```

### Gamification Service (`gamification-service.yml`)

```yaml
spring:
  datasource:
    url: jdbc:postgresql://${RDS_GAMIFICATION_SERVICE_ENDPOINT}:5432/gamification_service
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  
  data:
    redis:
      host: ${REDIS_GAMIFICATION_SERVICE_ENDPOINT}
      port: 6379

spring:
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS}
```

### Analytics Service (`analytics-service.yml`)

```yaml
spring:
  datasource:
    url: jdbc:postgresql://${RDS_ANALYTICS_SERVICE_ENDPOINT}:5432/analytics_service
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  
  data:
    redis:
      host: ${REDIS_ANALYTICS_SERVICE_ENDPOINT}
      port: 6379

services:
  content:
    url: http://content-service:8082
  user:
    url: http://user-service:8081
  engagement:
    url: http://engagement-service:8084
  gamification:
    url: http://gamification-service:8085
```

## 🔐 Environment Variables

For sensitive values (passwords, keys), use environment variables or AWS Secrets Manager:

### Option 1: Environment Variables (Kubernetes Secrets)

```yaml
# In Kubernetes Deployment
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: database-secrets
        key: password
  - name: REDIS_PASSWORD
    valueFrom:
      secretKeyRef:
        name: redis-secrets
        key: password
```

### Option 2: AWS Secrets Manager (Recommended for Production)

```yaml
spring:
  cloud:
    aws:
      secretsmanager:
        enabled: true
        region: ${AWS_REGION:ap-southeast-1}
```

## 📊 Configuration Mapping

| Service | RDS Instance | Redis Cluster | Kafka | S3 | Notes |
|---------|-------------|---------------|-------|----|----|
| **user-service** | `rds_user_service` | `redis_user_service` | ✅ | ❌ | Auth, user management |
| **content-service** | `rds_content_service` | `redis_content_service` | ✅ | ✅ | Novel, chapter, file storage |
| **engagement-service** | `rds_engagement_service` | `redis_engagement_service` | ✅ | ❌ | Comments, reviews, votes |
| **gamification-service** | `rds_gamification_service` | `redis_gamification_service` | ✅ | ❌ | XP, Yuan, achievements |
| **analytics-service** | `rds_analytics_service` | `redis_analytics_service` | ❌ | ❌ | Analytics, rankings |

## 🚀 Quick Start Script

Create a script to extract endpoints from Terraform outputs:

```bash
#!/bin/bash
# extract-endpoints.sh

cd terraform
terraform output -json > ../configs/terraform-outputs.json

# Extract RDS endpoints
echo "RDS Endpoints:"
terraform output rds_user_service_endpoint
terraform output rds_content_service_endpoint
terraform output rds_engagement_service_endpoint
terraform output rds_gamification_service_endpoint
terraform output rds_analytics_service_endpoint

# Extract Redis endpoints
echo "Redis Endpoints:"
terraform output elasticache_user_service_endpoint
terraform output elasticache_content_service_endpoint
terraform output elasticache_engagement_service_endpoint
terraform output elasticache_gamification_service_endpoint
terraform output elasticache_analytics_service_endpoint

# Extract Kafka endpoints
echo "Kafka Endpoints:"
terraform output kafka_bootstrap_servers

# Extract S3 bucket
echo "S3 Bucket:"
terraform output s3_content_storage_bucket_name

# Extract ECR URLs
echo "ECR Repository URLs:"
terraform output ecr_repository_urls
```

## ✅ Checklist

- [ ] Get Terraform outputs (RDS, Redis, Kafka, S3, ECR endpoints)
- [ ] Clone `yushan-microservices-config-data` repository
- [ ] Update `user-service.yml` with AWS endpoints
- [ ] Update `content-service.yml` with AWS endpoints
- [ ] Update `engagement-service.yml` with AWS endpoints
- [ ] Update `gamification-service.yml` with AWS endpoints
- [ ] Update `analytics-service.yml` with AWS endpoints
- [ ] Replace Eureka configs with Kubernetes Service Discovery
- [ ] Update OpenFeign URLs to use Kubernetes service names
- [ ] Set up environment variables/secrets for passwords
- [ ] Commit and push changes to config repo
- [ ] Verify Config Server fetches new configs
- [ ] Restart services to apply new configurations

## 📚 References

- [Terraform Outputs](./terraform/README.md#outputs)
- [Config Server Repository](https://github.com/phutruonnttn/yushan-microservices-config-data)
- [AWS Architecture Guide](./AWS_ARCHITECTURE.md)

