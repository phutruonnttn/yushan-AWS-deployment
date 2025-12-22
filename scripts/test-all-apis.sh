#!/bin/bash
# Script to test all API endpoints from Swagger UI
# Usage: ./scripts/test-all-apis.sh

set -e

echo "=========================================="
echo "Test All API Endpoints"
echo "=========================================="
echo ""

# Get service URLs
USER_URL="http://a4f91e763bb18457dacf36fde8d30abd-1999405995.ap-southeast-1.elb.amazonaws.com:8081"
API_GW_URL=$(kubectl get svc api-gateway -n yushan -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
CONTENT_URL=$(kubectl get svc content-service -n yushan -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
ENGAGE_URL=$(kubectl get svc engagement-service -n yushan -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
GAMIFY_URL=$(kubectl get svc gamification-service -n yushan -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
ANALYTICS_URL=$(kubectl get svc analytics-service -n yushan -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

# Test function
test_endpoint() {
    local name=$1
    local url=$2
    local method=${3:-GET}
    local data=${4:-""}
    
    echo ""
    echo "Testing: $name"
    echo "URL: $url"
    
    if [[ -z "$url" ]]; then
        echo "❌ Service URL not available"
        return 1
    fi
    
    if [[ "$method" == "POST" ]] && [[ -n "$data" ]]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$url" \
            -H 'Content-Type: application/json' \
            -d "$data" \
            --max-time 10 2>&1)
    else
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$url" --max-time 10 2>&1)
    fi
    
    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d: -f2)
    body=$(echo "$response" | sed '/HTTP_CODE/d')
    
    if [[ "$http_code" == "200" ]] || [[ "$http_code" == "201" ]]; then
        echo "✅ Status: $http_code"
        echo "Response: $(echo "$body" | head -c 200)..."
        return 0
    else
        echo "❌ Status: $http_code"
        echo "Response: $(echo "$body" | head -c 200)..."
        return 1
    fi
}

# Test User Service
echo "=========================================="
echo "1. USER SERVICE"
echo "=========================================="
test_endpoint "Login API" "$USER_URL/api/v1/auth/login" "POST" '{"email": "admin@yushan.com", "password": "admin"}'
test_endpoint "Health Check" "$USER_URL/actuator/health"

# Test API Gateway
if [[ -n "$API_GW_URL" ]]; then
    echo ""
    echo "=========================================="
    echo "2. API GATEWAY"
    echo "=========================================="
    test_endpoint "Health Check" "http://$API_GW_URL:8080/actuator/health"
fi

# Test Content Service
if [[ -n "$CONTENT_URL" ]]; then
    echo ""
    echo "=========================================="
    echo "3. CONTENT SERVICE"
    echo "=========================================="
    test_endpoint "Health Check" "http://$CONTENT_URL:8083/actuator/health"
fi

# Test Engagement Service
if [[ -n "$ENGAGE_URL" ]]; then
    echo ""
    echo "=========================================="
    echo "4. ENGAGEMENT SERVICE"
    echo "=========================================="
    test_endpoint "Health Check" "http://$ENGAGE_URL:8084/actuator/health"
fi

# Test Gamification Service
if [[ -n "$GAMIFY_URL" ]]; then
    echo ""
    echo "=========================================="
    echo "5. GAMIFICATION SERVICE"
    echo "=========================================="
    test_endpoint "Health Check" "http://$GAMIFY_URL:8085/actuator/health"
fi

# Test Analytics Service
if [[ -n "$ANALYTICS_URL" ]]; then
    echo ""
    echo "=========================================="
    echo "6. ANALYTICS SERVICE"
    echo "=========================================="
    test_endpoint "Health Check" "http://$ANALYTICS_URL:8086/actuator/health"
fi

echo ""
echo "=========================================="
echo "Test Complete!"
echo "=========================================="

