#!/bin/bash
# Smoke fixtures for the Claude Code runtime governance hook.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT_DIR/.claude/hooks/govern-effectiveness.sh"

fail() {
  echo "[FAIL] $1" >&2
  if [ -n "${LAST_OUTPUT:-}" ]; then
    echo "$LAST_OUTPUT" >&2
  fi
  exit 1
}

run_hook() {
  local fixture="$1"

  set +e
  LAST_OUTPUT="$(printf '%s' "$fixture" | bash "$HOOK" 2>&1)"
  LAST_STATUS=$?
  set -e
}

expect_block() {
  local name="$1"
  local fixture="$2"

  run_hook "$fixture"
  if [ "$LAST_STATUS" -ne 2 ]; then
    fail "$name should block with exit 2, got $LAST_STATUS"
  fi
}

expect_pass() {
  local name="$1"
  local fixture="$2"

  run_hook "$fixture"
  if [ "$LAST_STATUS" -ne 0 ]; then
    fail "$name should pass with exit 0, got $LAST_STATUS"
  fi
}

[ -f "$HOOK" ] || fail "missing hook: .claude/hooks/govern-effectiveness.sh"

destructive_bash="$(cat <<'JSON'
{
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf dist"
  }
}
JSON
)"

evidence_free_closeout="$(cat <<'JSON'
{
  "hook_event_name": "Stop",
  "stop_hook_active": false,
  "last_assistant_message": "Done. Everything is complete and ready."
}
JSON
)"

failed_verification_closeout="$(cat <<'JSON'
{
  "hook_event_name": "SubagentStop",
  "stop_hook_active": false,
  "last_assistant_message": "Implemented and ready. Verification failed when running the smoke test."
}
JSON
)"

safe_bash_read="$(cat <<'JSON'
{
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "sed -n '1,80p' scripts/hook-smoke.sh"
  }
}
JSON
)"

safe_edit="$(cat <<'JSON'
{
  "hook_event_name": "PreToolUse",
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "scripts/hook-smoke.sh",
    "old_string": "x",
    "new_string": "y"
  }
}
JSON
)"

safe_closeout_with_evidence="$(cat <<'JSON'
{
  "hook_event_name": "Stop",
  "stop_hook_active": false,
  "last_assistant_message": "Done.\n\nChanged files: `.claude/hooks/govern-effectiveness.sh`, `scripts/hook-smoke.sh`.\nCommands run: `bash -n .claude/hooks/govern-effectiveness.sh`, `bash scripts/hook-smoke.sh`.\nRisks: not wired into settings in this slice."
}
JSON
)"

expect_block "destructive Bash fixture" "$destructive_bash"
expect_block "evidence-free closeout fixture" "$evidence_free_closeout"
expect_block "failed-verification positive closeout fixture" "$failed_verification_closeout"
expect_pass "safe Bash read fixture" "$safe_bash_read"
expect_pass "safe Edit fixture" "$safe_edit"
expect_pass "safe closeout with evidence fixture" "$safe_closeout_with_evidence"

echo "[PASS] Claude Code governance hook smoke test passed"
