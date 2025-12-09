---
title: 'Отладка кода с помощью ИИ'
category: development
difficulty: medium
duration: '15 min'
roles: ['developer']
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-04'
---

# Отладка кода с помощью ИИ

## Цель

Использовать ИИ для быстрого поиска и исправления bugs, понимания error
messages, и debugging сложных проблем.

## Для кого

- **Developers** — все уровни
- **Tech Leads** — помощь junior разработчикам

## ⏱ Время выполнения

5-20 минут в зависимости от сложности бага

## Что вам понадобится

- Доступ к Open WebUI
- Error message / stack trace
- Проблемный код
- **Рекомендуемая модель:** GPT-4o или Claude 3.5

---

## Базовый workflow отладки

### Шаг 1: Опишите проблему

````markdown
У меня [язык/framework] код который выдаёт ошибку:

**Error:** [точный текст ошибки или stack trace]

**Код:** \```[язык] [проблемный код] \```

**Ожидаемое поведение:** [что должно работать] **Фактическое поведение:** [что
происходит]

Найди проблему и предложи исправление.
````

---

## Типы debugging сценариев

### Сценарий 1: Runtime Error

**Промпт:**

````
Python код падает с KeyError:

Error:
KeyError: 'email'
 File "app.py", line 45, in process_user
 email = user_data['email']

Код:
\```python
def process_user(user_data):
 name = user_data['name']
 email = user_data['email'] # Line 45
 return f"{name}: {email}"

users = [
 {'name': 'Alice', 'email': 'alice@example.com'},
 {'name': 'Bob'} # Missing email!
]

for user in users:
 print(process_user(user))
\```

Что не так и как исправить?
````

**ИИ найдёт:**

- Missing key handling
- Предложит `.get()` или try/except
- Покажет пример исправленного кода

---

### Сценарий 2: Logic Error (неправильное поведение)

**Промпт:**

````
Эта функция должна находить все простые числа до N,
но возвращает неправильные результаты:

\```python
def find_primes(n):
 primes = []
 for num in range(2, n):
 is_prime = True
 for i in range(2, num):
 if num % i == 0:
 is_prime = False
 if is_prime:
 primes.append(num)
 return primes

print(find_primes(10)) # Ожидаю: [2, 3, 5, 7]
 # Получаю: [2, 3, 5, 7, 9] - 9 лишнее!
\```

Где ошибка в логике?
````

**ИИ найдёт:**

- Bug в условии (нужно range(2, num) но лучше до sqrt(num))
- Предложит оптимизацию
- Объяснит почему 9 попало в результат

---

### Сценарий 3: Performance Issue

**Промпт:**

````
Эта React функция очень медленная с большими списками:

\```jsx
function UserList({ users }) {
 return (
 <div>
 {users.map(user => (
 <div key={user.id}>
 <UserCard user={user} />
 <ExpensiveComponent data={calculateStats(user)} />
 </div>
 ))}
 </div>
 );
}
\```

users array содержит 10,000+ элементов.
Компонент re-renders часто и тормозит UI.

Найди performance problems и предложи solutions.
````

**ИИ найдёт:**

- calculateStats() вызывается на каждом render
- Нужен useMemo или вынести вычисления
- Возможно virtualization для большого списка
- Missing React.memo для UserCard

---

### Сценарий 4: Непонятная ошибка

**Промпт:**

````
Получаю странную ошибку в Node.js приложении:

Error: Cannot read property 'length' of undefined

Stack trace:
at processArray (utils.js:23:15)
at handleRequest (controller.js:67:10)
at Layer.handle [as handle_request] (express/lib/router/layer.js:95:5)

Код из utils.js:23:
\```javascript
function processArray(data) {
 return data.items.length; // Line 23
}
\```

Код из controller.js:67:
\```javascript
async function handleRequest(req, res) {
 const result = await fetchData(req.params.id);
 const count = processArray(result); // Line 67
 res.json({ count });
}
\```

Иногда работает, иногда падает. В чём может быть проблема?
````

**ИИ найдёт:**

- fetchData() иногда возвращает null/undefined
- Нужна проверка на undefined
- Возможно async/await issue
- Предложит defensive programming

---

## Продвинутые техники debugging

### Техника 1: Root Cause Analysis

**Промпт:**

````
Проведи root cause analysis этого бага:

**Симптом:** API endpoint иногда возвращает 500 error

**Error log:**
TypeError: Cannot convert undefined to object
 at JSON.stringify(<anonymous>)

**Контекст:**
- Происходит ~1% requests
- Только на production
- Работает на staging

**Код endpoint:**
\```javascript
app.get('/api/user/:id', async (req, res) => {
 const user = await db.findUser(req.params.id);
 const profile = await getUserProfile(user.id);
 res.json({ user, profile });
});
\```

Найди возможные root causes этой intermittent проблемы.
````

**ИИ проанализирует:**

- Race conditions
- Database connection issues
- Null handling
- Async timing problems

---

### Техника 2: Comparative Debugging

**Промпт:**

````
У меня две версии функции:
- Версия A работает но медленная
- Версия B быстрая но иногда даёт wrong results

Версия A (медленная но правильная):
\```python
def process(data):
 result = []
 for item in data:
 if is_valid(item):
 processed = transform(item)
 result.append(processed)
 return result
\```

Версия B (быстрая но buggy):
\```python
def process(data):
 return [transform(item) for item in data if is_valid(item)]
\```

Иногда Version B даёт меньше элементов чем A.
Почему и как исправить сохранив performance?
````

---

### Техника 3: Error Pattern Recognition

**Промпт:**

```
Вот 5 похожих errors из разных частей кода:

