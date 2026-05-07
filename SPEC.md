# SPEC: Claude Code Native Remote Control Harness

## Problem Statement

Claude Code has native Remote Control (`/remote-control`, `/rc`,
`claude --remote-control`, and `claude remote-control`) for continuing a local
session from web or mobile. The minmaxing harness currently makes that path
fragile because the shared project settings set
`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`, and official Claude Code Remote
Control troubleshooting says that variable can make Remote Control eligibility
fail.

The harness should support Claude Code's native Remote Control without building
a separate network control plane, weakening secret protections, or claiming
runtime proof from static checks.

## Success Criteria

- [x] Shared project settings no longer set Remote Control blocker variables
  such as `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` or `DISABLE_TELEMETRY`.
- [x] The harness exposes an operator-facing `remote-control` route that
  explains the native Claude Code commands and boundaries.
- [x] A no-secret static doctor detects local blockers for native Remote
  Control and returns machine-readable JSON.
- [x] A smoke gate prevents regressions: blocker variables in shared settings,
  API-key-precedence over subscription auth, missing version evidence, and
  static runtime overclaims must fail.
- [x] The generated capability map discovers the route, script, and eval gate.
- [x] Docs distinguish native Remote Control from `claude --remote` cloud
  sessions and from any custom network control plane.
- [x] No `.env`, `.env.*`, `.claude/*.local.json`, key files, credentials, or
  private tokens are read or committed.

## Scope

In Scope:

- Use official Claude Code docs to research native Remote Control behavior.
- Patch shared harness settings to avoid known Remote Control blockers.
- Add a `remote-control` skill/route, static doctor, smoke gate, fixtures,
  eval metadata, and docs.
- Regenerate generated capability map artifacts.

Out of Scope:

- Starting a live Remote Control session during static CI.
- Reading Claude local credentials, `.env`, `.claude/*.local.json`, or managed
  organization settings.
- Building a custom HTTP/LAN/mobile control server.
- Claiming that the operator's account, organization, or mobile app is eligible
  without live authenticated runtime evidence.

## DeepResearch Brief

### Investigation Mode

Comprehensive, with a parallel research ceiling of 10 from
`bash scripts/parallel-capacity.sh --json`. Effective lanes used: 6 distinct
sidecar lanes plus local implementation, because the useful branches were repo
mapping, capability-map wiring, analogous route patterns, test/eval gates,
official docs, and adversarial review.

### Collaborative Research Plan

- Deliverable: a static, release-gated harness patch that makes Claude Code
  native Remote Control compatible with minmaxing.
- Branches:
  - official Claude Code Remote Control docs
  - official Claude Code settings/env docs
  - Codex project config and agent parallelism docs
  - local harness capability registration
  - local smoke/eval/release patterns
  - security review for remote-facing authority
- Source classes:
  - official Claude docs
  - official OpenAI Codex docs
  - repo truth surfaces
  - read-only subagent audits
- Stop condition: identify a concrete blocker and implement the smallest
  verified patch that removes it while preserving secret safety and release
  gates.

### Local Evidence

- `.claude/settings.json` currently sets
  `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`.
- No `.claude/skills/remote-control/SKILL.md`, route entry, smoke script, or
  eval gate currently exists.
- `scripts/harness-capability-map.sh` discovers `.claude/skills/*/SKILL.md`,
  route groups, related scripts, and eval tasks.
- `scripts/release-check.sh` is the static release gate that must include new
  route smokes.

### Current Product Evidence

- Claude Code Remote Control exists as native commands:
  `/remote-control`, `/rc`, `claude --remote-control`, and
  `claude remote-control`.
- Remote Control runs Claude Code locally and exposes that local session to
  Claude web/mobile; it is distinct from `claude --remote`, which starts a
  cloud session.
- Claude Code Remote Control troubleshooting lists
  `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` and `DISABLE_TELEMETRY` as
  environment variables that can make eligibility checks fail.
- Remote Control requires claude.ai subscription/OAuth-style login; API-key
  authentication and long-lived inference-only tokens are not sufficient.
- Claude Code settings support shared project `env` values and settings
  precedence, so shared project settings can create repo-wide runtime blockers.

### Source Ledger

- Claude Code Remote Control, accessed 2026-05-07:
  https://code.claude.com/docs/en/remote-control
- Claude Code on the web, accessed 2026-05-07:
  https://code.claude.com/docs/en/claude-code-on-the-web
- Claude Code settings/configuration, accessed 2026-05-07:
  https://code.claude.com/docs/en/settings
- OpenAI Codex config reference, accessed 2026-05-07:
  https://developers.openai.com/codex/config-reference

## Agent-Native Estimate

