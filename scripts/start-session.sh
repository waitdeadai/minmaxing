#!/bin/bash
# Ultimate MiniMax 2.7 Harness - Session Start
# Initializes everything for an effective session

set -e

echo "=========================================="
echo "  Ultimate MiniMax Session Start"
echo "  $(date)"
echo "=========================================="
echo ""

# Step 1: Memory System
echo "[1/5] Memory system..."
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/memory-auto.sh" ]; then
    bash "$SCRIPT_DIR/memory-auto.sh" start 2>/dev/null || true
fi
if [ -f "$SCRIPT_DIR/memory.sh" ]; then
    bash "$SCRIPT_DIR/memory.sh" stats 2>/dev/null | head -10
    bash "$SCRIPT_DIR/memory.sh" health 2>/dev/null | tail -1 || echo "status: disabled"
fi
if [ -f "$SCRIPT_DIR/memory-eval.sh" ]; then
    bash "$SCRIPT_DIR/memory-eval.sh" --summary 2>/dev/null || echo "memory freshness: degraded health=disabled fallback=local_truth_surfaces"
fi
echo ""

# Step 2: Working State
echo "[2/5] Working state..."
if [ -f ".minimaxing/state/CURRENT.md" ]; then
    echo "Working state: .minimaxing/state/CURRENT.md available for compaction-safe resume"
else
    echo "Working state: none yet (created automatically after the first Claude Code turn)"
fi
SPEC_ARCHIVE_COUNT=$(find .taste/specs -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo "Spec archive: ${SPEC_ARCHIVE_COUNT:-0} archived spec(s) in .taste/specs"
echo ""

# Step 3: Version Check
echo "[3/5] Version information..."
echo "Claude Code: $(claude --version 2>/dev/null || echo 'not found')"
echo "Model: MiniMax M2.7 Highspeed (provider capability: 100 TPS, 204K context)"
if [ -f "$SCRIPT_DIR/parallel-capacity.sh" ]; then
    bash "$SCRIPT_DIR/parallel-capacity.sh" --summary 2>/dev/null || true
fi
echo ""

# Step 4: Quick Health Check
echo "[4/5] Health check..."
PASS=0
FAIL=0

# Check skills
SKILL_COUNT=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -ge 22 ]; then
    echo "  [PASS] $SKILL_COUNT skills found"
    PASS=$((PASS+1))
else
    echo "  [FAIL] Expected 22 skills, found $SKILL_COUNT"
    FAIL=$((FAIL+1))
fi

# Check rules
RULE_COUNT=$(find .claude/rules -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$RULE_COUNT" -ge 6 ]; then
    echo "  [PASS] $RULE_COUNT rules found"
    PASS=$((PASS+1))
else
    echo "  [FAIL] Expected 6+ rules, found $RULE_COUNT"
    FAIL=$((FAIL+1))
fi

# Check CLAUDE.md
if [ -f "CLAUDE.md" ]; then
    echo "  [PASS] CLAUDE.md exists"
    PASS=$((PASS+1))
else
    echo "  [FAIL] CLAUDE.md missing"
    FAIL=$((FAIL+1))
fi

# Check settings
if grep -q "MiniMax-M2.7-highspeed" .claude/settings.json 2>/dev/null; then
    echo "  [PASS] MiniMax model configured"
    PASS=$((PASS+1))
else
    echo "  [FAIL] MiniMax model not configured"
    FAIL=$((FAIL+1))
fi

echo ""
echo "=========================================="
echo "  Session Ready"
echo "  $PASS checks passed, $FAIL failed"
echo "=========================================="
echo ""
echo "[5/5] Ready"
echo "Philosophy: governed autonomy — delegate execution, keep judgment, require evidence"
echo "Planning: Agent-Native Estimate before non-trivial plan or SPEC freeze"
echo "Fresh repos: run /tastebootstrap before /workflow"
echo "Skills: /tastebootstrap, /workflow, /digestflow, /align, /autoplan, /verify,"
echo "        /review, /qa, /ship, /investigate, /sprint, /overnight, /council,"
echo "        /audit, /deepresearch, /webresearch, /browse, /introspect, /codesearch,"
echo "        /memory, /agentfactory, /parallel"
echo ""
echo "Start with: ./scripts/test-harness.sh to verify setup"
echo "Optional runtime check: RUN_CLAUDE_INTEGRATION=1 bash scripts/test-harness.sh"
echo ""
