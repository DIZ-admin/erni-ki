---
language: en
translation_status: pending
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Prompting 101

## Golden rules

1. **Role → Task → Context → Format.** Explicitly set the assistant role, what
   it should do, which facts matter, and how to respond.
2. **Reference materials.** Attach files or snippets and quote their filenames
   so the model cites them.
3. **Fail fast.** Ask for intermediate reasoning (`"list assumptions"`) before
   requesting a final answer.

## Prompt skeleton

```
You are <role>. Complete the task for <audience>.

Task:
- ...

Context:
1. Fact 1
2. Fact 2

Constraints:
- tone/style
- length or format requirements

Produce: <bullet list/report/email/etc>
```

## Anti-patterns

- Vague instructions (“Please help”) without outputs or length.
- Mixing different asks in one prompt (e.g., translate + summarize + generate
  action items at the same time).
- Forgetting to specify language when source and target differ.

## Practice

Use the HowTo guides as exercises: run the prompt skeleton, compare with the
canonical Russian output, and adjust weighting/temperature if needed.
