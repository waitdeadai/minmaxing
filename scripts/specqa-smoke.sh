#!/bin/bash
# Static smoke gate for the automated SOTA Spec QA contract.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/specqa"
MODE=""
ARTIFACT_PATH=""

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/specqa-smoke.sh --fixtures
  bash scripts/specqa-smoke.sh --artifact PATH

--fixtures validates the /specqa skill, workflow wiring, eval metadata, release
registration, and deterministic green/red artifacts without making model calls.
--artifact validates one sanitized spec-qa-result JSON artifact.
EOF
}

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing required file: $1"
}

require_executable() {
  [ -x "$1" ] || fail "required script is not executable: $1"
}

require_grep() {
  local pattern="$1"
  local file="$2"
  grep -Fq -- "$pattern" "$file" 2>/dev/null || fail "missing pattern '$pattern' in $file"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--fixtures")
      MODE="fixtures"
      shift
      ;;
    "--artifact")
      MODE="artifact"
      ARTIFACT_PATH="${2:-}"
      [ -n "$ARTIFACT_PATH" ] || {
        usage
        exit 2
      }
      shift 2
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
done

[ -n "$MODE" ] || {
  usage
  exit 2
}

validate_artifact() {
  local artifact="$1"
  python3 - "$artifact" <<'PY'
import json
import pathlib
import re
import sys


path = pathlib.Path(sys.argv[1])

SECRET_RE = re.compile(
    r"(sk-[A-Za-z0-9_-]{20,}|OPENAI_API_KEY\s*=|ANTHROPIC_API_KEY\s*=|"
    r"MINIMAX_API_KEY\s*=|password\s*[:=]|secret\s*[:=]|token\s*[:=]|"
    r"BEGIN [A-Z ]*PRIVATE KEY)",
    re.IGNORECASE,
)

ALLOWED_STATUSES = {"pass", "pass_with_suggestions", "fix_required", "blocked"}
ALLOWED_DECISIONS = {"PASS", "PASS_WITH_SUGGESTIONS", "FIX_REQUIRED", "BLOCKED"}
ALLOWED_EVIDENCE = {"repo-verified", "web-verified", "report-derived", "conflicting", "unverified"}
BLOCKING_DECISIONS = {"FIX_REQUIRED", "BLOCKED"}


def fail(message: str) -> None:
    print(f"[FAIL] {path}: {message}", file=sys.stderr)
    raise SystemExit(1)


try:
    raw = path.read_text(encoding="utf-8")
except FileNotFoundError:
    fail("artifact file does not exist")

if SECRET_RE.search(raw):
    fail("artifact contains secret-like material")

try:
    data = json.loads(raw)
except json.JSONDecodeError as exc:
    fail(f"invalid JSON: {exc}")

if data.get("artifact_type") != "spec-qa-result":
    fail("artifact_type must be spec-qa-result")

status = str(data.get("status", "")).strip()
decision = str(data.get("decision", "")).strip()
if status not in ALLOWED_STATUSES:
    fail(f"status must be one of {sorted(ALLOWED_STATUSES)}")
if decision not in ALLOWED_DECISIONS:
    fail(f"decision must be one of {sorted(ALLOWED_DECISIONS)}")

execution_allowed = data.get("execution_allowed")
if not isinstance(execution_allowed, bool):
    fail("execution_allowed must be boolean")

spec = data.get("spec") or {}
if spec.get("path") != "SPEC.md":
    fail("spec.path must be SPEC.md")
if not re.fullmatch(r"[0-9a-f]{64}", str(spec.get("sha256", ""))):
    fail("spec.sha256 must be a lowercase sha256")
if spec.get("status") not in {"created", "updated", "reused"}:
    fail("spec.status must be created, updated, or reused")

workflow = data.get("workflow_integration") or {}
if workflow.get("runs_after_spec_creation") is not True:
    fail("workflow_integration.runs_after_spec_creation must be true")
if workflow.get("before_implementation") is not True:
    fail("workflow_integration.before_implementation must be true")

model = data.get("model") or {}
if model.get("requested_reviewer") != "claude-opus-4-7":
    fail("model.requested_reviewer must be claude-opus-4-7")
identity_status = str(model.get("identity_status", "")).strip()
if identity_status not in {"proven", "blocked", "unknown"}:
    fail("model.identity_status must be proven, blocked, or unknown")
if model.get("claims_opus_review") is True and identity_status != "proven":
    fail("cannot claim Opus 4.7 reviewed without proven identity")
if identity_status == "proven" and not model.get("proof_source"):
    fail("proven model identity requires proof_source")

research = data.get("current_research") or {}
research_required = research.get("required") is True
sota_target = research.get("sota_target") is True
ledger = research.get("source_ledger") or []
if not isinstance(ledger, list):
    fail("current_research.source_ledger must be a list")
if (research_required or sota_target) and not ledger:
    fail("SOTA or time-sensitive Spec QA requires a source ledger")

for index, source in enumerate(ledger, start=1):
    if not isinstance(source, dict):
        fail(f"source_ledger[{index}] must be an object")
    if not str(source.get("url", "")).startswith(("https://", "http://")):
        fail(f"source_ledger[{index}] missing URL")
    if not source.get("accessed_at"):
        fail(f"source_ledger[{index}] missing accessed_at")
    state = source.get("evidence_state")
    if state not in ALLOWED_EVIDENCE:
        fail(f"source_ledger[{index}] has invalid evidence_state")

findings = data.get("findings") or []
if not isinstance(findings, list):
    fail("findings must be a list")
critical_findings = [
    item for item in findings
    if isinstance(item, dict) and str(item.get("severity", "")).upper() == "CRITICAL"
]
if critical_findings:
    if decision not in BLOCKING_DECISIONS:
        fail("critical findings must force FIX_REQUIRED or BLOCKED")
    if execution_allowed is not False:
        fail("critical findings must set execution_allowed=false")

suggestions = data.get("improvement_suggestions")
if not isinstance(suggestions, list) or not suggestions:
    fail("improvement_suggestions must be a non-empty list")
for index, suggestion in enumerate(suggestions, start=1):
    if not isinstance(suggestion, dict):
        fail(f"improvement_suggestions[{index}] must be an object")
    if not suggestion.get("suggestion"):
        fail(f"improvement_suggestions[{index}] missing suggestion text")
    if str(suggestion.get("severity", "")).upper() not in {"CRITICAL", "HIGH", "MEDIUM", "LOW"}:
        fail(f"improvement_suggestions[{index}] has invalid severity")

artifacts = data.get("artifact_paths") or {}
if not str(artifacts.get("markdown", "")).startswith(".taste/specqa/"):
    fail("artifact_paths.markdown must point under .taste/specqa/")
if not str(artifacts.get("json", "")).startswith(".taste/specqa/"):
    fail("artifact_paths.json must point under .taste/specqa/")
if not str(artifacts.get("markdown", "")).endswith("/spec-qa.md"):
    fail("artifact_paths.markdown must end with /spec-qa.md")
if not str(artifacts.get("json", "")).endswith("/spec-qa.json"):
    fail("artifact_paths.json must end with /spec-qa.json")

security = data.get("security") or {}
if security.get("no_secret_paths_read") is not True:
    fail("security.no_secret_paths_read must be true")

if decision in {"PASS", "PASS_WITH_SUGGESTIONS"} and execution_allowed is not True:
    fail("passing decisions must set execution_allowed=true")
if decision in BLOCKING_DECISIONS and execution_allowed is not False:
    fail("blocking decisions must set execution_allowed=false")

print(f"[PASS] {path}")
PY
}

