# 📦 Installation Guide - ERNI-KI

> **Версия:** 5.2 **Дата обновления:** 12.08.2025 **Статус:** Production Ready
> (Оптимизированные конфигурации + nginx исправления)

## 📋 Обзор

Детальное руководство по установке и настройке системы ERNI-KI -
Production-Ready AI Platform с архитектурой 27 микросервисов.

## 📋 Системные требования

### Минимальные требования

- **OS:** Linux (Ubuntu 20.04+ / CentOS 8+ / Debian 11+)
- **CPU:** 4 cores (8+ рекомендуется)
- **RAM:** 8GB (16GB+ рекомендуется)
- **Storage:** 50GB свободного места (SSD рекомендуется)
- **Network:** Стабильное интернет-соединение

### Рекомендуемые требования

- **CPU:** 8+ cores с поддержкой AVX2
- **RAM:** 32GB+ для полной функциональности
- **GPU:** NVIDIA GPU с 8GB+ VRAM (для Ollama)
- **Storage:** 200GB+ NVMe SSD
- **Network:** 100Mbps+ для быстрой загрузки моделей

## 🔧 Предварительная настройка

### 1. Установка Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Перезагрузка для применения изменений
sudo reboot
```

### 2. Установка Docker Compose v2

```bash
# Установка Docker Compose v2
sudo apt update
sudo apt install docker-compose-plugin

# Проверка версии
docker compose version
```

### 3. Настройка NVIDIA Container Toolkit (для GPU)

```bash
# Добавление репозитория NVIDIA
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Установка nvidia-container-toolkit
sudo apt update
sudo apt install -y nvidia-container-toolkit

# Перезапуск Docker
sudo systemctl restart docker
```

## 🚀 Быстрая установка

### 1. Клонирование репозитория

```bash
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki
```

### 2. Запуск скрипта установки

```bash
# Интерактивная установка
./scripts/setup/setup.sh

# Или быстрая установка с настройками по умолчанию
./scripts/setup/quick-start.sh
```

### 3. Проверка установки

```bash
# Проверка статуса всех сервисов
./scripts/maintenance/health-check.sh

