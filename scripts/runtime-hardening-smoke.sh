#!/bin/bash
# Smoke the local runtime-hardening layer without secrets or network access.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_file() {
  [ -e "$1" ] || fail "missing ${1#$ROOT_DIR/}"
}

require_executable() {
  [ -x "$1" ] || fail "not executable: ${1#$ROOT_DIR/}"
}

require_text() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || fail "missing '$pattern' in ${file#$ROOT_DIR/}"
}

cd "$ROOT_DIR"

for script in \
  scripts/trace-ledger.sh \
  scripts/hook-mesh-smoke.sh \
  scripts/worktree-runner.sh \
  scripts/scenario-eval.sh \
  scripts/learning-loop.sh \
  scripts/harness-doctor.sh; do
  require_file "$script"
  require_executable "$script"
done

for path in \
  .taste/fixtures/trace-ledger \
  .taste/fixtures/hook-mesh \
  .taste/fixtures/worktree-runner \
  .taste/fixtures/learning-loop \
  evals/scenarios \
  docs/runtime-hardening.md; do
  require_file "$path"
done

for file in \
  .claude/settings.json \
  .claude/settings.solo-fast.example.json \
  .claude/settings.team-safe.example.json; do
  python3 -m json.tool "$file" >/dev/null || fail "invalid JSON: $file"
  for pattern in \
    '"PostToolUse"' \
    '"PostToolUseFailure"' \
    '"TaskCreated"' \
    '"TaskCompleted"' \
    'Edit|Write|MultiEdit|NotebookEdit' \
    'govern-effectiveness.sh'; do
    require_text "$file" "$pattern"
  done
done

bash -n \
  scripts/trace-ledger.sh \
  scripts/hook-mesh-smoke.sh \
  scripts/worktree-runner.sh \
  scripts/scenario-eval.sh \
  scripts/learning-loop.sh \
  scripts/harness-doctor.sh \
  .claude/hooks/govern-effectiveness.sh

bash scripts/trace-ledger.sh --fixtures >/dev/null
bash scripts/hook-mesh-smoke.sh >/dev/null
bash scripts/hook-smoke.sh >/dev/null
bash scripts/worktree-runner.sh --fixtures >/dev/null

bash scripts/scenario-eval.sh --fixtures --json >"$TMP_DIR/scenario-eval.json"
python3 -m json.tool "$TMP_DIR/scenario-eval.json" >/dev/null
grep -Fq '"status": "pass"' "$TMP_DIR/scenario-eval.json" || fail "scenario eval fixtures did not pass"

bash scripts/learning-loop.sh --fixtures --json >"$TMP_DIR/learning-loop.json"
python3 -m json.tool "$TMP_DIR/learning-loop.json" >/dev/null
grep -Fq '"provider_cost": "insufficient_data"' "$TMP_DIR/learning-loop.json" || fail "learning loop invented provider cost"
grep -Fq '"provider_tokens": "insufficient_data"' "$TMP_DIR/learning-loop.json" || fail "learning loop invented provider tokens"

bash scripts/harness-doctor.sh --json >"$TMP_DIR/harness-doctor.json"
python3 -m json.tool "$TMP_DIR/harness-doctor.json" >/dev/null
grep -Fq '"provider_cost": "insufficient_data"' "$TMP_DIR/harness-doctor.json" || fail "harness doctor invented provider cost"

for pattern in \
  "Trace Ledger" \
  "Worktree Runner" \
  "Scenario Eval" \
  "Learning Loop" \
  "Harness Doctor" \
  "no-secret"; do
  require_text docs/runtime-hardening.md "$pattern"
done

echo "[PASS] runtime hardening smoke test passed"
