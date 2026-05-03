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
STATIC_CI_MODE="${HARNESS_STATIC_CI:-0}"
if [ "${CI:-}" = "true" ]; then
    STATIC_CI_MODE=1
fi

test_pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
test_fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
test_warn() { echo "  [WARN] $1"; }
test_skip() { echo "  [SKIP] $1"; }

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
    if [ "$STATIC_CI_MODE" = "1" ]; then
        test_skip "Claude Code runtime probe skipped in static CI"
    else
        test_fail "Claude Code not installed"
    fi
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
   grep -Fq "25 skills" README.md 2>/dev/null && \
   grep -Fq "Introspection Gate" CLAUDE.md 2>/dev/null && \
   grep -Fq "hard gate" AGENTS.md 2>/dev/null && \
   [ ! -f ".claude/skills/instrospect/SKILL.md" ] && \
   ! grep -Fq "/instrospect" README.md 2>/dev/null && \
   ! grep -Fq "/instrospect" CLAUDE.md 2>/dev/null; then
    test_pass "introspection is a hard gate across workflow, skills, docs, and instructions"
else
    test_fail "introspection hard-gate contract is incomplete"
fi

# Test 3g-meta: Steered Metacognition Contract
echo "[3g-meta] Steered Metacognition Contract"
METACOG_OK=true
for required_file in \
    ".claude/skills/metacognition/SKILL.md" \
    ".claude/rules/metacognition.rules.md" \
    "scripts/metacognition-scorecard.sh" \
    "evals/harness/tasks/m4-metacognition-scorecard.yaml" \
    "evals/harness/golden/m4-metacognition-scorecard.json"; do
    if [ ! -e "$required_file" ]; then
        METACOG_OK=false
    fi
done
for pattern in \
    "Task Class" \
    "Capacity Evidence" \
    "Effective Parallel Budget" \
    "MAX_PARALLEL_AGENTS" \
    "ceilings, not quotas" \
    'does not replace `/workflow`' \
    'does not replace `/introspect`' \
    "raw hidden chain-of-thought"; do
    if ! grep -Fq "$pattern" .claude/skills/metacognition/SKILL.md .claude/rules/metacognition.rules.md README.md CLAUDE.md AGENTS.md 2>/dev/null; then
        METACOG_OK=false
    fi
done
for pattern in \
    "Metacognitive Route" \
    "effective_metacognition_budget" \
    "full parallel ceiling"; do
    if ! grep -Fq "$pattern" .claude/skills/workflow/SKILL.md 2>/dev/null; then
        METACOG_OK=false
    fi
done
for pattern in \
    "Metacognitive Quality" \
    "Self-report overtrust avoided" \
    "Parallel capacity treated as ceiling"; do
    if ! grep -Fq "$pattern" .claude/skills/introspect/SKILL.md 2>/dev/null; then
        METACOG_OK=false
    fi
done
for rule in \
    "missing_task_classification" \
    "missing_parallel_budget" \
    "linear_parallel_claim" \
    "reflection_without_evidence" \
    "unsupported_confidence" \
    "raw_cot_dependency" \
    "unverified_self_report" \
    "unresolved_blocker_closeout"; do
    if ! grep -Fq "$rule" scripts/metacognition-scorecard.sh 2>/dev/null; then
        METACOG_OK=false
    fi
done
if [ "$METACOG_OK" = true ] && \
   bash scripts/metacognition-scorecard.sh --fixtures --json >/dev/null 2>&1; then
    test_pass "/metacognition is a parallel-aware, evidence-grounded steering layer"
else
    test_fail "/metacognition contract, docs, fixtures, or scorecard are incomplete"
fi

# Test 3h: Governed Autonomy Truth Surfaces
echo "[3h] Governed Autonomy Truth Surfaces"
if grep -Fq "Delegate execution. Keep judgment. Require evidence." README.md 2>/dev/null && \
   grep -Fq "governed Claude Code harness" README.md 2>/dev/null && \
   grep -Fq "Verification Metadata" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "Independent verification pass" .claude/skills/verify/SKILL.md 2>/dev/null && \
   grep -Fq "bash scripts/memory.sh health" README.md 2>/dev/null && \
   grep -Fq "bash scripts/memory.sh health" CLAUDE.md 2>/dev/null && \
   grep -Fq "Expected 25 skills" scripts/start-session.sh 2>/dev/null && \
   grep -Fq "Expected 6+ rules" scripts/start-session.sh 2>/dev/null && \
   grep -Fq "settings.team-safe.example.json" README.md 2>/dev/null && \
   ! grep -Fq "Expected 20 skills" scripts/start-session.sh 2>/dev/null && \
   ! grep -Fq "Expected 16 skills" scripts/start-session.sh 2>/dev/null && \
   ! grep -Fq "Expected $((24 - 1)) skills" scripts/start-session.sh 2>/dev/null && \
   ! grep -Fq "Expected 22 skills" scripts/start-session.sh 2>/dev/null && \
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

