#!/bin/bash
# Validate and optionally execute packet plans in isolated git worktrees.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/worktree-runner"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/worktree-runner.sh --fixtures
  bash scripts/worktree-runner.sh [--dry-run] PLAN.json
  bash scripts/worktree-runner.sh --execute PLAN.json

Packet plan shape:
  {
    "run_id": "runtime-hardening-001",
    "base_ref": "HEAD",
    "packets": [
      {
        "id": "P3-worktree",
        "owner": "worker-p3",
        "owned_files": ["scripts/worktree-runner.sh"],
        "commands": ["bash -n scripts/worktree-runner.sh"]
      }
    ]
  }

Default mode is validation/dry-run. Commands run only with --execute.
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

MODE="dry-run"
PLAN_PATH=""

case "${1:-}" in
  --fixtures)
    [ "$#" -eq 1 ] || {
      usage
      exit 2
    }
    MODE="fixtures"
    ;;
  --dry-run)
    [ "$#" -eq 2 ] || {
      usage
      exit 2
    }
    MODE="dry-run"
    PLAN_PATH="$2"
    ;;
  --execute)
    [ "$#" -eq 2 ] || {
      usage
      exit 2
    }
    MODE="execute"
    PLAN_PATH="$2"
    ;;
  --*)
    usage
    exit 2
    ;;
  *)
    [ "$#" -eq 1 ] || {
      usage
      exit 2
    }
    PLAN_PATH="$1"
    ;;
esac

python3 - "$ROOT_DIR" "$FIXTURE_DIR" "$MODE" "$PLAN_PATH" <<'PY'
import json
import pathlib
import re
import subprocess
import sys
import time
from typing import Any


ROOT = pathlib.Path(sys.argv[1]).resolve()
FIXTURE_DIR = pathlib.Path(sys.argv[2]).resolve()
MODE = sys.argv[3]
PLAN_ARG = sys.argv[4]
ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$")
MISSING = {"", "none", "n/a", "null", "missing", "todo", "tbd"}
AMBIGUOUS_PATHS = {"*", ".", "./", "repo", "repository", "all", "everything", "shared"}
DEFAULT_TIMEOUT_SECONDS = 900


def rel(path: pathlib.Path) -> str:
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def print_fail(message: str) -> int:
    print(f"[FAIL] {message}", file=sys.stderr)
    return 1


def as_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def valid_id(value: Any) -> bool:
    if not isinstance(value, str):
        return False
    text = value.strip()
    return bool(ID_RE.fullmatch(text)) and ".." not in text


def is_valid_path_spec(value: Any) -> bool:
    if not isinstance(value, str):
        return False
    path = value.strip()
    if path.lower() in AMBIGUOUS_PATHS:
        return False
    if not path or path.startswith("/") or "\\" in path or "\x00" in path:
        return False
    if "//" in path:
        return False
    clean = path[:-3] if path.endswith("/**") else path
    clean = clean.rstrip("/")
    if not clean:
        return False
    parts = clean.split("/")
    if any(part in {"", ".", ".."} for part in parts):
        return False
    if any("*" in part for part in parts):
        return False
    if parts[0] == ".git" or ".git" in parts:
        return False
    return True


def normalize_path_spec(value: str) -> tuple[str, str]:
    path = value.strip()
    if path.endswith("/**"):
        return ("prefix", path[:-3].rstrip("/"))
    if path.endswith("/"):
        return ("prefix", path.rstrip("/"))
    return ("exact", path.rstrip("/"))


def spec_owns_path(spec: str, touched_path: str) -> bool:
    kind, value = normalize_path_spec(spec)
    touched = touched_path.strip().rstrip("/")
    if kind == "exact":
        return touched == value
    return touched == value or touched.startswith(value + "/")


def specs_overlap(left: str, right: str) -> bool:
    left_kind, left_value = normalize_path_spec(left)
    right_kind, right_value = normalize_path_spec(right)
    if left_kind == "exact" and right_kind == "exact":
        return left_value == right_value
    if left_kind == "prefix" and right_kind == "exact":
        return right_value == left_value or right_value.startswith(left_value + "/")
    if left_kind == "exact" and right_kind == "prefix":
        return left_value == right_value or left_value.startswith(right_value + "/")
    return (
        left_value == right_value
        or left_value.startswith(right_value + "/")
        or right_value.startswith(left_value + "/")
    )


