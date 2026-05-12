#!/bin/bash
# Prepare or launch the Sonnet judgment + MiniMax Token Plan executor route.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/sonnetminimaxworkflow.sh --task "..." [--inner-contract CONTRACT] [--run-id ID] [--effort high|xhigh|max] [--execute-planner]

/sonnetminimax keeps the normal /opusworkflow governance but requests Sonnet
4.6 for planning, Spec QA/review, adversarial judgment, and final decision
work while keeping MiniMax-M2.7-highspeed from the MiniMax Token Plan as the
bounded executor. Default effort is max, which maps to Claude CLI xhigh.
EOF
}

EFFORT="${SONNETMINIMAX_EFFORT:-max}"
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
      echo "[sonnetminimax] $1 is fixed by /sonnetminimax; use /opusworkflow --model-profile custom for custom model routing" >&2
      exit 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

case "$EFFORT" in
  high|xhigh|max) ;;
  *) echo "[sonnetminimax] invalid effort: $EFFORT (expected high, xhigh, or max)" >&2; exit 2 ;;
esac

echo "[sonnetminimax] power-user route: Sonnet 4.6 judgment + MiniMax-M2.7-highspeed Token Plan execution"
echo "[sonnetminimax] effort: $EFFORT (default max; max maps to Claude CLI xhigh)"
echo "[sonnetminimax] governance: same /opusworkflow gates, artifacts, verification, and blocked-with-repair closeout"
echo "[sonnetminimax] identity: requested model route only until /status, sentinel, or runtime artifact proves it"

exec bash "$ROOT_DIR/scripts/opusworkflow.sh" \
  --model-profile sonnetminimax \
  --executor-provider minimax \
  --planner-model claude-sonnet-4-6 \
  --executor-model MiniMax-M2.7-highspeed \
  --effort "$EFFORT" \
  "${ARGS[@]}"
