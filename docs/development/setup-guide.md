---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-29'
---

# Development Setup Guide

> **Document Version:** 1.0 **Last Updated:** 2025-11-29 **Estimated Setup
> Time:** 20-30 minutes

This guide will help you set up ERNI-KI for local development. By the end,
you'll be able to run the entire system locally and contribute code changes.

## Prerequisites

- **Operating System:** macOS, Linux, or Windows (with WSL2)
- **Git:** 2.25+
- **Docker Desktop:** 4.20+ (with Docker Compose v2)
- **Python:** 3.11+
- **Node.js:** 18.17+ with npm 9+

### macOS

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install git python@3.11 node docker
brew install --cask docker

# Start Docker Desktop
open /Applications/Docker.app

```

### Ubuntu/Debian

```bash
# Update package manager
sudo apt-get update && sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y git curl wget python3.11 python3-pip nodejs npm

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (requires logout/login)
sudo usermod -aG docker $USER

```

### Windows (WSL2)

```bash
# In WSL2 terminal
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git curl python3.11 python3-pip nodejs npm docker-ce

# Install Docker Desktop for Windows
# Download from https://www.docker.com/products/docker-desktop

```

## Installation

### 1. Clone Repository

```bash
# Clone the repository
git clone https://github.com/erni-gruppe/erni-ki-1.git
cd erni-ki-1

# Switch to develop branch (if needed)
git checkout develop

```

### 2. Set Up Environment Files

```bash
# Copy environment templates
cp env/example.env .env
cp env/openwebui.env.example env/openwebui.env
cp env/alertmanager.env.example env/alertmanager.env

# Edit .env with your local configuration
nano .env

```

**Minimal .env Configuration:**

```bash
# Core Settings
PROJECT_ROOT=/path/to/erni-ki-1
ENVIRONMENT=development
LOG_LEVEL=DEBUG

# Database
POSTGRES_USER=openwebui_user
POSTGRES_PASSWORD=dev-password-change-in-production
OPENWEBUI_DB_HOST=db
OPENWEBUI_DB_PORT=5432

# OpenWebUI
OPENWEBUI_ADMIN_USER_ID=your-admin-uuid-here
OPENWEBUI_ADMIN_NAME=Administrator
OPENWEBUI_ADMIN_EMAIL=admin@localhost

# Webhook Secret
ALERTMANAGER_WEBHOOK_SECRET=dev-webhook-secret

# GPU (if available)
CUDA_VISIBLE_DEVICES=0

# LiteLLM
LITELLM_API_KEY=dev-api-key

```

### 3. Create Secrets Directory

```bash
# Create secrets directory
mkdir -p secrets

# Generate secrets (use strong random values in production)
echo "dev-db-password" > secrets/postgres_password.txt
echo "dev-webhook-secret" > secrets/alertmanager_webhook_secret.txt
echo "dev-api-key" > secrets/litellm_api_key.txt
echo "your-admin-uuid" > secrets/openwebui_admin_user_id.txt

