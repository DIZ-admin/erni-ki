#!/bin/bash
# Ручная проверка SSL certificates ERNI-KI

cd "$(dirname "$0")/../.."
./scripts/ssl/monitor-certificates.sh check
