#!/usr/bin/env node
/* eslint-disable no-console, security/detect-non-literal-fs-filename */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const CODE_EXTENSIONS = new Set([
  '.js',
  '.jsx',
  '.ts',
  '.tsx',
  '.mjs',
  '.cjs',
  '.go',
  '.py',
  '.sh',
  '.rb',
  '.rs',
  '.java',
  '.php',
  '.yml',
  '.yaml',
]);
const DOC_EXTENSIONS = new Set(['.md', '.mdx']);
const CONFIG_FILES = new Set(['.snyk']);
const CYRILLIC = /[\u0400-\u04FF]/;
const CONFIG_PATH = path.join(process.cwd(), 'language-policy.config.json');

const args = process.argv.slice(2);
const runAll = args.includes('--all');

function normalizePath(filename) {
  return filename.replace(/\\/g, '/');
}

function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) {
    return { baseline: [] };
  }
  try {
    const raw = fs.readFileSync(CONFIG_PATH, 'utf8');
    return JSON.parse(raw);
  } catch (error) {
    console.warn(`Warning: failed to parse ${CONFIG_PATH}: ${error.message}`);
    return { baseline: [] };
  }
}

const config = loadConfig();
const baselineFiles = new Set((config.baseline || []).map(normalizePath));
const baselineHits = new Set();

function gitFiles(all) {
  const cmd = all ? 'git ls-files' : 'git diff --cached --name-only --diff-filter=ACMR';
  try {
    const output = execSync(cmd, { encoding: 'utf8' });
    return output
      .split('\n')
      .map(f => f.trim())
      .filter(f => f.length > 0);
  } catch (error) {
    console.error('Failed to list files:', error.message);
    process.exit(2);
  }
}

function localeFromPath(filename) {
  const normalized = normalizePath(filename);
  if (normalized.startsWith('docs/de/')) return 'de';
  if (normalized.startsWith('docs/en/')) return 'en';
  if (normalized.startsWith('docs/')) return 'ru';
  return null;
}

function isDocumentationFile(filename) {
  const normalized = normalizePath(filename);
  return normalized.startsWith('docs/');
}

function parseLanguage(frontMatter) {
  const match = frontMatter.match(/language\s*:\s*['"]?(\w{2})['"]?/i);
  if (!match) return null;
  return match[1].toLowerCase();
}

function extractFrontMatter(content) {
  if (!content.startsWith('---')) return null;
  const parts = content.split('---');
  if (parts.length < 3) return null;
  return parts[1];
}

const stagedFiles = gitFiles(runAll);
if (!stagedFiles.length) {
  process.exit(0);
}

const errors = [];
const warnings = [];

for (const file of stagedFiles) {
  const ext = path.extname(file).toLowerCase();
  if (!fs.existsSync(file)) {
    continue;
  }
  const content = fs.readFileSync(file, 'utf8');
  const normalizedPath = normalizePath(file);

  const isCodeOrConfig = CODE_EXTENSIONS.has(ext) || CONFIG_FILES.has(path.basename(file));
  const documentationFile = isDocumentationFile(file);

  if (isCodeOrConfig && !documentationFile) {
    if (CYRILLIC.test(content)) {
      if (baselineFiles.has(normalizedPath)) {
        baselineHits.add(normalizedPath);
        continue;
      }
      errors.push(`Cyrillic detected in code/config file ${file}`);
    }
  }

  if (DOC_EXTENSIONS.has(ext)) {
    const locale = localeFromPath(file);
    if (!locale) {
      continue;
    }
    const fm = extractFrontMatter(content);
    if (!fm) {
      warnings.push(
        `Missing front matter for ${file}; set "language: ${locale}" in the metadata block.`,
      );
      continue;
    }
    const language = parseLanguage(fm);
    if (language && language !== locale) {
      errors.push(
        `Document ${file} declares language '${language}' but lives inside '${locale}' content`,
      );
    } else if (!language) {
      warnings.push(`Front matter of ${file} lacks 'language:' value for locale '${locale}'`);
    }
  }
}

if (warnings.length) {
  console.log('\nLanguage check warnings:');
  for (const warning of warnings) {
    console.log('  ⚠️  ' + warning);
  }
}

if (baselineHits.size) {
  console.log('\nLanguage policy baseline (pending translation):');
  for (const file of Array.from(baselineHits).sort()) {
    console.log('  • ' + file);
  }
}

if (errors.length) {
  console.log('\nLanguage check failed:');
  for (const error of errors) {
    console.log('  ❌ ' + error);
  }
  process.exit(1);
}

process.exit(0);
