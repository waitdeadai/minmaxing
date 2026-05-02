# SPEC: CI Static Optional Tool Handling

## Problem Statement

The pushed `Harness Static / harness-static` GitHub Actions lane is failing even
though the visualization changes pass locally and in CI. The CI runner does not
install local developer tools such as `claude` and `forgegod`, while
`scripts/test-harness.sh` currently treats both availability probes as hard
failures.

Static CI should prove the public harness contract without requiring secrets or
local-only binaries. Runtime/provider proof remains the job of the manual
authenticated runtime lane.

The Actions list also exposes a separate zero-job
`.github/workflows/harness-runtime.yml` failure on push. Local `actionlint`
identified that as a YAML parse issue caused by an inline `run:` command with a
colon-space in the scalar. That should be fixed in the same CI hotfix so the
branch does not keep showing a red workflow-file failure after static passes.

After that fix, the latest static run succeeded but still emitted a GitHub
Actions warning that `actions/checkout@v4` runs on deprecated Node.js 20. This
follow-up removes that remaining warning by pinning both workflows to
`actions/checkout@v6.0.2`, whose upstream release notes document Node.js 24
support.

## Codebase Anchors

- `.github/workflows/harness-static.yml` runs
  `bash scripts/release-check.sh --static-only` on push and pull requests.
- `scripts/release-check.sh --static-only` is the no-secret static release gate.
- `scripts/test-harness.sh` contains the hard availability probes for `claude`
  and `forgegod`.
- `.github/workflows/harness-runtime.yml` contains the manual authenticated
  runtime lane and must parse cleanly even when it does not run on push.
- `actions/checkout` upstream latest release is `v6.0.2` as of 2026-05-02, and
  `v6.0.0` release notes include Node.js 24 support details.
- `AGENTS.md` says push readiness should use
  `bash scripts/release-check.sh --static-only` and should not claim runtime CI
  proof unless the manual authenticated lane ran.

## Success Criteria

- [x] Static CI treats missing `claude` as an intentional skip, not a warning or
      release-blocking failure.
- [x] Static CI treats missing `forgegod` as an intentional skip, not a warning
      or release-blocking failure.
- [x] Local/full harness behavior remains strict unless the caller explicitly
      enables static-CI mode or GitHub Actions sets `CI=true`.
- [x] `release-check --static-only` passes the static-CI mode flag into the full
      harness so local static release checks match the GitHub lane.
- [x] Runtime workflow YAML parses cleanly and no longer creates a zero-job
      workflow-file failure on push.
- [x] The CI governance smoke rejects inline workflow `run:` commands with
      colon-space content unless they use block syntax.
- [x] Push the fix and confirm the `Harness Static / harness-static` check
      passes on GitHub.
- [x] Replace Node.js 20-based `actions/checkout@v4` usage with
      `actions/checkout@v6.0.2`.
- [x] Add harness assertions so CI governance requires the Node.js 24-capable
      checkout version in both workflows.
- [x] Convert intentional static/runtime non-runs from `[WARN]` to `[SKIP]` so
      release logs do not carry misleading harness warnings.
- [x] Push the warning cleanup and confirm the latest `Harness Static` run has
      no annotations.

## Scope

### In Scope

- Minimal shell gating in `scripts/test-harness.sh`.
- Minimal release-check environment wiring in `scripts/release-check.sh`.
- Minimal runtime workflow YAML fix for the already-observed parse failure.
- Minimal checkout action upgrade in both workflows.
- Minimal harness log wording change from warnings to skips for intentionally
  absent runtime probes.
- Verification of local and pushed static release gates.

### Out of Scope

- Installing Claude Code or ForgeGod on GitHub-hosted runners.
- Weakening runtime/manual integration checks.
- Changing visualization skill behavior.
- Broad CI workflow refactors beyond the parse fix and warning cleanup needed to
  keep the pushed commit green and annotation-free.

## Surgical Diff Discipline