# Test 3j: Surgical Diff Discipline Contract
echo "[3j] Surgical Diff Discipline"
if grep -Fq "changed-line trace" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "no drive-by refactors" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "no speculative abstractions" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "smallest sufficient implementation" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   grep -Fq "changed-line trace" .claude/skills/introspect/SKILL.md 2>/dev/null && \
   grep -Fq "drive-by refactors" .claude/skills/introspect/SKILL.md 2>/dev/null && \
   grep -Fq "speculative abstractions" .claude/skills/introspect/SKILL.md 2>/dev/null && \
   grep -Fq "smallest sufficient implementation" .claude/skills/autoplan/SKILL.md 2>/dev/null && \
   grep -Fq "Changed-line trace gaps" .claude/skills/review/SKILL.md 2>/dev/null && \
   grep -Fq "Surgical Diff Discipline" README.md 2>/dev/null && \
   grep -Fq "vague requests become verifiable contracts" README.md 2>/dev/null && \
   grep -Fq "Surgical Diff Discipline" CLAUDE.md 2>/dev/null && \
   grep -Fq "surgical diff discipline" AGENTS.md 2>/dev/null; then
    test_pass "surgical diff discipline blocks speculative abstractions and drive-by refactors"
else
    test_fail "surgical diff discipline contract is incomplete"
fi

# Test 3k: Agent Factory Contract
echo "[3k] Agent Factory Contract"
AGENT_FACTORY_OK=true
while IFS= read -r pattern; do
    if [ -n "$pattern" ] && ! grep -Fq "$pattern" .claude/skills/agentfactory/SKILL.md 2>/dev/null; then
        AGENT_FACTORY_OK=false
    fi
done <<'EOF'
# /agentfactory
12 kernel questions
Hermes agent
least privilege
HERMES-{SLUG}-SPEC.md
hermes.manifest.md
hermes.system-prompt.md
hermes.memory-seed.json
hermes.runtime.json
hermes.deploy.md
hermes.verify.md
hermes.kill-switch.md
hermes-registry.md
REVCLI Readiness Overlay
Runtime Control Plane
runtime_control_plane
action_authority_matrix
operator_exception
Status Transition Matrix
Argument escape
Audit mirage
kill switch
independent verification
memory-coherent
.taste/hermes-agents/{slug}/
Agent Factory is a workflow on its own
AGENT_FACTORY_ARTIFACT
Compaction Safety
Research sufficiency gate
Required adversarial stress cases
read-only
read-write
destructive-allowed
EOF
if [ "$AGENT_FACTORY_OK" = true ] && \
   [ -f "hermes-factory.taste.md" ] && \
   [ -f "hermes-registry.md" ] && \
   [ -f "REVCLI_HERMES_AGENT_MAP.md" ] && \
   grep -Fq "Enterprise Operating Model" hermes-factory.taste.md 2>/dev/null && \
   grep -Fq "Active Agents" hermes-registry.md 2>/dev/null && \
   grep -Fq "Runtime Evidence" hermes-registry.md 2>/dev/null && \
   grep -Fq "Verification Isolation" hermes-registry.md 2>/dev/null && \
   grep -Fq "Last Kill Test" hermes-registry.md 2>/dev/null && \
   grep -Fq "Paused Agents" hermes-registry.md 2>/dev/null && \
   grep -Fq "Deprecated Agents" hermes-registry.md 2>/dev/null && \
   grep -Fq "Candidate Hermes Agents" REVCLI_HERMES_AGENT_MAP.md 2>/dev/null && \
   grep -Fq "REVCLI Runtime Blocks AgentFactory Must Respect" REVCLI_HERMES_AGENT_MAP.md 2>/dev/null && \
   grep -Fq "/agentfactory" README.md 2>/dev/null && \
   grep -Fq "/agentfactory" CLAUDE.md 2>/dev/null && \
   grep -Fq "/agentfactory" AGENTS.md 2>/dev/null && \
   grep -Fq "/agentfactory" scripts/start-session.sh 2>/dev/null && \
   bash scripts/agentfactory-smoke.sh >/dev/null 2>&1; then
    test_pass "/agentfactory is registered as a governed Hermes agent factory"
else
    test_fail "/agentfactory contract, registry, or docs registration is incomplete"
fi

# Test 3l: Open-Core Commercial Boundary
echo "[3l] Open-Core Boundary"
OPEN_CORE_OK=true
for required_file in \
    "LICENSE" \
    "NOTICE" \
    "OPEN_CORE_STRATEGY.md" \
    "COMMERCIAL.md" \
    "SECURITY.md" \
    "TRADEMARKS.md" \
    "CONTRIBUTING.md"; do
    if [ ! -f "$required_file" ]; then
        OPEN_CORE_OK=false
    fi
