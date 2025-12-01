// Global test setup for the erni-ki project
import { afterAll, afterEach, beforeAll, beforeEach, vi } from 'vitest';

import testUtils from './utils/test-utils';

// Keep original console methods
const originalConsoleLog = console.log;
const originalConsoleWarn = console.warn;
const originalConsoleError = console.error;

// Configure environment variables for tests
beforeAll(() => {
  // Set test environment variables
  process.env.NODE_ENV = 'test';
  process.env.JWT_SECRET = 'test-jwt-secret-key-for-testing-only';
  process.env.WEBUI_SECRET_KEY = 'test-webui-secret-key-for-testing-only';
  process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test_db';
  process.env.REDIS_URL = 'redis://localhost:6379/1';

  // Silence logging during tests
  console.log = () => {};
  console.warn = () => {};
  console.error = () => {};
});

// Cleanup after all tests
afterAll(() => {
  // Restore console originals
  console.log = originalConsoleLog;
  console.warn = originalConsoleWarn;
  console.error = originalConsoleError;
});

// Setup before each test
beforeEach(() => {
  // Clear all mocks
  vi.clearAllMocks();

  // Reset module state
  vi.resetModules();
});

// Cleanup after each test
afterEach(() => {
  // Restore all mocks
  vi.restoreAllMocks();
});

// Global utilities for tests
globalThis.testUtils = testUtils;

// Configure fetch for tests (mocked)
global.fetch = vi.fn();

// NOTE: Do not enable fake timers globally.
// In individual tests that need fake timers:
// beforeEach(() => { vi.useFakeTimers(); });
// afterEach(() => { vi.useRealTimers(); });

export {};