- Smallest sufficient implementation: add one static-CI mode flag, use it in
  the two optional-tool probes, convert the failing runtime workflow command to
  block syntax, update checkout to the Node.js 24-capable release, and label
  intentional runtime non-runs as skips.
- No speculative abstractions: do not introduce a new CI matrix, installer, or
  provider bootstrap.
- No drive-by refactors: keep unrelated harness checks untouched.
- Changed-line trace: every edit maps to the CI log showing missing `claude` and
  `forgegod` as the two static failures, or the Actions zero-job runtime
  workflow parse failure.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local
- Capacity evidence: no parallel-capacity run needed; this is a narrow serial CI
  hotfix with one file pair and one push verification path
- Effective lanes: 1 of ceiling 10
- Critical path: inspect CI logs -> patch optional-tool probes -> patch runtime
  workflow parse issue -> run static simulations -> commit/push -> watch GitHub
  static check
- Agent wall-clock: optimistic 20 minutes / likely 45 minutes / pessimistic 90
  minutes
- Agent-hours: 1-2 active agent-hours
- Human touch time: none expected
- Calendar blockers: GitHub Actions queue and network availability
- Confidence: high because the CI log names exactly two failing harness checks
  and both are local-tool availability probes
- Human-equivalent baseline: under half an engineer-day, secondary comparison
  only

## Verification

- `HARNESS_STATIC_CI=1 PATH="/usr/bin:/bin" bash scripts/test-harness.sh`
- `bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`
- GitHub Actions `Harness Static / harness-static` after push
- GitHub Actions runtime workflow file should no longer produce a zero-job push
  failure after the workflow YAML parse fix
- GitHub Actions latest static check should have zero annotations after the
  checkout upgrade

Verified locally on 2026-05-02:

- `bash -n scripts/test-harness.sh scripts/release-check.sh`: pass
- `git diff --check`: pass
- `HARNESS_STATIC_CI=1 PATH="/usr/bin:/bin" bash scripts/test-harness.sh`:
  pass, 101 passed, 0 failed, expected static-CI warnings for missing local
  `claude` and `forgegod`
- `bash scripts/test-harness.sh`: pass, 103 passed, 0 failed
- `bash scripts/release-check.sh --static-only`: pass, includes
  `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh` and `git diff --check`
- `actionlint .github/workflows/harness-runtime.yml .github/workflows/harness-static.yml`:
  initially found the runtime inline `run:` YAML parse issue; pass after block
  syntax fix
- GitHub Actions `Harness Static` for `60aa107`: pass, one remaining Node.js 20
  deprecation annotation from `actions/checkout@v4`
- `gh api repos/actions/checkout/releases/latest`: latest release `v6.0.2`,
  published 2026-01-09
- `gh api repos/actions/checkout/releases/tags/v6.0.0`: release notes include
  Node.js 24 support details
- `HARNESS_STATIC_CI=1 PATH="/usr/bin:/bin" bash scripts/test-harness.sh >
  /tmp/minmaxing-static-sim.log && ! grep -F "[WARN]"
  /tmp/minmaxing-static-sim.log`: pass, static simulation reports skips instead
  of warnings
- `bash scripts/test-harness.sh > /tmp/minmaxing-full-harness.log && ! grep -F
  "[WARN]" /tmp/minmaxing-full-harness.log`: pass, 103 passed, 0 failed
- `bash scripts/release-check.sh --static-only >
  /tmp/minmaxing-release-static.log && ! grep -F "[WARN]"
  /tmp/minmaxing-release-static.log`: pass, static-only release gate passed
- GitHub Actions `Harness Static` for `f93e423`: pass, annotations API returned
  `[]`, job log grep found no `[WARN]` lines

## Rollback Plan

- Remove the `STATIC_CI_MODE` handling from `scripts/test-harness.sh`.
- Restore `scripts/release-check.sh` to call `bash scripts/test-harness.sh`
  directly.
- Run `bash scripts/release-check.sh --static-only`.
