#!/bin/bash
# Validate minimal machine-readable harness artifacts and fixture expectations.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/artifact-lint"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/artifact-lint.sh --fixtures
  bash scripts/artifact-lint.sh PATH [PATH...]

Supported artifact_type values:
  agent-native-estimate
  verification-result
  worker-result
  hive-run
  opusminimax-packet
  opusminimax-run
  opusminimax-benchmark-result
EOF
}

if [ "$#" -eq 0 ]; then
  usage
  exit 2
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

python3 - "$ROOT_DIR" "$FIXTURE_DIR" "$@" <<'PY'
import json
import pathlib
import sys
from typing import Any


ROOT = pathlib.Path(sys.argv[1])
FIXTURE_DIR = pathlib.Path(sys.argv[2])
ARGS = sys.argv[3:]


POSITIVE_CLOSEOUT = {"complete", "completed", "verified", "passed", "ready", "shipped", "accepted"}
CONFIDENCE = {"high", "medium", "low"}
AMBIGUOUS = {"", "unknown", "tbd", "todo", "shared", "multiple", "anyone", "all", "*"}


def rel(path: pathlib.Path) -> str:
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def fail(message: str) -> int:
    print(f"[FAIL] {message}", file=sys.stderr)
    return 1


def as_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def present(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value.strip()) and value.strip().lower() not in {"none", "n/a", "null", "missing"}
    if isinstance(value, (list, tuple, set, dict)):
        return bool(value)
    return True


def nonempty_string(value: Any) -> bool:
    return isinstance(value, str) and present(value)


def list_has_entries(value: Any) -> bool:
    return isinstance(value, list) and any(present(item) for item in value)


def error(errors: list[str], message: str) -> None:
    errors.append(message)


def path_owned(owned: str, touched: str) -> bool:
    owned = owned.strip()
    touched = touched.strip()
    if not owned or not touched:
        return False
    if owned.endswith("/**"):
        prefix = owned[:-3]
        return touched == prefix or touched.startswith(prefix + "/")
    if owned == touched:
        return True
    if owned.endswith("/") and touched.startswith(owned):
        return True
    return False


def any_path_owned(owned_files: list[Any], touched: str) -> bool:
    return any(path_owned(str(owned), touched) for owned in owned_files)


def has_command_evidence(commands: Any) -> bool:
    for command in as_list(commands):
        if isinstance(command, str) and command.strip():
            return True
        if isinstance(command, dict) and present(command.get("command")):
            return True
    return False


def criterion_failed(criteria: Any) -> bool:
    for criterion in as_list(criteria):
        if isinstance(criterion, dict):
            status = str(criterion.get("status", "")).strip().lower()
            if status in {"fail", "failed", "red", "error"}:
                return True
        elif isinstance(criterion, str) and any(word in criterion.lower() for word in ["fail", "failed", "error"]):
            return True
    return False


def closeout_positive(value: Any) -> bool:
    text = str(value or "").strip().lower()
    return text in POSITIVE_CLOSEOUT or any(word in text for word in POSITIVE_CLOSEOUT)


def validate_estimate(data: dict[str, Any], errors: list[str]) -> None:
    required = [
        "estimate_type",
        "agent_wall_clock",
        "agent_hours",
        "human_touch_time",
        "calendar_blockers",
        "critical_path",
        "confidence",
        "capacity_evidence",
    ]
    for field in required:
        if not present(data.get(field)):
            error(errors, f"agent-native-estimate missing {field}")

    estimate_type = str(data.get("estimate_type", "")).strip().lower()
    if "agent-native" not in estimate_type:
        error(errors, "estimate_type must be agent-native by default")
    if "human" in estimate_type and not present(data.get("agent_wall_clock")):
        error(errors, "human-equivalent-only estimate is not allowed")

    confidence = str(data.get("confidence", "")).strip().lower()
    if confidence and confidence not in CONFIDENCE:
        error(errors, "confidence must be high, medium, or low")