done
for pattern in \
    "Apache License" \
    "Grant of Patent License"; do
    if ! grep -Fq "$pattern" LICENSE 2>/dev/null; then
        OPEN_CORE_OK=false
    fi
done
for pattern in \
    "Open-Core Boundary" \
    "Apache-2.0" \
    "private commercial moat" \
    "REVCLI/Revis runtime code" \
    "COMMERCIAL.md" \
    "TRADEMARKS.md"; do
    if ! grep -Fq "$pattern" README.md 2>/dev/null; then
        OPEN_CORE_OK=false
    fi
done
for pattern in \
    "Private Commercial Moat" \
    "REVCLI private runtime" \
    "Customer-specific Hermes agents"; do
    if ! grep -Fq "$pattern" COMMERCIAL.md 2>/dev/null; then
        OPEN_CORE_OK=false
    fi
done
for pattern in \
    "Apache-2.0" \
    "Open source cannot honestly restrict commercial use" \
    "REVCLI private runtime source code" \
    "Release Checklist"; do
    if ! grep -Fq "$pattern" OPEN_CORE_STRATEGY.md 2>/dev/null; then
        OPEN_CORE_OK=false
    fi
done
for pattern in \
    "Do not include customer data" \
    "REVCLI private runtime source code" \
    "Real credentials"; do
    if ! grep -Fq "$pattern" CONTRIBUTING.md 2>/dev/null; then
        OPEN_CORE_OK=false
    fi
done
for pattern in \
    "private vulnerability reporting" \
    "No real secrets in git" \
    "REVCLI/Revis-facing agents"; do
    if ! grep -Fq "$pattern" SECURITY.md 2>/dev/null; then
        OPEN_CORE_OK=false
    fi
done
for pattern in \
    "does not grant broad trademark rights" \
    "Hermes Enterprise Certified"; do
    if ! grep -Fq "$pattern" TRADEMARKS.md 2>/dev/null; then
        OPEN_CORE_OK=false
    fi
done
for pattern in \
    "Preserve the open-core boundary" \
    "Do not publish REVCLI private runtime code"; do
    if ! grep -Fq "$pattern" AGENTS.md 2>/dev/null; then
        OPEN_CORE_OK=false
    fi
done
for pattern in \
    "Open-Core Boundary" \
    "The public repo is the Apache-2.0 core"; do
    if ! grep -Fq "$pattern" CLAUDE.md 2>/dev/null; then
        OPEN_CORE_OK=false
    fi
done
for pattern in \
    "customer-artifacts/" \
    "revcli-private/" \
    "REVCLI/" \
    "*.memory-seed.private.json"; do
    if ! grep -Fq "$pattern" .gitignore 2>/dev/null; then
        OPEN_CORE_OK=false
    fi
done
if [ "$OPEN_CORE_OK" = true ] && \
   ! grep -Fq "License-MIT" README.md 2>/dev/null && \
   ! grep -Fq "## MIT License" README.md 2>/dev/null; then
    test_pass "open-core public/private boundary is documented and guarded"
else
    test_fail "open-core boundary, license, or moat-protection docs are incomplete"
fi

# Test 3m: Parallel Mode Contract
echo "[3m] Parallel Mode Contract"
PARALLEL_MODE_OK=true
for required_file in \
    ".claude/skills/parallel/SKILL.md" \
    "scripts/parallel-capacity.sh" \
    "scripts/parallel-smoke.sh"; do
    if [ ! -f "$required_file" ]; then
        PARALLEL_MODE_OK=false
    fi
done
for pattern in \
    "# /parallel" \
    "Parallel Eligibility Audit" \
    "Hardware Capacity Profile" \
    "Execution Substrate Selector" \
    "Packet DAG" \
    "Ownership Matrix" \
    "Sync Barrier" \
    "Worker Result Schema" \
    "parallel-instances" \
    "subagents" \
    "Agent teams are opt-in experimental" \
    "MAX_PARALLEL_AGENTS" \
    "development_host_profile" \
    "target_runtime_profile" \
    "host_capacity_profile" \
    "capacity_binding" \
    "concurrency_budget" \
    "agentfactory"; do
    if ! grep -Fq "$pattern" .claude/skills/parallel/SKILL.md 2>/dev/null; then
        PARALLEL_MODE_OK=false
    fi
done
for pattern in \
    "parallel-capacity.sh --summary" \
    "/parallel"; do
    if ! grep -Fq "$pattern" README.md CLAUDE.md AGENTS.md scripts/start-session.sh 2>/dev/null; then
        PARALLEL_MODE_OK=false
    fi
