#!/bin/bash
# Prepare or explicitly launch the cost-optimized /opusworkflow route.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/opusworkflow.sh --task "..." [--inner-contract CONTRACT] [--run-id ID] [--model-profile minimax|opussonnet|sonnet|opus|default|custom] [--executor-provider minimax|claude-sonnet|anthropic] [--execute-planner] [--planner-settings PATH] [--planner-model MODEL] [--executor-model MODEL]

/opusworkflow is the cost-optimized workflow entrypoint. It reuses
scripts/opusminimax.sh in workflow mode, keeping Claude/Opus for judgment and
MiniMax-M2.7-highspeed for bounded execution packets.

The optional claude-sonnet executor provider keeps the same workflow governance
but uses Claude Code opusplan/Sonnet 4.6 instead of MiniMax.

Model profiles:
  minimax     Opus judgment + MiniMax execution (default)
  opussonnet  Opus judgment + Sonnet execution, no MiniMax token
  sonnet      Sonnet for planning and execution
  opus        Opus for planning and execution
  default     Claude Code account default for planning and execution
  custom      Explicit --planner-model and --executor-model values

CONTRACT may be workflow, agentfactory, hiveworkflow, parallel, defineicp,
deepretaste, demo, or visualizeworkflow.
EOF
}

ARGS=()
EXECUTOR_PROVIDER="${OPUSWORKFLOW_EXECUTOR_PROVIDER:-minimax}"
MODEL_PROFILE="${OPUSWORKFLOW_MODEL_PROFILE:-}"
EXECUTOR_PROVIDER_SET=0
EXECUTOR_MODEL_SET=0
MODEL_PROFILE_SET=0
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
    "--model-profile")
      MODEL_PROFILE="${2:-}"
      MODEL_PROFILE_SET=1
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

if [ -z "$MODEL_PROFILE" ]; then
  case "$EXECUTOR_PROVIDER" in
    minimax) MODEL_PROFILE="minimax" ;;
    claude-sonnet) MODEL_PROFILE="opussonnet" ;;
    anthropic) MODEL_PROFILE="custom" ;;
  esac
fi

if [ "$EXECUTOR_PROVIDER_SET" -eq 0 ]; then
  case "$MODEL_PROFILE" in
    minimax) EXECUTOR_PROVIDER="minimax" ;;
    opussonnet) EXECUTOR_PROVIDER="claude-sonnet" ;;
    sonnet|opus|default|custom) EXECUTOR_PROVIDER="anthropic" ;;
  esac
fi

case "$MODEL_PROFILE" in
  minimax)
    echo "[opusworkflow] model profile: minimax (Opus judgment, MiniMax-M2.7-highspeed execution)"
    ;;
  opussonnet)
    echo "[opusworkflow] model profile: opussonnet (Opus 4.7 planning, Sonnet 4.6 execution)"
    ;;
  sonnet)
    echo "[opusworkflow] model profile: sonnet (Sonnet 4.6 planning and execution)"
    ;;
  opus)
    echo "[opusworkflow] model profile: opus (Opus 4.7 planning and execution; explicit high-cost route)"
    ;;
  default)
    echo "[opusworkflow] model profile: default (Claude Code account default; runtime identity remains unproven)"
    ;;
  custom)
    echo "[opusworkflow] model profile: custom (explicit planner/executor model request)"
    ;;
  *)
    echo "[opusworkflow] invalid model profile: $MODEL_PROFILE" >&2
    exit 2
    ;;
esac

case "$EXECUTOR_PROVIDER" in
  minimax)
    echo "[opusworkflow] executor provider: minimax"
    ;;
  claude-sonnet)
    if [ "$EXECUTOR_MODEL_SET" -eq 0 ]; then
      ARGS+=("--executor-model" "claude-sonnet-4-6")
    fi
    echo "[opusworkflow] executor provider: claude-sonnet"
    ;;
  anthropic)
    echo "[opusworkflow] executor provider: anthropic"
    ;;
  *)
    echo "[opusworkflow] invalid executor provider: $EXECUTOR_PROVIDER" >&2
    exit 2
    ;;
esac

if [ "$EXECUTOR_PROVIDER_SET" -eq 0 ]; then
  ARGS+=("--executor-provider" "$EXECUTOR_PROVIDER")
fi
if [ "$MODEL_PROFILE_SET" -eq 0 ]; then
  ARGS+=("--model-profile" "$MODEL_PROFILE")
fi
exec bash "$ROOT_DIR/scripts/opusminimax.sh" --mode workflow --outer-route opusworkflow "${ARGS[@]}"
