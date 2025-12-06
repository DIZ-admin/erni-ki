---
title: Contract Testing Implementation Plan
language: ru
page_id: contract-testing-plan
doc_version: '2025.11'
translation_status: original
---

# Contract Testing Implementation Plan (Phase 2.3)

**Created**: 2025-12-06 **Status**: In Progress **Estimated effort**: 12h
**Priority**: MEDIUM

## Executive Summary

Implement consumer-driven contract testing using Pact.js for critical API
integrations (LiteLLM, OpenWebUI, Docling) to ensure API compatibility across
versions and prevent breaking changes in production.

## Current State

### Existing Tests

- Basic contract test for Auth service
 (`tests/contracts/auth.contract.test.ts`)
- E2E tests for OpenWebUI (`tests/e2e/`)
- Load tests with k6 (`tests/load/`)
- No comprehensive API contract testing

### Services to Test

| Service | Version | Port | Key Endpoints |
| ------------- | ------------------- | ---- | ------------------------------------------------------------------------------------------- |
| **LiteLLM** | v1.80.0-stable.1 | 4000 | `/v1/chat/completions`, `/v1/embeddings`, `/v1/models`, `/health/liveliness` |
| **OpenWebUI** | v0.6.40 | 8080 | `/api/v1/auths`, `/api/v1/chats`, `/api/v1/documents`, `/api/v1/retrieval/query`, `/health` |
| **Docling** | docling-serve-cu126 | 5001 | `/convert`, `/health` |

## Goals

1. **Prevent Breaking Changes**: Catch API incompatibilities before deployment
2. **Version Compatibility**: Ensure new service versions work with existing
 consumers
3. **CI Integration**: Automated contract verification in pull requests
4. **Documentation**: Living API documentation through contracts

## Implementation Strategy

### Phase 1: Setup & Infrastructure (3h)

#### 1.1 Install Dependencies

```json
{
 "devDependencies": {
 "@pact-foundation/pact": "^13.0.0",
 "@pact-foundation/pact-node": "^10.18.0",
 "vitest": "^2.1.8"
 }
}
```

#### 1.2 Configure Pact

Create `tests/contracts/pact-setup.ts`:

```typescript
import { Pact } from '@pact-foundation/pact';
import { resolve } from 'node:path';

export const setupPact = (
 provider: string,
 consumer: string = 'erni-ki-frontend',
) => {
 return new Pact({
 consumer,
 provider,
 port: 1234, // Mock server port
 log: resolve(process.cwd(), 'logs', 'pact.log'),
 dir: resolve(process.cwd(), 'pacts'),
 logLevel: 'info',
 spec: 2,
 });
};
```

#### 1.3 Directory Structure

```
tests/
 contracts/
 pact-setup.ts # Pact configuration
 consumers/
 litellm.contract.test.ts
 openwebui.contract.test.ts
 docling.contract.test.ts
 auth.contract.test.ts (existing)
 providers/
 litellm.verify.ts
 openwebui.verify.ts
 docling.verify.ts
 README.md # Contract testing guide
 pacts/ # Generated pact files
 .gitkeep
```

### Phase 2: Consumer Contracts (4h)

#### 2.1 LiteLLM Consumer Contract

**File**: `tests/contracts/consumers/litellm.contract.test.ts`

**Critical Interactions**:

1. `POST /v1/chat/completions` - Chat completion requests
2. `POST /v1/embeddings` - Generate text embeddings
3. `GET /v1/models` - List available models
4. `GET /health/liveliness` - Health check

**Example Contract**:

