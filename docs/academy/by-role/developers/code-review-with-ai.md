---
title: 'Code Review с помощью ИИ'
category: development
difficulty: medium
duration: '15 min'
roles: ['developer', 'tech-lead']
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-04'
---

# Code Review с помощью ИИ

## Цель

Использовать ИИ для ускорения и улучшения качества code review: находить bugs,
улучшать читаемость кода, проверять соответствие best practices.

## Для кого

- **Разработчики:** проверить свой код перед PR
- **Tech Leads:** быстрый pre-review перед детальной проверкой
- **Code Reviewers:** помощь в поиске неочевидных проблем

## ⏱ Время выполнения

10-15 минут на code review session

## Что вам понадобится

- Доступ к Open WebUI
- Код, который нужно проверить
- **Рекомендуемая модель:** Claude 3.5 Sonnet (более внимательна к деталям)

## Пошаговая инструкция

### Шаг 1: Подготовка кода

**ВАЖНО:** Убедитесь, что код не содержит:

- Proprietary алгоритмы
- Секретные ключи или пароли
- Конфиденциальные данные клиентов
- Internal API endpoints

Безопасно для review:

- Общая логика приложения
- Utility functions
- UI components
- Open source contributions
- Обучающие примеры

### Шаг 2: Базовый Code Review

**Prompt шаблон:**

````
Проведи code review этого [язык] кода.
Проверь на:
1. Bugs и потенциальные ошибки
2. Code smells и anti-patterns
3. Улучшения читаемости
4. Best practices для [framework/library]
5. Потенциальные проблемы производительности

