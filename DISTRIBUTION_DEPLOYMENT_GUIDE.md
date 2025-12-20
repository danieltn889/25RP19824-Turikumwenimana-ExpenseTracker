# DEVOPS PROJECT DISTRIBUTION & DEPLOYMENT GUIDE

**Student ID:** 25RP19824-Turikumwenimana  
**Project Name:** Expense Tracker Microservices  
**Date:** December 20, 2025

---

## TABLE OF CONTENTS

1. [Project Structure](#project-structure)
2. [Component Overview](#component-overview)
3. [Local Development Setup](#local-development-setup)
4. [Docker Deployment](#docker-deployment)
5. [Kubernetes Deployment](#kubernetes-deployment)
6. [CI/CD Pipeline Deployment](#cicd-pipeline-deployment)
7. [Terraform IaC Deployment](#terraform-iac-deployment)
8. [Ansible Configuration Management](#ansible-configuration-management)
9. [Monitoring & Observability](#monitoring--observability)
10. [Production Deployment](#production-deployment)

---

## PROJECT STRUCTURE

```
25RP19824-Turikumwenimana-Project/
├── api-service/                          # Node.js REST API
│   ├── Dockerfile
│   ├── package.json
│   └── src/
│       ├── index.js                      # Main API server
│       ├── auth.js                       # Authentication module
│       ├── db.js                         # Database connection
│       ├── logger.js                     # Logging
│       └── server.js                     # Server config
│
├── frontend-service/                     # Nginx + HTML/CSS/JS UI
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   └── public/
│       ├── index.html                    # React UI
│       └── styles.css
│
├── docker-compose.yml                    # Local development
├── docker-compose-monitoring.yml         # Monitoring stack
│
├── kubernetes/                           # K8s manifests
│   ├── namespace.yaml
│   ├── api-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── database-statefulset.yaml
│   ├── ingress.yaml
│   └── secrets.yaml
│
├── terraform/                            # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── ansible/                              # Configuration management
│   ├── deploy.yml
│   └── inventory.ini
│
├── monitoring/                           # Prometheus & Grafana
│   ├── prometheus.yml
│   ├── alerts.yml
│   └── alertmanager.yml
│
├── scripts/                              # Automation scripts
│   ├── setup.sh
│   ├── deploy-k8s.sh
│   ├── docker-compose-test.sh
│   └── health-check.sh
│
├── .github/workflows/                    # GitHub Actions CI/CD
│   ├── ci-cd.yml
│   └── branch-workflow.yml
│
├── init-db.sql                           # Database initialization
├── README.md                             # Project overview
└── TECHNICAL_REPORT_FINAL.md             # Full documentation
```

---

## COMPONENT OVERVIEW

### 1. **API Service** (Node.js + Express.js)
- **Purpose:** RESTful backend for expense tracking
- **Port:** 3000
- **Database:** PostgreSQL
- **Authentication:** JWT + Bcrypt
- **Features:**
  - User registration & login
  - Expense CRUD operations
  - User profile management
  - Admin endpoints
  - Metrics endpoint for Prometheus

**Key Endpoints:**
```
POST   /api/v1/auth/register          # User registration
POST   /api/v1/auth/login             # User login
GET    /api/v1/expenses               # List expenses
POST   /api/v1/expenses               # Add expense
DELETE /api/v1/expenses/:id           # Delete expense
GET    /api/v1/users/profile          # User profile
GET    /metrics                        # Prometheus metrics
```

### 2. **Frontend Service** (Nginx + HTML/CSS/JS)
- **Purpose:** Web UI for expense tracking
- **Port:** 80
- **Features:**
  - Login/Signup modal
  - Dashboard with expense list
  - Add/Delete expenses
  - Real-time summary
  - Responsive design (mobile & desktop)

### 3. **Database** (PostgreSQL 15)
- **Purpose:** Data persistence
- **Port:** 5432
- **Persistence:** Docker volume
- **Tables:**
  - `users` - User accounts
  - `expenses` - Expense records

### 4. **Monitoring Stack**
- **Prometheus (Port 9090):** Metrics collection
- **Grafana (Port 3001):** Visualization & dashboards
- **AlertManager (Port 9093):** Alert routing

---

## LOCAL DEVELOPMENT SETUP

### Prerequisites

```bash
# Install required tools
Docker Desktop v29.1.2+
Docker Compose v5.0.0+
Git
Node.js 18+ (optional, for local development)
PostgreSQL 15+ (optional, for local dev DB)
```

### Step 1: Clone Repository

```bash
git clone https://github.com/danieltn889/25RP19824-Turikumwenimana-ExpenseTracker.git
cd 25RP19824-Turikumwenimana-ExpenseTracker
```

### Step 2: Configure Environment

```bash
# Create .env file
cat > .env << EOF
# API Configuration
API_PORT=3000
API_HOST=0.0.0.0
NODE_ENV=development

# Database Configuration
DB_HOST=db
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres123
DB_NAME=expensetracker

# JWT Configuration
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRY=24h

# Frontend Configuration
FRONTEND_PORT=80
REACT_APP_API_URL=http://localhost:3000/api/v1
EOF
```

### Step 3: Start Services

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Check service status
docker compose ps
```

### Step 4: Access Services

```
Frontend:  http://localhost
API:       http://localhost:3000
Database:  localhost:5432
```

### Step 5: Test Application

```bash
# Login test
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'

# Add expense test
TOKEN="your-jwt-token"
curl -X POST http://localhost:3000/api/v1/expenses \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"description":"Lunch","amount":15.50,"category":"Food"}'
```

---

## DOCKER DEPLOYMENT

### Build Docker Images

```bash
# Build API image
docker build -t 25rp19824-turikumwenimana-api:latest ./api-service

# Build Frontend image
docker build -t 25rp19824-turikumwenimana-frontend:latest ./frontend-service

# Tag for Docker Hub
docker tag 25rp19824-turikumwenimana-api:latest danieltn889/25rp19824-turikumwenimana-api:latest
docker tag 25rp19824-turikumwenimana-frontend:latest danieltn889/25rp19824-turikumwenimana-frontend:latest
```

### Push to Docker Hub

```bash
# Login to Docker Hub
docker login -u danieltn889

# Push images
docker push danieltn889/25rp19824-turikumwenimana-api:latest
docker push danieltn889/25rp19824-turikumwenimana-frontend:latest
```

### Run with Docker Compose

```bash
# Production deployment
docker compose -f docker-compose.yml up -d

# With monitoring
docker compose -f docker-compose-monitoring.yml up -d

# Scale services
docker compose up -d --scale api=3

# Stop services
docker compose down

# Cleanup
docker compose down -v
```

---

## KUBERNETES DEPLOYMENT

### Prerequisites

```bash
# Install Kubernetes cluster (minikube, EKS, GKE, etc.)
# Install kubectl CLI

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

### Deploy to Kubernetes

```bash
# 1. Create namespace
kubectl apply -f kubernetes/namespace.yaml

# 2. Create secrets
kubectl apply -f kubernetes/secrets.yaml

# 3. Deploy database
kubectl apply -f kubernetes/database-statefulset.yaml

# 4. Deploy API
kubectl apply -f kubernetes/api-deployment.yaml

# 5. Deploy Frontend
kubectl apply -f kubernetes/frontend-deployment.yaml

# 6. Setup Ingress
kubectl apply -f kubernetes/ingress.yaml

# Verify deployments
kubectl get deployments -n 25rp19824-turikumwenimana
kubectl get pods -n 25rp19824-turikumwenimana
kubectl get svc -n 25rp19824-turikumwenimana

# Access services
kubectl port-forward -n 25rp19824-turikumwenimana svc/api 3000:3000
kubectl port-forward -n 25rp19824-turikumwenimana svc/frontend 8080:80
```

### Kubernetes Manifests

**Namespace:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: 25rp19824-turikumwenimana
```

**API Deployment (Replicas=2):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: 25rp19824-turikumwenimana
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: api
        image: danieltn889/25rp19824-turikumwenimana-api:latest
        ports:
        - containerPort: 3000
        livenessProbe:
          httpGet:
            path: /api/v1/health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
```

---

## CI/CD PIPELINE DEPLOYMENT

### GitHub Actions Workflow

**File:** `.github/workflows/ci-cd.yml`

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, developer, backup ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build Docker images
        run: |
          docker build -t api:latest ./api-service
          docker build -t frontend:latest ./frontend-service
      
      - name: Run tests
        run: |
          docker compose -f docker-compose.yml up -d
          sleep 10
          npm test
      
      - name: Push to Docker Hub
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push api:latest
          docker push frontend:latest
```

### Setup GitHub Secrets

```bash
# In GitHub repository settings:
1. Go to Settings → Secrets and variables → Actions
2. Add DOCKER_USERNAME = danieltn889
3. Add DOCKER_PASSWORD = dckr_pat_***
```

### Branch Workflow

```
Developer Branch (Testing)
    ↓
    └→ Run tests, build images
    
Backup Branch (Staging)
    ↓
    └→ Integration tests
    
Main Branch (Production)
    ↓
    └→ Build with versioning, push to Docker Hub
```

---

## TERRAFORM IaC DEPLOYMENT

### Terraform Configuration

**File:** `terraform/main.tf`

```hcl
# Configure cloud provider (AWS, Azure, GCP, etc.)
provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "25rp19824-turikumwenimana-vpc"
  }
}

# Create ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "25rp19824-turikumwenimana-cluster"
}

# Deploy services to ECS
resource "aws_ecs_service" "api" {
  name            = "api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2
}
```

### Deploy Infrastructure

```bash
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan

# Verify
terraform output

# Destroy (cleanup)
terraform destroy
```

---

## ANSIBLE CONFIGURATION MANAGEMENT

### Ansible Playbook

**File:** `ansible/deploy.yml`

```yaml
---
- name: Deploy 25RP19824-Turikumwenimana Project
  hosts: all
  tasks:
    - name: Install Docker
      apt:
        name: docker.io
        state: present
    
    - name: Start Docker service
      systemd:
        name: docker
        state: started
    
    - name: Clone repository
      git:
        repo: https://github.com/danieltn889/25RP19824-Turikumwenimana-ExpenseTracker.git
        dest: /opt/project
    
    - name: Deploy with Docker Compose
      docker_compose:
        project_src: /opt/project
        state: present
    
    - name: Verify services
      uri:
        url: http://localhost:3000/api/v1/health
        status_code: 200
```

### Run Ansible Playbook

```bash
# Configure inventory
cat > ansible/inventory.ini << EOF
[webservers]
server1 ansible_host=192.168.1.100 ansible_user=ubuntu
server2 ansible_host=192.168.1.101 ansible_user=ubuntu
EOF

# Run playbook
ansible-playbook -i ansible/inventory.ini ansible/deploy.yml

# Verify deployment
ansible all -i ansible/inventory.ini -m command -a "docker ps"
```

---

## MONITORING & OBSERVABILITY

### Start Monitoring Stack

```bash
# Deploy monitoring services
docker compose -f docker-compose-monitoring.yml up -d

# Access dashboards
Prometheus:   http://localhost:9090
Grafana:      http://localhost:3001 (admin/admin123)
AlertManager: http://localhost:9093
```

### Configure Grafana Dashboards

```bash
# 1. Login to Grafana
# URL: http://localhost:3001
# Username: admin
# Password: admin123

# 2. Add Prometheus data source
# Configuration → Data Sources → Add Prometheus
# URL: http://prometheus:9090

# 3. Import dashboards
# Dashboards → Import → Upload JSON
# ID: 3662 (Docker & Host), 1860 (Node Exporter)

# 4. Create custom dashboards
# Dashboards → Create → Add Panel
# Metrics: up, rate(http_requests_total[5m]), etc.
```

### Alert Configuration

**File:** `monitoring/alerts.yml`

```yaml
groups:
  - name: api_alerts
    interval: 30s
    rules:
      - alert: APIDown
        expr: up{job="api-service"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "API service is down"
      
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
```

---

## PRODUCTION DEPLOYMENT

### Pre-Deployment Checklist

- [ ] Code reviewed and tested
- [ ] Docker images built and pushed
- [ ] Kubernetes manifests validated
- [ ] Terraform plan reviewed
- [ ] Ansible playbooks tested
- [ ] Monitoring configured
- [ ] Backups configured
- [ ] Security scanning completed
- [ ] Performance tested
- [ ] Documentation updated

### Deployment Steps

```bash
# 1. Build and tag images with version
VERSION=$(date +%Y.%m.%d)-$(git rev-parse --short HEAD)
docker build -t danieltn889/api:$VERSION ./api-service
docker build -t danieltn889/frontend:$VERSION ./frontend-service

# 2. Push to registry
docker push danieltn889/api:$VERSION
docker push danieltn889/frontend:$VERSION

# 3. Update Kubernetes manifests
sed -i "s/latest/$VERSION/g" kubernetes/*.yaml

# 4. Deploy to production
kubectl apply -f kubernetes/

# 5. Verify deployment
kubectl rollout status deployment/api -n 25rp19824-turikumwenimana
kubectl rollout status deployment/frontend -n 25rp19824-turikumwenimana

# 6. Run smoke tests
./scripts/health-check.sh

# 7. Monitor
kubectl logs -f deployment/api -n 25rp19824-turikumwenimana
```

### Rollback Procedure

```bash
# If issues occur, rollback to previous version
kubectl rollout undo deployment/api -n 25rp19824-turikumwenimana
kubectl rollout undo deployment/frontend -n 25rp19824-turikumwenimana

# Verify rollback
kubectl rollout status deployment/api -n 25rp19824-turikumwenimana
```

---

## SCALING & PERFORMANCE

### Horizontal Scaling

```bash
# Docker Compose
docker compose up -d --scale api=5

# Kubernetes
kubectl scale deployment api --replicas=5 -n 25rp19824-turikumwenimana

# Verify
kubectl get pods -n 25rp19824-turikumwenimana
```

### Load Testing

```bash
# Using Apache Bench
ab -n 1000 -c 10 http://localhost/

# Using Apache JMeter
jmeter -n -t test-plan.jmx -l results.jtl

# Using Locust (Python)
locust -f locustfile.py --host=http://localhost
```

---

## TROUBLESHOOTING

### Common Issues

**1. Services won't start:**
```bash
docker compose logs -f api
docker compose logs -f db
```

**2. Metrics not appearing in Prometheus:**
```bash
# Check if /metrics endpoint is responding
curl http://localhost:3000/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
```

**3. Kubernetes pod crashes:**
```bash
kubectl describe pod <pod-name> -n 25rp19824-turikumwenimana
kubectl logs <pod-name> -n 25rp19824-turikumwenimana
```

**4. Database connection issues:**
```bash
# Check DB is running
docker compose ps db

# Check connection
psql -h localhost -U postgres -d expensetracker -c "SELECT 1;"
```

---

## BACKUP & DISASTER RECOVERY

### Backup Database

```bash
# Docker backup
docker compose exec db pg_dump -U postgres expensetracker > backup.sql

# Kubernetes backup
kubectl exec -n 25rp19824-turikumwenimana pod/db-0 -- \
  pg_dump -U postgres expensetracker > backup.sql

# Restore
psql -h localhost -U postgres -d expensetracker < backup.sql
```

### Backup Configurations

```bash
# Backup all configurations
tar -czf backup-configs.tar.gz \
  kubernetes/ \
  terraform/ \
  ansible/ \
  monitoring/

# Restore
tar -xzf backup-configs.tar.gz
```

---

## SECURITY CONSIDERATIONS

### SSL/TLS Configuration

```yaml
# Add to kubernetes/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: api
            port:
              number: 3000
```

### Secrets Management

```bash
# Create secrets
kubectl create secret generic db-credentials \
  --from-literal=username=postgres \
  --from-literal=password=secure-password \
  -n 25rp19824-turikumwenimana
```

---

## RESOURCES & LIMITS

### Docker Compose Resource Limits

```yaml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### Kubernetes Resource Requests

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

---

## SUMMARY

This distribution guide covers all deployment methods:

1. **Local Development** - Docker Compose
2. **Containerization** - Docker images to Docker Hub
3. **Orchestration** - Kubernetes manifests
4. **IaC** - Terraform for cloud infrastructure
5. **Configuration** - Ansible for automation
6. **CI/CD** - GitHub Actions pipeline
7. **Monitoring** - Prometheus, Grafana, AlertManager
8. **Production** - Multi-stage deployment with rollback

**Your project is ready for deployment in any environment!**

---

**Student ID:** 25RP19824-Turikumwenimana  
**Date:** December 20, 2025
