# SPEC: `/opusworkflow` Cost-Optimized Opus + MiniMax Workflow

## Problem Statement

`/opusminimax` now provides the provider split, but the user's main daily mode
needs a sharper operating contract: squeeze a $20 Claude subscription plus a
$40 MiniMax Token Plan Plus-Highspeed subscription without pretending either
plan is unlimited.

The effective mode is not "Opus does everything" and not "MiniMax swarm at the
hardware ceiling." It is `/opusworkflow`: a workflow-first command where
Claude/Opus is used only for bounded judgment checkpoints, and
MiniMax-M2.7-highspeed does the bulk coding and repair work through the existing
`/opusminimax` packet system.

## Success Criteria

- [x] Add `.claude/skills/opusworkflow/SKILL.md` as a concise, manual
  end-to-end skill that wraps `/opusminimax --mode workflow`.
- [x] Add `scripts/opusworkflow.sh` as the script entrypoint for preparing or
  explicitly launching workflow-mode OpusMiniMax runs.
- [x] Extend `setup.sh --mode opusworkflow` as a one-command install alias for
  the same planner/executor profile split.
- [x] Add a static `scripts/opusworkflow-smoke.sh` gate and register it in the
  harness eval pack.
- [x] Update README, CLAUDE.md, AGENTS.md, session startup, release gate, test
  harness, and generated capability map so `/opusworkflow` is discoverable as
  the recommended daily mode.
- [x] Preserve the provider-split contract: shared settings stay neutral,
  planner profiles do not inherit MiniMax base URL, executor model remains
  `MiniMax-M2.7-highspeed`, and executor concurrency defaults to 1 unless
  runtime provider evidence proves otherwise.
- [x] Static gates pass without reading `.env`, local profile secrets, or
  MiniMax key files, and without running authenticated provider smoke tests.

## Research Brief

### Collaborative Research Plan

- Local repo branch:
  - inspect `/opusminimax`, `/workflow`, setup, capability map, release gates,
    evals, and test harness surfaces.
  - implement `/opusworkflow` with the smallest sufficient additions and reuse
    existing packet/artifact schemas.
- Current provider branch:
  - keep the recent source-ledger conclusions current in the spec: Claude
    subscription usage is shared, `ANTHROPIC_API_KEY` overrides subscription
    billing, Opus 4.7 access on Pro may require extra usage, MiniMax
    Plus-Highspeed is request-capped and traffic-shaped.
- Adversarial branch:
  - block false cost claims, false Opus claims, linear parallelism claims, and
    "one command means secrets/auth are magically solved" wording.

### Source Ledger

- Local truth:
  - `AGENTS.md`: `/opusminimax`, `/workflow`, `/parallel`, `/introspect`,
    active spec lifecycle, release gate, and security rules.
  - `CLAUDE.md`: slash route list, default behavior, OpusMiniMax profiles, and
    release gate.
  - `.claude/skills/opusminimax/SKILL.md`: provider split and packet contract.
  - `.claude/skills/workflow/SKILL.md`: workflow artifact, metacognitive route,
    SPEC-first lifecycle, and verification requirements.
  - `setup.sh`: one-command install and provider-profile setup flow.
  - `scripts/harness-capability-map.sh`: canonical route/script/eval map.
  - `scripts/test-harness.sh` and `scripts/release-check.sh`: static public
    verification surfaces.
- External sources checked in the prior provider research turn:
  - `https://support.claude.com/en/articles/11145838-use-claude-code-with-your-pro-or-max-plan`
  - `https://code.claude.com/docs/en/model-config`
  - `https://support.claude.com/en/articles/8606394-how-large-is-the-context-window-on-paid-claude-plans`
  - `https://claude.com/blog/best-practices-for-using-claude-opus-4-7-with-claude-code`
  - `https://platform.minimax.io/docs/token-plan/intro`
  - `https://platform.minimax.io/docs/guides/pricing-tokenplan`
  - `https://platform.minimax.io/docs/token-plan/faq`
  - `https://platform.minimax.io/docs/token-plan/other-tools`
