# Yushan Platform - Service URLs

## ⚠️ Temporary Setup: All Services as LoadBalancer (for Testing)

**Note**: This is a temporary configuration for testing Swagger UI. For production, use ClusterIP for microservices and only expose API Gateway.

## API Gateway (Entry Point)
- **URL**: http://a4c055e21eba646c69817409b412985d-634843057.ap-southeast-1.elb.amazonaws.com:8080
- **Health Check**: http://a4c055e21eba646c69817409b412985d-634843057.ap-southeast-1.elb.amazonaws.com:8080/actuator/health

## Microservices Swagger UIs

### User Service
- **Swagger UI**: http://a8ebaf68be5c1423caf553596b6a80bb-847336720.ap-southeast-1.elb.amazonaws.com:8081/swagger-ui.html
- **Service URL**: http://a8ebaf68be5c1423caf553596b6a80bb-847336720.ap-southeast-1.elb.amazonaws.com:8081
- **Port**: 8081

### Content Service
- **Swagger UI**: http://a5058ff21dcb54299a99f7668be10627-1270522524.ap-southeast-1.elb.amazonaws.com:8082/swagger-ui.html
- **Service URL**: http://a5058ff21dcb54299a99f7668be10627-1270522524.ap-southeast-1.elb.amazonaws.com:8082
- **Port**: 8082

### Analytics Service
- **Swagger UI**: http://a2b3ebe66441c497d89f8e607326576c-674569631.ap-southeast-1.elb.amazonaws.com:8083/swagger-ui.html
- **Service URL**: http://a2b3ebe66441c497d89f8e607326576c-674569631.ap-southeast-1.elb.amazonaws.com:8083
- **Port**: 8083

### Engagement Service
- **Swagger UI**: http://aefebd16c2ebc4f6a9b7884503a8dbe8-28592454.ap-southeast-1.elb.amazonaws.com:8084/swagger-ui.html
- **Service URL**: http://aefebd16c2ebc4f6a9b7884503a8dbe8-28592454.ap-southeast-1.elb.amazonaws.com:8084
- **Port**: 8084

### Gamification Service
- **Swagger UI**: http://a58a5ef87869c4653be471bfab1596ac-1441127796.ap-southeast-1.elb.amazonaws.com:8085/swagger-ui.html
- **Service URL**: http://a58a5ef87869c4653be471bfab1596ac-1441127796.ap-southeast-1.elb.amazonaws.com:8085
- **Port**: 8085

## Service Discovery

**Note**: Eureka Registry Server is **NOT** deployed. The platform uses **Kubernetes Service Discovery** instead.

Services can be accessed internally using Kubernetes service names:
- `api-gateway:8080`
- `user-service:8081`
- `content-service:8082`
- `analytics-service:8083`
- `engagement-service:8084`
- `gamification-service:8085`

## Quick Access Script

To list all service URLs, run:
```bash
./scripts/list-service-urls.sh
```

## Elasticsearch

**Note**: Elasticsearch is deployed as a ClusterIP service (internal only) for Content Service search functionality.

- **Service Name**: `elasticsearch:9200` (internal access only)
- **Status**: Deployed in `yushan` namespace
- **Purpose**: Advanced search for novels and chapters

## Notes

- **Current Setup**: All services exposed via LoadBalancer (temporary for testing)
- **Cost**: ~$120/month for 6 LoadBalancers (not recommended for production)
- **Recommended**: Use ClusterIP for microservices, only API Gateway as LoadBalancer (~$20/month)
- **EKS Nodes**: Default `t3.small` (2GB RAM) - can be upgraded to `t3.medium` (4GB RAM) if needed for Elasticsearch and all services
- All services use the `docker` Spring profile (same as Digital Ocean deployment)
- All services are configured with:
  - Database-per-Service pattern (RDS PostgreSQL)
  - Redis-per-Service pattern (ElastiCache)
  - Kafka for asynchronous communication
  - JWT authentication
  - HMAC signature verification
  - Elasticsearch (Content Service only)
