# SPEC: Hybrid Claude Plus MiniMax Default

## Problem Statement

The harness now has a strong provider-split route, `/opusworkflow`, where
Claude/Opus is reserved for planning, adversarial review, and final judgment,
while MiniMax-M2.7-highspeed handles bounded bulk execution. However the audit
found several remaining defaults that still implied either plain `/workflow` or
legacy MiniMax-only setup.

The default operator experience should be unambiguous:

- install defaults to the hybrid `/opusworkflow` mode
- Claude Code guidance treats `/opusworkflow` as the daily route for build/plan
  requests
- provider identity stays in ignored local planner/executor profiles
- shared settings remain provider-neutral and trusted-local
- MiniMax execution remains bounded, concurrency-limited, and parent-verified

## Success Criteria

- [x] `setup.sh` defaults to `opusworkflow` even when `--mode` is omitted.
- [x] README install commands show the default hybrid path without requiring
  `--mode opusworkflow`, while preserving `--mode` as an advanced override.
- [x] `setup.sh --help` and final next steps name `/opusworkflow` as the
  default route.
- [x] `setup.ps1` no longer implies the old MiniMax-only/shared-settings path;
  it must configure ignored local split profiles or point users to the Bash
  hybrid installer.
- [x] `CLAUDE.md`, `AGENTS.md`, `scripts/start-session.sh`, and relevant docs
  describe `/opusworkflow` as the default daily route, with plain `/workflow`
  remaining the underlying lifecycle/manual fallback.
- [x] Static gates enforce the new default instead of only checking that
  `--mode opusworkflow` exists.
- [x] The harness capability map is regenerated and fresh.
- [x] No `.env`, key files, committed local profiles, or secret values are
  printed, committed, or used as evidence. Runtime credential profiles remain
  ignored local state.
- [x] Static release verification passes and the result is pushed.

## Audit Findings

- Current time anchor: `2026-05-06T16:45:12-03:00` from
  `scripts/time-anchor.sh`; this task is local harness work and does not depend
  on fast-moving external facts.
- `setup.sh` still had `MODE="minimax"`, so a no-`--mode` install did not mean
  the hybrid Claude+MiniMax route.
- README top commands used `--mode opusworkflow`, which worked but hid the
  desired default behind an option.
- `CLAUDE.md` already called `/opusworkflow` the daily default, but its
  "When you say plan/build" path still described plain `/workflow` first.
- `scripts/start-session.sh` said `/opusworkflow` was available, not that it was
  the default.
- `setup.ps1` was stale: it edited `.claude/settings.json` and user-scope MCP
  paths instead of the ignored planner/executor split. That conflicts with the
  current provider-neutral settings contract.
- Static gates checked for `--mode opusworkflow`, but not for `MODE="opusworkflow"`
  as the default.
- While validating help output, the old parser bug was exposed: a single
  `--help` or `-h` argument was treated like a positional MiniMax key. The new
  parser treats any leading-dash argument as an option, and the smoke gate
  verifies help exits before installer steps run.

## Source Ledger

- Repo evidence:
  - `setup.sh`
  - `setup.ps1`
  - `README.md`
  - `CLAUDE.md`
  - `AGENTS.md`
  - `scripts/start-session.sh`
  - `scripts/opusworkflow-smoke.sh`
  - `scripts/test-harness.sh`
  - `scripts/security-smoke.sh`
  - `.claude/skills/opusworkflow/SKILL.md`
  - `.claude/skills/workflow/SKILL.md`
- External sources: none needed for this local default-routing change.

## Plan

1. Change `setup.sh` fallback mode from legacy `minimax` to `opusworkflow`.
2. Simplify README and setup help commands so the no-option command is the
   hybrid default; keep `--mode` documented as an advanced override.
3. Update Claude-facing guidance so build/plan defaults to `/opusworkflow`,
   with `/workflow` as the lifecycle underneath or explicit local fallback.
