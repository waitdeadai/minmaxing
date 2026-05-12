#!/bin/bash
# Static smoke gate for Claude Code Agent View harness compatibility.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/agent-view"
MODE=""
ARTIFACT_PATH=""

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/agent-view-smoke.sh --fixtures
  bash scripts/agent-view-smoke.sh --artifact PATH

--fixtures validates the Agent View diagnostic route, static doctor, docs,
eval metadata, and deterministic green/red fixtures without opening Agent View.
--artifact validates one sanitized agent-view-readiness JSON artifact.
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
MIN_VERSION = (2, 1, 139)
MIN_VERSION_TEXT = "2.1.139"
SECRET_RE = re.compile(
    r"(sk-[A-Za-z0-9_-]{20,}|OPENAI_API_KEY\s*=|ANTHROPIC_API_KEY\s*=|"
    r"MINIMAX_API_KEY\s*=|password\s*[:=]|secret\s*[:=]|token\s*[:=]|"
    r"BEGIN [A-Z ]*PRIVATE KEY)",
    re.IGNORECASE,
)

REQUIRED_COMMANDS = {
    "claude agents",
    "claude --bg \"<prompt>\"",
    "claude attach <id>",
    "claude logs <id>",
    "claude stop <id>",
    "claude respawn --all",
}

OFFICIAL_SOURCES = {
    "https://code.claude.com/docs/en/agent-view",
    "https://code.claude.com/docs/en/agents",
    "https://code.claude.com/docs/en/permissions",
    "https://claude.com/blog/agent-view-in-claude-code",
}


def fail(message: str) -> None:
    print(f"[FAIL] {path}: {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_version(text: str | None) -> tuple[int, int, int] | None:
    if not text:
        return None
    match = re.search(r"(\d+)\.(\d+)\.(\d+)", text)
    if not match:
        return None
    return tuple(int(part) for part in match.groups())


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

if data.get("artifact_type") != "agent-view-readiness":
    fail("artifact_type must be agent-view-readiness")
if data.get("status") not in {"pass", "warn"}:
    fail("status must be pass or warn for an accepted readiness artifact")
if data.get("native_claude_code_agent_view") is not True:
    fail("native_claude_code_agent_view must be true")
if data.get("runtime_agent_view_started") is not False:
    fail("static artifacts must not start runtime Agent View")
if data.get("runtime_background_session_dispatched") is not False:
    fail("static artifacts must not dispatch background sessions")
if data.get("custom_web_ui_or_proxy") is not False:
    fail("custom_web_ui_or_proxy must be false")
if data.get("api_key_only_auth_allowed") is not False:
    fail("api_key_only_auth_allowed must be false")
if data.get("manual_runtime_evidence_required") is not True:
    fail("manual_runtime_evidence_required must be true")
if data.get("operator_boundary") != "manual_operator_monitor_only":
    fail("operator_boundary must be manual_operator_monitor_only")
if data.get("minimum_required_version") != MIN_VERSION_TEXT:
    fail("minimum_required_version must be 2.1.139")
if data.get("agent_view_equals_remote_control") is not False:
    fail("Agent View must not be equated with Remote Control")
if data.get("agent_view_replaces_parallel") is not False:
    fail("Agent View must not replace /parallel")
if data.get("background_sessions_cloud_durable") is not False:
    fail("background sessions must not be claimed cloud durable")
if data.get("linear_parallel_speedup_claim") is not False:
    fail("linear parallel speedup claims are not allowed")

runtime_proof = str(data.get("runtime_proof_status", "")).strip().lower()
allowed_runtime = {"not_run_static_only", "blocked_by_cli_version", "ready_static_only"}
if runtime_proof not in allowed_runtime:
    fail(f"runtime_proof_status must be one of {sorted(allowed_runtime)}")
if runtime_proof in {"confirmed", "proven", "pass", "passed", "runtime_passed"}:
    fail("static artifact must not claim live Agent View runtime proof")

cli_version = parse_version(data.get("cli_version"))
if runtime_proof == "ready_static_only":
    if cli_version is None or cli_version < MIN_VERSION:
        fail("ready_static_only requires cli_version at or above 2.1.139")
    if data.get("claude_agents_help_kind") != "agent_view":
        fail("ready_static_only requires claude_agents_help_kind=agent_view")

commands = set(data.get("commands") or [])
missing_commands = sorted(REQUIRED_COMMANDS - commands)
if missing_commands:
    fail(f"missing Agent View command evidence: {missing_commands}")

auth = data.get("auth") or {}
if auth.get("requires_paid_claude_code_access") is not True:
    fail("auth.requires_paid_claude_code_access must be true")
if auth.get("api_key_only_supported") is not False:
    fail("auth.api_key_only_supported must be false")
if auth.get("uses_interactive_claude_code_credentials") is not True:
    fail("auth.uses_interactive_claude_code_credentials must be true")

session_model = data.get("session_model") or {}
for key in (
    "local_supervisor_process",
    "sessions_report_only_to_operator",
    "subagents_report_to_parent_conversation",
    "may_use_claude_worktrees",
    "stops_on_sleep_or_shutdown",
):
    if session_model.get(key) is not True:
        fail(f"session_model.{key} must be true")

secrets = data.get("secrets") or {}
if secrets.get("read_secret_files") is not False:
    fail("secrets.read_secret_files must be false")
if secrets.get("read_claude_jobs") is not False:
    fail("secrets.read_claude_jobs must be false")
if secrets.get("read_transcripts") is not False:
    fail("secrets.read_transcripts must be false")
if secrets.get("tokens_in_url") is not False:
    fail("secrets.tokens_in_url must be false")
if secrets.get("secret_values_redacted") is not True:
    fail("secrets.secret_values_redacted must be true")

if data.get("shared_project_env_blockers"):
    fail("shared_project_env_blockers must be empty")

sources = set(data.get("source_ledger") or [])
missing_sources = sorted(OFFICIAL_SOURCES - sources)
if missing_sources:
    fail(f"missing official source ledger entries: {missing_sources}")

for item in data.get("checks") or []:
    if isinstance(item, dict) and item.get("status") == "fail":
        fail(f"readiness check failed: {item.get('id', '<unknown>')}")

print(f"[PASS] {path}")
PY
}

