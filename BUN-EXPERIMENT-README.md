# Bun Experiment - Quick Start

This branch (`experiment/bun-evaluation`) contains a comprehensive evaluation of
Bun runtime for the ERNI-KI project.

## Results Summary

**Performance:**

- **3.5-4.4x faster** package installation vs npm
- **100% test compatibility** (81/81 tests pass)
- **11ms** HTTP server startup
- **Instant** TypeScript execution

**Recommendation:** **ADOPT for local development**

## Documentation

1. **[.claude/bun.md](.claude/bun.md)** - Complete Bun overview (23KB)
2. **[.claude/bun-experiment-results.md](.claude/bun-experiment-results.md)** -
   Detailed experiment results
3. **[bunfig.toml](bunfig.toml)** - Bun configuration

## Test Files

- `test-bun-native.ts` - Native TypeScript execution demo
- `test-bun-runner.test.ts` - Bun test runner demo
- `test-bun-server.ts` - HTTP server performance demo

## Quick Start

### 1. Install Bun (if not already installed)

```bash
curl -fsSL https://bun.sh/install | bash
```

### 2. Try it out

```bash
# Use Bun for package management (3.5x faster!)
bun install

# Run existing scripts
bun run test:unit
bun run type-check

# Run TypeScript directly (no compilation!)
bun run test-bun-native.ts

# Run Bun tests
bun test test-bun-runner.test.ts

# Start HTTP server
bun run test-bun-server.ts
```

## Performance Comparison

| Operation      | npm   | Bun   | Speedup  |
| -------------- | ----- | ----- | -------- |
| Cold install   | 6.67s | 1.88s | **3.5x** |
| Cached install | 8.10s | 1.85s | **4.4x** |

## Recommended Usage

**NOW:**

- Use `bun install` for local development
- Run scripts with `bun run`
- Execute TypeScript files directly

**LATER:**

- Evaluate for CI/CD
- Consider for production (after more testing)

## Learn More

- Official Docs: <https://bun.sh/docs>
- GitHub: <https://github.com/oven-sh/bun>

---

**Experiment Date:** 2025-12-02 **Bun Version:** 1.3.3 **Status:** Successful