Error 1: TypeError: Cannot read property 'map' of undefined (users.js:34)
Error 2: TypeError: items.filter is not a function (products.js:56)
Error 3: TypeError: data.reduce is not a function (analytics.js:89)

Все три происходят после API calls.

Есть ли общий pattern? Какова вероятная root cause?
Как предотвратить это systematically?
```

---

## Debugging по типу языка/framework

### JavaScript/Node.js

**Prompt template:**

````
Debug этот [JS/Node.js/React] код:

Error: [error message]

Код:
\```javascript
[код]
\```

Контекст:
- Node version: [version]
- Framework: [Express/React/etc]
- Environment: [development/production]

Особое внимание на:
- Async/await issues
- Callback hell
- Promise rejection
- Memory leaks (если applicable)
````

### Python

**Prompt template:**

````
Python код выдаёт [exception type]:

Traceback:
[full traceback]

Код:
\```python
[код]
\```

Python version: [version]
Libraries: [список]

Проверь:
- Type mismatches
- List/dict indexing
- Import issues
- Exception handling
````

### TypeScript

**Prompt template:**

````
TypeScript compilation error:

Error TS[code]: [message]
at [file:line:column]

Код:
\```typescript
[код]
\```

Контекст:
- TypeScript version: [version]
- tsconfig strictness: [strict/loose]

Найди type issues и предложи правильные types.
````

---

## Pro Tips для debugging

### Tip 1: Minimal Reproducible Example

Выделите минимальный код воспроизводящий проблему:

````
Вместо всего файла (200 строк):
"Вот упрощённый пример воспроизводящий проблему:
\```
[10-20 строк minimal example]
\```"
````

### Tip 2: Пошаговое выполнение

```
"Пройдись по этому коду step-by-step и покажи:
- Состояние variables на каждом шаге
- Где именно происходит ошибка
- Почему это приводит к exception"
```

### Tip 3: Multiple Hypotheses

```
"Дай 3 возможные причины этой проблемы,
упорядоченные по вероятности.
Для каждой объясни как проверить эту гипотезу."
```

### Tip 4: Defensive Code Review

```
"Какие edge cases этот код не обрабатывает?
Что может пойти не так в production?
Предложи defensive programming improvements."
```

---

## Важные примечания

### Что ИИ делает хорошо:

Синтаксические ошибки Типовые patterns ошибок Известные bugs в libraries Best
practices violations Error message interpretation

### Где ИИ может ошибаться:

Специфичный business logic Complex race conditions Environment-specific issues
Database-specific quirks Network/infrastructure problems

**Always verify AI suggestions before applying!**

---

## Чек-лист debugging сессии

- [ ] Собрал полный error message/stack trace
- [ ] Выделил minimal reproducible code
- [ ] Описал expected vs actual behavior
- [ ] Указал environment details
- [ ] Получил предложение от ИИ
- [ ] Понял логику исправления
- [ ] Протестировал fix
- [ ] Добавил tests для этого case
- [ ] Задокументировал если нужно

---

## Дальнейшее изучение

- [Code Review with AI](code-review-with-ai.md)
- [Write Unit Tests](write-unit-tests.md)
- [Prompting Fundamentals](../../fundamentals/prompting-fundamentals.md)

---

**Следующий сценарий:** [Write Unit Tests →](write-unit-tests.md)
