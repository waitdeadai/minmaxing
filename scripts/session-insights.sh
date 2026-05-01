#!/bin/bash
# Flag unhealthy local harness runs from workflow and eval artifacts.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="text"
SOURCE="$ROOT_DIR"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/session-insights.sh [--json] [--fixtures] [PATH]

Reports local run health. Missing provider/cost/token data is not guessed.
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


def find_workflows(source: pathlib.Path) -> list[pathlib.Path]:
    if source.is_file():
        return [source]
    candidates: list[pathlib.Path] = []
    workflow_dir = source / ".taste" / "workflow-runs"
    if workflow_dir.is_dir():
        return sorted(path for path in workflow_dir.glob("*.md") if path.is_file())
    candidates.extend(source.rglob("*workflow*.md") if source.exists() else [])
    return sorted(set(path for path in candidates if path.is_file()))


def has(text: str, pattern: str) -> bool:
    return re.search(pattern, text, re.IGNORECASE | re.MULTILINE) is not None


def analyze(path: pathlib.Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8", errors="replace")
    issues: list[str] = []
    if "## Agent-Native Estimate" not in text:
        issues.append("missing_agent_native_estimate")
    if "## Verification Evidence" not in text or has(text, r"## Verification Evidence\s+Pending\.?"):
        issues.append("missing_verification_evidence")
    if "## Outcome" not in text or has(text, r"## Outcome\s+Pending\.?"):
        issues.append("missing_outcome")
    if has(text, r"(tests?|verification|smoke|harness)[^\n]*(failed|fail|error)") and has(
        text, r"(outcome|closeout|status)[^\n]*(verified|complete|completed|ready|pass(ed)?)"
    ):
        issues.append("failed_verification_positive_closeout_risk")
    if has(text, r"(done|complete|verified|ready)[^\n]*(trust me|no evidence|not recorded)"):
        issues.append("evidence_free_closeout_risk")
    if "harness-eval" not in text and "mismatches=0" not in text:
        issues.append("missing_eval_score")
    if has(text, r"(rework|retry|fix attempt|failed verification count)[^\n]*(3|4|5|high)"):
        issues.append("high_rework_indicator")
    return {
        "path": rel(path),
        "status": "healthy" if not issues else "unhealthy",
        "issues": issues,
    }


records = [analyze(path) for path in find_workflows(SOURCE)]
unhealthy = [record for record in records if record["status"] != "healthy"]
payload = {
    "source": rel(SOURCE),
    "status": "healthy" if records and not unhealthy else ("insufficient_data" if not records else "unhealthy"),
    "run_count": len(records),
    "unhealthy_count": len(unhealthy),
    "healthy_count": len(records) - len(unhealthy),
    "provider_cost": "insufficient_data",
    "provider_tokens": "insufficient_data",
    "records": records,
}

if MODE == "json":
    print(json.dumps(payload, indent=2, sort_keys=True))
else:
    print("Session Insights")
    print(
        f"source={payload['source']} status={payload['status']} "
        f"runs={payload['run_count']} healthy={payload['healthy_count']} unhealthy={payload['unhealthy_count']}"
    )
    print("provider_cost=insufficient_data provider_tokens=insufficient_data")
    for record in records:
        if record["issues"]:
            print(f"- {record['path']}: {','.join(record['issues'])}")
PY
