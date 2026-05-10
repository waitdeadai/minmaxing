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
PLANNER_MODEL="${OPUSMINIMAX_PLANNER_MODEL:-}"
EXECUTOR_PROVIDER="${OPUSMINIMAX_EXECUTOR_PROVIDER:-minimax}"
EXECUTOR_MODEL="${OPUSMINIMAX_EXECUTOR_MODEL:-}"
MODEL_PROFILE="${OPUSMINIMAX_MODEL_PROFILE:-}"
PLAN_MODE_POLICY="${OPUSMINIMAX_PLAN_MODE_POLICY:-}"
PLANNER_MODEL_SET=0
EXECUTOR_MODEL_SET=0
EXECUTOR_PROVIDER_SET=0
PLAN_MODE_POLICY_SET=0

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/opusminimax.sh --task "..." [--mode workflow|benchmark|repair] [--outer-route ROUTE] [--inner-contract CONTRACT] [--model-profile minimax|opussonnet|sonnet|opus|default|custom] [--executor-provider minimax|claude-sonnet|anthropic] [--plan-mode-policy auto|manual|off] [--execute-planner] [--planner-settings PATH]

Default behavior prepares no-secret run artifacts and prints the next command.
--execute-planner is the explicit Claude runtime opt-in.

Model profiles are governed routing presets, not runtime identity proof:
  minimax     Opus judgment + MiniMax execution (default)
  opussonnet  Opus judgment + Sonnet execution, no MiniMax token
  sonnet      Sonnet planning + Sonnet execution
  opus        Opus planning + Opus execution
  default     Claude Code account default planning + execution
  custom      Explicit --planner-model and --executor-model values

CONTRACT may be workflow, agentfactory, hiveworkflow, parallel, defineicp,
digestaste, deepretaste, demo, or visualizeworkflow.
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
      PLANNER_MODEL_SET=1
      shift 2
      ;;
    "--executor-model")
      EXECUTOR_MODEL="${2:-}"
      EXECUTOR_MODEL_SET=1
      shift 2
      ;;
    "--executor-provider")
      EXECUTOR_PROVIDER="${2:-}"
      EXECUTOR_PROVIDER_SET=1
      shift 2
      ;;
    "--model-profile")
      MODEL_PROFILE="${2:-}"
      shift 2
      ;;
    "--plan-mode-policy")
      PLAN_MODE_POLICY="${2:-}"
      PLAN_MODE_POLICY_SET=1
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
  workflow|agentfactory|hiveworkflow|parallel|defineicp|digestaste|deepretaste|demo|visualizeworkflow) ;;
  *) echo "[opusminimax] invalid inner contract: $INNER_CONTRACT" >&2; exit 2 ;;
esac

if [ -z "$PLAN_MODE_POLICY" ]; then
  if [ "$OUTER_ROUTE" = "opusworkflow" ]; then
    PLAN_MODE_POLICY="${OPUSWORKFLOW_PLAN_MODE_POLICY:-auto}"
  else
    PLAN_MODE_POLICY="off"
  fi
fi
case "$PLAN_MODE_POLICY" in
  auto|manual|off) ;;
  *) echo "[opusminimax] invalid plan mode policy: $PLAN_MODE_POLICY" >&2; exit 2 ;;
esac

if [ -z "$MODEL_PROFILE" ]; then
  case "$EXECUTOR_PROVIDER" in
    minimax) MODEL_PROFILE="minimax" ;;
    claude-sonnet) MODEL_PROFILE="opussonnet" ;;
    anthropic) MODEL_PROFILE="custom" ;;
    *) MODEL_PROFILE="minimax" ;;
  esac
fi

case "$MODEL_PROFILE" in
  minimax|opussonnet|sonnet|opus|default|custom) ;;
  *) echo "[opusminimax] invalid model profile: $MODEL_PROFILE" >&2; exit 2 ;;
esac

