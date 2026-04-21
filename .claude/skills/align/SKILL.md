# /align

**MAX_PARALLEL_AGENTS** — 1 (single-threaded taste alignment check)

**Use when:** User says "align this", "does this fit our taste", "check this idea", or when /workflow triggers a taste gate.

**Swarm:** /workflow blocks if REJECTED, /workflow pauses if REVISION_NEEDED

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
