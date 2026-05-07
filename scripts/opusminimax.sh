#!/bin/bash
# Prepare or explicitly launch the /opusminimax planner workflow.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK=""
MODE="workflow"
OUTER_ROUTE="opusminimax"
INNER_CONTRACT="workflow"
RUN_ID=""
EXECUTE_PLANNER=0
PLANNER_SETTINGS="${CLAUDE_PLANNER_SETTINGS_PATH:-$ROOT_DIR/.claude/settings.opusminimax-planner.local.json}"
PLANNER_MODEL="${OPUSMINIMAX_PLANNER_MODEL:-claude-opus-4-7}"
EXECUTOR_MODEL="${OPUSMINIMAX_EXECUTOR_MODEL:-MiniMax-M2.7-highspeed}"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/opusminimax.sh --task "..." [--mode workflow|benchmark|repair] [--outer-route ROUTE] [--inner-contract CONTRACT] [--execute-planner] [--planner-settings PATH]

Default behavior prepares no-secret run artifacts and prints the next command.
--execute-planner is the explicit Claude runtime opt-in.

CONTRACT may be workflow, agentfactory, hiveworkflow, parallel, defineicp,
deepretaste, demo, or visualizeworkflow.
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
    "--outer-route")
      OUTER_ROUTE="${2:-}"
      shift 2
      ;;
    "--inner-contract")
      INNER_CONTRACT="${2:-}"
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
case "$OUTER_ROUTE" in
  opusworkflow|opusminimax) ;;
  *) echo "[opusminimax] invalid outer route: $OUTER_ROUTE" >&2; exit 2 ;;
esac
case "$INNER_CONTRACT" in
  workflow|agentfactory|hiveworkflow|parallel|defineicp|deepretaste|demo|visualizeworkflow) ;;
  *) echo "[opusminimax] invalid inner contract: $INNER_CONTRACT" >&2; exit 2 ;;
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

python3 - "$TASK" "$MODE" "$OUTER_ROUTE" "$INNER_CONTRACT" "$RUN_ID" "$PACKET" "$RUN_ARTIFACT" "$PLANNER_MODEL" "$EXECUTOR_MODEL" <<'PY'
import json
import pathlib
import sys

task, mode, outer_route, inner_contract, run_id, packet_path, run_artifact, planner_model, executor_model = sys.argv[1:10]
packet_path = pathlib.Path(packet_path)
run_artifact = pathlib.Path(run_artifact)

packet = {
    "artifact_type": "opusminimax-packet",
    "run_id": run_id,
    "packet_id": "P1",
    "objective": f"Prepare implementation packet for: {task}",
    "context_summary": f"Outer route={outer_route}. Inner contract={inner_contract}. Mode={mode}. Claude planner must refine this packet before MiniMax execution.",
    "owned_paths": ["SPEC.md"],
    "forbidden_paths": [".env", ".env.*", ".claude/*.local.json", "secrets/**"],
    "commands_allowed": ["bash scripts/opusminimax-doctor.sh --static"],
    "acceptance_checks": ["packet is refined before execution", "parent verification checks evidence"],
    "risk_notes": ["Initial packet is a placeholder until the planner writes exact ownership."],
    "rollback_plan": "Do not execute until planner replaces placeholder ownership with a task scoped packet.",
    "expected_outputs": ["refined packet", "diff evidence", "command evidence"],
    "stop_conditions": ["ambiguous ownership", "secret requested", "provider identity unverified"],
}
run = {
    "artifact_type": "opusminimax-run",
    "run_id": run_id,
    "outer_route": outer_route,
    "inner_contract": inner_contract,
    "planner_identity_status": "blocked",
    "executor_identity_status": "configured",
    "fallback_status": "none" if outer_route == "opusworkflow" else "explicit_user_override",
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
  echo "  bash scripts/opusminimax.sh --task \"$TASK\" --mode $MODE --outer-route $OUTER_ROUTE --inner-contract $INNER_CONTRACT --execute-planner"
  exit 0
fi

if [ ! -f "$PLANNER_SETTINGS" ]; then
  echo "[opusminimax] missing planner settings; attempting safe local profile repair" >&2
fi

DOCTOR_JSON="$(mktemp)"
if ! bash "$ROOT_DIR/scripts/opusminimax-doctor.sh" --runtime --fix-local-profiles --json >"$DOCTOR_JSON"; then
  echo "[opusminimax] planner identity blocked: runtime doctor failed." >&2
  echo "[opusminimax] repair steps: run claude auth login, ensure Opus is available on the account, unset ANTHROPIC_API_KEY for subscription billing, then retry." >&2
  rm -f "$DOCTOR_JSON"
  exit 1
fi

if ! python3 - "$DOCTOR_JSON" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
blocking = []
for item in payload.get("checks", []):
    name = str(item.get("name", ""))
    status = str(item.get("status", ""))
    if status == "fail":
        blocking.append(f"{name}: {status}")
        continue
    if name in {
        "claude version >= 2.1.111",
        "claude auth status",
        "ANTHROPIC_API_KEY subscription billing footgun",
        "planner local profile exists",
        "executor local profile exists",
        "planner local profile has no MiniMax base URL",
        "executor local profile uses MiniMax-M2.7-highspeed",
        "executor local profile does not alias Opus to MiniMax",
    } and status != "pass":
        blocking.append(f"{name}: {status}")

if blocking:
    print("[opusminimax] runtime doctor blocking checks:", file=sys.stderr)
    for line in blocking:
        print(f"  - {line}", file=sys.stderr)
    print("[opusminimax] repair steps:", file=sys.stderr)
    for step in payload.get("operator_repair_steps", []):
        print(f"  - {step}", file=sys.stderr)
    raise SystemExit(1)
PY
then
  rm -f "$DOCTOR_JSON"
  exit 1
fi
rm -f "$DOCTOR_JSON"

if [ ! -f "$PLANNER_SETTINGS" ]; then
  echo "[opusminimax] planner identity blocked: missing planner settings after repair: $PLANNER_SETTINGS" >&2
  echo "[opusminimax] repair steps: run claude auth login, ensure Opus is available on the account, unset ANTHROPIC_API_KEY for subscription billing, then retry." >&2
  exit 1
fi

PROMPT="/opusminimax outer_route=$OUTER_ROUTE inner_contract=$INNER_CONTRACT mode=$MODE task=$TASK run_dir=$RUN_DIR planner_model=$PLANNER_MODEL executor_model=$EXECUTOR_MODEL"
claude --model "$PLANNER_MODEL" --effort xhigh --settings "$PLANNER_SETTINGS" -p "$PROMPT"
