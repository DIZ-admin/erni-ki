/**
 * Docker Compose Integration Smoke Tests
 *
 * These tests verify that core services in compose.test.yml are healthy
 * and responding correctly.
 *
 * Prerequisites:
 *   docker compose -f compose.test.yml up -d --wait
 *
 * Run:
 *   INTEGRATION_TEST=1 bun test tests/integration/docker-compose-smoke.test.ts
 */
import { describe, expect, it, beforeAll } from 'vitest';
import { execSync } from 'node:child_process';

// Skip tests unless INTEGRATION_TEST is set
const isIntegrationTest = process.env.INTEGRATION_TEST === '1';
const testDescribe = isIntegrationTest ? describe : describe.skip;

// Service URLs (mapped ports from compose.test.yml)
const SERVICES = {
  auth: 'http://localhost:19090',
  prometheus: 'http://localhost:19091',
  grafana: 'http://localhost:13000',
} as const;

// Timeout for service health checks
const HEALTH_CHECK_TIMEOUT = 5000;

/**
 * Helper to make HTTP request with timeout
 */
async function fetchWithTimeout(
  url: string,
  options: RequestInit = {},
  timeout = HEALTH_CHECK_TIMEOUT,
): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal,
    });
    return response;
  } finally {
    clearTimeout(timeoutId);
  }
}

/**
 * Helper to check if Docker container is healthy
 */
function isContainerHealthy(serviceName: string): boolean {
  try {
    const result = execSync(`docker compose -f compose.test.yml ps --format json ${serviceName}`, {
      encoding: 'utf-8',
      timeout: 10000,
    });
    const container = JSON.parse(result);
    return container.Health === 'healthy' || container.State === 'running';
  } catch {
    return false;
  }
}

testDescribe('Docker Compose Integration Tests', () => {
  beforeAll(() => {
    // Verify Docker is available
    try {
      execSync('docker info', { stdio: 'ignore', timeout: 5000 });
    } catch {
      throw new Error('Docker is not available. Please start Docker first.');
    }
  });

  describe('Data Layer', () => {
    it('PostgreSQL container is healthy', () => {
      expect(isContainerHealthy('db')).toBe(true);
    });

    it('Redis container is healthy', () => {
      expect(isContainerHealthy('redis')).toBe(true);
    });
  });

  describe('Auth Service', () => {
    it('auth container is healthy', () => {
      expect(isContainerHealthy('auth')).toBe(true);
    });

    it('responds to /health endpoint', async () => {
      const res = await fetchWithTimeout(`${SERVICES.auth}/health`);
      expect(res.status).toBe(200);
    });

    it('rejects request without auth header', async () => {
      const res = await fetchWithTimeout(`${SERVICES.auth}/validate`);
      expect([401, 403]).toContain(res.status);
    });

    it('rejects invalid bearer token', async () => {
      const res = await fetchWithTimeout(`${SERVICES.auth}/validate`, {
        headers: {
          Authorization: 'Bearer invalid-token',
        },
      });
      expect([401, 403]).toContain(res.status);
    });
  });

  describe('Monitoring Stack', () => {
    it('Prometheus container is healthy', () => {
      expect(isContainerHealthy('prometheus')).toBe(true);
    });

    it('Prometheus is ready', async () => {
      const res = await fetchWithTimeout(`${SERVICES.prometheus}/-/ready`);
      expect(res.status).toBe(200);
    });

    it('Prometheus is healthy', async () => {
      const res = await fetchWithTimeout(`${SERVICES.prometheus}/-/healthy`);
      expect(res.status).toBe(200);
    });

    it('Prometheus API returns targets', async () => {
      const res = await fetchWithTimeout(`${SERVICES.prometheus}/api/v1/targets`);
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.status).toBe('success');
    });

    it('Grafana container is healthy', () => {
      expect(isContainerHealthy('grafana')).toBe(true);
    });

    it('Grafana health endpoint returns OK', async () => {
      const res = await fetchWithTimeout(`${SERVICES.grafana}/api/health`);
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.database).toBe('ok');
    });
  });
});

testDescribe('Docker Compose Configuration', () => {
  it('compose.test.yml is valid', () => {
    const result = execSync('docker compose -f compose.test.yml config --quiet 2>&1 || true', {
      encoding: 'utf-8',
      timeout: 10000,
    });
    // Should not contain errors
    expect(result).not.toContain('error');
  });

  it('all services can be listed', () => {
    const result = execSync('docker compose -f compose.test.yml config --services', {
      encoding: 'utf-8',
      timeout: 10000,
    });
    const services = result.trim().split('\n');
    expect(services).toContain('db');
    expect(services).toContain('redis');
    expect(services).toContain('auth');
    expect(services).toContain('prometheus');
    expect(services).toContain('grafana');
  });
});
