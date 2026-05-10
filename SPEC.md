# SPEC: OpusWorkflow Plan Mode Auto-Approval

## Problem Statement

`/opusworkflow` already wraps the governed `/workflow` lifecycle, but its
machine-readable run artifact did not prove that the plan-to-execution
transition was approved by the same gates that make native plan mode effective:
read-only/codebase analysis, a concrete plan, and approval before edits. The
user wants `/opusworkflow` to auto-approve that transition by default, without
turning the general workflow into a manual approval pause.

## Codebase Anchors

- `.claude/skills/opusworkflow/SKILL.md` owns the user-facing contract for the
  definitive mutating route.
- `scripts/opusworkflow.sh` is the wrapper that should expose the operator
  policy and forward it to the engine.
- `scripts/opusminimax.sh` creates `.taste/opusminimax/{run_id}/opusminimax-run.json`,
  so it is the right place to record plan-mode approval state.
- `scripts/artifact-lint.sh`, `schemas/opusminimax-run.schema.json`,
  `.taste/fixtures/artifact-lint/*`, and `scripts/opusworkflow-smoke.sh` are the
  static proof surfaces for governance fields.
- `.claude/skills/workflow/SKILL.md` already defines research -> code audit ->
  introspection -> plan -> Agent-Native Estimate -> `SPEC.md` -> `/specqa` ->
  execution -> verification.
- `/visualizeworkflow` remains the approval-first visual route and must not be
  weakened by automatic approval elsewhere.

## Current Research Brief

Investigation mode: comprehensive.

Time anchor: 2026-05-10, America/Argentina/Mendoza.

Effective research budget: 3 tracks of local ceiling 10. Capacity evidence:
`bash scripts/parallel-capacity.sh --json` reported `codex_max_threads=10`,
`recommended_ceiling=10`, `cores=16`, `ram_gb=32`, and
`agent_teams_available=false`. The useful tracks were official Claude Code
plan/permission behavior, repo `/opusworkflow` planning surfaces, and
artifact/test gate surfaces.

Source ledger:

- Claude Code common workflows, accessed 2026-05-10:
  https://code.claude.com/docs/en/tutorials
  - Plan before editing is intended for reviewing changes before they touch
    disk; Claude reads files and proposes a plan before approval.
- Claude Code permission modes, accessed 2026-05-10:
  https://code.claude.com/docs/en/permission-modes
  - Native plan mode can be made a project default with
    `permissions.defaultMode=plan`. Auto mode is separate, account-dependent,
    and uses a classifier; it is not the same thing as this harness gate.
- Claude Code model configuration, accessed 2026-05-10:
  https://code.claude.com/docs/en/model-config
  - `opusplan` uses Opus in plan mode and Sonnet in execution mode; current
    alias/model behavior is provider and account dependent, so runtime identity
    proof remains required before claiming Opus executed.

Local evidence:

- `/workflow` already has the plan-before-spec lifecycle and Spec QA gate.
- `/autoplan` explicitly says it writes `SPEC.md` directly and does not switch
  Claude Code into native plan mode.
- `/opusworkflow` had Spec QA, introspection, and provider split rules but no
  `plan_mode` artifact field.
- `artifact-lint` is the semantic gate; the JSON schema allows extra fields, so
  schema-only changes are not enough.

Conflicting evidence:

- Native Claude Code Plan Mode is read-only until approval, while this harness
  runs in a trusted-local profile and must continue automatically for normal
  `/opusworkflow` work. Resolution: model the feature as a workflow transition
  checkpoint with artifact evidence, not as a global permission-profile change.

## Success Criteria

- [x] `/opusworkflow` exposes default `--plan-mode-policy auto` plus
  `manual|off` advanced options.
- [x] `/opusminimax` accepts and records `plan_mode` in every prepared
  `/opusworkflow` run artifact.
- [x] The default artifact records
  `plan_mode.auto_approval.status=auto_approved_when_gates_pass`.
- [x] The gate lists the required execution prerequisites: research brief, code
  audit, `/introspect pre-plan`, Agent-Native Estimate, `SPEC.md`, and
  `/specqa` execution allowance.
- [x] The gate explicitly does not replace `SPEC.md`, `/specqa`, `/introspect`,
  `/verify`, runtime model identity proof, or `/visualizeworkflow` human
  approval.
