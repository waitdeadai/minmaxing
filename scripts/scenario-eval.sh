#!/bin/bash
# Run local no-secret scenario evals from JSON argv fixtures.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="text"
USE_FIXTURES=0
PATHS=()

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/scenario-eval.sh [--json] [--fixtures] [PATH...]

Runs local scenario JSON files. Each scenario must provide:
  id, argv, expected_exit_code, stdout_contains/stdout_not_contains,
  stderr_contains/stderr_not_contains, and risk_tags.

Fixtures live in evals/scenarios and are local, no-network, no-secret gates.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--json")
      MODE="json"
      shift
      ;;
    "--fixtures")
      USE_FIXTURES=1
      shift
      ;;
    "-h"|"--help")
      usage
      exit 0
      ;;
    --*)
      usage
      exit 2
      ;;
    *)
      PATHS+=("$1")
      shift
      ;;
  esac
done

python3 - "$ROOT_DIR" "$MODE" "$USE_FIXTURES" "${PATHS[@]}" <<'PY'
import json
import os
import pathlib
import re
import subprocess
import sys
import time
from typing import Any


ROOT = pathlib.Path(sys.argv[1]).resolve()
MODE = sys.argv[2]
USE_FIXTURES = sys.argv[3] == "1"
INPUT_PATHS = [pathlib.Path(arg) for arg in sys.argv[4:]]
SCENARIO_DIR = ROOT / "evals" / "scenarios"
ID_RE = re.compile(r"^[a-z0-9][a-z0-9_.-]*$")
NETWORK_COMMANDS = {
    "curl",
    "wget",
    "nc",
    "netcat",
    "ncat",
    "ssh",
    "scp",
    "sftp",
    "rsync",
    "telnet",
    "gh",
    "git",
}
URL_RE = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*://")


class ScenarioError(Exception):
    pass


