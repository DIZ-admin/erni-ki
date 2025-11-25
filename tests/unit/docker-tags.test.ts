import { spawnSync } from 'child_process';
import path from 'path';
import { describe, expect, it } from 'vitest';

const scriptPath = path.resolve('scripts/utilities/check-docker-tags.sh');

describe('check-docker-tags.sh', () => {
  it('passes on lowercase tags', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/org/image:tag\n',
      encoding: 'utf8',
    });
    expect(result.status).toBe(0);
    expect(result.stdout).toContain('lowercase');
  });

  it('fails on uppercase tags', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/ORG/IMAGE:Tag\n',
      encoding: 'utf8',
    });
    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain('Uppercase');
  });
});
