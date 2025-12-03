import { describe, expect, it } from 'vitest';
import testUtils from '../utils/test-utils';

describe('test utils bootstrap', () => {
  it('exposes helper factory methods', () => {
    // Bun test runner does not execute Vitest setup, ensure global is populated
    if (!globalThis.testUtils) {
      globalThis.testUtils = testUtils;
    }
    expect(globalThis.testUtils).toBeDefined();
    const req = globalThis.testUtils.createMockRequest({ method: 'POST', url: '/mock' });
    const res = globalThis.testUtils.createMockResponse();
    expect(req.method).toBe('POST');
    expect(req.url).toBe('/mock');
    res.status(201).json({ ok: true });
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({ ok: true });
  });

  it('sets deterministic environment variables for tests', () => {
    expect(process.env.NODE_ENV).toBe('test');
    expect(process.env.JWT_SECRET).toMatch(/test-jwt-secret/);
    expect(process.env.WEBUI_SECRET_KEY).toMatch(/test-webui-secret/);
    expect(process.env.DATABASE_URL).toContain('postgresql://');
    expect(process.env.REDIS_URL).toContain('redis://');
  });
});
