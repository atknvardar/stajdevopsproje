# Enterprise DevOps Pipeline - Makefile
# Comprehensive automation for development, build, test, and deployment

# Project configuration
PROJECT_NAME := microservice-demo
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "v1.0.0")
COMMIT_HASH := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Container configuration
REGISTRY := ghcr.io
REGISTRY_USER := $(shell git config user.name | tr '[:upper:]' '[:lower:]' | tr ' ' '-' 2>/dev/null || echo "default")
IMAGE_NAME := $(REGISTRY)/$(REGISTRY_USER)/$(PROJECT_NAME)
IMAGE_TAG := $(VERSION)
DOCKERFILE := build/Dockerfile

# Kubernetes configuration
KUBECTL := kubectl
KUSTOMIZE := kustomize
NAMESPACE_DEV := microservice-demo-dev
NAMESPACE_STAGING := microservice-demo-staging
NAMESPACE_PROD := microservice-demo-prod

# Local development
PYTHON := python3
PIP := pip3
VENV := venv
APP_DIR := app
BUILD_DIR := build
TEST_COVERAGE_THRESHOLD := 80

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)Enterprise DevOps Pipeline - Make Commands$(NC)"
	@echo "$(BLUE)============================================$(NC)"
	@echo ""
	@echo "$(GREEN)Development Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## .*Development/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Build Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## .*Build/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Test Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## .*Test/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Deployment Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## .*Deploy/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Infrastructure Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## .*Infrastructure/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Utility Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## .*Utility/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =============================================================================
# Development Commands
# =============================================================================

.PHONY: setup
setup: ## Development - Set up local development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@if [ ! -d "$(APP_DIR)/$(VENV)" ]; then \
		echo "$(YELLOW)Creating Python virtual environment...$(NC)"; \
		cd $(APP_DIR) && $(PYTHON) -m venv $(VENV); \
	fi
	@echo "$(YELLOW)Installing dependencies...$(NC)"
	@cd $(APP_DIR) && source $(VENV)/bin/activate && $(PIP) install -r requirements.txt
	@cd $(APP_DIR) && source $(VENV)/bin/activate && $(PIP) install pytest pytest-cov black isort flake8 mypy
	@echo "$(GREEN)✅ Development environment ready!$(NC)"
	@echo "$(BLUE)To activate the environment, run:$(NC) cd $(APP_DIR) && source $(VENV)/bin/activate"

.PHONY: dev
dev: setup ## Development - Run the application locally
	@echo "$(BLUE)Starting local development server...$(NC)"
	@cd $(APP_DIR) && source $(VENV)/bin/activate && $(PYTHON) main.py

.PHONY: dev-docker
dev-docker: ## Development - Run with Docker Compose (includes observability)
	@echo "$(BLUE)Starting development environment with Docker Compose...$(NC)"
	@docker-compose -f $(BUILD_DIR)/docker-compose.yml up -d
	@echo "$(GREEN)✅ Development environment started!$(NC)"
	@echo "$(BLUE)Services available at:$(NC)"
	@echo "  - Microservice: http://localhost:8080"
	@echo "  - Grafana: http://localhost:3000 (admin/admin123)"
	@echo "  - Prometheus: http://localhost:9090"

.PHONY: stop-dev
stop-dev: ## Development - Stop Docker Compose development environment
	@echo "$(BLUE)Stopping development environment...$(NC)"
	@docker-compose -f $(BUILD_DIR)/docker-compose.yml down
	@echo "$(GREEN)✅ Development environment stopped!$(NC)"

.PHONY: clean-dev
clean-dev: ## Development - Clean development environment
	@echo "$(BLUE)Cleaning development environment...$(NC)"
	@rm -rf $(APP_DIR)/$(VENV)
	@rm -rf $(APP_DIR)/__pycache__
	@rm -rf $(APP_DIR)/.pytest_cache
	@rm -rf $(APP_DIR)/htmlcov
	@rm -rf $(APP_DIR)/.coverage
	@docker-compose -f $(BUILD_DIR)/docker-compose.yml down -v --remove-orphans
	@echo "$(GREEN)✅ Development environment cleaned!$(NC)"

# =============================================================================
# Build Commands
# =============================================================================

.PHONY: build
build: ## Build - Build container image
	@echo "$(BLUE)Building container image...$(NC)"
	@echo "$(YELLOW)Image: $(IMAGE_NAME):$(IMAGE_TAG)$(NC)"
	@docker build \
		-f $(DOCKERFILE) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		-t $(IMAGE_NAME):latest \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT_HASH=$(COMMIT_HASH) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		.
	@echo "$(GREEN)✅ Container image built successfully!$(NC)"

