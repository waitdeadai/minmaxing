# SPEC: Digestflow External Report Intake Workflow

## Problem Statement
minmaxing needs a first-class `/digestflow` route for work that starts from external AI research reports, then continues through the existing governed workflow without laundering those reports into trusted truth.

The route must treat Gemini Deep Research, NotebookLM, ChatGPT Deep Research, Perplexity, and similar reports as untrusted candidate evidence. Report intake should improve the repo's own `deepresearch` phase, not replace it or recursively call `/workflow`.

## Codebase Anchors
- `.claude/skills/workflow/SKILL.md` is the central inline lifecycle contract.
- `.claude/skills/deepresearch/SKILL.md` defines the repo's source-ledger, contradiction-aware research protocol.
- `.claude/skills/introspect/SKILL.md` defines the required self-audit hard gates.
- `README.md`, `CLAUDE.md`, and `AGENTS.md` are public and operator-facing command contracts.
- `scripts/start-session.sh` and `scripts/test-harness.sh` enforce the visible skill count and command inventory.
- `scripts/workflow-smoke.sh` is the existing runtime smoke pattern for slash-command workflows.

## Success Criteria
- [ ] `.claude/skills/digestflow/SKILL.md` exists and defines `/digestflow` as a report-informed sibling of `/workflow`.
- [ ] `/digestflow` requires 1-10 report inputs and fails closed when no report is supplied.
- [ ] Report Intake requires a report manifest, claim ledger, contradiction handling, injection quarantine, source ledger handoff, and no-persist default for report bodies.
- [ ] External report claims are explicitly labeled `report-derived` until verified by repo inspection or live sources.
- [ ] The normal minmaxing `deepresearch` pass remains mandatory after intake and before planning.
- [ ] `/workflow` recognizes report intake as a sibling-route prelude without changing normal `/workflow` behavior.
- [ ] README, CLAUDE, AGENTS, and startup output document `/digestflow` and the 20-skill contract.
- [ ] Harness tests enforce the `/digestflow` contract and stale skill-count wording is removed.
- [ ] A dedicated digestflow smoke script exists for optional integration verification.

## Scope
### In Scope
- Add the `/digestflow` skill contract.
- Update workflow guidance, public docs, operator instructions, startup output, and harness tests.
- Add optional runtime smoke coverage using tiny report fixtures generated in a temporary repo.
- Preserve the existing `/workflow` path and governed autonomy language.

### Out of Scope
- Building binary PDF/DOCX extraction.
- Adding a persistent report database.
- Changing Claude Code runtime behavior or MiniMax MCP configuration.
- Pushing changes unless explicitly requested.

## Implementation Plan
1. Add `.claude/skills/digestflow/SKILL.md` with the report intake, evidence-state, privacy, and full-workflow handoff contract.
2. Update `.claude/skills/workflow/SKILL.md` to describe the `/digestflow` sibling route and optional `## Report Intake` artifact section.
3. Update README, CLAUDE, and AGENTS so the command inventory and operator contract are consistent.
4. Update `scripts/start-session.sh` for 20 skills and include `/digestflow`.
5. Update `scripts/test-harness.sh` to enforce the 20-skill count and digestflow contract language.
6. Add `scripts/digestflow-smoke.sh` for optional runtime coverage with poisoned and conflicting report fixtures.

## Verification
- `bash -n scripts/start-session.sh`
- `bash -n scripts/test-harness.sh`
- `bash -n scripts/workflow-smoke.sh`
- `bash -n scripts/digestflow-smoke.sh`
- `rg -n "The old skill-count heading|old Expected-skill-count wording" README.md CLAUDE.md AGENTS.md .claude/skills scripts`
- `bash scripts/test-harness.sh`
- Optional: `RUN_CLAUDE_INTEGRATION=1 bash scripts/test-harness.sh`
- Optional: `bash scripts/digestflow-smoke.sh`

## Rollback Plan
- Remove `.claude/skills/digestflow/`.
- Revert README, CLAUDE, AGENTS, workflow guidance, startup output, and harness test count updates back to the previous skill-count contract.
- Remove `scripts/digestflow-smoke.sh`.
