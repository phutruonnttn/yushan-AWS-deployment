#!/bin/bash

# Yushan Platform - Service URLs Listing Script

set -e

echo "=========================================="
echo "Yushan Platform - Service URLs"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE="yushan"

# Get all LoadBalancer services
echo -e "${BLUE}📋 LoadBalancer Services:${NC}"
echo "----------------------------------------"

kubectl get svc -n "$NAMESPACE" -o json | jq -r '.items[] | select(.spec.type == "LoadBalancer") | "\(.metadata.name)\t\(.status.loadBalancer.ingress[0].hostname // "pending")\t\(.spec.ports[0].port)"' | while IFS=$'\t' read -r name hostname port; do
    if [ "$hostname" != "pending" ] && [ -n "$hostname" ]; then
        echo -e "${GREEN}✓${NC} $name"
        echo "   URL: http://$hostname:$port"
        
        # Swagger UI URL for microservices
        case "$name" in
            "user-service")
                echo "   Swagger: http://$hostname:$port/swagger-ui.html"
                ;;
            "content-service")
                echo "   Swagger: http://$hostname:$port/swagger-ui.html"
                ;;
            "engagement-service")
                echo "   Swagger: http://$hostname:$port/swagger-ui.html"
                ;;
            "gamification-service")
                echo "   Swagger: http://$hostname:$port/swagger-ui.html"
                ;;
            "analytics-service")
                echo "   Swagger: http://$hostname:$port/swagger-ui.html"
                ;;
            "api-gateway")
                echo "   Gateway: http://$hostname:$port"
                echo "   Health: http://$hostname:$port/actuator/health"
                ;;
        esac
        echo ""
    else
        echo -e "${YELLOW}⚠${NC} $name: LoadBalancer address pending..."
        echo ""
    fi
done

echo "=========================================="
echo -e "${BLUE}📝 Summary:${NC}"
echo "=========================================="
echo ""
echo "API Gateway (Entry Point):"
kubectl get svc -n "$NAMESPACE" api-gateway -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}:{.spec.ports[0].port}' 2>/dev/null || echo "Pending..."
echo ""
echo ""
echo "Microservices Swagger UIs:"
for service in user-service content-service engagement-service gamification-service analytics-service; do
    URL=$(kubectl get svc -n "$NAMESPACE" "$service" -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}:{.spec.ports[0].port}/swagger-ui.html' 2>/dev/null)
    if [ -n "$URL" ] && [ "$URL" != "http://:8081/swagger-ui.html" ]; then
        echo "  - $service: $URL"
    else
        echo "  - $service: Pending..."
    fi
done
echo ""
echo "=========================================="
echo -e "${YELLOW}ℹ️  Note:${NC} Eureka Registry Server is not deployed (using Kubernetes Service Discovery)"
echo "=========================================="