done
if [ "$PARALLEL_MODE_OK" = true ] && \
   grep -Fq "Hardware-Aware Capacity" .claude/rules/parallelism.rules.md 2>/dev/null && \
   grep -Fq "Parallel substrate selection" .claude/rules/delegation.rules.md 2>/dev/null && \
   grep -Fq "development_host_profile" .claude/skills/agentfactory/SKILL.md 2>/dev/null && \
   grep -Fq "target_runtime_profile" .claude/skills/agentfactory/SKILL.md 2>/dev/null && \
   grep -Fq "host_capacity_profile" .claude/skills/agentfactory/SKILL.md 2>/dev/null && \
   grep -Fq "capacity_binding" .claude/skills/agentfactory/SKILL.md 2>/dev/null && \
   grep -Fq "concurrency_budget" .claude/skills/agentfactory/SKILL.md 2>/dev/null && \
   bash scripts/parallel-smoke.sh >/dev/null 2>&1; then
    test_pass "/parallel is registered as a hardware-aware orchestrator"
else
    test_fail "/parallel contract, capacity script, docs, or smoke test is incomplete"
fi

# Test 3n: Agent-Native Estimate Contract
echo "[3n] Agent-Native Estimate Contract"
ESTIMATE_OK=true
for required_file in \
    ".claude/rules/estimation.rules.md" \
    "scripts/estimate-history.sh" \
    "scripts/estimate-smoke.sh"; do
    if [ ! -f "$required_file" ]; then
        ESTIMATE_OK=false
    fi
done
for pattern in \
    "Agent-Native Estimate" \
    "agent_wall_clock" \
    "agent_hours" \
    "human_touch_time" \
    "calendar_blockers" \
    "critical path" \
    "confidence" \
    "scripts/parallel-capacity.sh --json"; do
    if ! grep -Fq "$pattern" .claude/rules/estimation.rules.md 2>/dev/null; then
        ESTIMATE_OK=false
    fi
done
for file in \
    "CLAUDE.md" \
    "AGENTS.md" \
    ".claude/skills/workflow/SKILL.md" \
    ".claude/skills/autoplan/SKILL.md" \
    ".claude/skills/parallel/SKILL.md" \
    ".claude/skills/introspect/SKILL.md"; do
    if ! grep -Fq "Agent-Native Estimate" "$file" 2>/dev/null; then
        ESTIMATE_OK=false
    fi
done
if [ "$ESTIMATE_OK" = true ] && \
   grep -Fq "human-equivalent-only estimate fixture was accepted" scripts/estimate-smoke.sh 2>/dev/null && \
   grep -Fq "linear scaling estimate fixture was accepted" scripts/estimate-smoke.sh 2>/dev/null && \
   grep -Fq "10 agents means 10x faster" scripts/estimate-smoke.sh 2>/dev/null && \
   bash scripts/estimate-smoke.sh >/dev/null 2>&1; then
    test_pass "Agent-Native Estimate is enforced across planning contracts"
else
    test_fail "Agent-Native Estimate contract or smoke test is incomplete"
fi

# Test 3o: Effectiveness-First Anti-Lazy Gates
echo "[3o] Effectiveness-First Anti-Lazy Gates"
EFFECTIVENESS_OK=true
for required_file in \
    ".claude/hooks/govern-effectiveness.sh" \
    "scripts/harness-scorecard.sh" \
    "scripts/hook-smoke.sh" \
    "scripts/codex-run-smoke.sh" \
    "scripts/parallel-plan-lint.sh"; do
    if [ ! -x "$required_file" ]; then
        EFFECTIVENESS_OK=false
    fi
done
for pattern in \
    "govern-effectiveness.sh" \
    '"PreToolUse"' \
    '"SubagentStop"'; do
    if ! grep -Fq "$pattern" .claude/settings.json 2>/dev/null; then
        EFFECTIVENESS_OK=false
    fi
done
for pattern in \
    "evidence-free closeout" \
    "failed-verification positive closeout" \
    "fake source ledger" \
    "tests-passed claims without command evidence" \
    "linear lane-scaling claims"; do
    if ! grep -Fq "$pattern" CLAUDE.md AGENTS.md README.md .claude/skills/workflow/SKILL.md .claude/skills/introspect/SKILL.md .claude/skills/verify/SKILL.md .claude/skills/parallel/SKILL.md 2>/dev/null; then
        EFFECTIVENESS_OK=false
    fi
done
if [ "$EFFECTIVENESS_OK" = true ] && \
   python3 -m json.tool .claude/settings.json >/dev/null 2>&1 && \
   bash scripts/harness-scorecard.sh --json >/dev/null 2>&1 && \
   bash scripts/codex-run-smoke.sh >/dev/null 2>&1 && \
   bash scripts/hook-smoke.sh >/dev/null 2>&1 && \
   bash scripts/parallel-plan-lint.sh --fixtures >/dev/null 2>&1; then
    test_pass "Claude Code runtime and harness smokes reject lazy completion patterns"
