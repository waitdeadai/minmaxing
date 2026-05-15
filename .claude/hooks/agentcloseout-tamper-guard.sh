#!/usr/bin/env bash
# Claude Code PreToolUse hook: protect AgentCloseoutBench enforcement files.
set -euo pipefail

_HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/agentcloseout-physics-hook.sh
source "$_HOOK_DIR/../lib/agentcloseout-physics-hook.sh"

input="$(cat)"

if [ "${AGENTCLOSEOUT_ALLOW_TAMPER:-0}" = "1" ]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "BLOCKED: agentcloseout tamper guard requires jq." >&2
  exit 2
fi

if ! printf '%s' "$input" | jq -e . >/dev/null 2>&1; then
  exit 0
fi

event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null || true)"
if [ "$event" != "PreToolUse" ]; then
  exit 0
fi

tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"

protected_markers() {
  printf '%s\n' \
    '.claude/agentcloseout.env' \
    '/.claude/agentcloseout.env' \
    '.claude/settings.json' \
    '/.claude/settings.json' \
    '.claude/settings.local.json' \
    '/.claude/settings.local.json' \
    '.claude/hooks/' \
    '/.claude/hooks/' \
    '.claude/lib/agentcloseout-physics-hook.sh' \
    '/.claude/lib/agentcloseout-physics-hook.sh' \
    'scripts/agentcloseout-physics.sh' \
    '/scripts/agentcloseout-physics.sh' \
    'tools/agentcloseout-physics/' \
    '/tools/agentcloseout-physics/'
  if [ -n "${AGENTCLOSEOUT_PHYSICS:-}" ]; then
    printf '%s\n' "$AGENTCLOSEOUT_PHYSICS"
    printf '%s\n' "$(_agentcloseout_resolve_path "$AGENTCLOSEOUT_PHYSICS")"
  fi
  if [ -n "${AGENTCLOSEOUT_RULES:-}" ]; then
    printf '%s\n' "$AGENTCLOSEOUT_RULES"
    printf '%s\n' "$(_agentcloseout_resolve_path "$AGENTCLOSEOUT_RULES")"
  fi
}

mentions_protected_marker() {
  local text="$1"
  local marker
  while IFS= read -r marker; do
    [ -z "$marker" ] && continue
    case "$text" in
      *"$marker"*) return 0 ;;
    esac
  done < <(protected_markers)
  return 1
}

block_tamper() {
  echo "BLOCKED: attempted modification of AgentCloseoutBench enforcement files." >&2
  echo "Protected surfaces include .claude/hooks, .claude/agentcloseout.env, the pinned engine, and pinned rule packs." >&2
  echo "Set AGENTCLOSEOUT_ALLOW_TAMPER=1 only for an intentional reviewed harness update." >&2
  exit 2
}

case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit)
    mapfile -t paths < <(
      printf '%s' "$input" | jq -r '
        [
          .tool_input.file_path?,
          .tool_input.path?,
          .tool_input.notebook_path?,
          (.tool_input.edits[]?.file_path?)
        ] | .[]? | select(type == "string")
      ' 2>/dev/null || true
    )
    for path in "${paths[@]}"; do
      if mentions_protected_marker "$path"; then
        block_tamper
      fi
    done
    ;;
  Bash)
    command_text="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
    if mentions_protected_marker "$command_text"; then
      if printf '%s' "$command_text" | grep -Eiq '(^|[;&|[:space:]])(rm|mv|cp|install|chmod|chown|truncate|touch|tee|sed[[:space:]].*-i|perl[[:space:]].*-pi|python3?[[:space:]].*open\(|cargo[[:space:]]+install|curl|wget)([;&|[:space:]]|$)|(^|[^<])>>?|cat[[:space:]]*>|printf[[:space:]].*>|echo[[:space:]].*>'; then
        block_tamper
      fi
    fi
    ;;
  *)
    ;;
esac

exit 0
