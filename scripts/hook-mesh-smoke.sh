#!/bin/bash
# Smoke fixtures for the broader Claude Code governance hook mesh.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT_DIR/.claude/hooks/govern-effectiveness.sh"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/hook-mesh"

fail() {
  echo "[FAIL] $1" >&2
  if [ -n "${LAST_OUTPUT:-}" ]; then
    echo "$LAST_OUTPUT" >&2
  fi
  exit 1
}

run_fixture() {
  local fixture="$1"
  local fixture_id expected_exit event_json status

  fixture_id="$(jq -r '.fixture_id // empty' "$fixture" 2>/dev/null)" || fail "invalid JSON: $fixture"
  expected_exit="$(jq -r '.expected_exit // empty' "$fixture" 2>/dev/null)" || fail "invalid JSON: $fixture"
  event_json="$(jq -c '.event' "$fixture" 2>/dev/null)" || fail "missing event: $fixture"

  [ -n "$fixture_id" ] || fail "fixture missing fixture_id: $fixture"
  case "$expected_exit" in
    0|2) ;;
    *) fail "$fixture_id has unsupported expected_exit: $expected_exit" ;;
  esac

  set +e
  LAST_OUTPUT="$(printf '%s' "$event_json" | bash "$HOOK" 2>&1)"
  status=$?
  set -e

  if [ "$status" -ne "$expected_exit" ]; then
    fail "$fixture_id expected exit $expected_exit, got $status"
  fi

  echo "[PASS] $fixture_id (exit $status)"
}

[ -f "$HOOK" ] || fail "missing hook: .claude/hooks/govern-effectiveness.sh"

shopt -s nullglob
fixtures=("$FIXTURE_DIR"/*.json)
shopt -u nullglob

[ "${#fixtures[@]}" -gt 0 ] || fail "no hook mesh fixtures found"

count=0
for fixture in "${fixtures[@]}"; do
  run_fixture "$fixture"
  count=$((count + 1))
done

echo "[PASS] hook mesh smoke passed ($count fixtures)"
