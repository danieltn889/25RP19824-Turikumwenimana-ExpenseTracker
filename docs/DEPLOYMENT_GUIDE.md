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
# Scale API service
docker-compose up -d --scale api=5

# Scale using deployment script
./scripts/deploy.sh docker scale api 5
```

### Kubernetes Scale
```bash
# Manual scaling
kubectl scale deployment 25rp19824-turikumwenimana-api --replicas=5 -n 25rp19824-turikumwenimana

# Using deployment script
./scripts/deploy.sh kubernetes scale api 5

# Enable HorizontalPodAutoscaler (automatic scaling)
kubectl apply -f kubernetes/hpa.yaml

# Check HPA status
kubectl get hpa -n 25rp19824-turikumwenimana
```

### Scaling Guidelines
- **API Service**: 2-10 replicas (based on CPU/memory usage)
- **Frontend Service**: 2-8 replicas (lighter load)
- **Database**: Single replica with read replicas for high availability

---

## Rollback & Recovery

### Automated Rollback Scripts

#### Kubernetes Rollback
```bash
# Rollback all services
./scripts/rollback-k8s.sh all

# Rollback specific service
./scripts/rollback-k8s.sh api
./scripts/rollback-k8s.sh frontend
./scripts/rollback-k8s.sh database
```

#### Docker Compose Rollback
```bash
# Using deployment script
./scripts/deploy.sh docker rollback
```

#### Terraform Rollback
```bash
cd terraform
terraform destroy -auto-approve
```

### Manual Rollback Procedures

#### Kubernetes Manual Rollback
```bash
# Check deployment history
kubectl rollout history deployment/25rp19824-turikumwenimana-api -n 25rp19824-turikumwenimana

# Rollback to previous version
kubectl rollout undo deployment/25rp19824-turikumwenimana-api -n 25rp19824-turikumwenimana

# Rollback to specific revision
kubectl rollout undo deployment/25rp19824-turikumwenimana-api --to-revision=2 -n 25rp19824-turikumwenimana

# Check rollback status
kubectl rollout status deployment/25rp19824-turikumwenimana-api -n 25rp19824-turikumwenimana
```

#### Docker Compose Manual Rollback
```bash
# Stop current deployment
docker-compose down

# Restore from backup (if available)
cp docker-compose.backup.YYYYMMDD_HHMMSS docker-compose.yml
docker-compose up -d
```

### Recovery Procedures

#### Database Recovery
```bash
# Create backup
docker exec 25rp19824-turikumwenimana-db pg_dump -U expenseuser expensedb > backup.sql

# Restore from backup
cat backup.sql | docker exec -i 25rp19824-turikumwenimana-db psql -U expenseuser expensedb
```

#### Service Recovery
```bash
# Restart specific service
docker-compose restart api

# Restart all services
docker-compose restart

# Force recreation
docker-compose up -d --force-recreate
```

### Health Checks & Monitoring

#### Continuous Health Monitoring
```bash
# Run health checks
./scripts/health-check.sh

# Using deployment script
./scripts/deploy.sh docker health
./scripts/deploy.sh kubernetes health
```

#### Monitoring Commands
```bash
# Docker monitoring
docker stats
docker-compose logs -f

# Kubernetes monitoring
kubectl top pods -n 25rp19824-turikumwenimana
kubectl logs -f deployment/25rp19824-turikumwenimana-api -n 25rp19824-turikumwenimana
```

---

## Deployment Automation

### Using the Unified Deployment Script

The `scripts/deploy.sh` script provides a unified interface for all deployment methods:

```bash
# Docker Compose deployment
./scripts/deploy.sh docker deploy

# Kubernetes deployment
./scripts/deploy.sh kubernetes deploy

# Terraform deployment
./scripts/deploy.sh terraform deploy

# Ansible deployment
./scripts/deploy.sh ansible deploy

# Check status
./scripts/deploy.sh docker status
./scripts/deploy.sh kubernetes status

# Run health checks
./scripts/deploy.sh docker health

# Scale services
./scripts/deploy.sh kubernetes scale api 5

# Rollback
./scripts/deploy.sh kubernetes rollback
```

### CI/CD Integration

The deployment scripts are designed to work with CI/CD pipelines:

```yaml
# In GitHub Actions
- name: Deploy to Kubernetes
  run: |
    chmod +x scripts/deploy.sh
    ./scripts/deploy.sh kubernetes deploy

- name: Run Health Checks
  run: ./scripts/deploy.sh kubernetes health

- name: Rollback on Failure
  if: failure()
  run: ./scripts/deploy.sh kubernetes rollback
```

---

## High Availability & Disaster Recovery

### Multi-Environment Deployment
- **Development**: Docker Compose on local machine
- **Staging**: Kubernetes with HPA enabled
- **Production**: Kubernetes with full monitoring and backup

### Backup Strategy
1. **Database**: Daily automated backups using cron jobs
2. **Configuration**: Git version control for all manifests
3. **Images**: Docker Hub registry with multiple tags
4. **Data**: Persistent volumes with replication

### Disaster Recovery Plan
1. **Detection**: Automated health checks every 5 minutes
2. **Isolation**: Scale down affected services
3. **Recovery**: Automated rollback to last known good state
4. **Restoration**: Restore from backups if needed
5. **Verification**: Full health check before resuming traffic
