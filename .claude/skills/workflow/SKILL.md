---
description: Central execution engine - orchestrates all skills with taste awareness
---

# /workflow

**CENTRAL EXECUTION ENGINE** — The main skill for complex/power user tasks. Reads taste.md + taste.vision first. Orchestrates all other skills. Taste is the OS, skills are system calls.

**MAX_PARALLEL_AGENTS** — spawns up to 10 parallel agents for autonomous full-implementation loop.

**MEMORY INTEGRATED** — Taste Check calls `memory recall` to get relevant past decisions.

**Use when:** User says "build X", "implement Y", "fix Z", "swarm workflow", or any substantial task.

**Swarm:** "swarm" or "swarm workflow" → `/workflow` (10 parallel agents with supervisor pattern).

---

## Taste OS Architecture

/workflow is the shell. Taste/vision is the kernel. Skills are system calls.

```
┌─────────────────────────────────────────────────────────┐
│                      /workflow                          │
│                   (Central Execution Engine)             │
├─────────────────────────────────────────────────────────┤
│  PHASE 0: TASTE CHECK [GATE]                           │
│  PHASE 1: ROUTE (skill_router)                          │
│  PHASE 2: EXECUTE (skill_execute)                       │
│  PHASE 3: VERIFY (taste_verify + SPEC_verify)          │
│  PHASE 4: ROUTE OUTPUT                                 │
├─────────────────────────────────────────────────────────┤
│              taste.md + taste.vision                    │
│                  (Kernel / OS)                         │
├─────────────────────────────────────────────────────────┤
│     /autoplan  /sprint  /verify  /ship  /investigate   │
│     /audit     /council /qa     /review  /browse       │
│     /codex     /overnight  /align                       │
│              (System Calls)                             │
└─────────────────────────────────────────────────────────┘
```

### PHASE 0: TASTE CHECK [GATE]

**MANDATORY GATE — Blocks all execution until passed.**

1. Check: taste.md + taste.vision exist?
   - If NO → invoke /align --bootstrap → wait → retry
2. Read taste.md + taste.vision
3. Call memory recall with task:
   - `bash scripts/memory.sh recall "<task>" --depth medium`
   - Inject results into context
4. Score alignment: task vs taste + memory recall
   - Score 0-10
   - If <5 → invoke /align → wait for approval
   - If >=5 → proceed to PHASE 1

**Taste Alignment Scoring Rubric:**

| Score | Alignment Level | Action |
|-------|-----------------|--------|
| 0-2 | Direct conflict with taste.md principles | BLOCK — invoke /align |
| 3-4 | Significant deviation from taste | BLOCK — invoke /align |
| 5-6 | Some friction, core alignment exists | Proceed, document deviations |
| 7-8 | Well-aligned, minor tradeoffs | Proceed |
| 9-10 | Perfect alignment with taste/vision | Proceed |

**Taste Check Questions:**
- Does this match the design principles in taste.md?
- Does this serve the intent in taste.vision?
- Would this pass the "Taste Test" — does it feel right?
- Are there价值观 conflicts with established patterns?

### PHASE 1: ROUTE

**skill_router(task) analyzes task pattern and selects skills.**

| Task Pattern | Skills to Invoke |
|--------------|-----------------|
| "build X" / "implement Y" | /autoplan → /sprint → /verify → /ship |
| "fix Z" / "debug this" | /investigate → /verify |
| "analyze decision" | /council → /align if needed |
| "audit this" | /audit |
| "test this" / "QA" | /qa |
| "review code" | /review |
| "plan this" | /autoplan |
| "search code" | /codex |
| "research X" | /browse |
| "run overnight" | /overnight |
| "align values" / "价值观" | /align |
| "office hours" / "clarify" | /align |
| "explain X" / "what is X" | /council |
| "refactor X" | /autoplan → /sprint → /verify → /ship |
| "optimize X" | /autoplan → /sprint → /verify → /ship |
| "document X" | /review |
| "migrate X" | /autoplan → /sprint → /verify → /ship |
| "generate tests" | /qa |
| "check security" / "security audit" | /audit |

### PHASE 2: EXECUTE — ACTIVE ORCHESTRATION

