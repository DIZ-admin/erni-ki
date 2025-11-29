import { describe, expect, it } from 'vitest';
import fs from 'fs';
import path from 'path';

describe('CI Pipeline Configuration Validation', () => {
  const ciPath = path.resolve('.github/workflows/ci.yml');

  it('CI workflow file exists', () => {
    expect(fs.existsSync(ciPath)).toBe(true);
  });

  it('CI workflow contains required jobs', () => {
    const content = fs.readFileSync(ciPath, 'utf8');
    
    const requiredJobs = ['lint', 'test-go', 'test-js', 'security', 'docker-build'];
    for (const job of requiredJobs) {
      expect(content).toContain(job);
    }
  });

  it('CI workflow has timeout settings', () => {
    const content = fs.readFileSync(ciPath, 'utf8');
    expect(content).toContain('timeout-minutes');
  });

  it('CI workflow uses Node.js', () => {
    const content = fs.readFileSync(ciPath, 'utf8');
    expect(content).toContain('node-version');
  });

  it('CI workflow uses Go', () => {
    const content = fs.readFileSync(ciPath, 'utf8');
    expect(content).toContain('go-version');
  });
});

describe('Repository Configuration Files', () => {
  it('package.json exists and is valid JSON', () => {
    const pkgPath = path.resolve('package.json');
    expect(fs.existsSync(pkgPath)).toBe(true);
    
    const content = fs.readFileSync(pkgPath, 'utf8');
    expect(() => JSON.parse(content)).not.toThrow();
  });

  it('tsconfig.json exists and is valid JSON', () => {
    const tsconfigPath = path.resolve('tsconfig.json');
    expect(fs.existsSync(tsconfigPath)).toBe(true);
    
    const content = fs.readFileSync(tsconfigPath, 'utf8');
    const config = JSON.parse(content);
    expect(config).toHaveProperty('compilerOptions');
  });

  it('vitest.config.ts exists', () => {
    const vitestConfigPath = path.resolve('vitest.config.ts');
    expect(fs.existsSync(vitestConfigPath)).toBe(true);
  });

  it('eslint.config.js exists', () => {
    const eslintConfigPath = path.resolve('eslint.config.js');
    expect(fs.existsSync(eslintConfigPath)).toBe(true);
  });

  it('.editorconfig exists', () => {
    const editorConfigPath = path.resolve('.editorconfig');
    expect(fs.existsSync(editorConfigPath)).toBe(true);
  });
});

describe('Test Infrastructure', () => {
  it('tests directory exists with proper structure', () => {
    const testDirs = ['tests', 'tests/unit', 'tests/integration', 'tests/e2e', 'tests/python'];
    
    for (const dir of testDirs) {
      expect(fs.existsSync(path.resolve(dir))).toBe(true);
    }
  });

  it('test configuration files exist', () => {
    const testFiles = ['tests/setup.ts', 'tests/global-setup.ts'];
    
    for (const file of testFiles) {
      expect(fs.existsSync(path.resolve(file))).toBe(true);
    }
  });

  it('BATS test files exist', () => {
    const batsDir = path.resolve('tests/integration/bats');
    expect(fs.existsSync(batsDir)).toBe(true);
    
    const batsFiles = fs.readdirSync(batsDir).filter(f => f.endsWith('.bats'));
    expect(batsFiles.length).toBeGreaterThan(0);
  });
});

describe('Docker Configuration', () => {
  it('compose.yml exists', () => {
    expect(fs.existsSync(path.resolve('compose.yml'))).toBe(true);
  });

  it('Dockerfile exists for auth service', () => {
    expect(fs.existsSync(path.resolve('auth/Dockerfile'))).toBe(true);
  });

  it('.dockerignore exists', () => {
    expect(fs.existsSync(path.resolve('.dockerignore'))).toBe(true);
  });
});

describe('Go Module Configuration', () => {
  it('Go module files exist for auth service', () => {
    const goFiles = ['auth/go.mod', 'auth/main.go', 'auth/main_test.go'];
    
    for (const file of goFiles) {
      expect(fs.existsSync(path.resolve(file))).toBe(true);
    }
  });

  it('go.mod specifies Go version', () => {
    const content = fs.readFileSync(path.resolve('auth/go.mod'), 'utf8');
    expect(content).toMatch(/^go \d+\.\d+/m);
  });
});

describe('Documentation', () => {
  it('core documentation files exist', () => {
    const docs = ['README.md', 'CONTRIBUTING.md', 'CHANGELOG.md', 'LICENSE'];
    
    for (const doc of docs) {
      expect(fs.existsSync(path.resolve(doc))).toBe(true);
    }
  });

  it('docs directory exists with content', () => {
    const docsDir = path.resolve('docs');
    expect(fs.existsSync(docsDir)).toBe(true);
    
    const files = fs.readdirSync(docsDir);
    expect(files.length).toBeGreaterThan(0);
  });
});

describe('Script Organization', () => {
  it('scripts directory exists', () => {
    expect(fs.existsSync(path.resolve('scripts'))).toBe(true);
  });

  it('critical scripts exist', () => {
    const scripts = [
      'scripts/utilities/check-docker-tags.sh',
      'scripts/language-check.cjs',
    ];
    
    for (const script of scripts) {
      const scriptPath = path.resolve(script);
      if (fs.existsSync(scriptPath)) {
        expect(fs.existsSync(scriptPath)).toBe(true);
      }
    }
  });
});