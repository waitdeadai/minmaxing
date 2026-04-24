# /council

Multi-perspective synthesis for complex decisions. Different viewpoints debate, synthesize into recommendation.

**MAX_PARALLEL_AGENTS** — ceiling for perspective lanes. Add perspectives only when they are genuinely distinct and decision-relevant.

**Use when:** User says "council this", "multiple perspectives", "architectural decision", "what do you think", "weigh the options", "swarm council".

**Swarm:** "swarm council" → `/council` with an efficacy-first perspective wave up to `MAX_PARALLEL_AGENTS`.

**For complex decisions only.** Not for simple questions.

---

## Purpose

Synthesize multiple viewpoints into informed recommendations. Different perspectives catch blind spots.

---

## Execution Protocol

### Step 0: Memory Recall (Before Decision)

Recall similar past decisions to inform current debate:

```bash
# Recall similar past decisions
bash scripts/memory.sh recall "[decision topic]" --depth medium 2>/dev/null || echo "Memory recall: skipped"

# Search for related decisions
bash scripts/memory.sh search "[decision keywords]" 2>/dev/null || true
```

### Step 1: Define the Decision

```markdown
## Council: [Decision to Make]

### Question
[What needs to be decided]

### Options
1. **Option A**: [description]
2. **Option B**: [description]
3. **Option C**: [description]

### Criteria for Evaluation
- [Criterion 1] — Weight: [high/med/low]
- [Criterion 2] — Weight: [high/med/low]
- [Criterion 3] — Weight: [high/med/low]
```

### Step 2: Perspectives

Present each perspective:

```markdown
## Perspective 1: [Engineer]

**Advocate for**: Option [A/B/C]

### Arguments
1. [Argument 1]
2. [Argument 2]

### Concerns
1. [Concern 1]
2. [Concern 2]

### Verdict
[Recommendation]

---

## Perspective 2: [Security]

**Advocate for**: Option [A/B/C]

### Arguments
1. [Argument 1]
2. [Argument 2]

### Concerns
1. [Concern 1]
2. [Concern 2]

### Verdict
[Recommendation]

---

## Perspective 3: [Product/User]

**Advocate for**: Option [A/B/C]

### Arguments
1. [Argument 1]
2. [Argument 2]

### Concerns
1. [Concern 1]
2. [Concern 2]

### Verdict
[Recommendation]
```

### Step 3: Synthesis

```markdown
## Synthesis

### Cross-Perspective Agreement
- All agree on: [points of agreement]
- All disagree on: [points of disagreement]

### Trade-off Analysis
| Option | Pros | Cons | Risk |
|--------|------|------|------|
| A | ... | ... | ... |
| B | ... | ... | ... |
| C | ... | ... | ... |

### Weighted Scoring
| Criteria | Weight | A | B | C |
|----------|--------|---|---|---|
| Crit 1 | X | Score | Score | Score |
| Crit 2 | Y | Score | Score | Score |
| **Total** | | | | |

### Recommendation
**Option [X]**

Reasoning:
1. [Key reason 1]
2. [Key reason 2]
3. [Key reason 3]

### Conditions
If following Option X:
- Do [this] to mitigate [risk]
- Monitor [this] for [warning sign]

If not following Option X:
- Consider [alternative] if [condition changes]
```

### Step 4: Final Council Vote

```markdown
## Council Vote

| Perspective | Vote |
|-------------|------|
| Engineer | Option [X] |
| Security | Option [X] |
| Product | Option [Y] |

### Decision
- **DECIDED**: Option [X]
- **UNANIMOUS** / **MAJORITY** / **SPLIT**

### Rationale
[2-3 sentence explanation of final decision]
```

### Step 5: Store Decision to Memory

After decision is made, store for future recall:

```bash
# Store decision as semantic memory
bash scripts/memory.sh add semantic "Council decision: [question] → Option [X] decided ([unanimous/majority/split]). Rationale: [brief rationale]" --tags "council,decision,[topic]"

# Record causal factors
python3 -c "
from memory.causal import record_outcome
factors = ['multi_perspective_analysis', 'tradeoff_explicit', 'criteria_based_scoring']
record_outcome(factors, 'success')
" 2>/dev/null || echo "record_outcome: skipped"
```

---

## Quality Gates

- **Must present at least 3 distinct perspectives** → FAIL if fewer
- **Perspectives must be genuinely different viewpoints** → FAIL if same
- **Trade-offs must be explicit** → FAIL if glossed over
- **Scoring must be based on stated criteria** → FAIL if arbitrary
- **Recommendation must follow from the analysis** → FAIL if not

---

## Anti-Patterns

- Same perspective with different words → BLOCK
- Ignoring minority view → WARN
- Vague trade-offs → BLOCK
- Recommendation not backed by analysis → BLOCK
- Forcing consensus when none exists → WARN