else
    test_fail "effectiveness-first gates are missing, unwired, or failing"
fi

# Test 3p: Minimal Artifact Sidecars
echo "[3p] Minimal Artifact Sidecars"
ARTIFACT_LINT_OK=true
for required_file in \
    "schemas/agent-native-estimate.schema.json" \
    "schemas/verification-result.schema.json" \
    "schemas/worker-result.schema.json" \
    "scripts/artifact-lint.sh"; do
    if [ ! -f "$required_file" ]; then
        ARTIFACT_LINT_OK=false
    fi
done
if [ ! -x "scripts/artifact-lint.sh" ]; then
    ARTIFACT_LINT_OK=false
fi
for schema in \
    schemas/agent-native-estimate.schema.json \
    schemas/verification-result.schema.json \
    schemas/worker-result.schema.json; do
    if ! python3 -m json.tool "$schema" >/dev/null 2>&1; then
        ARTIFACT_LINT_OK=false
    fi
done
for pattern in \
    "human-equivalent-only" \
    "missing-confidence" \
    "missing-critical-path" \
    "tests-passed-without-command-evidence" \
    "failed-verification-positive-closeout" \
    "unowned-worker-packet-change" \
    "unverified-worker-claim"; do
    if ! find .taste/fixtures/artifact-lint -type f -name "*$pattern*.json" 2>/dev/null | grep -q .; then
        ARTIFACT_LINT_OK=false
    fi
done
if [ "$ARTIFACT_LINT_OK" = true ] && \
   bash scripts/artifact-lint.sh --fixtures >/dev/null 2>&1; then
    test_pass "minimal artifact sidecars reject missing evidence and weak worker claims"
else
    test_fail "artifact schemas, fixtures, or lint gate are incomplete"
fi

# Test 3q: Static Harness Eval Pack
echo "[3q] Static Harness Eval Pack"
HARNESS_EVAL_OK=true
for required_file in \
    "scripts/harness-eval.sh" \
    "scripts/harness-eval-report.sh"; do
    if [ ! -x "$required_file" ]; then
        HARNESS_EVAL_OK=false
    fi
done
TASK_COUNT="$(find evals/harness/tasks -maxdepth 1 -type f -name '*.yaml' 2>/dev/null | wc -l | tr -d ' ')"
GOLDEN_COUNT="$(find evals/harness/golden -maxdepth 1 -type f -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
if [ "$TASK_COUNT" -lt 12 ] || [ "$GOLDEN_COUNT" -lt 12 ]; then
    HARNESS_EVAL_OK=false
fi
if [ "$HARNESS_EVAL_OK" = true ] && \
   find evals/harness/golden -name '*.json' -print0 2>/dev/null | xargs -0 -n1 python3 -m json.tool >/dev/null 2>&1 && \
   bash scripts/harness-eval.sh --metadata-json >/dev/null 2>&1 && \
   bash scripts/harness-eval.sh --json >/dev/null 2>&1 && \
   bash scripts/harness-eval-report.sh --run >/dev/null 2>&1; then
    test_pass "static harness eval pack scores local gates without network or secrets"
else
    test_fail "static harness eval pack metadata, goldens, scripts, or gates are failing"
fi

# Test 3r: Local Run Metrics And Session Insights
echo "[3r] Local Run Metrics And Session Insights"
RUN_INSIGHTS_OK=true
for required_file in \
    "scripts/run-metrics.sh" \
    "scripts/session-insights.sh" \
    ".taste/fixtures/session-insights/healthy/workflow.md" \
    ".taste/fixtures/session-insights/unhealthy/workflow.md"; do
    if [ ! -e "$required_file" ]; then
        RUN_INSIGHTS_OK=false
    fi
done
if [ ! -x "scripts/run-metrics.sh" ] || [ ! -x "scripts/session-insights.sh" ]; then
    RUN_INSIGHTS_OK=false
fi
if [ "$RUN_INSIGHTS_OK" = true ] && \
   bash scripts/run-metrics.sh --json >/dev/null 2>&1 && \
   bash scripts/run-metrics.sh --fixtures --json | grep -Fq '"provider_cost": "insufficient_data"' && \
   bash scripts/session-insights.sh --json >/dev/null 2>&1 && \
   bash scripts/session-insights.sh --fixtures --json | grep -Fq '"unhealthy_count": 1'; then
    test_pass "local run metrics and session insights report health without inventing provider data"
else
    test_fail "run metrics or session insights are missing, failing, or overclaiming data"
fi

