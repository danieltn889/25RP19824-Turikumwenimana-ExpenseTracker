#!/bin/bash

set -e

PROJECT_ID="25RP19824-Turikumwenimana"
NAMESPACE="25rp19824-turikumwenimana"

echo "=========================================="
echo "Rollback Script for $PROJECT_ID"
echo "=========================================="

# Function to rollback deployment
rollback_deployment() {
    local deployment_name=$1
    local target_version=${2:-"previous"}

    echo "Rolling back $deployment_name to $target_version..."

    if [ "$target_version" = "previous" ]; then
        # Rollback to previous revision
        kubectl rollout undo deployment/$deployment_name -n $NAMESPACE
    else
        # Rollback to specific revision
        kubectl rollout undo deployment/$deployment_name --to-revision=$target_version -n $NAMESPACE
    fi

    # Wait for rollout to complete
    kubectl rollout status deployment/$deployment_name -n $NAMESPACE --timeout=300s

    echo "✓ $deployment_name rolled back successfully"
}

# Function to check deployment health after rollback
check_deployment_health() {
    local deployment_name=$1

    echo "Checking health of $deployment_name after rollback..."

    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app=$deployment_name -n $NAMESPACE --timeout=300s

    # Check if deployment is available
    if kubectl get deployment $deployment_name -n $NAMESPACE | grep -q "1/1"; then
        echo "✓ $deployment_name is healthy"
        return 0
    else
        echo "✗ $deployment_name failed health check"
        return 1
    fi
}

# Function to rollback database (more complex due to statefulset)
rollback_database() {
    echo "Rolling back database statefulset..."

    # For database, we need to be more careful
    # Get current image
    current_image=$(kubectl get statefulset 25rp19824-turikumwenimana-db -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}')

    echo "Current database image: $current_image"

    # Scale down API and frontend first to prevent connections during rollback
    echo "Scaling down dependent services..."
    kubectl scale deployment 25rp19824-turikumwenimana-api --replicas=0 -n $NAMESPACE
    kubectl scale deployment 25rp19824-turikumwenimana-frontend --replicas=0 -n $NAMESPACE

    # Delete current statefulset pods to force recreation
    kubectl delete pod -l app=25rp19824-turikumwenimana-db -n $NAMESPACE

    # Wait for database to be ready
    kubectl wait --for=condition=ready pod -l app=25rp19824-turikumwenimana-db -n $NAMESPACE --timeout=300s

    # Scale services back up
    kubectl scale deployment 25rp19824-turikumwenimana-api --replicas=3 -n $NAMESPACE
    kubectl scale deployment 25rp19824-turikumwenimana-frontend --replicas=2 -n $NAMESPACE

    echo "✓ Database rollback completed"
}

# Main rollback logic
case "${1:-all}" in
    "api")
        echo "Rolling back API deployment..."
        rollback_deployment "25rp19824-turikumwenimana-api"
        check_deployment_health "25rp19824-turikumwenimana-api"
        ;;
    "frontend")
        echo "Rolling back Frontend deployment..."
        rollback_deployment "25rp19824-turikumwenimana-frontend"
        check_deployment_health "25rp19824-turikumwenimana-frontend"
        ;;
    "database")
        rollback_database
        ;;
    "all")
        echo "Performing full rollback..."

        # Rollback in reverse order: frontend -> api -> database
        rollback_deployment "25rp19824-turikumwenimana-frontend"
        check_deployment_health "25rp19824-turikumwenimana-frontend"

        rollback_deployment "25rp19824-turikumwenimana-api"
        check_deployment_health "25rp19824-turikumwenimana-api"

        rollback_database
        ;;
    *)
        echo "Usage: $0 [api|frontend|database|all]"
        echo "  api      - Rollback API deployment only"
        echo "  frontend - Rollback frontend deployment only"
        echo "  database - Rollback database statefulset"
        echo "  all      - Rollback all services (default)"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "✓ Rollback completed successfully!"
echo "=========================================="

# Display current status
echo "Current deployment status:"
kubectl get all -n $NAMESPACE