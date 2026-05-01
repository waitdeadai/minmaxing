#!/bin/bash
# Minimal linter for parallel worker plans and result claims.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/parallel-plan"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/parallel-plan-lint.sh --fixtures
  bash scripts/parallel-plan-lint.sh PATH [PATH...]

Plan files use one packet per line:
  packet=ID|owner=NAME|owned_files=a,b|touched_files=a|commands=cmd|evidence=note|parent_verified=yes|merge_barrier=none
EOF
}

field_value() {
  local packet="$1"
  local key="$2"
  local part

  IFS='|' read -ra parts <<< "$packet"
  for part in "${parts[@]}"; do
    case "$part" in
      "$key="*)
        printf '%s\n' "${part#*=}"
        return 0
        ;;
    esac
  done

  return 1
}

is_ambiguous() {
  local value="$1"

  case "$value" in
    ''|unknown|Unknown|UNKNOWN|tbd|TBD|shared|Shared|multiple|Multiple|anyone|Anyone|unassigned|Unassigned|all|All|*,*|*+*|*" and "*|*" or "*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

has_linear_scaling_claim() {
  local file="$1"

  grep -Eiq '([0-9]+|ten)[ -]?(agents|lanes).*(means|=).*(x faster|linear|faster)' "$file" && return 0
  grep -Eiq '(linear lane scaling|linear scaling|perfect scaling|10x faster)' "$file" && return 0
  return 1
}

is_missing_value() {
  local value="$1"

  case "$value" in
    ''|none|None|NONE|null|Null|NULL|missing|Missing|MISSING|todo|TODO|tbd|TBD)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

validate_file_list() {
  local value="$1"

  is_missing_value "$value" && return 1

  case "$value" in
    '*'|'.'|'./'|repo|repository|all|everything|shared)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

list_contains_path() {
  local list="$1"
  local path="$2"
  local item
  local prefix

  IFS=',' read -ra list_parts <<< "$list"
  for item in "${list_parts[@]}"; do
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"

    [ "$item" = "$path" ] && return 0

    case "$item" in
      */)
        prefix="${item%/}"
        case "$path" in
          "$prefix"/*) return 0 ;;
        esac
        ;;
    esac
  done

  return 1
}

validate_plan() {
  local file="$1"
  local errors=0
  local packet_count=0
  local touched_records=""

  add_error() {
    echo "[parallel-plan-lint] ${file#$ROOT_DIR/}: $1" >&2
    errors=1
  }

  [ -f "$file" ] || {
    echo "[parallel-plan-lint] missing plan: ${file#$ROOT_DIR/}" >&2
    return 1
  }

  if has_linear_scaling_claim "$file"; then
    add_error "linear lane scaling claims are not allowed"
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|\#*) continue ;;
      packet=*) ;;
      *) continue ;;
    esac

    packet_count=$((packet_count + 1))

    local packet_id
    local owner
    local owned_files
    local touched_files
    local commands
    local evidence
    local parent_verified
    local merge_barrier

    packet_id="$(field_value "$line" "packet" || true)"
    owner="$(field_value "$line" "owner" || true)"
    owned_files="$(field_value "$line" "owned_files" || true)"
    touched_files="$(field_value "$line" "touched_files" || true)"
    commands="$(field_value "$line" "commands" || true)"
    evidence="$(field_value "$line" "evidence" || true)"
    parent_verified="$(field_value "$line" "parent_verified" || true)"
    merge_barrier="$(field_value "$line" "merge_barrier" || true)"

    [ -n "$packet_id" ] || add_error "packet line is missing packet id"
    is_ambiguous "$owner" && add_error "packet ${packet_id:-unknown} has ambiguous ownership"
    validate_file_list "$owned_files" || add_error "packet ${packet_id:-unknown} has missing or ambiguous owned_files"
    validate_file_list "$touched_files" || add_error "packet ${packet_id:-unknown} has missing or ambiguous touched_files"
    is_missing_value "$commands" && add_error "packet ${packet_id:-unknown} is missing command evidence"
    is_missing_value "$evidence" && add_error "packet ${packet_id:-unknown} is missing verification evidence"
    [ "$parent_verified" = "yes" ] || add_error "packet ${packet_id:-unknown} has unverified worker claims"

    local touched_file
    IFS=',' read -ra touched_parts <<< "$touched_files"
    for touched_file in "${touched_parts[@]}"; do
      touched_file="${touched_file#"${touched_file%%[![:space:]]*}"}"
      touched_file="${touched_file%"${touched_file##*[![:space:]]}"}"
      [ -n "$touched_file" ] || continue

      list_contains_path "$owned_files" "$touched_file" || add_error "packet ${packet_id:-unknown} touches $touched_file outside owned_files"

      local prior_record
      while IFS='|' read -r prior_file prior_packet prior_barrier; do
        [ -n "$prior_file" ] || continue
        if [ "$prior_file" = "$touched_file" ]; then
          if is_missing_value "$merge_barrier" || is_missing_value "$prior_barrier"; then
            add_error "shared-file collision on $touched_file between $prior_packet and ${packet_id:-unknown} without merge barrier"
          fi
        fi
      done <<< "$touched_records"

      touched_records+="${touched_file}|${packet_id:-unknown}|${merge_barrier:-none}"$'\n'
    done
  done < "$file"

  [ "$packet_count" -gt 0 ] || add_error "plan must include at least one packet"

  [ "$errors" -eq 0 ]
}

expect_pass() {
  local file="$1"

  validate_plan "$file" || fail "green fixture was rejected"
}

expect_fail() {
  local file="$1"
  local name="$2"

  if validate_plan "$file" >/dev/null 2>&1; then
    fail "$name fixture was accepted"
  fi
}

run_fixtures() {
  expect_pass "$FIXTURE_DIR/green.plan"
  expect_fail "$FIXTURE_DIR/ambiguous-ownership.plan" "ambiguous ownership"
  expect_fail "$FIXTURE_DIR/unverified-worker-claims.plan" "unverified worker claims"
  expect_fail "$FIXTURE_DIR/missing-command-evidence.plan" "missing command evidence"
  expect_fail "$FIXTURE_DIR/outside-ownership.plan" "outside ownership"
  expect_fail "$FIXTURE_DIR/shared-file-collision.plan" "shared-file collision"
  expect_fail "$FIXTURE_DIR/linear-lane-scaling.plan" "linear lane scaling"
}

if [ "$#" -eq 0 ]; then
  usage
  fail "expected --fixtures or at least one plan file"
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit 0
fi

if [ "$1" = "--fixtures" ]; then
  [ "$#" -eq 1 ] || fail "--fixtures does not accept extra arguments"
  run_fixtures
  echo "[PASS] parallel plan lint fixtures passed"
  exit 0
fi

for plan in "$@"; do
  validate_plan "$plan" || fail "parallel plan lint failed"
done

echo "[PASS] parallel plan lint passed"
