import { spawnSync } from 'child_process';
import { mkdtempSync, mkdirSync, writeFileSync } from 'fs';
import os from 'os';
import path from 'path';
import { describe, expect, it } from 'vitest';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT_PATH = path.resolve(__dirname, '../../scripts/language-check.cjs');

function initRepo(): string {
  const dir = mkdtempSync(path.join(os.tmpdir(), 'language-check-'));
  spawnSync('git', ['init'], { cwd: dir, encoding: 'utf8' });
  return dir;
}

function writeFile(cwd: string, rel: string, content: string) {
  const full = path.join(cwd, rel);
  mkdirSync(path.dirname(full), { recursive: true });
  writeFileSync(full, content);
}

function stageAll(cwd: string) {
  spawnSync('git', ['add', '.'], { cwd, encoding: 'utf8' });
}

function runScript(cwd: string, args: string[] = []) {
  return spawnSync('node', [SCRIPT_PATH, ...args], {
    cwd,
    encoding: 'utf8',
  });
}

describe('language-check.cjs', () => {
  const cyrString = String.fromCharCode(0x0442, 0x0435, 0x0441, 0x0442); // cyrillic sample

  it('fails when Cyrillic appears in staged code', () => {
    const cwd = initRepo();
    writeFile(cwd, 'src/app.js', `console.log("${cyrString}");\n`);
    stageAll(cwd);

    const result = runScript(cwd);

    expect(result.status).toBe(1);
    expect(result.stdout + result.stderr).toContain('Cyrillic detected');
  });

  it('respects baseline entries from config', () => {
    const cwd = initRepo();
    writeFile(cwd, 'src/app.js', `console.log("${cyrString}");\n`);
    writeFile(
      cwd,
      'language-policy.config.json',
      JSON.stringify({ baseline: ['src/app.js'] }, null, 2),
    );
    stageAll(cwd);

    const result = runScript(cwd);

    expect(result.status).toBe(0);
    expect(result.stdout).toContain('Language policy baseline');
  });

  it('reports locale/frontmatter mismatches in docs', () => {
    const cwd = initRepo();
    writeFile(
      cwd,
      'docs/en/page.md',
      ['---', 'language: ru', 'translation_status: draft', '---', '', 'Hello'].join('\n'),
    );
    stageAll(cwd);

    const result = runScript(cwd);

    expect(result.status).toBe(1);
    expect(result.stdout).toContain("declares language 'ru'");
  });
});
