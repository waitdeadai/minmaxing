# Codex Project Instructions

This repo is optimized for Claude Code first, but it also ships project-scoped Codex defaults for the official OpenAI `codex-plugin-cc` plugin and direct Codex CLI usage.

## Research-Backed Work

- For planning, audits, debugging, refactors, and architecture work, start with a research brief before proposing edits.
- For deep research, use the repo’s effectiveness-first `deepresearch` protocol: draft a collaborative research plan before the first search wave, run an iterative search -> read -> refine loop, keep a source ledger with cited and reviewed-but-not-cited sources, surface conflicting evidence, and do follow-up research before freezing the plan. Use `webresearch` for narrower current-fact verification. Both must respect the configured parallel ceiling rather than filling slots.
- When the task benefits from parallelism, explicitly choose an effective subagent budget up to the configured `max_threads`.
- Use `.minimaxing/state/CURRENT.md` as the current-task continuity handoff after startup, resume, or compaction; reconcile it with live git status and `SPEC.md` before editing.
- Treat `SPEC.md` as the active contract. Before replacing a non-reused active spec, archive it with `bash scripts/spec-archive.sh prepare "[task]" "superseded-before-new-spec"`; after verified closeout, archive with `bash scripts/spec-archive.sh closeout "[task]" "verified: [outcome]"`.
- Prefer this split for deep research:
  - `repo_explorer` to map the code paths and evidence inside the repo
  - `docs_researcher` to verify APIs, versions, and current behavior with citations
  - `reviewer` to challenge the plan for correctness, rollback, and test gaps

## Model and Tooling Guidance

- The project default Codex model is `gpt-5.4` with `xhigh` reasoning via `.codex/config.toml`.
- Use `gpt-5.4-pro` only when you explicitly need the highest-cost, slowest deep-think pass and are prepared for background-style latency.
- For OpenAI and Codex questions, use the `openaiDeveloperDocs` MCP server before relying on memory.

## Output Expectations

- Produce a research-backed plan before code changes when the task is non-trivial.
- Cite files, symbols, and external sources when they materially affect the plan.
- Keep changes minimal, verifiable, and easy to roll back.
