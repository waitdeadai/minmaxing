# SPEC: `/opusminimax` Opus Planner + MiniMax Executor System

## Problem Statement

The harness currently works as a MiniMax-backed Claude Code setup, but it does
not provide a trustworthy Opus-planner plus MiniMax-executor split. Mapping
Claude model aliases to MiniMax is fast, but it makes claims such as "Opus
planned this" unprovable and turns `/opusminimax` into a model switch rather
than a governed execution system.

The repo needs a first-class `/opusminimax` mode where Claude Code/Opus is used
sparingly for planning, adversarial review, and final judgment, while
MiniMax-M2.7-highspeed handles bounded execution packets. The system must be
quota-aware, evidence-backed, and compatible with the existing `/deepresearch`,
`/parallel`, `/workflow`, `/verify`, and `/introspect` contracts.

## Success Criteria

- [x] `.claude/skills/opusminimax/SKILL.md` exists with manual-only Claude Code
  skill frontmatter and an explicit planner/adversary/reviewer versus executor
  banner.
- [x] Shared `.claude/settings.json` is provider-neutral and no longer maps
  Opus/Sonnet/Haiku aliases to MiniMax.
- [x] Committed example profiles separate the Opus planner from the MiniMax
  executor without committing credentials.
- [x] `.gitignore` covers local OpusMiniMax profile files and run artifacts.
- [x] `setup.sh --mode opusminimax` supports `--minimax-key-file`,
  `--minimax-key`, `--planner-model`, `--executor-model`, and
  `--profile solo-fast|team-safe`.
- [x] `scripts/opusminimax.sh`, `scripts/minimax-exec.sh`,
  `scripts/opusminimax-doctor.sh`, and
  `scripts/opusminimax-benchmark-smoke.sh` exist and are executable.
- [x] Artifact schemas and `scripts/artifact-lint.sh` support
  `opusminimax-packet`, `opusminimax-run`, and
  `opusminimax-benchmark-result`.
- [x] Static fixtures reject fake Opus claims, planner profiles using a
  MiniMax base URL, executor profiles missing MiniMax, secret-bearing configs,
  concurrency above provider ceiling, failed-verification positive closeout,
  and benchmark aggregates without per-task evidence.
- [x] Harness capability map, README, CLAUDE.md, AGENTS.md, and session startup
  surfaces discover `/opusminimax` as a core execution mode.
- [x] Static gates pass without running authenticated Claude or MiniMax smoke
  tests.

## Research Brief

### Collaborative Research Plan

- Deliverable: a repo-native `/opusminimax` mode, not a prompt-only workflow.
- Branches:
  - Repo integration: existing skills, route groups, static gates, settings,
    setup, and artifact linting.
  - Claude Code product behavior: model aliases, `opusplan`, settings priority,
    Pro subscription caveats, skills, hooks, and subagents.
  - MiniMax compatibility: Anthropic-compatible endpoint, exact highspeed model,
    Token Plan limits, cache behavior, and unsupported content/params.
  - Benchmark discipline: SWE-bench, SWE-agent, Agentless, Terminal-Bench, and
    fresh/private benchmark caveats.
  - Adversarial review: quota footguns, false provider claims, security profile
    leakage, runtime bridge proof, and benchmark overclaims.
- Stop condition: enough evidence to implement a static, no-secret v1 with
  explicit runtime opt-in and no false model-identity claims.

### Source Ledger

- Cited local truth:
  - `AGENTS.md`: research-first, `/parallel`, `/introspect`, open-core,
    capacity, SPEC archive, and release-gate rules.
  - `CLAUDE.md`: existing skill list, workflow lifecycle, artifact sidecars,
    security profiles, and capability-map gate.
  - `scripts/harness-capability-map.sh`: generated skill/script/eval map.
  - `scripts/artifact-lint.sh`: existing sidecar validation pattern.
  - `scripts/security-smoke.sh`: existing profile and hook smoke pattern.
  - `setup.sh`: current one-command installer and MiniMax credential path.
