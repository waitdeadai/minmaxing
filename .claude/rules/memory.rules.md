# Memory Learning Rules

Memory is a measured subsystem, not a source of automatic truth.

## Health And Fallback

- Check memory health with `bash scripts/memory.sh health` when prior context
  materially affects the task.
- Health must be reported as `healthy`, `degraded`, or `disabled`.
- If memory is `degraded` or `disabled`, say so and fall back to local truth
  surfaces: `SPEC.md`, workflow artifacts, docs, git status, tests, and source
  files.
- Do not claim memory captured everything unless a run artifact or memory event
  trace proves the relevant entry exists.

## Eval And Freshness

- Use `bash scripts/memory-eval.sh --summary` for a quick freshness report.
- Use `bash scripts/memory-eval.sh --fixtures` as the regression gate.
- The eval must catch stale or missing critical repo facts rather than silently
  treating absent recall as acceptable.

## Event Traces

- Decision, pattern, error-solution, graph, and verified candidate writes should
  produce JSONL event traces under `.taste/memory-events/`.
- Event traces are evidence that a write was attempted, not proof that every
  future recall will retrieve it.

## Run-To-Memory Promotion

- Important run insights become memory candidates only after verification.
- Use `bash scripts/memory.sh candidate <tier> "<content>" --verified yes --source <artifact>`
  to record a candidate for later promotion review.
- Do not auto-promote implementation summaries, worker claims, research claims,
  or failed verification results into durable memory.
- Promote with `bash scripts/memory.sh add ...` only when the source artifact
  shows verified evidence and the entry is reusable beyond the current run.

## Public Boundary

- Do not write sensitive customer memory seeds, private commercial playbooks,
  real credentials, private connector details, audit logs, or customer-specific
  Hermes/REVCLI runtime facts into the public open-core repo.
- Private memory belongs in ignored/private storage, not tracked
  `obsidian/Memory/`, eval fixtures, docs, or examples.
