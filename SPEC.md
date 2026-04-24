# SPEC: Gemini-Style Deep Research Workflow

## Problem Statement
minmaxing already promises research-first work, but its current contract still treats deep research mostly as a parallel search wave. The repo should mirror the strongest public behaviors of Gemini Deep Research by enforcing a plan-first, iterative, source-conscious investigation workflow before planning or editing.

## Codebase Anchors
- `.claude/skills/workflow/SKILL.md` is the primary end-to-end workflow contract.
- `.claude/skills/browse/SKILL.md` defines direct research behavior and should match the workflow contract.
- `.claude/skills/autoplan/SKILL.md` must synthesize specs from the same investigation model.
- `README.md`, `CLAUDE.md`, and `AGENTS.md` are the repo's public/operator-facing promise surfaces.
- `scripts/test-harness.sh` and `scripts/workflow-smoke.sh` are the regression gates for contract drift.

## Success Criteria
- [ ] `workflow` requires a research plan, iterative search/read/refine loops, a source ledger, contradiction handling, and follow-up research before planning or edits when external facts matter.
- [ ] `browse` and `autoplan` reuse the same Gemini-inspired investigation contract instead of generic parallel-search language.
- [ ] Repo docs describe the upgraded research behavior clearly and consistently.
- [ ] Harness checks cover the new research contract markers so future drift is caught.

## Scope
### In Scope
- Updating research-facing skill instructions.
- Updating repo instructions and public docs to match the new investigation contract.
- Extending harness and smoke checks to validate the new contract.

### Out of Scope
- Integrating the actual Gemini API or cloning Gemini-specific UI features.
- Forcing literal streaming/thinking UIs inside Claude Code.
- Adding new runtime services, databases, or network dependencies.

## Implementation Plan
1. Patch `workflow` to add investigation modes, research planning, iterative loops, source ledgers, contradiction handling, and follow-up passes.
2. Patch `browse` and `autoplan` so standalone research/planning behavior matches the upgraded workflow contract.
3. Update `AGENTS.md`, `CLAUDE.md`, and `README.md` to describe the new deep research model consistently.
4. Extend `scripts/test-harness.sh` and `scripts/workflow-smoke.sh` to verify the new research contract.

## Verification
- Skill/docs alignment -> targeted `rg` / manual inspection of updated files.
- Harness contract -> `bash scripts/test-harness.sh`.
- Script syntax -> `bash -n scripts/test-harness.sh` and `bash -n scripts/workflow-smoke.sh`.

## Rollback Plan
- Revert the commit that updates the research workflow contract, docs, and harness checks.
- Restore the previous active `SPEC.md` from `.taste/specs/` if needed.