4. Fix `setup.ps1` so it does not mutate shared settings with MiniMax secrets
   and points to/configures split local profiles.
5. Harden static tests to check default mode and split PowerShell behavior.
6. Regenerate capability map, run static verification, commit, and push.

## Agent-Native Estimate

- Estimate type: agent-native.
- Critical path: audit surfaces -> settings/docs/script edits -> smoke tests ->
  capability map -> release gate -> commit/push.
- Agent wall-clock: 45-75 minutes.
- Agent-hours: 1-2.
- Human touch time later: none for static install behavior; runtime Claude auth
  still requires `claude auth login` when not already authenticated.
- Calendar blockers: none.
- Confidence: medium-high. The main path is Bash and well-tested; PowerShell is
  static-reviewed here because the current Linux environment does not provide a
  Windows PowerShell runtime.

## Introspection: Pre-Implementation

- Likely mistake: making `/opusworkflow` sound like it proves Opus runtime
  identity. Guard: keep runtime proof explicit and opt-in.
- Likely mistake: collapsing planner and executor provider identities into one
  settings file. Guard: keep shared settings provider-neutral and use ignored
  planner/executor local profiles only.
- Likely mistake: overselling MiniMax concurrency. Guard: keep default executor
  concurrency at 1 until provider evidence proves a higher safe ceiling.
- Likely mistake: breaking existing users who still need legacy MiniMax-only.
  Guard: keep `--mode minimax` as an explicit override.
- Likely mistake: claiming PowerShell runtime proof without exercising Windows.
  Guard: only claim static lint/readiness for `setup.ps1` in this turn.

## Verified 2026-05-06

- `env -u MINIMAX_TOKEN_KEY -u TOKEN_KEY bash setup.sh --help`: pass; shows
  `(default: opusworkflow)` and does not execute installer steps.
- `env -u MINIMAX_TOKEN_KEY -u TOKEN_KEY bash setup.sh -h`: pass; same help
  behavior.
- `bash -n setup.sh scripts/start-session.sh scripts/opusworkflow-smoke.sh scripts/test-harness.sh scripts/security-smoke.sh scripts/release-check.sh`: pass.
- `python3 -m json.tool evals/harness/golden/m9-opusworkflow-cost-budget.json`: pass.
- `bash scripts/opusworkflow-smoke.sh`: pass.
- Stale default-facing phrase check for `Then try: /workflow` in setup/docs:
  pass; legacy MiniMax-only override is labeled explicitly.
- `bash scripts/security-smoke.sh`: pass.
- `bash scripts/harness-capability-map.sh --write`: regenerated generated map
  JSON after route/default script changes.
- `bash scripts/harness-capability-map.sh --check`: pass.
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`,
  `0 mismatches`).
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`138 passed`,
  `0 failed`).
- `git diff --check`: pass.
- `bash scripts/release-check.sh --static-only`: pass (`138 passed`,
  `0 failed`; static-only release gate passed).

## Introspection: Pre-Closeout

- Likely mistake: claiming runtime provider proof from static checks.
  Mitigation: this change only claims default wiring and static install
  behavior. Claude and MiniMax runtime identity checks remain explicit opt-in.
- Likely mistake: making the default install less clear by hiding the mode.
  Mitigation: README says both commands default to `/opusworkflow`, setup help
  labels `(default: opusworkflow)`, and tests verify `MODE="opusworkflow"`.
- Likely mistake: breaking explicit legacy users. Mitigation: `--mode minimax`
  and `--mode opusminimax` remain supported overrides.
- Likely mistake: leaving PowerShell as an unsafe stale path. Mitigation:
  `setup.ps1` now defaults to `opusworkflow`, writes MiniMax credentials only to
  ignored executor local settings, keeps planner settings provider-clean, and
  does not mutate user-scope MCP automatically in split mode.
- Remaining verification risk: PowerShell syntax/runtime was static-reviewed
  only because this Linux environment has no `pwsh`/Windows runtime.