- Conflicts and caveats:
  - Claude Pro subscription does not guarantee free/unlimited Opus 4.7 use in
    Claude Code. Runtime model identity and billing path must be proven before
    saying "Opus planned this."
  - MiniMax Plus-Highspeed has a large request quota, but provider traffic rules
    still make 1 continuous executor lane the honest default.
  - Local hardware capacity reports 10 as a ceiling. Provider quota and
    supervisor verification capacity lower the effective executor budget.

## Scope

### In Scope

- New `/opusworkflow` skill, wrapper script, smoke gate, eval metadata, setup
  alias, docs, generated map, and static tests.
- Cost policy for the default $20 Claude + $40 MiniMax configuration.
- No-secret, no-provider-runtime static verification.

### Out Of Scope

- Authenticated Claude or MiniMax runtime calls.
- Pay-as-you-go fallback implementation.
- Real benchmark execution or benchmark score claims.
- Reading `.env`, `.env.*`, `.claude/*.local.json`, key files, or customer
  private artifacts.

## Agent-Native Estimate

- Estimate type: agent-native.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` returned
  `recommended_ceiling=10`, `codex_max_threads=10`, `cores=16`, `ram_gb=32`,
  `hardware_class=workstation`, and `agent_teams_available=false`.
- Effective lanes: 1 local implementation lane. The changes are coupled across
  route registration, setup, docs, tests, and generated maps; parallelizing the
  edits would increase integration risk.
- Critical path: spec -> skill/script -> setup alias -> smoke/eval/release/test
  wiring -> docs -> generated capability map -> static release gate.
- Agent wall-clock: optimistic 45 minutes / likely 90 minutes / pessimistic 3
  hours.
- Agent-hours: 1-3.
- Human touch time later: 10-30 minutes for Claude login, MiniMax key placement,
  and optional runtime provider doctor.
- Calendar blockers: account-specific Opus access and MiniMax peak traffic.
- Confidence: medium-high for static harness behavior, medium for provider
  runtime effectiveness until runtime checks prove the actual account state.

## Implementation Plan

### Task 1: Route Contract

- Add `/opusworkflow` skill with:
  - mode banner
  - cost-optimized budget policy
  - Opus judgment checkpoints
  - MiniMax executor duties
  - default executor concurrency 1
  - refusal to claim Opus if model identity is unproven
  - final verification requirements

### Task 2: Script Interface

- Add `scripts/opusworkflow.sh` as a workflow-mode wrapper over
  `scripts/opusminimax.sh`.
- Keep runtime execution opt-in through `--execute-planner`.
- Pass through planner/executor model overrides and run IDs.

### Task 3: Setup Alias

- Extend `setup.sh --mode opusworkflow` to prepare the same local planner and
  executor profiles as `/opusminimax`.
- Make final setup guidance point to `/opusworkflow` when that mode is selected.

### Task 4: Static Gate And Eval

- Add `scripts/opusworkflow-smoke.sh`.
- Add `evals/harness/tasks/m9-opusworkflow-cost-budget.yaml` and matching
  golden JSON.
- Register the new gate in `scripts/harness-eval.sh`,
  `scripts/harness-capability-map.sh`, `scripts/release-check.sh`, and
  `scripts/test-harness.sh`.

### Task 5: Docs And Discovery

- Update README, CLAUDE.md, AGENTS.md, and `scripts/start-session.sh`.
- Regenerate `docs/harness-capability-map.md` and
  `docs/harness-capability-map.json`.

## Verification Plan

- `bash -n scripts/*.sh`
- `bash scripts/opusworkflow-smoke.sh`
- `bash scripts/opusminimax-doctor.sh --static`
- `bash scripts/opusminimax-benchmark-smoke.sh --fixtures`
- `bash scripts/harness-capability-map.sh --check --json`
- `bash scripts/artifact-lint.sh --fixtures`
- `bash scripts/harness-eval.sh --json`
- `bash scripts/security-smoke.sh`
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

## Verified 2026-05-06

- `bash -n scripts/*.sh`: pass.
- `bash scripts/opusworkflow-smoke.sh`: pass.
- `bash scripts/opusminimax-doctor.sh --static`: pass-with-warning. The warning
  is limited to obvious candidate secret strings in existing test/smoke scripts;
  no `.env` or local profile secrets were read.
- `bash scripts/opusminimax-benchmark-smoke.sh --fixtures`: pass.
- `bash scripts/harness-capability-map.sh --check --json`: pass
  (`skills=32`, `eval_tasks=20`, `/opusworkflow` core route present).
- `bash scripts/artifact-lint.sh --fixtures`: pass (`7 green`, `21 red`).
- `bash scripts/harness-eval.sh --json`: pass (`20 tasks`, `17 gates`,
  `0 mismatches`).
- `bash scripts/security-smoke.sh`: pass.
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`131 passed`,
  `0 failed`; runtime workflow smoke intentionally skipped).
- `bash scripts/release-check.sh --static-only`: pass, including
  `git diff --check`.
- `bash scripts/opusminimax-doctor.sh --runtime`: pass-with-warning after
  operator Claude login. Runtime doctor confirmed Claude Code `2.1.118`, Claude
  Pro subscription auth, provider-neutral shared settings, Opus planner request,
  and MiniMax executor profile separation. It made no model calls and read no
  `.env` or local profile secrets.
- `claude --model claude-opus-4-7 --settings .claude/settings.opusminimax-planner.local.json -p 'Reply exactly: OPUSWORKFLOW_AUTH_OK'`:
  operator-reported pass. The sentinel response printed
  `OPUSWORKFLOW_AUTH_OK`, proving the Claude/Opus planner path for this local
  account state.

MiniMax live executor packet runtime remains untested.

## Introspection Pre-Plan

- Likely mistake: overbuilding a second implementation stack instead of an alias
  over `/opusminimax`. Mitigation: make `/opusworkflow` a thin workflow-mode
  route and reuse existing schemas.
- Likely mistake: claiming the $20 Claude plan gives guaranteed Opus 4.7.
  Mitigation: docs and skill must say Opus is only claimed when identity is
  proven.
- Likely mistake: using local 10-lane capacity as MiniMax executor capacity.
  Mitigation: skill and smoke gate require default provider ceiling 1.
- Missing verification: MiniMax live executor behavior remains untested by
  design. Static closeout must keep that proof pending until a tiny executor
  packet is run with explicit operator approval.

## Introspection Post-Implementation

- Checked for overbuild: `/opusworkflow` is a wrapper and skill over the
  existing `/opusminimax` artifacts, not a second provider bridge.
- Checked for false cost claims: docs and skill say Opus must be proven and
  Plus-Highspeed executor concurrency defaults to 1.
- Checked for provider leakage: static doctor still confirms shared settings are
  provider-neutral, planner has no MiniMax base URL, and executor requests
  `MiniMax-M2.7-highspeed`.
- Checked for verification gap: Claude auth and Opus planner identity are now
  proven by runtime doctor plus operator-reported sentinel output; MiniMax live
  executor runtime remains pending and opt-in.
- Changed-line trace: every meaningful edit maps to this spec's route contract,
  script interface, setup alias, static gate/eval, docs/discovery, or verification
  cleanup.

## Rollback Plan

1. Remove `/opusworkflow` skill, script, smoke gate, eval task/golden, and setup
   alias.
2. Remove route/script/eval registrations from capability map generator,
   harness eval, release-check, test-harness, and docs.
3. Regenerate capability map.
4. Restore README/CLAUDE/AGENTS/start-session wording to `/opusminimax` only.
5. Re-run static release checks.
