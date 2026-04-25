#!/bin/bash
# Ultimate MiniMax 2.7 Harness - Comprehensive Test Suite
# 20+ verification tests

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

# Test 3aa: Team-Safe Settings Profile
echo "[3aa] Team-Safe Settings Profile"
if [ -f ".claude/settings.team-safe.example.json" ] && \
   python3 -m json.tool .claude/settings.team-safe.example.json >/dev/null 2>&1 && \
   grep -Fq '"defaultMode": "acceptEdits"' .claude/settings.team-safe.example.json 2>/dev/null; then
    test_pass "team-safe settings example is valid and uses acceptEdits"
else
    test_fail "team-safe settings example is missing, invalid, or not using acceptEdits"
fi

# Test 3a: Taste Kernel Structure
echo "[3a] Taste Kernel Structure"
KERNEL_OK=true
for section in "^version:" "^principles:" "^experience:" "^interfaces:" "^system:" "^delivery:" "^## Experience & Interaction$" "^### Accessibility & Inclusion$" "^## Interfaces & Contracts$" "^## System Behavior$" "^### Security & Privacy$" "^## Do's and Don'ts$"; do
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
    test_pass "taste.md + taste.vision use the operating kernel structure"
else
    test_fail "taste kernel files are missing required operating-kernel sections"
fi

# Test 3b: Taste Template Generation
echo "[3b] Taste Template Generation"
TMP_TASTE_DIR="$(mktemp -d)"
if (
    cd "$TMP_TASTE_DIR" &&
    bash "$ROOT_DIR/scripts/taste.sh" init >/dev/null &&
    grep -q "^principles:" taste.md &&
    grep -q "^interfaces:" taste.md &&
    grep -q "^## Experience & Interaction$" taste.md &&
    grep -q "^### Security & Privacy$" taste.md &&
    grep -q "^## Experience Promise$" taste.vision
); then
    test_pass "taste.sh init generates the operating-kernel template"
else
    test_fail "taste.sh init did not generate the expected operating-kernel template"
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
What kind of experience should this project create, and what should it avoid?
What public interfaces or contracts must stay explicit and stable?
What error-handling, observability, rollback, and security rules are required?
What code style, architecture, and naming rules are preferred?
## Experience & Interaction
## Interfaces & Contracts
## System Behavior
## Experience Promise
EOF
if [ "$ALIGN_OK" = true ]; then
    test_pass "/align --bootstrap documents the operating-kernel interview"
else
    test_fail "/align --bootstrap is missing required operating-kernel prompts"
fi

# Test 3d: Taste Bootstrap Skill
echo "[3d] Taste Bootstrap Skill"
TASTEBOOTSTRAP_OK=true
while IFS= read -r pattern; do
    if [ -n "$pattern" ] && ! grep -Fq "$pattern" .claude/skills/tastebootstrap/SKILL.md 2>/dev/null; then
        TASTEBOOTSTRAP_OK=false
    fi
done <<'EOF'
# /tastebootstrap
Bootstrap Interview (10 questions)
What kind of experience should this project create, and what should it avoid?
What public interfaces or contracts must stay explicit and stable?
What error-handling, observability, rollback, and security rules are required?
What code style, architecture, and naming rules are preferred?
TASTE_DEFINED
EOF
if [ "$TASTEBOOTSTRAP_OK" = true ]; then
    test_pass "/tastebootstrap documents the fresh-repo kernel interview"
else
    test_fail "/tastebootstrap is missing required bootstrap prompts"
fi

# Test 3e: Efficacy-First Parallelism Contract
echo "[3e] Efficacy-First Parallelism"
PARALLEL_OK=true
while IFS= read -r target; do
    if [ -n "$target" ] && ! grep -Fq "$target" .claude/rules/parallelism.rules.md 2>/dev/null; then
        PARALLEL_OK=false
    fi