def rel(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def as_string_list(value: Any, field: str) -> list[str]:
    if value is None:
        return []
    if isinstance(value, str):
        return [value]
    if isinstance(value, list) and all(isinstance(item, str) for item in value):
        return value
    raise ScenarioError(f"{field} must be a string or list of strings")


def is_relative_to(path: pathlib.Path, parent: pathlib.Path) -> bool:
    try:
        path.resolve().relative_to(parent.resolve())
    except ValueError:
        return False
    return True


def safe_env() -> dict[str, str]:
    env: dict[str, str] = {
        "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        "HOME": os.environ.get("HOME", str(ROOT)),
        "LANG": os.environ.get("LANG", "C.UTF-8"),
        "LC_ALL": os.environ.get("LC_ALL", "C.UTF-8"),
        "SCENARIO_EVAL": "1",
    }
    if "TMPDIR" in os.environ:
        env["TMPDIR"] = os.environ["TMPDIR"]
    return env


def collect_paths() -> list[pathlib.Path]:
    requested: list[pathlib.Path] = []
    if USE_FIXTURES:
        requested.append(SCENARIO_DIR)
    requested.extend(INPUT_PATHS)
    if not requested:
        requested.append(SCENARIO_DIR)

    files: list[pathlib.Path] = []
    for raw in requested:
        path = raw if raw.is_absolute() else ROOT / raw
        if path.is_dir():
            files.extend(sorted(candidate for candidate in path.glob("*.json") if candidate.is_file()))
        elif path.is_file():
            files.append(path)
        else:
            raise ScenarioError(f"missing scenario path: {rel(path)}")

    unique: list[pathlib.Path] = []
    seen: set[pathlib.Path] = set()
    for path in files:
        resolved = path.resolve()
        if resolved not in seen:
            seen.add(resolved)
            unique.append(path)
    if not unique:
        raise ScenarioError("no scenario JSON files found")
    return unique


def nested_expectations(data: dict[str, Any], stream: str, key: str) -> list[str]:
    nested = data.get(stream)
    if isinstance(nested, dict) and key in nested:
        return as_string_list(nested.get(key), f"{stream}.{key}")
    return []


def load_scenario(path: pathlib.Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise ScenarioError(f"{rel(path)}: invalid JSON: {exc}") from exc
    if not isinstance(data, dict):
        raise ScenarioError(f"{rel(path)}: scenario JSON must be an object")

    scenario_id = str(data.get("id", "")).strip()
    if not scenario_id or not ID_RE.match(scenario_id):
        raise ScenarioError(f"{rel(path)}: id must match {ID_RE.pattern}")

    argv = data.get("argv", data.get("command"))
    if not isinstance(argv, list) or not argv or not all(isinstance(arg, str) and arg for arg in argv):
        raise ScenarioError(f"{rel(path)}: argv must be a non-empty list of strings")

    expected_exit_code = data.get("expected_exit_code", data.get("expected_exit"))
    if not isinstance(expected_exit_code, int) or not 0 <= expected_exit_code <= 255:
        raise ScenarioError(f"{rel(path)}: expected_exit_code must be an integer from 0 to 255")

    risk_tags = as_string_list(data.get("risk_tags"), "risk_tags")
    normalized_tags = {tag.strip().lower() for tag in risk_tags}
    if not risk_tags:
        raise ScenarioError(f"{rel(path)}: risk_tags must be non-empty")
    for required_tag in ("no-network", "no-secret"):
        if required_tag not in normalized_tags:
            raise ScenarioError(f"{rel(path)}: risk_tags must include {required_tag}")

    timeout_s = data.get("timeout_s", 60)
    if not isinstance(timeout_s, int) or not 1 <= timeout_s <= 300:
        raise ScenarioError(f"{rel(path)}: timeout_s must be an integer from 1 to 300")

    scenario = {
        "id": scenario_id,
        "path": rel(path),
        "argv": argv,
        "expected_exit_code": expected_exit_code,
        "stdout_contains": as_string_list(data.get("stdout_contains"), "stdout_contains")
        + nested_expectations(data, "stdout", "contains"),
        "stdout_not_contains": as_string_list(data.get("stdout_not_contains"), "stdout_not_contains")
        + nested_expectations(data, "stdout", "not_contains"),
        "stderr_contains": as_string_list(data.get("stderr_contains"), "stderr_contains")
        + nested_expectations(data, "stderr", "contains"),
        "stderr_not_contains": as_string_list(data.get("stderr_not_contains"), "stderr_not_contains")
        + nested_expectations(data, "stderr", "not_contains"),
        "risk_tags": risk_tags,
        "timeout_s": timeout_s,
    }
    validate_argv(scenario, path)
    return scenario


def validate_argv(scenario: dict[str, Any], path: pathlib.Path) -> None:
    argv = scenario["argv"]
    command_name = pathlib.Path(argv[0]).name
    for arg in argv:
        if URL_RE.match(arg):
            raise ScenarioError(f"{rel(path)}: argv contains URL-like argument: {arg}")
        if pathlib.Path(arg).name in NETWORK_COMMANDS:
            raise ScenarioError(f"{rel(path)}: argv contains network-capable command: {arg}")

    if command_name == "bash":
        if len(argv) < 2:
            raise ScenarioError(f"{rel(path)}: bash scenarios must name a repo script")
        script = argv[1]
        if script.startswith("-"):
            raise ScenarioError(f"{rel(path)}: bash option scenarios are not allowed")
        script_path = (ROOT / script).resolve()
        scripts_dir = ROOT / "scripts"
        if not is_relative_to(script_path, scripts_dir) or script_path.suffix != ".sh":
            raise ScenarioError(f"{rel(path)}: bash scenarios must run scripts/*.sh")
        if not script_path.is_file():
            raise ScenarioError(f"{rel(path)}: missing script: {rel(script_path)}")
        return

    if command_name == "python3":
        if argv[1:3] != ["-m", "json.tool"]:
            raise ScenarioError(f"{rel(path)}: python3 scenarios are limited to -m json.tool")
        for arg in argv[3:]:
            candidate = (ROOT / arg).resolve()
            if not is_relative_to(candidate, ROOT) or not candidate.is_file():
                raise ScenarioError(f"{rel(path)}: python3 json.tool target must be an existing repo file")
        return

    raise ScenarioError(f"{rel(path)}: unsupported command for no-secret scenario: {argv[0]}")


def excerpt(text: str, limit: int = 1200) -> str:
    if len(text) <= limit:
        return text
    return text[:limit] + "\n...[truncated]"


def run_scenario(scenario: dict[str, Any]) -> dict[str, Any]:
    started = time.monotonic()
    reasons: list[str] = []
    try:
        completed = subprocess.run(
            scenario["argv"],
            cwd=ROOT,
            env=safe_env(),
            text=True,
            capture_output=True,
            timeout=scenario["timeout_s"],
            shell=False,
            check=False,
        )
        exit_code = completed.returncode
        stdout = completed.stdout
        stderr = completed.stderr
    except subprocess.TimeoutExpired as exc:
        exit_code = 124
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
        reasons.append(f"timeout_after_{scenario['timeout_s']}s")

    duration_ms = int((time.monotonic() - started) * 1000)
    if exit_code != scenario["expected_exit_code"]:
        reasons.append(f"exit_code expected={scenario['expected_exit_code']} actual={exit_code}")

    for needle in scenario["stdout_contains"]:
        if needle not in stdout:
            reasons.append(f"stdout_missing: {needle}")
    for needle in scenario["stdout_not_contains"]:
        if needle in stdout:
            reasons.append(f"stdout_forbidden: {needle}")
    for needle in scenario["stderr_contains"]:
        if needle not in stderr:
            reasons.append(f"stderr_missing: {needle}")
    for needle in scenario["stderr_not_contains"]:
        if needle in stderr:
            reasons.append(f"stderr_forbidden: {needle}")

    return {
        "id": scenario["id"],
        "path": scenario["path"],
        "argv": scenario["argv"],
        "risk_tags": scenario["risk_tags"],
        "expected_exit_code": scenario["expected_exit_code"],
        "exit_code": exit_code,
        "duration_ms": duration_ms,
        "status": "pass" if not reasons else "fail",
        "reasons": reasons,
        "stdout_excerpt": excerpt(stdout),
        "stderr_excerpt": excerpt(stderr),
    }


def main() -> int:
    try:
        paths = collect_paths()
        scenarios = [load_scenario(path) for path in paths]
    except ScenarioError as exc:
        payload = {
            "status": "error",
            "scenario_count": 0,
            "passed": 0,
            "failed": 0,
            "errors": [str(exc)],
            "results": [],
        }
        if MODE == "json":
            print(json.dumps(payload, indent=2, sort_keys=True))
        else:
            print(f"[scenario-eval] {exc}", file=sys.stderr)
        return 1

    seen_ids: set[str] = set()
    duplicate_ids: set[str] = set()
    for scenario in scenarios:
        if scenario["id"] in seen_ids:
            duplicate_ids.add(scenario["id"])
        seen_ids.add(scenario["id"])
    duplicate_ids = sorted(duplicate_ids)
    if duplicate_ids:
        payload = {
            "status": "error",
            "scenario_count": len(scenarios),
            "passed": 0,
            "failed": 0,
            "errors": [f"duplicate scenario id: {scenario_id}" for scenario_id in duplicate_ids],
            "results": [],
        }
        if MODE == "json":
            print(json.dumps(payload, indent=2, sort_keys=True))
        else:
            for error in payload["errors"]:
                print(f"[scenario-eval] {error}", file=sys.stderr)
        return 1

    results = [run_scenario(scenario) for scenario in scenarios]
    failed = [result for result in results if result["status"] != "pass"]
    payload = {
        "status": "pass" if not failed else "fail",
        "scenario_count": len(results),
        "passed": len(results) - len(failed),
        "failed": len(failed),
        "errors": [],
        "results": results,
    }

    if MODE == "json":
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print("Scenario Eval")
        print(f"scenarios={payload['scenario_count']} passed={payload['passed']} failed={payload['failed']}")
        for result in results:
            print(
                f"[scenario-eval] id={result['id']} status={result['status']} "
                f"exit={result['exit_code']} duration_ms={result['duration_ms']}"
            )
            for reason in result["reasons"]:
                print(f"[scenario-eval]   reason={reason}", file=sys.stderr)
        print(f"Summary: status={payload['status']} mismatches={payload['failed']}")

    return 0 if payload["status"] == "pass" else 1


raise SystemExit(main())
PY
