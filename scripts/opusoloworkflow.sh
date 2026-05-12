#!/bin/bash
# Prepare or launch the all-Opus /opusworkflow sibling route.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/opusoloworkflow.sh --task "..." [--inner-contract CONTRACT] [--run-id ID] [--effort high|max] [--execute-planner]

/opusolo keeps the normal /opusworkflow governance but requests Opus 4.7 as
planner, executor, Spec QA reviewer, adversary, and final judge. Default effort
is high. Use --effort max for the highest available Claude CLI effort alias.
EOF
}

EFFORT="${OPUSOLO_EFFORT:-high}"
ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    "-h"|"--help")
      usage
      exit 0
      ;;
    "--effort")
      EFFORT="${2:-}"
      shift 2
      ;;
    "--model-profile"|"--executor-provider"|"--planner-model"|"--executor-model")
      echo "[opusolo] $1 is fixed by /opusolo; use /opusworkflow --model-profile custom for custom model routing" >&2
      exit 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

case "$EFFORT" in
  high|max|xhigh) ;;
  *) echo "[opusolo] invalid effort: $EFFORT (expected high, max, or xhigh)" >&2; exit 2 ;;
esac

echo "[opusolo] all-Opus route: Opus 4.7 planning, execution, review, and judgment"
echo "[opusolo] effort: $EFFORT (default high; max maps to the highest Claude CLI effort)"
echo "[opusolo] governance: same /opusworkflow gates, artifacts, verification, and blocked-with-repair closeout"

exec bash "$ROOT_DIR/scripts/opusworkflow.sh" \
  --model-profile opus \
  --executor-provider anthropic \
  --planner-model claude-opus-4-7 \
  --executor-model claude-opus-4-7 \
  --effort "$EFFORT" \
  "${ARGS[@]}"