# Test 3s: Security And Permission Profiles
echo "[3s] Security And Permission Profiles"
SECURITY_PROFILE_OK=true
for required_file in \
    ".claude/settings.solo-fast.example.json" \
    ".claude/settings.team-safe.example.json" \
    ".claude/rules/security.rules.md" \
    "scripts/security-smoke.sh"; do
    if [ ! -e "$required_file" ]; then
        SECURITY_PROFILE_OK=false
    fi
done
if [ ! -x "scripts/security-smoke.sh" ]; then
    SECURITY_PROFILE_OK=false
fi
if [ "$SECURITY_PROFILE_OK" = true ] && \
   python3 -m json.tool .claude/settings.solo-fast.example.json >/dev/null 2>&1 && \
   python3 -m json.tool .claude/settings.team-safe.example.json >/dev/null 2>&1 && \
   bash scripts/security-smoke.sh >/dev/null 2>&1; then
    test_pass "solo-fast and team-safe profiles are explicit, valid, and security-smoked"
else
    test_fail "security profiles, rules, or smoke tests are incomplete"
fi

# Test 3t: CI And Release Governance
echo "[3t] CI And Release Governance"
RELEASE_OK=true
for required_file in \
    ".github/workflows/harness-static.yml" \
    ".github/workflows/harness-runtime.yml" \
    "scripts/release-check.sh"; do
    if [ ! -e "$required_file" ]; then
        RELEASE_OK=false
    fi
done
if [ ! -x "scripts/release-check.sh" ]; then
    RELEASE_OK=false
fi
for pattern in \
    "pull_request" \
    "bash scripts/release-check.sh --static-only" \
    "actions/checkout@v6.0.2"; do
    if ! grep -Fq "$pattern" .github/workflows/harness-static.yml 2>/dev/null; then
        RELEASE_OK=false
    fi
done
for pattern in \
    "workflow_dispatch" \
    "CLAUDE_SETTINGS_JSON" \
    "RUN_CLAUDE_INTEGRATION" \
    "actions/checkout@v6.0.2"; do
    if ! grep -Fq "$pattern" .github/workflows/harness-runtime.yml 2>/dev/null; then
        RELEASE_OK=false
    fi
done
for pattern in \
    "HARNESS_STATIC_CI=1" \
    "STATIC_CI_MODE" \
    "runtime probe skipped in static CI"; do
    if ! grep -Fq "$pattern" scripts/release-check.sh scripts/test-harness.sh 2>/dev/null; then
        RELEASE_OK=false
    fi
