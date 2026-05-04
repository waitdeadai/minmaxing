#!/bin/bash
# Aggregate and validate run-level /hive artifacts.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/hive-aggregate"
FORMAT="text"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/hive-aggregate.sh --fixtures
  bash scripts/hive-aggregate.sh [--json] RUN_DIR

RUN_DIR layout:
  hive-run.json
  optional: parallel-run-dir.txt
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

if [ "${1:-}" = "--json" ]; then
  FORMAT="json"
  shift
fi

python3 - "$ROOT_DIR" "$FIXTURE_DIR" "$FORMAT" "$@" <<'PY'
import json
import pathlib
import subprocess
import sys
from typing import Any


ROOT = pathlib.Path(sys.argv[1]).resolve()
FIXTURE_DIR = pathlib.Path(sys.argv[2]).resolve()
FORMAT = sys.argv[3]
ARGS = sys.argv[4:]


def rel(path: pathlib.Path) -> str:
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


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
        return bool(value.strip()) and value.strip().lower() not in {"none", "n/a", "null", "missing", "todo", "tbd"}
    if isinstance(value, (list, tuple, set, dict)):
        return bool(value)
    return True


def load_json(path: pathlib.Path, errors: list[str]) -> dict[str, Any]:
    if not path.is_file():
        errors.append(f"missing {rel(path)}")
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{rel(path)} invalid JSON: {exc}")
        return {}
    if not isinstance(data, dict):
        errors.append(f"{rel(path)} must be a JSON object")
        return {}
    return data


def normalize_hive(data: dict[str, Any]) -> dict[str, Any]:
    if data.get("artifact_type") == "hive_run" and isinstance(data.get("hive_run"), dict):
        hive = data["hive_run"]
        return {
            **data,
            "artifact_type": "hive-run",
            "role_map": hive.get("role_map"),
            "blackboard_claims": hive.get("blackboard_claims"),
            "capacity": hive.get("capacity"),
            "dissent_log": hive.get("dissent_log"),
            "synthesis": hive.get("synthesis"),
            "consensus_policy": hive.get("consensus_policy"),
            "verification": hive.get("verification"),
        }
    return data


def validate_hive_run(data: dict[str, Any], errors: list[str]) -> dict[str, Any]:
    data = normalize_hive(data)
    role_map = [item for item in as_list(data.get("role_map")) if isinstance(item, dict)]
    claims = [item for item in as_list(data.get("blackboard_claims")) if isinstance(item, dict)]
    capacity = data.get("capacity") if isinstance(data.get("capacity"), dict) else {}
    verification = data.get("verification") if isinstance(data.get("verification"), dict) else {}

    if data.get("artifact_type") != "hive-run":
        errors.append("hive-run.json artifact_type must be hive-run")
    if not any(str(role.get("role", "")).lower() in {"queen", "supervisor"} for role in role_map):
        errors.append("hive run must include queen or supervisor role")
    if not role_map:
        errors.append("hive run must include role_map")
    if not claims:
        errors.append("hive run must include blackboard_claims")
    if not as_list(data.get("dissent_log")):
        errors.append("hive run must include dissent_log")
    if not present(data.get("synthesis")):
        errors.append("hive run must include synthesis")

    statuses: dict[str, int] = {}
    for claim in claims:
        status = str(claim.get("status", "")).strip().lower()
        statuses[status] = statuses.get(status, 0) + 1
        if status == "verified" and not present(claim.get("evidence")):
            errors.append(f"verified claim {claim.get('claim_id', 'unknown')} lacks evidence")
        if not present(claim.get("lock_or_merge_barrier")):
            errors.append(f"claim {claim.get('claim_id', 'unknown')} lacks lock_or_merge_barrier")

    effective_budget = capacity.get("effective_hive_budget")
    ceiling = capacity.get("ceiling")
    if not isinstance(effective_budget, int) or effective_budget < 1:
        errors.append("effective_hive_budget must be a positive integer")
    if isinstance(ceiling, int) and isinstance(effective_budget, int) and effective_budget > ceiling:
        errors.append("effective_hive_budget exceeds ceiling")
    if not present(capacity.get("capacity_evidence")):
        errors.append("capacity_evidence is required")
    if str(data.get("consensus_policy", "")).lower() in {"majority-vote", "vote-only", "consensus-only"}:
        errors.append("consensus policy cannot replace evidence")

    commands = verification.get("commands_run")
    if not any((isinstance(command, str) and command.strip()) or (isinstance(command, dict) and present(command.get("command"))) for command in as_list(commands)):
        errors.append("verification requires command evidence")
    if str(verification.get("status", "")).lower() not in {"pass", "passed", "fail", "failed", "blocked"}:
        errors.append("verification.status must be pass, fail, or blocked")

    return {
        "roles": len(role_map),
        "claims": len(claims),
        "verified_claims": statuses.get("verified", 0),
        "candidate_claims": statuses.get("candidate", 0),
        "blocked_claims": statuses.get("blocked", 0),
        "effective_hive_budget": effective_budget if isinstance(effective_budget, int) else 0,
        "ceiling": ceiling if isinstance(ceiling, int) else 0,
    }


