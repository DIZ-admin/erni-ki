---
language: ru
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-30'
title: 'Стандарты кода ERNI-KI'
---

# Стандарты кода ERNI-KI

Краткие правила для Go, TypeScript/Node.js и Python, используемые в ERNI-KI.
Развернутые требования по линтерам — в конфигурациях (`eslint.config.js`,
`ruff.toml`, `go.mod`).

## Общие принципы

- Следуем SemVer и conventional commits (`feat/fix/chore/docs`, `scope`
  обязателен).
- Все изменения проходят через PR с CI (`ci`, `security`, `deploy-environments`)
  и двумя аппрувами.
- Линтеры и форматирование: `npm run lint`, `npm run format`,
  `python -m ruff check .`, `gofmt` + `go test ./...`.
- Запрещены секреты и токены в коде/логах; используем Docker secrets или `.env`.
- Тесты обязательны для новой логики; целевой coverage ≥85% (Vitest/pytest/Go).

## Go

- Версия: Go 1.24.x, модули и `GOTOOLCHAIN` должны совпадать.
- Форматирование: `gofmt` + `go vet`; линтеры из `golangci-lint` (см.
  `.golangci.yml` если добавится).
- Обработка ошибок: `errors.Is/As`, контекст через `fmt.Errorf("...: %w", err)`.
- Логи: структурные (`log/slog`), уровни INFO/ERROR; никаких `log.Fatal` в
  библиотеках.

## TypeScript / Node.js

- Версия Node: 22.14.x; TS строгий (`strict: true`), ES2022.
- ESLint flat config, Prettier — не выключать правила без причины; используем
  алиасы путей из `tsconfig.json`.
- Исключаем `any`; предпочитаем `unknown` + сужение типов.
- Асинхронщина: `async/await`, обработка ошибок try/catch, обязательные
  тайм-ауты для внешних запросов.

## Python

- Python 3.11; Ruff для lint/format.
- Типы обязательны для нового кода; mypy/pyright при добавлении большого объема
  логики.
- Логи через `logging` с форматером JSON, уровень по умолчанию INFO.
- Управление зависимостями: `pyproject.toml` + `poetry.lock`; избегать системных
  `pip install` без фиксации версий.

## Безопасность

- Используем secrets/`env/*.env`, запрещены дефолтные пароли и `latest` образы
  без digest.
- Настройки TLS/CORS/headers описываем в `docs/security/` и отражаем в Nginx
  конфигурации.
- Проверяем зависимости: `npm audit --audit-level=moderate`, `trivy image`,
  `gosec`, `detect-secrets`.

## Документация

- Каждая фича сопровождается обновлением `docs/` и фронтматтером (язык, дата,
  версия).
- Ссылки должны быть относительными и валидными; используйте линк-чекер из CI.