done
if grep -RE '^[[:space:]]*run:[[:space:]]+[^|>].*:[[:space:]]' .github/workflows/*.yml >/dev/null 2>&1; then
    RELEASE_OK=false
fi
if [ "$RELEASE_OK" = true ] && \
   bash -n scripts/release-check.sh >/dev/null 2>&1 && \
   bash scripts/release-check.sh --static-only --skip-full-harness >/dev/null 2>&1; then
    test_pass "CI workflows and local release gate are static-safe by default"
else
    test_fail "CI workflow or release gate is missing, unsafe, or failing"
fi

# Test 3u: Parallel Aggregation Lifecycle
echo "[3u] Parallel Aggregation Lifecycle"
PARALLEL_AGGREGATE_OK=true
for required_file in \
    "scripts/parallel-aggregate.sh" \
    ".taste/fixtures/parallel-aggregate/green-run/packet-dag.json" \
    ".taste/fixtures/parallel-aggregate/bottleneck-run/packet-dag.json" \
    ".taste/fixtures/parallel-aggregate/red-cross-owned-edit/packet-dag.json" \
    ".taste/fixtures/parallel-aggregate/red-unverified-worker/packet-dag.json" \
    ".taste/fixtures/parallel-aggregate/red-linear-scaling/packet-dag.json" \
    ".taste/fixtures/parallel-aggregate/red-failed-worker/packet-dag.json"; do
    if [ ! -e "$required_file" ]; then
        PARALLEL_AGGREGATE_OK=false
    fi
done
if [ ! -x "scripts/parallel-aggregate.sh" ]; then
    PARALLEL_AGGREGATE_OK=false
fi
for pattern in \
    ".taste/parallel/{run_id}" \
    "scripts/parallel-aggregate.sh" \
    "effective lanes" \
    "bottleneck" \
    "critical path"; do
    if ! grep -Fq "$pattern" .claude/skills/parallel/SKILL.md .claude/skills/workflow/SKILL.md .claude/skills/verify/SKILL.md .claude/skills/introspect/SKILL.md 2>/dev/null; then
        PARALLEL_AGGREGATE_OK=false
    fi
done
if [ "$PARALLEL_AGGREGATE_OK" = true ] && \
   bash -n scripts/parallel-aggregate.sh >/dev/null 2>&1 && \
   bash scripts/parallel-aggregate.sh --fixtures >/dev/null 2>&1 && \
   bash scripts/parallel-aggregate.sh --json .taste/fixtures/parallel-aggregate/bottleneck-run | grep -Fq '"additional_lanes_help": false'; then
    test_pass "parallel aggregation rejects unsafe worker outputs and reports lane bottlenecks"
else
    test_fail "parallel aggregation script, fixtures, contracts, or bottleneck proof is incomplete"
fi

# Test 3v: Runtime Hardening Layer
echo "[3v] Runtime Hardening Layer"
RUNTIME_HARDENING_OK=true
for required_file in \
    "scripts/trace-ledger.sh" \
    "scripts/hook-mesh-smoke.sh" \
    "scripts/worktree-runner.sh" \
    "scripts/scenario-eval.sh" \
    "scripts/learning-loop.sh" \
    "scripts/harness-doctor.sh" \
    "scripts/runtime-hardening-smoke.sh" \
    "docs/runtime-hardening.md" \
    "evals/scenarios/estimate-smoke.json" \
    ".taste/fixtures/trace-ledger/green/valid-trace.jsonl" \
    ".taste/fixtures/hook-mesh/destructive-bash-blocked.json" \
    ".taste/fixtures/worktree-runner/green-plan.json" \
    ".taste/fixtures/learning-loop/workflow-runs/healthy-workflow.md"; do
    if [ ! -e "$required_file" ]; then
        RUNTIME_HARDENING_OK=false
    fi
done
for script in \
    trace-ledger \
    hook-mesh-smoke \
    worktree-runner \
    scenario-eval \
    learning-loop \
    harness-doctor \
    runtime-hardening-smoke; do
    if [ ! -x "scripts/$script.sh" ]; then
        RUNTIME_HARDENING_OK=false
    fi
done
for pattern in \
    '"PostToolUse"' \
    '"PostToolUseFailure"' \
    '"TaskCreated"' \
    '"TaskCompleted"' \
    'Edit|Write|MultiEdit|NotebookEdit'; do
    if ! grep -Fq "$pattern" .claude/settings.json .claude/settings.solo-fast.example.json .claude/settings.team-safe.example.json 2>/dev/null; then
        RUNTIME_HARDENING_OK=false
    fi
done
for pattern in \
    "Trace Ledger" \
    "Worktree Runner" \
    "Scenario Eval" \
    "Learning Loop" \
    "Harness Doctor" \
    "no-secret"; do
    if ! grep -Fq "$pattern" docs/runtime-hardening.md 2>/dev/null; then
        RUNTIME_HARDENING_OK=false
    fi
done
if [ "$RUNTIME_HARDENING_OK" = true ] && \
   bash scripts/runtime-hardening-smoke.sh >/dev/null 2>&1; then
    test_pass "runtime hardening layer records traces, gates hooks, runs scenarios, learns, and reports health"
else
    test_fail "runtime hardening scripts, settings, fixtures, docs, or smoke gate are incomplete"
fi

# Test 3w: Visualization Approval Contract
echo "[3w] Visualization Approval Contract"
if [ -f ".claude/skills/visualize/SKILL.md" ] && \
   [ -f ".claude/skills/visualizeworkflow/SKILL.md" ] && \
   [ -f ".claude/rules/visualization.rules.md" ] && \
   [ -x "scripts/visualize-smoke.sh" ] && \
   grep -Fq "WAITING_FOR_VISUAL_APPROVAL" .claude/skills/visualizeworkflow/SKILL.md 2>/dev/null && \
   grep -Fq "Keep plain \`/workflow\` autonomous" .claude/skills/workflow/SKILL.md 2>/dev/null && \
   bash scripts/visualize-smoke.sh >/dev/null 2>&1; then
    test_pass "/visualize and /visualizeworkflow preserve autonomous workflow while adding approval-first visualization"
else
    test_fail "/visualize, /visualizeworkflow, visualization rules, or smoke gate are incomplete"
fi

# ========================================
# Skills (25 Expected)
# ========================================

echo ""
echo "[Skills - 25 Expected]"
echo ""

# Test 4: Skills Count
echo "[4] Skills Directory"
SKILL_COUNT=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -ge 25 ]; then
    test_pass "$SKILL_COUNT skills found"
else
    test_fail "Expected 25+ skills, found $SKILL_COUNT"
fi

# Test 5: Critical Skills Content
echo "[5] Critical Skills Content"
for skill in tastebootstrap workflow visualize visualizeworkflow digestflow align audit autoplan agentfactory parallel metacognition deepresearch webresearch introspect verify review qa ship investigate; do
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
for rule in quality context delegation parallelism spec verify estimation security memory visualization metacognition; do
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
for script in start-session sprint overnight-loop council test-harness state spec-archive digestflow-smoke agentfactory-smoke parallel-capacity parallel-smoke estimate-history estimate-smoke harness-scorecard metacognition-scorecard hook-smoke hook-mesh-smoke visualize-smoke codex-run-smoke parallel-plan-lint parallel-aggregate worktree-runner artifact-lint harness-eval harness-eval-report scenario-eval trace-ledger run-metrics session-insights learning-loop memory-eval security-smoke harness-doctor runtime-hardening-smoke release-check; do
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
    if [ "$STATIC_CI_MODE" = "1" ]; then
        test_skip "ForgeGod runtime probe skipped in static CI"
    else
        test_fail "ForgeGod not installed"
    fi
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

# Test 14b: Memory Eval And Promotion Policy
echo "[14b] Memory Eval And Promotion Policy"
MEMORY_EVAL_OK=true
for required_file in \
    "scripts/memory-eval.sh" \
    "evals/memory/known-prior-decisions.json" \
    "evals/memory/red-stale-prior-decision.json" \
    "evals/memory/red-missing-critical-fact.json" \
    ".claude/rules/memory.rules.md"; do
    if [ ! -e "$required_file" ]; then
        MEMORY_EVAL_OK=false
    fi
done
if [ ! -x "scripts/memory-eval.sh" ]; then
    MEMORY_EVAL_OK=false
fi
for pattern in \
    "memory freshness" \
    "local_truth_surfaces" \
    "memory candidate" \
    "memory-events" \
    "run insights require verified evidence"; do
    if ! grep -Fq "$pattern" scripts/memory-eval.sh scripts/start-session.sh scripts/memory.sh .claude/rules/memory.rules.md .claude/skills/workflow/SKILL.md 2>/dev/null; then
        MEMORY_EVAL_OK=false
    fi
done
if [ "$MEMORY_EVAL_OK" = true ] && \
   bash -n scripts/memory-eval.sh >/dev/null 2>&1 && \
   bash scripts/memory-eval.sh --fixtures >/dev/null 2>&1 && \
   bash scripts/memory-eval.sh --summary | grep -Fq "memory freshness:"; then
    test_pass "memory eval catches stale facts and promotion requires verified evidence"
else
    test_fail "memory eval, freshness report, trace policy, or promotion guard is incomplete"
fi

# Test 14c: Documentation Distribution Surface
echo "[14c] Documentation Distribution Surface"
DOCS_DISTRIBUTION_OK=true
for required_file in \
    "docs/runtime-governance-quickstart.md" \
    "examples/dummy-harness-run/README.md" \
    "COMMERCIAL.md"; do
    if [ ! -e "$required_file" ]; then
        DOCS_DISTRIBUTION_OK=false
    fi
done
for pattern in \
    "## Runtime Governance" \
    "bash scripts/release-check.sh --static-only" \
    "RUN_CLAUDE_INTEGRATION=1 bash scripts/test-harness.sh" \
    "docs/runtime-governance-quickstart.md" \
    "examples/dummy-harness-run"; do
    if ! grep -Fq "$pattern" README.md 2>/dev/null; then
        DOCS_DISTRIBUTION_OK=false
    fi
done
for pattern in \
    "solo-fast" \
    "team-safe" \
    "ci-static" \
    "ci-runtime" \
    "must not run by default on public PRs" \
    "Codex Users" \
    "Evidence Before Trust"; do
    if ! grep -Fq "$pattern" docs/runtime-governance-quickstart.md 2>/dev/null; then
        DOCS_DISTRIBUTION_OK=false
    fi
done
for pattern in \
    "intentionally fake" \
    "dummy-only" \
    "What This Example Does Not Prove" \
    "credentials"; do
    if ! grep -Fq "$pattern" examples/dummy-harness-run/README.md 2>/dev/null; then
        DOCS_DISTRIBUTION_OK=false
    fi
done
for pattern in \
    "Distribution Boundary" \
    "Plugin And Installer Claims" \
    "The public repo must not ship" \
    "customer-specific Hermes agents"; do
    if ! grep -Fq "$pattern" COMMERCIAL.md 2>/dev/null; then
        DOCS_DISTRIBUTION_OK=false
    fi
done
if grep -Fq "The repo can operate an entire company out of the box" README.md docs/runtime-governance-quickstart.md examples/dummy-harness-run/README.md 2>/dev/null; then
    DOCS_DISTRIBUTION_OK=false
fi
if [ "$DOCS_DISTRIBUTION_OK" = true ]; then
    test_pass "runtime governance docs and dummy-only examples are distribution-safe"
else
    test_fail "runtime governance docs, dummy examples, or commercial boundary are incomplete"
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
    test_skip "Workflow smoke test skipped (set RUN_CLAUDE_INTEGRATION=1)"
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
