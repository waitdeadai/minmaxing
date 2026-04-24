# SPEC: Hard-Gate Introspect Mode

## Problem Statement
minmaxing needs a first-class `/introspect` guardrail that forces the model to find likely mistakes in moments where premature confidence is most dangerous. The guardrail should be usable directly, triggered inside `/workflow`, and available through `/instrospect` as a compatibility alias for the requested spelling.

## Codebase Anchors
- `.claude/skills/workflow/SKILL.md` owns the full research -> audit -> plan -> spec -> execute -> verify lifecycle.
- `.claude/skills/audit/SKILL.md`, `.claude/skills/deepresearch/SKILL.md`, `.claude/skills/autoplan/SKILL.md`, and `.claude/skills/review/SKILL.md` are the main quality surfaces that must call out introspection.
- `README.md`, `CLAUDE.md`, and `AGENTS.md` are the public and operator-facing promise surfaces.
- `scripts/test-harness.sh` and `scripts/workflow-smoke.sh` are the regression gates for contract drift.

## Success Criteria
- [x] Canonical `/introspect` skill exists with hard-gate trigger modes: `pre-plan`, `post-implementation`, `after-test-failure`, `pre-push`, and `manual`.
- [x] `/instrospect` exists as a compatibility alias that routes to `/introspect`.
- [x] `/workflow` requires an `## Introspection` artifact section between `## Code Audit` and `## Plan`, with pre-plan and pre-closeout entries for file-changing work.
- [x] `/workflow` requires introspection reruns after failed verification and before push or ship decisions.
- [x] `/audit`, `/deepresearch`, `/autoplan`, and `/review` distinguish introspection from normal review and require it at the right decision points.
- [x] README, CLAUDE, AGENTS, and harness tests describe 20 skills and the hard-gate behavior consistently.
- [x] Static and live integration verification pass before commit and push.

## Scope
### In Scope
- Adding `/introspect` and `/instrospect` skill surfaces.
- Updating workflow, audit, research, planning, review, and docs contracts.
- Updating harness and smoke checks for the new skill count and introspection artifact.
- Verifying with the static harness and live `/workflow` smoke path.

### Out of Scope
- Adding a runtime service, database, or external introspection provider.
- Replacing `/review`, `/audit`, `/verify`, or `/deepresearch`; introspection complements them.
- Making every tiny local task use a large parallel self-audit wave.

## Implementation Plan
1. Add `/introspect` with trigger modes, required output, blocker behavior, and effectiveness-first parallelism.
2. Add `/instrospect` as a compatibility alias that delegates to `/introspect`.
3. Insert mandatory introspection language and artifact requirements into `/workflow`.
4. Update `/audit`, `/deepresearch`, `/autoplan`, and `/review` with the required introspection checkpoints.
5. Update docs and repo instructions from 18 to 20 skills.
6. Extend harness and smoke tests to enforce the hard-gate contract.

## Verification
- Script syntax -> `bash -n scripts/test-harness.sh` and `bash -n scripts/workflow-smoke.sh`.
- Contract drift -> targeted `rg` for stale skill counts and introspection markers.
- Static harness -> `bash scripts/test-harness.sh`.
- Live workflow -> `RUN_CLAUDE_INTEGRATION=1 bash scripts/test-harness.sh`.

## Rollback Plan
- Revert the implementation commit.
- Restore the previous active `SPEC.md` from `.taste/specs/20260424-143839-effectiveness-first-deepresearch-commands-superseded-before-new-spec.md` if needed.
