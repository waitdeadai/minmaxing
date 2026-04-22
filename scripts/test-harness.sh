#!/bin/bash
# Ultimate MiniMax 2.7 Harness - Comprehensive Test Suite
# 19+ verification tests

set -e

ROOT_DIR="$(pwd)"

echo "=========================================="
echo "  minmaxing Test Suite"
echo "  $(date)"
echo "=========================================="
echo ""

PASS=0
FAIL=0

test_pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
test_fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
test_warn() { echo "  [WARN] $1"; }

# ========================================
# Core Infrastructure
# ========================================

echo "[Core Infrastructure]"
echo ""

# Test 1: Claude Code
echo "[1] Claude Code Available"
if command -v claude &> /dev/null; then
    VERSION=$(claude --version 2>/dev/null || echo "unknown")
    test_pass "Claude Code $VERSION"
else
    test_fail "Claude Code not installed"
fi

# Test 2: MiniMax Model Config
echo "[2] MiniMax Model Config"
if grep -q "MiniMax-M2.7-highspeed" .claude/settings.json 2>/dev/null; then
    test_pass "MiniMax M2.7 Highspeed configured"
else
    test_fail "MiniMax M2.7 not configured"
fi

# Test 3: Settings
echo "[3] Settings Files"
if [ -f ".claude/settings.json" ]; then
    test_pass ".claude/settings.json exists"
else
    test_fail ".claude/settings.json missing"
fi

# Test 3a: Taste Kernel Structure
echo "[3a] Taste Kernel Structure"
KERNEL_OK=true
for section in "^version:" "^frontend:" "^backend:" "^## Frontend System$" "^### Interaction & Accessibility$" "^## Backend System$" "^### API & Contract Design$" "^## Do's and Don'ts$"; do
    if ! grep -Eq "$section" taste.md 2>/dev/null; then
        KERNEL_OK=false
    fi
done
for section in "^version:" "^## Audience$" "^## Values & Tradeoffs$" "^## Experience Promise$"; do
    if ! grep -Eq "$section" taste.vision 2>/dev/null; then
        KERNEL_OK=false
    fi
done
if [ "$KERNEL_OK" = true ]; then
    test_pass "taste.md + taste.vision use the hybrid kernel structure"
else
    test_fail "taste kernel files are missing required hybrid sections"
fi

# Test 3b: Taste Template Generation
echo "[3b] Taste Template Generation"
TMP_TASTE_DIR="$(mktemp -d)"
if (
    cd "$TMP_TASTE_DIR" &&
    bash "$ROOT_DIR/scripts/taste.sh" init >/dev/null &&
    grep -q "^frontend:" taste.md &&
    grep -q "^backend:" taste.md &&
    grep -q "^## Frontend System$" taste.md &&
    grep -q "^### Security & Privacy$" taste.md &&
    grep -q "^## Experience Promise$" taste.vision
); then
    test_pass "taste.sh init generates the richer hybrid template"
else
    test_fail "taste.sh init did not generate the expected hybrid template"
fi
rm -rf "$TMP_TASTE_DIR"

# Test 3c: Align Bootstrap Contract
echo "[3c] Align Bootstrap Contract"
ALIGN_OK=true
while IFS= read -r pattern; do
    if [ -n "$pattern" ] && ! grep -Fq "$pattern" .claude/skills/align/SKILL.md 2>/dev/null; then
        ALIGN_OK=false
    fi
done <<'EOF'
Bootstrap Interview (10 questions)
What visual personality should the UI have, and what should it avoid?
What error-handling, observability, rollback, and security rules are required?
What code style, architecture, and naming rules are preferred?
## Frontend System
## Backend System
## Experience Promise
EOF
if [ "$ALIGN_OK" = true ]; then
    test_pass "/align --bootstrap documents the richer kernel interview"
else
    test_fail "/align --bootstrap is missing required hybrid kernel prompts"
fi

# ========================================
# Skills (12 Required)
# ========================================

echo ""
echo "[Skills - 12 Required]"
echo ""

# Test 4: Skills Count
echo "[4] Skills Directory"
SKILL_COUNT=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -ge 10 ]; then
    test_pass "$SKILL_COUNT skills found"
else
    test_fail "Expected 10+ skills, found $SKILL_COUNT"
fi

# Test 5: Critical Skills Content
echo "[5] Critical Skills Content"
for skill in workflow align audit autoplan verify review qa ship investigate; do
    if [ -f ".claude/skills/$skill/SKILL.md" ]; then
        LINES=$(wc -l < ".claude/skills/$skill/SKILL.md" | tr -d ' ')
        if [ "$LINES" -gt 20 ]; then
            test_pass "/$skill ($LINES lines)"
        else
            test_fail "/$skill is minimal (${LINES} lines)"
        fi
    else
        test_fail "/$skill SKILL.md missing"
    fi
