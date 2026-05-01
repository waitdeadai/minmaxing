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
    else:
        error(errors, "artifact_type must be agent-native-estimate, verification-result, or worker-result")

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

    if red_rejected < 9:
        failures += 1
        print(f"[artifact-lint] expected at least 9 red fixture rejections, got {red_rejected}", file=sys.stderr)
    if green_passed < 3:
        failures += 1
        print(f"[artifact-lint] expected at least 3 green fixture passes, got {green_passed}", file=sys.stderr)

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
