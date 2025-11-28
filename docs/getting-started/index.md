---
language: ru
translation_status: original
doc_version: '2025.11'
last_updated: '2025-11-28'
---

# Начало работы с ERNI-KI

Этот раздел содержит основные инструкции по установке, настройке и использованию
платформы ERNI-KI.

## Содержание

### Установка

- **[installation.md](installation.md)** - Полное руководство по установке
- Системные требования
- Настройка Docker Compose
- Первоначальная конфигурация
- Развертывание первой модели

### Конфигурация

- **[configuration-guide.md](configuration-guide.md)** - Настройка сервисов
- Переменные окружения
- Специфичные настройки сервисов
- Конфигурация GPU
- Настройка сети

### Руководство пользователя

- **[user-guide.md](user-guide.md)** - Документация для конечного пользователя
- Обзор веб-интерфейса
- Функции чата
- Управление моделями
- Использование RAG поиска

### Настройка сети

- **[external-access-setup.md](external-access-setup.md)** - Настройка внешнего
  доступа
- **[local-network-dns-setup.md](local-network-dns-setup.md)** - Настройка
  локального DNS
- **[dnsmasq-setup-instructions.md](dnsmasq-setup-instructions.md)** - Настройка
  DNSMasq
- **[port-forwarding-setup.md](port-forwarding-setup.md)** - Руководство по
  пробросу портов

## Быстрый старт

1. **Установка:** Следуйте инструкции [installation.md](installation.md) (~30
   минут)
2. **Конфигурация:** Изучите [configuration-guide.md](configuration-guide.md)
3. **Первое использование:** Прочитайте [user-guide.md](user-guide.md)

## Требования

- Ubuntu 20.04+ или Debian 11+
- Docker 20.10+
- 8GB RAM минимум (32GB рекомендуется)
- 50GB места на диске минимум (200GB+ рекомендуется)
- NVIDIA GPU опционально (RTX 4060+ рекомендуется)

## Связанная документация

- [Обзор архитектуры](../architecture/index.md)
- [Руководство по эксплуатации](../operations/index.md)
- [Обзор системы](../overview.md)

## Версия

Версия документации: **12.1** Последнее обновление: **2025-11-28**
