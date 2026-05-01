# SPEC: Documentation Distribution And Open-Core Boundary

## Problem Statement

The harness now has runtime governance hooks, static evals, release checks,
parallel aggregation, and memory learning gates. Finish the roadmap with a
public documentation and distribution pass so a new user can run the static
core safely, a trusted operator can enable runtime checks intentionally, and
the open-core/private boundary remains explicit.

This implements M9 from `BEST_HARNESS_DEEPRESEARCH_PLAN_2026.md`.

## Codebase Anchors

- `README.md` will get a dedicated Runtime Governance section.
- `docs/runtime-governance-quickstart.md` will document solo-fast, team-safe,
  ci-static, and ci-runtime flows.
- `examples/dummy-harness-run/` will provide a public dummy-only example.
- `COMMERCIAL.md` will refresh distribution/open-core claims.
- `scripts/test-harness.sh` will include a docs/distribution smoke gate.

## Success Criteria

- [x] README has a dedicated Runtime Governance section.
- [x] Add docs-style quickstart for solo-fast vs team-safe vs CI profiles.
- [x] Add public dummy examples only, with no customer data, credentials,
      REVCLI private code, or commercial playbooks.
- [x] Refresh `COMMERCIAL.md` with distribution, plugin/installer, and public
      claims boundaries.
- [x] Document Claude Code first usage and optional Codex plugin guidance.
- [x] Docs say static smoke runs without secrets.
- [x] Docs say runtime smoke requires local credentials and must not run on
      public PRs by default.
- [x] Docs avoid claiming the harness is autonomous without verification.
- [x] `scripts/test-harness.sh` validates the M9 docs/distribution surface.

## Scope

### In Scope

- Public docs and dummy examples.
- Open-core/private boundary clarification.
- Static harness smoke assertions for docs.

### Out of Scope

- Publishing packages.
- Creating marketplace plugins.
- Running authenticated runtime checks.
- Moving private runtime/customer artifacts into this repo.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local
- Capacity evidence: `scripts/parallel-capacity.sh --json` reported
  workstation, 16 cores, 32GB RAM, Codex `max_threads` 10, recommended ceiling
  10, default substrate `subagents`
- Effective lanes: 1 of ceiling 10 because this is one coherent docs and smoke
  contract
- Critical path: write M9 spec -> add docs quickstart -> add dummy example ->
  refresh README/COMMERCIAL -> wire smoke -> verify
- Agent wall-clock: optimistic 60 minutes / likely 2 hours / pessimistic 4
  hours
- Agent-hours: 1.5-4 active agent-hours
- Human touch time: 15-30 minutes for public-positioning review
- Calendar blockers: none for local static docs gates
- Confidence: high because this is deterministic docs/test work
- Human-equivalent baseline: half engineer-day to 1 engineer-day, secondary
  comparison only

## Implementation Plan

- [x] Add runtime governance quickstart doc.
- [x] Add dummy-only public example.
- [x] Add README runtime governance entry.
- [x] Refresh `COMMERCIAL.md`.
- [x] Add docs/distribution smoke assertions.
- [x] Run final release and full harness verification.

## Verification

- `bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

Verified on 2026-05-01:

- `bash -n scripts/test-harness.sh`: pass
- `bash scripts/test-harness.sh`: pass, 90 passed, 0 failed; credentialed
  Claude workflow smoke skipped because `RUN_CLAUDE_INTEGRATION=1` was not set
- `bash scripts/release-check.sh --static-only`: pass; includes full harness
  and `git diff --check`
- `git diff --check`: pass

## Rollback Plan

1. Remove new docs/example files.
2. Revert README, COMMERCIAL, and test-harness changes.
3. Restore the prior active spec from `.taste/specs/` if abandoned before
   verified closeout.
