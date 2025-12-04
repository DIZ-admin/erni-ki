import { defineConfig } from 'vitest/config';

export default defineConfig({
  // Test settings for the erni-ki project
  test: {
    // Global settings
    globals: true,
    environment: 'node',

    // Code coverage target: ≥90%
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      reportsDirectory: './coverage',
      // Include source scripts and unit tests that exercise them
      include: [
        'tests/utils/**/*.{ts,js}',
        'types/**/*.ts',
        'tests/unit/**/*.{ts,js}',
        'tests/integration/**/*.{ts,js}',
      ],
      exclude: [
        'node_modules/**',
        'dist/**',
        'build/**',
        'coverage/**',
        '**/*.config.*',
        '**/*.d.ts',
        'auth/**',
        'data/**',
        'logs/**',
        'docs/**',
        'tests/e2e/**',
        'playwright-report/**',
        'playwright-artifacts/**',
        'scripts/**',
      ],
      thresholds: {
        global: {
          branches: 90,
          functions: 90,
          lines: 90,
          statements: 90,
        },
      },
      // Vitest 4.0: coverage.all removed; use coverage.include instead
      skipFull: false,
    },

    // Execution settings
    testTimeout: 10000,
    hookTimeout: 10000,
    teardownTimeout: 5000,

    // Test discovery patterns
    include: ['tests/unit/**/*.{test,spec}.{ts,js}', 'tests/integration/**/*.{test,spec}.{ts,js}'],

    // Exclude E2E tests (run via Playwright)
    exclude: [
      'node_modules/**',
      'dist/**',
      'build/**',
      'auth/**',
      'data/**',
      'logs/**',
      'tests/e2e/**', // E2E tests run via Playwright
      'playwright-report/**',
      'playwright-artifacts/**',
      'scripts/language-check.cjs', // executed as a subprocess; not instrumentable by Vitest
    ],

    // Reporters
    reporters: ['verbose', 'json', 'html'],
    outputFile: {
      json: './coverage/test-results.json',
      html: './coverage/test-results.html',
    },

    // Parallel execution
    // Vitest 4.0: poolOptions removed; all options are now top-level
    pool: 'threads',
    isolate: true, // Isolation between tests (previously poolOptions.threads.isolate)
    // singleThread: false equals maxWorkers > 1 (default)

    // Mocking settings
    mockReset: true,
    clearMocks: true,
    restoreMocks: true,

    // TypeScript settings
    typecheck: {
      enabled: true,
      tsconfig: './tsconfig.json',
    },

    // Test environment variables
    env: {
      NODE_ENV: 'test',
      VITEST: 'true',
    },

    // Configuration setup files
    setupFiles: ['./tests/setup.ts'],

    // Global setup
    globalSetup: ['./tests/global-setup.ts'],
  },

  // Module resolution
  resolve: {
    alias: {
      '@': './types',
    },
  },

  // File handling
  define: {
    __TEST__: true,
  },

  // Dependency optimization
  optimizeDeps: {
    include: ['vitest/globals'],
  },
});
