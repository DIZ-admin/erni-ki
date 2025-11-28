---
language: en
translation_status: original
doc_version: '2025.11'
last_updated: '2025-11-28'
---

# Getting Started with ERNI-KI

This directory contains essential guides for installing, configuring, and using
the ERNI-KI platform.

## Contents

### Installation

- **[installation.md](installation.md)** - Complete installation guide
  - System requirements
  - Docker Compose setup
  - Initial configuration
  - First model deployment

### Configuration

- **[configuration-guide.md](configuration-guide.md)** - Service configuration
  - Environment variables
  - Service-specific settings
  - GPU configuration
  - Network setup

### User Guides

- **[user-guide.md](user-guide.md)** - End-user guide
  - Chat interface
  - Document upload
  - Search features

### Network Setup

- **[external-access-setup.md](external-access-setup.md)** - External access
  configuration
- **[local-network-dns-setup.md](local-network-dns-setup.md)** - Local DNS setup
- **[dnsmasq-setup-instructions.md](dnsmasq-setup-instructions.md)** - DNSMasq
  guide
- **[port-forwarding-setup.md](port-forwarding-setup.md)** - Port forwarding
  guide

## Quick Start Path

1. **Installation:** Follow [installation.md](installation.md) (~30 minutes)
2. **Configuration:** Review [configuration-guide.md](configuration-guide.md)
3. **First Use:** Read [user-guide.md](user-guide.md)

## Prerequisites

- Ubuntu 20.04+ or Debian 11+
- Docker 20.10+
- 8GB RAM minimum (32GB recommended)
- 50GB storage minimum (200GB+ recommended)
- NVIDIA GPU optional (RTX 4060+ recommended)
