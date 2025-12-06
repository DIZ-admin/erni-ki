---
title: 'Написание Unit Tests с помощью ИИ'
category: development
difficulty: medium
duration: '15 min'
roles: ['developer', 'qa']
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-04'
---

# Написание Unit Tests с помощью ИИ

## Цель

Использовать ИИ для быстрого создания comprehensive unit tests, покрытия edge
cases, и улучшения test quality.

## Для кого

- **Developers** — ускорить TDD workflow
- **QA Engineers** — создать test scenarios
- **Tech Leads** — улучшить test coverage

## ⏱ Время выполнения

10-20 минут в зависимости от сложности

## Что вам понадобится

- Доступ к Open WebUI
- Код функции/класса для тестирования
- **Рекомендуемая модель:** GPT-4o или Claude 3.5

---

## Базовый шаблон промпта

````markdown
Напиши unit tests для этой [язык] функции:

**Функция:** \```[язык] [код функции] \```

**Framework:** [Jest/Pytest/JUnit/etc] **Coverage нужен:**

- Happy path
- Edge cases
- Error handling
- [специфичные сценарии]

**Формат:**

- Описательные test names
- Arrange-Act-Assert pattern
- Каждый test тестирует одну вещь
````

---

## Примеры по типам функций

### Пример 1: Простая функция

**Промпт:**

````
Напиши unit tests для этой Python функции:

\```python
def calculate_discount(price, discount_percent):
 """Calculate final price after discount."""
 if discount_percent < 0 or discount_percent > 100:
 raise ValueError("Discount must be between 0 and 100")
 return price * (1 - discount_percent / 100)
\```

Framework: pytest

Покрой:
1. Normal случаи (разные проценты)
2. Edge cases (0%, 100%)
3. Invalid input (negative, > 100)
4. Boundary values

Используй descriptive test names и parametrize где возможно.
````

**Результат:** Получите 8-10 тестов с хорошим coverage

---

### Пример 2: Класс с методами

**Промпт:**

````
Напиши unit tests для этого TypeScript класса:

\```typescript
class ShoppingCart {
 private items: CartItem[] = [];

 addItem(item: CartItem): void {
 this.items.push(item);
 }

 removeItem(itemId: string): boolean {
 const index = this.items.findIndex(i => i.id === itemId);
 if (index === -1) return false;
 this.items.splice(index, 1);
 return true;
 }

 getTotal(): number {
 return this.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
 }

 clear(): void {
 this.items = [];
 }
}
\```

Framework: Jest
TypeScript: strict mode

Для каждого метода:
- Happy path
- Edge cases
- State verification

Используй beforeEach для setup.
````

---

### Пример 3: Async функция

**Промпт:**

````
Напиши unit tests для async функции:

\```javascript
async function fetchUserData(userId) {
 const response = await fetch(`/api/users/${userId}`);
 if (!response.ok) {
 throw new Error(`User ${userId} not found`);
 }
 return await response.json();
}
\```

Framework: Jest
Mock: fetch API

Tests нужны для:
1. Successful fetch
2. 404 error
3. 500 error
4. Network error
5. Malformed JSON response

Используй jest.mock() для fetch.
Покажи как setup и teardown mocks.
````

---

## Продвинутые сценарии

### Сценарий 1: TDD - Tests First

**Промпт:**

```
Я хочу написать функцию validateEmail(email).

Сначала создай comprehensive test suite:
- Valid emails (разные форматы)
- Invalid emails (без @, без domain, etc)
- Edge cases (empty, null, numbers)

Framework: Jest
НЕ пиши implementation, только tests!

Затем я реализую функцию чтобы пройти tests.
```

**Результат:** Test suite для TDD approach

---

### Сценарий 2: Improve Existing Tests

**Промпт:**

````
Вот мои текущие tests:

\```javascript
test('adds numbers', () => {
 expect(add(2, 3)).toBe(5);
});

test('works with negatives', () => {
 expect(add(-1, 1)).toBe(0);
});
\```

Что ещё нужно протестировать?
Какие edge cases я пропустил?
Предложи 5-7 additional tests.
````

---

### Сценарий 3: Integration Test Scenarios

**Промпт:**

````
У меня есть API endpoint:

\```javascript
app.post('/api/orders', async (req, res) => {
 const { userId, items } = req.body;

 const user = await User.findById(userId);
 if (!user) return res.status(404).json({ error: 'User not found' });

 const total = items.reduce((sum, item) => sum + item.price, 0);
 const order = await Order.create({ userId, items, total });

 res.status(201).json(order);
});
\```

Напиши integration test scenarios (не полные tests, только scenarios):
1. Какие happy paths тестировать?
2. Какие error cases?
3. Какие edge cases?
4. Что мокать, что реально вызывать?

Framework: Supertest + Jest
````

---

## Техники для лучших tests

### Техника 1: Parametrized Tests

**Промпт:**

```
Напиши parametrized tests для функции isPalindrome():

Test cases:
- "racecar" → true
- "hello" → false
- "A man a plan a canal Panama" → true (ignore spaces/case)
- "" → true
- "a" → true