**/workflow is the orchestrator. It does NOT just describe the chain — it executes it.**

**CRITICAL:** After each skill completes, /workflow MUST invoke the next skill in the chain. Skills are dead ends without the orchestrator.

#### Chain Execution Pattern

For each skill in the chain, /workflow MUST:

1. **INVOKE** the skill with `Skill("[skill-name]")`
2. **PASS** current context + taste constraints
3. **WAIT** for skill completion
4. **COLLECT** output
5. **PASS** output as input to NEXT skill in chain
6. **REPEAT** until chain terminates at /ship or /review

#### Example: "build a REST API"

```
/workflow "build a REST API"
    │
    ├─ PHASE 0: TASTE CHECK → PASS
    ├─ PHASE 1: ROUTE → /autoplan → /sprint → /verify → /ship
    │
    ├─ PHASE 2: EXECUTE CHAIN
    │   │
    │   ├─ SKILL 1: /autoplan
    │   │       invoke /autoplan "build REST API"
    │   │       wait for SPEC.md creation
    │   │       collect SPEC.md path + context
    │   │       PASS to next skill ↓
    │   │
    │   ├─ SKILL 2: /sprint
    │   │       invoke /sprint with SPEC.md context
    │   │       spawn parallel agents
    │   │       wait for completion
    │   │       collect modified files + test results
    │   │       PASS to next skill ↓
    │   │
    │   ├─ SKILL 3: /verify
    │   │       invoke /verify against SPEC.md
    │   │       wait for ACCEPT/REJECT
    │   │       if REJECT → loop back to /sprint with fixes
    │   │       if ACCEPT → PASS to next skill ↓
    │   │
    │   └─ SKILL 4: /ship
    │           invoke /ship
    │           wait for ship confirmation
    │           chain complete
    │
    └─ PHASE 3: VERIFY (embedded in /verify)
    └─ PHASE 4: OUTPUT (ship complete)
```

#### Single-Skill Chains (no chain)

Some tasks are single-skill:
- `/audit` → terminates with findings
- `/council` → terminates with decision
- `/qa` → terminates with PASS/FAIL

For these, /workflow still invokes the skill and returns the output to user.

#### Anti-Pattern: Chain Breaking

```
BLOCK: Invoking /autoplan and stopping
BLOCK: Invoking /sprint and stopping
BLOCK: Invoking /verify and stopping
BLOCK: Assuming skills auto-chain without /workflow orchestration
```

**Every chain MUST terminate at /ship or /review unless the task is single-skill.**

### PHASE 3: VERIFY

**Dual verification: Taste alignment + SPEC compliance.**

```
taste_verify(output):
  - Does output match taste.md principles?
  - Does output serve taste.vision intent?
  - Would output pass the Taste Test?

SPEC_verify(output):
  - Does output meet all SPEC.md success criteria?
  - Are all verification methods complete?
  - Is rollback plan still valid?
```

**Verification Loop:**
- If taste_verify FAILS → loop back to fix taste violations
- If SPEC_verify FAILS → loop back to fix spec violations
- If both PASS → proceed to PHASE 4
- 3 failed loops → escalate, require human decision

### PHASE 4: ROUTE OUTPUT

| Condition | Route To |
|-----------|----------|
| Production-ready, all gates passed | /ship |
| Needs human review / sign-off | /review |
| Partial completion, continue later | /overnight or save state |
|价值观 alignment question | /align |
| Done, no further action | Return to user |

---

## Taste Check Protocol

### Step 1: Load Taste Files
```
Read: /home/fer/Music/ultimateminimax/taste.md
Read: /home/fer/Music/ultimateminimax/taste.vision
```

### Step 2: Recall Memory
```
bash scripts/memory.sh recall "<task>" --depth medium
```
Inject memory recall results into context for informed alignment scoring.

### Step 3: Score Alignment
Score task against each taste dimension:
- **Design principles** (from taste.md): 0-10
- **Intent alignment** (from taste.vision): 0-10
- **价值观 consistency**: 0-10
- **Memory alignment** (from recall): 0-10

**Composite Score = weighted average (design 35%, intent 35%,价值观 15%, memory 15%)**

