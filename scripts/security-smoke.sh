#!/bin/bash
# Static security smoke for Claude Code profile examples and governance hooks.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOLO="$ROOT_DIR/.claude/settings.solo-fast.example.json"
TEAM="$ROOT_DIR/.claude/settings.team-safe.example.json"
HOOK="$ROOT_DIR/.claude/hooks/govern-effectiveness.sh"

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

require_json "$SOLO"
require_json "$TEAM"
require_text "$SOLO" '"profile": "solo-fast"'
require_text "$TEAM" '"profile": "team-safe"'

[ "$(json_value "$SOLO" "permissions.defaultMode")" = "bypassPermissions" ] || fail "solo-fast must use bypassPermissions"
[ "$(json_value "$TEAM" "permissions.defaultMode")" = "acceptEdits" ] || fail "team-safe must use acceptEdits"

for file in "$SOLO" "$TEAM"; do
  for pattern in \
    "Read(./.claude/settings.local.json)" \
    "Read(./.env)" \
    "Read(./.env.*)" \
    "Read(./secrets/**)" \
	    "govern-effectiveness.sh" \
	    '"PreToolUse"' \
	    '"PostToolUse"' \
	    '"TaskCreated"' \
	    '"TaskCompleted"' \
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
require_text "$ROOT_DIR/SECURITY.md" "bypassPermissions is not the recommended team default"

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
