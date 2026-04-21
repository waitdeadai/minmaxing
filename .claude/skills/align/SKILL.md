# /align

**MAX_PARALLEL_AGENTS** — 1 (single-threaded taste alignment check)

**Use when:** User says "align this", "does this fit our taste", "check this idea", or when /workflow triggers a taste gate. Or "/align --bootstrap" to define taste for new projects.

**Swarm:** "swarm align" → /align (blocks /workflow on REJECTED, pauses on REVISION_NEEDED)

---

## Purpose

Validate that a proposed task, idea, or change aligns with this project's taste.md and taste.vision before entering the /workflow execution loop. This is a taste gate — not a startup vetting.

**Hard gate:** If REJECTED, /workflow is blocked until the proposal is fundamentally redesigned. If REVISION_NEEDED, /workflow pauses until revisions address the taste gaps.

---

## TASTE-FIRST Protocol

Before asking any questions, ALWAYS read:
1. `taste.vision` — the intent document (why we exist)
2. `taste.md` — the design spec (what's acceptable)

These are loaded first. All questions are derived from these documents, not from generic startup wisdom.

---

## Execution Protocol

### Step 1: Load Taste Documents

Read `taste.vision` and `taste.md` in full. Extract:
- Design principles from taste.md
- Intent from taste.vision
- Non-goals (what we explicitly do NOT do)
- Architectural constraints

### Step 2: Present the Proposal

Ask the user to describe what they want to align. Wait for their description.

### Step 3: Ask Taste-Aligned Questions

Present questions one at a time. Wait for answer before proceeding.

---

## The 5 Taste Questions

---

#### Question 1: Design Principles Alignment

**"Does this align with our design principles from taste.md?"**

Principles to reference:
- SPEC-first: write spec before code
- 10-agent parallelism for max throughput
- Separate verifier from implementer (PEV loop)
- Research-first: verify AI claims with web search

**Scoring:**
- YES (all principles honored)
- PARTIAL (some principles honored, some ignored)
- NO (violates core principles)

---

#### Question 2: Intent Fit

**"Does this serve our stated intent from taste.vision?"**

Intent: "minmaxing is a Claude Code harness that gets better outcomes by forcing explicit specification before implementation. Where other harnesses optimize for speed, we optimize for correctness."

**Scoring:**
- YES (serves correctness over speed)
- NO (prioritizes speed over correctness)

---

#### Question 3: Architectural Constraints

**"Does this violate any of our architectural constraints?"**

Constraints:
- Supervisor/worker pattern for parallelism
- File isolation between parallel agents
- Quality gates before progression
- Small functions, single responsibility
- Explicit over implicit

**Scoring:**
- YES (violates constraints)
- NO (honors constraints)

---

#### Question 4: Scope vs Non-Goals

**"Is this the right scope given our non-goals?"**

Non-goals:
- Not a code generator — it's a thinking system
- Not for一次性 scripts — for projects that need to be right

**Scoring:**
- YES (fits scope)
- NO (crosses into code-generator territory or throwaway scripts)

---

#### Question 5: Trade-off Clarity

**"What would we have to sacrifice to do this?"**

This question forces explicit acknowledgment of trade-offs. Speed vs correctness. Scope vs quality.

**Scoring:**
- ACCEPTABLE (trade-offs are explicit and within taste bounds)
- UNACCEPTABLE (trade-offs violate taste)

---

## Bootstrap Mode: /align --bootstrap

For new projects where taste.md + taste.vision don't exist.

### Phase 1: Define taste.md (5 questions)
1. Design Principles — "What are the non-negotiable design principles?"
2. Aesthetic Rules — "What aesthetic guidelines should we follow?"
3. Code Style — "What code patterns are acceptable/unacceptable?"
4. Architecture — "What architectural patterns do we prefer?"
5. Naming — "What naming conventions do we use?"

### Phase 2: Define taste.vision (5 questions)
1. Intent — "Why does this project exist?"
2. Success — "What does success look like?"
3. Non-Goals — "What is explicitly out of scope?"
4. Feel — "How should decisions feel? Fast? Careful? Both?"
5. Values — "What do we optimize for above all else?"

### Output
- Writes taste.md and taste.vision to project root
- Output: TASTE_DEFINED

---

## Review Mode: /align --review

Periodic taste review triggered every 30 sessions (or on demand).

### Phase 1: Surface Evidence

Query memory for:
1. **Top causal factors** — success and failure patterns from causal graph
2. **Recent error-solution pairs** — recurring bugs and fixes
3. **Taste alignment scores** — last 10 /workflow runs and their alignment scores

```bash
# Query causal graph for top factors
python3 -c "
from memory.causal import get_failure_factors, get_success_factors
failure_factors = get_failure_factors(limit=5)
success_factors = get_success_factors(limit=5)
print('FAILURE FACTORS:', failure_factors)
print('SUCCESS FACTORS:', success_factors)
" 2>/dev/null

# Query recent error patterns
bash scripts/memory.sh search "error" --tier error-solutions --limit 20 2>/dev/null | head -20

# Query recent semantic memories for alignment patterns
bash scripts/memory.sh search "taste" --tier semantic --limit 10 2>/dev/null | head -10
```

### Phase 2: Present Review

```markdown
## Taste Review — Session #[N]

### Causal Graph: Top Success Factors
- [Factor 1]: [weight] success correlation
- [Factor 2]: [weight] success correlation

### Causal Graph: Top Failure Factors
- [Factor 1]: [weight] failure correlation ⚠️ if >70%
- [Factor 2]: [weight] failure correlation

### Recent Error-Solution Patterns
- [Error pattern 1]: [times seen]
- [Error pattern 2]: [times seen]

### Recent Taste Alignments
- Session [N-9]: [score] — [task brief]
- Session [N-8]: [score] — [task brief]
- ...

### Taste Health Check
Does your taste.md still reflect your intent?
Does taste.vision still describe why this project exists?

**[ ] YES — taste is healthy
**[ ] REVIEW NEEDED — some aspects need updating
**[ ] EVOLVE NEEDED — significant changes proposed via --evolve
```

### Phase 3: Human Decision

- If healthy → continue
- If review needed → human edits taste.md/taste.vision directly
- If evolve needed → run `/align --evolve`

---

## Evolve Mode: /align --evolve

Memory-informed taste change proposals. Proposes changes when evidence strongly supports it.

### Trigger Conditions (agent proposes when ANY met):
- ≥5 semantic memories cite the same principle or pattern
- ≥3 error-solution pairs cite the same failure mode
- Causal graph shows a factor with >70% failure correlation not in taste

### Phase 1: Analyze Memory Evidence

```bash
# Check semantic memory frequency
python3 -c "
from memory.sqlite_db import MemoryDB
db = MemoryDB()
# Query for repeated principles
results = db.search(query='taste principle pattern', tier=2, limit=50)
# Count occurrences of each principle
from collections import Counter
principles = [r['text'] for r in results]
counter = Counter(principles)
for principle, count in counter.most_common(5):
    if count >= 5:
        print(f'PROPOSE: {principle} (seen {count} times)')
db.close()
" 2>/dev/null

# Check causal graph for high-failure factors
python3 -c "
from memory.causal import get_failure_factors
factors = get_failure_factors(limit=10)
for f in factors:
    if f['weight'] < 0.3:  # >70% failure correlation
        print(f'HIGH_FAILURE: {f[\"factor\"]} — {int((1-f[\"weight\"])*100)}% failure correlation')
        print(f'  Suggest adding to taste as constraint')
" 2>/dev/null
```

### Phase 2: Generate Proposal

If threshold met, generate structured proposal:

```markdown
## Taste Evolution Proposal

### Evidence (from memory)
- [N] semantic memories cite: [pattern]
- [N] error-solution pairs cite: [failure mode]
- Causal factor: [X] has [Y]% failure correlation

### Proposed Change to taste.md
```diff
+ ## New/Updated Principle
+ [Exact principle text to add]
```

### Proposed Change to taste.vision (if applicable)
```diff
+ ## New/Updated Intent
+ [Exact vision text to add]
```

### Rationale
[How this change serves your taste.vision intent]

### Decision
[ ] APPROVE — make the change
[ ] REJECT — keep current taste
[ ] REVISE — modify the proposal
```

### Phase 3: Human Approval

Human reviews evidence and proposal, then decides:
- **APPROVE** → agent edits taste.md and/or taste.vision
- **REJECT** → no changes, log rejection to memory
- **REVISE** → human provides feedback, agent refines proposal

### Phase 4: Apply Change

If APPROVED:
```bash
# Edit taste.md
edit taste.md with approved changes

# Edit taste.vision if applicable
edit taste.vision with approved changes

# Log decision to memory
bash scripts/memory.sh add semantic "Taste evolved: [summary of change]. Rationale: [why approved]. Human approved." --tags "taste-evolution,council-decision"
```

---

## Output Format

After all 5 questions are answered:

```markdown
## Taste Alignment Check

### Proposal: [brief description]

### Question Results

| Question | Score |
|----------|-------|
| 1. Design Principles Alignment | YES / PARTIAL / NO |
| 2. Intent Fit | YES / NO |
| 3. Architectural Constraints | YES / NO |
| 4. Scope vs Non-Goals | YES / NO |
| 5. Trade-off Clarity | ACCEPTABLE / UNACCEPTABLE |

### Taste Verdict

**[ALIGNED]** — All questions pass. Proceed to /workflow.

**[REVISION_NEEDED]** — Some questions fail. Revisions required before /workflow can proceed.
- Failed questions: [list which ones]
- Required changes: [specific revisions needed]

**[REJECTED]** — Core taste/vision violated. /workflow is BLOCKED.
- Failed questions: [list which ones]
- Root cause: [why this fundamentally doesn't fit]

### Next Step
If ALIGNED: invoke /workflow
If REVISION_NEEDED: revise and re-run /align
If REJECTED: abandon or fundamentally redesign this proposal
```

**Note:** Use `/align --bootstrap` for new projects without taste.md/taste.vision to define taste from scratch.

---

## Quality Gates

- All 5 questions must be answered (no skipping)
- Answers must reference specific taste.md or taste.vision content
- Verdict must match the evidence
- REJECTED requires explicit explanation of taste violation
- This skill produces ALIGNMENT DOCS only — no code, no SPEC.md

---

## Anti-Patterns

- Answering questions yourself instead of the user → FAIL
- Skipping taste.md/taste.vision read → FAIL
- Accepting vague alignment claims ("feels right") → FAIL, demand specificity
- Claiming alignment without referencing taste documents → FAIL
- Producing code/implementation instead of alignment check → BLOCK
- Bypassing taste gate to proceed to /workflow → BLOCK
