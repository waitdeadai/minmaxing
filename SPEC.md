# SPEC: Direct MiniMax Token One-Command Setup

## Problem Statement

The installer supports `--minimax-key`, `--prompt-minimax-key`, and
`--minimax-key-file`, but the operator wants one clear copy-paste form: put the
MiniMax Token Plan key in one command, install the harness into the current
folder, and open Claude. The README should not present multiple competing
recommended setup commands.

## Success Criteria

- [x] `setup.sh` accepts `MINIMAX_TOKEN_KEY=...` as a first-class MiniMax token
  input.
- [x] `setup.sh` accepts `TOKEN_KEY=...` as a short operator alias when
  `MINIMAX_TOKEN_KEY` is not set.
- [x] CLI `--minimax-key` and `--minimax-key-file` continue to work.
- [x] README shows one canonical setup command:
  `MINIMAX_TOKEN_KEY='YOUR_TOKEN_PLAN_KEY' bash -lc 'curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --mode opusworkflow && claude'`.
- [x] README removes duplicate "recommended" install variants and legacy
  MiniMax key install examples.
- [x] README keeps a concise warning that inline/env token commands can land in
  shell history and points advanced operators to `bash setup.sh --help` instead
  of listing alternate recommended commands.
- [x] `setup.sh` no-key closeout prints the same single canonical command.
- [x] Static smoke gates validate the env-var route.
- [x] No real token, `.env`, or ignored local settings file is read, printed, or
  committed.

## Local Research Brief

- `setup.sh` currently initializes `API_KEY=""` and fills it from the legacy
  positional arg, `--minimax-key`, or `--minimax-key-file`.
- README already shows the direct `--minimax-key` path but not an env-var token
  assignment, which is the more natural copy-paste shape for "one command".
- `scripts/opusworkflow-smoke.sh` and `scripts/test-harness.sh` already assert
  setup affordances and should include the new env-var route.

## Plan

1. Initialize `API_KEY` from `MINIMAX_TOKEN_KEY` or `TOKEN_KEY`.
2. Update setup usage/help and no-key closeout examples.
3. Collapse README one-command setup, Windows notes, fresh-folder, and
   existing-folder instructions onto the single canonical command.
4. Update setup help/no-key output so the normal operator path remains singular.
5. Extend static gates for the canonical route.
6. Run static verification and push.

## Agent-Native Estimate

- Estimate type: agent-native.
- Critical path: setup env alias -> README examples -> smoke/test patterns ->
  static gates -> commit/push.
- Agent wall-clock: likely 15-30 minutes.
- Agent-hours: under 1.
- Human touch time later: none.
- Confidence: high; narrow installer/docs/test update.

## Introspection: Pre-Implementation

- Likely mistake: making the inline env route look safer than it is. Guard:
  README must explicitly mention shell history risk and point advanced operators
  to `bash setup.sh --help` without making alternate commands look recommended.
- Likely mistake: breaking existing `--minimax-key` users. Guard: leave the
  current arg parser intact and only use env vars as defaults.
- Likely mistake: accidentally committing a real token. Guard: use placeholder
  strings only and do not inspect secret files.

## Verified 2026-05-06

- `bash scripts/harness-capability-map.sh --write`: refreshed generated map
  docs/JSON after README/script changes.
- `bash -n setup.sh scripts/opusworkflow-smoke.sh scripts/test-harness.sh scripts/release-check.sh`: pass.
- `bash scripts/opusworkflow-smoke.sh`: pass.
- `git diff --check`: pass.
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`137 passed`,
  `0 failed`).
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`,
  `0 mismatches`).
- `bash scripts/release-check.sh --static-only`: pass (`137 passed`,
  `0 failed`; static-only release gate passed).
- One-command clarity update: README now contains only one MiniMax install
  command, setup no-key output prints the same command, and the static gates
  expect that canonical command.

## Introspection: Pre-Closeout

- Likely mistake: encouraging unsafe key exposure. Mitigation: README shows the
  direct env route but explicitly warns it can land in shell history; hidden
  prompt and key-file routes remain available only as advanced setup help.
- Likely mistake: hidden regression for existing setup paths. Mitigation:
  `--minimax-key`, `--minimax-key-file`, and `--prompt-minimax-key` remain in
  setup help and smoke assertions.
- Likely mistake: over-testing by using a real key. Mitigation: verification
  stayed static/no-secret and used placeholder strings only.
