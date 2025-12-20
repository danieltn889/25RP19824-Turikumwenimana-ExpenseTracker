# 25RP19824-Turikumwenimana - Expense Tracker DevOps Project

## Overview
Complete DevOps implementation of an **Expense Tracker** microservices application demonstrating the full DevOps lifecycle from infrastructure to production monitoring.

**Project ID:** `25RP19824-Turikumwenimana`  
**Docker Username:** `danieltn889`

---

## Architecture

### Microservices
- **API Service** (Node.js/Express) - RESTful backend on port 3000
- **Frontend Service** (React/Nginx) - Web UI on port 80
- **Database Service** (PostgreSQL) - Data persistence on port 5432

### Technology Stack
| Component | Technology |
|-----------|-----------|
| Backend | Node.js 18, Express.js |
| Frontend | React, Nginx |
| Database | PostgreSQL 15 |
| Containerization | Docker & Docker Compose |
| Orchestration | Kubernetes |
| CI/CD | GitHub Actions |
| IaC | Terraform, Ansible |
| Monitoring | Prometheus, Grafana |

---

## Project Structure

```
25RP19824-Turikumwenimana-Project/
├── api-service/              # Backend API
│   ├── src/
│   │   ├── index.js
│   │   └── tests/
│   ├── Dockerfile
│   └── package.json
├── frontend-service/         # Frontend UI
│   ├── public/
│   │   └── index.html
│   ├── nginx.conf
│   ├── Dockerfile
│   └── package.json
├── kubernetes/              # Kubernetes manifests
│   ├── namespace.yaml
│   ├── secrets.yaml
│   ├── database-statefulset.yaml
│   ├── api-deployment.yaml
│   ├── frontend-deployment.yaml
│   └── ingress.yaml
├── terraform/               # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── ansible/                 # Configuration management
│   ├── inventory.ini
│   └── deploy.yml
├── monitoring/              # Prometheus & Alerts
│   ├── prometheus.yml
│   └── alerts.yml
├── scripts/                 # Helper scripts
│   ├── setup.sh
│   ├── deploy-k8s.sh
│   ├── destroy.sh
│   ├── health-check.sh
│   └── logs.sh
├── .github/workflows/       # CI/CD Pipeline
│   └── ci-cd.yml
├── docker-compose.yml       # Local development
├── init-db.sql             # Database initialization
├── Makefile                # Quick commands
├── .env                    # Environment variables
├── .gitignore
└── README.md
```

---

## Quick Start

### Prerequisites
- Docker & Docker Compose
- kubectl (for Kubernetes deployment)
- Terraform (optional, for IaC)
- Ansible (optional, for automation)

### Local Development with Docker Compose

```bash
# 1. Clone and navigate to project
cd 25RP19824-Turikumwenimana-Project

# 2. Setup and start services
make setup

# 3. Access services
API:      http://localhost:3000
Frontend: http://localhost
Database: localhost:5432
```

### Verify Services

```bash
# Check health status
make health-check

# View logs
make logs

# View container status
docker-compose ps
```

---

## DevOps Stages Implemented

### 1. Infrastructure Setup
- ✅ VM-based infrastructure (Docker)
- ✅ Network configuration (Bridge network)
- ✅ Persistent storage (Volumes)

### 2. Version Control & Git Workflow
- ✅ Git repository structure
- ✅ Branch strategy (main, develop)
- ✅ Commit conventions
- ✅ .gitignore configuration

### 3. Continuous Integration
- ✅ GitHub Actions pipeline
- ✅ Automated testing
- ✅ Security scanning (Trivy)
- ✅ Linting & code quality

### 4. Containerization
- ✅ Multi-stage Docker builds
- ✅ Image optimization
- ✅ Health checks
- ✅ Security best practices

Images:
- `danieltn889/25rp19824-turikumwenimana-api:latest`
- `danieltn889/25rp19824-turikumwenimana-frontend:latest`

### 5. Deployment & Orchestration
- ✅ Kubernetes manifests
- ✅ Namespace: `25rp19824-turikumwenimana`
- ✅ StatefulSet for database
- ✅ Deployments with replicas
- ✅ Services & Ingress
- ✅ Resource limits & requests
- ✅ Health probes (liveness/readiness)

