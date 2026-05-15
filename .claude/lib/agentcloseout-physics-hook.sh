#!/usr/bin/env bash
# Shared Claude Code Stop/SubagentStop adapter for AgentCloseoutBench physics.

set -euo pipefail

_AGENTCLOSEOUT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_AGENTCLOSEOUT_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$_AGENTCLOSEOUT_PROJECT_DIR" ]; then
  _AGENTCLOSEOUT_PROJECT_DIR="$(cd "$_AGENTCLOSEOUT_LIB_DIR/../.." && pwd)"
fi

_AGENTCLOSEOUT_PRELOAD_UNSAFE_ENV=""
for _agentcloseout_var in \
  AGENTCLOSEOUT_ENV \
  AGENTCLOSEOUT_PHYSICS \
  AGENTCLOSEOUT_RULES \
  AGENTCLOSEOUT_RULE_PACK_HASH \
  AGENTCLOSEOUT_PROFILE \
  AGENTCLOSEOUT_MODE \
  AGENTCLOSEOUT_OBSERVE_ONLY \
  AGENTCLOSEOUT_REQUIRE_CLEAN_ENV \
  AGENTCLOSEOUT_ALLOW_TAMPER \
  AGENTCLOSEOUT_LOOP_GUARD_MODE \
  AGENTCLOSEOUT_LOOP_GUARD_REPAIR_LIMIT \
  AGENTCLOSEOUT_LOOP_GUARD_STATE \
  AGENTCLOSEOUT_TELEMETRY_QUEUE \
  AGENTCLOSEOUT_TELEMETRY_MODE; do
  if [ "${!_agentcloseout_var+x}" = "x" ]; then
    if [ -n "$_AGENTCLOSEOUT_PRELOAD_UNSAFE_ENV" ]; then
      _AGENTCLOSEOUT_PRELOAD_UNSAFE_ENV="$_AGENTCLOSEOUT_PRELOAD_UNSAFE_ENV,$_agentcloseout_var"
    else
      _AGENTCLOSEOUT_PRELOAD_UNSAFE_ENV="$_agentcloseout_var"
    fi
  fi
done
unset _agentcloseout_var

_agentcloseout_unquote_env_value() {
  local value="$1"
  value="${value%%#*}"
  value="${value%"${value##*[![:space:]]}"}"
  value="${value#"${value%%[![:space:]]*}"}"
  case "$value" in
    \"*\") value="${value#\"}"; value="${value%\"}" ;;
    \'*\') value="${value#\'}"; value="${value%\'}" ;;
  esac
  printf '%s' "$value"
}

_agentcloseout_load_env_file() {
  local env_file="$1"
  local line key value
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|'#'*) continue ;;
      *=*) ;;
      *) continue ;;
    esac
    key="${line%%=*}"
    value="${line#*=}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    value="$(_agentcloseout_unquote_env_value "$value")"
    case "$key" in
      AGENTCLOSEOUT_PHYSICS) AGENTCLOSEOUT_PHYSICS="$value" ;;
      AGENTCLOSEOUT_RULES) AGENTCLOSEOUT_RULES="$value" ;;
      AGENTCLOSEOUT_RULE_PACK_HASH) AGENTCLOSEOUT_RULE_PACK_HASH="$value" ;;
      AGENTCLOSEOUT_PROFILE) AGENTCLOSEOUT_PROFILE="$value" ;;
      AGENTCLOSEOUT_MODE) AGENTCLOSEOUT_MODE="$value" ;;
      AGENTCLOSEOUT_OBSERVE_ONLY) AGENTCLOSEOUT_OBSERVE_ONLY="$value" ;;
      AGENTCLOSEOUT_REQUIRE_CLEAN_ENV) AGENTCLOSEOUT_REQUIRE_CLEAN_ENV="$value" ;;
      AGENTCLOSEOUT_LOOP_GUARD_MODE) AGENTCLOSEOUT_LOOP_GUARD_MODE="$value" ;;
      AGENTCLOSEOUT_LOOP_GUARD_REPAIR_LIMIT) AGENTCLOSEOUT_LOOP_GUARD_REPAIR_LIMIT="$value" ;;
      AGENTCLOSEOUT_LOOP_GUARD_STATE) AGENTCLOSEOUT_LOOP_GUARD_STATE="$value" ;;
      AGENTCLOSEOUT_TELEMETRY_QUEUE) AGENTCLOSEOUT_TELEMETRY_QUEUE="$value" ;;
      AGENTCLOSEOUT_TELEMETRY_MODE) AGENTCLOSEOUT_TELEMETRY_MODE="$value" ;;
      *) ;;
    esac
  done < "$env_file"
}

