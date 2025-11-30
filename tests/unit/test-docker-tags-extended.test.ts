import { spawnSync } from 'child_process';
import { describe, expect, it } from 'vitest';
import path from 'path';

const scriptPath = path.resolve('scripts/utilities/check-docker-tags.sh');

describe('check-docker-tags.sh - Extended Tests', () => {
  it('accepts fully lowercase docker tags', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/myorg/myimage:v1.2.3\n',
      encoding: 'utf8',
    });
    expect(result.status).toBe(0);
  });

  it('rejects tags with uppercase letters in registry', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'GHCR.io/org/image:tag\n',
      encoding: 'utf8',
    });
    expect(result.status).not.toBe(0);
  });

  it('rejects tags with uppercase in organization', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/MyOrg/image:tag\n',
      encoding: 'utf8',
    });
    expect(result.status).not.toBe(0);
  });

  it('rejects tags with uppercase in image name', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/org/MyImage:tag\n',
      encoding: 'utf8',
    });
    expect(result.status).not.toBe(0);
  });

  it('rejects tags with uppercase in tag version', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/org/image:Latest\n',
      encoding: 'utf8',
    });
    expect(result.status).not.toBe(0);
  });

  it('accepts SHA-prefixed tags in lowercase', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/org/image:sha-a1b2c3d4\n',
      encoding: 'utf8',
    });
    expect(result.status).toBe(0);
  });

  it('rejects SHA-prefixed tags with uppercase', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/org/image:SHA-a1b2c3d4\n',
      encoding: 'utf8',
    });
    expect(result.status).not.toBe(0);
  });

  it('handles multiple tags in input', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/org/image:v1\nghcr.io/org/image:v2\nghcr.io/org/image:latest\n',
      encoding: 'utf8',
    });
    expect(result.status).toBe(0);
  });

  it('fails if any tag in multiple tags has uppercase', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/org/image:v1\nghcr.io/org/image:V2\nghcr.io/org/image:latest\n',
      encoding: 'utf8',
    });
    expect(result.status).not.toBe(0);
  });

  it('handles empty input gracefully', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: '',
      encoding: 'utf8',
    });
    expect(result.status).toBe(0);
  });

  it('handles whitespace-only input', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: '   \n  \n',
      encoding: 'utf8',
    });
    expect(result.status).toBe(0);
  });

  it('accepts hyphenated names in lowercase', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/my-org/my-image:my-tag\n',
      encoding: 'utf8',
    });
    expect(result.status).toBe(0);
  });

  it('accepts underscored names in lowercase', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/my_org/my_image:my_tag\n',
      encoding: 'utf8',
    });
    expect(result.status).toBe(0);
  });

  it('accepts numeric versions', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/org/image:1.2.3\n',
      encoding: 'utf8',
    });
    expect(result.status).toBe(0);
  });

  it('accepts codex tag', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/diz-admin/erni-ki/auth:codex\n',
      encoding: 'utf8',
    });
    expect(result.status).toBe(0);
  });

  it('rejects Codex with uppercase C', () => {
    const result = spawnSync('bash', [scriptPath], {
      input: 'ghcr.io/diz-admin/erni-ki/auth:Codex\n',
      encoding: 'utf8',
    });
    expect(result.status).not.toBe(0);
  });
});