def packet_id(packet: dict[str, Any]) -> str:
    value = packet.get("id", packet.get("packet_id", ""))
    return str(value).strip() if isinstance(value, str) else ""


def packet_owner(packet: dict[str, Any]) -> str:
    value = packet.get("owner", "")
    return str(value).strip() if isinstance(value, str) else ""


def packet_owned_files(packet: dict[str, Any]) -> list[str]:
    value = packet.get("owned_files", packet.get("owned_paths", []))
    return [str(item).strip() for item in as_list(value) if isinstance(item, str) and item.strip()]


def packet_commands(packet: dict[str, Any]) -> list[str]:
    value = packet.get("commands", packet.get("command", []))
    return [str(item).strip() for item in as_list(value) if isinstance(item, str) and item.strip()]


def packet_timeout(packet: dict[str, Any], plan: dict[str, Any]) -> int:
    raw = packet.get("timeout_seconds", plan.get("timeout_seconds", DEFAULT_TIMEOUT_SECONDS))
    if isinstance(raw, bool):
        return DEFAULT_TIMEOUT_SECONDS
    if isinstance(raw, int) and 1 <= raw <= 86400:
        return raw
    if isinstance(raw, str) and raw.isdigit():
        value = int(raw)
        if 1 <= value <= 86400:
            return value
    return DEFAULT_TIMEOUT_SECONDS


def load_plan(path: pathlib.Path) -> tuple[dict[str, Any], list[str]]:
    errors: list[str] = []
    if not path.is_file():
        return {}, [f"missing plan: {rel(path)}"]
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return {}, [f"{rel(path)} invalid JSON: {exc}"]
    if not isinstance(data, dict):
        return {}, [f"{rel(path)} must be a JSON object"]
    return data, errors


def validate_plan(plan: dict[str, Any], plan_path: pathlib.Path) -> tuple[dict[str, Any], list[str]]:
    errors: list[str] = []
    run_id = plan.get("run_id", "")
    if not valid_id(run_id):
        errors.append("run_id must match [A-Za-z0-9][A-Za-z0-9_.-]{0,63} and must not contain '..'")

    base_ref = plan.get("base_ref", "HEAD")
    if not isinstance(base_ref, str) or not base_ref.strip():
        errors.append("base_ref must be a non-empty string when provided")
        base_ref = "HEAD"

    packets_raw = plan.get("packets")
    if not isinstance(packets_raw, list) or not packets_raw:
        errors.append("plan must include a non-empty packets array")
        packets_raw = []

    packets: list[dict[str, Any]] = []
    ids_seen: set[str] = set()
    ownership: list[tuple[str, str]] = []

    for index, raw_packet in enumerate(packets_raw, start=1):
        if not isinstance(raw_packet, dict):
            errors.append(f"packet #{index} must be a JSON object")
            continue
        packets.append(raw_packet)
        current_id = packet_id(raw_packet)
        owner = packet_owner(raw_packet)
        owned_files = packet_owned_files(raw_packet)
        commands = packet_commands(raw_packet)

        if not valid_id(current_id):
            errors.append(f"packet #{index} has invalid id")
        elif current_id in ids_seen:
            errors.append(f"packet {current_id} is duplicated")
        else:
            ids_seen.add(current_id)

        if not owner or owner.lower() in {"unknown", "unassigned", "shared", "multiple", "anyone", "all"}:
            errors.append(f"packet {current_id or index} has missing or ambiguous owner")

        if not owned_files:
            errors.append(f"packet {current_id or index} must include owned_files")
        for owned in owned_files:
            if not is_valid_path_spec(owned):
                errors.append(f"packet {current_id or index} has invalid owned_files entry: {owned}")

        if not commands:
            errors.append(f"packet {current_id or index} must include at least one command")

        for command in as_list(raw_packet.get("commands", raw_packet.get("command", []))):
            if not isinstance(command, str) or not command.strip():
                errors.append(f"packet {current_id or index} has a non-string or empty command")

        for owned in owned_files:
            ownership.append((current_id or f"#{index}", owned))

    for left_index, (left_packet, left_path) in enumerate(ownership):
        for right_packet, right_path in ownership[left_index + 1 :]:
            if left_packet == right_packet:
                if left_path == right_path:
                    errors.append(f"packet {left_packet} repeats owned path {left_path}")
                continue
            if specs_overlap(left_path, right_path):
                errors.append(
                    f"owned_files overlap between {left_packet} ({left_path}) and {right_packet} ({right_path})"
                )

    normalized = {
        "run_id": str(run_id).strip() if isinstance(run_id, str) else "",
        "base_ref": base_ref.strip() if isinstance(base_ref, str) else "HEAD",
        "packet_count": len(packets),
        "plan_path": rel(plan_path),
        "worktree_root": rel(ROOT / ".taste" / "worktrees" / str(run_id).strip())
        if isinstance(run_id, str)
        else "",
    }
    return normalized, errors