if [ "$EXECUTOR_PROVIDER_SET" -eq 0 ]; then
  case "$MODEL_PROFILE" in
    minimax) EXECUTOR_PROVIDER="minimax" ;;
    opussonnet) EXECUTOR_PROVIDER="claude-sonnet" ;;
    sonnet|opus|default|custom) EXECUTOR_PROVIDER="anthropic" ;;
  esac
fi

case "$EXECUTOR_PROVIDER" in
  minimax|claude-sonnet|anthropic) ;;
  *) echo "[opusminimax] invalid executor provider: $EXECUTOR_PROVIDER" >&2; exit 2 ;;
esac

case "$MODEL_PROFILE:$EXECUTOR_PROVIDER" in
  minimax:minimax|opussonnet:claude-sonnet|sonnet:anthropic|opus:anthropic|default:anthropic|custom:anthropic) ;;
  *)
    echo "[opusminimax] model profile '$MODEL_PROFILE' conflicts with executor provider '$EXECUTOR_PROVIDER'" >&2
    exit 2
    ;;
esac

case "$MODEL_PROFILE" in
  minimax)
    [ -n "$PLANNER_MODEL" ] || PLANNER_MODEL="claude-opus-4-7"
    [ -n "$EXECUTOR_MODEL" ] || EXECUTOR_MODEL="MiniMax-M2.7-highspeed"
    ;;
  opussonnet)
    [ -n "$PLANNER_MODEL" ] || PLANNER_MODEL="claude-opus-4-7"
    [ -n "$EXECUTOR_MODEL" ] || EXECUTOR_MODEL="claude-sonnet-4-6"
    ;;
  sonnet)
    [ -n "$PLANNER_MODEL" ] || PLANNER_MODEL="claude-sonnet-4-6"
    [ -n "$EXECUTOR_MODEL" ] || EXECUTOR_MODEL="claude-sonnet-4-6"
    ;;
  opus)
    [ -n "$PLANNER_MODEL" ] || PLANNER_MODEL="claude-opus-4-7"
    [ -n "$EXECUTOR_MODEL" ] || EXECUTOR_MODEL="claude-opus-4-7"
    ;;
  default)
    [ -n "$PLANNER_MODEL" ] || PLANNER_MODEL="default"
    [ -n "$EXECUTOR_MODEL" ] || EXECUTOR_MODEL="default"
    ;;
  custom)
    if [ -z "$PLANNER_MODEL" ] || [ -z "$EXECUTOR_MODEL" ]; then
      echo "[opusminimax] --model-profile custom requires --planner-model and --executor-model or OPUSMINIMAX_* model env vars" >&2
      exit 2
    fi
    ;;
esac

if [ "$EXECUTOR_PROVIDER" = "minimax" ] && [ "$EXECUTOR_MODEL" != "MiniMax-M2.7-highspeed" ]; then
  echo "[opusminimax] minimax profile requires executor model MiniMax-M2.7-highspeed" >&2
  exit 2
fi
if [ "$EXECUTOR_PROVIDER" != "minimax" ] && [[ "${EXECUTOR_MODEL,,}" == *"minimax"* ]]; then
  echo "[opusminimax] Anthropic model profiles must not request MiniMax executor models" >&2
  exit 2
fi

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

python3 - "$TASK" "$MODE" "$OUTER_ROUTE" "$INNER_CONTRACT" "$RUN_ID" "$PACKET" "$RUN_ARTIFACT" "$PLANNER_MODEL" "$EXECUTOR_MODEL" "$EXECUTOR_PROVIDER" "$MODEL_PROFILE" "$PLAN_MODE_POLICY" <<'PY'
import json
import pathlib
import sys

