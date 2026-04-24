# SPEC: Canonical Introspect Command Surface

## Problem Statement
The hard-gate introspection mode is useful, but exposing both `/introspect` and `/instrospect` as public slash commands can confuse users into thinking there are two different modes. The repo should keep `/introspect` as the only public command and handle `instrospect` as an internal typo correction in prose, not as a documented slash-command surface.

## Codebase Anchors
- `.claude/skills/introspect/SKILL.md` is the canonical hard-gate self-audit command.
- `README.md`, `CLAUDE.md`, and `AGENTS.md` are the public and operator-facing command references.
- `.claude/skills/workflow/SKILL.md` lists specialist skills available to the workflow.
- `scripts/test-harness.sh` enforces skill count and command-contract drift.
- `scripts/workflow-smoke.sh` verifies the live workflow artifact still includes `## Introspection`.

## Success Criteria
- [x] `/introspect` remains the only public slash command for introspection.
- [x] `.claude/skills/instrospect/SKILL.md` is removed so the typo does not appear as a separate command.
- [x] README and CLAUDE list 19 skills and do not advertise `/instrospect`.
- [x] AGENTS keeps the typo behavior internal: prose misspellings can be interpreted as `/introspect`, but the public command surface stays canonical.
- [x] Harness checks enforce 19 skills, canonical `/introspect`, and no public `/instrospect` docs.
- [x] Static and live verification pass before any commit or push.

## Scope
### In Scope
- Removing the `/instrospect` skill directory.
- Updating docs, instructions, and tests from 20 to 19 public skills.
- Preserving `/introspect` hard-gate behavior and workflow smoke requirements.

### Out of Scope
- Removing the introspection hard gate itself.
- Changing deepresearch, audit, review, or verify behavior beyond command naming clarity.
- Adding a new alias/deprecation framework.

## Implementation Plan
1. Remove the `/instrospect` skill file.
2. Update `/introspect` docs to state it is the canonical command and that `instrospect` is only a prose typo correction.
3. Remove `/instrospect` from README, CLAUDE, workflow skill listings, and public skill counts.
4. Update AGENTS with internal typo-handling guidance.
5. Update harness checks to expect 19 skills and fail if public docs advertise `/instrospect`.
6. Run static and live verification.

## Verification
- Syntax -> `bash -n scripts/test-harness.sh` and `bash -n scripts/workflow-smoke.sh`.
- Drift scan -> `rg -n "/instrospect|20 skills|The 20 Skills|Expected 20|Skills - 20" README.md CLAUDE.md .claude/skills scripts/test-harness.sh`.
- Static harness -> `bash scripts/test-harness.sh`.
- Live workflow -> `RUN_CLAUDE_INTEGRATION=1 bash scripts/test-harness.sh`.

## Rollback Plan
- Revert the commit that removes the typo alias and restores the 20-skill public surface.