done <<'EOF'
ceilings, not quotas
effective_agents
Do not inflate the packet count just to hit the ceiling.
EOF
if [ "$PARALLEL_OK" = true ] && \
   grep -Fq "ceiling, not a quota" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "Do not split work just to fill slots." .claude/skills/sprint/SKILL.md 2>/dev/null && \
   grep -Fq "distinct branches" .claude/skills/deepresearch/SKILL.md 2>/dev/null && \
   grep -Fq "The max of 10 reports is a ceiling, not a target." .claude/skills/digestflow/SKILL.md 2>/dev/null && \
   grep -Fq "not automatically a 10-agent sprint" .claude/skills/sprint/SKILL.md 2>/dev/null && \
   grep -Fq "Effective Agent Budget" obsidian/Memory/Patterns/parallel-workers.md 2>/dev/null && \
   grep -Fq "effective subagent budget" AGENTS.md 2>/dev/null && \
   ! grep -Fq "SPEC.md: [created, updated, reused, or not needed]" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   ! grep -Fq "always use the full agent pool" .claude/skills/sprint/SKILL.md 2>/dev/null && \
   ! grep -Fq "6-8 parallel tasks per phase" .claude/skills/autoplan/SKILL.md 2>/dev/null && \
   ! grep -Fq "10-agent parallelism for max throughput" .claude/skills/align/SKILL.md 2>/dev/null; then
    test_pass "parallelism guidance is efficacy-first across rules and core skills"
else
    test_fail "parallelism guidance still rewards slot-filling over efficacy"
fi

# Test 3f: Effectiveness-First DeepResearch Contract
echo "[3f] Effectiveness-First DeepResearch"
if grep -Fq "collaborative research plan" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "search -> read -> refine" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "source ledger" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "reviewed but not cited" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "conflicting evidence" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "follow-up research" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "collaborative research plan" .claude/skills/deepresearch/SKILL.md 2>/dev/null && \
   grep -Fq "source ledger" .claude/skills/deepresearch/SKILL.md 2>/dev/null && \
   grep -Fq "MAX_PARALLEL_AGENTS" .claude/skills/webresearch/SKILL.md 2>/dev/null && \
   grep -Fqi "backward-compatible" .claude/skills/browse/SKILL.md 2>/dev/null && \
   grep -Fq "collaborative research plan" .claude/skills/autoplan/SKILL.md 2>/dev/null && \
   grep -Fq "source ledger" .claude/skills/autoplan/SKILL.md 2>/dev/null && \
   grep -Fq 'effectiveness-first `deepresearch` protocol' README.md 2>/dev/null && \
   grep -Fq 'effectiveness-first `deepresearch` protocol' CLAUDE.md 2>/dev/null && \
   grep -Fq "/deepresearch" README.md 2>/dev/null && \
   grep -Fq "/webresearch" README.md 2>/dev/null && \
   grep -Fq "search -> read -> refine" AGENTS.md 2>/dev/null; then
    test_pass "research guidance mirrors the effectiveness-first deepresearch protocol"
else
    test_fail "deep research guidance is missing the new investigation contract"
fi

# Test 3g: Hard-Gate Introspection Contract
echo "[3g] Hard-Gate Introspection"
if grep -Fq "pre-plan" .claude/skills/introspect/SKILL.md 2>/dev/null && \
   grep -Fq "post-implementation" .claude/skills/introspect/SKILL.md 2>/dev/null && \
   grep -Fq "after-test-failure" .claude/skills/introspect/SKILL.md 2>/dev/null && \
   grep -Fq "pre-push" .claude/skills/introspect/SKILL.md 2>/dev/null && \
   grep -Fq "manual" .claude/skills/introspect/SKILL.md 2>/dev/null && \
   grep -Fq "Blocker Decision" .claude/skills/introspect/SKILL.md 2>/dev/null && \
   grep -Fq "downgrade confidence" .claude/skills/introspect/SKILL.md 2>/dev/null && \
   grep -Fq "only public slash command" .claude/skills/introspect/SKILL.md 2>/dev/null && \
   grep -Fq "instrospect" AGENTS.md 2>/dev/null && \
   grep -Fq "## Introspection" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "after-test-failure" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "pre-push" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "hidden assumptions" .claude/skills/audit/SKILL.md 2>/dev/null && \
   grep -Fq "premature certainty" .claude/skills/deepresearch/SKILL.md 2>/dev/null && \
   grep -Fq "SPEC.md is frozen" .claude/skills/autoplan/SKILL.md 2>/dev/null && \
   grep -Fq 'not a substitute for `/introspect`' .claude/skills/review/SKILL.md 2>/dev/null && \
   grep -Fq "/introspect" README.md 2>/dev/null && \
   grep -Fq "20 skills" README.md 2>/dev/null && \
   grep -Fq "Introspection Gate" CLAUDE.md 2>/dev/null && \
   grep -Fq "hard gate" AGENTS.md 2>/dev/null && \
   [ ! -f ".claude/skills/instrospect/SKILL.md" ] && \
   ! grep -Fq "/instrospect" README.md 2>/dev/null && \
   ! grep -Fq "/instrospect" CLAUDE.md 2>/dev/null; then
    test_pass "introspection is a hard gate across workflow, skills, docs, and instructions"
