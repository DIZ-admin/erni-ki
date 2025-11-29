#!/bin/bash
# GPU acceleration setup script for ERNI-KI
# Install NVIDIA Container Toolkit and configure Ollama

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# Color definitions for output

# Logging functions
[INFO]${NC} $1"
}

[SUCCESS]${NC} $1"
}

[WARNING]${NC} $1"
}

[ERROR]${NC} $1"
    exit 1
}

# Check for NVIDIA GPU presence
check_nvidia_gpu() {
    log_info "Checking for NVIDIA GPU..."

    if ! command -v nvidia-smi &> /dev/null; then
        log_error "NVIDIA drivers not installed. Install NVIDIA drivers before running this script."
    fi

    local gpu_count=$(nvidia-smi --list-gpus | wc -l)
    if [ "$gpu_count" -eq 0 ]; then
        log_error "No NVIDIA GPUs detected"
    fi

    log_success "Detected GPUs: $gpu_count"
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader,nounits
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        log_error "Unable to determine Linux distribution"
    fi

    log_info "Detected distribution: $DISTRO $VERSION"
}

# Install NVIDIA Container Toolkit for Ubuntu/Debian
install_nvidia_toolkit_debian() {
    log_info "Installing NVIDIA Container Toolkit for Ubuntu/Debian..."

    # Add repository
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    # Update packages and install
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit

    log_success "NVIDIA Container Toolkit installed"
}

# Install NVIDIA Container Toolkit for CentOS/RHEL/Fedora
install_nvidia_toolkit_rhel() {
    log_info "Installing NVIDIA Container Toolkit for CentOS/RHEL/Fedora..."

    # Add repository
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
        sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

    # Install
    if command -v dnf &> /dev/null; then
        sudo dnf install -y nvidia-container-toolkit
    else
        sudo yum install -y nvidia-container-toolkit
    fi

    log_success "NVIDIA Container Toolkit installed"
}

# Install NVIDIA Container Toolkit
install_nvidia_container_toolkit() {
    detect_distro

    case $DISTRO in
        ubuntu|debian)
            install_nvidia_toolkit_debian
            ;;
        centos|rhel|fedora)
            install_nvidia_toolkit_rhel
            ;;
        *)
            log_error "Unsupported distribution: $DISTRO"
            ;;
    esac
}

# Configure Docker to use NVIDIA runtime
configure_docker_nvidia() {
    log_info "Configuring Docker to use NVIDIA runtime..."

    # Configure NVIDIA Container Runtime
    sudo nvidia-ctk runtime configure --runtime=docker

    # Restart Docker
    sudo systemctl restart docker

    # Check configuration
    if docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi; then
        log_success "Docker successfully configured to use GPU"
    else
        log_error "Error configuring Docker for GPU"
    fi
}

# Update compose.yml to enable GPU
update_compose_gpu() {
    log_info "Updating compose.yml to enable GPU support..."

    local compose_file="compose.yml"

    # Check file existence
    if [ ! -f "$compose_file" ]; then
        if [ -f "compose.yml.example" ]; then
            cp "compose.yml.example" "$compose_file"
            log_info "Created compose.yml from example"
        else
            log_error "File compose.yml not found"
        fi
    fi

    # Uncomment GPU deploy for Ollama
    if grep -q "# deploy: \*gpu-deploy" "$compose_file"; then
        sed -i 's/# deploy: \*gpu-deploy/deploy: *gpu-deploy/' "$compose_file"
        log_success "GPU deploy enabled for Ollama"
    else
        log_warn "GPU deploy already enabled or not found in configuration"
    fi

    # Uncomment GPU deploy for Open WebUI (if present)
    if grep -q "# deploy: \*gpu-deploy" "$compose_file"; then
        sed -i 's/# deploy: \*gpu-deploy/deploy: *gpu-deploy/' "$compose_file"
        log_success "GPU deploy enabled for Open WebUI"
    fi
}

