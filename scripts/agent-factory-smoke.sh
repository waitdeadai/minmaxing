#!/bin/bash
# Static stress test for the /agent-factory production contract.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/.claude/skills/agent-factory/SKILL.md"
REGISTRY="$ROOT_DIR/hermes-registry.md"
FACTORY_TASTE="$ROOT_DIR/hermes-factory.taste.md"
BLUEPRINT="$ROOT_DIR/AGENT_FACTORY_AUDIT_AND_BLUEPRINT.md"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_file() {
  local file="$1"
  [ -f "$file" ] || fail "Missing required file: ${file#$ROOT_DIR/}"
}

require_text() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || fail "Missing '${pattern}' in ${file#$ROOT_DIR/}"
}

require_file "$SKILL"
require_file "$REGISTRY"
require_file "$FACTORY_TASTE"
require_file "$BLUEPRINT"

for phase in \
  "## Phase 0: Taste Gate" \
  "## Phase 1: Hermes Intent Intake" \
  "## Phase 2: Deep Research" \
  "## Phase 3: Hermes Manifest Drafting" \
  "## Phase 4: Capability Stack Design" \
  "## Phase 5: SPEC.md For The Hermes Agent" \
  "## Phase 6: Agent File Generation" \
  "## Phase 6.5: Introspect Hard Gate" \
  "## Phase 7: Independent Verification" \
  "## Phase 8: Closeout And Registry"; do
  require_text "$SKILL" "$phase"
done

question_count="$(
  awk '
    /^Ask these 12 kernel questions verbatim/ { in_questions = 1; next }
    in_questions && /^Rules:/ { in_questions = 0 }
    in_questions && /^[0-9]+\. / { count++ }
    END { print count + 0 }
  ' "$SKILL"
)"
[ "$question_count" -eq 12 ] || fail "Expected 12 Hermes intent questions, found $question_count"

for pattern in \
  "Agent Factory is a workflow on its own" \
  "AGENT_FACTORY_ARTIFACT" \
  "Compaction Safety" \
  "search -> read -> refine" \
  "reviewed-but-not-cited" \
  "rejected/downweighted" \
  "Research sufficiency gate" \
  "Required adversarial stress cases" \
  "Enterprise monolith" \
  "Runtime bypass" \
  "memory-coherent" \
  "HERMES-{NAME}-SPEC.md" \
  "hermes.manifest.md" \
  "hermes.system-prompt.md" \
  "hermes.memory-seed.json" \
  "hermes.deploy.md" \
  "hermes.verify.md" \
  "hermes.kill-switch.md" \
  "hermes-registry.md" \
  "independent verification" \
  "kill switch"; do
  require_text "$SKILL" "$pattern"
done

for status in "active" "experimental" "paused" "deprecated"; do
  require_text "$REGISTRY" "$status"
done

for section in \
  "## Principles" \
  "## Enterprise Operating Model" \
  "## Approval Philosophy" \
  "## Memory Philosophy" \
  "## Non-Goals"; do
  require_text "$FACTORY_TASTE" "$section"
done

for section in \
  "## AUDIT: minmaxing" \
  "## AUDIT: revcli" \
  "## AGENT FACTORY: Skill Specification" \
  "## FIRST HERMES AGENT BLUEPRINT" \
  "## FAILURE MODE CATALOG" \
  "## CONSTRAINT COMPLIANCE SUMMARY"; do
  require_text "$BLUEPRINT" "$section"
done

echo "[PASS] /agent-factory production contract smoke test passed"
