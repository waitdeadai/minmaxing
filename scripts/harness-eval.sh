#!/bin/bash
# Run the local static harness eval pack.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_DIR="$ROOT_DIR/evals/harness/tasks"
GOLDEN_DIR="$ROOT_DIR/evals/harness/golden"
MODE="text"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/harness-eval.sh
  bash scripts/harness-eval.sh --json
  bash scripts/harness-eval.sh --metadata-json

Validates evals/harness/tasks/*.yaml against matching golden JSON, then runs
each unique known gate once.
EOF
}

case "${1:-}" in
  "")
    ;;
  "--json")
    MODE="json"
    ;;
  "--metadata-json")
    MODE="metadata-json"
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

metadata_json() {
  python3 - "$ROOT_DIR" <<'PY'
import json
import pathlib
import re
import sys
from typing import Any


ROOT = pathlib.Path(sys.argv[1]).resolve()
TASK_DIR = ROOT / "evals" / "harness" / "tasks"
GOLDEN_DIR = ROOT / "evals" / "harness" / "golden"
KNOWN_GATES = {
    "estimate-smoke",
    "parallel-plan-lint",
    "hook-smoke",
    "harness-scorecard",
    "artifact-lint",
    "codex-run-smoke",
    "agentfactory-smoke",
    "digestflow-static",
    "spec-archive-smoke",
}
VALID_RESULTS = {"pass", "reject", "accept", "fail", "skip", "blocked"}
VALID_GATE_STATUSES = {"pass", "fail", "skip", "blocked"}
ID_RE = re.compile(r"^[a-z0-9][a-z0-9_.-]*$")


def rel(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def strip_inline_comment(value: str) -> str:
    quote = ""
    escaped = False
    out: list[str] = []
    for char in value:
        if escaped:
            out.append(char)
            escaped = False
            continue
        if char == "\\" and quote == '"':
            out.append(char)
            escaped = True
            continue
        if char in {'"', "'"}:
            if not quote:
                quote = char
            elif quote == char:
                quote = ""
            out.append(char)
            continue
        if char == "#" and not quote:
            break
        out.append(char)
    return "".join(out).strip()


def parse_scalar(raw: str, path: pathlib.Path, line_no: int) -> str:
    value = strip_inline_comment(raw)
    if not value:
        raise ValueError(f"{rel(path)}:{line_no}: empty values and nested YAML are not supported")
    if value[0] in {'"', "'"}:
        if len(value) < 2 or value[-1] != value[0]:
            raise ValueError(f"{rel(path)}:{line_no}: unterminated quoted scalar")
        quote = value[0]
        inner = value[1:-1]
        if quote == '"':
            try:
                return bytes(inner, "utf-8").decode("unicode_escape")
            except UnicodeDecodeError as exc:
                raise ValueError(f"{rel(path)}:{line_no}: invalid escape in quoted scalar: {exc}") from exc
        return inner.replace("''", "'")
    return value


def parse_task_yaml(path: pathlib.Path) -> dict[str, str]:
    data: dict[str, str] = {}
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if line[:1].isspace():
            raise ValueError(f"{rel(path)}:{line_no}: nested YAML is not supported for eval task metadata")
        if ":" not in line:
            raise ValueError(f"{rel(path)}:{line_no}: expected key: value")
        key, raw_value = line.split(":", 1)
        key = key.strip()
        if not key:
            raise ValueError(f"{rel(path)}:{line_no}: empty key")
        if key in data:
            raise ValueError(f"{rel(path)}:{line_no}: duplicate key: {key}")
        data[key] = parse_scalar(raw_value, path, line_no)
    return data


def is_relative_to(path: pathlib.Path, parent: pathlib.Path) -> bool:
    try:
        path.resolve().relative_to(parent.resolve())
    except ValueError:
        return False
    return True


def resolve_golden(raw: str) -> pathlib.Path:
    if pathlib.PurePosixPath(raw).is_absolute() or pathlib.PureWindowsPath(raw).is_absolute():
        raise ValueError(f"golden path must be repo-relative, got {raw}")
    normalized = raw.strip().replace("\\", "/")
    if normalized.startswith("../") or "/../" in normalized or normalized == "..":
        raise ValueError(f"golden path must stay under evals/harness/golden, got {raw}")
    if normalized.startswith("evals/harness/golden/"):
        path = ROOT / normalized
    elif normalized.startswith("golden/"):
        path = GOLDEN_DIR / normalized[len("golden/") :]
    else:
        path = GOLDEN_DIR / normalized
    if not is_relative_to(path, GOLDEN_DIR):
        raise ValueError(f"golden path must stay under evals/harness/golden, got {raw}")
    return path


def normalize_result(value: Any) -> str:
    text = str(value or "").strip().lower().replace("_", "-")
    aliases = {
        "passed": "pass",
        "ok": "pass",
        "green": "pass",
        "failed": "fail",
        "red": "fail",
        "error": "fail",
        "skipped": "skip",
        "rejected": "reject",
        "blocked-reject": "reject",
        "accepted": "accept",
    }
    return aliases.get(text, text)


def normalize_gate_status(value: Any) -> str:
    text = str(value or "").strip().lower().replace("_", "-")
    aliases = {
        "passed": "pass",
        "ok": "pass",
        "green": "pass",
        "failed": "fail",
        "red": "fail",
        "error": "fail",
        "skipped": "skip",
    }
    return aliases.get(text, text)


def normalize_gate(value: str) -> str:
    gate = " ".join(value.strip().split())
    aliases = {
        "estimate-smoke": "estimate-smoke",
        "scripts/estimate-smoke.sh": "estimate-smoke",
        "bash scripts/estimate-smoke.sh": "estimate-smoke",
        "parallel-plan-lint": "parallel-plan-lint",
        "scripts/parallel-plan-lint.sh": "parallel-plan-lint",
        "scripts/parallel-plan-lint.sh --fixtures": "parallel-plan-lint",
        "bash scripts/parallel-plan-lint.sh --fixtures": "parallel-plan-lint",
        "hook-smoke": "hook-smoke",
        "scripts/hook-smoke.sh": "hook-smoke",
        "bash scripts/hook-smoke.sh": "hook-smoke",
        "harness-scorecard": "harness-scorecard",
        "scripts/harness-scorecard.sh": "harness-scorecard",
        "scripts/harness-scorecard.sh --json": "harness-scorecard",
        "bash scripts/harness-scorecard.sh --json": "harness-scorecard",
        "artifact-lint": "artifact-lint",
        "scripts/artifact-lint.sh": "artifact-lint",
        "scripts/artifact-lint.sh --fixtures": "artifact-lint",
        "bash scripts/artifact-lint.sh --fixtures": "artifact-lint",
        "codex-run-smoke": "codex-run-smoke",
        "scripts/codex-run-smoke.sh": "codex-run-smoke",
        "bash scripts/codex-run-smoke.sh": "codex-run-smoke",
        "agentfactory-smoke": "agentfactory-smoke",
        "scripts/agentfactory-smoke.sh": "agentfactory-smoke",
        "bash scripts/agentfactory-smoke.sh": "agentfactory-smoke",
        "digestflow-static": "digestflow-static",
        "digestflow-smoke": "digestflow-static",
        "scripts/digestflow-smoke.sh": "digestflow-static",
        "bash scripts/digestflow-smoke.sh": "digestflow-static",
        "spec-archive-smoke": "spec-archive-smoke",
        "scripts/spec-archive.sh": "spec-archive-smoke",
        "scripts/test-harness.sh": "spec-archive-smoke",
        "bash scripts/test-harness.sh": "spec-archive-smoke",
    }
    return aliases.get(gate, gate)


def golden_status(data: dict[str, Any]) -> str:
    for key in ("status", "expected_result", "expected_status"):
        if key in data:
            return normalize_result(data[key])
    return ""


def golden_gate_status(data: dict[str, Any]) -> str:
    for key in ("gate_status", "expected_gate_status", "expected_command_status"):
        if key in data:
            return normalize_gate_status(data[key])
    return "pass"


def golden_id(data: dict[str, Any]) -> str:
    for key in ("id", "task_id"):
        if key in data:
            return str(data[key]).strip()
    return ""


def golden_evidence(data: dict[str, Any]) -> Any:
    for key in ("evidence_summary", "expected_evidence", "evidence", "summary"):
        if key in data:
            return data[key]
    return None


def present(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value.strip()) and value.strip().lower() not in {"none", "n/a", "null", "missing"}
    if isinstance(value, (list, tuple, dict, set)):
        return bool(value)
    return True


errors: list[str] = []
if not TASK_DIR.is_dir():
    errors.append(f"Missing eval task directory: {rel(TASK_DIR)}")
if not GOLDEN_DIR.is_dir():
    errors.append(f"Missing eval golden directory: {rel(GOLDEN_DIR)}")

task_paths = sorted(TASK_DIR.glob("*.yaml")) if TASK_DIR.is_dir() else []
if TASK_DIR.is_dir() and not task_paths:
    errors.append(f"No eval task metadata found: {rel(TASK_DIR)}/*.yaml")

tasks: list[dict[str, str]] = []
seen_ids: set[str] = set()
seen_golden_paths: set[pathlib.Path] = set()
gates: list[str] = []

for path in task_paths:
    try:
        data = parse_task_yaml(path)
    except Exception as exc:
        errors.append(str(exc))
        continue

    required = ("id", "title", "gate", "expected_result", "golden")
    for key in required:
        if not data.get(key, "").strip():
            errors.append(f"{rel(path)}: missing required field: {key}")
    if any(not data.get(key, "").strip() for key in required):
        continue

    task_id = data["id"].strip()
    gate_raw = data["gate"].strip()
    gate = normalize_gate(gate_raw)
    expected_result = normalize_result(data["expected_result"])

    if not ID_RE.match(task_id):
        errors.append(f"{rel(path)}: id must match {ID_RE.pattern}: {task_id}")
    if task_id in seen_ids:
        errors.append(f"{rel(path)}: duplicate eval task id: {task_id}")
    seen_ids.add(task_id)

    if gate not in KNOWN_GATES:
        errors.append(f"{rel(path)}: unknown gate '{gate_raw}'")
    elif gate not in gates:
        gates.append(gate)

    if expected_result not in VALID_RESULTS:
        errors.append(f"{rel(path)}: expected_result must be one of {sorted(VALID_RESULTS)}, got {data['expected_result']}")

    try:
        golden_path = resolve_golden(data["golden"])
    except Exception as exc:
        errors.append(f"{rel(path)}: {exc}")
        continue

    if golden_path in seen_golden_paths:
        errors.append(f"{rel(path)}: duplicate golden reference: {rel(golden_path)}")
    seen_golden_paths.add(golden_path)

    if not golden_path.is_file():
        errors.append(f"{rel(path)}: missing golden JSON: {rel(golden_path)}")
        continue

    try:
        golden_data = json.loads(golden_path.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{rel(golden_path)}: invalid JSON: {exc}")
        continue
    if not isinstance(golden_data, dict):
        errors.append(f"{rel(golden_path)}: golden JSON must be an object")
        continue

    gid = golden_id(golden_data)
    if gid != task_id:
        errors.append(f"{rel(golden_path)}: golden id '{gid or '<missing>'}' does not match task id '{task_id}'")

    golden_gate_raw = str(golden_data.get("gate", "")).strip()
    golden_gate = normalize_gate(golden_gate_raw)
    if golden_gate_raw != gate_raw and golden_gate != gate:
        errors.append(f"{rel(golden_path)}: golden gate '{golden_gate_raw or '<missing>'}' does not match task gate '{gate_raw}'")

    gstatus = golden_status(golden_data)
    if gstatus not in VALID_RESULTS:
        errors.append(f"{rel(golden_path)}: golden status must be one of {sorted(VALID_RESULTS)}")
    elif gstatus != expected_result:
        errors.append(
            f"{rel(golden_path)}: golden status '{gstatus}' does not match task expected_result '{expected_result}'"
        )

    ggate_status = golden_gate_status(golden_data)
    if ggate_status not in VALID_GATE_STATUSES:
        errors.append(f"{rel(golden_path)}: golden gate status must be one of {sorted(VALID_GATE_STATUSES)}")

    if not present(golden_evidence(golden_data)):
        errors.append(f"{rel(golden_path)}: golden JSON missing evidence_summary/expected_evidence/evidence/summary")

    tasks.append(
        {
            "id": task_id,
            "title": data["title"].strip(),
            "gate": gate,
            "gate_label": gate_raw,
            "expected_result": expected_result,
            "expected_gate_status": ggate_status,
            "task_file": rel(path),
            "golden_file": rel(golden_path),
        }
    )

if GOLDEN_DIR.is_dir():
    referenced = {path.resolve() for path in seen_golden_paths}
    for path in sorted(GOLDEN_DIR.glob("*.json")):
        if path.resolve() not in referenced:
            errors.append(f"{rel(path)}: golden JSON is not referenced by any eval task")

if errors:
    for error in errors:
        print(f"[harness-eval] {error}", file=sys.stderr)
    raise SystemExit(1)

print(
    json.dumps(
        {
            "task_dir": rel(TASK_DIR),
            "golden_dir": rel(GOLDEN_DIR),
            "tasks": tasks,
            "gates": gates,
        },
        indent=2,
        sort_keys=True,
    )
)
PY
}

require_gate_script() {
  local script="$1"
  if [ ! -f "$ROOT_DIR/$script" ]; then
    echo "[harness-eval] missing gate script: $script" >&2
    return 125
  fi
}

run_spec_archive_smoke() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${SPEC_ARCHIVE_EVAL_TMP:-}"' RETURN
  SPEC_ARCHIVE_EVAL_TMP="$tmp_dir"

  cat > "$tmp_dir/SPEC.md" <<'EOF'
# SPEC: Archive Demo

## Problem Statement
Preserve this completed spec.
EOF

  CLAUDE_PROJECT_DIR="$tmp_dir" bash "$ROOT_DIR/scripts/spec-archive.sh" closeout "Archive Demo" "verified accept" >/dev/null

  local archive_count
  local archive_file
  archive_count="$(find "$tmp_dir/.taste/specs" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')"
  archive_file="$(find "$tmp_dir/.taste/specs" -maxdepth 1 -type f -name "*.md" 2>/dev/null | head -n 1)"
  [ "$archive_count" = "1" ] || {
    echo "[harness-eval] expected one archived spec after closeout, got $archive_count" >&2
    return 1
  }
  [ -n "$archive_file" ] || {
    echo "[harness-eval] missing archive file after closeout" >&2
    return 1
  }
  basename "$archive_file" | grep -Eq "archive-demo.*verified-accept"
  grep -Fq 'reason: "closeout"' "$archive_file"
  grep -Fq 'outcome: "verified accept"' "$archive_file"
  grep -Fq 'source_sha256:' "$archive_file"
  grep -Fq '# SPEC: Archive Demo' "$archive_file"

  CLAUDE_PROJECT_DIR="$tmp_dir" bash "$ROOT_DIR/scripts/spec-archive.sh" closeout "Archive Demo" "verified accept" >/dev/null
  archive_count="$(find "$tmp_dir/.taste/specs" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')"
  [ "$archive_count" = "1" ] || {
    echo "[harness-eval] duplicate closeout archive was not deduplicated" >&2
    return 1
  }

  cat > "$tmp_dir/SPEC.md" <<'EOF'
# SPEC: Next Active Contract

## Problem Statement
This spec is about to be replaced.
EOF

  CLAUDE_PROJECT_DIR="$tmp_dir" bash "$ROOT_DIR/scripts/spec-archive.sh" prepare "New Work" "superseded-before-new-spec" >/dev/null
  archive_count="$(find "$tmp_dir/.taste/specs" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')"
  [ "$archive_count" = "2" ] || {
    echo "[harness-eval] prepare archive did not create the second archived spec" >&2
    return 1
  }
  CLAUDE_PROJECT_DIR="$tmp_dir" bash "$ROOT_DIR/scripts/spec-archive.sh" status 2>/dev/null | grep -Fq ".taste/specs/"

  echo "[PASS] SPEC archive lifecycle smoke test passed"
}

run_digestflow_static_smoke() {
  local skill="$ROOT_DIR/.claude/skills/digestflow/SKILL.md"
  local smoke="$ROOT_DIR/scripts/digestflow-smoke.sh"
  local agents="$ROOT_DIR/AGENTS.md"
  local readme="$ROOT_DIR/README.md"

  [ -f "$skill" ] || {
    echo "[harness-eval] missing digestflow skill" >&2
    return 1
  }
  [ -f "$smoke" ] || {
    echo "[harness-eval] missing digestflow smoke script" >&2
    return 1
  }

  for pattern in \
    "Report Intake" \
    "untrusted candidate evidence" \
    "report-derived" \
    "no-persist report bodies" \
    "Injection Quarantine" \
    "prompt-like instructions"; do
    grep -Fq "$pattern" "$skill" || {
      echo "[harness-eval] digestflow skill missing pattern: $pattern" >&2
      return 1
    }
  done

  grep -Fq "report-derived" "$smoke" || {
    echo "[harness-eval] digestflow smoke lacks report-derived assertion" >&2
    return 1
  }
  grep -Fq "Injection Quarantine" "$smoke" || {
    echo "[harness-eval] digestflow smoke lacks injection quarantine assertion" >&2
    return 1
  }
  grep -Fq "untrusted candidate evidence" "$agents" || {
    echo "[harness-eval] AGENTS.md lacks digestflow untrusted evidence guidance" >&2
    return 1
  }
  grep -Fq "report-derived" "$readme" || {
    echo "[harness-eval] README lacks digestflow report-derived guidance" >&2
    return 1
  }

  echo "[PASS] digestflow static report-derived evidence contract passed"
}

run_gate() {
  local gate="$1"
  case "$gate" in
    "estimate-smoke")
      require_gate_script "scripts/estimate-smoke.sh" || return $?
      bash "$ROOT_DIR/scripts/estimate-smoke.sh"
      ;;
    "parallel-plan-lint")
      require_gate_script "scripts/parallel-plan-lint.sh" || return $?
      bash "$ROOT_DIR/scripts/parallel-plan-lint.sh" --fixtures
      ;;
    "hook-smoke")
      require_gate_script "scripts/hook-smoke.sh" || return $?
      bash "$ROOT_DIR/scripts/hook-smoke.sh"
      ;;
    "harness-scorecard")
      require_gate_script "scripts/harness-scorecard.sh" || return $?
      bash "$ROOT_DIR/scripts/harness-scorecard.sh" --json
      ;;
    "artifact-lint")
      require_gate_script "scripts/artifact-lint.sh" || return $?
      bash "$ROOT_DIR/scripts/artifact-lint.sh" --fixtures
      ;;
    "codex-run-smoke")
      require_gate_script "scripts/codex-run-smoke.sh" || return $?
      bash "$ROOT_DIR/scripts/codex-run-smoke.sh"
      ;;
    "agentfactory-smoke")
      require_gate_script "scripts/agentfactory-smoke.sh" || return $?
      bash "$ROOT_DIR/scripts/agentfactory-smoke.sh"
      ;;
    "digestflow-static")
      run_digestflow_static_smoke
      ;;
    "spec-archive-smoke")
      require_gate_script "scripts/spec-archive.sh" || return $?
      run_spec_archive_smoke
      ;;
    *)
      echo "[harness-eval] unknown gate at runtime: $gate" >&2
      return 125
      ;;
  esac
}

classify_status() {
  local exit_code="$1"
  local output_file="$2"

  if [ "$exit_code" -eq 125 ]; then
    printf 'error\n'
  elif [ "$exit_code" -eq 0 ]; then
    if grep -Eiq '(^|[[:space:]])SKIP(:|[[:space:]]|$)|\[[^]]+\][[:space:]]*SKIP' "$output_file"; then
      printf 'skip\n'
    else
      printf 'pass\n'
    fi
  else
    printf 'fail\n'
  fi
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
METADATA_FILE="$TMP_DIR/metadata.json"
RESULTS_FILE="$TMP_DIR/results.tsv"

if ! metadata_json > "$METADATA_FILE"; then
  exit 1
fi

if [ "$MODE" = "metadata-json" ]; then
  cat "$METADATA_FILE"
  exit 0
fi

mapfile -t GATES < <(
  python3 - "$METADATA_FILE" <<'PY'
import json
import sys

data = json.loads(open(sys.argv[1], encoding="utf-8").read())
for gate in data["gates"]:
    print(gate)
PY
)

: > "$RESULTS_FILE"

if [ "$MODE" = "text" ]; then
  task_count="$(python3 - "$METADATA_FILE" <<'PY'
import json
import sys

print(len(json.loads(open(sys.argv[1], encoding="utf-8").read())["tasks"]))
PY
)"
  echo "Harness Eval"
  echo "Tasks: $task_count | gates: ${#GATES[@]}"
fi

for gate in "${GATES[@]}"; do
  output_file="$TMP_DIR/${gate//[^a-zA-Z0-9_.-]/_}.out"
  set +e
  run_gate "$gate" >"$output_file" 2>&1
  exit_code=$?
  set -e
  status="$(classify_status "$exit_code" "$output_file")"
  printf '%s\t%s\t%s\n' "$gate" "$status" "$exit_code" >> "$RESULTS_FILE"

  if [ "$MODE" = "text" ]; then
    echo "[harness-eval] gate=$gate status=$status exit=$exit_code"
    if [ "$status" = "fail" ] || [ "$status" = "error" ]; then
      sed -n '1,40p' "$output_file" | sed 's/^/[harness-eval output] /' >&2
    fi
  fi
done

python3 - "$METADATA_FILE" "$RESULTS_FILE" "$MODE" <<'PY'
import json
import sys
from collections import Counter


metadata_path, results_path, mode = sys.argv[1:4]
metadata = json.loads(open(metadata_path, encoding="utf-8").read())
results = {}
for raw in open(results_path, encoding="utf-8"):
    gate, status, exit_code = raw.rstrip("\n").split("\t")
    results[gate] = {"status": status, "exit_code": int(exit_code)}

mismatches = []
for task in metadata["tasks"]:
    actual = results[task["gate"]]["status"]
    if actual != task["expected_gate_status"]:
        mismatches.append(
            {
                "id": task["id"],
                "gate": task["gate"],
                "expected_gate_status": task["expected_gate_status"],
                "expected_result": task["expected_result"],
                "actual_status": actual,
            }
        )

result_counts = Counter(task["expected_result"] for task in metadata["tasks"])
gate_status_expectations = Counter(task["expected_gate_status"] for task in metadata["tasks"])
gate_status_counts: dict[str, Counter[str]] = {}
for task in metadata["tasks"]:
    gate_status_counts.setdefault(task["gate"], Counter())[task["expected_result"]] += 1

gate_errors = [gate for gate, result in results.items() if result["status"] == "error"]
overall = "pass" if not mismatches and not gate_errors else "fail"

payload = {
    "status": overall,
    "tasks": len(metadata["tasks"]),
    "gates": len(metadata["gates"]),
    "expected_result_counts": dict(sorted(result_counts.items())),
    "expected_gate_status_counts": dict(sorted(gate_status_expectations.items())),
    "gate_expected_result_counts": {
        gate: dict(sorted(counts.items())) for gate, counts in sorted(gate_status_counts.items())
    },
    "gate_results": results,
    "mismatches": mismatches,
    "gate_errors": gate_errors,
}

if mode == "json":
    print(json.dumps(payload, indent=2, sort_keys=True))
else:
    print(
        "Summary: "
        f"status={overall} tasks={payload['tasks']} gates={payload['gates']} "
        f"mismatches={len(mismatches)} gate_errors={len(gate_errors)}"
    )
    if mismatches:
        for mismatch in mismatches:
            print(
                "[harness-eval] mismatch "
                f"id={mismatch['id']} gate={mismatch['gate']} "
                f"expected_gate={mismatch['expected_gate_status']} "
                f"expected_result={mismatch['expected_result']} actual={mismatch['actual_status']}",
                file=sys.stderr,
            )
    if gate_errors:
        print(f"[harness-eval] infrastructure gate errors: {', '.join(gate_errors)}", file=sys.stderr)

raise SystemExit(0 if overall == "pass" else 1)
PY
