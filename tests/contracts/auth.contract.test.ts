import { describe, expect, it } from 'vitest';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { parse } from 'yaml';

const specPath = resolve(process.cwd(), 'docs/api/auth-service-openapi.yaml');

describe('auth OpenAPI spec', () => {
  it('loads local OpenAPI spec and contains validate endpoint', () => {
    expect(existsSync(specPath)).toBe(true);
    const raw = readFileSync(specPath, 'utf8');
    const spec = parse(raw);

    expect(spec).toBeTruthy();
    expect(spec.paths).toBeTruthy();
    expect(spec.paths['/validate']).toBeTruthy();
  });
});

const baseUrl = process.env.CONTRACT_BASE_URL;
const bearer = process.env.CONTRACT_BEARER_TOKEN ?? 'invalid-token';
const runtimeDescribe = baseUrl ? describe : describe.skip;

runtimeDescribe('auth contract runtime', () => {
  it('rejects invalid bearer token', async () => {
    const res = await fetch(new URL('/validate', baseUrl).toString(), {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${bearer}`,
      },
    });

    expect([401, 403]).toContain(res.status);
  });
});