def validate_verification(data: dict[str, Any], errors: list[str]) -> None:
    metadata = data.get("verification_metadata")
    if not isinstance(metadata, dict):
        error(errors, "verification-result missing verification_metadata")
    else:
        for field in ["executor", "verifier", "isolation_status"]:
            if not present(metadata.get(field)):
                error(errors, f"verification_metadata missing {field}")

    status = str(data.get("status", "")).strip().lower()
    if status not in {"pass", "passed", "fail", "failed", "blocked", "conditional"}:
        error(errors, "verification-result status must be pass, fail, blocked, or conditional")

    commands = data.get("commands_run")
    tests_passed = bool(data.get("tests_passed")) or status in {"pass", "passed"}
    if tests_passed and not has_command_evidence(commands):
        error(errors, "tests_passed requires command evidence")

    if not present(data.get("criteria")):
        error(errors, "verification-result missing criteria")

    failed = status in {"fail", "failed"} or bool(data.get("failed_verification")) or criterion_failed(data.get("criteria"))
    positive = closeout_positive(data.get("closeout_status"))
    transition_ok = bool(data.get("remediated_by_later_pass")) or bool(data.get("operator_override")) or str(data.get("outcome", "")).lower() in {"blocked", "rejected"}
    if failed and positive and not transition_ok:
        error(errors, "failed verification cannot have positive closeout without remediation, blocked outcome, or operator override")


def validate_worker(data: dict[str, Any], errors: list[str]) -> None:
    for field in ["packet_id", "owner", "owned_files", "touched_files", "commands_run", "evidence"]:
        if not present(data.get(field)):
            error(errors, f"worker-result missing {field}")

    owner = str(data.get("owner", "")).strip().lower()
    if owner in AMBIGUOUS or "," in owner:
        error(errors, "worker-result owner is ambiguous")

    owned_files = as_list(data.get("owned_files"))
    touched_files = as_list(data.get("touched_files"))
    if not list_has_entries(owned_files):
        error(errors, "worker-result owned_files must be non-empty")
    if not list_has_entries(touched_files):
        error(errors, "worker-result touched_files must be non-empty")

    for touched in touched_files:
        touched_text = str(touched).strip()
        if touched_text and not any_path_owned(owned_files, touched_text):
            error(errors, f"worker-result touches unowned file: {touched_text}")

    if not has_command_evidence(data.get("commands_run")):
        error(errors, "worker-result missing command evidence")
    if data.get("parent_verified") is not True:
        error(errors, "worker-result must set parent_verified to true")
    for claim in as_list(data.get("claims")):
        if isinstance(claim, dict) and claim.get("verified") is not True:
            error(errors, "worker-result contains unverified worker claim")


def validate_hive_run(data: dict[str, Any], errors: list[str]) -> None:
    role_map = as_list(data.get("role_map"))
    blackboard_claims = as_list(data.get("blackboard_claims"))
    capacity = data.get("capacity") if isinstance(data.get("capacity"), dict) else {}
    dissent_log = as_list(data.get("dissent_log"))
    verification = data.get("verification") if isinstance(data.get("verification"), dict) else {}

    if not role_map:
        error(errors, "hive-run missing role_map")
    if not any(isinstance(role, dict) and str(role.get("role", "")).lower() in {"queen", "supervisor"} for role in role_map):
        error(errors, "hive-run role_map must include queen or supervisor")
    for role in role_map:
        if not isinstance(role, dict):
            error(errors, "hive-run role_map entries must be objects")
            continue
        for field in ["role", "owner", "purpose", "inputs", "output", "stop_condition", "verification"]:
            if not present(role.get(field)):
                error(errors, f"hive-run role missing {field}")

    if not blackboard_claims:
        error(errors, "hive-run missing blackboard_claims")
    for claim in blackboard_claims:
        if not isinstance(claim, dict):
            error(errors, "hive-run blackboard_claims entries must be objects")
            continue
        for field in ["claim_id", "owner", "claim", "evidence", "status", "conflicts", "lock_or_merge_barrier"]:
            if not present(claim.get(field)):
                error(errors, f"hive-run claim missing {field}")
        status = str(claim.get("status", "")).strip().lower()
        if status not in {"candidate", "verified", "rejected", "blocked"}:
            error(errors, "hive-run claim status must be candidate, verified, rejected, or blocked")
        if status == "verified" and not present(claim.get("evidence")):
            error(errors, "hive-run verified claims require evidence")
        if str(claim.get("lock_or_merge_barrier", "")).strip().lower() in AMBIGUOUS:
            error(errors, "hive-run claims require lock_or_merge_barrier")

    if not present(capacity.get("capacity_evidence")):
        error(errors, "hive-run missing capacity.capacity_evidence")
    effective_budget = capacity.get("effective_hive_budget")
    if not isinstance(effective_budget, int) or effective_budget < 1:
        error(errors, "hive-run capacity.effective_hive_budget must be a positive integer")
    ceiling = capacity.get("ceiling")
    if isinstance(ceiling, int) and isinstance(effective_budget, int) and effective_budget > ceiling:
        error(errors, "hive-run effective_hive_budget exceeds capacity ceiling")

    if not dissent_log:
        error(errors, "hive-run missing dissent_log")
    if not present(data.get("synthesis")):
        error(errors, "hive-run missing synthesis")
    if str(data.get("consensus_policy", "")).strip().lower() in {"majority-vote", "vote-only", "consensus-only"}:
        error(errors, "hive-run consensus policy cannot replace evidence")
    if not has_command_evidence(verification.get("commands_run")):
        error(errors, "hive-run verification requires command evidence")
    if verification.get("status") not in {"pass", "passed", "fail", "failed", "blocked"}:
        error(errors, "hive-run verification.status must be pass, fail, or blocked")


