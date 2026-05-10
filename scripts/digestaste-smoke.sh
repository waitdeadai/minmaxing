#!/bin/bash
# Static smoke gate for /digestaste research-to-taste bootstrap packets.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/digestaste-smoke.sh --fixtures

Runs deterministic no-network checks for the /digestaste skill contract.
EOF
}

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing required file: $1"
}

require_grep() {
  local pattern="$1"
  local file="$2"
  grep -Fq -- "$pattern" "$file" 2>/dev/null || fail "missing pattern '$pattern' in $file"
}

require_not_grep() {
  local pattern="$1"
  local file="$2"
  if grep -Fq -- "$pattern" "$file" 2>/dev/null; then
    fail "forbidden pattern '$pattern' found in $file"
  fi
}

if [ "${1:-}" != "--fixtures" ]; then
  usage
  exit 2
fi

skill="$ROOT_DIR/.claude/skills/digestaste/SKILL.md"
require_file "$skill"

for pattern in \
  "name: digestaste" \
  "argument-hint:" \
  "disable-model-invocation: true" \
  "# /digestaste" \
  "Deep Research markdown" \
  "DigesTaste Bootstrap Packet" \
  "Goal Bootstrap Text" \
  "Tastebootstrap Answers" \
  "Draft taste.md Text" \
  "Draft taste.vision Text" \
  "Existing-Kernel Proposal" \
  "Report Intake" \
  "untrusted candidate evidence" \
  "report-derived" \
  "no-persist report bodies" \
  "Injection Quarantine" \
  "prompt-like instructions" \
  "/tastebootstrap" \
  "/defineicp" \
  "/deepretaste" \
  "text|bootstrap|proposal|apply" \
  "proposal-first" \
  "backup both files" \
  "write both files as one unit" \
  "changed-line trace" \
  "DIGESTASTE_TEXT_READY" \
  "DIGESTASTE_BOOTSTRAPPED" \
  "DIGESTASTE_PROPOSED" \
  "DIGESTASTE_APPLIED" \
  "DIGESTASTE_BLOCKED"; do
  require_grep "$pattern" "$skill"
done

for forbidden in \
  "source .env" \
  "cat .env" \
  "dotenv" \
  "printenv" \
  "env >" \
  "read .claude/settings.local.json"; do
  require_not_grep "$forbidden" "$skill"
done

for file in README.md CLAUDE.md AGENTS.md scripts/start-session.sh; do
  require_grep "/digestaste" "$ROOT_DIR/$file"
done

require_grep "digestaste" "$ROOT_DIR/scripts/harness-capability-map.sh"
require_grep "digestaste-smoke" "$ROOT_DIR/scripts/harness-eval.sh"
require_grep "digestaste-smoke" "$ROOT_DIR/scripts/release-check.sh"
require_grep "m14-digestaste-research-to-bootstrap-text" "$ROOT_DIR/evals/harness/tasks/m14-digestaste-research-to-bootstrap-text.yaml"
require_grep "m14-digestaste-research-to-bootstrap-text" "$ROOT_DIR/evals/harness/golden/m14-digestaste-research-to-bootstrap-text.json"

echo "[digestaste-smoke] PASS"
