#!/bin/bash
# Summarize Agent-Native Estimate calibration data from workflow artifacts.

set -euo pipefail

MODE="${1:-summary}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
  ROOT_DIR="$CLAUDE_PROJECT_DIR"
fi

WORKFLOW_DIR="$ROOT_DIR/.taste/workflow-runs"

python3 - "$MODE" "$WORKFLOW_DIR" "$ROOT_DIR" <<'PY'
import datetime as dt
import json
import os
import pathlib
import re
import sys


mode = sys.argv[1]
workflow_dir = pathlib.Path(sys.argv[2])
root = pathlib.Path(sys.argv[3])


def section(text: str, heading: str) -> str:
    pattern = re.compile(rf"^## {re.escape(heading)}\s*$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        return ""
    start = match.end()
    next_match = re.search(r"^## .+$", text[start:], re.MULTILINE)
    end = start + next_match.start() if next_match else len(text)
    return text[start:end].strip()


def line_value(text: str, label: str) -> str:
    match = re.search(rf"^- {re.escape(label)}\s*(.+)$", text, re.MULTILINE)
    return match.group(1).strip() if match else ""


def field_value(text: str, key: str) -> str:
    match = re.search(rf"^\s*(?:-\s*)?{re.escape(key)}\s*:\s*(.+)$", text, re.MULTILINE)
    return match.group(1).strip() if match else ""


def parse_time(value: str) -> dt.datetime | None:
    value = value.strip()
    if not value or value.lower() in {"unknown", "n/a", "na", "none"}:
        return None
    try:
        if value.endswith("Z"):
            value = value[:-1] + "+00:00"
        parsed = dt.datetime.fromisoformat(value)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed


records = []
if workflow_dir.exists():
    for path in sorted(workflow_dir.glob("*.md")):
        text = path.read_text(encoding="utf-8", errors="replace")
        estimate = section(text, "Agent-Native Estimate")
        if not estimate:
            continue

        verification = section(text, "Verification Evidence")
        combined = "\n".join([text, verification])
        started = parse_time(field_value(combined, "started_at"))
        closed = parse_time(field_value(combined, "closed_at"))
        elapsed_minutes = None
        if started and closed and closed >= started:
            elapsed_minutes = round((closed - started).total_seconds() / 60, 1)

        records.append(
            {
                "artifact": os.path.relpath(path, root),
                "agent_wall_clock": line_value(estimate, "Agent wall-clock:"),
                "agent_hours": line_value(estimate, "Agent-hours:"),
                "effective_lanes": line_value(estimate, "Effective lanes:"),
                "critical_path": line_value(estimate, "Critical path:"),
                "confidence": line_value(estimate, "Confidence:"),
                "started_at": field_value(combined, "started_at"),
                "closed_at": field_value(combined, "closed_at"),
                "actual_elapsed_minutes": elapsed_minutes,
                "failed_verification_count": field_value(combined, "failed_verification_count"),
                "human_blocker_minutes": field_value(combined, "human_blocker_minutes"),
            }
        )

if mode in {"--json", "json"}:
    print(json.dumps({"count": len(records), "records": records}, indent=2, sort_keys=True))
    raise SystemExit(0)

if mode not in {"summary", "--summary"}:
    print("Usage: bash scripts/estimate-history.sh [summary|--json]", file=sys.stderr)
    raise SystemExit(2)

if not records:
    print("estimate history: no workflow artifacts with Agent-Native Estimate yet")
    print("calibration: no actual-vs-estimated data available; do not invent numbers")
    raise SystemExit(0)

print(f"estimate history: {len(records)} artifact(s) with Agent-Native Estimate")
for record in records[-20:]:
    actual = (
        f"{record['actual_elapsed_minutes']}m"
        if record["actual_elapsed_minutes"] is not None
        else "unknown"
    )
    print(f"- {record['artifact']}")
    print(f"  agent_wall_clock: {record['agent_wall_clock'] or 'unknown'}")
    print(f"  agent_hours: {record['agent_hours'] or 'unknown'}")
    print(f"  effective_lanes: {record['effective_lanes'] or 'unknown'}")
    print(f"  critical_path: {record['critical_path'] or 'unknown'}")
    print(f"  confidence: {record['confidence'] or 'unknown'}")
    print(f"  actual_elapsed: {actual}")
PY
