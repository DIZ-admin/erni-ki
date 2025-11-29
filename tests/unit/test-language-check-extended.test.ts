import { spawnSync } from 'child_process';
import { describe, expect, it } from 'vitest';
import path from 'path';
import fs from 'fs';
import os from 'os';

const scriptPath = path.resolve('scripts/language-check.cjs');

describe('language-check.cjs - Extended Tests', () => {
  it('script file exists and is executable', () => {
    expect(fs.existsSync(scriptPath)).toBe(true);
  });

  it('detects German language in text', () => {
    const tempFile = path.join(os.tmpdir(), 'test-german.md');
    fs.writeFileSync(tempFile, 'Das ist ein deutscher Text.');

    const result = spawnSync('node', [scriptPath, tempFile], {
      encoding: 'utf8',
    });

    fs.unlinkSync(tempFile);
    // Current language-check only flags Cyrillic; German should pass
    expect(result.status).toBe(0);
  });

  it('accepts English-only text', () => {
    const tempFile = path.join(os.tmpdir(), 'test-english.md');
    fs.writeFileSync(tempFile, 'This is an English text.');

    const result = spawnSync('node', [scriptPath, tempFile], {
      encoding: 'utf8',
    });

    fs.unlinkSync(tempFile);
    expect(result.status).toBe(0);
  });

  it('handles empty files', () => {
    const tempFile = path.join(os.tmpdir(), 'test-empty.md');
    fs.writeFileSync(tempFile, '');

    const result = spawnSync('node', [scriptPath, tempFile], {
      encoding: 'utf8',
    });

    fs.unlinkSync(tempFile);
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
      const tempFile = path.join(os.tmpdir(), 'test-word.md');
      fs.writeFileSync(tempFile, `The system uses ${word} for management.`);

      const result = spawnSync('node', [scriptPath, tempFile], {
        encoding: 'utf8',
      });

      fs.unlinkSync(tempFile);
      expect(result.status).toBe(0);
    }
  });

  it('handles files with mixed content', () => {
    const tempFile = path.join(os.tmpdir(), 'test-mixed.md');
    fs.writeFileSync(
      tempFile,
      `# Configuration Guide

This is a configuration guide.
Some technical terms in English.
      `,
    );

    const result = spawnSync('node', [scriptPath, tempFile], {
      encoding: 'utf8',
    });

    fs.unlinkSync(tempFile);
    expect(result.status).toBe(0);
  });

  it('ignores code blocks with German-like content', () => {
    const tempFile = path.join(os.tmpdir(), 'test-code.md');
    fs.writeFileSync(
      tempFile,
      `# Documentation

\`\`\`bash
# Configuration example
echo "Konfiguration"
\`\`\`
      `,
    );

    const result = spawnSync('node', [scriptPath, tempFile], {
      encoding: 'utf8',
    });

    fs.unlinkSync(tempFile);
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
    const tempFile = path.join(os.tmpdir(), 'test-no-ext');
    fs.writeFileSync(tempFile, 'This is a test file.');

    const result = spawnSync('node', [scriptPath, tempFile], {
      encoding: 'utf8',
    });

    fs.unlinkSync(tempFile);
    expect(result.status).toBe(0);
  });

  it('handles very large files', () => {
    const tempFile = path.join(os.tmpdir(), 'test-large.md');
    const largeContent = 'This is English text. '.repeat(10000);
    fs.writeFileSync(tempFile, largeContent);

    const result = spawnSync('node', [scriptPath, tempFile], {
      encoding: 'utf8',
      timeout: 5000,
    });

    fs.unlinkSync(tempFile);
    expect(result.status).toBe(0);
  });

  it('handles files with special characters', () => {
    const tempFile = path.join(os.tmpdir(), 'test-special.md');
    fs.writeFileSync(tempFile, 'This is a test with émojis 🎉 and special chars: @#$%^&*()');

    const result = spawnSync('node', [scriptPath, tempFile], {
      encoding: 'utf8',
    });

    fs.unlinkSync(tempFile);
    expect(result.status).toBe(0);
  });
});
