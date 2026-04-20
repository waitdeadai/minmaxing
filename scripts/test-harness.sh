#!/bin/bash
# minmaxing - Comprehensive Test Suite

echo "=========================================="
echo "  minmaxing Test Suite"
echo "  $(date)"
echo "=========================================="
echo ""

PASS=0
FAIL=0

test_pass() { echo "✓ PASS: $1"; PASS=$((PASS+1)); }
test_fail() { echo "✗ FAIL: $1"; FAIL=$((FAIL+1)); }

# Test 1: Claude Code
echo "[1] Claude Code Available"
if command -v claude &> /dev/null; then
    VERSION=$(claude --version 2>/dev/null || echo "unknown")
    test_pass "Claude Code $VERSION"
else
    test_fail "Claude Code not installed"
fi

# Test 2: MiniMax MCP
echo "[2] MiniMax MCP Server"
if claude mcp list 2>/dev/null | grep -q "MiniMax"; then
    test_pass "MiniMax MCP found"
else
    test_fail "MiniMax MCP not found"
fi

# Test 3: Skills
echo "[3] Skills Directory"
SKILL_COUNT=$(find .forgegod/skills -name "SKILL.md" 2>/dev/null | wc -l)
if [ "$SKILL_COUNT" -eq 10 ]; then
    test_pass "10 skills found"
else
    test_fail "Expected 10 skills, found $SKILL_COUNT"
fi

# Test 4: Rules
echo "[4] Rules Directory"
RULE_COUNT=$(find .claude/rules -name "*.md" 2>/dev/null | wc -l)
if [ "$RULE_COUNT" -eq 5 ]; then
    test_pass "5 rules found"
else
    test_fail "Expected 5 rules, found $RULE_COUNT"
fi

# Test 5: Scripts
echo "[5] Scripts Executable"
ALL_EXEC=true
for script in scripts/*.sh; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        ALL_EXEC=false
    fi
done
if [ "$ALL_EXEC" = true ]; then
    test_pass "All scripts executable"
else
    test_fail "Some scripts not executable"
fi

# Test 6: Settings
echo "[6] Settings Files"
[ -f ".claude/settings.json" ] && test_pass ".claude/settings.json exists" || test_fail ".claude/settings.json missing"
[ -f "settings.json" ] && test_pass "settings.json exists" || test_fail "settings.json missing"

# Test 7: CLAUDE.md
echo "[7] CLAUDE.md"
[ -f "CLAUDE.md" ] && test_pass "CLAUDE.md exists" || test_fail "CLAUDE.md missing"

# Test 8: ForgeGod
echo "[8] Memory System"
if command -v forgegod &> /dev/null; then
    test_pass "ForgeGod installed"
else
    test_fail "ForgeGod not installed"
fi

# Test 9: Git Ignore
echo "[9] Git Ignore"
if [ -f ".gitignore" ] && grep -q "settings.local.json" .gitignore; then
    test_pass "API keys gitignored"
else
    test_fail ".gitignore missing or incomplete"
fi

# Test 10: MiniMax Model
echo "[10] MiniMax Model Config"
if grep -q "MiniMax-M2.7-highspeed" .claude/settings.json 2>/dev/null; then
    test_pass "MiniMax M2.7 Highspeed configured"
else
    test_fail "MiniMax M2.7 not configured"
fi

# Test 11: Effort Level
echo "[11] Effort Level"
if grep -q "CLAUDE_CODE_EFFORT_LEVEL" .claude/settings.json 2>/dev/null; then
    test_pass "Effort level configured"
else
    test_fail "Effort level not configured"
fi

echo ""
echo "=========================================="
echo "  Summary: $PASS passed, $FAIL failed"
echo "=========================================="

[ $FAIL -eq 0 ]
