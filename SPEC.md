# SPEC: OpusWorkflow Default For Mutating Work

## Problem Statement

The harness already recommends `/opusworkflow` for ordinary build and plan work,
but several routing surfaces still present `/workflow`, `/agentfactory`,
`/hiveworkflow`, and other mutating skills as separate non-hybrid execution
islands. The operator wants one standard: Claude/Opus plans, criticizes, and
reviews when proven available; MiniMax-M2.7-highspeed performs coding and repair
packets.

The harness must make that default explicit without deleting specialized
contracts. A governed Hermes agent still needs `/agentfactory`; a coordinated
multi-agent build still needs `/hiveworkflow`; taste evolution still needs
`/defineicp` or `/deepretaste`. The difference is that mutating specialist work
inherits the `/opusworkflow` provider split by default.

## Success Criteria

- [x] File-changing routes identify `/opusworkflow` as the default outer route.
- [x] Specialized mutating skills declare that they inherit the Opus planner plus
  MiniMax executor split by default.
- [x] Plain `/workflow` remains available only as explicit user override,
  provider-split fallback, or intentionally local supervisor loop.
- [x] `/opusminimax` run artifacts include `outer_route`, `inner_contract`,
  planner/executor identity status, and fallback status.
- [x] Runtime planner execution diagnoses and repairs safe local profile issues
  before failing, but never fakes Opus or enables PAYG silently.
- [x] Static smokes and metacognition fixtures cover ordinary, AgentFactory, and
  Hive routing through `/opusworkflow`.
- [x] No `.env`, `.env.*`, `.claude/*.local.json`, key files, or secrets are read
  or committed.
- [x] Release gates pass before push.

## Research Brief

### Local Evidence

- `AGENTS.md` already says `/opusworkflow` is the default outer route for
  ordinary build/plan work, but direct specialized routes remain more prominent
  in `/workflow` and `/metacognition`.
- `.claude/skills/opusworkflow/SKILL.md` defines the budget policy:
  Opus for judgment gates, MiniMax-M2.7-highspeed for implementation, executor
  concurrency `1` until provider evidence proves otherwise.
- `scripts/opusminimax.sh` currently writes placeholder `opusminimax-run`
  artifacts, but does not record `outer_route`, `inner_contract`,
  `planner_identity_status`, `executor_identity_status`, or `fallback_status`.
- `scripts/opusminimax-doctor.sh` validates committed example profiles and
  runtime Claude auth/version state, but has no safe local profile repair mode.
- `scripts/opusworkflow-smoke.sh` and `scripts/test-harness.sh` already protect
  the default `/opusworkflow` install and docs surface.

### Current Product Evidence

- Claude Code settings docs define shareable project settings and ignored local
  settings levels, supporting the repo's provider-neutral shared settings plus
  local planner/executor profiles.
- Claude Code model configuration docs say the `default` model depends on
  account type and may fall back when Opus usage thresholds are hit; this
  supports blocking fake Opus claims and requiring model-identity evidence.
- Claude Code hooks docs define project hooks and exit-code behavior; the
  existing governance hooks remain the enforcement surface for closeout quality.

### Source Ledger

- Claude Code settings: https://code.claude.com/docs/en/configuration
- Claude Code model configuration: https://code.claude.com/docs/en/model-config
- Claude Code hooks: https://code.claude.com/docs/en/hooks

## Plan

1. Extend `/opusminimax` and `/opusworkflow` artifacts with the new route,
   identity, and fallback fields. Default `outer_route=opusworkflow` and infer
   `inner_contract` from an optional CLI flag, defaulting to `workflow`.
2. Extend `scripts/opusminimax-doctor.sh` with `--fix-local-profiles`:
   create/repair ignored local profile structure, remove MiniMax base URL from
   planner local profile, ensure MiniMax model is executor-only, preserve
   unknown local keys, and never print secrets.
3. Before `--execute-planner`, run runtime doctor repair/checks. If local repair
   cannot prove a safe planner path, fail with exact auth/account/API-key
   instructions rather than silently degrading.
4. Update routing contracts in docs and skills so mutating specialized routes
   inherit `/opusworkflow` by default.
5. Update smokes and fixtures to prove ordinary, AgentFactory, Hive, direct
   fallback, and Opus-unavailable routing semantics.
6. Regenerate the harness capability map and run the required gates.

## Agent-Native Estimate

- Estimate type: agent-native.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` reported
  `recommended_ceiling=10`, `codex_max_threads=10`, `hardware_class=workstation`
  on 2026-05-07T07:44:30-03:00.
- Effective parallel budget: 1 main implementation lane. The change is tightly
  coupled across routing docs, one doctor script, one artifact writer, and
  static gates; parallel edits would add review overhead.
- Agent wall-clock: 60-120 minutes.
- Agent-hours: 1.5-3.
- Human touch time: none expected unless runtime Opus account access must be
  proven.
- Calendar blockers: none for static implementation.
- Confidence: medium. The behavior is mostly static and testable, but runtime
  model identity remains account-dependent by design.

## Introspection: Pre-Implementation

- Likely mistake: replacing specialist contracts with `/opusworkflow` and losing
  AgentFactory/Hive safeguards. Mitigation: make `/opusworkflow` the outer route
  while preserving `inner_contract`.
- Likely mistake: fake Opus claims. Mitigation: artifacts default
  `planner_identity_status=blocked` or `not_required` until runtime proof exists.
- Likely mistake: local profile repair overwrites user credentials. Mitigation:
  do not read secret files, do not print values, and preserve unknown local env
  keys while removing only unsafe planner MiniMax routing keys.
- Likely mistake: making plain `/workflow` impossible. Mitigation: keep it as an
  explicit override/fallback and document the boundary.

## Verified 2026-05-07

- `bash -n scripts/opusminimax-doctor.sh scripts/opusminimax.sh scripts/opusworkflow.sh scripts/opusworkflow-smoke.sh scripts/test-harness.sh scripts/artifact-lint.sh scripts/metacognition-scorecard.sh`: pass.
- `bash scripts/artifact-lint.sh --fixtures`: pass (`7 green`, `22 red`).
- `bash scripts/opusworkflow-smoke.sh`: pass; it now validates
  `inner_contract=workflow`, `agentfactory`, and `hiveworkflow` artifacts.
- `bash scripts/opusminimax-doctor.sh --static`: exits 0 with no failures and
  warns only on existing tracked fixture/test placeholder strings.
- `bash scripts/metacognition-scorecard.sh --fixtures --json`: pass (`7 green`,
  `11 red`).
- `bash scripts/harness-capability-map.sh --check`: pass after regeneration.
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`,
  `0 mismatches`).
- `bash scripts/security-smoke.sh`: pass.
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`138 passed`,
  `0 failed`; workflow smoke skipped by static CI mode).
- `git diff --check`: pass.
- `bash scripts/release-check.sh --static-only`: pass (`138 passed`,
  `0 failed`; static-only release gate passed).

## Introspection: Pre-Closeout

- Likely mistake: overclaiming runtime proof. This implementation adds runtime
  diagnosis and local profile repair, but static checks still do not prove real
  Opus or MiniMax model calls.
- Likely mistake: hiding specialist routes. The routes remain direct commands,
  but mutating use now records them as `inner_contract` under `/opusworkflow`.
- Likely mistake: local profile repair could overwrite credentials. The repair
  function preserves unknown local env keys, removes only unsafe planner
  MiniMax routing keys, and never prints values.
- Remaining risk: `--runtime --fix-local-profiles` is intentionally not run in
  static release gates because it can touch ignored local profiles. Runtime
  account/auth proof remains operator opt-in.
