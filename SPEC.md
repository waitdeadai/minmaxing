# SPEC: Runtime Hardening Wave

## Problem Statement

The harness now has strong planning, estimation, parallel, security, memory, CI,
and documentation contracts. The next weakness is runtime proof: minmaxing must
record what actually happened, use more of Claude Code's hook surface, support
isolated worktree execution, run scenario-style harness evals, learn from real
runs, and expose operator health in one place.

This wave implements the post-roadmap benchmark audit recommendations:

- M10 Trace Ledger
- M11 Worktree Runner
- M12 Full Claude Hook Mesh
- M13 Scenario Eval Harness
- M14 Learning Loop
- M15 Harness Doctor

The target runtime remains Claude Code. Codex is the implementation
orchestrator for this wave and may use bounded parallel agents for disjoint
implementation packets.

## Research Brief

The previous benchmark audit found that strong 2026 harnesses are moving beyond
prompt contracts toward traceability, isolated execution, telemetry, action-risk
analysis, managed parallelism, scenario evals, and session learning.

Key local anchors:

- `BEST_HARNESS_DEEPRESEARCH_PLAN_2026.md` already identified traces,
  schemas, hooks, evals, metrics, and CI as the path from static harness to
  runtime harness.
- `README.md` defines effectiveness as evidence from `SPEC.md`,
  Agent-Native Estimates, parent-verified worker outputs, aggregate
  verification, memory checks, and command-backed closeout.
- `scripts/run-metrics.sh` and `scripts/session-insights.sh` intentionally
  report provider cost, token, ACU, and calibration as `insufficient_data`
  when unavailable.
- `.claude/settings.json` currently wires governance to `PreToolUse` Bash,
  `Stop`, and `SubagentStop`; Claude Code exposes more useful runtime events
  than the current mesh uses.
- `scripts/parallel-aggregate.sh` validates run artifacts, but it does not
  create or supervise isolated worktrees.
- `scripts/harness-eval.sh` validates static harness metadata; it is not yet a
  scenario executor over live gate commands.

## Success Criteria

- [x] Add a local trace ledger with append, validate, summary, and fixture
      modes.
- [x] Wire a broader Claude hook mesh without making unsupported claims about
      authenticated runtime proof.
- [x] Add a worktree runner that validates packet ownership and can dry-run or
      execute isolated packet commands.
- [x] Add scenario evals that execute local no-secret gates and return
      per-scenario pass/fail reasons.
- [x] Add a learning loop that derives verified run insights without inventing
      provider telemetry.
- [x] Add a harness doctor that produces a single text/JSON/HTML operator
      summary.
- [x] Add smoke gates and release-check integration for the new runtime
      hardening surfaces.
- [x] Keep public/open-core boundaries intact; no private REVCLI runtime,
      customer memory, credentials, or commercial playbooks.
- [x] Keep skill count stable unless a new user-facing skill is intentionally
      added. This wave should add scripts and docs, not a new slash command.
- [x] Update docs to describe the runtime-hardening layer as local evidence,
      not as a managed cloud agent platform.

## Scope

### In Scope

- Local JSONL trace artifacts under `.taste/traces/`.
- Hook smoke coverage for extra Claude Code hook events.
- Worktree packet validation and optional local execution.
- Scenario eval metadata and runner scripts.
- Learning summaries from workflow, trace, eval, and memory artifacts.
- Operator-facing doctor report.
- Static/offline smoke tests.

### Out Of Scope

- Scheduler daemon.
- Hosted dashboard service.
- Real provider token/cost/ACU telemetry unless already available locally.
- Authenticated Claude runtime proof in public CI.
- Claude agent teams as default runtime.
- Private runtime/customer artifacts.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: subagents
- Capacity evidence: `scripts/parallel-capacity.sh --json` reports workstation,
  16 cores, 32GB RAM, Codex `max_threads` 10, recommended ceiling 10, default
  substrate `subagents`
- Effective lanes: 5 of ceiling 10 because the work has five mostly disjoint
  script surfaces, but final settings/test integration is a supervisor
  bottleneck
- Critical path: active spec -> parallel packet patches -> hook/settings
  integration -> smoke/release gates -> docs -> verification -> closeout
- Agent wall-clock: optimistic 6 hours / likely 12 hours / pessimistic 24 hours
- Agent-hours: 45-90 active agent-hours across implementation, fixtures,
  integration, and verification
- Human touch time: 1-3 hours for reviewing hook strictness, worktree execution
  posture, and public claims
- Calendar blockers: authenticated Claude runtime proof and provider cost/token
  telemetry remain unavailable unless local credentials/settings are provided
