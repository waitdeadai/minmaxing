#!/bin/bash
# Static smoke gate for native Claude Code /goal harness compatibility.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/goal-mode"
MODE=""
ARTIFACT_PATH=""

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/goal-mode-smoke.sh --fixtures
  bash scripts/goal-mode-smoke.sh --artifact PATH

--fixtures validates the /goal-mode diagnostic route, static doctor, docs,
eval metadata, and deterministic green/red fixtures without setting /goal.
--artifact validates one sanitized goal-mode-readiness JSON artifact.
EOF
}

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing required file: $1"
}

require_absent() {
  [ ! -e "$1" ] || fail "unexpected file exists: $1"
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
OBSERVED_VERSION = (2, 1, 139)
OBSERVED_VERSION_TEXT = "2.1.139"
SECRET_RE = re.compile(
    r"(sk-[A-Za-z0-9_-]{20,}|OPENAI_API_KEY\s*=|ANTHROPIC_API_KEY\s*=|"
    r"MINIMAX_API_KEY\s*=|password\s*[:=]|secret\s*[:=]|token\s*[:=]|"
    r"BEGIN [A-Z ]*PRIVATE KEY)",
    re.IGNORECASE,
)

REQUIRED_COMMANDS = {
    "/goal <condition>",
    "/goal",
    "/goal clear",
    "claude -p --max-turns 2 --no-session-persistence \"/goal <toy condition or stop after 1 turn>\"",
}

OFFICIAL_SOURCES = {
    "https://code.claude.com/docs/en/goal",
    "https://code.claude.com/docs/en/commands",
    "https://code.claude.com/docs/en/cli-reference",
    "https://code.claude.com/docs/en/hooks",
    "https://code.claude.com/docs/en/permission-modes",
    "https://code.claude.com/docs/en/agent-view",
    "https://code.claude.com/docs/en/agents",
    "https://code.claude.com/docs/en/remote-control",
    "https://code.claude.com/docs/en/headless",
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

if data.get("artifact_type") != "goal-mode-readiness":
    fail("artifact_type must be goal-mode-readiness")
if data.get("status") not in {"pass", "warn"}:
    fail("status must be pass or warn for an accepted readiness artifact")
if data.get("native_claude_code_goal") is not True:
    fail("native_claude_code_goal must be true")
if data.get("native_goal_shadowed_by_project_skill") is not False:
    fail("native /goal must not be shadowed by a project skill")
if data.get("custom_goal_skill_created") is not False:
    fail("custom_goal_skill_created must be false")
if data.get("runtime_goal_started") is not False:
    fail("static artifacts must not set runtime /goal")
runtime_proof = str(data.get("runtime_goal_proof_status", "")).strip().lower()
allowed_runtime = {"not_run_static_only", "blocked_by_cli_version", "ready_static_only", "local_runtime_unproven"}
if runtime_proof not in allowed_runtime:
    fail(f"runtime_goal_proof_status must be one of {sorted(allowed_runtime)}")
if runtime_proof in {"confirmed", "proven", "pass", "passed", "runtime_passed"}:
    fail("static artifact must not claim live /goal runtime proof")
if data.get("official_minimum_required_version", "unexpected") is not None:
    fail("official_minimum_required_version must be null unless official docs publish one")
if data.get("minimum_observed_launch_version") != OBSERVED_VERSION_TEXT:
    fail("minimum_observed_launch_version must be 2.1.139")
if data.get("operator_boundary") != "manual_or_bounded_runtime_only":
    fail("operator_boundary must be manual_or_bounded_runtime_only")
if data.get("goal_evaluator_is_verifier") is not False:
    fail("goal evaluator must not be treated as verifier")
if data.get("goal_evaluator_runs_tools") is not False:
    fail("goal evaluator must not be claimed to run tools")
if data.get("requires_hooks_available") is not True:
    fail("requires_hooks_available must be true")
if data.get("requires_workspace_trust_runtime") is not True:
    fail("requires_workspace_trust_runtime must be true")
if data.get("works_with_print_mode_doc_claim") is not True:
    fail("works_with_print_mode_doc_claim must be true")
if data.get("works_with_remote_control_doc_claim") is not True:
    fail("works_with_remote_control_doc_claim must be true")
if data.get("manual_runtime_evidence_required") is not True:
    fail("manual_runtime_evidence_required must be true")

if data.get("goal_replaces_opusworkflow") is not False:
    fail("/goal must not replace /opusworkflow")
if data.get("goal_replaces_parallel") is not False:
    fail("/goal must not replace /parallel")
if data.get("goal_replaces_verify") is not False:
    fail("/goal must not replace /verify")
if data.get("goal_claims_ci_safe_by_default") is not False:
    fail("claude -p /goal must not be claimed CI-safe by default")
if data.get("trusted_local_bypass_goal_loop_safe") is not False:
    fail("trusted-local bypassPermissions goal loops must not be claimed safe")
if data.get("agent_view_rows_are_parent_verified") is not False:
    fail("Agent View rows must not be treated as parent-verified evidence")
if data.get("remote_control_goal_cloud_durable") is not False:
    fail("Remote Control plus /goal must not be claimed cloud durable")
if data.get("provider_identity_proven_by_goal") is not False:
    fail("/goal must not prove provider or model identity")
goal_assist = data.get("goal_assist") or {}
if goal_assist.get("passed") is True:
    fail("Goal Assist must not claim it passed")
if goal_assist.get("verified_repo_state") is True:
    fail("Goal Assist must not claim verified repo state")
if data.get("goal_verified_repo_state") is True:
    fail("static /goal artifacts must not claim verified repo state")

safe = data.get("safe_goal_template") or {}
if safe.get("bounded_condition") is not True:
    fail("safe_goal_template.bounded_condition must be true")
if safe.get("command_evidence_required") is not True:
    fail("safe_goal_template.command_evidence_required must be true")
if safe.get("max_turn_or_stop_bound_required") is not True:
    fail("safe_goal_template.max_turn_or_stop_bound_required must be true")
if safe.get("parent_verification_required") is not True:
    fail("safe_goal_template.parent_verification_required must be true")
condition = str(safe.get("condition") or "")
if "/goal " not in condition:
    fail("safe_goal_template.condition must show native /goal usage")
if "git diff --check" not in condition:
    fail("safe_goal_template.condition must require command evidence")
if "stop after" not in condition.lower():
    fail("safe_goal_template.condition must include a stop bound")

goal_assist_template = data.get("goal_assist_template") or {}
if goal_assist_template.get("mode") != "copy_paste_template_only":
    fail("goal_assist_template.mode must be copy_paste_template_only")
if goal_assist_template.get("runtime_goal_started") is not False:
    fail("goal_assist_template.runtime_goal_started must be false")
for key in (
    "exact_command_required",
    "owned_scope_required",
    "forbidden_paths_required",
    "transcript_evidence_required",
    "stop_bound_required",
    "parent_verification_required",
    "manual_runtime_evidence_required",
):
    if goal_assist_template.get(key) is not True:
        fail(f"goal_assist_template.{key} must be true")

commands = set(data.get("commands") or [])
missing_commands = sorted(REQUIRED_COMMANDS - commands)
if missing_commands:
    fail(f"missing native /goal command evidence: {missing_commands}")

cli_version = parse_version(data.get("cli_version"))
if runtime_proof == "ready_static_only" and (cli_version is None or cli_version < OBSERVED_VERSION):
    fail("ready_static_only requires cli_version at or above 2.1.139")
if runtime_proof == "blocked_by_cli_version" and cli_version is not None and cli_version >= OBSERVED_VERSION:
    fail("blocked_by_cli_version must not be used for cli_version at or above 2.1.139")

secrets = data.get("secrets") or {}
for key in (
    "read_secret_files",
    "read_local_claude_profiles",
    "read_claude_jobs",
    "read_transcripts",
    "tokens_in_url",
):
    if secrets.get(key) is not False:
        fail(f"secrets.{key} must be false")
if secrets.get("secret_values_redacted") is not True:
    fail("secrets.secret_values_redacted must be true")

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
  local skill="$ROOT_DIR/.claude/skills/goal-mode/SKILL.md"
  local shadow_skill="$ROOT_DIR/.claude/skills/goal/SKILL.md"
  local doctor="$ROOT_DIR/scripts/goal-mode-doctor.sh"
  local smoke="$ROOT_DIR/scripts/goal-mode-smoke.sh"
  local task="$ROOT_DIR/evals/harness/tasks/m16-goal-mode-smoke.yaml"
  local golden="$ROOT_DIR/evals/harness/golden/m16-goal-mode-smoke.json"

  require_file "$skill"
  require_absent "$shadow_skill"
  require_file "$doctor"
  require_file "$smoke"
  require_file "$task"
  require_file "$golden"
  require_executable "$doctor"
  require_executable "$smoke"

  for pattern in \
    "name: goal-mode" \
    "disable-model-invocation: true" \
    "# /goal-mode" \
    "/goal <condition>" \
    "/goal clear" \
    "does not set a live goal" \
    "/opusworkflow" \
    "/workflow" \
    "/parallel" \
    "/hive" \
    "/agent-view" \
    "/remote-control" \
    "increases persistence, not correctness" \
    "parent verification" \
    "Goal Assist" \
    "Owned scope" \
    "Forbidden:" \
    "Evidence required" \
    "Stop bound" \
    "Parent verification" \
    "transcript evidence" \
    "git diff --check" \
    "make it production ready" \
    "bypassPermissions"; do
    require_grep "$pattern" "$skill"
  done

  for pattern in \
    "goal-mode-readiness" \
    "runtime_goal_started" \
    "runtime_goal_proof_status" \
    "official_minimum_required_version" \
    "minimum_observed_launch_version" \
    "2.1.139" \
    "disableAllHooks" \
    "native_goal_shadowed_by_project_skill" \
    "goal_evaluator_is_verifier" \
    "goal_evaluator_runs_tools" \
    "goal_assist_template" \
    "copy_paste_template_only" \
    "owned_scope_required" \
    "forbidden_paths_required" \
    "transcript_evidence_required" \
    "stop_bound_required" \
    "parent_verification_required" \
    "manual_or_bounded_runtime_only" \
    "source_ledger"; do
    require_grep "$pattern" "$doctor"
  done

  for pattern in \
    "goal-mode-readiness" \
    "native_goal_shadowed_by_project_skill" \
    "runtime_goal_started" \
    "goal_replaces_opusworkflow" \
    "goal_replaces_parallel" \
    "goal_replaces_verify" \
    "goal_claims_ci_safe_by_default" \
    "trusted_local_bypass_goal_loop_safe" \
    "agent_view_rows_are_parent_verified" \
    "remote_control_goal_cloud_durable" \
    "provider_identity_proven_by_goal" \
    "goal_assist_template" \
    "goal_verified_repo_state" \
    "passed"; do
    require_grep "$pattern" "$smoke"
  done

  for file in README.md CLAUDE.md AGENTS.md; do
    require_grep "/goal-mode" "$ROOT_DIR/$file"
    require_grep "/goal <condition>" "$ROOT_DIR/$file"
    require_grep "Native /goal" "$ROOT_DIR/$file"
  done

  require_grep "goal-mode" "$ROOT_DIR/scripts/harness-capability-map.sh"
  require_grep "goal-mode-smoke" "$ROOT_DIR/scripts/harness-eval.sh"
  require_grep "goal-mode-smoke" "$ROOT_DIR/scripts/release-check.sh"
  require_grep "m16-goal-mode-smoke" "$task"
  require_grep "m16-goal-mode-smoke" "$golden"

  python3 - "$ROOT_DIR/.claude/settings.json" <<'PY'
import json
import pathlib
import sys

data = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert data.get("disableAllHooks") is not True
notes = "\n".join(data.get("profileNotes") or [])
assert "/goal" in notes
assert "disableAllHooks" in notes
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
    [ -e "$path" ] || fail "missing green goal-mode fixtures"
    validate_artifact "$path" >/dev/null
    green_count=$((green_count + 1))
  done

  for path in "$FIXTURE_DIR"/red/*.json; do
    [ -e "$path" ] || fail "missing red goal-mode fixtures"
    if validate_artifact "$path" >/dev/null 2>&1; then
      fail "red fixture was accepted: ${path#$ROOT_DIR/}"
    fi
    red_count=$((red_count + 1))
  done

  [ "$green_count" -ge 3 ] || fail "expected at least three green fixtures"
  [ "$red_count" -ge 20 ] || fail "expected at least twenty red fixtures"

  echo "[PASS] native Claude Code /goal mode contract smoke passed"
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
