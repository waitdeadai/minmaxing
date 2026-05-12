# SPEC: SonnetMiniMax `/opusworkflow` model profile

## Problem Statement

`/opusworkflow` has first-class routes for Opus+MiniMax, Opus+Sonnet,
all-Sonnet, all-Opus, default Claude, and custom Anthropic-only routing. It
does not have a clean governed profile for operators who want Sonnet 4.6 for
planning and review while keeping MiniMax-M2.7-highspeed as the bounded
executor.

The current workaround is a fragile planner override on the `minimax` profile.
That records mixed signals in banners, Spec QA metadata, docs, and lint rules.
The harness needs an explicit `sonnetminimax` profile so the route can be
requested, linted, smoked, and documented without overclaiming runtime model
identity.

## Success Criteria

- [x] `scripts/opusworkflow.sh`, `scripts/opusminimax.sh`, and
  `scripts/opusminimax-doctor.sh` accept `--model-profile sonnetminimax` only
  with `--executor-provider minimax`.
- [x] `sonnetminimax` defaults to `planner_model=claude-sonnet-4-6` and
  `executor_model=MiniMax-M2.7-highspeed`.
- [x] Run artifacts record Sonnet as the requested planner and Spec QA reviewer,
  MiniMax as the requested executor, and keep planner/reviewer runtime identity
  blocked until proven.
- [x] `schemas/opusminimax-run.schema.json` and `scripts/artifact-lint.sh`
  accept valid `sonnetminimax` artifacts and still reject invalid provider/model
  combinations.
- [x] `scripts/opusworkflow-smoke.sh` creates and validates a
  `sonnetminimax` artifact, including `--effort max` mapping to Claude CLI
  `xhigh`.
- [x] README, CLAUDE, AGENTS, and `/opusworkflow` / `/opusminimax` skill docs
  describe `sonnetminimax` clearly and distinguish it from `/opussonnet`.
- [x] `docs/harness-capability-map.md` and `.json` are regenerated and fresh.

## Scope

In:
- Add `sonnetminimax` as a model profile, not a new slash command or installer
  mode.
- Update routing, artifact validation, static smokes, generated capability maps,
  and operator docs.
- Preserve existing meanings for `minimax`, `opussonnet`, `sonnet`, `opus`,
  `default`, and `custom`.

Out:
- Runtime model calls, live MiniMax packet execution, or provider identity
  claims.
- New setup mode or new `.claude/skills/sonnetminimax` slash route.
- Changes to secret-bearing local profiles or `.env` files.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Capacity evidence: `scripts/parallel-capacity.sh --json` reported a local
  ceiling of 10 lanes on a workstation profile during planning.
- Effective lanes: 5 implementation packets
- Critical path: active SPEC -> routing scripts -> artifact/schema/lint ->
  smoke/tests -> docs -> capability map -> release gates
- Agent wall-clock: optimistic 45m / likely 90m / pessimistic 150m
- Human touch time: 0 unless a runtime proof lane is requested later
- Confidence: medium-high; several allowlists and docs must stay synchronized.

## Implementation Plan

1. Add the route contract to routing scripts.
   - Extend profile allowlists and provider compatibility.
   - Default `sonnetminimax` models.
   - Make selected-profile banners and Spec QA reviewer metadata accurate.

2. Add artifact validation.
   - Extend schema enum and artifact lint profile logic.
   - Add a valid SonnetMiniMax fixture.
   - Keep negative provider-boundary checks intact.

3. Add smoke coverage.
   - Extend `scripts/opusworkflow-smoke.sh` with a SonnetMiniMax artifact run.
   - Assert Sonnet planner/reviewer, MiniMax executor, provider-neutral planner,
     MiniMax executor profile, blocked identity claims, and max->xhigh effort.

4. Update docs and discoverability.
   - Update README, CLAUDE, AGENTS, and relevant skill docs.
   - Regenerate capability map artifacts.

5. Verify with the full static gate set.

## Verification

Required:

```bash
bash scripts/opusworkflow.sh --task "sonnet minimax smoke" --model-profile sonnetminimax --effort max --run-id opusworkflow-sonnetminimax-smoke
bash scripts/opusminimax-doctor.sh --static --model-profile sonnetminimax --executor-provider minimax --json
bash scripts/opusworkflow-smoke.sh
bash scripts/artifact-lint.sh --fixtures
bash scripts/security-smoke.sh
bash scripts/harness-capability-map.sh --check --json
bash scripts/harness-eval.sh --json
env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh
bash scripts/release-check.sh --static-only
git diff --check
```

Verified static closeout on 2026-05-12:

- `bash scripts/opusworkflow.sh --task "sonnet minimax smoke" --model-profile sonnetminimax --effort max --run-id opusworkflow-sonnetminimax-final-smoke`
- `bash scripts/opusminimax-doctor.sh --static --model-profile sonnetminimax --executor-provider minimax --json` exited 0 with an existing obvious-secret fixture-string warning only.
- `bash scripts/opusworkflow-smoke.sh`
- `bash scripts/artifact-lint.sh --fixtures`
- `bash scripts/security-smoke.sh`
- `bash scripts/harness-capability-map.sh --write`
- `bash scripts/harness-capability-map.sh --check --json`
- `bash scripts/harness-eval.sh --json`
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

Optional runtime proof requires explicit operator opt-in and must not be implied
by static verification.

## Rollback Plan

1. Revert the SonnetMiniMax profile commit.
2. Restore the archived `/leveragepath` spec if that work needs to resume.
3. Rerun `bash scripts/release-check.sh --static-only`.