- Cited external sources from the investigation:
  - `https://code.claude.com/docs/en/model-config`
  - `https://code.claude.com/docs/en/cli-reference`
  - `https://code.claude.com/docs/en/settings`
  - `https://code.claude.com/docs/en/skills`
  - `https://code.claude.com/docs/en/sub-agents`
  - `https://code.claude.com/docs/en/hooks`
  - `https://support.claude.com/en/articles/11145838-use-claude-code-with-your-pro-or-max-plan`
  - `https://support.claude.com/en/articles/14552983-models-usage-and-limits-in-claude-code`
  - `https://platform.minimax.io/docs/api-reference/text-anthropic-api`
  - `https://platform.minimax.io/docs/guides/text-ai-coding-tools`
  - `https://platform.minimax.io/docs/token-plan/intro`
  - `https://arxiv.org/abs/2310.06770`
  - `https://github.com/SWE-bench/SWE-bench`
  - `https://www.swebench.com/SWE-bench/api/harness/`
  - `https://arxiv.org/abs/2405.15793`
  - `https://arxiv.org/abs/2407.01489`
  - `https://github.com/harbor-framework/terminal-bench`
  - `https://www.tbench.ai/`
  - `https://arxiv.org/abs/2509.16941`
- Conflicts:
  - `opusplan` matches Anthropic's Opus-plan/Sonnet-execute pattern, but not an
    external MiniMax executor. This spec uses explicit Opus planner artifacts
    instead.
  - Local hardware capacity reports a 10-lane ceiling, while MiniMax Token Plan
    continuous-agent limits may be lower. This spec defaults executor
    concurrency to 1 until provider tier evidence exists.

## Scope

### In Scope

- Add the `/opusminimax` skill and static bridge commands.
- Split shared provider-neutral settings from planner/executor profile examples.
- Extend setup for OpusMiniMax mode without reading `.env` or local secrets.
- Add sidecar schemas, lint validation, fixtures, and eval metadata.
- Add a static benchmark contract gate that does not run real SWE-bench.
- Update docs, generated capability map, release gate, and test harness.

### Out Of Scope

- Running authenticated Claude or MiniMax runtime smoke tests in this turn.
- Downloading or executing real SWE-bench, Terminal-Bench, or paid provider
  workloads.
- Claiming benchmark performance or production readiness.
- Reading `.env`, `.env.*`, `.claude/settings.local.json`, local private
  profile secrets, or customer artifacts.
- Implementing PAYG or production fleet orchestration.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock.
- Execution topology: parent implementation with local static verification.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` reported
  `recommended_ceiling=10`, `codex_max_threads=10`, `cores=16`, `ram_gb=32`,
  `hardware_class=workstation`, and `default_substrate=subagents`.
- Effective lanes: 1 implementation lane. The plan already had parallel
  research; this implementation touches coupled harness files where parent
  integration and verification are the critical path.
- Critical path: archive old SPEC -> write new SPEC -> settings/profile split
  -> skill -> scripts -> schemas/fixtures/lint -> eval/docs/test wiring ->
  generated capability map -> static verification.
- Agent wall-clock: optimistic 2 hours / likely 4 hours / pessimistic 7 hours.
- Agent-hours: approximately 8-14 across research already completed,
  implementation, debugging, and static verification.
- Human touch time: 1-3 hours later for Claude login, MiniMax key placement,
  runtime opt-in, and benchmark approvals.
- Calendar blockers: Opus availability under the user's Claude subscription,
  MiniMax Token Plan tier limits, and any paid/large benchmark runs.
- Confidence: medium. Static contracts are straightforward; runtime provider
  behavior must be verified later by opt-in commands.

## Implementation Plan

### Task 1: Provider Profile Foundation

- Make `.claude/settings.json` provider-neutral: governance hooks, deny rules,
  allowed public tools, and `acceptEdits` default only.
- Add planner and executor example profiles:
  - planner: no `ANTHROPIC_BASE_URL`, planner model `claude-opus-4-7`, effort
    `xhigh`, and no MiniMax alias collapse.
  - executor: `ANTHROPIC_BASE_URL=https://api.minimax.io/anthropic`, model
    `MiniMax-M2.7-highspeed`, and placeholder token fields only.