# Protect secrets
chmod 600 secrets/*

```

### 4. Set Up Python Development Environment

```bash
# Create virtual environment
python3.11 -m venv .venv

# Activate virtual environment
source .venv/bin/activate # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements-dev.txt

# Verify installation
python --version
pip list | head -10

```

### 5. Set Up Node.js Development Environment

```bash
# Install Node.js dependencies
npm install

# Install development tools
npm install -D @types/node typescript eslint prettier

# Verify installation
node --version
npm --version

```

### 6. Configure Pre-commit Hooks

```bash
# Install pre-commit framework
pip install pre-commit

# Install hooks
pre-commit install

# (Optional) Run against all files
pre-commit run --all-files

```

## Running ERNI-KI Locally

### Option 1: Docker Compose (Recommended for Full System)

```bash
# Build images
docker-compose build

# Start all services
docker-compose up -d

# Verify services are running
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down

```

**First Run:**

After starting Docker Compose, services will take ~2 minutes to initialize:

```bash
# Wait for services to be ready
sleep 30

# Check health
curl http://localhost:8080/health
curl http://localhost:9093/-/healthy

```

### Option 2: Local Development (Selected Services)

For faster development, run only essential services in Docker:

```bash
# Start only database and dependencies
docker-compose up -d db redis ollama

# Run Python services locally
source .venv/bin/activate
python conf/webhook-receiver/webhook-receiver.py &
python conf/rag_exporter.py &
python ops/ollama-exporter/app.py &

# In another terminal, run Node.js services
npm run dev

# Stop background processes
pkill -f webhook-receiver
pkill -f rag_exporter
pkill -f ollama-exporter

```

### Option 3: Service-by-Service Development

```bash
# Terminal 1: Database
docker-compose up db redis

# Terminal 2: Ollama
docker-compose up ollama

# Terminal 3: Python services
source .venv/bin/activate
python conf/webhook-receiver/webhook-receiver.py

# Terminal 4: Node/OpenWebUI
npm run dev

```

## Verification

### Check All Services Running

```bash
# In Docker
docker-compose ps

# Expected output:
# NAME STATUS
# db Up 2 minutes
# redis Up 2 minutes
# ollama Up 2 minutes
# openwebui Up 2 minutes
# alertmanager Up 2 minutes
# webhook-receiver Up 2 minutes

```

### Test Connectivity

```bash
# Test OpenWebUI
curl http://localhost:8080

# Test Ollama
curl http://localhost:11434/api/tags

# Test Webhook Receiver
curl -X POST http://localhost:5001/webhook \
 -H "Content-Type: application/json" \
 -H "X-Signature: test" \
 -d '{"alerts":[]}'

# Test Database
docker-compose exec db psql -U openwebui_user -d openwebui -c "SELECT version();"

```

### Run Health Checks

```bash
# Dashboard health endpoint
curl http://localhost:8080/health | jq .

# Alertmanager health
curl http://localhost:9093/-/healthy

# Prometheus ready
curl http://localhost:9090/-/ready

# Database connectivity test
python -c "
import psycopg2
conn = psycopg2.connect('postgresql://openwebui_user:password@localhost:5432/openwebui')
print(' Database connection successful')
"

```

## Development Workflow

### Making Code Changes

1. **Create feature branch:**

```bash
git checkout -b feature/my-feature
```

2. **Make changes** to your files

3. **Run tests:**

```bash
npm run test
pytest tests/
```

4. **Run linting:**

```bash
npm run lint
npm run lint:py
```

5. **Commit changes:**

```bash
git add .
git commit -m "feat: add my feature"
```

6. **Push and create PR:**

```bash
git push origin feature/my-feature
# Create PR on GitHub
```

### Running Tests

```bash
# Python tests
pytest tests/ -v

# JavaScript/TypeScript tests
npm run test

# With coverage
npm run test:coverage
pytest tests/ --cov

# Watch mode (for development)
npm run test -- --watch
pytest-watch tests/

```

### Code Quality Checks

```bash
# ESLint (JavaScript/TypeScript)
npm run lint
npm run lint -- --fix # Auto-fix issues

# Ruff (Python)
ruff check .
ruff format .

# Type checking
npx tsc --noEmit
mypy . --ignore-missing-imports

# All checks
npm run lint:all

```

## IDE Setup

### VS Code

```bash
# Install extensions
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint
code --install-extension charliermarsh.ruff

# Open workspace
code .

```

**VS Code Settings (.vscode/settings.json):**

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.ruffEnabled": true,
  "python.formatting.provider": "black",
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnSave": true
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  }
}
```

### PyCharm

1. Open Project Settings > Python Interpreter
2. Add interpreter from `.venv` directory
3. Set default test runner to pytest
4. Configure code style to match `ruff` rules

### VIM/Neovim

```bash
# Install LSP and formatter support
# See tools/vim-setup.md for detailed instructions

```

## Debugging

### Python Debugging

```bash
# With pdb (Python debugger)
python -m pdb conf/webhook-receiver/webhook-receiver.py

# With ipdb (better debugging)
pip install ipdb
ipdb conf/webhook-receiver/webhook-receiver.py

```

### JavaScript Debugging

```bash
# VS Code debugging
# Press F5 or add breakpoints and run with debugger

# Node.js debugging
node --inspect path/to/your-javascript-file.js

# Chrome DevTools
# Visit chrome://inspect

```

### Python Debugging

```bash
# For Python files, use:
python -m debugpy --listen 5678 conf/webhook-receiver/webhook-receiver.py

```

### Docker Container Debugging

```bash
# Execute commands in running container
docker-compose exec openwebui bash
docker-compose exec webhook-receiver sh

# View logs
docker-compose logs -f webhook-receiver
docker-compose logs -f openwebui --tail=50

```

## Troubleshooting

### Services Won't Start

```bash
# Check Docker version
docker --version
docker-compose --version

# Rebuild images
docker-compose build --no-cache

# Check for port conflicts
lsof -i :8080 # OpenWebUI
lsof -i :5001 # Webhook receiver
lsof -i :5432 # Database

```

### Database Connection Error

```bash
# Check if database is running
docker-compose ps db

# Check database logs
docker-compose logs db

# Connect directly
docker-compose exec db psql -U openwebui_user -d openwebui

# Reset database
docker-compose down -v
docker-compose up -d db

```

### Port Already in Use

```bash
# Find process using port
lsof -i :8080

# Kill process (use PID from lsof output)
kill -9 <PID>

# Or change ports in docker-compose.override.yml

```

### Memory/Resource Issues

```bash
# Check Docker resources
docker stats

# Increase Docker memory allocation
# Docker Desktop > Settings > Resources > Memory: 8GB+

# Clear unused containers/images
docker system prune -a

```

## Next Steps

- Read the [Testing Guide](./testing-guide.md) to learn about running tests
- Check the [API Reference](../reference/api-reference.md) for available
  endpoints
- Review [Security Policy](../security/security-policy.md) for authentication
- Read
  [CONTRIBUTING.md](https://github.com/DIZ-admin/erni-ki/blob/main/CONTRIBUTING.md)
  for contribution guidelines

## Getting Help

- Check [troubleshooting guide](../troubleshooting/common-issues.md)
- Review service logs: `docker-compose logs <service>`
- Check GitHub issues: https://github.com/erni-gruppe/erni-ki-1/issues
- Join community discussions

---

**Problems with this guide?** Open an issue or submit a PR!