task, mode, outer_route, inner_contract, run_id, packet_path, run_artifact, planner_model, executor_model, executor_provider, model_profile, plan_mode_policy = sys.argv[1:13]
packet_path = pathlib.Path(packet_path)
run_artifact = pathlib.Path(run_artifact)
if executor_provider == "claude-sonnet":
    executor_profile = {
        "path": ".claude/settings.sonnet-executor.example.json",
        "anthropic_base_url": "",
        "model": executor_model,
        "provider": "claude-sonnet",
    }
    executor_label = "Claude Sonnet executor"
elif executor_provider == "anthropic":
    executor_profile = {
        "path": ".claude/settings.opusminimax-planner.example.json",
        "anthropic_base_url": "",
        "model": executor_model,
        "provider": "anthropic",
    }
    executor_label = "Claude/Anthropic executor"
else:
    executor_profile = {
        "path": ".claude/settings.minimax-executor.example.json",
        "anthropic_base_url": "https://api.minimax.io/anthropic",
        "model": executor_model,
        "provider": "minimax",
    }
    executor_label = "MiniMax executor"

packet = {
    "artifact_type": "opusminimax-packet",
    "run_id": run_id,
    "packet_id": "P1",
    "objective": f"Prepare implementation packet for: {task}",
    "context_summary": f"Outer route={outer_route}. Inner contract={inner_contract}. Mode={mode}. Claude planner must refine this packet before {executor_label} execution.",
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
    "outcome_policy": "verified-partial-or-blocked-with-repair" if outer_route == "opusworkflow" else "advanced-engine-artifact",
    "workflow_contract": {
        "definitive_command": outer_route == "opusworkflow",
        "route_role": "definitive_outer_route" if outer_route == "opusworkflow" else "advanced_engine",
        "effectiveness_policy": "continue_until_verified_partial_or_blocked",
        "default_model_split": "claude-opus-4-7 high/xhigh planner-reviewer + MiniMax-M2.7-highspeed executor when model_profile=minimax",
        "allowed_closeout_statuses": ["verified", "partial", "blocked", "runtime-pending"],
        "blocked_requires_repair": True,
    },
    "model_profile": model_profile,
    "executor_provider": executor_provider,
    "planner_identity_status": "blocked",
    "executor_identity_status": "configured",
    "fallback_status": "none" if outer_route == "opusworkflow" and model_profile == "minimax" else "explicit_user_override",
    "provider_profiles": {
        "planner": {
            "path": ".claude/settings.opusminimax-planner.example.json",
            "anthropic_base_url": "",
            "model": planner_model,
        },
        "executor": executor_profile,
    },
    "model_ids": {
        "planner_requested": planner_model,
        "executor_requested": executor_model,
    },
    "model_route": {
        "profile": model_profile,
        "planner": {
            "provider": "anthropic",
            "requested_model": planner_model,
            "identity_status": "blocked",
        },
        "executor": {
            "provider": executor_profile["provider"],
            "requested_model": executor_model,
            "identity_status": "configured",
        },
        "fallback_policy": "fail-closed-unless-explicit",
    },
    "spec_qa": {
        "required": outer_route == "opusworkflow",
        "runs_after_spec_creation": True,
        "before_implementation": True,
        "requested_reviewer": "claude-opus-4-7",
        "identity_status": "blocked",
        "claims_opus_review": False,
        "source_ledger_required_for_sota": True,
        "artifact_paths": {
            "markdown": f".taste/specqa/{run_id}/spec-qa.md",
            "json": f".taste/specqa/{run_id}/spec-qa.json",
        },
    },
    "plan_mode": {
        "enabled": outer_route == "opusworkflow" and plan_mode_policy != "off",
        "policy": plan_mode_policy,
        "checkpoint": "pre-implementation-plan-approval",
        "native_permission_mode": "plan",
        "native_permission_mode_status": "runtime-dependent",
        "approval_scope": "workflow-transition-only",
        "auto_approval": {
            "default": plan_mode_policy == "auto",
            "status": (
                "auto_approved_when_gates_pass"
                if plan_mode_policy == "auto"
                else "manual_required"
                if plan_mode_policy == "manual"
                else "disabled"
            ),
            "execution_allowed_after": [
                "research_brief_recorded",
                "code_audit_recorded",
                "pre_plan_introspection_pass",
                "agent_native_estimate_recorded",
                "spec_created_updated_or_reused",
                "specqa_execution_allowed",
            ],
            "blocks": [
                "missing_research_brief",
                "missing_code_audit",
                "pre_plan_introspection_not_pass",
                "missing_agent_native_estimate",
                "missing_spec",
                "specqa_fix_required_or_blocked",
                "operator_boundary_requires_review",
                "secret_or_protected_path_risk",
            ],
        },
        "does_not_replace": [
            "SPEC.md",
            "/specqa",
            "/introspect",
            "/verify",
            "runtime_model_identity_proof",
            "visualizeworkflow_human_approval",
        ],
        "human_approval_required_when": [
            "policy_manual",
            "visualizeworkflow_waiting_for_visual_approval",
            "critical_specqa_findings",
            "operator_boundary_requires_review",
            "unsafe_external_infrastructure_action",
        ],
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
        "spec_qa_opus_reviewed": False,
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
  echo "  bash scripts/opusminimax.sh --task \"$TASK\" --mode $MODE --outer-route $OUTER_ROUTE --inner-contract $INNER_CONTRACT --model-profile $MODEL_PROFILE --executor-provider $EXECUTOR_PROVIDER --planner-model $PLANNER_MODEL --executor-model $EXECUTOR_MODEL --plan-mode-policy $PLAN_MODE_POLICY --execute-planner"
  exit 0
fi

if [ ! -f "$PLANNER_SETTINGS" ]; then
  echo "[opusminimax] missing planner settings; attempting safe local profile repair" >&2
fi

DOCTOR_JSON="$(mktemp)"
if ! bash "$ROOT_DIR/scripts/opusminimax-doctor.sh" --runtime --fix-local-profiles --model-profile "$MODEL_PROFILE" --executor-provider "$EXECUTOR_PROVIDER" --json >"$DOCTOR_JSON"; then
  echo "[opusminimax] planner identity blocked: runtime doctor failed." >&2
  echo "[opusminimax] repair steps: run claude auth login, ensure Opus is available on the account, unset ANTHROPIC_API_KEY for subscription billing, then retry." >&2
  rm -f "$DOCTOR_JSON"
  exit 1
fi

if ! python3 - "$DOCTOR_JSON" "$EXECUTOR_PROVIDER" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
executor_provider = sys.argv[2]
payload = json.loads(path.read_text(encoding="utf-8"))
provider_required = {
    "minimax": {
        "executor local profile exists",
        "executor local profile uses MiniMax-M2.7-highspeed",
        "executor local profile does not alias Opus to MiniMax",
    },
    "claude-sonnet": {
        "sonnet executor local profile exists",
        "sonnet executor local profile has no MiniMax base URL",
        "sonnet executor local profile requests Sonnet 4.6",
    },
}.get(executor_provider, set())
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
        "planner local profile has no MiniMax base URL",
    }.union(provider_required) and status != "pass":
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

PROMPT="/opusminimax outer_route=$OUTER_ROUTE inner_contract=$INNER_CONTRACT mode=$MODE task=$TASK run_dir=$RUN_DIR model_profile=$MODEL_PROFILE planner_model=$PLANNER_MODEL executor_provider=$EXECUTOR_PROVIDER executor_model=$EXECUTOR_MODEL plan_mode_policy=$PLAN_MODE_POLICY"
CLAUDE_ARGS=()
if [ "$PLANNER_MODEL" != "default" ]; then
  CLAUDE_ARGS+=(--model "$PLANNER_MODEL")
fi
claude "${CLAUDE_ARGS[@]}" --effort xhigh --settings "$PLANNER_SETTINGS" -p "$PROMPT"