```typescript
import { describe, it, beforeAll, afterAll } from 'vitest';
import { setupPact } from '../pact-setup';
import { MatchersV3 } from '@pact-foundation/pact';

const { like, regex } = MatchersV3;

describe('LiteLLM Consumer Contract', () => {
 const provider = setupPact('litellm-api', 'erni-ki-openwebui');

 beforeAll(() => provider.setup());
 afterAll(() => provider.finalize());

 it('should get list of available models', async () => {
 await provider.addInteraction({
 state: 'models are available',
 uponReceiving: 'a request for available models',
 withRequest: {
 method: 'GET',
 path: '/v1/models',
 headers: {
 Authorization: regex('Bearer .+', 'Bearer test-token'),
 },
 },
 willRespondWith: {
 status: 200,
 headers: {
 'Content-Type': 'application/json',
 },
 body: {
 object: 'list',
 data: like([
 {
 id: like('gpt-4'),
 object: 'model',
 created: like(1686935002),
 owned_by: like('openai'),
 },
 ]),
 },
 },
 });

 // Test the interaction
 const response = await fetch(`${provider.mockService.baseUrl}/v1/models`, {
 headers: { Authorization: 'Bearer test-token' },
 });

 expect(response.status).toBe(200);
 const data = await response.json();
 expect(data.object).toBe('list');
 expect(Array.isArray(data.data)).toBe(true);
 });

 it('should create chat completion', async () => {
 await provider.addInteraction({
 state: 'chat model is available',
 uponReceiving: 'a chat completion request',
 withRequest: {
 method: 'POST',
 path: '/v1/chat/completions',
 headers: {
 'Content-Type': 'application/json',
 Authorization: regex('Bearer .+', 'Bearer test-token'),
 },
 body: {
 model: like('gpt-4'),
 messages: like([
 {
 role: 'user',
 content: 'Hello',
 },
 ]),
 },
 },
 willRespondWith: {
 status: 200,
 headers: {
 'Content-Type': 'application/json',
 },
 body: {
 id: regex('chatcmpl-.+', 'chatcmpl-123'),
 object: 'chat.completion',
 created: like(1686935002),
 model: like('gpt-4'),
 choices: like([
 {
 index: 0,
 message: {
 role: 'assistant',
 content: like('Hello! How can I help you?'),
 },
 finish_reason: 'stop',
 },
 ]),
 usage: {
 prompt_tokens: like(10),
 completion_tokens: like(20),
 total_tokens: like(30),
 },
 },
 },
 });

 const response = await fetch(
 `${provider.mockService.baseUrl}/v1/chat/completions`,
 {
 method: 'POST',
 headers: {
 'Content-Type': 'application/json',
 Authorization: 'Bearer test-token',
 },
 body: JSON.stringify({
 model: 'gpt-4',
 messages: [{ role: 'user', content: 'Hello' }],
 }),
 },
 );

 expect(response.status).toBe(200);
 const data = await response.json();
 expect(data.object).toBe('chat.completion');
 expect(data.choices).toBeDefined();
 });
});
```

#### 2.2 OpenWebUI Consumer Contract

**File**: `tests/contracts/consumers/openwebui.contract.test.ts`

**Critical Interactions**:

1. `POST /api/v1/auths/signin` - User authentication
2. `GET /api/v1/chats` - List user conversations
3. `POST /api/v1/chats` - Create new conversation
4. `POST /api/v1/retrieval/query` - RAG query
5. `GET /health` - Health check

#### 2.3 Docling Consumer Contract

**File**: `tests/contracts/consumers/docling.contract.test.ts`

**Critical Interactions**:

1. `POST /convert` - Convert document
2. `GET /health` - Health check

### Phase 3: Provider Verification (3h)

#### 3.1 Provider Verification Setup

**File**: `tests/contracts/providers/litellm.verify.ts`

```typescript
import { Verifier } from '@pact-foundation/pact';
import { resolve } from 'node:path';

const providerBaseUrl =
 process.env.CONTRACT_BASE_URL || 'http://localhost:4000';
const authToken = process.env.CONTRACT_BEARER_TOKEN || '';

const opts = {
 provider: 'litellm-api',
 providerBaseUrl,
 pactUrls: [
 resolve(process.cwd(), 'pacts', 'erni-ki-openwebui-litellm-api.json'),
 ],
 publishVerificationResult: process.env.CI === 'true',
 providerVersion: process.env.PROVIDER_VERSION || '1.0.0',
 requestFilter: (req, res, next) => {
 // Add authentication to requests
 req.headers['Authorization'] = `Bearer ${authToken}`;
 next();
 },
 stateHandlers: {
 'models are available': async () => {
 // Setup: Ensure models are loaded
 console.log('Provider state: models are available');
 },
 'chat model is available': async () => {
 // Setup: Ensure chat model is ready
 console.log('Provider state: chat model is available');
 },
 },
};

new Verifier(opts)
 .verifyProvider()
 .then(() => {
 console.log('Pact verification complete!');
 process.exit(0);
 })
 .catch(error => {
 console.error('Pact verification failed:', error);
 process.exit(1);
 });
```

#### 3.2 Provider States

Document required provider states for each service:

| Service | State | Setup Required |
| --------- | ------------------------- | ------------------------ |
| LiteLLM | `models are available` | Load model list |
| LiteLLM | `chat model is available` | Ensure Ollama connection |
| OpenWebUI | `user exists` | Create test user |
| OpenWebUI | `documents exist` | Seed test documents |
| Docling | `service is ready` | Warmup models |

### Phase 4: CI Integration (2h)

#### 4.1 Update package.json

