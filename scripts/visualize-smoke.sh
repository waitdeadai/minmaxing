#!/bin/bash
# Smoke the /visualize and /visualizeworkflow contracts without secrets or image providers.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

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

VISUALIZE=".claude/skills/visualize/SKILL.md"
VISUALIZE_WORKFLOW=".claude/skills/visualizeworkflow/SKILL.md"
RULES=".claude/rules/visualization.rules.md"
WORKFLOW=".claude/skills/workflow/SKILL.md"

require_file "$VISUALIZE"
require_file "$VISUALIZE_WORKFLOW"
require_file "$RULES"
require_file "$WORKFLOW"

SKILL_COUNT="$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')"
[ "$SKILL_COUNT" -ge 24 ] || fail "expected at least 24 skills, found $SKILL_COUNT"

for pattern in \
  "taste.md" \
  "taste.vision" \
  "SPEC.md" \
  ".taste/visualizations" \
  "image generation" \
  "no-image fallback" \
  "Understanding Card" \
  "no-secret" \
  "Never claim an image was generated when it was not"; do
  require_grep "$pattern" "$VISUALIZE"
done

for pattern in \
  "WAITING_FOR_VISUAL_APPROVAL" \
  "--continue" \
  "--revise" \
  "draft-SPEC.md" \
  "approval.json" \
  "Plain \`/workflow\` remains autonomous" \
  "Never implement before \`--continue\`"; do
  require_grep "$pattern" "$VISUALIZE_WORKFLOW"
done

for pattern in \
  "Plain \`/workflow\` remains autonomous" \
  "must not be forced into a fake UI mockup" \
  "no image artifact path" \
  "WAITING_FOR_VISUAL_APPROVAL" \
  ".taste/visualizations/"; do
  require_grep "$pattern" "$RULES"
done

require_grep "Keep plain \`/workflow\` autonomous" "$WORKFLOW"
require_grep "route that request to \`/visualizeworkflow\`" "$WORKFLOW"
require_grep "/visualizeworkflow" "$WORKFLOW"
require_not_grep "## Visualization Gate" "$WORKFLOW"

for file in README.md CLAUDE.md AGENTS.md scripts/start-session.sh; do
  require_grep "/visualize" "$file"
  require_grep "/visualizeworkflow" "$file"
done

require_grep "24 skills" README.md
require_grep "Expected 24 skills" scripts/start-session.sh

if ! git check-ignore -q .taste/visualizations/probe/visualization.md; then
  fail ".taste/visualizations is not ignored by git"
fi

echo "[PASS] /visualize and /visualizeworkflow contract smoke test passed"
