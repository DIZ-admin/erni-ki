.PHONY: help install dev test lint lint-fix format format-py docker-build docker-up docker-down docker-logs health-check docs-serve clean

# ERNI-KI Development & Operations Commands
# Usage: make <target>
# For available targets: make help

.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║                   ERNI-KI Development Commands                  ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make install       # Install all dependencies"
	@echo "  make dev           # Start development environment"
	@echo "  make test          # Run all tests"
	@echo "  make lint          # Run linters"
	@echo "  make docker-up     # Start all services"
	@echo ""

# ============================================================================
# INSTALLATION & SETUP
# ============================================================================

install: ## Install all dependencies (npm + pip + pre-commit)
	@echo "$(YELLOW)Installing dependencies...$(NC)"
	npm ci --prefer-offline
	@echo "$(YELLOW)Installing Python dependencies...$(NC)"
	pip install -r requirements-dev.txt
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

install-quick: ## Quick install (npm only)
	@echo "$(YELLOW)Installing npm dependencies...$(NC)"
	npm ci --prefer-offline

setup-git-hooks: ## Setup pre-commit hooks
	@echo "$(YELLOW)Setting up pre-commit hooks...$(NC)"
	source .venv/bin/activate && pre-commit install && pre-commit install --hook-type commit-msg
	@echo "$(GREEN)✓ Git hooks installed$(NC)"

# ============================================================================
# DEVELOPMENT
# ============================================================================

dev: ## Start development environment (up + lint + test)
	@echo "$(YELLOW)Starting development environment...$(NC)"
	docker compose up -d
	@sleep 3
	@echo "$(YELLOW)Running linters...$(NC)"
	npm run lint
	@echo "$(YELLOW)Running tests...$(NC)"
	npm run test:unit
	@echo "$(GREEN)✓ Development environment ready$(NC)"

dev-watch: ## Run tests in watch mode
	@echo "$(YELLOW)Running tests in watch mode...$(NC)"
	npm run test:watch

dev-ui: ## Run tests with UI
	@echo "$(YELLOW)Opening test UI...$(NC)"
	npm run test:ui

# ============================================================================
# CODE QUALITY
# ============================================================================

lint: ## Run all linters (JS + Python + Shells)
	@echo "$(YELLOW)Running linters...$(NC)"
	@echo "  → TypeScript/JavaScript..."
	npm run lint:js
	@echo "  → Python..."
	npm run lint:py
	@echo "$(GREEN)✓ All linters passed$(NC)"

lint-fix: ## Fix linting issues (auto-fixable only)
	@echo "$(YELLOW)Fixing linting issues...$(NC)"
	@echo "  → TypeScript/JavaScript..."
	npm run lint:js:fix
	@echo "  → Python..."
	npm run lint:py:fix
	@echo "$(GREEN)✓ Linting issues fixed$(NC)"

format: ## Format code (Prettier + Ruff)
	@echo "$(YELLOW)Formatting code...$(NC)"
	npm run format
	npm run format:py
	@echo "$(GREEN)✓ Code formatted$(NC)"

format-check: ## Check code formatting without changes
	@echo "$(YELLOW)Checking code formatting...$(NC)"
	npm run format:check
	@echo "$(GREEN)✓ Code formatting OK$(NC)"

type-check: ## Run TypeScript type checking
	@echo "$(YELLOW)Type checking...$(NC)"
	npm run type-check
	@echo "$(GREEN)✓ No type errors$(NC)"

# ============================================================================
# TESTING
# ============================================================================

test: ## Run all tests (unit + e2e mock)
	@echo "$(YELLOW)Running all tests...$(NC)"
	npm run test
	@echo "$(GREEN)✓ All tests passed$(NC)"

test-unit: ## Run unit tests only
	@echo "$(YELLOW)Running unit tests...$(NC)"
	npm run test:unit
	@echo "$(GREEN)✓ Unit tests passed$(NC)"

test-e2e: ## Run E2E tests (requires real server)
	@echo "$(YELLOW)Running E2E tests...$(NC)"
	npm run test:e2e

test-e2e-mock: ## Run E2E tests with mock data
	@echo "$(YELLOW)Running E2E tests (mock)...$(NC)"
	npm run test:e2e:mock

test-go: ## Run Go tests (auth service)
	@echo "$(YELLOW)Running Go tests...$(NC)"
	cd auth && go test -v ./...
	@echo "$(GREEN)✓ Go tests passed$(NC)"

# ============================================================================
# SECURITY SCANNING
# ============================================================================

security-scan: ## Run security scans (npm audit + gosec)
	@echo "$(YELLOW)Running security scans...$(NC)"
	@echo "  → npm audit..."
	npm audit --audit-level=high
	@echo "  → gosec (Go security)..."
	docker run --rm -v $(PWD)/auth:/src -w /src securecodewarrior/docker-gosec ./...
	@echo "$(GREEN)✓ Security scans passed$(NC)"