# Create optimized Ollama configuration
create_ollama_config() {
    log_info "Creating optimized Ollama configuration..."

    local ollama_env="env/ollama.env"

    # Create or update configuration
    cat > "$ollama_env" << 'EOF'
# Ollama GPU Configuration
OLLAMA_DEBUG=0
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_ORIGINS=*

# GPU settings
OLLAMA_GPU_LAYERS=-1
OLLAMA_NUM_PARALLEL=4
OLLAMA_MAX_LOADED_MODELS=3

# Performance
OLLAMA_FLASH_ATTENTION=1
OLLAMA_KV_CACHE_TYPE=f16
OLLAMA_NUM_THREAD=0

# Memory
OLLAMA_MAX_VRAM=0.9
OLLAMA_KEEP_ALIVE=5m

# Logging
OLLAMA_LOG_LEVEL=INFO
EOF

    log_success "Created optimized Ollama configuration"
}

# Download recommended models
download_models() {
    log_info "Downloading recommended models..."

    # Check if Ollama is running
    if ! docker compose ps ollama | grep -q "Up"; then
        log_info "Starting Ollama service..."
        docker compose up -d ollama

        # Wait for startup
        local retries=30
        while [ $retries -gt 0 ]; do
            if docker compose exec ollama ollama list &>/dev/null; then
                break
            fi
            sleep 2
            ((retries--))
        done

        if [ $retries -eq 0 ]; then
            log_error "Ollama failed to start within 60 seconds"
        fi
    fi

    # List of models to download
    local models=(
        "nomic-embed-text:latest"
        "llama3.2:3b"
    )

    for model in "${models[@]}"; do
        log_info "Downloading model: $model"
        if docker compose exec ollama ollama pull "$model"; then
            log_success "Model $model downloaded"
        else
            log_warn "Failed to download model $model"
        fi
    done
}

# Test GPU performance
test_gpu_performance() {
    log_info "Testing GPU performance..."

    # Simple generation test
    local test_prompt="Hello, how are you?"

    log_info "Testing with model llama3.2:3b..."
    local start_time=$(date +%s.%N)

    if docker compose exec ollama ollama run llama3.2:3b "$test_prompt" &>/dev/null; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)
        log_success "Test completed in ${duration} seconds"

        if (( $(echo "$duration < 1.0" | bc -l) )); then
            log_success "Excellent GPU performance! (<1s)"
        elif (( $(echo "$duration < 3.0" | bc -l) )); then
            log_success "Good GPU performance! (<3s)"
        else
            log_warn "GPU performance could be improved (>3s)"
        fi
    else
        log_warn "Failed to run performance test"
    fi
}

# Create GPU monitoring
create_gpu_monitoring() {
    log_info "Creating GPU monitoring configuration..."

    # Create docker-compose override for monitoring
    cat > "docker-compose.gpu-monitoring.yml" << 'EOF'
version: '3.8'

services:
  nvidia-exporter:
    image: mindprince/nvidia_gpu_prometheus_exporter:0.1
    restart: unless-stopped
    ports:
      - "9445:9445"
    volumes:
      - /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1:/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1:ro
      - /usr/bin/nvidia-smi:/usr/bin/nvidia-smi:ro
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
EOF

    log_success "GPU monitoring configuration created"
    log_info "To start monitoring use: docker compose -f compose.yml -f docker-compose.gpu-monitoring.yml up -d"
}

# Main function
main() {
    log_info "Starting GPU acceleration setup for ERNI-KI..."

    # Check that we are in project root
    if [ ! -f "compose.yml.example" ]; then
        log_error "Script must be run from ERNI-KI project root"
    fi

    # Check sudo rights
    if [ "$EUID" -eq 0 ]; then
        log_error "Do not run script as root. Use sudo when needed."
    fi

    check_nvidia_gpu
    install_nvidia_container_toolkit
    configure_docker_nvidia
    update_compose_gpu
    create_ollama_config
    create_gpu_monitoring

    log_success "GPU setup completed!"

    echo ""
    log_info "Next steps:"
    echo "1. Restart services: docker compose down && docker compose up -d"
    echo "2. Wait for Ollama service to start"
    echo "3. Download models: $0 --download-models"
    echo "4. Test performance: $0 --test-performance"

    # Process command line arguments
    case "${1:-}" in
        --download-models)
            download_models
            ;;
        --test-performance)
            test_gpu_performance
            ;;
        --help)
            echo "Usage: $0 [--download-models|--test-performance|--help]"
            echo "  --download-models   Download recommended models"
            echo "  --test-performance  Test GPU performance"
            echo "  --help             Show this help"
            ;;
    esac
}

# Run script
main "$@"