run_static_contract_checks() {
  local skill="$ROOT_DIR/.claude/skills/agent-view/SKILL.md"
  local doctor="$ROOT_DIR/scripts/agent-view-doctor.sh"
  local smoke="$ROOT_DIR/scripts/agent-view-smoke.sh"
  local task="$ROOT_DIR/evals/harness/tasks/m15-agent-view-smoke.yaml"
  local golden="$ROOT_DIR/evals/harness/golden/m15-agent-view-smoke.json"

  require_file "$skill"
  require_file "$doctor"
  require_file "$smoke"
  require_file "$task"
  require_file "$golden"
  require_executable "$doctor"
  require_executable "$smoke"

  for pattern in \
    "name: agent-view" \
    "disable-model-invocation: true" \
    "# /agent-view" \
    "claude agents" \
    "readiness and troubleshooting route only" \
    "does not open" \
    "/remote-control" \
    "/agents" \
    "subagents report back to the parent conversation" \
    "sessions report only to the operator" \
    ".claude/worktrees/" \
    "quota" \
    "stopped by sleep or shutdown" \
    "does not satisfy packet DAG" \
    "bypassPermissions"; do
    require_grep "$pattern" "$skill"
  done

  for pattern in \
    "2.1.139" \
    "CLAUDE_CODE_DISABLE_AGENT_VIEW" \
    "disableAgentView" \
    "runtime_agent_view_started" \
    "blocked_by_cli_version" \
    "ready_static_only" \
    "manual_operator_monitor_only" \
    "claude agents" \
    "claude --bg" \
    "read_claude_jobs" \
    "source_ledger"; do
    require_grep "$pattern" "$doctor"
  done

  for pattern in \
    "agent-view-readiness" \
    "runtime_agent_view_started" \
    "runtime_background_session_dispatched" \
    "agent_view_replaces_parallel" \
    "agent_view_equals_remote_control" \
    "background_sessions_cloud_durable" \
    "linear_parallel_speedup_claim" \
    "2.1.139" \
    "claude agents"; do
    require_grep "$pattern" "$smoke"
  done

  for file in README.md CLAUDE.md AGENTS.md; do
    require_grep "/agent-view" "$ROOT_DIR/$file"
    require_grep "claude agents" "$ROOT_DIR/$file"
    require_grep "Agent View" "$ROOT_DIR/$file"
  done

  require_grep "agent-view" "$ROOT_DIR/scripts/harness-capability-map.sh"
  require_grep "agent-view-smoke" "$ROOT_DIR/scripts/harness-eval.sh"
  require_grep "agent-view-smoke" "$ROOT_DIR/scripts/release-check.sh"
  require_grep "m15-agent-view-smoke" "$task"
  require_grep "m15-agent-view-smoke" "$golden"

  python3 - "$ROOT_DIR/.claude/settings.json" <<'PY'
import json
import pathlib
import sys

data = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
env = data.get("env") or {}
assert "CLAUDE_CODE_DISABLE_AGENT_VIEW" not in env
assert data.get("disableAgentView") is not True
for rule in [
    "Read(./.env)",
    "Read(./.env.*)",
    "Read(./.claude/settings.local.json)",
    "Read(./.claude/*.local.json)",
    "Read(./secrets/**)",
]:
    assert rule in data.get("permissions", {}).get("deny", [])
PY

  local doctor_json
  doctor_json="$(mktemp)"
  trap 'rm -f "${doctor_json:-}"' RETURN
  bash "$doctor" --static --json >"$doctor_json"
  validate_artifact "$doctor_json" >/dev/null
}

run_fixtures() {
  run_static_contract_checks

  local green_count=0
  local red_count=0
  local path

  for path in "$FIXTURE_DIR"/green/*.json; do
    [ -e "$path" ] || fail "missing green agent-view fixtures"
    validate_artifact "$path" >/dev/null
    green_count=$((green_count + 1))
  done

  for path in "$FIXTURE_DIR"/red/*.json; do
    [ -e "$path" ] || fail "missing red agent-view fixtures"
    if validate_artifact "$path" >/dev/null 2>&1; then
      fail "red fixture was accepted: ${path#$ROOT_DIR/}"
    fi
    red_count=$((red_count + 1))
  done

  [ "$green_count" -ge 1 ] || fail "expected at least one green fixture"
  [ "$red_count" -ge 9 ] || fail "expected at least nine red fixtures"

  echo "[PASS] native Claude Code Agent View contract smoke passed"
}

case "$MODE" in
  "fixtures")
    run_fixtures
    ;;
  "artifact")
    validate_artifact "$ARTIFACT_PATH"
    ;;
  *)
    usage
    exit 2
    ;;
esac

