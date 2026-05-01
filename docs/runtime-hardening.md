# Runtime Hardening

The runtime-hardening layer keeps minmaxing honest about local execution. It is
designed for no-secret, local-only evidence: scripts inspect files and local
artifacts, and provider telemetry is reported as `insufficient_data` unless a
local artifact proves a value.

## Operator Summary

Use the harness doctor when you want one operator-facing health snapshot:

```bash
bash scripts/harness-doctor.sh
bash scripts/harness-doctor.sh --json
bash scripts/harness-doctor.sh --html .taste/reports/harness-doctor.html
```

The doctor checks:

- `git status --short`, including dirty file count and current branch/head.
- `SPEC.md` presence and `## Agent-Native Estimate`.
- `.claude/settings.json` JSON validity, mapped hook events, and referenced
  hook script presence.
- `bash scripts/memory.sh health` when the memory script is available.
- `bash scripts/run-metrics.sh --json` when available.
- `bash scripts/session-insights.sh --json` when available.

It does not read `.env`, `.env.*`, `.claude/settings.local.json`, or secret
folders. It does not use the network.

## Telemetry Posture

Local scripts must not invent provider cost, token, ACU, or calibration data.
When those values are unavailable, reports should say:

```text
insufficient_data
```

This is intentional. Static harness evidence can prove local contracts,
fixtures, and artifact health. It cannot prove authenticated provider runtime
costs unless those values exist in local run artifacts.

## Related Scripts

- **Trace Ledger:** `scripts/trace-ledger.sh` appends, validates, and summarizes
  local JSONL events under `.taste/traces/`.
- **Worktree Runner:** `scripts/worktree-runner.sh` validates packet ownership
  and can run commands in explicit isolated git worktrees.
- **Scenario Eval:** `scripts/scenario-eval.sh` runs no-secret, no-network JSON
  scenarios from `evals/scenarios/`.
- **Learning Loop:** `scripts/learning-loop.sh` turns workflow, trace, and eval
  artifacts into verified insights and failure taxonomy.
- **Harness Doctor:** `scripts/harness-doctor.sh` composes the operator view
  without becoming a release gate by itself.
- `scripts/run-metrics.sh` summarizes local workflow, Codex run, and eval
  artifacts.
- `scripts/session-insights.sh` flags unhealthy workflow artifacts and missing
  evidence patterns.
- `scripts/memory.sh health` checks flat-file memory and SQLite/FTS5 memory
  availability.

Use `scripts/release-check.sh --static-only` for release readiness. Use the
doctor as a quick runtime posture report before handing work to an operator.
