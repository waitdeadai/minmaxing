#!/bin/bash
# Prepare or explicitly launch the cost-optimized /opusworkflow route.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/opusworkflow.sh --task "..." [--run-id ID] [--execute-planner] [--planner-settings PATH] [--planner-model MODEL] [--executor-model MODEL]

/opusworkflow is the cost-optimized workflow entrypoint. It reuses
scripts/opusminimax.sh in workflow mode, keeping Claude/Opus for judgment and
MiniMax-M2.7-highspeed for bounded execution packets.
EOF
}

ARGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    "--mode")
      echo "[opusworkflow] --mode is fixed to workflow; use /opusminimax for benchmark or repair modes" >&2
      exit 2
      ;;
    "-h"|"--help")
      usage
      exit 0
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

echo "[opusworkflow] cost-optimized mode: Claude/Opus judgment, MiniMax-M2.7-highspeed execution, default executor concurrency=1"
exec bash "$ROOT_DIR/scripts/opusminimax.sh" --mode workflow "${ARGS[@]}"