- Ignore local profile files and `.taste/opusminimax/` run artifacts.

### Task 2: Skill And Runtime Interface

- Add `/opusminimax` as a manual skill.
- Add `scripts/opusminimax.sh` to create run directories, packet templates, and
  optionally launch Claude planner runtime only when explicitly requested.
- Add `scripts/minimax-exec.sh` to validate executor packets and optionally run
  a MiniMax-backed Claude Code process only when explicitly requested.
- Add `scripts/opusminimax-doctor.sh` with a no-secret `--static` default and an
  explicit `--runtime` mode for future auth/model checks.

### Task 3: Artifact Contracts

- Add JSON schemas for `opusminimax-packet`, `opusminimax-run`, and
  `opusminimax-benchmark-result`.
- Extend artifact lint validation and fixtures for green/red cases.
- Treat model identity, provider separation, command evidence, quota ceilings,
  and benchmark per-task evidence as lintable contract surfaces.

### Task 4: Benchmark Repair Lab Contract

- Add a static `opusminimax-benchmark-smoke` gate.
- Add a harness eval task/golden for benchmark honesty.
- Document the task pipeline:
  intake -> gold quarantine -> localization -> repro test -> MiniMax candidate
  patches -> validation -> Claude adversarial selection -> final prediction.

### Task 5: Docs, Discovery, And Release Wiring

- Register `/opusminimax` in the capability map as a core execution route.
- Update README, CLAUDE.md, AGENTS.md, start-session, test-harness,
  release-check, and generated map docs.
- Keep all runtime provider checks opt-in; static release remains no-secret and
  no-network where existing gates permit.

## Verification

- `bash scripts/opusminimax-doctor.sh --static`
- `bash scripts/opusminimax-benchmark-smoke.sh --fixtures`
- `bash scripts/harness-capability-map.sh --check`
- `bash scripts/artifact-lint.sh --fixtures`
- `bash scripts/harness-eval.sh --json`
- `bash scripts/security-smoke.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

### Verified 2026-05-06

- `bash -n scripts/*.sh`: pass.
- JSON profile/schema validation with `python3 -m json.tool`: pass.
- `bash scripts/artifact-lint.sh --fixtures`: pass (`7 green`, `21 red`).
- `bash scripts/opusminimax-doctor.sh --static`: pass-with-warning. The warning
  is limited to existing candidate secret strings in test/smoke scripts; no
  local secret files were read.
- `bash scripts/opusminimax-benchmark-smoke.sh --fixtures`: pass.
- `bash scripts/security-smoke.sh`: pass.
- `bash scripts/harness-capability-map.sh --check --json`: pass
  (`skills=31`, `/opusminimax` group=`execution`, core route enabled).
- `bash scripts/harness-eval.sh --json`: pass (`19 tasks`, `16 gates`,
  `0 mismatches`).
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass
  (`128 passed`, `0 failed`; runtime workflow smoke intentionally skipped).
- `bash scripts/release-check.sh --static-only`: pass, including
  `git diff --check`.

Runtime Claude/MiniMax smoke tests were not run.

## Runtime Opt-In Verification Later

These commands are not part of static closeout:

- `bash scripts/opusminimax-doctor.sh --runtime`
- `bash scripts/opusminimax.sh --task "say hi only" --execute-planner`
- `bash scripts/minimax-exec.sh --packet PATH --run-dir PATH --execute`
- A tiny isolated benchmark fixture before any real SWE-bench or Terminal-Bench
  run.

## Rollback Plan

1. Restore the prior provider-specific `.claude/settings.json`.
2. Remove `/opusminimax` skill, scripts, schemas, fixtures, and eval task.
3. Remove `opusminimax` from capability-map route/script/eval wiring.
4. Restore docs and skill counts to the previous baseline.
5. Regenerate capability-map docs.
6. Re-run static release checks.