done

# ========================================
# Rules (5+ Required)
# ========================================

echo ""
echo "[Rules - 5+ Required]"
echo ""

# Test 6: Rules Count
echo "[6] Rules Directory"
RULE_COUNT=$(find .claude/rules -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$RULE_COUNT" -ge 5 ]; then
    test_pass "$RULE_COUNT rules found"
else
    test_fail "Expected 5+ rules, found $RULE_COUNT"
fi

# Test 7: Individual Rules
echo "[7] Individual Rules"
for rule in quality context delegation spec verify; do
    if [ -f ".claude/rules/$rule.rules.md" ]; then
        LINES=$(wc -l < ".claude/rules/$rule.rules.md" | tr -d ' ')
        if [ "$LINES" -gt 10 ]; then
            test_pass "/$rule.rules.md ($LINES lines)"
        else
            test_fail "/$rule.rules.md is minimal (${LINES} lines)"
        fi
    else
        test_fail "/$rule.rules.md missing"
    fi
done

# ========================================
# Scripts (5 Required)
# ========================================

echo ""
echo "[Scripts - 5 Required]"
echo ""

# Test 8: Scripts Executable
echo "[8] Scripts Executable"
ALL_EXEC=true
for script in scripts/*.sh; do
    if [ -f "$script" ]; then
        if [ ! -x "$script" ]; then
            ALL_EXEC=false
            test_fail "$(basename $script) not executable"
        fi
    fi
done
if [ "$ALL_EXEC" = true ]; then
    test_pass "All scripts executable"
fi

# Test 9: Individual Scripts
echo "[9] Individual Scripts"
for script in start-session sprint overnight-loop council test-harness; do
    if [ -f "scripts/$script.sh" ]; then
        test_pass "$script.sh exists"
    else
        test_fail "$script.sh missing"
    fi
done

# ========================================
# Documentation
# ========================================

echo ""
echo "[Documentation]"
echo ""

# Test 10: CLAUDE.md
echo "[10] CLAUDE.md"
if [ -f "CLAUDE.md" ]; then
    LINES=$(wc -l < "CLAUDE.md" | tr -d ' ')
    if [ "$LINES" -gt 50 ]; then
        test_pass "CLAUDE.md exists ($LINES lines)"
    else
        test_warn "CLAUDE.md is minimal ($LINES lines)"
    fi
else
    test_fail "CLAUDE.md missing"
fi

# Test 11: SPEC-First Documentation
echo "[11] SPEC-First Documentation"
if grep -q "SPEC" CLAUDE.md 2>/dev/null; then
    test_pass "SPEC-first philosophy documented"
else
    test_fail "SPEC-first not documented in CLAUDE.md"
fi

# Test 12: PEV Loop Documentation
echo "[12] PEV Loop Documentation"
if grep -q "PEV" CLAUDE.md 2>/dev/null; then
    test_pass "PEV loop documented"
else
    test_fail "PEV loop not documented in CLAUDE.md"
fi

# Test 13: Socratic Documentation
echo "[13] Socratic Questioning Documentation"
if grep -q "Socratic\|taste alignment" CLAUDE.md 2>/dev/null; then
    test_pass "Socratic questioning documented"
else
    test_fail "Socratic questioning not documented"
fi

# ========================================
# Memory System
# ========================================

echo ""
echo "[Memory System]"
echo ""

# Test 14: ForgeGod
echo "[14] ForgeGod Memory"
if command -v forgegod &> /dev/null; then
    test_pass "ForgeGod installed"
else
    test_fail "ForgeGod not installed"
fi

# ========================================
# Git Safety
# ========================================

echo ""
echo "[Git Safety]"
echo ""

# Test 15: Git Ignore
echo "[15] Git Ignore"
if [ -f ".gitignore" ] && grep -q "settings.local.json" .gitignore; then
    test_pass "API keys gitignored"
else
    test_fail ".gitignore missing or incomplete"
fi

# Optional integration smoke test
echo "[16] Workflow Smoke Test"
if [ "${RUN_CLAUDE_INTEGRATION:-0}" = "1" ]; then
    if bash scripts/workflow-smoke.sh; then
        test_pass "/workflow runtime smoke test"
    else
        test_fail "/workflow runtime smoke test failed"
    fi
else
    test_warn "Workflow smoke test skipped (set RUN_CLAUDE_INTEGRATION=1)"
fi

# ========================================
# Summary
# ========================================

echo ""
echo "=========================================="
echo "  Summary: $PASS passed, $FAIL failed"
echo "=========================================="
echo ""

if [ $FAIL -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi
