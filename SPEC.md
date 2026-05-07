# SPEC: Governed Claude Model Profile Flexibility

## Problem Statement

The harness can already represent the cost-optimized `/opusworkflow` default
and the optional `/opussonnet` route, but the current implementation makes model
choice too rigid. Operators should be able to request Claude Code models such as
`claude-opus-4-7`, `claude-sonnet-4-6`, `opus`, `sonnet`, `opusplan`, or a
custom model route without breaking artifacts, smokes, or safety gates.

The default must remain conservative and cost-aware. Model freedom must not
weaken provider isolation, secret safety, runtime identity honesty, or
verification requirements.

## Success Criteria

- [x] `/opusworkflow` accepts a first-class `--model-profile` selector while
  preserving the existing default behavior.
- [x] Supported profiles include `minimax`, `opussonnet`, `sonnet`, `opus`,
  `default`, and `custom`.
- [x] Existing `--executor-provider minimax|claude-sonnet` compatibility keeps
  working for current scripts and docs.
- [x] Anthropic-only profiles never inherit MiniMax base URLs, API key fields,
  or MiniMax executor model IDs.
- [x] `artifact-lint` validates model route honesty without requiring every
  planner to be Opus.
- [x] Static smokes prove the default MiniMax route, optional Opus+Sonnet route,
  all-Sonnet route, and all-Opus route.
- [x] Docs explain exact commands for switching models and state that runtime
  identity is account/session dependent until proven with `/status`, sentinel,
  or run artifact.
- [x] No `.env`, `.env.*`, `.claude/*.local.json`, key files, or secrets are
  read or committed.

## Scope

In Scope:

- Add governed model-profile resolution to the existing OpusWorkflow scripts.
- Extend run artifacts with explicit model profile and role route metadata.
- Update lint/doctor/static smokes for flexible Anthropic model profiles.
- Update README, AGENTS, CLAUDE, skills, fixtures, and generated capability map.

Out of Scope:

- Running live Claude model calls in this turn.
- Editing ignored local settings profiles or shell startup files.
- Changing the default `/opusworkflow` MiniMax-backed cost strategy.
- Claiming Opus/Sonnet runtime identity without authenticated runtime proof.

## Research Brief

### Local Evidence

- `scripts/opusworkflow.sh` currently accepts only
  `--executor-provider minimax|claude-sonnet`.
- `scripts/opusminimax.sh` defaults the planner to `claude-opus-4-7` and rejects
  executor providers outside `minimax|claude-sonnet`.
- `scripts/artifact-lint.sh` rejects any `opusminimax-run` whose planner model
  does not contain `opus`.
- `scripts/opusworkflow-smoke.sh` proves the current MiniMax default and
  optional `claude-sonnet` route but has no all-Sonnet or all-Opus route.

### Current Product Evidence

- Claude Code model configuration docs say users can switch models with
  `/model`, `claude --model`, `ANTHROPIC_MODEL`, or the `model` settings field.
- Claude Code docs define `opusplan` as Opus in plan mode and Sonnet in
  execution mode.
- Claude Code docs say `ANTHROPIC_DEFAULT_OPUS_MODEL`,
  `ANTHROPIC_DEFAULT_SONNET_MODEL`, and `CLAUDE_CODE_SUBAGENT_MODEL` control
  alias and subagent model routing.
- Claude Code docs say command-line settings override local/project/user
  settings, while managed settings remain highest priority.
- Claude Help Center lists `claude-opus-4-7` and `claude-sonnet-4-6` as
  supported Claude Code model identifiers.

### Source Ledger

- Claude Code model configuration, accessed 2026-05-07:
  https://code.claude.com/docs/en/model-config
- Claude Code CLI reference, accessed 2026-05-07:
  https://code.claude.com/docs/en/cli-reference
- Claude Code settings, accessed 2026-05-07:
  https://code.claude.com/docs/en/settings
- Claude Help Center model configuration, accessed 2026-05-07:
  https://support.claude.com/en/articles/11940350-claude-code-model-configuration

## Agent-Native Estimate