else
    test_fail "introspection hard-gate contract is incomplete"
fi

# Test 3h: Governed Autonomy Truth Surfaces
echo "[3h] Governed Autonomy Truth Surfaces"
if grep -Fq "Delegate execution. Keep judgment. Require evidence." README.md 2>/dev/null && \
   grep -Fq "governed Claude Code harness" README.md 2>/dev/null && \
   grep -Fq "Verification Metadata" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "Independent verification pass" .claude/skills/verify/SKILL.md 2>/dev/null && \
   grep -Fq "bash scripts/memory.sh health" README.md 2>/dev/null && \
   grep -Fq "bash scripts/memory.sh health" CLAUDE.md 2>/dev/null && \
   grep -Fq "Expected 20 skills" scripts/start-session.sh 2>/dev/null && \
   grep -Fq "Expected 6+ rules" scripts/start-session.sh 2>/dev/null && \
   grep -Fq "settings.team-safe.example.json" README.md 2>/dev/null && \
   ! grep -Fq "Expected 16 skills" scripts/start-session.sh 2>/dev/null && \
   ! grep -Fq "Expected $((20 - 1)) skills" scripts/start-session.sh 2>/dev/null && \
   ! grep -Fq "Expected 5+ rules" scripts/start-session.sh 2>/dev/null && \
   ! grep -Fq "verifies everything before you accept it" README.md 2>/dev/null && \
   ! grep -Fq "Every decision, every fix, every shipped feature is remembered" README.md 2>/dev/null && \
   ! grep -Fq "Every external claim gets verified" README.md 2>/dev/null && \
   ! grep -Fq "Zero safety checks" README.md 2>/dev/null && \
   ! grep -Fq "Not the same AI" README.md 2>/dev/null && \
   ! grep -Fq "This is NOT the same AI" .claude/skills/verify/SKILL.md 2>/dev/null && \
   ! grep -Fq "Same model. Better results." README.md 2>/dev/null; then
    test_pass "public and runtime claims are governed, evidence-first, and contract-tested"
else
    test_fail "governed-autonomy truth surfaces contain stale counts or unsupported overclaims"
fi

# Test 3i: Digestflow External Report Intake Contract
echo "[3i] Digestflow Report Intake Contract"
if [ -f ".claude/skills/digestflow/SKILL.md" ] && \
   grep -Fq "# /digestflow" .claude/skills/digestflow/SKILL.md 2>/dev/null && \
   grep -Fq "Report Intake" .claude/skills/digestflow/SKILL.md 2>/dev/null && \
   grep -Fq "report-derived" .claude/skills/digestflow/SKILL.md 2>/dev/null && \
   grep -Fq "untrusted candidate evidence" .claude/skills/digestflow/SKILL.md 2>/dev/null && \
   grep -Fq "1-10" .claude/skills/digestflow/SKILL.md 2>/dev/null && \
   grep -Fq "source ledger" .claude/skills/digestflow/SKILL.md 2>/dev/null && \
   grep -Fq "Contradiction" .claude/skills/digestflow/SKILL.md 2>/dev/null && \
   grep -Fq "no-persist" .claude/skills/digestflow/SKILL.md 2>/dev/null && \
   grep -Fq "/introspect" .claude/skills/digestflow/SKILL.md 2>/dev/null && \
   grep -Fq "full workflow" .claude/skills/digestflow/SKILL.md 2>/dev/null && \
   grep -Fq "Report Intake" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "/digestflow" README.md 2>/dev/null && \
   grep -Fq "/digestflow" CLAUDE.md 2>/dev/null && \
   grep -Fq "/digestflow" AGENTS.md 2>/dev/null && \
   grep -Fq "/digestflow" scripts/start-session.sh 2>/dev/null && \
   [ -f "scripts/digestflow-smoke.sh" ]; then
    test_pass "/digestflow treats external reports as report-derived evidence before full workflow execution"