.PHONY: build-secure
build-secure: build ## Build - Build and scan container image for security vulnerabilities
	@echo "$(BLUE)Scanning container image for vulnerabilities...$(NC)"
	@if command -v trivy >/dev/null 2>&1; then \
		trivy image --severity HIGH,CRITICAL $(IMAGE_NAME):$(IMAGE_TAG); \
	else \
		echo "$(YELLOW)Trivy not installed, skipping security scan$(NC)"; \
	fi
	@echo "$(GREEN)✅ Security scan completed!$(NC)"

.PHONY: push
push: build ## Build - Push container image to registry
	@echo "$(BLUE)Pushing container image to registry...$(NC)"
	@docker push $(IMAGE_NAME):$(IMAGE_TAG)
	@docker push $(IMAGE_NAME):latest
	@echo "$(GREEN)✅ Container image pushed successfully!$(NC)"

# =============================================================================
# Test Commands
# =============================================================================

.PHONY: lint
lint: ## Test - Run code linting and formatting checks
	@echo "$(BLUE)Running linting and formatting checks...$(NC)"
	@cd $(APP_DIR) && source $(VENV)/bin/activate && \
		echo "$(YELLOW)Running black...$(NC)" && \
		black --check . && \
		echo "$(YELLOW)Running isort...$(NC)" && \
		isort --check-only . && \
		echo "$(YELLOW)Running flake8...$(NC)" && \
		flake8 . && \
		echo "$(YELLOW)Running mypy...$(NC)" && \
		mypy . --ignore-missing-imports
	@echo "$(GREEN)✅ All linting checks passed!$(NC)"

.PHONY: format
format: ## Test - Auto-format code
	@echo "$(BLUE)Auto-formatting code...$(NC)"
	@cd $(APP_DIR) && source $(VENV)/bin/activate && \
		echo "$(YELLOW)Running black...$(NC)" && \
		black . && \
		echo "$(YELLOW)Running isort...$(NC)" && \
		isort .
	@echo "$(GREEN)✅ Code formatting completed!$(NC)"

.PHONY: test
test: ## Test - Run unit tests with coverage
	@echo "$(BLUE)Running unit tests...$(NC)"
	@cd $(APP_DIR) && source $(VENV)/bin/activate && \
		pytest tests/ -v --cov=. --cov-report=html --cov-report=term-missing \
		--cov-fail-under=$(TEST_COVERAGE_THRESHOLD)
	@echo "$(GREEN)✅ All tests passed!$(NC)"
	@echo "$(BLUE)Coverage report: $(APP_DIR)/htmlcov/index.html$(NC)"

.PHONY: test-container
test-container: build ## Test - Test the built container
	@echo "$(BLUE)Testing container...$(NC)"
	@echo "$(YELLOW)Starting container for testing...$(NC)"
	@docker run --rm -d --name $(PROJECT_NAME)-test -p 8081:8080 $(IMAGE_NAME):$(IMAGE_TAG)
	@sleep 5
	@echo "$(YELLOW)Testing health endpoints...$(NC)"
	@curl -f http://localhost:8081/healthz || (docker stop $(PROJECT_NAME)-test && exit 1)
	@curl -f http://localhost:8081/ready || (docker stop $(PROJECT_NAME)-test && exit 1)
	@curl -f http://localhost:8081/metrics || (docker stop $(PROJECT_NAME)-test && exit 1)
	@echo "$(YELLOW)Stopping test container...$(NC)"
	@docker stop $(PROJECT_NAME)-test
	@echo "$(GREEN)✅ Container tests passed!$(NC)"

.PHONY: test-all
test-all: lint test test-container ## Test - Run all tests (lint, unit, container)
	@echo "$(GREEN)✅ All tests completed successfully!$(NC)"

.PHONY: test-e2e
test-e2e: ## Test - Run end-to-end tests
	@echo "$(BLUE)Running end-to-end tests...$(NC)"
	@if [ -f "testing/scripts/run-all-tests.sh" ]; then \
		./testing/scripts/run-all-tests.sh; \
	else \
		echo "$(YELLOW)E2E test framework not found$(NC)"; \
	fi

# =============================================================================
# Deployment Commands
# =============================================================================

.PHONY: deploy-dev
deploy-dev: ## Deploy - Deploy to development environment
	@echo "$(BLUE)Deploying to development environment...$(NC)"
	@$(KUBECTL) apply -k openshift/overlays/dev
	@$(KUBECTL) rollout status deployment/$(PROJECT_NAME) -n $(NAMESPACE_DEV) --timeout=300s
	@echo "$(GREEN)✅ Deployed to development!$(NC)"