def validate_opusminimax_packet(data: dict[str, Any], errors: list[str]) -> None:
    required = [
        "run_id",
        "packet_id",
        "objective",
        "context_summary",
        "owned_paths",
        "forbidden_paths",
        "commands_allowed",
        "acceptance_checks",
        "risk_notes",
        "rollback_plan",
        "expected_outputs",
        "stop_conditions",
    ]
    for field in required:
        if not present(data.get(field)):
            error(errors, f"opusminimax-packet missing {field}")
    for field in ["owned_paths", "forbidden_paths", "commands_allowed", "acceptance_checks", "risk_notes", "expected_outputs", "stop_conditions"]:
        if not list_has_entries(data.get(field)):
            error(errors, f"opusminimax-packet {field} must be a non-empty list")
    forbidden = {str(item).strip() for item in as_list(data.get("forbidden_paths"))}
    for required_forbidden in [".env", ".env.*", ".claude/*.local.json", "secrets/**"]:
        if required_forbidden not in forbidden:
            error(errors, f"opusminimax-packet forbidden_paths missing {required_forbidden}")
    objective_blob = json.dumps(data, sort_keys=True).lower()
    if "sk-" in objective_blob or "minimax_api_key" in objective_blob and "your_minimax_api_key" not in objective_blob:
        error(errors, "opusminimax-packet appears to contain secret material")


def profile_blob(profile: Any) -> str:
    if isinstance(profile, dict):
        return json.dumps(profile, sort_keys=True)
    return str(profile or "")


def profile_value(profile: Any, key: str) -> str:
    if isinstance(profile, dict):
        value = profile.get(key)
        if value is None and isinstance(profile.get("env"), dict):
            value = profile["env"].get(key)
        return str(value or "")
    return ""