```json
{
 "scripts": {
 "test:contracts": "vitest run tests/contracts/consumers",
 "test:contracts:watch": "vitest watch tests/contracts/consumers",
 "verify:contracts": "npm run verify:litellm && npm run verify:openwebui && npm run verify:docling",
 "verify:litellm": "ts-node tests/contracts/providers/litellm.verify.ts",
 "verify:openwebui": "ts-node tests/contracts/providers/openwebui.verify.ts",
 "verify:docling": "ts-node tests/contracts/providers/docling.verify.ts"
 }
}
```

#### 4.2 GitHub Actions Workflow

**File**: `.github/workflows/ci.yml` (add new job)

```yaml
test-contracts:
 name: Contract Tests
 runs-on: ubuntu-latest
 timeout-minutes: 15
 needs: [lint]

 steps:
 - name: Checkout code
 uses: actions/checkout@v6.0.1

 - name: Setup Bun
 uses: oven-sh/setup-bun@v2.0.2
 with:
 bun-version: 1.3.3

 - name: Install dependencies
 run: bun install --frozen-lockfile
 working-directory: tests

 - name: Run consumer contract tests
 run: bun run test:contracts
 working-directory: tests

 - name: Upload pact files
 uses: actions/upload-artifact@v5
 with:
 name: pact-contracts
 path: tests/pacts/*.json

 - name: Verify provider contracts (if CONTRACT_BASE_URL set)
 if: env.CONTRACT_BASE_URL != ''
 env:
 CONTRACT_BASE_URL: ${{ secrets.CONTRACT_BASE_URL }}
 CONTRACT_BEARER_TOKEN: ${{ secrets.CONTRACT_BEARER_TOKEN }}
 run: bun run verify:contracts
 working-directory: tests
```

## Testing Strategy

### Consumer Testing

- **Run locally**: Developers run before commit
- **Run in CI**: Every pull request
- **Mock provider**: Use Pact mock server
- **Fast feedback**: < 30 seconds

### Provider Verification

- **Run on staging**: After deployment
- **Run in CI**: Optional (requires running services)
- **Real provider**: Hit actual service endpoints
- **Slower**: 2-5 minutes

## Success Metrics

1. **Coverage**: Contract tests for top 10 API endpoints (by usage)
2. **CI Integration**: All tests green in CI
3. **Breaking Changes**: Caught 100% before production
4. **Speed**: Consumer tests < 30s, Provider verification < 5min

## Risks & Mitigation

| Risk | Impact | Mitigation |
| ---------------------------- | ------ | -------------------------------------------------- |
| Provider service unavailable | HIGH | Skip provider verification if services not running |
| Breaking changes in test | MEDIUM | Version contracts, semantic versioning |
| Slow CI builds | MEDIUM | Run provider verification only on staging |
| Complex setup | LOW | Good documentation, examples |

## Dependencies

- `@pact-foundation/pact` - Core Pact library
- `@pact-foundation/pact-node` - Node.js bindings
- `vitest` - Test runner (already installed)
- Running services for provider verification (optional)

## Documentation

- [ ] Contract testing guide (`tests/contracts/README.md`)
- [ ] How to write consumer contracts
- [ ] How to verify provider contracts
- [ ] Troubleshooting guide
- [ ] CI/CD integration examples

## Timeline

| Phase | Duration | Deliverable |
| ------------------ | -------- | ---------------------------------------------- |
| Phase 1: Setup | 3h | Pact installed, configured |
| Phase 2: Consumers | 4h | LiteLLM, OpenWebUI, Docling consumer contracts |
| Phase 3: Providers | 3h | Provider verification for all 3 services |
| Phase 4: CI | 2h | GitHub Actions integration |
| **Total** | **12h** | Production-ready contract testing |

## Next Steps

1. Update task status to "doing"
2. ⏳ Install Pact dependencies
3. ⏳ Create directory structure
4. ⏳ Implement LiteLLM consumer contract
5. ⏳ Implement OpenWebUI consumer contract
6. ⏳ Implement Docling consumer contract
7. ⏳ Add provider verification
8. ⏳ Integrate with CI
9. ⏳ Document usage
10. ⏳ Update task to "review"

## References

- [Pact Documentation](https://docs.pact.io/)
- [Pact.js GitHub](https://github.com/pact-foundation/pact-js)
- [Contract Testing Best Practices](https://docs.pact.io/implementation_guides/best_practices)
- [OpenAPI vs Pact](https://docs.pact.io/getting_started/comparisons#pact-vs-openapi)

---

**Author**: Claude Sonnet 4.5 **Last Updated**: 2025-12-06