Код:
```[язык]
[ваш код здесь]
\```

Структурируй ответ по категориям с примерами исправлений.
````

**Пример:**

````
Проведи code review этого Python кода.
Проверь на bugs, читаемость, и best practices.

Код:
\```python
def process_users(users):
 result = []
 for user in users:
 if user['age'] > 18:
 result.append({'name': user['name'], 'email': user['email']})
 return result
\```
````

**Ожидаемый результат:** ИИ найдёт:

- Missing error handling
- Возможные KeyError exceptions
- Улучшения (list comprehension)
- Type hints отсутствуют

### Шаг 3: Фокусированная проверка безопасности

**Prompt для security review:**

````
Проверь этот код на security уязвимости:
1. SQL injection
2. XSS vulnerabilities
3. Authentication/authorization issues
4. Data leakage
5. Input validation

Код:
\```[язык]
[код]
\```

Для каждой найденной уязвимости:
- Опиши риск
- Покажи пример эксплуатации
- Предложи безопасное решение
````

**Пример:**

````
Проверь этот Node.js код на security проблемы:

\```javascript
app.get('/user/:id', (req, res) => {
 const userId = req.params.id;
 const query = `SELECT * FROM users WHERE id = ${userId}`;
 db.query(query, (err, result) => {
 res.json(result);
 });
});
\```
````

### Шаг 4: Performance Review

**Prompt для performance:**

````
Проанализируй производительность этого кода:
1. Time complexity (Big O)
2. Memory usage
3. Potential bottlenecks
4. Optimization opportunities

Код:
\```[язык]
[код]
\```

Предложи оптимизированную версию с объяснением улучшений.
````

### Шаг 5: Проверка на соответствие стандартам

**Prompt для style/conventions:**

````
Проверь соответствие этого кода стандартам:
- [PEP 8 / Airbnb Style Guide / Google Style Guide]
- Naming conventions
- Code organization
- Documentation standards

Код:
\```[язык]
[код]
\```

Укажи все отклонения от стандартов с примерами исправлений.
````

## Продвинутые техники

### Техника 1: Comparative Review

Сравните два подхода:

````
У меня два варианта решения задачи.
Сравни их по:
1. Читаемости
2. Производительности
3. Maintainability
4. Тестируемости

Вариант 1:
\```[код 1]
\```

Вариант 2:
\```[код 2]
\```

Какой лучше и почему?
````

### Техника 2: Context-Aware Review

Добавьте контекст проекта:

````
Контекст: Это e-commerce приложение с высокой нагрузкой (1M+ users).
Используем: React 18, TypeScript, Node.js, PostgreSQL.

Проверь этот компонент на:
- Performance для больших списков
- Accessibility (a11y)
- Error boundaries
- Loading states

Код:
\```typescript
[компонент]
\```
````

### Техника 3: Test Coverage Analysis

````
Проанализируй этот код и:
1. Определи, какие edge cases не покрыты
2. Предложи, какие unit tests нужны
3. Напиши 3-5 примеров test cases

Код:
\```[код]
\```
````

## Специализированные Reviews

### React/Frontend Component Review

````
Code review этого React компонента:
1. Hooks usage (правильное использование)
2. Re-render optimization
3. Props drilling issues
4. Accessibility
5. Error handling
6. TypeScript types quality

Компонент:
\```typescript
[код]
\```
````

### API Endpoint Review

````
Review этого API endpoint:
1. RESTful principles
2. Error handling
3. Input validation
4. Authentication/authorization
5. Rate limiting considerations
6. Response format

Код:
\```[код]
\```
````

### Database Query Review

````
Оптимизируй этот SQL query:
1. Index usage
2. JOIN efficiency
3. N+1 problem
4. Query plan analysis

Query:
\```sql
[query]
\```
````

## Как интерпретировать результаты

### Приоритизация найденных проблем

**Критичные (исправить немедленно):**

- Security vulnerabilities
- Data loss bugs
- Memory leaks

**Важные (исправить до merge):**

- [WARNING] Logic errors
- [WARNING] Performance issues
- [WARNING] Error handling gaps

**Желательные (можно отложить):**

- [OK] Style improvements
- [OK] Minor refactoring
- [OK] Documentation enhancements

### Проверка ИИ рекомендаций

**Не все предложения ИИ корректны!**

**Всегда проверяйте:**

1. Применимы ли исправления к вашему контексту
2. Не ломают ли они существующую функциональность
3. Соответствуют ли best practices вашей команды
4. Нет ли trade-offs которые ИИ не учла

## Чек-лист Code Review

### Перед отправкой в ИИ:

- [ ] Код анонимизирован (no secrets, proprietary info)
- [ ] Выбрана подходящая модель (Claude для детального review)
- [ ] Определены конкретные аспекты для проверки

### После получения результатов:

- [ ] Критичные issues помечены для немедленного исправления
- [ ] Проверены все предложения ИИ на корректность
- [ ] Решено, что применять, что отложить
- [ ] Code updated и протестирован

### Финальная проверка:

- [ ] Все security issues исправлены
- [ ] Tests добавлены/обновлены
- [ ] Documentation обновлена (если нужно)
- [ ] Готов для human code review

## Возможные проблемы

### Проблема 1: ИИ предлагает избыточные изменения

**Симптом:** Слишком много мелких style improvements

**Решение:**

```
"Фокусируйся только на critical и high-priority issues.
Игнорируй minor style improvements."
```

### Проблема 2: ИИ не понимает специфику фреймворка

**Симптом:** Предлагает generic решения

**Решение:** Добавьте контекст:

```
"Мы используем [framework] версия [X].
Предлагай решения специфичные для этого стека."
```

### Проблема 3: Ложные срабатывания

**Симптом:** ИИ находит "проблемы" которых нет

**Решение:**

- Объясните контекст лучше
- Попросите уточнить конкретную "проблему"
- Проконсультируйтесь с коллегой

## Workflow Integration

### Pre-PR Review Process

```
1. Разработчик завершает feature
2. Self-review с ИИ (10-15 мин)
3. Исправление critical issues
4. Human code review request
5. Финальные правки
6. Merge
```

### Pair Programming with AI

```
Во время разработки:
1. Пишете функцию
2. Быстрый ИИ review (2-3 мин)
3. Исправляете на ходу
4. Меньше issues в финальном PR
```

## Примеры из реальной практики

### Пример 1: React Hook Bug

**Код:**

```typescript
function useUsers() {
  const [users, setUsers] = useState([]);

  useEffect(() => {
    fetchUsers().then(setUsers);
  }); // Missing dependency array!

  return users;
}
```

**ИИ нашла:**

- Missing dependency array → infinite loop
- No error handling
- No loading state

### Пример 2: SQL Injection

**Код:**

```javascript
const query = `SELECT * FROM products WHERE id = ${req.query.id}`;
```

**ИИ нашла:**

- SQL injection vulnerability
- Предложила prepared statements

### Пример 3: Performance Issue

**Код:**

```python
for item in large_list:
 if item.id in database_query(): # N+1 query!
 process(item)
```

**ИИ нашла:**

- N+1 query problem
- Предложила batch query optimization

## Дальнейшее изучение

- [Отладка кода с ИИ](debug-code.md) — fix bugs faster
- [Написание тестов с ИИ](write-unit-tests.md) — automate testing
- [Best Practices](../../fundamentals/index.md) — improve prompting

---

## Пример полного workflow

```
# 1. Initial Review
"Проведи code review этого TypeScript React компонента.
Фокусируйся на hooks, performance, и TypeScript types."

# 2. Security Check
"Теперь проверь на security issues: XSS, data leaks, validation."

# 3. Performance Analysis
"Проанализируй performance этого компонента для списка из 10,000 items."

# 4. Test Suggestions
"Какие unit tests нужны для покрытия основных сценариев?"

# 5. Final Polish
"Предложи улучшения читаемости и maintainability."
```

---

**Следующий сценарий:** [Отладка кода →](debug-code.md)

**Вернуться:** [Developers Hub →](index.md)