def run_artifact_lint(path: pathlib.Path, errors: list[str]) -> None:
    script = ROOT / "scripts" / "artifact-lint.sh"
    result = subprocess.run(["bash", str(script), str(path)], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        errors.append(f"artifact-lint failed for {rel(path)}: {detail}")


def run_parallel_aggregate(run_dir: pathlib.Path, errors: list[str]) -> str:
    pointer = run_dir / "parallel-run-dir.txt"
    if not pointer.is_file():
        return "not_applicable"
    target_text = pointer.read_text(encoding="utf-8").strip()
    if not target_text:
        errors.append("parallel-run-dir.txt is empty")
        return "fail"
    target = (run_dir / target_text).resolve() if not pathlib.Path(target_text).is_absolute() else pathlib.Path(target_text)
    script = ROOT / "scripts" / "parallel-aggregate.sh"
    result = subprocess.run(["bash", str(script), str(target)], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        errors.append(f"parallel aggregate failed for {rel(target)}: {detail}")
        return "fail"
    return "pass"


def validate_run(run_dir: pathlib.Path) -> dict[str, Any]:
    errors: list[str] = []
    if not run_dir.is_dir():
        errors.append(f"missing run dir: {rel(run_dir)}")
        return {"status": "fail", "errors": errors}

    hive_path = run_dir / "hive-run.json"
    data = load_json(hive_path, errors)
    summary = validate_hive_run(data, errors) if data else {}
    if data:
        run_artifact_lint(hive_path, errors)
    parallel_status = run_parallel_aggregate(run_dir, errors)

    return {
        "status": "fail" if errors else "pass",
        "run_dir": rel(run_dir),
        "errors": errors,
        "parallel_aggregate": parallel_status,
        **summary,
    }


def fixture_expected(path: pathlib.Path) -> str:
    expected = path / "expected.json"
    if expected.is_file():
        try:
            data = json.loads(expected.read_text(encoding="utf-8"))
            result = str(data.get("result", "")).lower()
            if result in {"pass", "fail"}:
                return result
        except Exception:
            pass
    return "fail" if path.name.startswith("red-") else "pass"


def run_fixtures() -> int:
    runs = sorted(path for path in FIXTURE_DIR.iterdir() if path.is_dir())
    failures = 0
    green = 0
    red = 0
    for run_dir in runs:
        expected = fixture_expected(run_dir)
        result = validate_run(run_dir)
        actual = result["status"]
        if actual == expected:
            if expected == "pass":
                green += 1
            else:
                red += 1
            continue
        failures += 1
        print(f"[hive-aggregate] {rel(run_dir)} expected={expected} actual={actual} errors={'; '.join(result['errors'])}", file=sys.stderr)
    if green < 1:
        failures += 1
        print(f"[hive-aggregate] expected at least 1 green fixture, got {green}", file=sys.stderr)
    if red < 3:
        failures += 1
        print(f"[hive-aggregate] expected at least 3 red fixtures, got {red}", file=sys.stderr)
    if failures:
        return 1
    print(f"[PASS] hive aggregate fixtures passed ({green} green, {red} red)")
    return 0


def emit(result: dict[str, Any]) -> int:
    if FORMAT == "json":
        print(json.dumps(result, sort_keys=True))
    elif result["status"] == "pass":
        print(
            "[PASS] hive aggregate passed "
            f"(roles={result.get('roles', 0)}, claims={result.get('claims', 0)}, "
            f"verified={result.get('verified_claims', 0)}, parallel={result.get('parallel_aggregate')})"
        )
    else:
        print(f"[FAIL] hive aggregate failed: {'; '.join(result['errors'])}", file=sys.stderr)
    return 0 if result["status"] == "pass" else 1


if ARGS == ["--fixtures"]:
    raise SystemExit(run_fixtures())
if not ARGS:
    raise SystemExit(2)
if len(ARGS) != 1:
    print("[FAIL] expected one RUN_DIR", file=sys.stderr)
    raise SystemExit(2)
raise SystemExit(emit(validate_run(pathlib.Path(ARGS[0]))))
PY
