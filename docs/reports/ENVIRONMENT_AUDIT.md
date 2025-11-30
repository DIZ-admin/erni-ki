---
language: ru
translation_status: original
doc_version: '2025.11'
last_updated: '2025-11-30'
title: 'Аудит окружения (локальное vs CI)'
---

# Аудит окружения (локальное vs CI)

| Компонент   | Ожидается в CI                                 | Обнаружено локально                                                      | Статус/риск                        | Действие                                                                                                                                                                                      |
| ----------- | ---------------------------------------------- | ------------------------------------------------------------------------ | ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Python      | 3.11.x                                         | 3.14.0 (по умолчанию), 3.11.14 доступен (`/opt/homebrew/bin/python3.11`) | Medium: разные версии по умолчанию | Использовать `python3.11` и venv (`python3.11 -m venv .venv && source .venv/bin/activate`); устанавливать зависимости из `requirements-dev.txt` + `requests Flask pydantic pytest pytest-cov` |
| Node.js     | 22.14.0                                        | 23.11.0 / npm 10.9.2                                                     | Medium: несовпадение major         | Использовать 22.14.0 (добавлен `.nvmrc`), `nvm use` или менеджер версий; зависимости ставить через `npm ci`                                                                                   |
| Go          | 1.24.x                                         | 1.24.4                                                                   | OK                                 | Без действий                                                                                                                                                                                  |
| Docker      | 24.x                                           | 28.5.2, Compose v2.40.3                                                  | OK (новее)                         | Без действий                                                                                                                                                                                  |
| PYTHONPATH  | `$PYTHONPATH:.`                                | не задан                                                                 | Risk: импорты в `tests/python`     | Экспортировать `export PYTHONPATH=$PYTHONPATH:.` перед запуском тестов/скриптов                                                                                                               |
| pre-commit  | Все хуки проходят                              | не проверено                                                             | Risk: рассинхрон с CI              | `pre-commit install && pre-commit run --all-files` после установки зависимостей                                                                                                               |
| Env/secrets | Заполнены `.env`, `env/*.env`, `secrets/*.txt` | не проверено                                                             | Info                               | Скопировать примеры и заполнить для локальных запусков                                                                                                                                        |

## Команды выравнивания

```bash
# Python 3.11 окружение
python3.11 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements-dev.txt
pip install requests Flask pydantic pytest pytest-cov

# Node 22.14.0 (через nvm/volta)
nvm use 22.14.0   # .nvmrc добавлен
npm ci

# Go
(cd auth && go test ./...)

# PYTHONPATH для тестов и скриптов
export PYTHONPATH=$PYTHONPATH:.

# Pre-commit
pre-commit install
pre-commit run --all-files
```

## Примечания

- macOS с PEP 668: предпочтительно использовать venv; глобальная установка
  требует `--break-system-packages`.
- Если без GPU: выставить заглушки в `.env` (`DOCLING_GPU_VISIBLE_DEVICES=` и
  т.п.) перед запуском стека.
