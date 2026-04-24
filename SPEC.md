# SPEC: Effectiveness-First DeepResearch Commands

## Problem Statement
minmaxing now has a stronger research workflow, but it still exposes that method mainly through `/browse` and describes it as “Gemini-style” in multiple repo surfaces. The harness should own this capability as first-class `deepresearch` and `webresearch` commands while preserving effectiveness-first behavior, `MAX_PARALLEL_AGENTS` ceilings, and backward compatibility for `/browse`.

## Codebase Anchors
- `.claude/skills/workflow/SKILL.md` is the primary end-to-end workflow contract.
- `.claude/skills/deepresearch/SKILL.md` should become the canonical deep investigation playbook.
- `.claude/skills/webresearch/SKILL.md` should become the direct current-facts/web verification playbook.
- `.claude/skills/browse/SKILL.md` should remain as a compatibility alias.
- `.claude/skills/autoplan/SKILL.md` must synthesize specs from the same investigation model.
- `README.md`, `CLAUDE.md`, and `AGENTS.md` are the repo's public/operator-facing promise surfaces.
- `scripts/test-harness.sh` and `scripts/workflow-smoke.sh` are the regression gates for contract drift.

## Success Criteria
- [ ] `workflow` requires a research plan, iterative search/read/refine loops, a source ledger, contradiction handling, and follow-up research before planning or edits when external facts matter.
- [ ] Canonical `/deepresearch` and `/webresearch` skills exist and both honor `MAX_PARALLEL_AGENTS` as an effectiveness-first ceiling.
- [ ] `/browse` remains usable as a compatibility alias while pointing to the same repo-owned research protocol.
- [ ] `autoplan` and the user-facing docs describe the research behavior as repo-owned `deepresearch` / `webresearch`, not as “Gemini-style.”
- [ ] Repo docs describe the upgraded research behavior clearly and consistently.
- [ ] Harness checks cover the new research contract markers so future drift is caught.

## Scope
### In Scope
- Adding canonical `deepresearch` and `webresearch` skill surfaces.
- Converting `/browse` into a compatibility alias.
- Updating research-facing skill instructions.
- Updating repo instructions and public docs to match the new investigation contract.
- Extending harness and smoke checks to validate the new contract.

### Out of Scope
- Integrating an external deep-research provider or cloning product-specific UI features.
- Changing the effectiveness-first `MAX_PARALLEL_AGENTS` policy into quota-based slot filling.
- Adding new runtime services, databases, or network dependencies.

## Implementation Plan
1. Add canonical `deepresearch` and `webresearch` skills built around the same effectiveness-first investigation protocol.
2. Convert `browse` into a backward-compatible alias and update `workflow` / `autoplan` to reference the repo-owned naming.
3. Update `AGENTS.md`, `CLAUDE.md`, and `README.md` to describe the new command surfaces and remove stale Gemini phrasing.
4. Extend `scripts/test-harness.sh` and related docs to verify the new command surfaces and still-effectiveness-first parallelism contract.

## Verification
- Skill/docs alignment -> targeted `rg` / manual inspection of updated files.
- Harness contract -> `bash scripts/test-harness.sh`.
- Script syntax -> `bash -n scripts/test-harness.sh` and `bash -n scripts/workflow-smoke.sh`.

## Rollback Plan
- Revert the commit that updates the research workflow contract, docs, and harness checks.
- Restore the previous active `SPEC.md` from `.taste/specs/` if needed.