- Estimate type: agent-native.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` reported
  `codex_max_threads=10`, `recommended_ceiling=10`, `hardware_class=workstation`,
  `cores=16`, `ram_gb=32`, and `agent_teams_available=false` on 2026-05-07.
- Effective parallel budget: 6 research lanes, 1 local implementation lane.
- Agent wall-clock: 60-120 minutes.
- Agent-hours: 2-4 across research, patch, and verification.
- Human touch time: none for static implementation; live `rc` proof requires
  the operator's Claude account and mobile/web connection.
- Calendar blockers: none for static release.
- Confidence: medium-high for the blocker removal and static gate; medium for
  live account eligibility because Team/Enterprise admin policy and login state
  are external.

## Implementation Plan

### Task 1: Remove shared Remote Control blockers

Definition of Done:

- [x] `.claude/settings.json` no longer sets
  `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` or `DISABLE_TELEMETRY`.
- [x] The settings still avoid secrets and keep project hooks/denies intact.

### Task 2: Add native Remote Control harness route

Definition of Done:

- [x] `.claude/skills/remote-control/SKILL.md` documents native `rc` commands,
  prerequisites, troubleshooting, and static/runtime evidence boundaries.
- [x] README, CLAUDE, and AGENTS mention native Remote Control support.
- [x] Capability map groups `remote-control` under operations and links the
  doctor/smoke script.

### Task 3: Add static doctor and regression gate

Definition of Done:

- [x] `scripts/remote-control-doctor.sh --static --json` checks version,
  shared settings blockers, API-key-precedence warnings, and runtime proof
  status without reading secrets.
- [x] `scripts/remote-control-smoke.sh --fixtures` validates green/red fixture
  contracts.
- [x] `scripts/harness-eval.sh`, `scripts/release-check.sh`, and
  `scripts/test-harness.sh` include the route gate.
- [x] Generated capability map artifacts are regenerated.

## Verification

- [x] `bash -n scripts/remote-control-doctor.sh scripts/remote-control-smoke.sh scripts/harness-eval.sh scripts/release-check.sh scripts/test-harness.sh scripts/harness-capability-map.sh scripts/opusminimax-doctor.sh setup.sh`
- [x] `python3 -m json.tool` on changed settings examples, remote-control fixtures, and eval golden JSON.
- [x] `bash scripts/remote-control-doctor.sh --static --json`
  - Result: pass. Claude Code CLI version detected as `2.1.118`; no shared
    blocker variables; runtime proof status `not_run_static_only`.
- [x] `bash scripts/remote-control-smoke.sh --fixtures`
  - Result: pass. Green fixture accepted; red fixtures for shared blocker env,
    API-key auth, custom network control plane, static runtime proof claim, and
    token-in-URL were rejected.
- [x] `bash scripts/harness-capability-map.sh --write`
- [x] `bash scripts/harness-capability-map.sh --check --json`
  - Result: pass. Counts include 36 skills, 58 scripts, 23 eval tasks.
- [x] `bash scripts/harness-eval.sh --json`
  - Result: pass. 23 tasks, 20 gates, no mismatches; `remote-control-smoke`
    passed.
- [x] `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`
  - Result: pass. 145 passed, 0 failed.
- [x] `bash scripts/security-smoke.sh`
  - Result: pass.
- [x] `bash scripts/visualize-smoke.sh`
  - Result: pass after updating expected skill count to 36.
- [x] `bash scripts/release-check.sh --static-only`
  - Result: pass, including full static harness and `git diff --check`.

## Implementation Notes

- Removed `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` from shared settings and
  profile examples, replacing it with narrower non-RC-blocking toggles:
  `DISABLE_AUTOUPDATER`, `DISABLE_FEEDBACK_COMMAND`, and
  `DISABLE_ERROR_REPORTING`.
- Updated `setup.sh`, `setup.ps1`, and `scripts/opusminimax-doctor.sh` so local
  profile generation/repair does not reintroduce the Remote Control blocker.
- Added `.claude/skills/remote-control/SKILL.md`,
  `scripts/remote-control-doctor.sh`, `scripts/remote-control-smoke.sh`,
  `.taste/fixtures/remote-control/*`, and `evals/harness/*/m12-*`.
- Registered the route in `scripts/harness-capability-map.sh`,
  `scripts/harness-eval.sh`, `scripts/release-check.sh`,
  `scripts/test-harness.sh`, `scripts/start-session.sh`, README, CLAUDE, and
  AGENTS.

## Rollback Plan

1. Revert this commit.
2. Regenerate the capability map if needed.
3. Re-run `bash scripts/release-check.sh --static-only`.

## Introspection: Pre-Implementation

- Likely mistake: accidentally building a custom remote-control server. The
  fix must stay on Claude Code native `rc`.
- Likely mistake: removing privacy settings too broadly. Mitigation: only
  remove known Remote Control blockers from shared project settings and keep
  deny rules intact.
- Likely mistake: static doctor overclaims runtime success. Mitigation: doctor
  reports runtime proof as `not_run_static_only` unless the operator runs live
  Remote Control.
- Likely mistake: adding a skill count without updating hardcoded truth
  surfaces. Mitigation: update startup/test/visualize checks and regenerate the
  capability map.

## Introspection: Post-Implementation

- Verified mistake avoided: no custom remote-control server or network bridge
  was added. The route documents and gates only native Claude Code RC.
- Verified mistake avoided: static checks do not claim live browser/mobile
  connection. Doctor artifacts report `runtime_remote_control_started=false`
  and `runtime_proof_status=not_run_static_only`.
- Verified mistake avoided: secret protections remained intact. Shared and
  example profiles still deny `.env`, `.env.*`, `.claude/*.local.json`, and
  `secrets/**`; no secret files were read.
- Remaining live-runtime caveat: this proves harness compatibility, not the
  operator account's live RC eligibility. Team/Enterprise admin policy,
  claude.ai login state, mobile app state, and network access still require a
  manual authenticated RC run by the operator.