_agentcloseout_source_env() {
  local candidate
  for candidate in \
    "${AGENTCLOSEOUT_ENV:-}" \
    "${CLAUDE_PROJECT_DIR:-}/.claude/agentcloseout.env" \
    "$_AGENTCLOSEOUT_LIB_DIR/../agentcloseout.env" \
    "$_AGENTCLOSEOUT_LIB_DIR/../../agentcloseout.env"; do
    if [ -n "$candidate" ] && [ -f "$candidate" ]; then
      _agentcloseout_load_env_file "$candidate"
      return 0
    fi
  done
}

_agentcloseout_source_env || true

_agentcloseout_resolve_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s' "$path" ;;
    *) printf '%s/%s' "$_AGENTCLOSEOUT_PROJECT_DIR" "$path" ;;
  esac
}

_agentcloseout_observe_only() {
  [ "${AGENTCLOSEOUT_OBSERVE_ONLY:-0}" = "1" ] || [ "${AGENTCLOSEOUT_MODE:-enforce}" = "observe" ]
}

_agentcloseout_config_failure() {
  local message="$1"
  if _agentcloseout_observe_only; then
    echo "NOTE: agentcloseout-physics observe_only_unenforced: $message" >&2
    exit 0
  fi
  echo "BLOCKED: agentcloseout-physics configuration failure." >&2
  echo "$message" >&2
  echo "Set AGENTCLOSEOUT_MODE=observe only for non-enforcing diagnostics." >&2
  exit 2
}

_agentcloseout_require_clean_env() {
  [ "${AGENTCLOSEOUT_REQUIRE_CLEAN_ENV:-0}" = "1" ]
}

_agentcloseout_check_unsafe_env_overrides() {
  if _agentcloseout_require_clean_env && [ -n "$_AGENTCLOSEOUT_PRELOAD_UNSAFE_ENV" ]; then
    _agentcloseout_config_failure "unsafe AGENTCLOSEOUT_* environment overrides were set before config load: $_AGENTCLOSEOUT_PRELOAD_UNSAFE_ENV"
  fi
}

_agentcloseout_validate_runtime_config() {
  case "${AGENTCLOSEOUT_MODE:-enforce}" in
    enforce|observe) ;;
    *) _agentcloseout_config_failure "AGENTCLOSEOUT_MODE must be enforce or observe." ;;
  esac
  case "${AGENTCLOSEOUT_TELEMETRY_MODE:-off}" in
    off|minimal_stats) ;;
    *) _agentcloseout_config_failure "AGENTCLOSEOUT_TELEMETRY_MODE must be off or minimal_stats." ;;
  esac
  case "${AGENTCLOSEOUT_LOOP_GUARD_MODE:-release}" in
    release|strict) ;;
    *) _agentcloseout_config_failure "AGENTCLOSEOUT_LOOP_GUARD_MODE must be release or strict." ;;
  esac
  case "${AGENTCLOSEOUT_LOOP_GUARD_REPAIR_LIMIT:-1}" in
    ''|*[!0-9]*) _agentcloseout_config_failure "AGENTCLOSEOUT_LOOP_GUARD_REPAIR_LIMIT must be a non-negative integer." ;;
    *) ;;
  esac
}

_agentcloseout_scan() {
  local category="$1"
  local input="$2"
  local engine="$3"
  local rules="$4"
  local status
  local -a args
  args=(scan --category "$category" --input - --rules "$rules")
  if [ -n "${AGENTCLOSEOUT_TELEMETRY_QUEUE:-}" ] && [ "${AGENTCLOSEOUT_TELEMETRY_MODE:-off}" != "off" ]; then
    args+=(--telemetry-queue "$AGENTCLOSEOUT_TELEMETRY_QUEUE" --telemetry-mode "${AGENTCLOSEOUT_TELEMETRY_MODE:-minimal_stats}")
  fi
  set +e
  AGENTCLOSEOUT_SCAN_RESULT="$(printf '%s' "$input" | "$engine" "${args[@]}" 2>&1)"
  status=$?
  set -e
  return "$status"
}

_agentcloseout_verify_rule_pack_hash() {
  local result="$1"
  local category="$2"
  local expected="${AGENTCLOSEOUT_RULE_PACK_HASH:-}"
  local actual
  [ -n "$expected" ] || return 0
  actual="$(printf '%s' "$result" | jq -r '.rule_pack_hash // empty' 2>/dev/null || true)"
  if [ -z "$actual" ]; then
    _agentcloseout_config_failure "engine did not report a rule_pack_hash for category '$category'."
  fi
  if [ "$actual" != "$expected" ]; then
    _agentcloseout_config_failure "rule-pack hash mismatch for category '$category': expected $expected, got $actual"
  fi
}

