#!/bin/bash
# Manual SSL certificate validation for ERNI-KI

cd "$(dirname "$0")/../.."
./scripts/ssl/monitor-certificates.sh check