gitleaks: ## Check for secrets in Git history
	@echo "$(YELLOW)Checking for secrets...$(NC)"
	pre-commit run gitleaks --all-files
	@echo "$(GREEN)✓ No secrets detected$(NC)"

trivy-container: ## Scan Docker images for vulnerabilities
	@echo "$(YELLOW)Scanning Docker images...$(NC)"
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy:latest image erni-ki-auth:dev
	@echo "$(GREEN)✓ Image scanning complete$(NC)"

# ============================================================================
# DOCKER OPERATIONS
# ============================================================================

docker-build: ## Build auth service Docker image
	@echo "$(YELLOW)Building auth service image...$(NC)"
	docker build -t erni-ki-auth:dev ./auth
	@echo "$(GREEN)✓ Image built: erni-ki-auth:dev$(NC)"

docker-build-full: ## Build all custom images
	@echo "$(YELLOW)Building all custom images...$(NC)"
	docker build -t erni-ki-auth:dev ./auth
	@echo "$(GREEN)✓ All custom images built$(NC)"

docker-up: ## Start all services (background)
	@echo "$(YELLOW)Starting all services...$(NC)"
	docker compose up -d
	@echo "$(YELLOW)Waiting for services to initialize...$(NC)"
	@sleep 5
	@make health-check
	@echo "$(GREEN)✓ All services started$(NC)"

docker-down: ## Stop all services
	@echo "$(YELLOW)Stopping all services...$(NC)"
	docker compose down
	@echo "$(GREEN)✓ All services stopped$(NC)"

docker-clean: ## Remove all containers and volumes (DATA LOSS!)
	@echo "$(RED)⚠️  WARNING: This will delete ALL data!$(NC)"
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		docker compose down -v; \
		echo "$(GREEN)✓ Containers and volumes removed$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

docker-logs: ## Show logs from all services
	@echo "$(YELLOW)Streaming logs (Ctrl+C to stop)...$(NC)"
	docker compose logs -f

docker-logs-service: ## Show logs from specific service (usage: make docker-logs-service SERVICE=openwebui)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE variable required$(NC)"; \
		echo "Usage: make docker-logs-service SERVICE=openwebui"; \
		exit 1; \
	fi
	docker compose logs -f $(SERVICE)

docker-ps: ## Show running containers
	@docker compose ps

docker-restart: ## Restart all services
	@echo "$(YELLOW)Restarting all services...$(NC)"
	docker compose restart
	@sleep 3
	@make health-check

# ============================================================================
# MONITORING & HEALTH
# ============================================================================

health-check: ## Check health of all services
	@echo "$(YELLOW)Checking service health...$(NC)"
	@./scripts/health-monitor.sh --report

health-watch: ## Watch service health continuously
	@echo "$(YELLOW)Monitoring service health (Ctrl+C to stop)...$(NC)"
	@watch -n 5 './scripts/health-monitor.sh --report'

disk-usage: ## Check disk space usage
	@echo "$(YELLOW)Disk usage:$(NC)"
	@df -h | grep -E '^/dev|^Filesystem'

memory-usage: ## Check memory usage
	@echo "$(YELLOW)Memory usage:$(NC)"
	@free -h

gpu-status: ## Check GPU status (if available)
	@echo "$(YELLOW)GPU status:$(NC)"
	@nvidia-smi || echo "GPU not available"

system-stats: ## Show comprehensive system stats
	@echo "$(BLUE)=== System Statistics ===$(NC)"
	@make disk-usage
	@echo ""
	@make memory-usage
	@echo ""
	@make gpu-status
	@echo ""
	@make health-check

# ============================================================================
# DOCUMENTATION
# ============================================================================

docs-serve: ## Build and serve documentation locally
	@echo "$(YELLOW)Starting documentation server...$(NC)"
	@docker run --rm -v $(PWD):/docs -p 8000:8000 mkdocs:latest mkdocs serve
	@echo "$(GREEN)✓ Docs available at http://localhost:8000$(NC)"

docs-build: ## Build documentation static site
	@echo "$(YELLOW)Building documentation...$(NC)"
	@docker run --rm -v $(PWD):/docs mkdocs:latest mkdocs build
	@echo "$(GREEN)✓ Documentation built in site/$(NC)"

docs-lint: ## Lint documentation
	@echo "$(YELLOW)Linting documentation...$(NC)"
	npm run docs:lint

# ============================================================================
# MAINTENANCE & CLEANUP
# ============================================================================

clean: ## Clean build artifacts and caches
	@echo "$(YELLOW)Cleaning artifacts...$(NC)"
	npm run clean
	rm -rf dist coverage .pytest_cache
	docker system prune -f
	@echo "$(GREEN)✓ Cleaned$(NC)"