- Estimate type: agent-native.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` reported
  `codex_max_threads=10`, `recommended_ceiling=10`, `hardware_class=workstation`,
  `cores=16`, `ram_gb=32`, and `agent_teams_available=false` on 2026-05-07.
- Effective parallel budget: 1 implementation lane. The work touches coupled
  shell scripts, lint rules, fixtures, and docs, so parallel editing would
  create merge friction.
- Agent wall-clock: 60-120 minutes.
- Agent-hours: 1.5-3.0.
- Human touch time: none for static implementation. Runtime model proof remains
  account/session dependent.
- Calendar blockers: none for static release.
- Confidence: medium. Static gates can prove routing and safety invariants, not
  live model availability for the operator's Claude account.

## Implementation Plan

### Task 1: Add model profile resolution

Definition of Done:

- [x] `scripts/opusworkflow.sh` exposes `--model-profile`.
- [x] `scripts/opusminimax.sh` resolves model profiles to planner/executor
  provider and model IDs.
- [x] Backward-compatible `--executor-provider claude-sonnet` still maps to the
  Opus+Sonnet route.

### Task 2: Relax lint while preserving honesty

Definition of Done:

- [x] `scripts/artifact-lint.sh` accepts Anthropic model routes without MiniMax
  base URLs.
- [x] Lint still rejects MiniMax leakage into Anthropic profiles.
- [x] Lint still rejects Opus runtime claims without model identity proof.

### Task 3: Update smokes and docs

Definition of Done:

- [x] `scripts/opusworkflow-smoke.sh` validates default, Opus+Sonnet, all-Sonnet,
  and all-Opus static artifacts.
- [x] Fixture coverage includes at least one Anthropic flexible model route.
- [x] README, AGENTS, CLAUDE, and route skills document the selector.
- [x] Capability map is regenerated.

## Verification

- `bash -n scripts/opusworkflow.sh scripts/opusminimax.sh scripts/opusminimax-doctor.sh scripts/artifact-lint.sh scripts/opusworkflow-smoke.sh`
- `python3 -m json.tool` on changed JSON fixtures and settings examples.
- `bash scripts/opusworkflow-smoke.sh`
- `bash scripts/artifact-lint.sh --fixtures`
- `bash scripts/security-smoke.sh`
- `bash scripts/harness-capability-map.sh --write`
- `bash scripts/harness-capability-map.sh --check --json`
- `bash scripts/harness-eval.sh --json`
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

## Rollback Plan

1. Revert this commit.
2. Regenerate the capability map if needed.
3. Verify rollback with `bash scripts/opusworkflow-smoke.sh` and
   `bash scripts/release-check.sh --static-only`.

## Introspection: Pre-Implementation

- Likely mistake: weakening the MiniMax/Anthropic boundary. Mitigation: lint
  must still reject MiniMax URLs or MiniMax model IDs in Anthropic profiles.
- Likely mistake: making all-Opus look like the new default. Mitigation:
  default remains `minimax`; docs label Opus-only as explicit and expensive.
- Likely mistake: treating static profile selection as runtime proof.
  Mitigation: artifacts keep identity status `blocked` or `runtime-pending`
  until `/status`, sentinel, or equivalent run evidence proves the model.
- Likely mistake: breaking existing `--executor-provider claude-sonnet` users.
  Mitigation: keep it as a backward-compatible alias for `opussonnet`.

## Verified 2026-05-07

- `bash -n scripts/opusworkflow.sh scripts/opusminimax.sh scripts/opusminimax-doctor.sh scripts/artifact-lint.sh scripts/opusworkflow-smoke.sh scripts/opussonnetworkflow.sh scripts/test-harness.sh`: pass.
- `python3 -m json.tool schemas/opusminimax-run.schema.json` and
  `.taste/fixtures/artifact-lint/green/valid-sonnet-model-profile-run.json`:
  pass.
- `bash scripts/opusworkflow-smoke.sh`: pass; validates default MiniMax,
  backward-compatible Opus+Sonnet, all-Sonnet, and all-Opus static artifacts.
- `bash scripts/artifact-lint.sh --fixtures`: pass (`9 green`, `22 red`).
- `bash scripts/opusminimax-doctor.sh --static --model-profile minimax --executor-provider minimax --json`: pass with existing tracked test/fixture secret-string warning.
- `bash scripts/opusminimax-doctor.sh --static --model-profile opussonnet --executor-provider claude-sonnet --json`: pass with existing tracked test/fixture secret-string warning.
- `bash scripts/opusminimax-doctor.sh --static --model-profile sonnet --executor-provider anthropic --json`: pass with existing tracked test/fixture secret-string warning.
- `bash scripts/opusminimax-doctor.sh --static --model-profile opus --executor-provider anthropic --json`: pass with existing tracked test/fixture secret-string warning.
- `bash scripts/opusworkflow.sh --task "default profile smoke" --model-profile default --run-id manual-profile-default` plus artifact lint: pass; runtime not executed.
- `bash scripts/opusworkflow.sh --task "custom profile smoke" --model-profile custom --planner-model claude-sonnet-4-6 --executor-model claude-sonnet-4-6 --run-id manual-profile-custom` plus artifact lint: pass; runtime not executed.
- `bash scripts/opusworkflow.sh --task "bad profile smoke" --model-profile sonnet --executor-provider minimax --run-id manual-profile-bad`: correctly exits 2.
- `bash scripts/security-smoke.sh`: pass.
- `bash scripts/harness-capability-map.sh --write` and
  `bash scripts/harness-capability-map.sh --check --json`: pass.
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`,
  `0 mismatches`).
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`141 passed`,
  `0 failed`; workflow runtime smoke intentionally skipped).
- `bash scripts/release-check.sh --static-only`: pass.
- `git diff --check`: pass.

## Introspection: Pre-Closeout

- Likely mistake checked: this could make all-Opus look like the new default.
  The default remains `model_profile=minimax`; `opus` is explicit and documented
  as a high-cost route.
- Likely mistake checked: Anthropic profiles could leak MiniMax provider state.
  `artifact-lint` rejects MiniMax base URLs and MiniMax executor model IDs in
  Anthropic routes, and the smoke covers Sonnet/Opus profiles.
- Likely mistake checked: static model selection could be overclaimed as runtime
  model proof. Artifacts keep `model_identity_confirmed=false`,
  `planner_identity_status=blocked`, and `verification.status=runtime-pending`
  until `/status`, sentinel, or equivalent runtime evidence proves identity.
- Remaining risk: live account availability and usage thresholds can still make
  Claude Code fall back or block at runtime. This implementation proves the
  harness no longer breaks statically when the operator requests a different
  governed model route.