else
    test_fail "/digestflow report intake contract is incomplete"
fi

# ========================================
# Skills (20 Expected)
# ========================================

echo ""
echo "[Skills - 20 Expected]"
echo ""

# Test 4: Skills Count
echo "[4] Skills Directory"
SKILL_COUNT=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -ge 20 ]; then
    test_pass "$SKILL_COUNT skills found"
else
    test_fail "Expected 20+ skills, found $SKILL_COUNT"
fi

# Test 5: Critical Skills Content
echo "[5] Critical Skills Content"
for skill in tastebootstrap workflow digestflow align audit autoplan deepresearch webresearch introspect verify review qa ship investigate; do
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
# Rules (6+ Required)
# ========================================

echo ""
echo "[Rules - 6+ Required]"
echo ""

# Test 6: Rules Count
echo "[6] Rules Directory"
RULE_COUNT=$(find .claude/rules -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$RULE_COUNT" -ge 6 ]; then
    test_pass "$RULE_COUNT rules found"
else
    test_fail "Expected 6+ rules, found $RULE_COUNT"
fi

# Test 7: Individual Rules
echo "[7] Individual Rules"
for rule in quality context delegation parallelism spec verify; do
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
# Scripts (6 Required)
# ========================================

echo ""
echo "[Scripts - 6 Required]"
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
for script in start-session sprint overnight-loop council test-harness state spec-archive digestflow-smoke; do
    if [ -f "scripts/$script.sh" ]; then
        test_pass "$script.sh exists"
    else
        test_fail "$script.sh missing"
    fi
done

# Test 9a: Compaction-Safe Working State
echo "[9a] Compaction-Safe Working State"
STATE_OK=true
for file in \
    "scripts/state.sh" \
    ".claude/hooks/state-sessionstart.sh" \
    ".claude/hooks/state-precompact.sh" \
    ".claude/hooks/state-postcompact.sh" \
    ".claude/hooks/state-stop.sh"; do
    if [ ! -x "$file" ]; then
        STATE_OK=false
    fi
done

if ! python3 -m json.tool .claude/settings.json >/dev/null 2>&1; then
    STATE_OK=false
fi

for pattern in \
    '"SessionStart"' \
    '"PreCompact"' \
    '"PostCompact"' \
    '"Stop"' \
    'state-sessionstart.sh' \
    'state-precompact.sh' \
    'state-postcompact.sh' \
    'state-stop.sh'; do
    if ! grep -Fq "$pattern" .claude/settings.json 2>/dev/null; then
        STATE_OK=false
    fi
done

TMP_STATE_DIR="$(mktemp -d)"
if MINIMAXING_STATE_DIR="$TMP_STATE_DIR/state" CLAUDE_PROJECT_DIR="$ROOT_DIR" \
    bash scripts/state.sh snapshot <<'EOF' >/dev/null 2>&1
{"session_id":"state-test","hook_event_name":"Stop","last_assistant_message":"done sk-testSECRET1234567890"}
EOF
then
    if [ ! -f "$TMP_STATE_DIR/state/CURRENT.md" ]; then
        STATE_OK=false
    fi
    if grep -q "sk-testSECRET1234567890" "$TMP_STATE_DIR/state/CURRENT.md" 2>/dev/null; then
        STATE_OK=false
    fi
    HYDRATE_OUTPUT="$(MINIMAXING_STATE_DIR="$TMP_STATE_DIR/state" CLAUDE_PROJECT_DIR="$ROOT_DIR" bash scripts/state.sh hydrate <<'EOF'
{"hook_event_name":"SessionStart","source":"compact"}
EOF
)"
    if ! printf '%s' "$HYDRATE_OUTPUT" | python3 -c 'import json,sys; data=json.load(sys.stdin); assert data["hookSpecificOutput"]["hookEventName"] == "SessionStart"; assert "additionalContext" in data["hookSpecificOutput"]' >/dev/null 2>&1; then
        STATE_OK=false
    fi
else
    STATE_OK=false
fi
rm -rf "$TMP_STATE_DIR"

if [ "$STATE_OK" = true ]; then
    test_pass "working state hooks create redacted state and hydrate context"
else
    test_fail "working state hooks or state.sh are not wired correctly"
fi

