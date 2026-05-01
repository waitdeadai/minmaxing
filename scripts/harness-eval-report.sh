#!/bin/bash
# Print a concise summary for the local static harness eval pack.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="metadata"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/harness-eval-report.sh
  bash scripts/harness-eval-report.sh --run

Without --run, reads validated eval metadata and prints expected counts.
With --run, runs scripts/harness-eval.sh --json and includes actual gate status.
EOF
}

case "${1:-}" in
  "")
    ;;
  "--metadata")
    MODE="metadata"
    ;;
  "--run")
    MODE="run"
    ;;
  "-h"|"--help")
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
INPUT_FILE="$TMP_DIR/input.json"

if [ "$MODE" = "run" ]; then
  set +e
  bash "$ROOT_DIR/scripts/harness-eval.sh" --json > "$INPUT_FILE"
  eval_status=$?
  set -e
  if [ ! -s "$INPUT_FILE" ]; then
    exit "$eval_status"
  fi
else
  bash "$ROOT_DIR/scripts/harness-eval.sh" --metadata-json > "$INPUT_FILE"
  eval_status=0
fi

python3 - "$MODE" "$INPUT_FILE" <<'PY'
import json
import sys
from collections import Counter, defaultdict


mode, input_path = sys.argv[1:3]
data = json.loads(open(input_path, encoding="utf-8").read())


def fmt_counts(counts: dict[str, int]) -> str:
    if not counts:
        return "none"
    return " ".join(f"{key}={counts[key]}" for key in sorted(counts))


print("Harness Eval Report")

if mode == "run":
    expected_results = data.get("expected_result_counts", {})
    expected_gate_status = data.get("expected_gate_status_counts", {})
    actual = Counter(result["status"] for result in data.get("gate_results", {}).values())
    print(
        f"mode=run status={data.get('status', 'unknown')} "
        f"tasks={data.get('tasks', 0)} gates={data.get('gates', 0)} "
        f"mismatches={len(data.get('mismatches', []))}"
    )
    print(f"expected_result: {fmt_counts(expected_results)}")
    print(f"expected_gate_status: {fmt_counts(expected_gate_status)}")
    print(f"actual_gate_status: {fmt_counts(dict(actual))}")
    print("by_gate:")
    for gate, result in sorted(data.get("gate_results", {}).items()):
        expected_counts = data.get("gate_expected_result_counts", {}).get(gate, {})
        print(
            f"- {gate}: expected_result[{fmt_counts(expected_counts)}] "
            f"actual={result['status']} exit={result['exit_code']}"
        )
    if data.get("mismatches"):
        print("mismatches:")
        for mismatch in data["mismatches"]:
            print(
                f"- {mismatch['id']}: gate={mismatch['gate']} "
                f"expected_gate={mismatch['expected_gate_status']} "
                f"expected_result={mismatch['expected_result']} actual={mismatch['actual_status']}"
            )
else:
    tasks = data.get("tasks", [])
    result_counts = Counter(task["expected_result"] for task in tasks)
    gate_status_counts = Counter(task["expected_gate_status"] for task in tasks)
    gate_counts: dict[str, Counter[str]] = defaultdict(Counter)
    for task in tasks:
        gate_counts[task["gate"]][task["expected_result"]] += 1

    print(f"mode=metadata tasks={len(tasks)} gates={len(data.get('gates', []))}")
    print(f"expected_result: {fmt_counts(dict(result_counts))}")
    print(f"expected_gate_status: {fmt_counts(dict(gate_status_counts))}")
    print("by_gate:")
    for gate in sorted(gate_counts):
        print(f"- {gate}: {fmt_counts(dict(gate_counts[gate]))}")
PY

exit "$eval_status"
