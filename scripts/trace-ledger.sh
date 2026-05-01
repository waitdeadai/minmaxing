#!/bin/bash
# Append, validate, and summarize local JSONL trace ledgers.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACE_ROOT="$ROOT_DIR/.taste/traces"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/trace-ledger"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/trace-ledger.sh append --run-id RUN_ID --event EVENT --status STATUS [options]
  bash scripts/trace-ledger.sh append --event-json JSON_OR_- [--run-id RUN_ID]
  bash scripts/trace-ledger.sh validate [PATH_OR_RUN_ID ...]
  bash scripts/trace-ledger.sh summary [--json] [PATH_OR_RUN_ID ...]
  bash scripts/trace-ledger.sh --fixtures

Append options:
  --source SOURCE       Event source, default: trace-ledger
  --message TEXT        Optional human-readable message
  --duration-ms N       Optional nonnegative duration in milliseconds
  --at TIMESTAMP        Optional ISO-8601 timestamp, default: current UTC time
  --data-json JSON      Optional JSON object stored under data

Trace files are written to .taste/traces/{run_id}/trace.jsonl. Provider cost
and token data are summarized only when explicitly present as valid metrics;
otherwise they remain insufficient_data.
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

python3 - "$ROOT_DIR" "$TRACE_ROOT" "$FIXTURE_DIR" "$@" <<'PY'
import datetime as dt
import fcntl
import json
import os
import pathlib
import re
import shutil
import sys
from collections import Counter
from typing import Any


ROOT = pathlib.Path(sys.argv[1]).resolve()
TRACE_ROOT = pathlib.Path(sys.argv[2]).resolve()
FIXTURE_DIR = pathlib.Path(sys.argv[3]).resolve()
ARGS = sys.argv[4:]

RUN_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")
STATUS_RE = re.compile(r"^[A-Za-z0-9._-]{1,64}$")
REQUIRED_FIELDS = ("timestamp", "run_id", "event", "status")
METRIC_KEYS = ("provider_cost", "provider_tokens")


def rel(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def fail(message: str, code: int = 1) -> int:
    print(f"[FAIL] {message}", file=sys.stderr)
    return code


def now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def parse_timestamp(value: Any) -> dt.datetime | None:
    if not isinstance(value, str) or not value.strip():
        return None
    text = value.strip()
    try:
        parsed = dt.datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def safe_run_id(value: Any) -> bool:
    return isinstance(value, str) and RUN_ID_RE.match(value) is not None and value not in {".", ".."}


def trace_path_for_run(run_id: str) -> pathlib.Path:
    if not safe_run_id(run_id):
        raise ValueError("run_id must match [A-Za-z0-9][A-Za-z0-9._-]{0,127}")
    return TRACE_ROOT / run_id / "trace.jsonl"


def as_nonnegative_number(value: Any) -> int | float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)) and value >= 0:
        return value
    if isinstance(value, str):
        text = value.strip()
        if re.match(r"^\d+(\.\d+)?$", text):
            parsed = float(text) if "." in text else int(text)
            return parsed if parsed >= 0 else None
    return None


def parse_json_object(raw: str, label: str) -> dict[str, Any]:
    if raw == "-":
        raw = sys.stdin.read()
    try:
        value = json.loads(raw)
    except Exception as exc:
        raise ValueError(f"{label} is invalid JSON: {exc}") from exc
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be a JSON object")
    return value


def metric_value(value: Any, key: str) -> int | float | str | None:
    if value == "insufficient_data":
        return value
    number = as_nonnegative_number(value)
    if number is None:
        return None
    if key == "provider_tokens" and isinstance(number, float) and not number.is_integer():
        return None
    return int(number) if key == "provider_tokens" else number