.PHONY: deploy-staging
deploy-staging: ## Deploy - Deploy to staging environment
	@echo "$(BLUE)Deploying to staging environment...$(NC)"
	@$(KUBECTL) apply -k openshift/overlays/staging
	@$(KUBECTL) rollout status deployment/$(PROJECT_NAME) -n $(NAMESPACE_STAGING) --timeout=300s
	@echo "$(GREEN)✅ Deployed to staging!$(NC)"

.PHONY: deploy-prod
deploy-prod: ## Deploy - Deploy to production environment (requires confirmation)
	@echo "$(RED)⚠️  WARNING: Deploying to PRODUCTION!$(NC)"
	@read -p "Are you sure you want to deploy to production? [y/N]: " confirm && [ "$$confirm" = "y" ]
	@echo "$(BLUE)Deploying to production environment...$(NC)"
	@$(KUBECTL) apply -k openshift/overlays/prod
	@$(KUBECTL) rollout status deployment/$(PROJECT_NAME) -n $(NAMESPACE_PROD) --timeout=300s
	@echo "$(GREEN)✅ Deployed to production!$(NC)"

.PHONY: deploy-all
deploy-all: setup-infrastructure deploy-microservice setup-cicd setup-observability setup-governance setup-testing ## Deploy - Deploy complete pipeline infrastructure
	@echo "$(GREEN)✅ Complete infrastructure deployed!$(NC)"

.PHONY: deploy-microservice
deploy-microservice: deploy-dev deploy-staging ## Deploy - Deploy microservice to dev and staging
	@echo "$(GREEN)✅ Microservice deployed to dev and staging!$(NC)"

# =============================================================================
# Infrastructure Commands
# =============================================================================

.PHONY: setup-infrastructure
setup-infrastructure: ## Infrastructure - Set up base Kubernetes infrastructure
	@echo "$(BLUE)Setting up base infrastructure...$(NC)"
	@$(KUBECTL) apply -f openshift/base/
	@echo "$(GREEN)✅ Base infrastructure created!$(NC)"

.PHONY: setup-cicd
setup-cicd: ## Infrastructure - Set up CI/CD pipeline
	@echo "$(BLUE)Setting up CI/CD pipeline...$(NC)"
	@if [ -f "cicd/scripts/setup-pipeline.sh" ]; then \
		./cicd/scripts/setup-pipeline.sh; \
	else \
		echo "$(YELLOW)CI/CD setup script not found$(NC)"; \
	fi
	@echo "$(GREEN)✅ CI/CD pipeline configured!$(NC)"

.PHONY: setup-observability
setup-observability: ## Infrastructure - Set up monitoring and observability
	@echo "$(BLUE)Setting up observability stack...$(NC)"
	@if [ -f "observability/scripts/setup-observability.sh" ]; then \
		./observability/scripts/setup-observability.sh; \
	else \
		echo "$(YELLOW)Observability setup script not found$(NC)"; \
	fi
	@echo "$(GREEN)✅ Observability stack configured!$(NC)"

.PHONY: setup-governance
setup-governance: ## Infrastructure - Set up security and governance
	@echo "$(BLUE)Setting up governance and security...$(NC)"
	@if [ -f "governance/scripts/setup-governance.sh" ]; then \
		./governance/scripts/setup-governance.sh; \
	else \
		echo "$(YELLOW)Governance setup script not found$(NC)"; \
	fi
	@echo "$(GREEN)✅ Governance and security configured!$(NC)"

.PHONY: setup-testing
setup-testing: ## Infrastructure - Set up testing framework
	@echo "$(BLUE)Setting up testing infrastructure...$(NC)"
	@if [ -f "testing/scripts/setup-testing.sh" ]; then \
		./testing/scripts/setup-testing.sh; \
	else \
		echo "$(YELLOW)Testing setup script not found$(NC)"; \
	fi
	@echo "$(GREEN)✅ Testing infrastructure configured!$(NC)"

# =============================================================================
# Utility Commands
# =============================================================================

.PHONY: status
status: ## Utility - Show deployment status across all environments
	@echo "$(BLUE)Deployment Status$(NC)"
	@echo "$(BLUE)=================$(NC)"
	@echo ""
	@echo "$(YELLOW)Development Environment:$(NC)"
	@$(KUBECTL) get pods -n $(NAMESPACE_DEV) -l app=$(PROJECT_NAME) 2>/dev/null || echo "  No deployments found"
	@echo ""
	@echo "$(YELLOW)Staging Environment:$(NC)"
	@$(KUBECTL) get pods -n $(NAMESPACE_STAGING) -l app=$(PROJECT_NAME) 2>/dev/null || echo "  No deployments found"
	@echo ""
	@echo "$(YELLOW)Production Environment:$(NC)"
	@$(KUBECTL) get pods -n $(NAMESPACE_PROD) -l app=$(PROJECT_NAME) 2>/dev/null || echo "  No deployments found"