def validate_opusminimax_run(data: dict[str, Any], errors: list[str]) -> None:
    for field in [
        "run_id",
        "outer_route",
        "inner_contract",
        "planner_identity_status",
        "executor_identity_status",
        "provider_profiles",
        "model_ids",
        "capacity",
        "packets",
        "verification",
        "retries",
        "final_confidence",
    ]:
        if not present(data.get(field)):
            error(errors, f"opusminimax-run missing {field}")
    if "fallback_status" not in data:
        error(errors, "opusminimax-run missing fallback_status")
    if "failures" not in data or not isinstance(data.get("failures"), list):
        error(errors, "opusminimax-run failures must be a list")

    if data.get("outer_route") not in {"opusworkflow", "opusminimax"}:
        error(errors, "opusminimax-run outer_route is unsupported")
    if data.get("inner_contract") not in {"workflow", "agentfactory", "hiveworkflow", "parallel", "defineicp", "deepretaste", "demo", "visualizeworkflow"}:
        error(errors, "opusminimax-run inner_contract is unsupported")
    if data.get("planner_identity_status") not in {"proven", "diagnosed_fixed", "blocked", "not_required"}:
        error(errors, "opusminimax-run planner_identity_status is unsupported")
    if data.get("executor_identity_status") not in {"configured", "blocked", "not_required"}:
        error(errors, "opusminimax-run executor_identity_status is unsupported")
    if data.get("fallback_status") not in {"none", "explicit_user_override", "blocked"}:
        error(errors, "opusminimax-run fallback_status is unsupported")

    profiles = data.get("provider_profiles") if isinstance(data.get("provider_profiles"), dict) else {}
    planner = profiles.get("planner") if isinstance(profiles, dict) else {}
    executor = profiles.get("executor") if isinstance(profiles, dict) else {}
    planner_blob = profile_blob(planner).lower()
    executor_blob = profile_blob(executor)

    if not planner:
        error(errors, "opusminimax-run missing planner profile")
    if not executor:
        error(errors, "opusminimax-run missing executor profile")
    if "api.minimax.io/anthropic" in planner_blob or "minimax-m2.7-highspeed" in planner_blob:
        error(errors, "opusminimax-run planner profile must not route through MiniMax")
    if "https://api.minimax.io/anthropic" not in executor_blob:
        error(errors, "opusminimax-run executor profile must use MiniMax base URL")
    if "MiniMax-M2.7-highspeed" not in executor_blob:
        error(errors, "opusminimax-run executor profile must request MiniMax-M2.7-highspeed")

    model_ids = data.get("model_ids") if isinstance(data.get("model_ids"), dict) else {}
    planner_model = str(model_ids.get("planner_requested", "")).lower()
    executor_model = str(model_ids.get("executor_requested", ""))
    if planner_model and "opus" not in planner_model:
        error(errors, "opusminimax-run planner_requested must be an Opus model or alias")
    if executor_model != "MiniMax-M2.7-highspeed":
        error(errors, "opusminimax-run executor_requested must be MiniMax-M2.7-highspeed")

    capacity = data.get("capacity") if isinstance(data.get("capacity"), dict) else {}
    effective = capacity.get("effective_concurrency")
    for field in ["local_ceiling", "provider_ceiling", "task_packet_count", "safety_cap", "effective_concurrency"]:
        if not isinstance(capacity.get(field), int) or capacity.get(field) < 1:
            error(errors, f"opusminimax-run capacity.{field} must be a positive integer")
    if isinstance(effective, int):
        for field in ["local_ceiling", "provider_ceiling", "task_packet_count", "safety_cap"]:
            limit = capacity.get(field)
            if isinstance(limit, int) and effective > limit:
                error(errors, f"opusminimax-run effective_concurrency exceeds capacity.{field}")

    if not list_has_entries(data.get("packets")):
        error(errors, "opusminimax-run packets must be non-empty")
    confidence = str(data.get("final_confidence", "")).strip().lower()
    if confidence and confidence not in CONFIDENCE:
        error(errors, "opusminimax-run final_confidence must be high, medium, or low")

    claims = data.get("claims") if isinstance(data.get("claims"), dict) else {}
    if claims.get("opus_planned") is True and data.get("model_identity_confirmed") is not True:
        error(errors, "opusminimax-run cannot claim Opus planned without model_identity_confirmed true")

    verification = data.get("verification") if isinstance(data.get("verification"), dict) else {}
    status = str(verification.get("status", "")).strip().lower()
    if status and status not in {"pass", "passed", "fail", "failed", "blocked", "partial", "runtime-pending"}:
        error(errors, "opusminimax-run verification.status is unsupported")
    failed = status in {"fail", "failed"} or bool(verification.get("failed_verification"))
    positive = closeout_positive(verification.get("closeout_status") or data.get("closeout_status"))
    if failed and positive and not verification.get("remediated_by_later_pass"):
        error(errors, "opusminimax-run failed verification cannot have positive closeout")

    blob = json.dumps(data, sort_keys=True)
    if "sk-" in blob or ("MINIMAX_API_KEY" in blob and "YOUR_MINIMAX_API_KEY" not in blob):
        error(errors, "opusminimax-run appears to contain secret material")