def validate_event(event: Any, expected_run_id: str | None = None) -> list[str]:
    errors: list[str] = []
    if not isinstance(event, dict):
        return ["line must be a JSON object"]

    for field in REQUIRED_FIELDS:
        value = event.get(field)
        if not isinstance(value, str) or not value.strip():
            errors.append(f"missing required field {field}")

    run_id = event.get("run_id")
    if run_id is not None and not safe_run_id(run_id):
        errors.append("run_id must be a safe path segment")
    if expected_run_id and run_id != expected_run_id:
        errors.append(f"run_id {run_id!r} does not match trace directory {expected_run_id!r}")

    timestamp = event.get("timestamp")
    if timestamp is not None and parse_timestamp(timestamp) is None:
        errors.append("timestamp must be ISO-8601 parseable")

    status = event.get("status")
    if isinstance(status, str) and not STATUS_RE.match(status.strip()):
        errors.append("status must be a slug up to 64 characters")

    duration = event.get("duration_ms")
    if duration is not None and as_nonnegative_number(duration) is None:
        errors.append("duration_ms must be a nonnegative number")

    data = event.get("data")
    if data is not None and not isinstance(data, dict):
        errors.append("data must be a JSON object when present")

    metrics = event.get("metrics")
    if metrics is not None and not isinstance(metrics, dict):
        errors.append("metrics must be a JSON object when present")
    metric_sources: list[dict[str, Any]] = []
    if isinstance(metrics, dict):
        metric_sources.append(metrics)
    metric_sources.append(event)
    for source in metric_sources:
        for key in METRIC_KEYS:
            if key in source and metric_value(source[key], key) is None:
                errors.append(f"{key} must be nonnegative numeric data or insufficient_data")

    return errors


def expected_run_id_from_path(path: pathlib.Path) -> str | None:
    try:
        relative = path.resolve().relative_to(TRACE_ROOT)
    except ValueError:
        return None
    if len(relative.parts) >= 2 and relative.parts[-1] == "trace.jsonl":
        return relative.parts[0]
    return None


def load_jsonl(path: pathlib.Path) -> tuple[list[dict[str, Any]], list[str]]:
    records: list[dict[str, Any]] = []
    errors: list[str] = []
    expected_run_id = expected_run_id_from_path(path)

    if not path.is_file():
        return records, [f"{rel(path)} does not exist or is not a file"]

    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        if not line.strip():
            errors.append(f"{rel(path)}:{line_no}: blank JSONL lines are not allowed")
            continue
        try:
            value = json.loads(line)
        except Exception as exc:
            errors.append(f"{rel(path)}:{line_no}: invalid JSON: {exc}")
            continue
        event_errors = validate_event(value, expected_run_id=expected_run_id)
        if event_errors:
            errors.extend(f"{rel(path)}:{line_no}: {error}" for error in event_errors)
            continue
        records.append(value)

    if not records and not errors:
        errors.append(f"{rel(path)} has no trace events")
    return records, errors


def resolve_target(raw: str) -> list[pathlib.Path]:
    path = pathlib.Path(raw)
    if path.exists():
        path = path.resolve()
        if path.is_file():
            return [path]
        if path.is_dir():
            candidates = sorted(path.rglob("trace.jsonl"))
            if not candidates:
                candidates = sorted(path.rglob("*.jsonl"))
            return [candidate for candidate in candidates if candidate.is_file()]
    if safe_run_id(raw):
        return [trace_path_for_run(raw)]
    return [path.resolve()]


def resolve_targets(raws: list[str]) -> list[pathlib.Path]:
    if not raws:
        raws = [TRACE_ROOT.as_posix()]
    targets: list[pathlib.Path] = []
    for raw in raws:
        targets.extend(resolve_target(raw))
    return sorted(set(targets))


def validate_paths(paths: list[pathlib.Path]) -> tuple[int, int, list[str]]:
    if not paths:
        return 0, 0, ["no trace files found"]
    event_count = 0
    errors: list[str] = []
    for path in paths:
        records, path_errors = load_jsonl(path)
        event_count += len(records)
        errors.extend(path_errors)
    return len(paths), event_count, errors


def append_event(event: dict[str, Any]) -> pathlib.Path:
    errors = validate_event(event)
    if errors:
        raise ValueError("; ".join(errors))
    path = trace_path_for_run(str(event["run_id"]))
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(event, sort_keys=True, separators=(",", ":"))
    with path.open("a", encoding="utf-8") as handle:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
        handle.write(payload + "\n")
        handle.flush()
        os.fsync(handle.fileno())
        fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
    return path


def parse_append_args(args: list[str]) -> dict[str, Any]:
    event_json: dict[str, Any] | None = None
    event: dict[str, Any] = {}
    index = 0
    while index < len(args):
        flag = args[index]
        if flag not in {
            "--run-id",
            "--event",
            "--status",
            "--source",
            "--message",
            "--duration-ms",
            "--at",
            "--data-json",
            "--event-json",
        }:
            raise ValueError(f"unknown append option: {flag}")
        if index + 1 >= len(args):
            raise ValueError(f"{flag} requires a value")
        value = args[index + 1]
        if flag == "--run-id":
            event["run_id"] = value
        elif flag == "--event":
            event["event"] = value
        elif flag == "--status":
            event["status"] = value
        elif flag == "--source":
            event["source"] = value
        elif flag == "--message":
            event["message"] = value
        elif flag == "--duration-ms":
            parsed = as_nonnegative_number(value)
            if parsed is None:
                raise ValueError("--duration-ms must be a nonnegative number")
            event["duration_ms"] = parsed
        elif flag == "--at":
            event["timestamp"] = value
        elif flag == "--data-json":
            event["data"] = parse_json_object(value, "--data-json")
        elif flag == "--event-json":
            event_json = parse_json_object(value, "--event-json")
        index += 2

    if event_json is not None:
        event = {**event_json, **event}
    event.setdefault("timestamp", now_iso())
    event.setdefault("source", "trace-ledger")
    return event


