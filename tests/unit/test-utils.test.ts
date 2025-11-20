import { describe, expect, it } from 'vitest';
import testUtils, {
  createMockRequest,
  createMockResponse,
  sleep,
  waitFor,
} from '../../tests/utils/test-utils';

describe('test-utils', () => {
  describe('createMockRequest', () => {
    it('should create a default mock request', () => {
      const req = createMockRequest();
      expect(req.method).toBe('GET');
      expect(req.url).toBe('/');
      expect(req.headers).toEqual({});
      expect(req.body).toEqual({});
    });

    it('should override defaults with provided options', () => {
      const req = createMockRequest({
        method: 'POST',
        url: '/api/test',
        body: { foo: 'bar' },
        headers: { 'content-type': 'application/json' },
      });
      expect(req.method).toBe('POST');
      expect(req.url).toBe('/api/test');
      expect(req.body).toEqual({ foo: 'bar' });
      expect(req.headers).toEqual({ 'content-type': 'application/json' });
    });
  });

  describe('createMockResponse', () => {
    it('should create a mock response with chainable methods', () => {
      const res = createMockResponse();

      // Test chaining
      res.status(201).json({ success: true });

      expect(res.statusCode).toBe(201);
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith({ success: true });
    });

    it('should handle redirects', () => {
      const res = createMockResponse();
      res.redirect('/login');
      expect(res.redirect).toHaveBeenCalledWith('/login');
    });

    it('should allow setting headers', () => {
      const res = createMockResponse();
      res.header('X-Test', 'value');
      expect(res.header).toHaveBeenCalledWith('X-Test', 'value');
    });
  });

  describe('sleep', () => {
    it('should wait for the specified duration', async () => {
      vi.useRealTimers();
      const start = Date.now();
      await sleep(50);
      const duration = Date.now() - start;
      expect(duration).toBeGreaterThanOrEqual(45); // Allow small variance
      vi.useFakeTimers();
    });
  });

  describe('waitFor', () => {
    it('should resolve when condition becomes true', async () => {
      vi.useRealTimers();
      let condition = false;
      setTimeout(() => {
        condition = true;
      }, 20);

      await waitFor(() => condition);
      expect(condition).toBe(true);
      vi.useFakeTimers();
    });

    it('should throw error on timeout', async () => {
      vi.useRealTimers();
      await expect(waitFor(() => false, 50)).rejects.toThrow('Timeout waiting for condition');
      vi.useFakeTimers();
    });
  });

  describe('default export', () => {
    it('should export all utilities', () => {
      expect(testUtils.createMockRequest).toBeDefined();
      expect(testUtils.createMockResponse).toBeDefined();
      expect(testUtils.waitFor).toBeDefined();
      expect(testUtils.sleep).toBeDefined();
    });
  });
});
