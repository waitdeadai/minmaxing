#!/bin/bash
# Static security smoke for Claude Code profile examples and governance hooks.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/.claude/settings.json"
SOLO="$ROOT_DIR/.claude/settings.solo-fast.example.json"
TEAM="$ROOT_DIR/.claude/settings.team-safe.example.json"
OPUS_PLANNER="$ROOT_DIR/.claude/settings.opusminimax-planner.example.json"
MINIMAX_EXECUTOR="$ROOT_DIR/.claude/settings.minimax-executor.example.json"
OPUSSONNET="$ROOT_DIR/.claude/settings.opussonnet.example.json"
SONNET_EXECUTOR="$ROOT_DIR/.claude/settings.sonnet-executor.example.json"
HOOK="$ROOT_DIR/.claude/hooks/govern-effectiveness.sh"
TIME_ANCHOR_HOOK="$ROOT_DIR/.claude/hooks/time-anchor.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

json_value() {
  local file="$1"
  local expr="$2"
  python3 - "$file" "$expr" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
value = data
for part in sys.argv[2].split("."):
    if not part:
        continue
    value = value[part]
print(value)
PY
}

require_json() {
  python3 -m json.tool "$1" >/dev/null || fail "invalid JSON: ${1#$ROOT_DIR/}"
}

require_text() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || fail "missing '$pattern' in ${file#$ROOT_DIR/}"
}

expect_hook_block() {
  local name="$1"
  local payload="$2"
  set +e
  printf '%s' "$payload" | bash "$HOOK" >/tmp/minmaxing-security-smoke.out 2>&1
  local status=$?
  set -e
  [ "$status" -eq 2 ] || fail "$name should block with exit 2, got $status"
}

require_json "$PROJECT"
require_json "$SOLO"
require_json "$TEAM"
require_json "$OPUS_PLANNER"
require_json "$MINIMAX_EXECUTOR"
require_json "$OPUSSONNET"
require_json "$SONNET_EXECUTOR"
require_text "$SOLO" '"profile": "solo-fast"'
require_text "$TEAM" '"profile": "team-safe"'
require_text "$OPUS_PLANNER" '"profile": "opusminimax-planner"'
require_text "$MINIMAX_EXECUTOR" '"profile": "minimax-executor"'
require_text "$OPUSSONNET" '"profile": "opussonnet"'
require_text "$SONNET_EXECUTOR" '"profile": "sonnet-executor"'

[ "$(json_value "$PROJECT" "permissions.defaultMode")" = "bypassPermissions" ] || fail "project default must use bypassPermissions"
[ "$(json_value "$SOLO" "permissions.defaultMode")" = "bypassPermissions" ] || fail "solo-fast must use bypassPermissions"
[ "$(json_value "$TEAM" "permissions.defaultMode")" = "acceptEdits" ] || fail "team-safe must use acceptEdits"
require_text "$PROJECT" "TRUSTED-LOCAL WARNING"
require_text "$PROJECT" "settings.team-safe.example.json"
[ -x "$TIME_ANCHOR_HOOK" ] || fail "time-anchor hook must be executable"

python3 - "$OPUS_PLANNER" <<'PY' || fail "opusminimax planner example must not route through MiniMax"
import json
import sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
env = data.get("env", {})
assert "ANTHROPIC_BASE_URL" not in env
assert "MiniMax-M2.7-highspeed" not in json.dumps(env)
PY
grep -Fq '"ANTHROPIC_BASE_URL": "https://api.minimax.io/anthropic"' "$MINIMAX_EXECUTOR" || fail "minimax executor example must set MiniMax base URL"
grep -Fq '"ANTHROPIC_MODEL": "MiniMax-M2.7-highspeed"' "$MINIMAX_EXECUTOR" || fail "minimax executor example must set MiniMax-M2.7-highspeed"
grep -Fq '"ANTHROPIC_MODEL": "opusplan"' "$OPUSSONNET" || fail "opussonnet example must request opusplan"
grep -Fq '"ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-7"' "$OPUSSONNET" || fail "opussonnet example must pin Opus 4.7"
grep -Fq '"ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-6"' "$OPUSSONNET" || fail "opussonnet example must pin Sonnet 4.6"
grep -Fq '"ANTHROPIC_MODEL": "claude-sonnet-4-6"' "$SONNET_EXECUTOR" || fail "sonnet executor example must request Sonnet 4.6"

python3 - "$OPUSSONNET" "$SONNET_EXECUTOR" <<'PY' || fail "Claude-only profiles must not route through MiniMax"
import json
import sys
for raw in sys.argv[1:]:
    data = json.load(open(raw, encoding="utf-8"))
    env = data.get("env", {})
    assert "ANTHROPIC_BASE_URL" not in env
    assert "MINIMAX_API_KEY" not in env
    assert "MINIMAX_API_HOST" not in env
PY

for file in "$PROJECT" "$SOLO" "$TEAM"; do
  for pattern in \
    "Read(./.claude/settings.local.json)" \
    "Read(./.env)" \
    "Read(./.env.*)" \
    "Read(./secrets/**)" \
	    "govern-effectiveness.sh" \
	    "time-anchor.sh" \
	    '"PreToolUse"' \
	    '"PostToolUse"' \
	    '"UserPromptSubmit"' \
	    '"SessionStart"' \
	    '"TaskCreated"' \
	    '"TaskCompleted"' \
	    '"Stop"' \
	    '"SubagentStop"'; do
    require_text "$file" "$pattern"
  done
done

for file in "$OPUS_PLANNER" "$MINIMAX_EXECUTOR" "$OPUSSONNET" "$SONNET_EXECUTOR"; do
  for pattern in \
    "Read(./.claude/settings.local.json)" \
    "Read(./.claude/*.local.json)" \
    "Read(./.env)" \
    "Read(./.env.*)" \
    "Read(./secrets/**)" \
    "govern-effectiveness.sh" \
    "time-anchor.sh" \
    '"PreToolUse"' \
    '"PostToolUse"' \
    '"UserPromptSubmit"' \
    '"SessionStart"' \
    '"Stop"' \
    '"SubagentStop"'; do
    require_text "$file" "$pattern"
  done
done

require_text "$ROOT_DIR/.claude/rules/security.rules.md" "solo-fast"
require_text "$ROOT_DIR/.claude/rules/security.rules.md" "team-safe"
require_text "$ROOT_DIR/.claude/rules/security.rules.md" "ci-static"
require_text "$ROOT_DIR/.claude/rules/security.rules.md" "ci-runtime"
require_text "$ROOT_DIR/SECURITY.md" "Runtime Policy Matrix"
require_text "$ROOT_DIR/SECURITY.md" "trusted-local default"
require_text "$ROOT_DIR/SECURITY.md" "bypassPermissions is not the recommended team default"
require_text "$ROOT_DIR/setup.ps1" '$Mode = "opusworkflow"'
require_text "$ROOT_DIR/setup.ps1" "settings.minimax-executor.local.json"
require_text "$ROOT_DIR/setup.ps1" "settings.opusminimax-planner.local.json"
require_text "$ROOT_DIR/setup.ps1" "Split mode does not mutate user-scope MCP automatically"

expect_hook_block "destructive Bash" '{
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "git reset --hard"
  }
}'

expect_hook_block "evidence-free closeout" '{
  "hook_event_name": "Stop",
  "last_assistant_message": "Done. Everything is complete and ready."
}'

echo "[PASS] security profile smoke test passed"
