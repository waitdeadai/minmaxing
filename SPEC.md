# SPEC: HTML companion artifact hardening

## Problem Statement

The harness already allows `HTML` as a visualization mode, but the current gate
mostly checks that the route text exists. The recent audit of "The Unreasonable
Effectiveness of HTML" showed that HTML can improve human comprehension for
plans, diagrams, PR explainers, and interactive review, but it must not replace
the canonical Markdown/JSON contracts that drive implementation and verification.

The repo needs a surgical hardening pass: keep `/visualize` and
`/visualizeworkflow` as the existing surfaces, make HTML explicitly
companion-only unless promoted, and add fixture-backed validation for safe HTML
artifact packages.

## Success Criteria

- [x] Visualization rules state that HTML artifacts are presentation/review
  companions and cannot be the sole source of requirements, approvals, source
  ledgers, or verification evidence.
- [x] `/visualize` and `/visualizeworkflow` docs require HTML packages to point
  back to canonical Markdown/JSON files and stay no-secret/no-private by default.
- [x] `scripts/visualize-smoke.sh` validates green/red HTML package fixtures,
  including ignored run-dir policy, `approval.json` semantics, static HTML
  structure, no remote scripts/assets, no absolute paths, and no secret-like text.
- [x] `visualize-smoke` is visible in the harness eval metadata and capability
  map as a static gate.
- [x] Release/static gates remain green after the change.

## Scope

In:
- Existing `/visualize` and `/visualizeworkflow` contracts.
- Visualization rules.
- `visualize-smoke` fixture validation.
- Static eval metadata and generated capability-map refresh.

Out:
- A new `/html` route or skill.
- Browser hosting, upload, S3/GitHub Pages publishing, or live preview servers.
- Replacing `SPEC.md`, source ledgers, approval JSON, or verification sidecars
  with HTML.
- Runtime Claude, MiniMax, or image-generation calls.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` reported
  `codex_max_threads=10` and `recommended_ceiling=10`; this slice is tightly
  coupled and uses one local implementation lane.
- Agent wall-clock: optimistic 35m / likely 70m / pessimistic 120m.
- Human touch time: 0 unless the operator wants wording changes.
- Critical path: contract docs -> fixture validator -> eval registration ->
  capability map -> release gates.
- Confidence: medium-high; main risk is stale generated capability-map artifacts.

## Implementation Plan

1. Tighten the visualization rules and skill docs around the dual-artifact
   policy: Markdown/JSON canonical, HTML companion.
2. Extend `scripts/visualize-smoke.sh` with `--fixtures` and `--manifest`
   validation while keeping the no-arg release-check behavior.
3. Add tracked `.taste/fixtures/visualize-html` green/red packages.
4. Register `visualize-smoke` in `scripts/harness-eval.sh` and add eval
   task/golden files.
5. Regenerate `docs/harness-capability-map.md` and `.json`.
6. Verify with focused gates, then the static release gate.

## Verification

Required:

```bash
bash scripts/visualize-smoke.sh --fixtures
bash scripts/harness-eval.sh --metadata-json
bash scripts/harness-eval.sh --json
bash scripts/harness-capability-map.sh --write
bash scripts/harness-capability-map.sh --check --json
bash scripts/agentcloseout-physics-smoke.sh
bash scripts/release-check.sh --static-only
git diff --check
```

Verified static closeout on 2026-05-15:

- `bash scripts/visualize-smoke.sh --fixtures`
- `bash scripts/harness-eval.sh --metadata-json`
- `bash scripts/harness-eval.sh --json`
- `bash scripts/harness-capability-map.sh --write`
- `bash scripts/harness-capability-map.sh --check --json`
- `bash scripts/agentcloseout-physics-smoke.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

`bash scripts/release-check.sh --static-only` reported `167 passed, 0 failed`
and `static-only release gate passed`.

## Rollback Plan

1. Revert the HTML companion hardening commit.
2. Rerun `bash scripts/release-check.sh --static-only`.
3. Restore the archived SonnetMiniMax spec if that previous task needs to resume.
