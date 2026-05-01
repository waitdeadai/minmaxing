#!/bin/bash
# Local release gate for the public harness contract.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_FULL_HARNESS=1
STATIC_ONLY=0

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/release-check.sh [--static-only] [--skip-full-harness]

Runs the no-secret release checks. Runtime Claude checks are intentionally
outside this script and belong to the manual harness-runtime workflow.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--static-only")
      STATIC_ONLY=1
      shift
      ;;
    "--skip-full-harness")
      RUN_FULL_HARNESS=0
      shift
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
done

cd "$ROOT_DIR"

run() {
  echo "[release-check] $*"
  "$@"
}

run bash -n scripts/*.sh
run python3 -m json.tool .claude/settings.json >/dev/null
run python3 -m json.tool .claude/settings.solo-fast.example.json >/dev/null
run python3 -m json.tool .claude/settings.team-safe.example.json >/dev/null
run bash scripts/estimate-smoke.sh
run bash scripts/parallel-smoke.sh
run bash scripts/agentfactory-smoke.sh
run bash scripts/hook-smoke.sh
run bash scripts/artifact-lint.sh --fixtures
run bash scripts/harness-eval.sh --json >/dev/null
run bash scripts/security-smoke.sh
run bash scripts/run-metrics.sh --fixtures --json >/dev/null
run bash scripts/session-insights.sh --fixtures --json >/dev/null
run bash scripts/memory-eval.sh --fixtures

if [ "$RUN_FULL_HARNESS" -eq 1 ]; then
  run bash scripts/test-harness.sh
fi

run git diff --check

if [ "$STATIC_ONLY" -eq 1 ]; then
  echo "[release-check] static-only release gate passed"
else
  echo "[release-check] release gate passed"
fi