_agentcloseout_emit_block() {
  local category="$1"
  local result="$2"
  local state rules_hit evidence
  state="$(printf '%s' "$result" | jq -r '.closeout_state // "unknown"' 2>/dev/null || true)"
  rules_hit="$(printf '%s' "$result" | jq -r '.matched_rules | map(.rule_id) | join(", ")' 2>/dev/null || true)"
  evidence="$(printf '%s' "$result" | jq -r '.redacted_evidence | join(" | ")' 2>/dev/null || true)"
  if _agentcloseout_observe_only; then
    echo "NOTE: agentcloseout-physics observed $category closeout mechanics but AGENTCLOSEOUT_MODE=observe is non-enforcing." >&2
    [ -n "$rules_hit" ] && echo "Matched rules: $rules_hit" >&2
    exit 0
  fi
  echo "BLOCKED: agentcloseout-physics detected $category closeout mechanics." >&2
  echo "Closeout state: $state" >&2
  [ -n "$rules_hit" ] && echo "Matched rules: $rules_hit" >&2
  [ -n "$evidence" ] && echo "Evidence: $evidence" >&2
  echo "" >&2
  echo "Repair guidance:" >&2
  echo "- End in a valid closeout state: verified_done, partial_blocked, read_only_audit, needs_user_input, needs_bounded_choice, or handoff_with_evidence." >&2
  echo "- Remove generic retention bait, dangling permission loops, role/persona drift, and unearned praise." >&2
  echo "- If claiming completion, include concrete verification or evidence." >&2
  exit 2
}