def git_changed_paths(worktree: pathlib.Path) -> list[str]:
    result = subprocess.run(
        ["git", "status", "--porcelain", "--untracked-files=all"],
        cwd=worktree,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        return []
    paths: list[str] = []
    for line in result.stdout.splitlines():
        if not line.strip():
            continue
        path = line[3:].strip()
        if " -> " in path:
            path = path.split(" -> ", 1)[1].strip()
        if path:
            paths.append(path)
    return sorted(set(paths))


def write_text(path: pathlib.Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def command_record(command: str, exit_code: int, duration: float, stdout_path: pathlib.Path, stderr_path: pathlib.Path) -> dict[str, Any]:
    return {
        "command": command,
        "exit_code": exit_code,
        "duration_seconds": round(duration, 3),
        "stdout_path": rel(stdout_path),
        "stderr_path": rel(stderr_path),
    }


def execute_plan(plan: dict[str, Any], normalized: dict[str, Any], plan_path: pathlib.Path) -> int:
    run_id = normalized["run_id"]
    base_ref = normalized["base_ref"]
    run_root = ROOT / ".taste" / "worktrees" / run_id
    results_dir = run_root / "worker-results"

    if run_root.exists():
        return print_fail(f"worktree run directory already exists: {rel(run_root)}")

    results_dir.mkdir(parents=True, exist_ok=False)

    packets = [packet for packet in plan.get("packets", []) if isinstance(packet, dict)]
    overall_status = 0

    for packet in packets:
        current_id = packet_id(packet)
        owner = packet_owner(packet)
        owned_files = packet_owned_files(packet)
        commands = packet_commands(packet)
        timeout_seconds = packet_timeout(packet, plan)
        worktree = run_root / current_id
        result_path = results_dir / f"{current_id}.json"

        if worktree.exists():
            return print_fail(f"worktree already exists: {rel(worktree)}")
        if result_path.exists():
            return print_fail(f"worker result already exists: {rel(result_path)}")

        add_result = subprocess.run(
            ["git", "worktree", "add", "--detach", str(worktree), base_ref],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if add_result.returncode != 0:
            return print_fail(f"git worktree add failed for {current_id}: {add_result.stderr.strip()}")

        commands_run: list[dict[str, Any]] = []
        command_failed = False

        for index, command in enumerate(commands, start=1):
            stdout_path = results_dir / f"{current_id}-command-{index}.stdout.txt"
            stderr_path = results_dir / f"{current_id}-command-{index}.stderr.txt"
            started = time.monotonic()
            try:
                command_result = subprocess.run(
                    command,
                    cwd=worktree,
                    shell=True,
                    executable="/bin/bash",
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    timeout=timeout_seconds,
                    check=False,
                )
                duration = time.monotonic() - started
                write_text(stdout_path, command_result.stdout)
                write_text(stderr_path, command_result.stderr)
                commands_run.append(
                    command_record(command, command_result.returncode, duration, stdout_path, stderr_path)
                )
                if command_result.returncode != 0:
                    command_failed = True
                    break
            except subprocess.TimeoutExpired as exc:
                duration = time.monotonic() - started
                write_text(stdout_path, exc.stdout or "")
                write_text(stderr_path, exc.stderr or f"command timed out after {timeout_seconds} seconds\n")
                commands_run.append(command_record(command, 124, duration, stdout_path, stderr_path))
                command_failed = True
                break

        touched_files = git_changed_paths(worktree)
        outside_owned = [
            touched
            for touched in touched_files
            if not any(spec_owns_path(owned, touched) for owned in owned_files)
        ]
        status = "failed" if command_failed or outside_owned else "success"
        if status != "success":
            overall_status = 1

        evidence = [
            f"worktree-runner created {rel(worktree)} from {base_ref}",
            f"executed {len(commands_run)} of {len(commands)} command(s)",
        ]
        if outside_owned:
            evidence.append("detected touched files outside owned_files")

        worker_result = {
            "artifact_type": "worker-result",
            "run_id": run_id,
            "packet_id": current_id,
            "owner": owner,
            "status": status,
            "base_ref": base_ref,
            "worktree_path": rel(worktree),
            "owned_files": owned_files,
            "touched_files": touched_files,
            "outside_owned_touched_files": outside_owned,
            "commands_run": commands_run,
            "tests_run": commands_run,
            "evidence": evidence,
            "unresolved_risks": [] if status == "success" else ["review failed command or ownership evidence"],
            "changed_line_trace": [
                f"{current_id}: packet command execution requested by {rel(plan_path)}"
            ],
            "handoff_notes": "Generated by scripts/worktree-runner.sh --execute.",
            "parent_verified": True,
        }
        result_path.write_text(json.dumps(worker_result, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    if overall_status == 0:
        print(f"[PASS] worktree runner executed run_id={run_id} packets={len(packets)}")
    else:
        print(f"[FAIL] worktree runner executed run_id={run_id} with failed packet evidence", file=sys.stderr)
    return overall_status


def dry_run(plan_path: pathlib.Path) -> int:
    plan, load_errors = load_plan(plan_path)
    if load_errors:
        return print_fail("; ".join(load_errors))
    normalized, validation_errors = validate_plan(plan, plan_path)
    if validation_errors:
        return print_fail("; ".join(validation_errors))
    print(
        "[PASS] worktree runner dry-run "
        f"run_id={normalized['run_id']} packets={normalized['packet_count']} "
        f"worktree_root={normalized['worktree_root']}"
    )
    return 0


def execute(plan_path: pathlib.Path) -> int:
    plan, load_errors = load_plan(plan_path)
    if load_errors:
        return print_fail("; ".join(load_errors))
    normalized, validation_errors = validate_plan(plan, plan_path)
    if validation_errors:
        return print_fail("; ".join(validation_errors))
    return execute_plan(plan, normalized, plan_path)


def expect_pass(path: pathlib.Path) -> None:
    code = dry_run(path)
    if code != 0:
        raise SystemExit(print_fail(f"green fixture was rejected: {rel(path)}"))


def expect_fail(path: pathlib.Path, name: str) -> None:
    plan, load_errors = load_plan(path)
    if load_errors:
        raise SystemExit(print_fail("; ".join(load_errors)))
    _, validation_errors = validate_plan(plan, path)
    if not validation_errors:
        raise SystemExit(print_fail(f"{name} fixture was accepted: {rel(path)}"))


def fixtures() -> int:
    expect_pass(FIXTURE_DIR / "green-plan.json")
    expect_fail(FIXTURE_DIR / "red-overlapping-owned-files.json", "overlapping ownership")
    expect_fail(FIXTURE_DIR / "red-missing-commands.json", "missing commands")
    expect_fail(FIXTURE_DIR / "red-invalid-ids.json", "invalid ids")
    print("[PASS] worktree runner fixtures passed")
    return 0


def main() -> int:
    if MODE == "fixtures":
        return fixtures()
    plan_path = pathlib.Path(PLAN_ARG)
    if not plan_path.is_absolute():
        plan_path = ROOT / plan_path
    if MODE == "dry-run":
        return dry_run(plan_path)
    if MODE == "execute":
        return execute(plan_path)
    return print_fail(f"unknown mode: {MODE}")


if __name__ == "__main__":
    raise SystemExit(main())
PY
