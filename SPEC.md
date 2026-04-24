# SPEC: Active SPEC Archive Lifecycle

## Problem Statement

`SPEC.md` is the active workflow contract, but each new task can overwrite the previous contract and erase useful history. The harness should preserve completed or superseded specs with descriptive archive names while keeping `SPEC.md` as the current source of truth.

## Codebase Anchors

- `.claude/skills/workflow/SKILL.md` owns the end-to-end research -> audit -> plan -> spec -> execute -> verify flow.
- `.claude/skills/autoplan/SKILL.md` can create specs directly without executing implementation.
- `.claude/rules/spec.rules.md` and `.claude/rules/context.rules.md` define SPEC-first and context-reset behavior.
- `scripts/test-harness.sh` is the fast local contract suite.
- `.taste/` is already ignored and is the right home for generated workflow history.

## Success Criteria

- [ ] Existing `SPEC.md` can be archived before a new spec replaces it.
- [ ] Verified closeout can archive the final active spec with a descriptive task/outcome filename.
- [ ] Archiving is deduplicated by content hash to avoid repeated copies of the same spec.
- [ ] `/workflow` and `/autoplan` instructions tell agents when to archive versus reuse.
- [ ] README documents active specs versus archived specs.
- [ ] Test coverage verifies archive creation, metadata, filename shape, and dedupe.

## Scope

### In Scope
- Add a local `scripts/spec-archive.sh` helper.
- Add `.taste/specs/` to setup-created local directories.
- Update workflow, autoplan, spec, context, and README guidance.
- Extend test harness coverage.

### Out of Scope
- Changing `/verify` to consume archived specs by default.
- Tracking archived specs in git.
- Moving `SPEC.md` out of the project root.

## Implementation Plan

1. Add `scripts/spec-archive.sh` with `prepare`, `archive`, `closeout`, and `status` commands.
2. Update `/workflow` Phase 5 to archive non-reused active specs before replacement and Phase 8 to archive verified closeouts.
3. Update `/autoplan` and spec/context rules with the same active-versus-archive policy.
4. Update README and setup directory initialization.
5. Add a test-harness block that creates temporary specs and verifies archive behavior.

## Verification

- Archive helper behavior -> temp-dir test in `scripts/test-harness.sh`.
- Script syntax -> `bash -n scripts/spec-archive.sh`.
- Harness contract -> `bash scripts/test-harness.sh`.
- Smoke contract remains compatible -> `bash scripts/workflow-smoke.sh`.

## Rollback Plan

- Revert the commit that adds `scripts/spec-archive.sh` and documentation updates.
- Existing `.taste/specs/` files are generated local history and can be deleted without affecting active workflow execution.