def validate_opusminimax_benchmark_result(data: dict[str, Any], errors: list[str]) -> None:
    required = [
        "benchmark_name",
        "task_id",
        "base_commit",
        "visible_prompt",
        "prediction_patch",
        "tests_run",
        "pass_fail",
        "timeout",
        "logs",
        "gold_hidden_quarantined",
    ]
    for field in required:
        if not present(data.get(field)):
            error(errors, f"opusminimax-benchmark-result missing {field}")
    if data.get("gold_hidden_quarantined") is not True:
        error(errors, "opusminimax-benchmark-result requires gold_hidden_quarantined true")
    if not list_has_entries(data.get("tests_run")):
        error(errors, "opusminimax-benchmark-result tests_run must be non-empty")
    if not list_has_entries(data.get("logs")):
        error(errors, "opusminimax-benchmark-result logs must be non-empty")
    if str(data.get("pass_fail", "")).strip().lower() not in {"pass", "fail", "blocked", "timeout"}:
        error(errors, "opusminimax-benchmark-result pass_fail must be pass, fail, blocked, or timeout")
    timeout = data.get("timeout")
    if not isinstance(timeout, int) or timeout < 1:
        error(errors, "opusminimax-benchmark-result timeout must be a positive integer")
    if data.get("aggregate") is True and not list_has_entries(data.get("per_task_results")):
        error(errors, "opusminimax-benchmark-result aggregate scores require per_task_results")
    if data.get("benchmark_claim_verified") is True and not list_has_entries(data.get("per_task_results")):
        error(errors, "opusminimax-benchmark-result benchmark claims require per-task evidence")
    prompt_blob = str(data.get("visible_prompt", "")).lower()
    if "gold patch" in prompt_blob or "hidden test" in prompt_blob:
        error(errors, "opusminimax-benchmark-result visible_prompt appears to expose quarantined data")


def confidence_level(value: Any) -> Any:
    if isinstance(value, dict):
        return value.get("level")
    return value


def normalize_artifact(data: dict[str, Any]) -> dict[str, Any]:
    artifact_type = str(data.get("artifact_type", "")).strip()

    if artifact_type == "agent_native_estimate" and isinstance(data.get("estimate"), dict):
        estimate = data["estimate"]
        return {
            **data,
            "artifact_type": "agent-native-estimate",
            "estimate_type": estimate.get("estimate_type"),
            "agent_wall_clock": estimate.get("agent_wall_clock"),
            "agent_hours": estimate.get("agent_hours"),
            "human_touch_time": estimate.get("human_touch_time"),
            "calendar_blockers": estimate.get("calendar_blockers"),
            "critical_path": estimate.get("critical_path"),
            "confidence": confidence_level(estimate.get("confidence")),
            "capacity_evidence": estimate.get("capacity_evidence"),
        }

    if artifact_type == "verification_result" and isinstance(data.get("verification"), dict):
        verification = data["verification"]
        closeout = verification.get("closeout")
        closeout_status = closeout.get("status") if isinstance(closeout, dict) else verification.get("closeout_status")
        return {
            **data,
            "artifact_type": "verification-result",
            "verification_metadata": verification.get("metadata") or verification.get("verification_metadata"),
            "status": verification.get("status"),
            "criteria": verification.get("criteria"),
            "commands_run": verification.get("commands") or verification.get("commands_run"),
            "tests_passed": verification.get("tests_passed"),
            "closeout_status": closeout_status,
            "failed_verification": verification.get("failed_verification"),
            "remediated_by_later_pass": verification.get("remediated_by_later_pass"),
            "operator_override": verification.get("operator_override"),
            "outcome": verification.get("outcome"),
        }

    if artifact_type == "worker_result" and isinstance(data.get("worker_result"), dict):
        worker_result = data["worker_result"]
        worker = worker_result.get("worker") if isinstance(worker_result.get("worker"), dict) else {}
        packet = worker_result.get("packet") if isinstance(worker_result.get("packet"), dict) else {}
        parent = worker_result.get("parent_verification") if isinstance(worker_result.get("parent_verification"), dict) else {}
        return {
            **data,
            "artifact_type": "worker-result",
            "packet_id": packet.get("id") or worker_result.get("packet_id"),
            "owner": worker.get("id") or worker_result.get("owner"),
            "owned_files": packet.get("owned_paths") or worker.get("ownership") or worker_result.get("owned_files"),
            "touched_files": packet.get("touched_paths") or worker_result.get("touched_files"),
            "commands_run": worker_result.get("commands") or worker_result.get("commands_run"),
            "evidence": worker_result.get("claims") or parent.get("evidence") or worker_result.get("evidence"),
            "claims": worker_result.get("claims"),
            "parent_verified": parent.get("verified") if "verified" in parent else worker_result.get("parent_verified"),
        }

    if artifact_type == "hive_run" and isinstance(data.get("hive_run"), dict):
        hive_run = data["hive_run"]
        return {
            **data,
            "artifact_type": "hive-run",
            "role_map": hive_run.get("role_map"),
            "blackboard_claims": hive_run.get("blackboard_claims"),
            "capacity": hive_run.get("capacity"),
            "dissent_log": hive_run.get("dissent_log"),
            "synthesis": hive_run.get("synthesis"),
            "consensus_policy": hive_run.get("consensus_policy"),
            "verification": hive_run.get("verification"),
        }

    return data