- Confidence: medium because shell/script implementation is deterministic, but
  Claude Code hook payload edge cases require conservative fixture-based gating
- Human-equivalent baseline: 1-2 engineer-weeks, secondary comparison only

## Parallel Packet Plan

| Packet | Owner | Scope | Owns | Must Not Touch |
|---|---|---|---|---|
| P0-main | Codex main | SPEC, worker coordination, settings/test integration, final verification | `SPEC.md`, `README.md`, `scripts/test-harness.sh`, `scripts/release-check.sh`, final `.claude/settings.json` merge | worker-owned implementation scripts unless resolving conflicts |
| P1-trace | worker | Trace ledger | `scripts/trace-ledger.sh`, `.taste/fixtures/trace-ledger/`, optional trace schema/doc | hook mesh, worktree runner, test harness |
| P2-hooks | worker | Hook mesh script behavior and fixtures | `.claude/hooks/govern-effectiveness.sh`, `scripts/hook-mesh-smoke.sh`, `.taste/fixtures/hook-mesh/` | final `.claude/settings.json`, trace ledger |
| P3-worktree | worker | Worktree runner | `scripts/worktree-runner.sh`, `.taste/fixtures/worktree-runner/` | parallel aggregate script, test harness |
| P4-evals-learning | worker | Scenario eval and learning loop | `scripts/scenario-eval.sh`, `scripts/learning-loop.sh`, `evals/scenarios/`, `.taste/fixtures/learning-loop/` | trace ledger, hook mesh |
| P5-doctor | worker | Operator report | `scripts/harness-doctor.sh`, optional `docs/runtime-hardening.md` | test harness, release-check |

## Implementation Plan

- [x] Spawn bounded parallel agents for P1-P5.
- [x] Main integrates the new hook mapping and smoke gates after worker patches.
- [x] Add a runtime-hardening smoke gate that composes all new scripts.
- [x] Update README/docs with a concise runtime-hardening surface.
- [x] Run targeted script checks.
- [x] Run full harness and release checks.
- [x] Record closeout evidence and archive this spec after verification.

## Verification

Target commands:

- `git status --short`
- `bash scripts/parallel-capacity.sh --json`
- `python3 -m json.tool .claude/settings.json`
- `bash -n scripts/*.sh`
- `bash scripts/trace-ledger.sh --fixtures`
- `bash scripts/hook-mesh-smoke.sh`
- `bash scripts/worktree-runner.sh --fixtures`
- `bash scripts/scenario-eval.sh --fixtures`
- `bash scripts/learning-loop.sh --fixtures`
- `bash scripts/harness-doctor.sh --json`
- `bash scripts/runtime-hardening-smoke.sh`
- `bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

Verified on 2026-05-01:

- `bash scripts/parallel-capacity.sh --json`: pass, recommended ceiling 10,
  default substrate `subagents`
- `python3 -m json.tool .claude/settings.json`: pass
- `bash -n scripts/*.sh`: pass
- `bash scripts/trace-ledger.sh --fixtures`: pass
- `bash scripts/hook-mesh-smoke.sh`: pass, 11 fixtures
- `bash scripts/worktree-runner.sh --fixtures`: pass
- `bash scripts/scenario-eval.sh --fixtures`: pass, 3 scenarios, 0 failed
- `bash scripts/learning-loop.sh --fixtures`: pass, expected
  `needs_attention` fixture taxonomy with telemetry as `insufficient_data`
- `bash scripts/harness-doctor.sh --json`: pass, JSON parses and reports
  provider telemetry as `insufficient_data`
- `bash scripts/runtime-hardening-smoke.sh`: pass
- `bash scripts/test-harness.sh`: pass, 98 passed, 0 failed
- `bash scripts/release-check.sh --static-only`: pass, includes full harness
  and `git diff --check`
- `bash scripts/spec-archive.sh closeout "Runtime Hardening Wave"
  "verified: runtime-hardening-smoke, full harness 98/0, release-check
  static-only passed"`: pass

Authenticated runtime proof:

- `RUN_CLAUDE_INTEGRATION=1 bash scripts/test-harness.sh` only when local
  Claude Code credentials/settings are available and safe to use.

Not run in this wave because authenticated runtime credentials/settings were
not enabled in the environment.

## Rollback Plan

1. Revert new runtime-hardening scripts, fixtures, docs, and test harness
   integration.
2. Restore the previous `.claude/settings.json` hook mapping from git.
3. Keep archived M9 spec untouched.
4. If partially implemented, archive this `SPEC.md` with `prepare` outcome
   before replacing it.
