#!/bin/bash
# Static benchmark-honesty gate for /opusminimax.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="check"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/opusminimax-benchmark-smoke.sh [--fixtures]

Runs no provider calls and no real benchmark workloads.
EOF
}

case "${1:-}" in
  "")
    ;;
  "--fixtures")
    MODE="fixtures"
    ;;
  "-h"|"--help")
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

cd "$ROOT_DIR"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

require_file() {
  [ -e "$1" ] || fail "missing $1"
}

require_text() {
  local pattern="$1"
  local file="$2"
  grep -Fq "$pattern" "$file" || fail "missing '$pattern' in $file"
}

require_file ".claude/skills/opusminimax/SKILL.md"
require_file "scripts/opusminimax-doctor.sh"
require_file "scripts/minimax-exec.sh"
require_file "schemas/opusminimax-benchmark-result.schema.json"
require_file ".taste/fixtures/artifact-lint/green/valid-opusminimax-benchmark-result.json"
require_file ".taste/fixtures/artifact-lint/red/opusminimax-benchmark-aggregate-without-per-task.json"

for pattern in \
  "gold/hidden quarantine" \
  "Aggregate scores require per-task result artifacts" \
  "Static harness evals are not benchmark proof" \
  "MiniMax candidate patches" \
  "Claude adversarial selection"; do
  require_text "$pattern" ".claude/skills/opusminimax/SKILL.md"
done

for pattern in \
  "opusminimax-benchmark-result" \
  "gold_hidden_quarantined" \
  "per_task_results"; do
  require_text "$pattern" "scripts/artifact-lint.sh"
done

bash scripts/artifact-lint.sh .taste/fixtures/artifact-lint/green/valid-opusminimax-benchmark-result.json >/dev/null

if bash scripts/artifact-lint.sh .taste/fixtures/artifact-lint/red/opusminimax-benchmark-aggregate-without-per-task.json >/dev/null 2>&1; then
  fail "benchmark aggregate without per-task evidence was accepted"
fi

if [ "$MODE" = "fixtures" ]; then
  bash scripts/artifact-lint.sh --fixtures >/dev/null
fi

echo "[PASS] /opusminimax benchmark honesty smoke passed"