run_static_contract_checks() {
  local skill="$ROOT_DIR/.claude/skills/specqa/SKILL.md"
  local smoke="$ROOT_DIR/scripts/specqa-smoke.sh"
  local task="$ROOT_DIR/evals/harness/tasks/m13-specqa-sota-gate.yaml"
  local golden="$ROOT_DIR/evals/harness/golden/m13-specqa-sota-gate.json"

  require_file "$skill"
  require_file "$smoke"
  require_file "$task"
  require_file "$golden"
  require_executable "$smoke"

  for pattern in \
    "name: specqa" \
    "disable-model-invocation: true" \
    "# /specqa" \
    "Spec QA Agent" \
    'runs after `SPEC.md` is created or updated and before implementation' \
    "Opus 4.7 high/xhigh reviewer when runtime-proven" \
    "Do not claim Opus 4.7 performed Spec QA unless runtime identity evidence proves it" \
    "webresearched actual-time data" \
    "SOTA 2026" \
    "source ledger" \
    "requirements quality" \
    "improvement suggestions" \
    "Block execution" \
    ".taste/specqa/{run_id}/spec-qa.md" \
    ".taste/specqa/{run_id}/spec-qa.json" \
    "repo-verified" \
    "web-verified" \
    "report-derived" \
    "unverified"; do
    require_grep "$pattern" "$skill"
  done

  for file in \
    "$ROOT_DIR/.claude/skills/workflow/SKILL.md" \
    "$ROOT_DIR/.claude/skills/opusworkflow/SKILL.md" \
    "$ROOT_DIR/.claude/skills/digestflow/SKILL.md" \
    "$ROOT_DIR/.claude/skills/verify/SKILL.md" \
    "$ROOT_DIR/README.md" \
    "$ROOT_DIR/CLAUDE.md" \
    "$ROOT_DIR/AGENTS.md"; do
    require_grep "/specqa" "$file"
    require_grep "Spec QA" "$file"
  done

  require_grep "specqa" "$ROOT_DIR/scripts/harness-capability-map.sh"
  require_grep "specqa-smoke" "$ROOT_DIR/scripts/harness-eval.sh"
  require_grep "specqa-smoke" "$ROOT_DIR/scripts/release-check.sh"
  require_grep "specqa-smoke" "$ROOT_DIR/scripts/test-harness.sh"
  require_grep "m13-specqa-sota-gate" "$task"
  require_grep "m13-specqa-sota-gate" "$golden"
}

run_fixture_checks() {
  run_static_contract_checks

  local green_count=0
  local red_count=0
  local fixture

  for fixture in "$FIXTURE_DIR"/green/*.json; do
    [ -e "$fixture" ] || fail "no green fixtures found"
    validate_artifact "$fixture"
    green_count=$((green_count + 1))
  done

  for fixture in "$FIXTURE_DIR"/red/*.json; do
    [ -e "$fixture" ] || fail "no red fixtures found"
    if validate_artifact "$fixture" >/tmp/specqa-red.out 2>/tmp/specqa-red.err; then
      cat /tmp/specqa-red.out >&2 || true
      fail "red fixture unexpectedly passed: $fixture"
    fi
    red_count=$((red_count + 1))
  done
  rm -f /tmp/specqa-red.out /tmp/specqa-red.err

  [ "$green_count" -ge 1 ] || fail "expected at least one green fixture"
  [ "$red_count" -ge 5 ] || fail "expected at least five red fixtures"
  echo "[PASS] specqa fixtures passed ($green_count green, $red_count red)"
}

case "$MODE" in
  "fixtures")
    run_fixture_checks
    ;;
  "artifact")
    validate_artifact "$ARTIFACT_PATH"
    ;;
esac