Используй pytest.mark.parametrize или Jest test.each.
```

### Техника 2: Test Coverage Analysis

**Промпт:**

````
Вот моя функция и мои tests.

Функция:
\```python
[код]
\```

Tests:
\```python
[тесты]
\```

Какие code paths не покрыты?
Какой примерный coverage % у меня сейчас?
Какие tests добавить для 100% coverage?
````

### Техника 3: Mocking Strategy

**Промпт:**

```
Эта функция зависит от:
- Database calls
- External API
- File system
- Random values

Как правильно замокать каждую dependency?
Покажи примеры mocks для Jest.
```

### Техника 4: Test Data Builders

**Промпт:**

````
Мои tests создают много test objects.
Напиши test data builders/factories для:

\```typescript
interface User {
 id: string;
 email: string;
 name: string;
 role: 'admin' | 'user';
 createdAt: Date;
}
\```

С reasonable defaults и возможностью override.
````

---

## Специфичные фреймворки

### Jest (JavaScript/TypeScript)

**Prompt template:**

````
Напиши Jest tests для [функция/класс]:

\```typescript
[код]
\```

Используй:
- describe/it structure
- beforeEach/afterEach для setup
- jest.fn() для mocks
- expect().toEqual/toBe/etc
- jest.spyOn() если нужно

Каждый test должен быть independent.
````

### Pytest (Python)

**Prompt template:**

````
Напиши pytest tests для:

\```python
[код]
\```

Используй:
- pytest fixtures для setup
- pytest.raises() для exceptions
- pytest.mark.parametrize для data-driven tests
- monkeypatch для mocking если нужно

Следуй AAA pattern (Arrange-Act-Assert).
````

### JUnit (Java)

**Prompt template:**

````
Напиши JUnit 5 tests для:

\```java
[код]
\```

Используй:
- @BeforeEach/@AfterEach
- @ParameterizedTest для multiple inputs
- Mockito для mocking
- AssertJ для assertions (fluent)

Следуй Given-When-Then structure в комментариях.
````

---

## Best Practices

### DO: Descriptive Names

```
 ХОРОШО:
test_calculate_discount_with_valid_percentage_returns_correct_price()
test_calculate_discount_with_negative_percent_raises_ValueError()

 ПЛОХО:
test1()
test_discount()
```

### DO: One Assert Per Test

```
 ХОРОШО:
test('returns sum of two numbers') {
 expect(add(2, 3)).toBe(5);
}

test('handles negative numbers') {
 expect(add(-2, 3)).toBe(1);
}

 ПЛОХО:
test('math operations') {
 expect(add(2, 3)).toBe(5);
 expect(add(-2, 3)).toBe(1);
 expect(multiply(2, 3)).toBe(6); // unrelated!
}
```

### DO: Independent Tests

```
 Tests не зависят друг от друга
 Можно запускать в любом порядке
 Каждый test делает свой setup

 Test 2 зависит от state после Test 1
```

### DO: Test Behavior, Not Implementation

```
 ХОРОШО:
test('shopping cart calculates correct total')

 ПЛОХО:
test('shopping cart uses reduce() to sum prices')
[это implementation detail]
```

---

## Troubleshooting Tests

### ИИ создал flaky tests

**Промпт:**

````
Эти tests иногда проходят, иногда падают:

\```javascript
[тесты]
\```

Найди:
1. Race conditions
2. Timing issues
3. Shared state
4. Non-deterministic behavior

Предложи stable версию.
````

### ИИ создал слишком много mocks

**Промпт:**

````
Эти tests очень coupled к implementation из-за mocks:

\```python
[тесты с множеством моков]
\```

Как упростить?
Какие dependencies реально протестировать вместо мокинга?
````

### Tests слишком медленные

**Промпт:**

````
Мой test suite занимает 5 минут.
Вот пример медленного теста:

\```javascript
[медленный тест]
\```

Как оптимизировать?
- Что мокать?
- Parallel execution?
- Test data setup improvements?
````

---

## Чек-лист качественного Test Suite

### Coverage:

- [ ] Happy path cases
- [ ] Edge cases (null, empty, boundary values)
- [ ] Error cases (exceptions, validation)
- [ ] Different input types/combinations

### Quality:

- [ ] Descriptive test names
- [ ] One logical assertion per test
- [ ] Independent tests (no shared state)
- [ ] Fast execution (<1s per test)
- [ ] Deterministic (no flakiness)

### Structure:

- [ ] Proper setup/teardown
- [ ] Mocks for external dependencies
- [ ] Clear Arrange-Act-Assert sections
- [ ] Grouped by feature/class

### Maintainability:

- [ ] DRY (test helpers/fixtures)
- [ ] Easy to understand
- [ ] Easy to modify
- [ ] Good failure messages

---

## Дальнейшее изучение

- [Code Review with AI](code-review-with-ai.md)
- [Debug Code](debug-code.md)
- [Prompting Fundamentals](../../fundamentals/prompting-fundamentals.md)

---

**Следующий сценарий:** [Generate Documentation →](generate-documentation.md)