_agentcloseout_loop_guard_state_path() {
  if [ -n "${AGENTCLOSEOUT_LOOP_GUARD_STATE:-}" ]; then
    printf '%s' "$AGENTCLOSEOUT_LOOP_GUARD_STATE"
  elif [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    printf '%s/.claude/agentcloseout-loop-guard.jsonl' "$CLAUDE_PROJECT_DIR"
  fi
}

_agentcloseout_loop_guard_key() {
  local category="$1"
  local input="$2"
  local raw_key
  raw_key="$(printf '%s' "$input" | jq -r --arg category "$category" '
    [
      $category,
      (.hook_event_name // ""),
      (.session_id // ""),
      (.transcript_path // ""),
      (.cwd // "")
    ] | join("|")
  ' 2>/dev/null || printf '%s' "$category")"
  printf 'sha256:%s' "$(printf '%s' "$raw_key" | sha256sum | awk '{print $1}')"
}

_agentcloseout_loop_guard_repair_count() {
  local state_file="$1"
  local loop_key="$2"
  local category="$3"
  [ -f "$state_file" ] || {
    printf '0'
    return 0
  }
  jq -s -r --arg loop_key "$loop_key" --arg category "$category" '
    [.[] | select(.loop_key == $loop_key and .category == $category and .action == "strict_repair_block")] | length
  ' "$state_file" 2>/dev/null || printf '0'
}

_agentcloseout_account_loop_guard() {
  local action="$1"
  local category="$2"
  local input="$3"
  local result="$4"
  local attempt="${5:-0}"
  local state_file loop_key decision closeout_state rule_hash engine_version
  state_file="$(_agentcloseout_loop_guard_state_path)"
  [ -n "$state_file" ] || return 0
  loop_key="$(_agentcloseout_loop_guard_key "$category" "$input")"
  decision="$(printf '%s' "$result" | jq -r '.decision // "unknown"' 2>/dev/null || true)"
  closeout_state="$(printf '%s' "$result" | jq -r '.closeout_state // "loop_guard_release"' 2>/dev/null || true)"
  if [ "$action" = "loop_guard_release" ]; then
    decision="pass"
    closeout_state="loop_guard_release"
  fi
  rule_hash="$(printf '%s' "$result" | jq -r '.rule_pack_hash // empty' 2>/dev/null || true)"
  engine_version="$(printf '%s' "$result" | jq -r '.engine_version // empty' 2>/dev/null || true)"
  mkdir -p "$(dirname "$state_file")"
  jq -cn \
    --arg schema_version "agentcloseout.loop_guard.v1" \
    --arg profile "${AGENTCLOSEOUT_PROFILE:-custom}" \
    --arg mode "${AGENTCLOSEOUT_LOOP_GUARD_MODE:-release}" \
    --arg action "$action" \
    --arg category "$category" \
    --arg loop_key "$loop_key" \
    --arg decision "$decision" \
    --arg closeout_state "$closeout_state" \
    --arg rule_pack_hash "$rule_hash" \
    --arg engine_version "$engine_version" \
    --argjson attempt "$attempt" \
    '{
      schema_version: $schema_version,
      profile: $profile,
      loop_guard_mode: $mode,
      action: $action,
      category: $category,
      loop_key: $loop_key,
      attempt: $attempt,
      decision: $decision,
      closeout_state: $closeout_state,
      rule_pack_hash: $rule_pack_hash,
      engine_version: $engine_version,
      privacy_flags: ["content_free", "hashed_loop_key", "no_raw_text"]
    }' >> "$state_file"
}

_agentcloseout_handle_loop_guard() {
  local category="$1"
  local input="$2"
  local engine="$3"
  local rules="$4"
  local mode="${AGENTCLOSEOUT_LOOP_GUARD_MODE:-release}"
  local limit="${AGENTCLOSEOUT_LOOP_GUARD_REPAIR_LIMIT:-1}"
  local state_file loop_key count check_input decision

  if [ "$mode" = "strict" ] && [ "$limit" -gt 0 ]; then
    state_file="$(_agentcloseout_loop_guard_state_path)"
    loop_key="$(_agentcloseout_loop_guard_key "$category" "$input")"
    count=0
    if [ -n "$state_file" ]; then
      count="$(_agentcloseout_loop_guard_repair_count "$state_file" "$loop_key" "$category")"
    fi
    if [ "$count" -lt "$limit" ]; then
      check_input="$(printf '%s' "$input" | jq '.stop_hook_active = false')"
      if ! _agentcloseout_scan "$category" "$check_input" "$engine" "$rules"; then
        _agentcloseout_config_failure "engine scan failed for strict loop-guard repair in category '$category': $AGENTCLOSEOUT_SCAN_RESULT"
      fi
      _agentcloseout_verify_rule_pack_hash "$AGENTCLOSEOUT_SCAN_RESULT" "$category"
      decision="$(printf '%s' "$AGENTCLOSEOUT_SCAN_RESULT" | jq -r '.decision // empty' 2>/dev/null || true)"
      if [ "$decision" = "block" ]; then
        _agentcloseout_account_loop_guard "strict_repair_block" "$category" "$input" "$AGENTCLOSEOUT_SCAN_RESULT" "$((count + 1))"
        _agentcloseout_emit_block "$category" "$AGENTCLOSEOUT_SCAN_RESULT"
      fi
      _agentcloseout_account_loop_guard "strict_checked_pass" "$category" "$input" "$AGENTCLOSEOUT_SCAN_RESULT" "$count"
    fi
  fi

  if ! _agentcloseout_scan "$category" "$input" "$engine" "$rules"; then
    _agentcloseout_config_failure "engine scan failed for loop-guard release in category '$category': $AGENTCLOSEOUT_SCAN_RESULT"
  fi
  _agentcloseout_verify_rule_pack_hash "$AGENTCLOSEOUT_SCAN_RESULT" "$category"
  _agentcloseout_account_loop_guard "loop_guard_release" "$category" "$input" "$AGENTCLOSEOUT_SCAN_RESULT" "0"
  exit 0
}

run_agentcloseout_physics_hook() {
  local category="$1"
  local input
  input="$(cat)"

  _agentcloseout_check_unsafe_env_overrides
  _agentcloseout_validate_runtime_config

  if ! command -v jq >/dev/null 2>&1; then
    _agentcloseout_config_failure "jq is required so the hook can enforce deterministic decisions."
  fi

  if ! printf '%s' "$input" | jq -e . >/dev/null 2>&1; then
    exit 0
  fi

  local event stop_active
  event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null || true)"
  if [ "$event" != "Stop" ] && [ "$event" != "SubagentStop" ]; then
    exit 0
  fi

  local engine rules
  engine="$(_agentcloseout_resolve_path "${AGENTCLOSEOUT_PHYSICS:-scripts/agentcloseout-physics.sh}")"
  rules="$(_agentcloseout_resolve_path "${AGENTCLOSEOUT_RULES:-tools/agentcloseout-physics/rules/closeout}")"

  if [ ! -x "$engine" ]; then
    _agentcloseout_config_failure "engine is missing or not executable: $engine"
  fi
  if [ ! -d "$rules" ]; then
    _agentcloseout_config_failure "rule pack directory is missing: $rules"
  fi

  stop_active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || true)"
  if [ "$stop_active" = "true" ]; then
    _agentcloseout_handle_loop_guard "$category" "$input" "$engine" "$rules"
  fi

  if ! _agentcloseout_scan "$category" "$input" "$engine" "$rules"; then
    _agentcloseout_config_failure "engine scan failed for category '$category': $AGENTCLOSEOUT_SCAN_RESULT"
  fi
  _agentcloseout_verify_rule_pack_hash "$AGENTCLOSEOUT_SCAN_RESULT" "$category"

  local decision
  decision="$(printf '%s' "$AGENTCLOSEOUT_SCAN_RESULT" | jq -r '.decision // empty' 2>/dev/null || true)"
  if [ -z "$decision" ]; then
    _agentcloseout_config_failure "engine returned unparsable decision JSON for category '$category'."
  fi

  if [ "$decision" = "block" ]; then
    _agentcloseout_emit_block "$category" "$AGENTCLOSEOUT_SCAN_RESULT"
  fi

  exit 0
}