# Test 9b: SPEC Archive Lifecycle
echo "[9b] SPEC Archive Lifecycle"
SPEC_ARCHIVE_OK=true
TMP_SPEC_DIR="$(mktemp -d)"

cat > "$TMP_SPEC_DIR/SPEC.md" <<'EOF'
# SPEC: Archive Demo

## Problem Statement
Preserve this completed spec.
EOF

if ! CLAUDE_PROJECT_DIR="$TMP_SPEC_DIR" bash "$ROOT_DIR/scripts/spec-archive.sh" closeout "Archive Demo" "verified accept" >/dev/null 2>&1; then
    SPEC_ARCHIVE_OK=false
fi

ARCHIVE_COUNT="$(find "$TMP_SPEC_DIR/.taste/specs" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')"
ARCHIVE_FILE="$(find "$TMP_SPEC_DIR/.taste/specs" -maxdepth 1 -type f -name "*.md" 2>/dev/null | head -n 1)"

if [ "$ARCHIVE_COUNT" != "1" ] || [ -z "$ARCHIVE_FILE" ]; then
    SPEC_ARCHIVE_OK=false
else
    ARCHIVE_BASENAME="$(basename "$ARCHIVE_FILE")"
    if ! printf '%s' "$ARCHIVE_BASENAME" | grep -Eq "archive-demo.*verified-accept"; then
        SPEC_ARCHIVE_OK=false
    fi
    for pattern in \
        'reason: "closeout"' \
        'outcome: "verified accept"' \
        'source_sha256:' \
        '# SPEC: Archive Demo'; do
        if ! grep -Fq "$pattern" "$ARCHIVE_FILE" 2>/dev/null; then
            SPEC_ARCHIVE_OK=false
        fi
    done
fi

CLAUDE_PROJECT_DIR="$TMP_SPEC_DIR" bash "$ROOT_DIR/scripts/spec-archive.sh" closeout "Archive Demo" "verified accept" >/dev/null 2>&1 || SPEC_ARCHIVE_OK=false
ARCHIVE_COUNT_AFTER_DEDUPE="$(find "$TMP_SPEC_DIR/.taste/specs" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')"
if [ "$ARCHIVE_COUNT_AFTER_DEDUPE" != "1" ]; then
    SPEC_ARCHIVE_OK=false
fi

cat > "$TMP_SPEC_DIR/SPEC.md" <<'EOF'
# SPEC: Next Active Contract

## Problem Statement
This spec is about to be replaced.
EOF

CLAUDE_PROJECT_DIR="$TMP_SPEC_DIR" bash "$ROOT_DIR/scripts/spec-archive.sh" prepare "New Work" "superseded-before-new-spec" >/dev/null 2>&1 || SPEC_ARCHIVE_OK=false
ARCHIVE_COUNT_AFTER_PREPARE="$(find "$TMP_SPEC_DIR/.taste/specs" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')"
if [ "$ARCHIVE_COUNT_AFTER_PREPARE" != "2" ]; then
    SPEC_ARCHIVE_OK=false
fi

if ! CLAUDE_PROJECT_DIR="$TMP_SPEC_DIR" bash "$ROOT_DIR/scripts/spec-archive.sh" status 2>/dev/null | grep -Fq ".taste/specs/"; then
    SPEC_ARCHIVE_OK=false
fi

rm -rf "$TMP_SPEC_DIR"

if [ "$SPEC_ARCHIVE_OK" = true ]; then
    test_pass "SPEC.md archives are descriptive, deduplicated, and status-readable"
else
    test_fail "SPEC archive lifecycle is not working correctly"
fi

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

# Test 14a: Memory Health Command
echo "[14a] Memory Health Command"
MEMORY_HEALTH_OUTPUT="$(bash scripts/memory.sh health 2>/dev/null || true)"
if printf '%s' "$MEMORY_HEALTH_OUTPUT" | grep -Eq "status: (healthy|degraded|disabled)" && \
   printf '%s' "$MEMORY_HEALTH_OUTPUT" | grep -Fq "Flat-file Decisions"; then
    test_pass "memory health reports concrete status and flat-file evidence"
else
    test_fail "memory health command did not report status and evidence"
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
    elif bash scripts/workflow-smoke.sh; then
        test_pass "/workflow runtime smoke test (passed on retry)"
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