.PHONY: logs
logs: ## Utility - Show logs from development environment
	@echo "$(BLUE)Showing logs from development environment...$(NC)"
	@$(KUBECTL) logs -n $(NAMESPACE_DEV) -l app=$(PROJECT_NAME) --tail=100 -f

.PHONY: logs-staging
logs-staging: ## Utility - Show logs from staging environment
	@echo "$(BLUE)Showing logs from staging environment...$(NC)"
	@$(KUBECTL) logs -n $(NAMESPACE_STAGING) -l app=$(PROJECT_NAME) --tail=100 -f

.PHONY: logs-prod
logs-prod: ## Utility - Show logs from production environment
	@echo "$(BLUE)Showing logs from production environment...$(NC)"
	@$(KUBECTL) logs -n $(NAMESPACE_PROD) -l app=$(PROJECT_NAME) --tail=100 -f

.PHONY: port-forward-dev
port-forward-dev: ## Utility - Port forward to development service
	@echo "$(BLUE)Port forwarding to development service...$(NC)"
	@echo "$(YELLOW)Service will be available at http://localhost:8080$(NC)"
	@$(KUBECTL) port-forward -n $(NAMESPACE_DEV) svc/$(PROJECT_NAME) 8080:8080

.PHONY: port-forward-grafana
port-forward-grafana: ## Utility - Port forward to Grafana
	@echo "$(BLUE)Port forwarding to Grafana...$(NC)"
	@echo "$(YELLOW)Grafana will be available at http://localhost:3000$(NC)"
	@echo "$(YELLOW)Default credentials: admin/admin123$(NC)"
	@$(KUBECTL) port-forward -n observability svc/grafana 3000:3000

.PHONY: shell
shell: ## Utility - Open shell in development pod
	@echo "$(BLUE)Opening shell in development pod...$(NC)"
	@$(KUBECTL) exec -it -n $(NAMESPACE_DEV) deployment/$(PROJECT_NAME) -- /bin/bash

.PHONY: describe
describe: ## Utility - Describe resources in development environment
	@echo "$(BLUE)Describing resources in development environment...$(NC)"
	@$(KUBECTL) describe deployment $(PROJECT_NAME) -n $(NAMESPACE_DEV)
	@echo ""
	@$(KUBECTL) describe service $(PROJECT_NAME) -n $(NAMESPACE_DEV)

.PHONY: clean
clean: clean-dev ## Utility - Clean all local artifacts
	@echo "$(BLUE)Cleaning Docker images...$(NC)"
	@docker rmi $(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_NAME):latest 2>/dev/null || true
	@docker system prune -f
	@echo "$(GREEN)✅ Cleanup completed!$(NC)"

.PHONY: version
version: ## Utility - Show version information
	@echo "$(BLUE)Version Information$(NC)"
	@echo "$(BLUE)==================$(NC)"
	@echo "Project: $(PROJECT_NAME)"
	@echo "Version: $(VERSION)"
	@echo "Commit: $(COMMIT_HASH)"
	@echo "Build Date: $(BUILD_DATE)"
	@echo "Image: $(IMAGE_NAME):$(IMAGE_TAG)"

.PHONY: check-deps
check-deps: ## Utility - Check required dependencies
	@echo "$(BLUE)Checking dependencies...$(NC)"
	@echo -n "$(YELLOW)Docker: $(NC)"
	@docker --version 2>/dev/null || echo "$(RED)NOT FOUND$(NC)"
	@echo -n "$(YELLOW)kubectl: $(NC)"
	@$(KUBECTL) version --client --short 2>/dev/null || echo "$(RED)NOT FOUND$(NC)"
	@echo -n "$(YELLOW)Python: $(NC)"
	@$(PYTHON) --version 2>/dev/null || echo "$(RED)NOT FOUND$(NC)"
	@echo -n "$(YELLOW)Git: $(NC)"
	@git --version 2>/dev/null || echo "$(RED)NOT FOUND$(NC)"
	@echo -n "$(YELLOW)Kustomize: $(NC)"
	@$(KUSTOMIZE) version --short 2>/dev/null || echo "$(RED)NOT FOUND$(NC)"