### Step 4: Gate Decision
| Composite Score | Decision |
|-----------------|----------|
| 0-4 | BLOCK → invoke /align |
| 5-6 | CAUTION → note deviations, proceed |
| 7-10 | PROCEED |

### Step 5: Document Taste Status
```
## Taste Check Results

### Alignment Scores
- Design Principles: [score]/10
- Intent Alignment: [score]/10
- 价值观 Consistency: [score]/10
- Memory Alignment: [score]/10
- **Composite: [score]/10**

### Gate Status: [PROCEED/CAUTION/BLOCK]
### Deviations (if any): [list]
### Memory Recall Insights: [relevant past decisions]
```

---

## Skill Router Protocol

### Step 1: Parse Task Intent
Extract the core verb and object:
- "build X" → implementation intent
- "fix Z" → debugging intent
- "analyze Y" → analysis intent

### Step 2: Match Pattern
Match against routing table:
```
implementation_patterns = ["build", "implement", "create", "add", "make"]
debugging_patterns = ["fix", "debug", "repair", "resolve"]
analysis_patterns = ["analyze", "review", "audit", "examine"]
research_patterns = ["research", "browse", "search", "find"]
```

### Step 3: Select Skill Chain
Based on pattern match, select skill chain:
- Implementation → `/autoplan` → `/sprint` → `/verify` → `/ship`
- Debugging → `/investigate` → `/verify`
- Analysis → `/council` → `/align` if needed
- Research → `/browse`
- etc.

### Step 4: Validate Chain
Ensure skill chain:
- Has no circular dependencies
- Respects taste constraints
- Has clear termination (all lead to /ship or /review)

---

## Execution Protocol

### Full Step-by-Step for /workflow

```
STEP 0: TASTE CHECK [GATE]
├── Read taste.md
├── Read taste.vision
├── Call memory recall with task
├── Score task alignment
├── If score < 5 → invoke /align, wait for approval
└── If score >= 5 → proceed

STEP 1: ROUTE
├── Parse task intent
├── Match pattern against routing table
├── Select skill chain
└── Validate chain

STEP 2: EXECUTE
├── For each skill in chain (in order):
│   ├── Invoke skill with task context
│   ├── Pass taste constraints to skill
│   ├── Collect output
│   └── Pass output to next skill
└── If /sprint invoked: spawn up to MAX_PARALLEL_AGENTS workers

STEP 3: VERIFY
├── taste_verify(output) → does it match taste?
├── SPEC_verify(output) → does it meet SPEC criteria?
├── If either fails → loop back to STEP 2 with fixes
└── If 3 failures → escalate to human

STEP 4: ROUTE OUTPUT
├── If production-ready → /ship
├── If needs review → /review
├── If价值观 question → /align
└── Otherwise → return to user
```

### Research-First Mandate
Before executing any skill chain:
- Verify AI claims with web search (training data is stale)
- Research APIs, libraries, error codes for external dependencies
- Document findings in execution context

---

## Agent Pool Configuration

**Default: 10 agents** (for 32GB+ RAM, 8+ cores)

To configure for your hardware, add to `~/.claude/settings.json`:

```json
{
  "env": {
    "MAX_PARALLEL_AGENTS": "6"
  }
}
```

| Hardware | MAX_PARALLEL_AGENTS |
|----------|---------------------|
| 32GB+ RAM, 8+ cores | 10 |
| 16GB RAM, 4+ cores | 6 |
| 8GB RAM, 2+ cores | 3 |
| Low-end | 2 |

---

## Anti-Patterns (BLOCK)

### Taste Violations
- Proceeding with score < 5 without /align approval → BLOCK
- Ignoring taste.md principles in execution → BLOCK
- Violating taste.vision intent → BLOCK
-价值观 mismatch without acknowledgment → BLOCK

### Execution Violations
- Workers modifying shared files → BLOCK (conflicts)
- Skipping research on external deps → BLOCK
- Marking done without tests passing → BLOCK
- Workers communicating directly → BLOCK (supervisor only)
- Ignoring file conflicts → BLOCK
- Skipping taste check → BLOCK

### Verification Violations
- Skipping SPEC_verify → BLOCK
- Accepting "looks good" as evidence → BLOCK
- No taste verification documented → BLOCK
- Silent acceptance of output → BLOCK