def summarize_events(paths: list[pathlib.Path]) -> tuple[dict[str, Any], list[str]]:
    records: list[dict[str, Any]] = []
    errors: list[str] = []
    for path in paths:
        loaded, path_errors = load_jsonl(path)
        records.extend(loaded)
        errors.extend(path_errors)

    status_counts = Counter(str(record.get("status", "")).strip().lower() for record in records)
    event_counts = Counter(str(record.get("event", "")).strip() for record in records)
    run_ids = sorted({str(record.get("run_id")) for record in records if record.get("run_id")})

    timestamps = [parsed for parsed in (parse_timestamp(record.get("timestamp")) for record in records) if parsed]
    duration_values = [
        number for number in (as_nonnegative_number(record.get("duration_ms")) for record in records) if number is not None
    ]

    numeric_metrics: dict[str, list[int | float]] = {key: [] for key in METRIC_KEYS}
    for record in records:
        sources: list[dict[str, Any]] = []
        metrics = record.get("metrics")
        if isinstance(metrics, dict):
            sources.append(metrics)
        sources.append(record)
        for source in sources:
            for key in METRIC_KEYS:
                if key not in source:
                    continue
                value = metric_value(source[key], key)
                if isinstance(value, (int, float)) and not isinstance(value, bool):
                    numeric_metrics[key].append(value)

    provider_cost: int | float | str = (
        round(sum(numeric_metrics["provider_cost"]), 6) if numeric_metrics["provider_cost"] else "insufficient_data"
    )
    provider_tokens: int | str = (
        int(sum(numeric_metrics["provider_tokens"])) if numeric_metrics["provider_tokens"] else "insufficient_data"
    )

    first_timestamp = min(timestamps).isoformat().replace("+00:00", "Z") if timestamps else None
    last_timestamp = max(timestamps).isoformat().replace("+00:00", "Z") if timestamps else None
    observed_duration_ms: int | str = "insufficient_data"
    if len(timestamps) >= 2:
        observed_duration_ms = int((max(timestamps) - min(timestamps)).total_seconds() * 1000)

    summary = {
        "source": ",".join(rel(path) for path in paths) if paths else "none",
        "trace_files": len(paths),
        "total_events": len(records),
        "run_ids": run_ids,
        "status_counts": dict(sorted(status_counts.items())),
        "event_counts": dict(sorted(event_counts.items())),
        "first_timestamp": first_timestamp or "insufficient_data",
        "last_timestamp": last_timestamp or "insufficient_data",
        "observed_duration_ms": observed_duration_ms,
        "duration_ms_count": len(duration_values),
        "duration_ms_total": sum(duration_values) if duration_values else "insufficient_data",
        "duration_ms_min": min(duration_values) if duration_values else "insufficient_data",
        "duration_ms_max": max(duration_values) if duration_values else "insufficient_data",
        "provider_cost": provider_cost,
        "provider_tokens": provider_tokens,
    }
    return summary, errors


def print_summary(summary: dict[str, Any]) -> None:
    statuses = ",".join(f"{key}:{value}" for key, value in summary["status_counts"].items()) or "none"
    events = ",".join(f"{key}:{value}" for key, value in summary["event_counts"].items()) or "none"
    print("Trace Ledger Summary")
    print(f"source={summary['source']}")
    print(
        f"trace_files={summary['trace_files']} events={summary['total_events']} "
        f"run_ids={','.join(summary['run_ids']) or 'none'}"
    )
    print(f"statuses={statuses}")
    print(f"event_counts={events}")
    print(
        f"duration_ms_total={summary['duration_ms_total']} "
        f"observed_duration_ms={summary['observed_duration_ms']}"
    )
    print(f"provider_cost={summary['provider_cost']} provider_tokens={summary['provider_tokens']}")


