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
echo "[1/4] Memory system..."
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/memory-auto.sh" ]; then
    bash "$SCRIPT_DIR/memory-auto.sh" start 2>/dev/null || true
fi
if [ -f "$SCRIPT_DIR/memory.sh" ]; then
    bash "$SCRIPT_DIR/memory.sh" stats 2>/dev/null | head -10
fi
echo ""

# Step 3: Version Check
echo "[3/4] Version information..."
echo "Claude Code: $(claude --version 2>/dev/null || echo 'not found')"
echo "Model: MiniMax M2.7 Highspeed (100 TPS, 204K context)"
echo ""

# Step 4: Quick Health Check
echo "[4/4] Health check..."
PASS=0
FAIL=0

# Check skills
SKILL_COUNT=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -ge 15 ]; then
    echo "  [PASS] $SKILL_COUNT skills found"
    PASS=$((PASS+1))
else
    echo "  [FAIL] Expected 15 skills, found $SKILL_COUNT"
    FAIL=$((FAIL+1))
fi

# Check rules
RULE_COUNT=$(find .claude/rules -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$RULE_COUNT" -ge 5 ]; then
    echo "  [PASS] $RULE_COUNT rules found"
    PASS=$((PASS+1))
else
    echo "  [FAIL] Expected 5+ rules, found $RULE_COUNT"
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
echo "Philosophy: SPEC-First, PEV loops, Quality Gates"
echo "Skills: /workflow, /align, /autoplan, /verify, /review, /qa,"
echo "        /ship, /investigate, /sprint, /overnight, /council"
echo ""
echo "Start with: ./scripts/test-harness.sh to verify setup"
echo ""
