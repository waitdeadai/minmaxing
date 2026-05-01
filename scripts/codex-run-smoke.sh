#!/bin/bash
# Smoke test for the Codex-orchestrated execution contract.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/codex-run"
GREEN_FIXTURE="$FIXTURE_DIR/green.codex-run"
BROAD_WRITE_FIXTURE="$FIXTURE_DIR/broad-write-worker.codex-run"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/codex-run-smoke.sh
  bash scripts/codex-run-smoke.sh --artifact PATH

With no arguments, validates the built-in green fixture and confirms that a
broad/no-sandbox parent proposing write-capable workers is rejected.
EOF
}

get_value() {
  local file="$1"
  local key="$2"

  awk -F= -v key="$key" '
    $0 ~ /^[[:space:]]*#/ { next }
    $1 == key {
      sub(/^[^=]*=/, "")
      print
      found = 1
      exit
    }
    END {
      if (!found) {
        exit 1
      }
    }
  ' "$file"
}

contains_item() {
  local list="$1"
  local expected="$2"

  case ",$list," in
    *",$expected,"*) return 0 ;;
    *) return 1 ;;
  esac
}

is_positive_int() {
  local value="$1"

  case "$value" in
    ''|*[!0-9]*) return 1 ;;
  esac

  [ "$value" -gt 0 ]
}

is_broad_parent_profile() {
  local value="$1"

  case "$value" in
    *"danger-full-access"*|*"no-sandbox"*|*"approval_policy=never"*|*"approval=never"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

validate_codex_run() {
  local file="$1"
  local errors=0

  add_error() {
    echo "[codex-run-smoke] ${file#$ROOT_DIR/}: $1" >&2
    errors=1
  }

  [ -f "$file" ] || {
    echo "[codex-run-smoke] missing artifact: ${file#$ROOT_DIR/}" >&2
    return 1
  }

  local target_runtime
  local implementation_executor
  local requested_agents
  local effective_lanes
  local capacity_profile
  local parent_permission
  local child_sandbox
  local approval_risk
  local packet_ownership
  local worker_schema
  local parent_verified
  local read_only_agents
  local write_capable_workers
  local permission_notes
  local packet_plan

  target_runtime="$(get_value "$file" "target_runtime" || true)"
  implementation_executor="$(get_value "$file" "implementation_executor" || true)"
  requested_agents="$(get_value "$file" "requested_agents" || true)"
  effective_lanes="$(get_value "$file" "effective_lanes" || true)"
  capacity_profile="$(get_value "$file" "capacity_profile" || true)"
  parent_permission="$(get_value "$file" "codex_parent_permission_profile" || true)"
  child_sandbox="$(get_value "$file" "child_sandbox_policy" || true)"
  approval_risk="$(get_value "$file" "approval_inheritance_risk" || true)"
  packet_ownership="$(get_value "$file" "packet_ownership" || true)"
  worker_schema="$(get_value "$file" "worker_result_schema_version" || true)"
  parent_verified="$(get_value "$file" "parent_verified_worker_claims" || true)"
  read_only_agents="$(get_value "$file" "read_only_agents" || true)"
  write_capable_workers="$(get_value "$file" "write_capable_workers" || true)"
  permission_notes="$(get_value "$file" "permission_sandbox_notes" || true)"
  packet_plan="$(get_value "$file" "next_execution_packet_plan" || true)"

  [ "$target_runtime" = "claude-code" ] || add_error "target_runtime must be claude-code"
  [ "$implementation_executor" = "codex" ] || add_error "implementation_executor must be codex"
  is_positive_int "$effective_lanes" || add_error "effective_lanes must be a positive integer"

  for agent in repo_explorer docs_researcher reviewer; do
    contains_item "$requested_agents" "$agent" || add_error "requested_agents must include $agent"
    contains_item "$read_only_agents" "$agent" || add_error "$agent must be recorded as read-only when used for evidence gathering"
  done

  [ -n "$capacity_profile" ] || add_error "capacity_profile is required"
  case "$capacity_profile" in
    *"max_threads is a ceiling"*|*"max_threads=ceiling"*) ;;
    *) add_error "capacity_profile must record that Codex max_threads is a ceiling, not a target" ;;
  esac

  [ -n "$parent_permission" ] || add_error "codex_parent_permission_profile is required"
  [ -n "$child_sandbox" ] || add_error "child_sandbox_policy is required"
  [ -n "$approval_risk" ] || add_error "approval_inheritance_risk is required"
  [ -n "$permission_notes" ] || add_error "permission_sandbox_notes is required"
  [ -n "$packet_ownership" ] || add_error "packet_ownership is required"
  [ -n "$worker_schema" ] || add_error "worker_result_schema_version is required"
  [ -n "$packet_plan" ] || add_error "next_execution_packet_plan is required"

  [ "$parent_verified" = "yes" ] || add_error "parent_verified_worker_claims must be yes"

  if is_broad_parent_profile "$parent_permission" && [ "$write_capable_workers" != "none" ]; then
    case "$child_sandbox" in
      *"write-capable workers blocked"*|*"write workers blocked"*) ;;
      *) add_error "broad/no-sandbox parent cannot propose write-capable workers without blocking them" ;;
    esac
  fi

  [ "$errors" -eq 0 ]
}

expect_rejected() {
  local file="$1"
  local name="$2"

  if validate_codex_run "$file" >/dev/null 2>&1; then
    fail "$name fixture was accepted"
  fi
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "${1:-}" = "--artifact" ]; then
  [ -n "${2:-}" ] || fail "--artifact requires a path"
  [ -z "${3:-}" ] || fail "unexpected extra argument: $3"
  validate_codex_run "$2" || fail "Codex run artifact validation failed"
  echo "[PASS] Codex run artifact validated"
  exit 0
fi

[ "$#" -eq 0 ] || {
  usage
  fail "unexpected argument: $1"
}

validate_codex_run "$GREEN_FIXTURE" || fail "green Codex run fixture was rejected"
expect_rejected "$BROAD_WRITE_FIXTURE" "broad write worker"

echo "[PASS] Codex run contract smoke test passed"