### 6. Automation & Configuration
- ✅ Terraform infrastructure code
- ✅ Ansible playbooks
- ✅ Docker Compose orchestration
- ✅ Environment management
- ✅ Secrets management

### 7. Monitoring & Reliability
- ✅ Prometheus metrics collection
- ✅ Alert rules configuration
- ✅ Container health checks
- ✅ Logging (Docker logs)
- ✅ Pod disruption budgets
- ✅ Rolling updates strategy

---

## API Endpoints

```
GET    /health              - Health check
GET    /api/v1/expenses     - List all expenses
POST   /api/v1/expenses     - Create expense
GET    /api/v1/expenses/:id - Get expense by ID
PUT    /api/v1/expenses/:id - Update expense
DELETE /api/v1/expenses/:id - Delete expense
GET    /api/v1/summary      - Get summary statistics
```

---

## Deployment

### Option 1: Docker Compose (Recommended for Local)

```bash
make setup
```

### Option 2: Kubernetes

```bash
# Create namespace and deploy
make deploy-k8s

# Check status
kubectl get all -n 25rp19824-turikumwenimana

# Port forward to access
kubectl port-forward svc/25rp19824-turikumwenimana-frontend 80:80 -n 25rp19824-turikumwenimana
```

### Option 3: Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Option 4: Ansible

```bash
cd ansible
ansible-playbook -i inventory.ini deploy.yml
```

---

## CI/CD Pipeline

GitHub Actions workflow triggers on:
- Push to `main` branch
- Pull requests to `main`/`develop`

### Pipeline Stages
1. **Lint & Test** - Code quality checks
2. **Build API** - Docker image build & push
3. **Build Frontend** - Docker image build & push
4. **Security Scan** - Trivy vulnerability scanning

---

## Monitoring

### Prometheus
```bash
# Start Prometheus
docker run -d -p 9090:9090 -v $(pwd)/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
```

### Grafana
```bash
# Start Grafana
docker run -d -p 3001:3000 grafana/grafana
```

---

## Common Commands

```bash
# View all available commands
make help

# Setup services
make setup

# Check health
make health-check

# View logs (specify: api, frontend, db, all)
make logs

# Lint code
make lint

# Run tests
make test

# Build images
make build

# Push to Docker Hub
make push

# Destroy everything
make destroy

# Clean build artifacts
make clean
```

---

## Environment Variables

See `.env` file:
```
PROJECT_ID=25RP19824-Turikumwenimana
DOCKER_USERNAME=danieltn889
DB_USER=expenseuser
DB_PASSWORD=expensepass123
DB_NAME=expensedb
DB_HOST=db
API_PORT=3000
FRONTEND_PORT=80
```

---

## Troubleshooting

### API not connecting to database
```bash
# Check database status
docker-compose logs db

# Restart database
docker-compose restart db
```

### Frontend not connecting to API
- Ensure API is running: `curl http://localhost:3000/health`
- Check nginx configuration: `frontend-service/nginx.conf`
- Verify network connectivity: `docker network ls`

### Port conflicts
```bash
# Find process using port
lsof -i :3000  # for API
lsof -i :80    # for Frontend
lsof -i :5432  # for Database
```

---

## Security Considerations

✅ Environment variables for sensitive data  
✅ Secret management in Kubernetes  
✅ Network policies  
✅ Health checks & probes  
✅ Resource limits  
✅ Security scanning (Trivy)  
✅ Helmet.js for API security  
✅ Rate limiting  

---

## Performance

- **API Response Time**: <100ms (local)
- **Database**: PostgreSQL with indexes
- **Frontend**: Nginx serving static files
- **Scalability**: Replicated services in Kubernetes

---

## Documentation

- `docs/TECHNICAL_REPORT.md` - Detailed implementation report
- `docs/ARCHITECTURE.md` - System architecture
- `docs/DEPLOYMENT.md` - Deployment guide
- `docs/TROUBLESHOOTING.md` - Common issues

---

## Author

**Student ID:** 25RP19824  
**Name:** Turikumwenimana  
**Docker Username:** danieltn889  
**Submission Date:** December 2025

---

## License

Educational Project - All Rights Reserved

---

## Support

For issues or questions, refer to the troubleshooting section or technical report.
