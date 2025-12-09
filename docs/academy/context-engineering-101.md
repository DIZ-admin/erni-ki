---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-01'
---

# Context Engineering 101

> Context engineering = how to supply the model with the right data, history,
> and tools at the right moment so answers are accurate, fast, and safe.

## What it is and why it matters

- Context is more than a prompt: system instructions, retrieved documents
  (RAG/Context7/Docling), dialog history, tool outputs (LiteLLM tools), and
  safety constraints.
- Goal: a minimal yet sufficient token budget so the model relies on trusted
  sources (Redis/RAG) and does not hallucinate.

## Context anatomy in ERNI-KI

- **System prompt:** role, policies, constraints.
- **Retrieved docs:** relevant snippets (Context7, Docling, Tika).
- **User history:** latest turns/decisions (trim by importance, not just
  length).
- **Tool outputs:** API/script results that must appear in the final answer.
- **Guardrails:** filters, token limits, privacy (no PII without explicit
  consent).

## Practice: preparing context

- **Source selection:** only trusted collections; keep versions and dates.
- **Trimming:** remove noise (greetings, duplicates), keep section markers and
  headings.
- **Compression:** concise summaries when snippets are long; preserve numbers
  and key facts.
- **Privacy:** avoid mixing in personal/internal links without permission;
  redact when in doubt.
- **Completeness check:** ensure the context contains the answer; if not, ask
  for missing data before responding.

## Developer checklist (RAG/agents)

- Define token budget: system vs retrieved docs vs history.
- Rank documents: BM25 + vector + rerank → top-k → trim.
- Log exactly what went into context for debugging and cost control.
- Add source tags so the model can cite references.
- If the answer is not in context, return “no data” instead of guessing.

## When it’s not about context

- Need new capabilities → adjust pipeline/model, not just expand context.
- Tight constraints (PII, licensing) → enforce filters before and after the LLM.
- Heavy computation → push to tools instead of the LLM.

## Related materials

- Prompting 101: basic patterns and prompt limits.
- RAG and monitoring: see Operations → Monitoring (Redis/LiteLLM/Context7).
