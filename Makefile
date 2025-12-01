.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_%-]+:.*?##' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'

install: ## Install dependencies
	npm install

test: ## Run tests
	PYTHONPATH=$$PYTHONPATH:. .venv/bin/pytest -q

lint: ## Run linters
	.venv/bin/pre-commit run --all-files

clean: ## Clean build artifacts
	rm -rf .venv node_modules __pycache__

docker-build: ## Build docker images
	docker compose build

docker-up: ## Start docker stack
	docker compose up -d

docker-down: ## Stop docker stack
	docker compose down

fmt: ## Format code
	.venv/bin/ruff format

docs: ## Build docs
	npm run docs