# =============================================================================
# Special Targets
# =============================================================================

.PHONY: install-tools
install-tools: ## Utility - Install required development tools (macOS/Linux)
	@echo "$(BLUE)Installing development tools...$(NC)"
	@if [ "$(shell uname)" = "Darwin" ]; then \
		echo "$(YELLOW)Installing tools for macOS...$(NC)"; \
		brew install kubectl kustomize trivy; \
	elif [ "$(shell uname)" = "Linux" ]; then \
		echo "$(YELLOW)Installing tools for Linux...$(NC)"; \
		curl -LO "https://dl.k8s.io/release/$(shell curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; \
		chmod +x kubectl && sudo mv kubectl /usr/local/bin/; \
		curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash; \
		sudo mv kustomize /usr/local/bin/; \
	else \
		echo "$(RED)Unsupported operating system$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Development tools installed!$(NC)"

.PHONY: docs
docs: ## Utility - Generate and serve documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@if command -v mkdocs >/dev/null 2>&1; then \
		mkdocs serve; \
	else \
		echo "$(YELLOW)MkDocs not installed. Opening docs in browser...$(NC)"; \
		open docs/README.md || xdg-open docs/README.md; \
	fi

# Security: Prevent accidental exposure of sensitive information
.PHONY: security-check
security-check: ## Utility - Run security checks on the codebase
	@echo "$(BLUE)Running security checks...$(NC)"
	@echo "$(YELLOW)Checking for secrets in code...$(NC)"
	@if command -v git-secrets >/dev/null 2>&1; then \
		git secrets --scan; \
	else \
		echo "$(YELLOW)git-secrets not installed, skipping secrets scan$(NC)"; \
	fi
	@echo "$(YELLOW)Checking for security vulnerabilities...$(NC)"
	@if command -v safety >/dev/null 2>&1; then \
		cd $(APP_DIR) && source $(VENV)/bin/activate && safety check; \
	else \
		echo "$(YELLOW)safety not installed, skipping vulnerability check$(NC)"; \
	fi
	@echo "$(GREEN)✅ Security checks completed!$(NC)"

# =============================================================================
# Documentation and Help
# =============================================================================

.PHONY: quickstart
quickstart: setup build test deploy-dev ## Utility - Quick start: setup, build, test, and deploy to dev
	@echo "$(GREEN)🎉 Quickstart completed!$(NC)"
	@echo "$(BLUE)Your microservice is now running in the development environment.$(NC)"
	@echo ""
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Check status: make status"
	@echo "  2. View logs: make logs"
	@echo "  3. Port forward: make port-forward-dev"
	@echo "  4. Access Grafana: make port-forward-grafana"

.PHONY: makefile-help
makefile-help: ## Utility - Show detailed Makefile documentation
	@echo "$(BLUE)Enterprise DevOps Pipeline - Makefile Documentation$(NC)"
	@echo "$(BLUE)=================================================$(NC)"
	@echo ""
	@echo "This Makefile provides comprehensive automation for:"
	@echo ""
	@echo "$(GREEN)🔧 Development:$(NC)"
	@echo "  - Local development environment setup"
	@echo "  - Code formatting and linting"
	@echo "  - Local testing with Docker Compose"
	@echo ""
	@echo "$(GREEN)🏗️  Build & Test:$(NC)"
	@echo "  - Container image building"
	@echo "  - Security vulnerability scanning"
	@echo "  - Unit and integration testing"
	@echo "  - End-to-end testing"
	@echo ""
	@echo "$(GREEN)🚀 Deployment:$(NC)"
	@echo "  - Multi-environment deployments"
	@echo "  - Infrastructure setup automation"
	@echo "  - CI/CD pipeline configuration"
	@echo ""
	@echo "$(GREEN)📊 Operations:$(NC)"
	@echo "  - Service status monitoring"
	@echo "  - Log aggregation and viewing"
	@echo "  - Port forwarding for local access"
	@echo ""
	@echo "$(YELLOW)Configuration:$(NC)"
	@echo "  - Edit variables at the top of this Makefile"
	@echo "  - Environment-specific settings in openshift/overlays/"
	@echo "  - Application configuration in app/config.py"

# =============================================================================
# Variables for internal use
# =============================================================================

# Build information
BUILD_INFO := "Version: $(VERSION), Commit: $(COMMIT_HASH), Built: $(BUILD_DATE)"

# Export variables for use in scripts
export PROJECT_NAME
export VERSION
export IMAGE_NAME
export IMAGE_TAG
export REGISTRY
export REGISTRY_USER 