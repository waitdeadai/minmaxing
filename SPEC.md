# SPEC: One-Command OpusWorkflow Install UX

## Problem Statement

The current installer can already configure MiniMax in one command with
`--minimax-key`, but the README primarily shows the safer key-file path for
`/opusworkflow`. That makes the setup feel inconsistent with the legacy
MiniMax solo command, where the token is visibly passed as the single argument.

The desired UX is: an operator can run one command that clones/configures the
harness, writes the local ignored MiniMax executor profile, prepares the Opus
planner profile, and then enters Claude Code. Claude subscription auth still
belongs to `claude auth login` because it is an interactive account login, but
the installer should make MiniMax Token Plan setup one-command and obvious.

## Success Criteria

- [x] Keep the existing safe key-file path.
- [x] Document the single-command inline MiniMax token path for
  `/opusworkflow`.
- [x] Add a secure terminal prompt fallback when no MiniMax token is supplied
  and an interactive TTY is available.
- [x] Do not print or commit MiniMax tokens.
- [x] Preserve split-execution safety: shared `.claude/settings.json` remains
  provider-neutral, MiniMax credentials go only to ignored local executor
  settings, and planner settings do not inherit MiniMax base URL.
- [x] Update README and setup help so the difference between MiniMax token setup
  and Claude subscription login is clear.
- [x] Static verification passes.

## Local Research Brief

- Existing `setup.sh` already supports:
  - legacy positional MiniMax token
  - `--minimax-key KEY`
  - `--minimax-key-file PATH`
  - `--mode opusworkflow`
  - split planner/executor local profiles
- README currently highlights the token-file path for `/opusworkflow`, not the
  inline one-command path.
- No external docs are needed for this change; the behavior is local installer
  UX and docs.

## Plan

1. Add a no-secret prompt fallback to `setup.sh`.
2. Update setup usage examples.
3. Update README top install section and OpusWorkflow verification guidance.
4. Run focused static checks and release gate.

## Agent-Native Estimate

- Estimate type: agent-native.
- Critical path: setup edit -> README edit -> syntax/static checks -> release
  gate -> commit/push.
- Agent wall-clock: likely 20-35 minutes.
- Agent-hours: under 1.
- Human touch time later: none, except normal Claude browser auth if not logged
  in.
- Confidence: high; small docs/installer UX change with existing test surfaces.

## Verified 2026-05-06

- `bash scripts/opusworkflow-smoke.sh`: pass.
- `bash -n setup.sh scripts/opusworkflow-smoke.sh scripts/test-harness.sh`: pass.
- `git diff --check`: pass.
- `bash scripts/harness-capability-map.sh --write`: refreshed generated JSON
  after script line/hash changes.
- `bash scripts/harness-capability-map.sh --check --json`: pass.
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`,
  `0 mismatches`).
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`137 passed`,
  `0 failed`).
- `bash scripts/release-check.sh --static-only`: pass (`137 passed`,
  `0 failed`; static-only release gate passed).

## Introspection: Pre-Closeout

- Likely mistake: documenting a one-command install that still hides the token
  step. Mitigation: README and setup help now show `--minimax-key` directly and
  also document `--prompt-minimax-key` and `--minimax-key-file`.
- Likely mistake: encouraging secrets in shell history as the only path.
  Mitigation: inline key is available for true one-command setup, while the
  prompt and key-file paths remain documented for safer local use.
- Likely mistake: conflating MiniMax Token Plan setup with Claude subscription
  auth. Mitigation: README explicitly says `claude auth login` is separate
  account auth and the installer does not fake or store a Claude session.
- Remaining verification risk: runtime Claude and MiniMax authenticated checks
  remain opt-in; this change is a no-secret installer/docs update and was
  verified with static gates only.
