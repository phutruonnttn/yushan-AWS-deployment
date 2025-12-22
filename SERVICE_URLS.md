# Yushan Platform - Service URLs

## ✅ Deployment Status

**Current Status**: 
- ✅ Infrastructure deployed (EKS, RDS, ElastiCache, Kafka, S3, LoadBalancers)
- ✅ Security Groups configured - EKS nodes can connect to RDS, ElastiCache, and Kafka
- ✅ Docker images pushed to ECR
- ✅ **EKS Cluster: 2 nodes (t3.small) - 4GB total memory** ✅
- ✅ **All services running simultaneously** ✅
- ✅ **Elasticsearch deployed and running** ✅
- ✅ **Kafka: Installed, configured, and running** ✅
- ✅ **6/6 Swagger URLs accessible** ✅
- ✅ **All APIs working with Kafka enabled** ✅

**Fixed Issues:**
1. ✅ Security Groups - Added EKS node SG to RDS, ElastiCache, and Kafka
2. ✅ Config Server - Disabled for all services
3. ✅ Database connectivity - All services can connect to PostgreSQL
4. ✅ Redis connectivity - All services can connect to Redis
5. ✅ Kafka connectivity - Kafka installed, configured, and accessible from pods
6. ✅ Memory - Scaled up to 2 nodes (4GB total) to run all services

## API Gateway (Entry Point) ✅
- **Swagger UI**: http://af4552e3304b94afb928951c774ed03d-1972664349.ap-southeast-1.elb.amazonaws.com:8080/swagger-ui/index.html ✅ **ACCESSIBLE**
- **Health Check**: http://af4552e3304b94afb928951c774ed03d-1972664349.ap-southeast-1.elb.amazonaws.com:8080/actuator/health ✅ **UP**

## Microservices Swagger UIs

### User Service ✅
- **Swagger UI**: http://a4f91e763bb18457dacf36fde8d30abd-1999405995.ap-southeast-1.elb.amazonaws.com:8081/swagger-ui/index.html ✅ **ACCESSIBLE**
- **Health Check**: http://a4f91e763bb18457dacf36fde8d30abd-1999405995.ap-southeast-1.elb.amazonaws.com:8081/actuator/health ✅ **UP**
- **Service URL**: http://a4f91e763bb18457dacf36fde8d30abd-1999405995.ap-southeast-1.elb.amazonaws.com:8081
- **Port**: 8081
- **Status**: Running, Database/Redis/Mail/Kafka OK ✅
- **API Test**: Login API returns 200 ✅

### Content Service ✅
- **Swagger UI**: http://a86b04591fe714d98be369f90e876ebb-2140820585.ap-southeast-1.elb.amazonaws.com:8082/swagger-ui/index.html ✅ **ACCESSIBLE**
- **Service URL**: http://a86b04591fe714d98be369f90e876ebb-2140820585.ap-southeast-1.elb.amazonaws.com:8082
- **Port**: 8082
- **Status**: Running with Elasticsearch ✅

### Analytics Service ✅
- **Swagger UI**: http://a6da0990ea4ff456a84c2fa7551c1100-1501186405.ap-southeast-1.elb.amazonaws.com:8083/swagger-ui/index.html ✅ **ACCESSIBLE**
- **Service URL**: http://a6da0990ea4ff456a84c2fa7551c1100-1501186405.ap-southeast-1.elb.amazonaws.com:8083
- **Port**: 8083
- **Health Check**: ✅ **UP**

### Engagement Service ✅
- **Swagger UI**: http://ad89d7f9bd4ba4b15a1d861d9679ce92-677921056.ap-southeast-1.elb.amazonaws.com:8084/swagger-ui/index.html ✅ **ACCESSIBLE**
- **Service URL**: http://ad89d7f9bd4ba4b15a1d861d9679ce92-677921056.ap-southeast-1.elb.amazonaws.com:8084
- **Port**: 8084
- **Health Check**: ✅ **UP**

### Gamification Service ✅
- **Swagger UI**: http://a06e67a4e10624a089041277007ded1d-2088158062.ap-southeast-1.elb.amazonaws.com:8085/swagger-ui/index.html ✅ **ACCESSIBLE**
- **Service URL**: http://a06e67a4e10624a089041277007ded1d-2088158062.ap-southeast-1.elb.amazonaws.com:8085
- **Port**: 8085
- **Health Check**: ✅ **UP**

## Service Discovery

**Note**: Eureka Registry Server is **NOT** deployed. The platform uses **Kubernetes Service Discovery** instead.

Services can be accessed internally using Kubernetes service names:
- `api-gateway:8080`
- `user-service:8081`
- `content-service:8082`
- `analytics-service:8083`
- `engagement-service:8084`
- `gamification-service:8085`

## Kafka

**Status**: ✅ **Running and Accessible**
- **Broker 1**: 10.0.10.210:9092 ✅
- **Broker 2**: 10.0.11.92:9092
- **Broker 3**: 10.0.12.142:9092
- **Zookeeper**: Running on broker 1 (standalone mode)
- **Connectivity**: ✅ Accessible from EKS pods
- **Topics**: Auto-created when services publish events

## Elasticsearch

**Note**: Elasticsearch is deployed as a ClusterIP service (internal only) for Content Service search functionality.

- **Service Name**: `elasticsearch:9200` (internal access only)
- **Status**: Deployed in `yushan` namespace
- **Purpose**: Advanced search for novels and chapters

## Notes

- **Current Setup**: All services exposed via LoadBalancer (temporary for testing)
- **Cost**: ~$120/month for 6 LoadBalancers (not recommended for production)
- **Recommended**: Use ClusterIP for microservices, only API Gateway as LoadBalancer (~$20/month)
- **EKS Nodes**: 2x `t3.small` (2GB RAM each = 4GB total)
- All services use the `docker` Spring profile (same as Digital Ocean deployment)
- All services are configured with:
  - Database-per-Service pattern (RDS PostgreSQL)
  - Redis-per-Service pattern (ElastiCache)
  - Kafka for asynchronous communication ✅
  - JWT authentication
  - HMAC signature verification
  - Elasticsearch (Content Service only)
