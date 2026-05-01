#!/bin/bash
# Aggregate and validate run-level /parallel artifacts.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/parallel-aggregate"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/parallel-aggregate.sh --fixtures
  bash scripts/parallel-aggregate.sh [--json] RUN_DIR

RUN_DIR layout:
  packet-dag.json
  ownership.json
  worker-results/*.json
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
import re
import subprocess
import sys
from collections import defaultdict, deque
from typing import Any


ROOT = pathlib.Path(sys.argv[1])
FIXTURE_DIR = pathlib.Path(sys.argv[2])
ARGS = sys.argv[3:]

LINEAR_SCALING_RE = re.compile(
    r"(\b\d+\s*(agents|lanes)\s*(means|=)\s*\d*x\s*faster\b|"
    r"\b10\s*agents\s*means\s*10x\s*faster\b|"
    r"\blinear\s+lane\s+scaling\b|"
    r"\bperfect\s+scaling\b|"
    r"\blinear\s+scaling\b)",
    re.IGNORECASE,
)

FAIL_STATUSES = {"fail", "failed", "blocked", "partial", "error", "red"}
PASS_STATUSES = {"success", "pass", "passed", "complete", "completed"}


def rel(path: pathlib.Path) -> str:
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def print_fail(message: str) -> int:
    print(f"[FAIL] {message}", file=sys.stderr)
    return 1


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


def int_or_none(value: Any) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int) and value > 0:
        return value
    if isinstance(value, str) and value.isdigit() and int(value) > 0:
        return int(value)
    return None


def path_owned(owned: str, touched: str) -> bool:
    owned = owned.strip()
    touched = touched.strip()
    if not owned or not touched:
        return False
    if owned.endswith("/**"):
        prefix = owned[:-3]
        return touched == prefix or touched.startswith(prefix + "/")
    if owned.endswith("/"):
        return touched.startswith(owned)
    return owned == touched


def any_path_owned(owned_files: list[str], touched: str) -> bool:
    return any(path_owned(owned, touched) for owned in owned_files)


def has_command_evidence(commands: Any) -> bool:
    for command in as_list(commands):
        if isinstance(command, str) and command.strip():
            return True
        if isinstance(command, dict) and present(command.get("command")):
            return True
    return False


def strings_for_scan(value: Any) -> str:
    try:
        return json.dumps(value, sort_keys=True)
    except TypeError:
        return str(value)


def fixture_expected(path: pathlib.Path) -> str:
    expected_file = path / "expected.json"
    if expected_file.is_file():
        try:
            expected = json.loads(expected_file.read_text(encoding="utf-8"))
            result = str(expected.get("result", "")).strip().lower()
            if result in {"pass", "fail"}:
                return result
        except Exception:
            pass
    return "fail" if path.name.startswith("red-") else "pass"


def normalize_worker(data: dict[str, Any]) -> dict[str, Any]:
    if data.get("artifact_type") == "worker_result" and isinstance(data.get("worker_result"), dict):
        worker_result = data["worker_result"]
        worker = worker_result.get("worker") if isinstance(worker_result.get("worker"), dict) else {}
        packet = worker_result.get("packet") if isinstance(worker_result.get("packet"), dict) else {}
        parent = worker_result.get("parent_verification") if isinstance(worker_result.get("parent_verification"), dict) else {}
        data = {
            **data,
            "artifact_type": "worker-result",
            "packet_id": packet.get("id") or worker_result.get("packet_id"),
            "owner": worker.get("id") or worker_result.get("owner"),
            "owned_files": packet.get("owned_paths") or worker.get("ownership") or worker_result.get("owned_files"),
            "touched_files": packet.get("touched_paths") or worker_result.get("touched_files"),
            "commands_run": worker_result.get("commands") or worker_result.get("commands_run"),
            "tests_run": worker_result.get("tests_run"),
            "evidence": worker_result.get("claims") or parent.get("evidence") or worker_result.get("evidence"),
            "claims": worker_result.get("claims"),
            "parent_verified": parent.get("verified") if "verified" in parent else worker_result.get("parent_verified"),
            "changed_line_trace": worker_result.get("changed_line_trace"),
            "handoff_notes": worker_result.get("handoff_notes"),
            "status": worker_result.get("status"),
        }
    return data


def run_capacity() -> dict[str, Any]:
    script = ROOT / "scripts" / "parallel-capacity.sh"
    try:
        output = subprocess.check_output(["bash", str(script), "--json"], cwd=ROOT, text=True, stderr=subprocess.DEVNULL)
        data = json.loads(output)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def capacity_ceiling(packet_dag: dict[str, Any]) -> tuple[int, dict[str, Any]]:
    capacity = packet_dag.get("capacity") if isinstance(packet_dag.get("capacity"), dict) else {}
    if not capacity:
        capacity = run_capacity()
    candidates = [
        int_or_none(capacity.get("recommended_ceiling")),
        int_or_none(capacity.get("max_parallel_agents")),
        int_or_none(capacity.get("codex_max_threads")),
        int_or_none(capacity.get("auto_ceiling")),
    ]
    positives = [candidate for candidate in candidates if candidate is not None]
    return (min(positives) if positives else 1, capacity)


def packet_duration(packet: dict[str, Any]) -> int:
    for key in ("estimated_minutes", "duration_minutes", "likely_minutes"):
        value = int_or_none(packet.get(key))
        if value is not None:
            return value
    estimate = packet.get("estimate")
    if isinstance(estimate, dict):
        value = int_or_none(estimate.get("likely_minutes"))
        if value is not None:
            return value
    return 30


def packet_dependencies(packet: dict[str, Any]) -> list[str]:
    return [str(item).strip() for item in as_list(packet.get("depends_on")) if str(item).strip() and str(item).strip().lower() != "none"]


def compute_graph(packets: list[dict[str, Any]], errors: list[str]) -> tuple[list[str], int, int]:
    ids = [str(packet.get("id", "")).strip() for packet in packets]
    if len(set(ids)) != len(ids):
        errors.append("packet ids must be unique")
    packet_by_id = {packet_id: packet for packet_id, packet in zip(ids, packets) if packet_id}
    children: dict[str, list[str]] = defaultdict(list)
    indegree: dict[str, int] = {packet_id: 0 for packet_id in packet_by_id}
    parents: dict[str, list[str]] = {packet_id: [] for packet_id in packet_by_id}

    for packet_id, packet in packet_by_id.items():
        for dependency in packet_dependencies(packet):
            if dependency not in packet_by_id:
                errors.append(f"packet {packet_id} depends on unknown packet {dependency}")
                continue
            children[dependency].append(packet_id)
            indegree[packet_id] += 1
            parents[packet_id].append(dependency)

    queue = deque([packet_id for packet_id, count in indegree.items() if count == 0])
    topo: list[str] = []
    levels: dict[str, int] = {}
    longest_minutes: dict[str, int] = {}
    longest_path: dict[str, list[str]] = {}

    for packet_id in queue:
        levels[packet_id] = 0
        longest_minutes[packet_id] = packet_duration(packet_by_id[packet_id])
        longest_path[packet_id] = [packet_id]

    while queue:
        current = queue.popleft()
        topo.append(current)
        for child in children.get(current, []):
            candidate_level = levels[current] + 1
            levels[child] = max(levels.get(child, 0), candidate_level)
            candidate_minutes = longest_minutes[current] + packet_duration(packet_by_id[child])
            if candidate_minutes > longest_minutes.get(child, 0):
                longest_minutes[child] = candidate_minutes
                longest_path[child] = longest_path[current] + [child]
            indegree[child] -= 1
            if indegree[child] == 0:
                if child not in longest_minutes:
                    longest_minutes[child] = packet_duration(packet_by_id[child])
                    longest_path[child] = [child]
                queue.append(child)

    if len(topo) != len(packet_by_id):
        errors.append("packet DAG contains a cycle")
        return [], 0, 1

    if not packet_by_id:
        return [], 0, 0

    level_counts: dict[int, int] = defaultdict(int)
    for packet_id in packet_by_id:
        level_counts[levels.get(packet_id, 0)] += 1
    max_width = max(level_counts.values()) if level_counts else 0
    terminal = max(packet_by_id, key=lambda packet_id: longest_minutes.get(packet_id, 0))
    return longest_path.get(terminal, [terminal]), longest_minutes.get(terminal, packet_duration(packet_by_id[terminal])), max_width


def ownership_entry_map(ownership: dict[str, Any]) -> dict[str, dict[str, Any]]:
    entries = ownership.get("ownership") or ownership.get("packets") or []
    result: dict[str, dict[str, Any]] = {}
    for entry in as_list(entries):
        if isinstance(entry, dict) and present(entry.get("packet_id")):
            result[str(entry["packet_id"])] = entry
    return result


def approval_set(ownership: dict[str, Any]) -> set[tuple[str, str]]:
    approvals: set[tuple[str, str]] = set()
    for approval in as_list(ownership.get("approved_cross_owned_edits")):
        if not isinstance(approval, dict):
            continue
        packet_id = str(approval.get("packet_id", "")).strip()
        path = str(approval.get("path", "")).strip()
        if packet_id and path and present(approval.get("approved_by")) and present(approval.get("reason")):
            approvals.add((packet_id, path))
    return approvals


def is_approved(approvals: set[tuple[str, str]], packet_id: str, path: str) -> bool:
    return (packet_id, path) in approvals or (packet_id, "*") in approvals


def aggregate(run_dir: pathlib.Path) -> tuple[dict[str, Any], list[str]]:
    errors: list[str] = []
    packet_dag = load_json(run_dir / "packet-dag.json", errors)
    ownership = load_json(run_dir / "ownership.json", errors)
    worker_dir = run_dir / "worker-results"

    packets_raw = packet_dag.get("packets", [])
    packets = [packet for packet in as_list(packets_raw) if isinstance(packet, dict)]
    packet_ids = [str(packet.get("id", "")).strip() for packet in packets if present(packet.get("id"))]
    packet_set = set(packet_ids)
    if not packets:
        errors.append("packet-dag.json must include packets")
    if len(packet_set) != len(packet_ids):
        errors.append("packet-dag.json has duplicate or missing packet ids")

    if LINEAR_SCALING_RE.search(strings_for_scan(packet_dag)) or LINEAR_SCALING_RE.search(strings_for_scan(ownership)):
        errors.append("linear lane scaling claims are not allowed")

    critical_path, critical_path_minutes, max_width = compute_graph(packets, errors)
    ceiling, capacity = capacity_ceiling(packet_dag)
    supervisor_capacity = int_or_none(packet_dag.get("supervisor_review_capacity")) or ceiling
    verification_capacity = int_or_none(packet_dag.get("verification_capacity")) or ceiling
    sync_barrier_capacity = int_or_none(packet_dag.get("sync_barrier_capacity")) or max_width or 1
    independent_width = max_width or len(packet_set) or 1
    lane_candidates = {
        "capacity_ceiling": ceiling,
        "independent_packet_width": independent_width,
        "supervisor_review_capacity": supervisor_capacity,
        "verification_capacity": verification_capacity,
        "sync_barrier_capacity": sync_barrier_capacity,
    }
    effective_lanes = min(value for value in lane_candidates.values() if value > 0)
    bottleneck = min(lane_candidates, key=lane_candidates.get)

    ownership_by_packet = ownership_entry_map(ownership)
    approvals = approval_set(ownership)
    for packet_id in packet_set:
        if packet_id not in ownership_by_packet:
            errors.append(f"missing ownership entry for packet {packet_id}")

    worker_paths = sorted(worker_dir.glob("*.json")) if worker_dir.is_dir() else []
    if not worker_paths:
        errors.append(f"missing worker result JSON files under {rel(worker_dir)}")

    worker_by_packet: dict[str, dict[str, Any]] = {}
    touched_by_path: dict[str, list[str]] = defaultdict(list)
    for path in worker_paths:
        worker = normalize_worker(load_json(path, errors))
        packet_id = str(worker.get("packet_id", "")).strip()
        if not packet_id:
            errors.append(f"{rel(path)} missing packet_id")
            continue
        if packet_id not in packet_set:
            errors.append(f"{rel(path)} references unknown packet {packet_id}")
        if packet_id in worker_by_packet:
            errors.append(f"duplicate worker result for packet {packet_id}")
        worker_by_packet[packet_id] = worker

        if worker.get("artifact_type") != "worker-result":
            errors.append(f"{rel(path)} artifact_type must be worker-result")
        status = str(worker.get("status", "success")).strip().lower()
        if status in FAIL_STATUSES or (status and status not in PASS_STATUSES):
            errors.append(f"packet {packet_id} worker status is not successful: {status or 'missing'}")
        if worker.get("parent_verified") is not True:
            errors.append(f"packet {packet_id} worker result is not parent_verified")
        if not has_command_evidence(worker.get("commands_run")):
            errors.append(f"packet {packet_id} worker result is missing command evidence")
        if not present(worker.get("tests_run")):
            errors.append(f"packet {packet_id} worker result is missing tests_run")
        if not present(worker.get("evidence")):
            errors.append(f"packet {packet_id} worker result is missing evidence")
        if not present(worker.get("changed_line_trace")):
            errors.append(f"packet {packet_id} worker result is missing changed_line_trace")
        if not present(worker.get("handoff_notes")):
            errors.append(f"packet {packet_id} worker result is missing handoff_notes")

        ownership_entry = ownership_by_packet.get(packet_id, {})
        owned_files = [str(item) for item in as_list(ownership_entry.get("owned_files") or ownership_entry.get("owned_paths"))]
        if not owned_files:
            owned_files = [str(item) for item in as_list(worker.get("owned_files"))]
        if not owned_files:
            errors.append(f"packet {packet_id} has no owned_files in ownership matrix or worker result")

        for touched in as_list(worker.get("touched_files")):
            touched_text = str(touched).strip()
            if not touched_text:
                continue
            touched_by_path[touched_text].append(packet_id)
            if any_path_owned(owned_files, touched_text):
                continue
            if is_approved(approvals, packet_id, touched_text):
                continue
            errors.append(f"packet {packet_id} touches {touched_text} outside owned files without approval")

    missing_results = sorted(packet_set - set(worker_by_packet))
    for packet_id in missing_results:
        errors.append(f"missing worker result for packet {packet_id}")

    for touched_path, packets_for_path in sorted(touched_by_path.items()):
        unique_packets = sorted(set(packets_for_path))
        if len(unique_packets) <= 1:
            continue
        if all(is_approved(approvals, packet_id, touched_path) for packet_id in unique_packets):
            continue
        errors.append(f"shared-file collision on {touched_path} across packets {', '.join(unique_packets)} without approval")

    result = {
        "status": "fail" if errors else "pass",
        "run_dir": rel(run_dir),
        "packet_count": len(packet_set),
        "worker_result_count": len(worker_by_packet),
        "capacity_ceiling": ceiling,
        "capacity": capacity,
        "effective_lanes": effective_lanes,
        "bottleneck": bottleneck,
        "lane_candidates": lane_candidates,
        "critical_path": critical_path,
        "critical_path_minutes": critical_path_minutes,
        "additional_lanes_help": effective_lanes >= ceiling and effective_lanes >= independent_width,
        "errors": errors,
    }
    return result, errors


def run_one(run_dir: pathlib.Path, json_mode: bool = False) -> int:
    result, errors = aggregate(run_dir)
    if json_mode:
        print(json.dumps(result, sort_keys=True))
    elif errors:
        for error in errors:
            print(f"[parallel-aggregate] {error}", file=sys.stderr)
    else:
        print(
            "[PASS] parallel aggregate "
            f"packets={result['packet_count']} "
            f"workers={result['worker_result_count']} "
            f"effective_lanes={result['effective_lanes']} "
            f"bottleneck={result['bottleneck']} "
            f"critical_path={','.join(result['critical_path'])}"
        )
    return 0 if not errors else 1


def run_fixtures() -> int:
    if not FIXTURE_DIR.is_dir():
        return print_fail(f"missing fixture dir: {rel(FIXTURE_DIR)}")

    runs = sorted(path for path in FIXTURE_DIR.iterdir() if path.is_dir())
    if not runs:
        return print_fail(f"no parallel aggregate fixtures under {rel(FIXTURE_DIR)}")

    failures = 0
    passed_green = 0
    rejected_red = 0
    bottleneck_checked = False
    for run in runs:
        expected = fixture_expected(run)
        result, errors = aggregate(run)
        actual = "fail" if errors else "pass"
        if run.name == "bottleneck-run" and actual == "pass":
            if result["effective_lanes"] == 1 and result["bottleneck"] == "supervisor_review_capacity" and result["additional_lanes_help"] is False:
                bottleneck_checked = True
            else:
                failures += 1
                print(f"[parallel-aggregate] {run.name} did not expose supervisor bottleneck", file=sys.stderr)
        if expected == actual:
            if actual == "pass":
                passed_green += 1
            else:
                rejected_red += 1
            continue
        failures += 1
        print(
            f"[parallel-aggregate] {run.name} expected {expected} but got {actual}: "
            + ("; ".join(errors) if errors else "no validation errors"),
            file=sys.stderr,
        )

    if passed_green < 2:
        failures += 1
        print(f"[parallel-aggregate] expected at least 2 passing fixtures, got {passed_green}", file=sys.stderr)
    if rejected_red < 4:
        failures += 1
        print(f"[parallel-aggregate] expected at least 4 rejected fixtures, got {rejected_red}", file=sys.stderr)
    if not bottleneck_checked:
        failures += 1
        print("[parallel-aggregate] bottleneck fixture did not prove additional lanes stop helping", file=sys.stderr)

    if failures:
        return 1
    print(f"[PASS] parallel aggregate fixtures passed ({passed_green} green, {rejected_red} red)")
    return 0


if ARGS == ["--fixtures"]:
    raise SystemExit(run_fixtures())

json_mode = False
if ARGS and ARGS[0] == "--json":
    json_mode = True
    ARGS = ARGS[1:]

if len(ARGS) != 1:
    print("[FAIL] expected one RUN_DIR", file=sys.stderr)
    raise SystemExit(2)

raise SystemExit(run_one(pathlib.Path(ARGS[0]), json_mode=json_mode))
PY
