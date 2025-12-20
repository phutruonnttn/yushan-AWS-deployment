# Kubernetes Service Types: LoadBalancer vs ClusterIP

## Differences

### 1. **ClusterIP** (Default)
- **Access**: Only accessible from **within the Kubernetes cluster**
- **IP**: Only has internal IP (ClusterIP), no public IP
- **Cost**: **Free** (does not create AWS resources)
- **Use Case**: 
  - Internal communication between services
  - Services that don't need internet exposure
  - Access via API Gateway or Ingress

**Example:**
```yaml
spec:
  type: ClusterIP  # Default, can be omitted
  ports:
  - port: 8081
```

### 2. **LoadBalancer**
- **Access**: Accessible from **internet** (public IP)
- **IP**: AWS automatically creates **Elastic Load Balancer (ELB)** with public IP
- **Cost**: **~$16-20/month per LoadBalancer** (not free tier)
- **Use Case**:
  - Services that need direct internet exposure
  - Entry point (API Gateway)
  - Development/Debug (direct Swagger UI access)

**Example:**
```yaml
spec:
  type: LoadBalancer
  ports:
  - port: 8081
```

## Best Practice for Yushan Platform

### ✅ **Recommended Architecture:**

```
Internet
   ↓
[API Gateway] ← LoadBalancer (only one needs public access)
   ↓
[User Service] ← ClusterIP (internal only)
[Content Service] ← ClusterIP (internal only)
[Analytics Service] ← ClusterIP (internal only)
[Engagement Service] ← ClusterIP (internal only)
[Gamification Service] ← ClusterIP (internal only)
```

**Reasons:**
1. **Cost**: 1 LoadBalancer instead of 6 → Save ~$100/month
2. **Security**: Only API Gateway exposed to internet, other services protected
3. **Architecture**: Aligns with microservices pattern (single entry point)
4. **Swagger UI**: Can access via API Gateway routes or port-forward when needed

### ❌ **Current Setup (Not Recommended):**
- 6 LoadBalancers → ~$120/month just for LoadBalancers
- All services exposed to internet → Security risk
- Not aligned with microservices best practice

## Recommendation

**Only API Gateway uses LoadBalancer**, all microservices use ClusterIP:

```yaml
# API Gateway - LoadBalancer (public access)
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
spec:
  type: LoadBalancer  # ✅ Public access
  ports:
  - port: 8080

---
# User Service - ClusterIP (internal only)
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  type: ClusterIP  # ✅ Internal only
  ports:
  - port: 8081
```

## Access Swagger UI

### Option 1: Via API Gateway (Recommended)
- API Gateway route: `/api/v1/user/actuator/swagger-ui.html`
- Or: `/api/v1/content/actuator/swagger-ui.html`

### Option 2: Port Forward (Development/Debug)
```bash
kubectl port-forward -n yushan svc/user-service 8081:8081
# Access: http://localhost:8081/swagger-ui.html
```

### Option 3: LoadBalancer (Current - Not Recommended)
- Expensive, security risk
- Only use when truly need direct access from internet

## Cost Comparison

| Setup | LoadBalancers | Monthly Cost |
|-------|--------------|--------------|
| Current (All LoadBalancer) | 6 | ~$120 |
| Recommended (Only Gateway) | 1 | ~$20 |
| **Savings** | | **~$100/month** |

## Migration Plan

1. ✅ Keep API Gateway as LoadBalancer
2. ✅ Change all microservices to ClusterIP
3. ✅ Access Swagger UI via API Gateway routes or port-forward
4. ✅ Save ~$100/month
