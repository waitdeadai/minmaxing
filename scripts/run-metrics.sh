#!/bin/bash
# Summarize local harness run artifacts without inventing missing provider data.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="text"
SOURCE="$ROOT_DIR"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/run-metrics.sh [--json] [--fixtures] [PATH]

Summarizes local workflow, Codex run, and harness eval artifacts. Provider
cost, token, and ACU data are reported as insufficient_data when unavailable.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--json")
      MODE="json"
      shift
      ;;
    "--fixtures")
      SOURCE="$ROOT_DIR/.taste/fixtures/session-insights"
      shift
      ;;
    "-h"|"--help")
      usage
      exit 0
      ;;
    --*)
      usage
      exit 2
      ;;
    *)
      SOURCE="$1"
      shift
      ;;
  esac
done

python3 - "$ROOT_DIR" "$SOURCE" "$MODE" <<'PY'
import json
import pathlib
import re
import sys
from typing import Any


ROOT = pathlib.Path(sys.argv[1]).resolve()
SOURCE = pathlib.Path(sys.argv[2]).resolve()
MODE = sys.argv[3]


def rel(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def read(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def find_files(source: pathlib.Path, patterns: list[str]) -> list[pathlib.Path]:
    files: list[pathlib.Path] = []
    if source.is_file():
        return [source]
    if not source.exists():
        return []
    for pattern in patterns:
        files.extend(path for path in source.rglob(pattern) if path.is_file())
    return sorted(set(files))


def has(text: str, pattern: str) -> bool:
    return re.search(pattern, text, re.IGNORECASE | re.MULTILINE) is not None


workflow_files = find_files(SOURCE / ".taste" / "workflow-runs", ["*.md"])
if not workflow_files:
    workflow_files = find_files(SOURCE, ["*workflow*.md"])

codex_files = find_files(SOURCE / ".taste" / "codex-runs", ["*.codex-run"])
if not codex_files:
    codex_files = find_files(SOURCE, ["*.codex-run"])

eval_task_files = find_files(SOURCE / "evals" / "harness" / "tasks", ["*.yaml"])
eval_golden_files = find_files(SOURCE / "evals" / "harness" / "golden", ["*.json"])
if not eval_task_files:
    eval_task_files = find_files(SOURCE, ["*.yaml"])
if not eval_golden_files:
    eval_golden_files = find_files(SOURCE, ["*.json"])

workflow_records: list[dict[str, Any]] = []
for path in workflow_files:
    text = read(path)
    record = {
        "path": rel(path),
        "has_agent_native_estimate": "## Agent-Native Estimate" in text,
        "has_verification_evidence": "## Verification Evidence" in text and not has(text, r"## Verification Evidence\s+Pending\.?"),
        "has_outcome": "## Outcome" in text and not has(text, r"## Outcome\s+Pending\.?"),
        "verification_failed": has(text, r"(verification|tests?|smoke|harness)[^\n]*(fail|failed|error)"),
        "positive_closeout": has(text, r"(implemented|verified|complete|completed|ready|pass(ed)?)"),
        "eval_score_present": has(text, r"(harness eval|mismatches=0|tasks=\d+|gates=\d+)"),
    }
    workflow_records.append(record)

metrics = {
    "source": rel(SOURCE),
    "workflow_runs": len(workflow_records),
    "workflow_runs_with_agent_native_estimate": sum(1 for item in workflow_records if item["has_agent_native_estimate"]),
    "workflow_runs_with_verification_evidence": sum(1 for item in workflow_records if item["has_verification_evidence"]),
    "workflow_runs_with_outcome": sum(1 for item in workflow_records if item["has_outcome"]),
    "workflow_runs_with_eval_score": sum(1 for item in workflow_records if item["eval_score_present"]),
    "workflow_runs_with_failed_verification_markers": sum(1 for item in workflow_records if item["verification_failed"]),
    "codex_run_artifacts": len(codex_files),
    "eval_tasks": len(eval_task_files),
    "eval_goldens": len(eval_golden_files),
    "provider_cost": "insufficient_data",
    "provider_tokens": "insufficient_data",
    "acu": "insufficient_data",
    "estimate_calibration": "insufficient_data",
    "records": workflow_records,
}

if MODE == "json":
    print(json.dumps(metrics, indent=2, sort_keys=True))
else:
    print("Run Metrics")
    print(f"source={metrics['source']}")
    print(
        "workflow_runs={workflow_runs} estimates={workflow_runs_with_agent_native_estimate} "
        "verification={workflow_runs_with_verification_evidence} outcomes={workflow_runs_with_outcome}".format(**metrics)
    )
    print(
        "codex_runs={codex_run_artifacts} eval_tasks={eval_tasks} eval_goldens={eval_goldens}".format(**metrics)
    )
    print("provider_cost=insufficient_data provider_tokens=insufficient_data acu=insufficient_data")
PY