# Проверка веб-интерфейсов
./scripts/maintenance/check-web-interfaces.sh
```

## 🔧 Ручная установка

### 1. Настройка переменных окружения

```bash
# Копирование примеров конфигураций (оптимизированная структура)
cp env/*.example env/
# Удалите расширение .example из скопированных файлов

# Редактирование основных настроек
nano env/db.env
nano env/ollama.env
nano env/openwebui.env
```

> **Примечание:** Структура конфигураций оптимизирована (август 2025). Все
> дублирующиеся конфигурации удалены, naming convention стандартизирован.

### 2. Настройка SSL сертификатов

```bash
# Генерация самоподписанных сертификатов (для тестирования)
./conf/ssl/generate-ssl-certs.sh

# Или размещение собственных сертификатов
cp your-cert.pem conf/ssl/cert.pem
cp your-key.pem conf/ssl/key.pem
```

### 3. Настройка Cloudflare Tunnel (опционально)

```bash
# Настройка cloudflared
nano env/cloudflared.env

# Добавление tunnel token
echo "TUNNEL_TOKEN=your_tunnel_token_here" >> env/cloudflared.env
```

### 4. Запуск системы

```bash
# Создание Docker сетей
./scripts/setup/create-networks.sh

# Запуск всех сервисов
docker compose up -d

# Проверка статуса
docker compose ps
```

## 🎯 Настройка GPU для Ollama

### 1. Проверка GPU

```bash
# Проверка доступности GPU
nvidia-smi

# Тест GPU в Docker
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
```

### 2. Настройка Ollama для GPU

```bash
# Запуск скрипта настройки GPU
./scripts/setup/gpu-setup.sh

# Или ручная настройка
nano env/ollama.env
# Добавить: OLLAMA_GPU_ENABLED=true
```

### 3. Проверка GPU в Ollama

```bash
# Проверка использования GPU
./scripts/performance/gpu-performance-test.sh

# Мониторинг GPU
./scripts/performance/gpu-monitor.sh
```

## 📊 Настройка мониторинга

### 1. Развертывание системы мониторинга

```bash
# Автоматическая настройка
./scripts/setup/deploy-monitoring-system.sh

# Проверка статуса мониторинга
./scripts/performance/monitoring-system-status.sh

# Проверка webhook-receiver
curl -s http://localhost:9095/health
```

### 2. Доступ к интерфейсам мониторинга

- **Grafana:** http://localhost:3000 (admin/admin)
- **Prometheus:** http://localhost:9091
- **AlertManager:** http://localhost:9093
- **Webhook Receiver:** http://localhost:9095/health

**Примечание:** Для внешнего доступа используйте домен ki.erni-gruppe.ch

### 3. Настройка GPU мониторинга

```bash
# Проверка NVIDIA GPU Exporter
curl -s http://localhost:9445/metrics | grep nvidia_gpu

# Проверка GPU дашборда в Grafana
# Откройте: http://localhost:3000/d/gpu-monitoring
```

## 💾 Настройка backup

### 1. Настройка Backrest

```bash
# Автоматическая настройка
./scripts/setup/setup-backrest-integration.sh

# Проверка backup
./scripts/backup/check-local-backup.sh
```

### 2. Настройка расписания backup

```bash
# Настройка cron для автоматических backup
./scripts/setup/setup-cron-rotation.sh
```

## 🔒 Настройка безопасности

### 1. Усиление безопасности

```bash
# Применение security hardening
./scripts/security/security-hardening.sh

# Настройка мониторинга безопасности
./scripts/security/security-monitor.sh
```

### 2. Настройка firewall

```bash
# UFW (Ubuntu)
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## 🌐 Доступ к системе

### Основные интерфейсы:

- **OpenWebUI:** https://your-domain/ (основной интерфейс)
- **Grafana:** https://your-domain/grafana (мониторинг)
- **Kibana:** https://your-domain/kibana (логи)

### Первый вход:

1. Откройте https://your-domain/
2. Создайте первого пользователя
3. Настройте модели в Ollama
4. Проверьте интеграции

## 🔧 Устранение проблем

### Общие проблемы:

```bash
# Проверка логов
docker compose logs -f

# Перезапуск проблемных сервисов
docker compose restart service-name

# Полная диагностика
./scripts/troubleshooting/automated-recovery.sh
```

### Проблемы с GPU:

```bash
# Диагностика GPU
./scripts/troubleshooting/test-healthcheck.sh

# Проверка драйверов NVIDIA
nvidia-smi
```

## 📞 Поддержка

- **📖 Документация:** [docs/troubleshooting.md](troubleshooting.md)
- **🐛 Issues:** [GitHub Issues](https://github.com/DIZ-admin/erni-ki/issues)
- **💬 Discussions:**
  [GitHub Discussions](https://github.com/DIZ-admin/erni-ki/discussions)

## 🆕 Важные обновления

### Август 2025 - Версия 5.0

**Исправления после установки:**

1. **SearXNG RAG интеграция** - если поиск не работает:

   ```bash
   # Проверить статус SearXNG
   docker logs erni-ki-searxng-1 --tail 20

   # При CAPTCHA ошибках от DuckDuckGo - уже исправлено в конфигурации
   # Активные движки: Startpage, Brave, Bing
   ```

2. **Backrest API** - использовать правильные endpoints:

   ```bash
   # Правильные JSON RPC endpoints
   curl -X POST 'http://localhost:9898/v1.Backrest/GetOperations' \
     --data '{}' -H 'Content-Type: application/json'
   ```

3. **Ollama модели** - доступны 6 моделей включая qwen2.5-coder:1.5b

---

**📝 Примечание:** Данное руководство актуализировано для архитектуры 20+
сервисов ERNI-KI версии 5.0.
