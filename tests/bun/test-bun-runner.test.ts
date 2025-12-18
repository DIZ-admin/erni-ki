import { test, expect, describe } from 'bun:test';

describe('Bun Test Runner', () => {
  test('basic assertions', () => {
    expect(2 + 2).toBe(4);
    expect('hello').toMatch(/ello/);
    expect([1, 2, 3]).toHaveLength(3);
  });

  test('async operations', async () => {
    const promise = Promise.resolve(42);
    await expect(promise).resolves.toBe(42);
  });

  test('object matching', () => {
    const user = { name: 'Alice', age: 30 };
    expect(user).toMatchObject({ name: 'Alice' });
    expect(user).toHaveProperty('age');
  });

  test('array operations', () => {
    const numbers = [1, 2, 3, 4, 5];
    expect(numbers).toContain(3);
    expect(numbers.length).toBeGreaterThan(0);
  });
});

describe('Performance test', () => {
  test('should complete quickly', () => {
    const start = Date.now();
    let sum = 0;
    for (let i = 0; i < 1000000; i++) {
      sum += i;
    }
    const duration = Date.now() - start;
    expect(duration).toBeLessThan(1000);
    expect(sum).toBeGreaterThan(0);
  });
});
