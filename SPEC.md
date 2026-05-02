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

## Codebase Anchors

- `.github/workflows/harness-static.yml` runs
  `bash scripts/release-check.sh --static-only` on push and pull requests.
- `scripts/release-check.sh --static-only` is the no-secret static release gate.
- `scripts/test-harness.sh` contains the hard availability probes for `claude`
  and `forgegod`.
- `AGENTS.md` says push readiness should use
  `bash scripts/release-check.sh --static-only` and should not claim runtime CI
  proof unless the manual authenticated lane ran.

## Success Criteria

- [x] Static CI treats missing `claude` as a warning, not a release-blocking
      failure.
- [x] Static CI treats missing `forgegod` as a warning, not a release-blocking
      failure.
- [x] Local/full harness behavior remains strict unless the caller explicitly
      enables static-CI mode or GitHub Actions sets `CI=true`.
- [x] `release-check --static-only` passes the static-CI mode flag into the full
      harness so local static release checks match the GitHub lane.
- [ ] Push the fix and confirm the `Harness Static / harness-static` check
      passes on GitHub.

## Scope

### In Scope

- Minimal shell gating in `scripts/test-harness.sh`.
- Minimal release-check environment wiring in `scripts/release-check.sh`.
- Verification of local and pushed static release gates.

### Out of Scope

- Installing Claude Code or ForgeGod on GitHub-hosted runners.
- Weakening runtime/manual integration checks.
- Changing visualization skill behavior.
- Broad CI workflow refactors.

## Surgical Diff Discipline

- Smallest sufficient implementation: add one static-CI mode flag and use it in
  the two optional-tool probes.
- No speculative abstractions: do not introduce a new CI matrix, installer, or
  provider bootstrap.
- No drive-by refactors: keep unrelated harness checks untouched.
- Changed-line trace: every edit maps to the CI log showing missing `claude` and
  `forgegod` as the two static failures.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local
- Capacity evidence: no parallel-capacity run needed; this is a narrow serial CI
  hotfix with one file pair and one push verification path
- Effective lanes: 1 of ceiling 10
- Critical path: inspect CI logs -> patch optional-tool probes -> run static
  simulations -> commit/push -> watch GitHub static check
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

Verified locally on 2026-05-02:

- `bash -n scripts/test-harness.sh scripts/release-check.sh`: pass
- `git diff --check`: pass
- `HARNESS_STATIC_CI=1 PATH="/usr/bin:/bin" bash scripts/test-harness.sh`:
  pass, 101 passed, 0 failed, expected static-CI warnings for missing local
  `claude` and `forgegod`
- `bash scripts/test-harness.sh`: pass, 103 passed, 0 failed
- `bash scripts/release-check.sh --static-only`: pass, includes
  `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh` and `git diff --check`

## Rollback Plan

- Remove the `STATIC_CI_MODE` handling from `scripts/test-harness.sh`.
- Restore `scripts/release-check.sh` to call `bash scripts/test-harness.sh`
  directly.
- Run `bash scripts/release-check.sh --static-only`.
