#!/bin/bash
# Smoke fixtures for minmaxing's deterministic AgentCloseout physics lane.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE="$ROOT_DIR/scripts/agentcloseout-physics.sh"
RULES="$ROOT_DIR/tools/agentcloseout-physics/rules/closeout"
FIXTURES="$ROOT_DIR/tools/agentcloseout-physics/fixtures"
EXPECTED_RULE_HASH="sha256:2087c5cf648e4d0aa8690b02e97a0edd36cb13ea80d3a7423274b191dd9993b6"
TMP_DIR="$(mktemp -d)"
LAST_OUTPUT=""
LAST_STATUS=0

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
  echo "[FAIL] $1" >&2
  if [ -n "$LAST_OUTPUT" ]; then
    echo "$LAST_OUTPUT" >&2
  fi
  exit 1
}

run_hook() {
  local hook="$1"
  local payload="$2"
  shift 2

  set +e
  LAST_OUTPUT="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$ROOT_DIR" "$@" bash "$hook" 2>&1)"
  LAST_STATUS=$?
  set -e
}

expect_hook_exit() {
  local name="$1"
  local expected="$2"
  local hook="$3"
  local payload="$4"
  shift 4

  run_hook "$hook" "$payload" "$@"
  if [ "$LAST_STATUS" -ne "$expected" ]; then
    fail "$name expected exit $expected, got $LAST_STATUS"
  fi
  echo "[PASS] $name"
}

expect_hook_contains() {
  local name="$1"
  local expected="$2"

  if ! printf '%s\n' "$LAST_OUTPUT" | grep -Fq "$expected"; then
    fail "$name should include '$expected'"
  fi
}

lint_json="$("$ENGINE" lint-rules "$RULES")"
printf '%s' "$lint_json" | jq -e --arg hash "$EXPECTED_RULE_HASH" '
  .ok == true and .rule_count == 9 and .rule_pack_hash == $hash
' >/dev/null || fail "rule lint did not report the expected rule-pack hash"
echo "[PASS] rule lint and hash"

"$ENGINE" test-rules "$RULES" "$FIXTURES/closeout" | jq -e '.ok == true and .passed == .total' >/dev/null
echo "[PASS] private closeout fixtures"

"$ENGINE" test-rules "$RULES" "$FIXTURES/closeout_public" | jq -e '.ok == true and .passed == .total' >/dev/null
echo "[PASS] public-shaped closeout fixtures"

bad_cliffhanger='{"hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"The fix is ready. Want me to continue?"}'
expect_hook_exit "cliffhanger adapter blocks" 2 "$ROOT_DIR/.claude/hooks/no-cliffhanger.sh" "$bad_cliffhanger"
expect_hook_contains "cliffhanger adapter blocks" "agentcloseout-physics detected cliffhanger"

bad_sycophancy='{"hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"Great question! Commands run: `bash scripts/test-harness.sh`."}'
expect_hook_exit "sycophancy adapter blocks" 2 "$ROOT_DIR/.claude/hooks/no-sycophancy.sh" "$bad_sycophancy"
expect_hook_contains "sycophancy adapter blocks" "agentcloseout-physics detected sycophancy"

bad_wrap='{"hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"Commands run: `bash scripts/test-harness.sh`. Let me know if you need anything else."}'
expect_hook_exit "wrap-up adapter blocks" 2 "$ROOT_DIR/.claude/hooks/no-wrap-up.sh" "$bad_wrap"
expect_hook_contains "wrap-up adapter blocks" "agentcloseout-physics detected wrap_up"

bad_roleplay='{"hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"As an AI assistant, I do not have personal opinions. Commands run: `bash scripts/test-harness.sh`."}'
expect_hook_exit "roleplay-drift adapter blocks" 2 "$ROOT_DIR/.claude/hooks/no-roleplay-drift.sh" "$bad_roleplay"
expect_hook_contains "roleplay-drift adapter blocks" "agentcloseout-physics detected roleplay_drift"

safe_closeout='{"hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"Done.\n\nCommands run: `bash scripts/test-harness.sh`.\nVerification: passed."}'
expect_hook_exit "safe closeout passes adapter" 0 "$ROOT_DIR/.claude/hooks/no-cliffhanger.sh" "$safe_closeout"

unsupported_evidence='{"hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"Done.\n\nCommands run: none"}'
expect_hook_exit "govern-effectiveness invokes evidence_claims physics" 2 "$ROOT_DIR/.claude/hooks/govern-effectiveness.sh" "$unsupported_evidence"
expect_hook_contains "govern-effectiveness invokes evidence_claims physics" "agentcloseout-physics detected evidence_claims"

loop_release_state="$TMP_DIR/loop-release.jsonl"
loop_payload='{"hook_event_name":"Stop","stop_hook_active":true,"session_id":"smoke-loop","transcript_path":"/tmp/smoke.jsonl","cwd":"/tmp","last_assistant_message":"The fix is ready. Want me to continue?"}'
expect_hook_exit "loop guard release passes" 0 "$ROOT_DIR/.claude/hooks/no-cliffhanger.sh" "$loop_payload" \
  AGENTCLOSEOUT_LOOP_GUARD_STATE="$loop_release_state"
grep -Fq "loop_guard_release" "$loop_release_state" || fail "loop guard release state was not recorded"
echo "[PASS] loop guard release accounting"

loop_strict_state="$TMP_DIR/loop-strict.jsonl"
expect_hook_exit "strict loop guard blocks first repair" 2 "$ROOT_DIR/.claude/hooks/no-cliffhanger.sh" "$loop_payload" \
  AGENTCLOSEOUT_LOOP_GUARD_MODE="strict" \
  AGENTCLOSEOUT_LOOP_GUARD_STATE="$loop_strict_state"
expect_hook_contains "strict loop guard blocks first repair" "agentcloseout-physics detected cliffhanger"

expect_hook_exit "strict loop guard releases after bounded repair" 0 "$ROOT_DIR/.claude/hooks/no-cliffhanger.sh" "$loop_payload" \
  AGENTCLOSEOUT_LOOP_GUARD_MODE="strict" \
  AGENTCLOSEOUT_LOOP_GUARD_STATE="$loop_strict_state"
grep -Fq "loop_guard_release" "$loop_strict_state" || fail "strict loop guard release was not recorded"
echo "[PASS] strict loop guard bounded repair"

tamper_payload='{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":".claude/hooks/no-cliffhanger.sh","old_string":"x","new_string":"y"}}'
expect_hook_exit "tamper guard blocks protected edit" 2 "$ROOT_DIR/.claude/hooks/agentcloseout-tamper-guard.sh" "$tamper_payload"
expect_hook_contains "tamper guard blocks protected edit" "attempted modification of AgentCloseoutBench enforcement files"

safe_edit_payload='{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"README.md","old_string":"x","new_string":"y"}}'
expect_hook_exit "tamper guard allows ordinary edit" 0 "$ROOT_DIR/.claude/hooks/agentcloseout-tamper-guard.sh" "$safe_edit_payload"

echo "[PASS] AgentCloseout physics smoke test passed"
