#!/bin/bash
# Static smoke gate for Claude Code native Remote Control harness compatibility.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/remote-control"
MODE=""
ARTIFACT_PATH=""

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/remote-control-smoke.sh --fixtures
  bash scripts/remote-control-smoke.sh --artifact PATH

--fixtures validates the native Remote Control route, static doctor, docs,
eval metadata, and deterministic green/red fixtures without starting RC.
--artifact validates one sanitized remote-control-readiness JSON artifact.
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

require_not_grep() {
  local pattern="$1"
  local file="$2"
  if grep -Fq -- "$pattern" "$file" 2>/dev/null; then
    fail "forbidden pattern '$pattern' found in $file"
  fi
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

REQUIRED_COMMANDS = {
    "/remote-control",
    "/rc",
    "claude --remote-control",
    "claude remote-control",
}


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

if data.get("artifact_type") != "remote-control-readiness":
    fail("artifact_type must be remote-control-readiness")
if data.get("status") not in {"pass", "warn"}:
    fail("status must be pass or warn for an accepted readiness artifact")
if data.get("native_claude_code_remote_control") is not True:
    fail("native_claude_code_remote_control must be true")
if data.get("custom_network_control_plane") is not False:
    fail("custom_network_control_plane must be false")
if data.get("api_key_auth_allowed") is not False:
    fail("api_key_auth_allowed must be false")
if data.get("runtime_remote_control_started") is not False:
    fail("static artifacts must not start runtime Remote Control")

runtime_proof = str(data.get("runtime_proof_status", "")).strip().lower()
if runtime_proof in {"confirmed", "proven", "pass", "passed", "runtime_passed"}:
    fail("static artifact must not claim live Remote Control runtime proof")

commands = set(data.get("commands") or [])
missing_commands = sorted(REQUIRED_COMMANDS - commands)
if missing_commands:
    fail(f"missing native command aliases: {missing_commands}")

auth = data.get("auth") or {}
if auth.get("requires_claude_ai_subscription") is not True:
    fail("auth.requires_claude_ai_subscription must be true")
if auth.get("api_keys_supported") is not False:
    fail("auth.api_keys_supported must be false")
if auth.get("oauth_login_required") is not True:
    fail("auth.oauth_login_required must be true")

if data.get("shared_project_env_blockers"):
    fail("shared_project_env_blockers must be empty")

secrets = data.get("secrets") or {}
if secrets.get("read_secret_files") is not False:
    fail("secrets.read_secret_files must be false")
if secrets.get("tokens_in_url") is not False:
    fail("secrets.tokens_in_url must be false")
if secrets.get("secret_values_redacted") is not True:
    fail("secrets.secret_values_redacted must be true")

if data.get("operator_stop_required") is not True:
    fail("operator_stop_required must be true for live native RC sessions")

for item in data.get("checks") or []:
    if isinstance(item, dict) and item.get("status") == "fail":
        fail(f"readiness check failed: {item.get('id', '<unknown>')}")

print(f"[PASS] {path}")
PY
}

