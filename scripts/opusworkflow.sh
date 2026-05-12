#!/bin/bash
# Prepare or explicitly launch the definitive /opusworkflow route.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/opusworkflow.sh --task "..." [--inner-contract CONTRACT] [--run-id ID] [--model-profile minimax|opussonnet|sonnet|opus|default|custom] [--executor-provider minimax|claude-sonnet|anthropic] [--plan-mode-policy auto|manual|off] [--effort high|xhigh|max] [--execute-planner] [--planner-settings PATH] [--planner-model MODEL] [--executor-model MODEL]

/opusworkflow is the definitive effectiveness-first workflow entrypoint. It
reuses scripts/opusminimax.sh in workflow mode, requesting Opus 4.7 for
judgment and MiniMax-M2.7-highspeed for bounded execution packets. A real
closeout must be verified, partial, or blocked-with-repair.

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
digestaste, deepretaste, demo, or visualizeworkflow.

Plan mode policy:
  auto    Default. Record a plan-mode checkpoint and auto-approve execution
          after research, code audit, pre-plan introspection, estimate, SPEC,
          and Spec QA gates allow execution.
  manual  Record the same checkpoint but require explicit human approval.
  off     Disable the plan-mode checkpoint for advanced/manual debugging.
EOF
}

ARGS=()
EXECUTOR_PROVIDER="${OPUSWORKFLOW_EXECUTOR_PROVIDER:-minimax}"
MODEL_PROFILE="${OPUSWORKFLOW_MODEL_PROFILE:-}"
PLAN_MODE_POLICY="${OPUSWORKFLOW_PLAN_MODE_POLICY:-auto}"
EFFORT="${OPUSWORKFLOW_EFFORT:-}"
EXECUTOR_PROVIDER_SET=0
EXECUTOR_MODEL_SET=0
MODEL_PROFILE_SET=0
PLAN_MODE_POLICY_SET=0
EFFORT_SET=0
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
    "--plan-mode-policy")
      PLAN_MODE_POLICY="${2:-}"
      PLAN_MODE_POLICY_SET=1
      ARGS+=("$1" "$2")
      shift 2
      ;;
    "--effort")
      EFFORT="${2:-}"
      EFFORT_SET=1
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

echo "[opusworkflow] definitive route: Opus 4.7 judgment + MiniMax-M2.7-highspeed execution"
echo "[opusworkflow] closeout policy: verified, partial, or blocked-with-repair"
echo "[opusworkflow] spec qa: required after SPEC.md and before implementation"

case "$PLAN_MODE_POLICY" in
  auto)
    echo "[opusworkflow] plan-mode auto-approval: execution starts only after research/audit/introspection/estimate/SPEC/Spec QA gates pass"
    ;;
  manual)
    echo "[opusworkflow] plan-mode policy: manual approval required after the plan checkpoint"
    ;;
  off)
    echo "[opusworkflow] plan-mode policy: off"
    ;;
  *)
    echo "[opusworkflow] invalid plan mode policy: $PLAN_MODE_POLICY" >&2
    exit 2
    ;;
esac

if [ -n "$EFFORT" ]; then
  case "$EFFORT" in
    high|xhigh|max)
      echo "[opusworkflow] effort: $EFFORT"
      ;;
    *)
      echo "[opusworkflow] invalid effort: $EFFORT (expected high, xhigh, or max)" >&2
      exit 2
      ;;
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
if [ "$PLAN_MODE_POLICY_SET" -eq 0 ]; then
  ARGS+=("--plan-mode-policy" "$PLAN_MODE_POLICY")
fi
if [ "$EFFORT_SET" -eq 0 ] && [ -n "$EFFORT" ]; then
  ARGS+=("--effort" "$EFFORT")
fi
exec bash "$ROOT_DIR/scripts/opusminimax.sh" --mode workflow --outer-route opusworkflow "${ARGS[@]}"
