# Deployment Guide - 25RP19824-Turikumwenimana

## Table of Contents
1. [Docker Compose Deployment](#docker-compose-deployment)
2. [Kubernetes Deployment](#kubernetes-deployment)
3. [Terraform Deployment](#terraform-deployment)
4. [Post-Deployment Verification](#post-deployment-verification)

---

## Docker Compose Deployment

### Prerequisites
- Docker installed and running
- Docker Compose version 2.0+
- Minimum 2GB RAM available

### Step 1: Clone Repository
```bash
cd 25RP19824-Turikumwenimana-Project
```

### Step 2: Configure Environment
```bash
# .env file is pre-configured
cat .env
```

### Step 3: Build Images
```bash
docker-compose build
```

### Step 4: Start Services
```bash
docker-compose up -d
```

### Step 5: Verify Deployment
```bash
# Check all services
docker-compose ps

# Check logs
docker-compose logs -f

# Health check
curl http://localhost:3000/health
```

### Services Access
- **API**: http://localhost:3000
- **Frontend**: http://localhost
- **Database**: localhost:5432

---

## Kubernetes Deployment

### Prerequisites
- kubectl installed and configured
- Kubernetes cluster (minikube/EKS/AKS/GKE)
- Minimum 4GB RAM cluster

### Step 1: Create Namespace
```bash
kubectl create namespace 25rp19824-turikumwenimana
```

### Step 2: Apply Secrets
```bash
kubectl apply -f kubernetes/secrets.yaml
```

### Step 3: Deploy Database
```bash
kubectl apply -f kubernetes/database-statefulset.yaml
kubectl wait --for=condition=ready pod -l app=25rp19824-turikumwenimana-db -n 25rp19824-turikumwenimana --timeout=300s
```

### Step 4: Deploy API
```bash
kubectl apply -f kubernetes/api-deployment.yaml
kubectl wait --for=condition=available --timeout=300s deployment/25rp19824-turikumwenimana-api -n 25rp19824-turikumwenimana
```

### Step 5: Deploy Frontend
```bash
kubectl apply -f kubernetes/frontend-deployment.yaml
kubectl wait --for=condition=available --timeout=300s deployment/25rp19824-turikumwenimana-frontend -n 25rp19824-turikumwenimana
```

### Step 6: Apply Ingress
```bash
kubectl apply -f kubernetes/ingress.yaml
```

### Verify Deployment
```bash
# View all resources
kubectl get all -n 25rp19824-turikumwenimana

# View pods
kubectl get pods -n 25rp19824-turikumwenimana -w

# View services
kubectl get svc -n 25rp19824-turikumwenimana

# Check pod logs
kubectl logs -f deployment/25rp19824-turikumwenimana-api -n 25rp19824-turikumwenimana
```

---

## Terraform Deployment

### Prerequisites
- Terraform 1.0+
- Docker daemon running

### Step 1: Initialize Terraform
```bash
cd terraform
terraform init
```

### Step 2: Plan Deployment
```bash
terraform plan -out=tfplan
```

### Step 3: Apply Configuration
```bash
terraform apply tfplan
```

### Step 4: Get Outputs
```bash
terraform output
```

### Destroy Infrastructure
```bash
terraform destroy
```

---

## Post-Deployment Verification

### Health Checks

```bash
# API health
curl -s http://localhost:3000/health | jq

# Frontend health
curl -s http://localhost/health

# Database connection
psql -h localhost -U expenseuser -d expensedb -c "SELECT COUNT(*) FROM expenses;"
```

### Functional Testing

```bash
# Create expense
curl -X POST http://localhost:3000/api/v1/expenses \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Test expense",
    "amount": 100,
    "category": "Food"
  }'

# Get all expenses
curl http://localhost:3000/api/v1/expenses

# Get summary
curl http://localhost:3000/api/v1/summary
```

### Performance Testing

```bash
# Using Apache Bench
ab -n 100 -c 10 http://localhost:3000/health

# Using wrk
wrk -t12 -c400 -d30s http://localhost:3000/health
```

---

## Troubleshooting

### Services not starting
```bash
# Check logs
docker-compose logs api
docker-compose logs db

# Restart services
docker-compose restart
```

### Database connection issues
```bash
# Test database connection
docker exec 25rp19824-turikumwenimana-db psql -U expenseuser -d expensedb -c "SELECT 1"

# Check database logs
docker-compose logs db
```

### Frontend not loading
```bash
# Check nginx configuration
docker exec 25rp19824-turikumwenimana-frontend cat /etc/nginx/conf.d/default.conf

# Check frontend logs
docker-compose logs frontend
```

---

## Monitoring

### Docker Stats
```bash
docker stats 25rp19824-turikumwenimana-api
```

### Kubernetes Metrics
```bash
kubectl top pods -n 25rp19824-turikumwenimana
kubectl top nodes
```

---

## Scaling

### Docker Compose Scale
```bash
docker-compose up -d --scale api=3
```

### Kubernetes Scale
```bash
kubectl scale deployment 25rp19824-turikumwenimana-api --replicas=5 -n 25rp19824-turikumwenimana
```

---

## Backup & Recovery

### Database Backup
```bash
docker exec 25rp19824-turikumwenimana-db pg_dump -U expenseuser expensedb > backup.sql
```

### Database Restore
```bash
cat backup.sql | docker exec -i 25rp19824-turikumwenimana-db psql -U expenseuser expensedb
```

---

## Performance Optimization

1. Enable resource limits (already configured)
2. Use read replicas for database
3. Enable caching on frontend
4. Use CDN for static files
5. Monitor and scale based on metrics
