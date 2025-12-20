#!/bin/bash

set -e

PROJECT_ID="25RP19824-Turikumwenimana"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==========================================${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    local deployment_type=$1

    case $deployment_type in
        "docker")
            if ! command -v docker &> /dev/null; then
                print_error "Docker is not installed"
                exit 1
            fi
            if ! command -v docker-compose &> /dev/null; then
                print_error "Docker Compose is not installed"
                exit 1
            fi
            ;;
        "kubernetes")
            if ! command -v kubectl &> /dev/null; then
                print_error "kubectl is not installed"
                exit 1
            fi
            ;;
        "terraform")
            if ! command -v terraform &> /dev/null; then
                print_error "Terraform is not installed"
                exit 1
            fi
            ;;
        "ansible")
            if ! command -v ansible-playbook &> /dev/null; then
                print_error "Ansible is not installed"
                exit 1
            fi
            ;;
    esac
}

# Function to deploy with Docker Compose
deploy_docker() {
    print_header "Docker Compose Deployment"

    cd "$PROJECT_ROOT"

    print_status "Building Docker images..."
    docker-compose build

    print_status "Starting services..."
    docker-compose up -d

    print_status "Waiting for services to be ready..."
    sleep 10

    print_status "Running health checks..."
    if curl -s http://localhost:3000/health > /dev/null; then
        print_status "✅ API is healthy"
    else
        print_error "❌ API health check failed"
        exit 1
    fi

    if curl -s http://localhost/health > /dev/null; then
        print_status "✅ Frontend is healthy"
    else
        print_error "❌ Frontend health check failed"
        exit 1
    fi

    print_status "Deployment completed successfully!"
    docker-compose ps
}

# Function to deploy with Kubernetes
deploy_kubernetes() {
    print_header "Kubernetes Deployment"

    cd "$PROJECT_ROOT"

    local namespace="25rp19824-turikumwenimana"

    print_status "Creating namespace..."
    kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -

    print_status "Applying secrets..."
    kubectl apply -f kubernetes/secrets.yaml

    print_status "Deploying database..."
    kubectl apply -f kubernetes/database-statefulset.yaml
    kubectl wait --for=condition=ready pod -l app=25rp19824-turikumwenimana-db -n $namespace --timeout=300s

    print_status "Deploying API..."
    kubectl apply -f kubernetes/api-deployment.yaml
    kubectl wait --for=condition=available --timeout=300s deployment/25rp19824-turikumwenimana-api -n $namespace

    print_status "Deploying frontend..."
    kubectl apply -f kubernetes/frontend-deployment.yaml
    kubectl wait --for=condition=available --timeout=300s deployment/25rp19824-turikumwenimana-frontend -n $namespace

    print_status "Applying HorizontalPodAutoscalers..."
    kubectl apply -f kubernetes/hpa.yaml

    print_status "Applying ingress..."
    kubectl apply -f kubernetes/ingress.yaml

    print_status "Deployment completed successfully!"
    kubectl get all -n $namespace
}

# Function to deploy with Terraform
deploy_terraform() {
    print_header "Terraform Deployment"

    cd "$PROJECT_ROOT/terraform"

    print_status "Initializing Terraform..."
    terraform init

    print_status "Planning deployment..."
    terraform plan -out=tfplan

    print_status "Applying configuration..."
    terraform apply tfplan

    print_status "Deployment outputs:"
    terraform output

    print_status "Terraform deployment completed successfully!"
}

# Function to deploy with Ansible
deploy_ansible() {
    print_header "Ansible Deployment"

    cd "$PROJECT_ROOT/ansible"

    print_status "Running Ansible playbook..."
    ansible-playbook -i inventory.ini deploy.yml

    print_status "Ansible deployment completed successfully!"
}

# Function to rollback deployment
rollback_deployment() {
    local deployment_type=$1

    print_header "Rollback Deployment"

    case $deployment_type in
        "docker")
            cd "$PROJECT_ROOT"
            print_warning "Rolling back Docker Compose deployment..."
            docker-compose down
            # Restore from backup if available
            print_status "Checking for backup..."
            # Implementation would depend on backup strategy
            ;;
        "kubernetes")
            print_warning "Rolling back Kubernetes deployment..."
            bash "$SCRIPT_DIR/rollback-k8s.sh" all
            ;;
        "terraform")
            cd "$PROJECT_ROOT/terraform"
            print_warning "Destroying Terraform deployment..."
            terraform destroy -auto-approve
            ;;
        *)
            print_error "Unsupported deployment type for rollback: $deployment_type"
            exit 1
            ;;
    esac

    print_status "Rollback completed!"
}