clean-all: ## Deep clean (removes node_modules, .venv)
	@echo "$(RED)⚠️  This will remove node_modules and .venv!$(NC)"
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		rm -rf node_modules .venv dist coverage; \
		npm cache clean --force; \
		echo "$(GREEN)✓ Deep clean complete$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

pre-commit-run: ## Run pre-commit hooks on all files
	@echo "$(YELLOW)Running pre-commit hooks...$(NC)"
	source .venv/bin/activate && pre-commit run --all-files
	@echo "$(GREEN)✓ Pre-commit checks passed$(NC)"

pre-commit-update: ## Update pre-commit hooks
	@echo "$(YELLOW)Updating pre-commit hooks...$(NC)"
	source .venv/bin/activate && pre-commit autoupdate
	@echo "$(GREEN)✓ Pre-commit hooks updated$(NC)"

# ============================================================================
# DEPLOYMENT
# ============================================================================

check-deploy: ## Pre-deployment checklist verification
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║            Pre-Deployment Checklist Verification                ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)1. Code Quality Checks...$(NC)"
	@make lint || { echo "$(RED)✗ Linting failed$(NC)"; exit 1; }
	@make type-check || { echo "$(RED)✗ Type checking failed$(NC)"; exit 1; }
	@echo ""
	@echo "$(YELLOW)2. Running Tests...$(NC)"
	@make test || { echo "$(RED)✗ Tests failed$(NC)"; exit 1; }
	@echo ""
	@echo "$(YELLOW)3. Security Checks...$(NC)"
	@make security-scan || { echo "$(RED)✗ Security scan failed$(NC)"; exit 1; }
	@echo ""
	@echo "$(YELLOW)4. Building Docker Image...$(NC)"
	@make docker-build || { echo "$(RED)✗ Docker build failed$(NC)"; exit 1; }
	@echo ""
	@echo "$(GREEN)✓ All pre-deployment checks passed!$(NC)"
	@echo "$(GREEN)✓ Ready for deployment$(NC)"
	@echo ""
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Review: docs/operations/core/pre-deployment-checklist.md"
	@echo "  2. Create backup: make backup"
	@echo "  3. Deploy: docker compose pull && docker compose up -d"

backup: ## Create backup of PostgreSQL and Redis (development only)
	@echo "$(YELLOW)Creating backups...$(NC)"
	@mkdir -p backups
	@docker compose exec db pg_dump -U postgres erni_ki | gzip > backups/erni_ki_$$(date +%Y%m%d_%H%M%S).sql.gz
	@docker compose exec redis redis-cli BGSAVE
	@echo "$(GREEN)✓ Backups created in backups/ directory$(NC)"

# ============================================================================
# UTILITIES
# ============================================================================

version: ## Show version information
	@echo "$(BLUE)ERNI-KI Version Information:$(NC)"
	@grep '"version"' package.json | head -1
	@echo "Node: $$(node --version)"
	@echo "npm: $$(npm --version)"
	@echo "Python: $$(python3 --version)"
	@echo "Docker: $$(docker --version)"

info: ## Show project information
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║                      ERNI-KI Project Info                       ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Project:$(NC) ERNI-KI - Production AI Platform"
	@echo "$(YELLOW)Repository:$(NC) https://github.com/DIZ-admin/erni-ki"
	@echo "$(YELLOW)Documentation:$(NC) https://ki.erni-gruppe.ch"
	@echo ""
	@make version
	@echo ""
	@echo "$(YELLOW)Available environments:$(NC)"
	@echo "  - Development: localhost:8080"
	@echo "  - Monitoring: localhost:3000 (Grafana)"
	@echo "  - Prometheus: localhost:9090"
	@echo ""

# ============================================================================
# ADVANCED TARGETS
# ============================================================================

# Composite targets for common workflows

all: install lint test ## Install, lint, and test (default workflow)
	@echo "$(GREEN)✓ Complete workflow finished$(NC)"

ci-local: lint type-check test security-scan ## Local CI simulation
	@echo "$(GREEN)✓ CI simulation passed$(NC)"

full-setup: clean install setup-git-hooks docker-build docker-up health-check ## Complete setup from scratch
	@echo "$(GREEN)✓ Full setup complete$(NC)"

# ============================================================================
# CI/CD (For automated pipelines)
# ============================================================================

ci-lint: lint type-check format-check ## CI linting job
ci-test: test test-go ## CI testing job
ci-build: docker-build docker-build-full ## CI build job
ci-security: security-scan gitleaks trivy-container ## CI security job

# ============================================================================
# HELP & INFO
# ============================================================================

targets: ## List all make targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {print $$1}' | sort

.PHONY: targets help all ci-local full-setup ci-lint ci-test ci-build ci-security

# Print help on unknown targets (optional)
%:
	@echo "$(RED)Unknown target: $@$(NC)"
	@echo "$(YELLOW)Run 'make help' for available commands$(NC)"
	@exit 1
