#!/bin/bash
# Static smoke test for the Agent-Native Estimate contract.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULE="$ROOT_DIR/.claude/rules/estimation.rules.md"

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

validate_estimate_file() {
  local file="$1"

  grep -Fq "## Agent-Native Estimate" "$file" || return 1
  grep -Fq "Estimate type: agent-native wall-clock" "$file" || return 1
  grep -Fq "Capacity evidence:" "$file" || return 1
  grep -Fq "scripts/parallel-capacity.sh --json" "$file" || return 1
  grep -Fq "Effective lanes:" "$file" || return 1
  grep -Fq "Critical path:" "$file" || return 1
  grep -Fq "Agent wall-clock:" "$file" || return 1
  grep -Fq "Agent-hours:" "$file" || return 1
  grep -Fq "Human touch time:" "$file" || return 1
  grep -Fq "Calendar blockers:" "$file" || return 1
  grep -Fq "Confidence:" "$file" || return 1

  if grep -Fqi "human-equivalent baseline:" "$file" && ! grep -Fq "Agent wall-clock:" "$file"; then
    return 1
  fi

  if grep -Eqi '([0-9]+|ten)[ -]?(agents|lanes).*(means|=).*(x faster|linear|faster)' "$file"; then
    return 1
  fi

  if grep -Fqi "10 agents means 10x faster" "$file"; then
    return 1
  fi
}

for file in \
  "$RULE" \
  "$ROOT_DIR/CLAUDE.md" \
  "$ROOT_DIR/AGENTS.md" \
  "$ROOT_DIR/.claude/skills/workflow/SKILL.md" \
  "$ROOT_DIR/.claude/skills/autoplan/SKILL.md" \
  "$ROOT_DIR/.claude/skills/parallel/SKILL.md" \
  "$ROOT_DIR/.claude/skills/sprint/SKILL.md" \
  "$ROOT_DIR/.claude/skills/introspect/SKILL.md"; do
  require_file "$file"
done

for file in \
  "$ROOT_DIR/CLAUDE.md" \
  "$ROOT_DIR/AGENTS.md" \
  "$ROOT_DIR/.claude/skills/workflow/SKILL.md" \
  "$ROOT_DIR/.claude/skills/autoplan/SKILL.md" \
  "$ROOT_DIR/.claude/skills/parallel/SKILL.md" \
  "$ROOT_DIR/.claude/skills/introspect/SKILL.md"; do
  require_text "$file" "Agent-Native Estimate"
done

for pattern in \
  "agent_wall_clock" \
  "agent_hours" \
  "human_touch_time" \
  "calendar_blockers" \
  "critical path" \
  "confidence" \
  "scripts/parallel-capacity.sh --json" \
  "human-equivalent" \
  "linear scaling"; do
  require_text "$RULE" "$pattern"
done

require_text "$ROOT_DIR/.claude/skills/parallel/SKILL.md" "Estimated Duration"
require_text "$ROOT_DIR/.claude/skills/parallel/SKILL.md" "Confidence"
require_text "$ROOT_DIR/.claude/skills/sprint/SKILL.md" "Estimated duration"
require_text "$ROOT_DIR/.claude/skills/sprint/SKILL.md" "Estimate confidence"
require_text "$ROOT_DIR/.claude/skills/introspect/SKILL.md" "human-equivalent-only estimates must return"
require_text "$ROOT_DIR/.claude/skills/workflow/SKILL.md" "scripts/parallel-capacity.sh --json"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/positive.md" <<'EOF'
## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: subagents
- Capacity evidence: scripts/parallel-capacity.sh --json, Codex max_threads, MAX_PARALLEL_AGENTS
- Effective lanes: 5 of ceiling 10
- Critical path: P1 -> P4 -> verification
- Agent wall-clock: optimistic 4h / likely 7h / pessimistic 11h
- Agent-hours: 22-34 total active work across all lanes
- Human touch time: 45-90 minutes for review and credentials
- Calendar blockers: CI queue and production deploy credentials
- Confidence: medium because CI duration is unproven
- Human-equivalent baseline: 2-4 engineer-weeks, secondary comparison only
EOF

cat > "$TMPDIR/human-only.md" <<'EOF'
## Agent-Native Estimate

- Estimate type: human-equivalent
- Human-equivalent baseline: 6 weeks
- Confidence: high
EOF

cat > "$TMPDIR/linear.md" <<'EOF'
## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: subagents
- Capacity evidence: scripts/parallel-capacity.sh --json
- Effective lanes: 10 of ceiling 10
- Critical path: all packets at once
- Agent wall-clock: 1 day because 10 agents means 10x faster
- Agent-hours: 10
- Human touch time: none
- Calendar blockers: none
- Confidence: high
EOF

validate_estimate_file "$TMPDIR/positive.md" || fail "positive estimate fixture was rejected"
if validate_estimate_file "$TMPDIR/human-only.md"; then
  fail "human-equivalent-only estimate fixture was accepted"
fi
if validate_estimate_file "$TMPDIR/linear.md"; then
  fail "linear scaling estimate fixture was accepted"
fi

echo "[PASS] Agent-Native Estimate contract smoke test passed"
