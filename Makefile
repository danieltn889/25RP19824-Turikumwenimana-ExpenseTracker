.PHONY: help setup destroy logs health-check deploy-k8s lint test build push clean

PROJECT_ID=25RP19824-Turikumwenimana
DOCKER_USER=danieltn889

help:
	@echo "=========================================="
	@echo "$(PROJECT_ID) - Expense Tracker DevOps"
	@echo "=========================================="
	@echo "Available commands:"
	@echo "  make setup          - Set up and start all services"
	@echo "  make destroy        - Stop and remove all services"
	@echo "  make logs           - View service logs"
	@echo "  make health-check   - Check service health"
	@echo "  make deploy-k8s     - Deploy to Kubernetes"
	@echo "  make lint           - Run code linting"
	@echo "  make test           - Run tests"
	@echo "  make build          - Build Docker images"
	@echo "  make push           - Push images to Docker Hub"
	@echo "  make clean          - Clean up build artifacts"
	@echo "=========================================="

setup:
	@bash scripts/setup.sh

destroy:
	@bash scripts/destroy.sh

logs:
	@bash scripts/logs.sh all

health-check:
	@bash scripts/health-check.sh

deploy-k8s:
	@bash scripts/deploy-k8s.sh

lint:
	@echo "Linting API..."
	@cd api-service && npm run lint || true

test:
	@echo "Running tests..."
	@cd api-service && npm test || true

build:
	@echo "Building Docker images..."
	docker-compose build

push:
	@echo "Pushing images to Docker Hub..."
	docker push $(DOCKER_USER)/$(PROJECT_ID)-api:latest
	docker push $(DOCKER_USER)/$(PROJECT_ID)-frontend:latest

clean:
	@echo "Cleaning up..."
	@rm -rf api-service/node_modules
	@rm -rf api-service/coverage
	@rm -rf terraform/.terraform
	@rm -rf logs/*
	@echo "Clean complete"
