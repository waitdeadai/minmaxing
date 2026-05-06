#!/bin/bash
# Prepare or explicitly launch the /opusminimax planner workflow.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK=""
MODE="workflow"
RUN_ID=""
EXECUTE_PLANNER=0
PLANNER_SETTINGS="${CLAUDE_PLANNER_SETTINGS_PATH:-$ROOT_DIR/.claude/settings.opusminimax-planner.local.json}"
PLANNER_MODEL="${OPUSMINIMAX_PLANNER_MODEL:-claude-opus-4-7}"
EXECUTOR_MODEL="${OPUSMINIMAX_EXECUTOR_MODEL:-MiniMax-M2.7-highspeed}"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/opusminimax.sh --task "..." [--mode workflow|benchmark|repair] [--execute-planner] [--planner-settings PATH]

Default behavior prepares no-secret run artifacts and prints the next command.
--execute-planner is the explicit Claude runtime opt-in.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--task")
      TASK="${2:-}"
      shift 2
      ;;
    "--mode")
      MODE="${2:-}"
      shift 2
      ;;
    "--run-id")
      RUN_ID="${2:-}"
      shift 2
      ;;
    "--planner-settings")
      PLANNER_SETTINGS="${2:-}"
      shift 2
      ;;
    "--planner-model")
      PLANNER_MODEL="${2:-}"
      shift 2
      ;;
    "--executor-model")
      EXECUTOR_MODEL="${2:-}"
      shift 2
      ;;
    "--execute-planner")
      EXECUTE_PLANNER=1
      shift
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
done

[ -n "$TASK" ] || { usage; exit 2; }
case "$MODE" in
  workflow|benchmark|repair) ;;
  *) echo "[opusminimax] invalid mode: $MODE" >&2; exit 2 ;;
esac

if [ -z "$RUN_ID" ]; then
  STAMP="$(date +%Y%m%d-%H%M%S)"
  SLUG="$(printf '%s' "$TASK" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g; s/-+/-/g' | cut -c1-48)"
  RUN_ID="${STAMP}-${SLUG:-task}"
fi

RUN_DIR="$ROOT_DIR/.taste/opusminimax/$RUN_ID"
PACKET_DIR="$RUN_DIR/packets"
mkdir -p "$PACKET_DIR"

PACKET="$PACKET_DIR/P1.json"
RUN_ARTIFACT="$RUN_DIR/opusminimax-run.json"

python3 - "$TASK" "$MODE" "$RUN_ID" "$PACKET" "$RUN_ARTIFACT" "$PLANNER_MODEL" "$EXECUTOR_MODEL" <<'PY'
import json
import pathlib
import sys

task, mode, run_id, packet_path, run_artifact, planner_model, executor_model = sys.argv[1:8]
packet_path = pathlib.Path(packet_path)
run_artifact = pathlib.Path(run_artifact)

packet = {
    "artifact_type": "opusminimax-packet",
    "run_id": run_id,
    "packet_id": "P1",
    "objective": f"Prepare implementation packet for: {task}",
    "context_summary": f"Mode={mode}. Claude planner must refine this packet before MiniMax execution.",
    "owned_paths": ["SPEC.md"],
    "forbidden_paths": [".env", ".env.*", ".claude/*.local.json", "secrets/**"],
    "commands_allowed": ["bash scripts/opusminimax-doctor.sh --static"],
    "acceptance_checks": ["packet is refined before execution", "parent verification checks evidence"],
    "risk_notes": ["Initial packet is a placeholder until the planner writes exact ownership."],
    "rollback_plan": "Do not execute until planner replaces placeholder ownership with a task-specific packet.",
    "expected_outputs": ["refined packet", "diff evidence", "command evidence"],
    "stop_conditions": ["ambiguous ownership", "secret requested", "provider identity unverified"],
}
run = {
    "artifact_type": "opusminimax-run",
    "run_id": run_id,
    "provider_profiles": {
        "planner": {
            "path": ".claude/settings.opusminimax-planner.example.json",
            "anthropic_base_url": "",
            "model": planner_model,
        },
        "executor": {
            "path": ".claude/settings.minimax-executor.example.json",
            "anthropic_base_url": "https://api.minimax.io/anthropic",
            "model": executor_model,
        },
    },
    "model_ids": {
        "planner_requested": planner_model,
        "executor_requested": executor_model,
    },
    "capacity": {
        "local_ceiling": 10,
        "provider_ceiling": 1,
        "task_packet_count": 1,
        "safety_cap": 1,
        "effective_concurrency": 1,
    },
    "packets": ["P1"],
    "verification": {
        "status": "runtime-pending",
        "commands_run": ["bash scripts/opusminimax.sh --task ..."],
        "closeout_status": "runtime-pending",
    },
    "failures": [],
    "retries": 0,
    "final_confidence": "medium",
    "model_identity_confirmed": False,
    "claims": {
        "opus_planned": False,
        "runtime_model_calls": False,
    },
}
packet_path.write_text(json.dumps(packet, indent=2, sort_keys=True) + "\n", encoding="utf-8")
run_artifact.write_text(json.dumps(run, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

bash "$ROOT_DIR/scripts/artifact-lint.sh" "$PACKET"
bash "$ROOT_DIR/scripts/artifact-lint.sh" "$RUN_ARTIFACT"

echo "[opusminimax] prepared run: $RUN_DIR"
echo "[opusminimax] packet: $PACKET"
echo "[opusminimax] run artifact: $RUN_ARTIFACT"

if [ "$EXECUTE_PLANNER" -eq 0 ]; then
  echo "[opusminimax] runtime not executed. To launch planner explicitly:"
  echo "  bash scripts/opusminimax.sh --task \"$TASK\" --mode $MODE --execute-planner"
  exit 0
fi

if [ ! -f "$PLANNER_SETTINGS" ]; then
  echo "[opusminimax] missing planner settings: $PLANNER_SETTINGS" >&2
  echo "[opusminimax] copy .claude/settings.opusminimax-planner.example.json to an ignored local profile first" >&2
  exit 1
fi

PROMPT="/opusminimax mode=$MODE task=$TASK run_dir=$RUN_DIR planner_model=$PLANNER_MODEL executor_model=$EXECUTOR_MODEL"
claude --model "$PLANNER_MODEL" --effort xhigh --settings "$PLANNER_SETTINGS" -p "$PROMPT"