- [x] `artifact-lint --fixtures` accepts green `/opusworkflow` run fixtures and
  rejects a missing-plan-mode red fixture.
- [x] `scripts/opusworkflow-smoke.sh` asserts the new artifact fields.
- [x] README, CLAUDE, AGENTS, workflow, and engine docs explain the new behavior
  without implying native Claude Code Plan Mode or Auto Mode proof.

## Scope

### In Scope

- Add CLI/env policy plumbing to `scripts/opusworkflow.sh` and
  `scripts/opusminimax.sh`.
- Add `plan_mode` artifact shape, schema documentation, semantic linting,
  fixtures, and smoke assertions.
- Update public route docs and generated capability-map outputs.

### Out of Scope

- Changing committed `.claude/settings.json` default permission mode.
- Enabling Claude Code native Auto Mode or depending on account-specific
  classifier behavior.
- Proving live Opus/opusplan runtime identity in static tests.
- Changing `/visualizeworkflow` approval semantics.
- Building a new standalone `/plan` skill.

## Surgical Diff Discipline

- Smallest sufficient implementation: add a policy flag and artifact gate to
  existing `/opusworkflow` -> `/opusminimax` plumbing.
- No speculative abstractions: no new daemon, hook state machine, permission
  profile rewrite, or separate smoke script.
- No drive-by refactors: leave unrelated setup, provider, hook, and visual
  approval behavior untouched.
- Changed-line trace:
  - Wrapper and engine script edits map to success criteria 1-5.
  - Lint/schema/fixture/smoke edits map to success criteria 3-7.
  - Docs and generated map edits map to success criterion 8.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock.
- Execution topology: local supervisor plus 2 read-only repo subagents.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json`, Codex
  `max_threads=10`, recommended ceiling 10.
- Effective lanes: 3 of ceiling 10 for research/audit, 1 implementation lane.
- Critical path: source research -> repo audit -> spec update -> script/artifact
  patch -> docs -> generated map -> static release gates -> push.
- Agent wall-clock: optimistic 50 minutes / likely 90 minutes / pessimistic 3
  hours.
- Agent-hours: 3-5 active hours across research, patching, verification, and
  repair.
- Human touch time: none expected for static harness implementation.
- Calendar blockers: none for local static gates; runtime Claude account access
  remains outside this static proof.
- Confidence: medium-high; downgraded because live native Claude Code plan/auto
  mode availability remains account-dependent and is intentionally not claimed.

## Implementation Plan

1. Add `--plan-mode-policy auto|manual|off` to `scripts/opusworkflow.sh`, with
   default `auto` and forwarding to `scripts/opusminimax.sh`.
2. Add policy validation to `scripts/opusminimax.sh` and emit `plan_mode` in the
   run artifact.
3. Add semantic lint checks and fixtures for the new artifact field.
4. Extend `scripts/opusworkflow-smoke.sh` and `scripts/test-harness.sh` static
   expectations.
5. Update `/opusworkflow`, `/opusminimax`, `/workflow`, README, CLAUDE, AGENTS,
   and startup text.
6. Regenerate the harness capability map and update m9 golden evidence.
7. Run focused and release verification, repair any failures, then push.

## Verification

- Script syntax: `bash -n scripts/opusworkflow.sh scripts/opusminimax.sh scripts/artifact-lint.sh scripts/opusworkflow-smoke.sh scripts/test-harness.sh`
- Artifact fixtures: `bash scripts/artifact-lint.sh --fixtures`
- OpusWorkflow gate: `bash scripts/opusworkflow-smoke.sh`
- Capability map: `bash scripts/harness-capability-map.sh --check --json`
- Release gate: `bash scripts/release-check.sh --static-only`
- JSON validity: `python3 -m json.tool` for changed fixtures, schema, and eval
  golden files.
- Diff hygiene: `git diff --check`

## Rollback Plan

- Revert this commit to remove the `plan_mode` artifact contract and docs.
- If only the policy default is problematic, set `OPUSWORKFLOW_PLAN_MODE_POLICY=off`
  or invoke `scripts/opusworkflow.sh --plan-mode-policy off` while preserving the
  rest of the `/opusworkflow` provider split.
