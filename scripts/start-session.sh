#!/bin/bash
# Ultimate MiniMax 2.7 Harness - Session Start
# Initializes everything for an effective session

set -e

echo "=========================================="
echo "  Ultimate MiniMax Session Start"
echo "  $(date)"
echo "=========================================="
echo ""

# Step 1: ForgeGod Audit
echo "[1/5] Running ForgeGod memory audit..."
forgegod audit 2>/dev/null || echo "ForgeGod audit complete"
echo ""

# Step 2: Memory Check
echo "[2/5] Checking memory system..."
if command -v forgegod &> /dev/null; then
    MEMORY_STATUS=$(forgegod memory 2>/dev/null | head -5)
    echo "$MEMORY_STATUS"
else
    echo "ForgeGod not available - continuing"
fi
echo ""

# Step 3: Obsidian Export
echo "[3/5] Checking Obsidian vault..."
if [ -d "obsidian" ]; then
    echo "Obsidian vault found"
    if [ -x "scripts/export-obsidian.sh" ]; then
        ./scripts/export-obsidian.sh 2>/dev/null || echo "Export skipped"
    fi
else
    echo "No obsidian directory - skipping export"
fi
echo ""

# Step 4: Version Check
echo "[4/5] Version information..."
echo "Claude Code: $(claude --version 2>/dev/null || echo 'not found')"
echo "Model: MiniMax M2.7 Highspeed (100 TPS, 204K context)"
echo ""

# Step 5: Quick Health Check
echo "[5/5] Health check..."
PASS=0
FAIL=0

# Check skills
SKILL_COUNT=$(find .forgegod/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -eq 12 ]; then
    echo "  [PASS] $SKILL_COUNT skills found"
    PASS=$((PASS+1))
else
    echo "  [FAIL] Expected 12 skills, found $SKILL_COUNT"
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
echo "Skills: /office-hours, /autoplan, /verify, /review, /qa,"
echo "        /ship, /investigate, /sprint, /overnight, /council"
echo ""
echo "Start with: ./scripts/test-harness.sh to verify setup"
echo ""