run_static_contract_checks() {
  local skill="$ROOT_DIR/.claude/skills/remote-control/SKILL.md"
  local doctor="$ROOT_DIR/scripts/remote-control-doctor.sh"
  local smoke="$ROOT_DIR/scripts/remote-control-smoke.sh"
  local task="$ROOT_DIR/evals/harness/tasks/m12-remote-control-smoke.yaml"
  local golden="$ROOT_DIR/evals/harness/golden/m12-remote-control-smoke.json"

  require_file "$skill"
  require_file "$doctor"
  require_file "$smoke"
  require_file "$task"
  require_file "$golden"
  require_executable "$doctor"
  require_executable "$smoke"

  for pattern in \
    "name: remote-control" \
    "disable-model-invocation: true" \
    "# /remote-control" \
    "native Remote Control" \
    "/remote-control" \
    "/rc" \
    "claude --remote-control" \
    "claude remote-control" \
    "claude --remote" \
    "custom remote server" \
    "MCP control plane" \
    "claude.ai subscription" \
    "ANTHROPIC_API_KEY" \
    "CLAUDE_CODE_OAUTH_TOKEN" \
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" \
    "DISABLE_TELEMETRY" \
    "disableRemoteControl" \
    "bypassPermissions" \
    "Static harness evidence is compatibility evidence"; do
    require_grep "$pattern" "$skill"
  done

  for pattern in \
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" \
    "DISABLE_TELEMETRY" \
    "ANTHROPIC_API_KEY" \
    "CLAUDE_CODE_OAUTH_TOKEN" \
    "disableRemoteControl" \
    "shared_project_env_blockers" \
    "runtime_remote_control_started" \
    "not_run_static_only" \
    "custom_network_control_plane" \
    "api_key_auth_allowed" \
    "claude --version"; do
    require_grep "$pattern" "$doctor"
  done

  for pattern in \
    "custom_network_control_plane" \
    "api_key_auth_allowed" \
    "runtime_remote_control_started" \
    "shared_project_env_blockers" \
    "tokens_in_url" \
    "operator_stop_required"; do
    require_grep "$pattern" "$smoke"
  done

  for file in README.md CLAUDE.md AGENTS.md scripts/start-session.sh; do
    require_grep "/remote-control" "$ROOT_DIR/$file"
    require_grep "claude remote-control" "$ROOT_DIR/$file"
  done

  require_grep "remote-control" "$ROOT_DIR/scripts/harness-capability-map.sh"
  require_grep "remote-control-smoke" "$ROOT_DIR/scripts/harness-eval.sh"
  require_grep "remote-control-smoke" "$ROOT_DIR/scripts/release-check.sh"
  require_grep "m12-remote-control-smoke" "$task"
  require_grep "m12-remote-control-smoke" "$golden"

  python3 - "$ROOT_DIR/.claude/settings.json" <<'PY'
import json
import pathlib
import sys

settings_path = pathlib.Path(sys.argv[1])
data = json.loads(settings_path.read_text(encoding="utf-8"))
env = data.get("env") or {}
blockers = {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC",
    "DISABLE_TELEMETRY",
    "ANTHROPIC_API_KEY",
    "ANTHROPIC_AUTH_TOKEN",
    "CLAUDE_CODE_OAUTH_TOKEN",
    "CLAUDE_CODE_USE_BEDROCK",
    "CLAUDE_CODE_USE_VERTEX",
    "CLAUDE_CODE_USE_FOUNDRY",
}
present = sorted(name for name in blockers if name in env)
if present:
    raise SystemExit(f"shared project env still contains Remote Control blockers: {present}")
if data.get("disableRemoteControl") is True:
    raise SystemExit("shared project settings disable native Remote Control")
deny = data.get("permissions", {}).get("deny", [])
for rule in [
    "Read(./.env)",
    "Read(./.env.*)",
    "Read(./.claude/settings.local.json)",
    "Read(./.claude/*.local.json)",
    "Read(./secrets/**)",
]:
    if rule not in deny:
        raise SystemExit(f"missing required deny rule: {rule}")
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
    [ -e "$path" ] || fail "missing green remote-control fixtures"
    validate_artifact "$path" >/dev/null
    green_count=$((green_count + 1))
  done

  for path in "$FIXTURE_DIR"/red/*.json; do
    [ -e "$path" ] || fail "missing red remote-control fixtures"
    if validate_artifact "$path" >/dev/null 2>&1; then
      fail "red fixture was accepted: ${path#$ROOT_DIR/}"
    fi
    red_count=$((red_count + 1))
  done

  [ "$green_count" -ge 1 ] || fail "expected at least one green fixture"
  [ "$red_count" -ge 5 ] || fail "expected at least five red fixtures"

  echo "[PASS] native Claude Code Remote Control contract smoke passed"
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