# Function to scale services
scale_services() {
    local deployment_type=$1
    local service=$2
    local replicas=$3

    print_header "Scaling Services"

    case $deployment_type in
        "docker")
            cd "$PROJECT_ROOT"
            print_status "Scaling $service to $replicas replicas..."
            docker-compose up -d --scale $service=$replicas
            ;;
        "kubernetes")
            local namespace="25rp19824-turikumwenimana"
            print_status "Scaling $service to $replicas replicas..."
            kubectl scale deployment 25rp19824-turikumwenimana-$service --replicas=$replicas -n $namespace
            ;;
        *)
            print_error "Scaling not supported for deployment type: $deployment_type"
            exit 1
            ;;
    esac

    print_status "Scaling completed!"
}

# Function to show status
show_status() {
    local deployment_type=$1

    print_header "Deployment Status"

    case $deployment_type in
        "docker")
            cd "$PROJECT_ROOT"
            docker-compose ps
            echo ""
            docker stats --no-stream
            ;;
        "kubernetes")
            local namespace="25rp19824-turikumwenimana"
            kubectl get all -n $namespace
            echo ""
            kubectl top pods -n $namespace 2>/dev/null || echo "Metrics server not available"
            ;;
        "terraform")
            cd "$PROJECT_ROOT/terraform"
            terraform output
            ;;
    esac
}

# Function to run health checks
run_health_checks() {
    print_header "Health Checks"

    print_status "Checking API health..."
    if curl -s http://localhost:3000/health | jq . 2>/dev/null; then
        print_status "✅ API is healthy"
    else
        print_error "❌ API is not responding"
    fi

    print_status "Checking frontend health..."
    if curl -s http://localhost/health 2>/dev/null | grep -q "healthy\|ok"; then
        print_status "✅ Frontend is healthy"
    else
        print_error "❌ Frontend is not responding"
    fi

    print_status "Checking database..."
    if docker exec 25rp19824-turikumwenimana-db pg_isready -U expenseuser >/dev/null 2>&1; then
        print_status "✅ Database is ready"
    else
        print_error "❌ Database is not responding"
    fi
}

# Main script logic
usage() {
    echo "Usage: $0 <deployment_type> <action> [options]"
    echo ""
    echo "Deployment Types:"
    echo "  docker      - Docker Compose deployment"
    echo "  kubernetes  - Kubernetes deployment"
    echo "  terraform   - Terraform deployment"
    echo "  ansible     - Ansible deployment"
    echo ""
    echo "Actions:"
    echo "  deploy      - Deploy the application"
    echo "  rollback    - Rollback the deployment"
    echo "  scale       - Scale services (requires: <service> <replicas>)"
    echo "  status      - Show deployment status"
    echo "  health      - Run health checks"
    echo ""
    echo "Examples:"
    echo "  $0 docker deploy"
    echo "  $0 kubernetes rollback"
    echo "  $0 kubernetes scale api 5"
    echo "  $0 docker status"
    echo "  $0 docker health"
}

# Parse arguments
if [ $# -lt 2 ]; then
    usage
    exit 1
fi

DEPLOYMENT_TYPE=$1
ACTION=$2
shift 2

case $DEPLOYMENT_TYPE in
    docker|kubernetes|terraform|ansible)
        check_prerequisites $DEPLOYMENT_TYPE
        ;;
    *)
        print_error "Invalid deployment type: $DEPLOYMENT_TYPE"
        usage
        exit 1
        ;;
esac

case $ACTION in
    deploy)
        case $DEPLOYMENT_TYPE in
            docker) deploy_docker ;;
            kubernetes) deploy_kubernetes ;;
            terraform) deploy_terraform ;;
            ansible) deploy_ansible ;;
        esac
        ;;
    rollback)
        rollback_deployment $DEPLOYMENT_TYPE
        ;;
    scale)
        if [ $# -ne 2 ]; then
            print_error "Scale action requires service and replicas arguments"
            echo "Usage: $0 $DEPLOYMENT_TYPE scale <service> <replicas>"
            exit 1
        fi
        scale_services $DEPLOYMENT_TYPE $1 $2
        ;;
    status)
        show_status $DEPLOYMENT_TYPE
        ;;
    health)
        run_health_checks
        ;;
    *)
        print_error "Invalid action: $ACTION"
        usage
        exit 1
        ;;
esac

print_status "Operation completed successfully!"