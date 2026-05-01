#!/bin/bash
# Summarize local workflow, trace, and eval artifacts into verified learnings.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="text"
SOURCE="$ROOT_DIR"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/learning-loop.sh [--json] [--fixtures] [PATH]

Summarizes workflow, trace, and eval artifacts. Provider cost, token, ACU, and
calibration data are reported as insufficient_data when unavailable.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--json")
      MODE="json"
      shift
      ;;
    "--fixtures")
      SOURCE="$ROOT_DIR/.taste/fixtures/learning-loop"
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
      SOURCE="$1"
      shift
      ;;
  esac
done

python3 - "$ROOT_DIR" "$SOURCE" "$MODE" <<'PY'
import json
import pathlib
import re
import sys
from collections import Counter, defaultdict
from typing import Any


ROOT = pathlib.Path(sys.argv[1]).resolve()
SOURCE = pathlib.Path(sys.argv[2]).resolve()
MODE = sys.argv[3]


def rel(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def has(text: str, pattern: str) -> bool:
    return re.search(pattern, text, re.IGNORECASE | re.MULTILINE) is not None


def find_files(base: pathlib.Path, patterns: list[str]) -> list[pathlib.Path]:
    files: list[pathlib.Path] = []
    if base.is_file():
        return [base]
    if not base.exists():
        return []
    for pattern in patterns:
        files.extend(path for path in base.rglob(pattern) if path.is_file())
    return sorted(set(files))


def candidate_dirs(source: pathlib.Path, names: list[str]) -> list[pathlib.Path]:
    dirs = []
    for name in names:
        candidate = source / name
        if candidate.is_dir():
            dirs.append(candidate)
    return dirs


def record_failure(taxonomy: Counter[str], evidence: dict[str, list[str]], category: str, path: pathlib.Path) -> None:
    taxonomy[category] += 1
    evidence[category].append(rel(path))


def add_insight(insights: list[dict[str, Any]], insight_id: str, summary: str, evidence: list[str]) -> None:
    if not evidence:
        return
    insights.append(
        {
            "id": insight_id,
            "status": "verified",
            "summary": summary,
            "evidence": sorted(set(evidence)),
        }
    )


def workflow_paths(source: pathlib.Path) -> list[pathlib.Path]:
    paths: list[pathlib.Path] = []
    for directory in candidate_dirs(source, [".taste/workflow-runs", "workflow-runs"]):
        paths.extend(find_files(directory, ["*.md"]))
    if not paths:
        paths.extend(path for path in find_files(source, ["*.md"]) if "workflow" in path.name.lower())
    return sorted(set(paths))


def trace_paths(source: pathlib.Path) -> list[pathlib.Path]:
    paths: list[pathlib.Path] = []
    for directory in candidate_dirs(source, [".taste/traces", "traces"]):
        paths.extend(find_files(directory, ["*.jsonl", "*.json"]))
    if not paths:
        paths.extend(
            path
            for path in find_files(source, ["*.jsonl", "*trace*.json"])
            if "trace" in path.as_posix().lower()
        )
    return sorted(set(paths))


def eval_paths(source: pathlib.Path) -> list[pathlib.Path]:
    paths: list[pathlib.Path] = []
    for directory in candidate_dirs(source, [".taste/evals", "eval-artifacts", "evals"]):
        paths.extend(find_files(directory, ["*.json"]))
    if not paths:
        paths.extend(
            path
            for path in find_files(source, ["*eval*.json", "*scenario*.json", "*harness*.json"])
            if "scenarios/" not in path.as_posix()
        )
    return sorted(set(paths))


def analyze_workflows(paths: list[pathlib.Path], taxonomy: Counter[str], evidence: dict[str, list[str]]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for path in paths:
        text = read_text(path)
        issues: list[str] = []
        if "## Agent-Native Estimate" not in text:
            issues.append("missing_agent_native_estimate")
        if "## Verification Evidence" not in text or has(text, r"## Verification Evidence\s+Pending\.?"):
            issues.append("missing_verification_evidence")
        if "## Outcome" not in text or has(text, r"## Outcome\s+Pending\.?"):
            issues.append("missing_outcome")
        if has(text, r"(tests?|verification|smoke|harness)[^\n]*(failed|fail|error)") and has(
            text, r"(outcome|closeout|status)[^\n]*(verified|complete|completed|ready|pass(ed)?)"
        ):
            issues.append("failed_verification_positive_closeout_risk")
        if has(text, r"(done|complete|verified|ready)[^\n]*(trust me|no evidence|not recorded)"):
            issues.append("evidence_free_closeout_risk")
        if "harness-eval" not in text and "scenario-eval" not in text and "mismatches=0" not in text:
            issues.append("missing_eval_score")
        for issue in issues:
            record_failure(taxonomy, evidence, issue, path)
        records.append(
            {
                "path": rel(path),
                "status": "healthy" if not issues else "unhealthy",
                "issues": issues,
            }
        )
    return records


def load_json_file(path: pathlib.Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def is_eval_artifact(data: Any) -> bool:
    if not isinstance(data, dict):
        return False
    return any(key in data for key in ("scenario_count", "gate_results", "mismatches", "results")) and "status" in data


def reason_category(reason: Any) -> str:
    text = str(reason).lower()
    if "exit_code" in text:
        return "scenario_exit_code_mismatch"
    if "stdout_missing" in text or "stderr_missing" in text:
        return "scenario_expected_output_missing"
    if "stdout_forbidden" in text or "stderr_forbidden" in text:
        return "scenario_forbidden_output_present"
    if "timeout" in text:
        return "scenario_timeout"
    if text.strip():
        return "scenario_eval_failure"
    return "scenario_unknown_failure"


def analyze_evals(paths: list[pathlib.Path], taxonomy: Counter[str], evidence: dict[str, list[str]]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for path in paths:
        try:
            data = load_json_file(path)
        except Exception as exc:
            record_failure(taxonomy, evidence, "invalid_eval_json", path)
            records.append({"path": rel(path), "status": "invalid", "issues": [f"invalid_json: {exc}"]})
            continue
        if not is_eval_artifact(data):
            continue
        issues: list[str] = []
        status = str(data.get("status", "")).lower()
        if status not in {"pass", "healthy"}:
            issues.append("eval_status_not_pass")
            record_failure(taxonomy, evidence, "eval_status_not_pass", path)
        for mismatch in data.get("mismatches", []) or []:
            issues.append("eval_mismatch")
            record_failure(taxonomy, evidence, "eval_mismatch", path)
        for gate in data.get("gate_errors", []) or []:
            issues.append(f"gate_error:{gate}")
            record_failure(taxonomy, evidence, "eval_gate_error", path)
        for result in data.get("results", []) or []:
            if not isinstance(result, dict):
                continue
            if str(result.get("status", "")).lower() != "pass":
                reasons = result.get("reasons") or ["scenario failed without reason"]
                for reason in reasons:
                    category = reason_category(reason)
                    issues.append(category)
                    record_failure(taxonomy, evidence, category, path)
        records.append(
            {
                "path": rel(path),
                "status": "healthy" if not issues else "unhealthy",
                "issues": sorted(set(issues)),
                "reported_status": status or "missing",
            }
        )
    return records


def iter_trace_records(path: pathlib.Path) -> list[dict[str, Any]]:
    if path.suffix == ".jsonl":
        records = []
        for line_no, line in enumerate(read_text(path).splitlines(), start=1):
            if not line.strip():
                continue
            try:
                value = json.loads(line)
            except Exception as exc:
                records.append({"_invalid": f"line {line_no}: {exc}"})
                continue
            records.append(value if isinstance(value, dict) else {"_invalid": f"line {line_no}: not an object"})
        return records
    data = load_json_file(path)
    if isinstance(data, list):
        return [item if isinstance(item, dict) else {"_invalid": "not an object"} for item in data]
    if isinstance(data, dict):
        if isinstance(data.get("events"), list):
            return [item if isinstance(item, dict) else {"_invalid": "not an object"} for item in data["events"]]
        return [data]
    return [{"_invalid": "not an object"}]


def analyze_traces(paths: list[pathlib.Path], taxonomy: Counter[str], evidence: dict[str, list[str]]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for path in paths:
        issues: list[str] = []
        verified_passes = 0
        try:
            trace_records = iter_trace_records(path)
        except Exception as exc:
            record_failure(taxonomy, evidence, "invalid_trace_json", path)
            records.append({"path": rel(path), "status": "invalid", "issues": [f"invalid_json: {exc}"], "events": 0})
            continue
        for item in trace_records:
            if "_invalid" in item:
                issues.append("invalid_trace_record")
                record_failure(taxonomy, evidence, "invalid_trace_record", path)
                continue
            status = str(item.get("status", item.get("outcome", ""))).lower()
            verified = item.get("verified")
            if verified is True and status in {"pass", "passed", "verified", "ok"}:
                verified_passes += 1
            if status in {"fail", "failed", "error", "blocked"}:
                category = str(item.get("failure_category") or item.get("category") or f"trace_{status}").strip()
                issues.append(category)
                record_failure(taxonomy, evidence, category, path)
            if item.get("claim") and verified is not True:
                issues.append("unverified_trace_claim")
                record_failure(taxonomy, evidence, "unverified_trace_claim", path)
        records.append(
            {
                "path": rel(path),
                "status": "healthy" if not issues else "unhealthy",
                "issues": sorted(set(issues)),
                "events": len(trace_records),
                "verified_passes": verified_passes,
            }
        )
    return records


taxonomy: Counter[str] = Counter()
evidence: dict[str, list[str]] = defaultdict(list)

workflows = analyze_workflows(workflow_paths(SOURCE), taxonomy, evidence)
traces = analyze_traces(trace_paths(SOURCE), taxonomy, evidence)
evals = analyze_evals(eval_paths(SOURCE), taxonomy, evidence)

insights: list[dict[str, Any]] = []
healthy_workflows = [record["path"] for record in workflows if record["status"] == "healthy"]
verified_trace_paths = [record["path"] for record in traces if record.get("verified_passes", 0) > 0]
healthy_evals = [record["path"] for record in evals if record["status"] == "healthy"]

add_insight(
    insights,
    "workflow-closeout-backed-by-evidence",
    "Workflow artifacts with Agent-Native Estimate, Verification Evidence, Outcome, and eval score were found.",
    healthy_workflows,
)
add_insight(
    insights,
    "trace-records-include-verified-pass",
    "Trace artifacts include at least one verified passing event.",
    verified_trace_paths,
)
add_insight(
    insights,
    "eval-artifacts-pass-with-local-evidence",
    "Eval artifacts report pass status with machine-readable results.",
    healthy_evals,
)

artifact_count = len(workflows) + len(traces) + len(evals)
failure_taxonomy = [
    {
        "category": category,
        "count": count,
        "evidence": sorted(set(evidence[category])),
    }
    for category, count in sorted(taxonomy.items())
]
status = "insufficient_data" if artifact_count == 0 else ("needs_attention" if failure_taxonomy else "healthy")

payload = {
    "source": rel(SOURCE),
    "status": status,
    "artifact_counts": {
        "workflow": len(workflows),
        "trace": len(traces),
        "eval": len(evals),
    },
    "provider_cost": "insufficient_data",
    "provider_tokens": "insufficient_data",
    "acu": "insufficient_data",
    "estimate_calibration": "insufficient_data",
    "insights": insights,
    "failure_taxonomy": failure_taxonomy,
    "records": {
        "workflows": workflows,
        "traces": traces,
        "evals": evals,
    },
}

if MODE == "json":
    print(json.dumps(payload, indent=2, sort_keys=True))
else:
    counts = payload["artifact_counts"]
    print("Learning Loop")
    print(
        f"source={payload['source']} status={payload['status']} "
        f"workflows={counts['workflow']} traces={counts['trace']} evals={counts['eval']}"
    )
    print("provider_cost=insufficient_data provider_tokens=insufficient_data acu=insufficient_data")
    print(f"verified_insights={len(insights)} failure_categories={len(failure_taxonomy)}")
    for insight in insights:
        print(f"- insight={insight['id']} evidence={len(insight['evidence'])}")
    for item in failure_taxonomy:
        print(f"- failure={item['category']} count={item['count']} evidence={','.join(item['evidence'])}")
PY
