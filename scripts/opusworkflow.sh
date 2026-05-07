#!/bin/bash
# Prepare or explicitly launch the cost-optimized /opusworkflow route.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/opusworkflow.sh --task "..." [--inner-contract CONTRACT] [--run-id ID] [--executor-provider minimax|claude-sonnet] [--execute-planner] [--planner-settings PATH] [--planner-model MODEL] [--executor-model MODEL]

/opusworkflow is the cost-optimized workflow entrypoint. It reuses
scripts/opusminimax.sh in workflow mode, keeping Claude/Opus for judgment and
MiniMax-M2.7-highspeed for bounded execution packets.

The optional claude-sonnet executor provider keeps the same workflow governance
but uses Claude Code opusplan/Sonnet 4.6 instead of MiniMax.

CONTRACT may be workflow, agentfactory, hiveworkflow, parallel, defineicp,
deepretaste, demo, or visualizeworkflow.
EOF
}

ARGS=()
EXECUTOR_PROVIDER="${OPUSWORKFLOW_EXECUTOR_PROVIDER:-minimax}"
EXECUTOR_PROVIDER_SET=0
EXECUTOR_MODEL_SET=0
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
    "--executor-provider")
      EXECUTOR_PROVIDER="${2:-}"
      EXECUTOR_PROVIDER_SET=1
      ARGS+=("$1" "$2")
      shift 2
      ;;
    "--executor-model")
      EXECUTOR_MODEL_SET=1
      ARGS+=("$1" "$2")
      shift 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

case "$EXECUTOR_PROVIDER" in
  minimax)
    echo "[opusworkflow] cost-optimized mode: Claude/Opus judgment, MiniMax-M2.7-highspeed execution, default executor concurrency=1"
    ;;
  claude-sonnet)
    if [ "$EXECUTOR_MODEL_SET" -eq 0 ]; then
      ARGS+=("--executor-model" "claude-sonnet-4-6")
    fi
    echo "[opusworkflow] suggested Claude-only mode: Opus 4.7 planning, Sonnet 4.6 execution, default executor concurrency=1"
    ;;
  *)
    echo "[opusworkflow] invalid executor provider: $EXECUTOR_PROVIDER" >&2
    exit 2
    ;;
esac
if [ "$EXECUTOR_PROVIDER_SET" -eq 0 ]; then
  ARGS+=("--executor-provider" "$EXECUTOR_PROVIDER")
fi
exec bash "$ROOT_DIR/scripts/opusminimax.sh" --mode workflow --outer-route opusworkflow "${ARGS[@]}"
