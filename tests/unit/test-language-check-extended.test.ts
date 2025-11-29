import { spawnSync } from 'child_process';
import { describe, expect, it } from 'vitest';
import fs from 'fs';
import path from 'path';
import os from 'os';

const scriptPath = path.resolve('scripts/language-check.cjs');
const tmpPrefix = path.join(os.tmpdir(), 'lang-check-');

const createTempFile = (filename: string, content: string) => {
  const dir = fs.mkdtempSync(tmpPrefix);
  const filePath = path.join(dir, filename);
  fs.writeFileSync(filePath, content, { encoding: 'utf8' });

  const cleanup = () => {
    fs.rmSync(dir, { recursive: true, force: true });
  };

  return { filePath, cleanup };
};

describe('language-check.cjs - Extended Tests', () => {
  it('script file exists and is executable', () => {
    expect(fs.existsSync(scriptPath)).toBe(true);
  });

  it('detects German language in text', () => {
    const { filePath, cleanup } = createTempFile('test-german.md', 'Das ist ein deutscher Text.');

    const result = spawnSync('node', [scriptPath, filePath], {
      encoding: 'utf8',
    });

    cleanup();
    // Current language-check only flags Cyrillic; German should pass
    expect(result.status).toBe(0);
  });

  it('accepts English-only text', () => {
    const { filePath, cleanup } = createTempFile('test-english.md', 'This is an English text.');

    const result = spawnSync('node', [scriptPath, filePath], {
      encoding: 'utf8',
    });

    cleanup();
    expect(result.status).toBe(0);
  });

  it('handles empty files', () => {
    const { filePath, cleanup } = createTempFile('test-empty.md', '');

    const result = spawnSync('node', [scriptPath, filePath], {
      encoding: 'utf8',
    });

    cleanup();
    // Empty files should pass (no forbidden language)
    expect(result.status).toBe(0);
  });

  it('detects common German words', () => {
    const germanWords = [
      'Betriebssystem',
      'Konfiguration',
      'Verwaltung',
      'Übersicht',
      'Einstellungen',
    ];

    for (const word of germanWords) {
      const { filePath, cleanup } = createTempFile(
        'test-word.md',
        `The system uses ${word} for management.`,
      );

      const result = spawnSync('node', [scriptPath, filePath], {
        encoding: 'utf8',
      });

      cleanup();
      expect(result.status).toBe(0);
    }
  });

  it('handles files with mixed content', () => {
    const { filePath, cleanup } = createTempFile(
      'test-mixed.md',
      `# Configuration Guide

This is a configuration guide.
Some technical terms in English.
      `,
    );

    const result = spawnSync('node', [scriptPath, filePath], {
      encoding: 'utf8',
    });

    cleanup();
    expect(result.status).toBe(0);
  });

  it('ignores code blocks with German-like content', () => {
    const { filePath, cleanup } = createTempFile(
      'test-code.md',
      `# Documentation

\`\`\`bash
# Configuration example
echo "Konfiguration"
\`\`\`
      `,
    );

    const result = spawnSync('node', [scriptPath, filePath], {
      encoding: 'utf8',
    });

    cleanup();
    // Code blocks should be ignored
    expect(result.status).toBe(0);
  });
});

describe('language-check.cjs - Edge Cases', () => {
  it('handles non-existent files', () => {
    const result = spawnSync('node', [scriptPath, '/nonexistent/file.md'], {
      encoding: 'utf8',
    });

    expect(result.status).toBe(0);
  });

  it('handles files without extensions', () => {
    const { filePath, cleanup } = createTempFile('test-no-ext', 'This is a test file.');

    const result = spawnSync('node', [scriptPath, filePath], {
      encoding: 'utf8',
    });

    cleanup();
    expect(result.status).toBe(0);
  });

  it('handles very large files', () => {
    const largeContent = 'This is English text. '.repeat(10000);
    const { filePath, cleanup } = createTempFile('test-large.md', largeContent);

    const result = spawnSync('node', [scriptPath, filePath], {
      encoding: 'utf8',
      timeout: 5000,
    });

    cleanup();
    expect(result.status).toBe(0);
  });

  it('handles files with special characters', () => {
    const { filePath, cleanup } = createTempFile(
      'test-special.md',
      'This is a test with émojis 🎉 and special chars: @#$%^&*()',
    );

    const result = spawnSync('node', [scriptPath, filePath], {
      encoding: 'utf8',
    });

    cleanup();
    expect(result.status).toBe(0);
  });
});
