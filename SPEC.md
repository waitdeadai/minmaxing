# SPEC: Trusted-Local Bypass Permissions Default

## Problem Statement

The operator uses this harness as a trusted local solo workspace and wants
Claude Code to open in `bypassPermissions` by default. The current project
settings still default to `acceptEdits`, so a plain `claude` session does not
match the intended working style.

The change must be explicit, not sneaky: the repo should warn that this is a
trusted-local posture, keep secret-read denies and governance hooks, and keep
`team-safe` available for shared or client-visible work.

## Success Criteria

- [x] `.claude/settings.json` uses `permissions.defaultMode =
  bypassPermissions`.
- [x] The default settings carry a visible trusted-local warning.
- [x] README documents that bypass is the default and explains the risk.
- [x] `team-safe` remains available and documented as the shared-work fallback.
- [x] Security docs/rules distinguish "operator default" from "team default."
- [x] Static gates validate the new default instead of silently drifting back to
  `acceptEdits`.
- [x] No `.env`, `.claude/*.local.json`, token files, or secrets are read,
  modified, or committed.

## Local Research Brief

- `.claude/settings.json` currently has provider-neutral shared settings and
  `permissions.defaultMode = acceptEdits`.
- `.claude/settings.solo-fast.example.json` already proves the trusted-local
  `bypassPermissions` posture with secret-read denies and governance hooks.
- `.claude/settings.team-safe.example.json` remains the correct fallback for
  shared work.
- `scripts/security-smoke.sh`, `scripts/test-harness.sh`, README, SECURITY,
  and runtime governance docs contain the policy language that must be updated
  so the default is honest and tested.

## Plan

1. Change the shared default permission mode to `bypassPermissions`.
2. Add explicit warning text to settings notes and README.
3. Update security docs/rules so `team-safe` remains the recommended shared
   profile, while this repo default is trusted-local.
4. Extend static tests to assert the new default and warning.
5. Regenerate the harness capability map and run static release gates.

## Agent-Native Estimate

- Estimate type: agent-native.
- Critical path: settings -> README/security docs -> smoke/test assertions ->
  generated capability map -> release static gate.
- Agent wall-clock: likely 25-45 minutes.
- Agent-hours: under 1.5.
- Human touch time later: none, except restarting Claude Code for the new
  default to apply in an interactive session.
- Confidence: high; this is a narrow policy/config/docs/test update.

## Introspection: Pre-Implementation

- Likely mistake: turning bypass into a quiet default with no warning. Guard:
  add explicit warning in settings and README, and test for the warning.
- Likely mistake: breaking team-safe semantics. Guard: keep team-safe on
  `acceptEdits` and keep security smoke asserting it.
- Likely mistake: reading or committing ignored local provider profiles while
  changing permission posture. Guard: do not inspect `.claude/*.local.json`;
  stage only tracked policy/docs/scripts.

## Verified 2026-05-06

- `python3 -m json.tool .claude/settings.json`: pass.
- `bash -n scripts/security-smoke.sh scripts/test-harness.sh scripts/harness-capability-map.sh scripts/release-check.sh`: pass.
- `bash scripts/security-smoke.sh`: pass.
- `git diff --check`: pass.
- `bash scripts/harness-capability-map.sh --write`: refreshed generated
  capability map docs/JSON after settings/docs/script hash changes.
- `bash scripts/harness-capability-map.sh --check --json`: pass.
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`137 passed`,
  `0 failed`).
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`,
  `0 mismatches`).
- `bash scripts/release-check.sh --static-only`: pass (`137 passed`,
  `0 failed`; static-only release gate passed).

## Introspection: Pre-Closeout

- Likely mistake: weakening the repo by removing all guardrails. Mitigation:
  only the default permission mode changed; secret-read denies, governance
  hooks, destructive-command blocks, and evidence-free closeout blocks remain
  tested.
- Likely mistake: making `bypassPermissions` look safe for teams. Mitigation:
  README, SECURITY, runtime governance docs, AGENTS, CLAUDE, and security rules
  all distinguish the operator's trusted-local default from `team-safe`.
- Likely mistake: release gate race from parallel execution. Observation: a
  first `release-check` run raced with `harness-eval` because both call
  `opusworkflow-smoke` with the same temporary run id. Mitigation: reran
  `release-check` by itself and it passed.
