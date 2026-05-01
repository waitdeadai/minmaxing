#!/bin/bash
# Claude Code hook: block destructive Bash and low-evidence positive closeout.

set -euo pipefail

INPUT="$(cat)"

json_get() {
  local filter="$1"
  printf '%s' "$INPUT" | jq -r "$filter // empty" 2>/dev/null || true
}

block() {
  echo "BLOCKED: $1" >&2
  exit 2
}

if ! printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1; then
  exit 0
fi

event="$(json_get '.hook_event_name')"

is_destructive_bash() {
  local command="$1"
  local pattern
  local patterns=(
    '(^|[[:space:];&|])sudo[[:space:]]+rm[[:space:]].*(-[[:alnum:]]*r|--recursive)([[:space:]]|$)'
    '(^|[[:space:];&|])rm[[:space:]]+(-[[:alnum:]]*r[[:alnum:]]*|--recursive)([[:space:]]|$)'
    '(^|[[:space:];&|])rm[[:space:]]+-[[:alnum:]]*f[[:alnum:]]*[[:space:]]+/'
    '(^|[[:space:];&|])git[[:space:]]+reset[[:space:]]+--hard([[:space:]]|$)'
    '(^|[[:space:];&|])git[[:space:]]+clean[[:space:]]+-[[:alnum:]]*(f[[:alnum:]]*d|d[[:alnum:]]*f)'
    '(^|[[:space:];&|])git[[:space:]]+checkout[[:space:]]+--[[:space:]]'
    '(^|[[:space:];&|])find[[:space:]].*[[:space:]]-delete([[:space:]]|$)'
    '(^|[[:space:];&|])mkfs(\.[[:alnum:]_-]+)?([[:space:]]|$)'
    '(^|[[:space:];&|])dd[[:space:]].*[[:space:]]of=/dev/'
    '(^|[[:space:];&|])chmod[[:space:]]+-R[[:space:]]+777([[:space:]]|$)'
  )

  for pattern in "${patterns[@]}"; do
    if printf '%s\n' "$command" | grep -Eiq -- "$pattern"; then
      return 0
    fi
  done

  return 1
}

has_positive_closeout() {
  local message="$1"
  if printf '%s\n' "$message" | grep -Eiq '(^|[^[:alpha:]])(not done|not complete|not completed|not ready|incomplete|unfinished)([^[:alpha:]]|$)'; then
    return 1
  fi
  printf '%s\n' "$message" | grep -Eiq '(^|[^[:alpha:]])(all set|done|completed|complete|implemented|fixed|finished|ready|passes|passed|shipped)([^[:alpha:]]|$)'
}

has_evidence() {
  local message="$1"
  printf '%s\n' "$message" | grep -Eiq '(^|[[:space:]])(commands? run|verification|verified|tests?|smoke|changed files?|files? changed)(:|[[:space:]])' && return 0
  printf '%s\n' "$message" | grep -Eiq '`(bash|git|npm|pnpm|yarn|pytest|python3?|ruff|cargo|go test|make)[^`]*`' && return 0
  printf '%s\n' "$message" | grep -Eiq '([[:alnum:]_.-]+/)+[[:alnum:]_.-]+\.[[:alnum:]]+' && return 0
  printf '%s\n' "$message" | grep -Eiq '[[:alnum:]_.-]+\.(sh|md|json|toml|yaml|yml|js|ts|tsx|jsx|py|go|rs|rb|php|java|kt|swift|css|html)' && return 0
  return 1
}

has_failed_verification() {
  local message="$1"
  printf '%s\n' "$message" | grep -Eiq '(verification|verify|tests?|smoke|lint|build)[^[:cntrl:]]*(failed|failing|failure|error|errors|could not run|did not run|not run|unable to run|blocked)' && return 0
  printf '%s\n' "$message" | grep -Eiq '(failed|failing|failure|error|errors|could not run|did not run|not run|unable to run|blocked)[^[:cntrl:]]*(verification|verify|tests?|smoke|lint|build)' && return 0
  return 1
}

if [ "$event" = "PreToolUse" ] && [ "$(json_get '.tool_name')" = "Bash" ]; then
  command="$(json_get '.tool_input.command')"
  if [ -n "$command" ] && is_destructive_bash "$command"; then
    block "destructive Bash command requires explicit human approval and a rollback plan."
  fi
  exit 0
fi

if [ "$event" = "Stop" ] || [ "$event" = "SubagentStop" ]; then
  if [ "$(json_get '.stop_hook_active')" = "true" ]; then
    exit 0
  fi

  message="$(json_get '.last_assistant_message')"
  if [ -z "$message" ]; then
    exit 0
  fi

  if has_failed_verification "$message" && has_positive_closeout "$message"; then
    block "positive closeout conflicts with failed or missing verification."
  fi

  if has_positive_closeout "$message" && ! has_evidence "$message"; then
    block "closeout needs concrete evidence: changed files, commands run, or verification."
  fi
fi

exit 0
