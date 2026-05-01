#!/bin/bash
# Evaluate memory freshness and known critical repo facts.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_EVAL="$ROOT_DIR/evals/memory/known-prior-decisions.json"
EVAL_DIR="$ROOT_DIR/evals/memory"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/memory-eval.sh [--summary|--json] [EVAL_JSON]
  bash scripts/memory-eval.sh --fixtures

The eval checks known prior decisions against flat-file memory and reports
whether degraded memory should fall back to local truth surfaces.
EOF
}

MODE="summary"
RUN_FIXTURES=0
EVAL_PATH="$DEFAULT_EVAL"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --summary)
      MODE="summary"
      shift
      ;;
    --json)
      MODE="json"
      shift
      ;;
    --fixtures)
      RUN_FIXTURES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      EVAL_PATH="$1"
      shift
      ;;
  esac
done

python3 - "$ROOT_DIR" "$EVAL_DIR" "$EVAL_PATH" "$MODE" "$RUN_FIXTURES" <<'PY'
import datetime as dt
import json
import pathlib
import re
import subprocess
import sys
from typing import Any


ROOT = pathlib.Path(sys.argv[1])
EVAL_DIR = pathlib.Path(sys.argv[2])
EVAL_PATH = pathlib.Path(sys.argv[3])
MODE = sys.argv[4]
RUN_FIXTURES = sys.argv[5] == "1"


def rel(path: pathlib.Path) -> str:
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def load_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"{rel(path)} must be a JSON object")
    return data


def as_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def read_text(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""


def memory_health() -> str:
    script = ROOT / "scripts" / "memory.sh"
    try:
        output = subprocess.run(["bash", str(script), "health"], cwd=ROOT, text=True, capture_output=True, check=False)
    except Exception:
        return "disabled"
    match = re.search(r"status:\s*(healthy|degraded|disabled)", output.stdout + "\n" + output.stderr)
    return match.group(1) if match else "disabled"


def parse_dates(text: str) -> list[dt.date]:
    dates: list[dt.date] = []
    for match in re.finditer(r"^date:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})\s*$", text, re.MULTILINE):
        try:
            dates.append(dt.date.fromisoformat(match.group(1)))
        except ValueError:
            pass
    return dates


def source_paths(case: dict[str, Any]) -> list[pathlib.Path]:
    paths = []
    for source in as_list(case.get("sources")):
        path = ROOT / str(source)
        paths.append(path)
    if paths:
        return paths
    return sorted((ROOT / "obsidian" / "Memory").rglob("*.md"))


def evaluate_case(case: dict[str, Any]) -> dict[str, Any]:
    paths = source_paths(case)
    texts = [(path, read_text(path)) for path in paths]
    corpus = "\n".join(text for _, text in texts)
    errors: list[str] = []

    required_any = [str(item) for item in as_list(case.get("required_any"))]
    required_all = [str(item) for item in as_list(case.get("required_all"))]
    if required_any and not any(item in corpus for item in required_any):
        errors.append("required_any terms were not recalled")
    missing_all = [item for item in required_all if item not in corpus]
    if missing_all:
        errors.append("missing required_all terms: " + ", ".join(missing_all))

    max_age_days = case.get("max_age_days")
    if isinstance(max_age_days, int) and max_age_days >= 0:
        all_dates: list[dt.date] = []
        for _, text in texts:
            all_dates.extend(parse_dates(text))
        if not all_dates:
            errors.append("no frontmatter date found for freshness check")
        else:
            newest = max(all_dates)
            age_days = (dt.date.today() - newest).days
            if age_days > max_age_days:
                errors.append(f"memory fact is stale: age_days={age_days} max_age_days={max_age_days}")

    missing_sources = [rel(path) for path, text in texts if not text]
    if missing_sources:
        errors.append("missing source files: " + ", ".join(missing_sources))

    return {
        "id": str(case.get("id", "unnamed")),
        "query": str(case.get("query", "")),
        "status": "fail" if errors else "pass",
        "sources": [rel(path) for path, _ in texts],
        "errors": errors,
    }


def evaluate_privacy_guard(config: dict[str, Any]) -> dict[str, Any]:
    guard = config.get("privacy_guard") if isinstance(config.get("privacy_guard"), dict) else {}
    paths = [ROOT / str(path) for path in as_list(guard.get("paths"))] or [ROOT / "obsidian" / "Memory"]
    patterns = [str(pattern) for pattern in as_list(guard.get("forbidden_regex"))]
    hits: list[str] = []
    for base in paths:
        files = sorted(base.rglob("*")) if base.is_dir() else [base]
        for path in files:
            if not path.is_file():
                continue
            text = read_text(path)
            for pattern in patterns:
                if re.search(pattern, text):
                    hits.append(f"{rel(path)} matches {pattern}")
    return {
        "status": "fail" if hits else "pass",
        "hits": hits,
    }


def evaluate(path: pathlib.Path) -> dict[str, Any]:
    config = load_json(path)
    health = memory_health()
    case_results = [evaluate_case(case) for case in as_list(config.get("cases")) if isinstance(case, dict)]
    privacy = evaluate_privacy_guard(config)
    errors = [error for case in case_results for error in case["errors"]]
    errors.extend(privacy["hits"])
    passed_cases = sum(1 for case in case_results if case["status"] == "pass")
    status = "fail" if errors or not case_results else "pass"
    return {
        "status": status,
        "eval": rel(path),
        "memory_health": health,
        "fallback": "local_truth_surfaces" if health in {"degraded", "disabled"} else "memory_and_local_truth",
        "case_count": len(case_results),
        "passed_cases": passed_cases,
        "failed_cases": len(case_results) - passed_cases,
        "cases": case_results,
        "privacy_guard": privacy,
        "errors": errors,
    }


def expected(path: pathlib.Path) -> str:
    try:
        data = load_json(path)
        value = str(data.get("expected_result", "")).strip().lower()
        if value in {"pass", "fail"}:
            return value
    except Exception:
        pass
    return "fail" if path.name.startswith("red-") else "pass"


def run_fixtures() -> int:
    paths = sorted(EVAL_DIR.glob("*.json"))
    if not paths:
        print("[FAIL] no memory eval fixtures found", file=sys.stderr)
        return 1
    failures = 0
    green = 0
    red = 0
    for path in paths:
        result = evaluate(path)
        actual = result["status"]
        wanted = expected(path)
        if actual == wanted:
            if actual == "pass":
                green += 1
            else:
                red += 1
            continue
        failures += 1
        print(
            f"[memory-eval] {rel(path)} expected {wanted} but got {actual}: "
            + "; ".join(result["errors"]),
            file=sys.stderr,
        )
    if green < 1:
        failures += 1
        print("[memory-eval] expected at least one passing fixture", file=sys.stderr)
    if red < 2:
        failures += 1
        print("[memory-eval] expected at least two rejected fixtures", file=sys.stderr)
    if failures:
        return 1
    print(f"[PASS] memory eval fixtures passed ({green} green, {red} red)")
    return 0


if RUN_FIXTURES:
    raise SystemExit(run_fixtures())

result = evaluate(EVAL_PATH)
if MODE == "json":
    print(json.dumps(result, sort_keys=True))
else:
    print(
        "memory freshness: "
        f"{result['status']} "
        f"health={result['memory_health']} "
        f"cases={result['passed_cases']}/{result['case_count']} "
        f"fallback={result['fallback']}"
    )
    for case in result["cases"]:
        if case["status"] != "pass":
            print(f"  [FAIL] {case['id']}: {'; '.join(case['errors'])}")

raise SystemExit(0 if result["status"] == "pass" else 1)
PY