def validate_artifact(path: pathlib.Path) -> list[str]:
    errors: list[str] = []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return [f"invalid JSON: {exc}"]

    if not isinstance(data, dict):
        return ["artifact must be a JSON object"]

    data = normalize_artifact(data)
    artifact_type = str(data.get("artifact_type", "")).strip()
    if artifact_type == "agent-native-estimate":
        validate_estimate(data, errors)
    elif artifact_type == "verification-result":
        validate_verification(data, errors)
    elif artifact_type == "worker-result":
        validate_worker(data, errors)
    elif artifact_type == "hive-run":
        validate_hive_run(data, errors)
    elif artifact_type == "opusminimax-packet":
        validate_opusminimax_packet(data, errors)
    elif artifact_type == "opusminimax-run":
        validate_opusminimax_run(data, errors)
    elif artifact_type == "opusminimax-benchmark-result":
        validate_opusminimax_benchmark_result(data, errors)
    else:
        error(errors, "artifact_type must be agent-native-estimate, verification-result, worker-result, hive-run, opusminimax-packet, opusminimax-run, or opusminimax-benchmark-result")

    return errors


def expected_for_fixture(path: pathlib.Path) -> str:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        expected = str(data.get("expected_result", "")).strip().lower()
        if expected in {"pass", "accepted", "accept"}:
            return "pass"
        if expected in {"fail", "reject", "rejected"}:
            return "fail"
    except Exception:
        pass
    parts = {part.lower() for part in path.parts}
    if "green" in parts:
        return "pass"
    if "red" in parts:
        return "fail"
    return "pass"


def fixture_paths() -> list[pathlib.Path]:
    if not FIXTURE_DIR.is_dir():
        raise FileNotFoundError(f"missing fixture dir: {rel(FIXTURE_DIR)}")
    return sorted(FIXTURE_DIR.rglob("*.json"))


def run_fixtures() -> int:
    try:
        paths = fixture_paths()
    except FileNotFoundError as exc:
        return fail(str(exc))

    if not paths:
        return fail(f"no artifact-lint fixtures found under {rel(FIXTURE_DIR)}")

    failures = 0
    red_rejected = 0
    green_passed = 0
    for path in paths:
        expected = expected_for_fixture(path)
        errors = validate_artifact(path)
        actual = "fail" if errors else "pass"
        if expected == actual:
            if expected == "pass":
                green_passed += 1
            else:
                red_rejected += 1
            continue
        failures += 1
        print(
            f"[artifact-lint] {rel(path)} expected {expected} but got {actual}: "
            + ("; ".join(errors) if errors else "no validation errors"),
            file=sys.stderr,
        )

    if red_rejected < 12:
        failures += 1
        print(f"[artifact-lint] expected at least 12 red fixture rejections, got {red_rejected}", file=sys.stderr)
    if green_passed < 4:
        failures += 1
        print(f"[artifact-lint] expected at least 4 green fixture passes, got {green_passed}", file=sys.stderr)

    if failures:
        return 1

    print(f"[PASS] artifact lint fixtures passed ({green_passed} green, {red_rejected} red)")
    return 0


def run_paths(paths: list[str]) -> int:
    failures = 0
    for raw in paths:
        path = pathlib.Path(raw)
        errors = validate_artifact(path)
        if errors:
            failures += 1
            print(f"[artifact-lint] {rel(path)}: {'; '.join(errors)}", file=sys.stderr)
    if failures:
        return 1
    print("[PASS] artifact lint passed")
    return 0


if ARGS == ["--fixtures"]:
    raise SystemExit(run_fixtures())
if ARGS and ARGS[0] == "--fixtures":
    print("[FAIL] --fixtures does not accept extra arguments", file=sys.stderr)
    raise SystemExit(2)
raise SystemExit(run_paths(ARGS))
PY