def fixture_expected(path: pathlib.Path) -> str:
    parts = {part.lower() for part in path.parts}
    if "red" in parts:
        return "fail"
    if "green" in parts:
        return "pass"
    return "pass"


def run_fixtures() -> int:
    if not FIXTURE_DIR.is_dir():
        return fail(f"missing fixture dir: {rel(FIXTURE_DIR)}")
    paths = sorted(FIXTURE_DIR.rglob("*.jsonl"))
    if not paths:
        return fail(f"no trace-ledger fixtures found under {rel(FIXTURE_DIR)}")

    failures = 0
    green_passed = 0
    red_rejected = 0
    for path in paths:
        expected = fixture_expected(path)
        trace_count, event_count, errors = validate_paths([path])
        actual = "fail" if errors else "pass"
        if actual == expected:
            if expected == "pass":
                green_passed += 1
                summary, summary_errors = summarize_events([path])
                if summary_errors or summary["total_events"] != event_count or trace_count != 1:
                    failures += 1
                    print(f"[trace-ledger] {rel(path)} fixture summary failed", file=sys.stderr)
            else:
                red_rejected += 1
            continue
        failures += 1
        detail = "; ".join(errors) if errors else "no validation errors"
        print(f"[trace-ledger] {rel(path)} expected {expected} but got {actual}: {detail}", file=sys.stderr)

    if green_passed < 1:
        failures += 1
        print("[trace-ledger] expected at least 1 green fixture pass", file=sys.stderr)
    if red_rejected < 1:
        failures += 1
        print("[trace-ledger] expected at least 1 red fixture rejection", file=sys.stderr)

    run_id = f"fixture-smoke-{os.getpid()}"
    smoke_dir = TRACE_ROOT / run_id
    try:
        path = append_event(
            {
                "timestamp": now_iso(),
                "run_id": run_id,
                "event": "trace-ledger.fixture",
                "status": "passed",
                "source": "trace-ledger",
                "duration_ms": 1,
                "data": {"fixture": True},
            }
        )
        _, event_count, errors = validate_paths([path])
        summary, summary_errors = summarize_events([path])
        if errors or summary_errors or event_count != 1 or summary["provider_tokens"] != "insufficient_data":
            failures += 1
            print("[trace-ledger] append smoke failed", file=sys.stderr)
    except Exception as exc:
        failures += 1
        print(f"[trace-ledger] append smoke failed: {exc}", file=sys.stderr)
    finally:
        shutil.rmtree(smoke_dir, ignore_errors=True)

    if failures:
        return 1
    print(f"[PASS] trace ledger fixtures passed ({green_passed} green, {red_rejected} red, append smoke ok)")
    return 0


def run_validate(args: list[str]) -> int:
    paths = resolve_targets(args)
    trace_count, event_count, errors = validate_paths(paths)
    if errors:
        for error in errors:
            print(f"[trace-ledger] {error}", file=sys.stderr)
        return 1
    print(f"[PASS] trace ledger validation passed ({trace_count} traces, {event_count} events)")
    return 0


def run_summary(args: list[str]) -> int:
    json_mode = False
    targets: list[str] = []
    for arg in args:
        if arg == "--json":
            json_mode = True
        elif arg in {"-h", "--help"}:
            print("Usage: bash scripts/trace-ledger.sh summary [--json] [PATH_OR_RUN_ID ...]", file=sys.stderr)
            return 0
        elif arg.startswith("--"):
            return fail(f"unknown summary option: {arg}", code=2)
        else:
            targets.append(arg)
    paths = resolve_targets(targets)
    summary, errors = summarize_events(paths)
    if errors:
        for error in errors:
            print(f"[trace-ledger] {error}", file=sys.stderr)
        return 1
    if json_mode:
        print(json.dumps(summary, indent=2, sort_keys=True))
    else:
        print_summary(summary)
    return 0


def run_append(args: list[str]) -> int:
    try:
        event = parse_append_args(args)
        path = append_event(event)
    except Exception as exc:
        return fail(str(exc), code=2)
    print(f"[PASS] appended trace event {rel(path)}")
    return 0


def main() -> int:
    if ARGS == ["--fixtures"]:
        return run_fixtures()
    if ARGS and ARGS[0] == "--fixtures":
        return fail("--fixtures does not accept extra arguments", code=2)
    command = ARGS[0]
    args = ARGS[1:]
    if command == "append":
        return run_append(args)
    if command == "validate":
        return run_validate(args)
    if command == "summary":
        return run_summary(args)
    return fail(f"unknown command: {command}", code=2)


raise SystemExit(main())
PY
