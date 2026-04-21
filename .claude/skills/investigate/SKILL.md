# /investigate

Systematic root-cause debugging with hypothesis testing. 3-fix limit prevents rabbit holes. Root cause or escalate.

**Use when:** User says "investigate this", "debug this", "what's causing this", "root cause", "why is this broken", "swarm investigate", "swarm this".

**Hypothesis first, then fix.** Never guess.

---

## Purpose

Find root cause of bugs/issues systematically. Hypothesis testing prevents guessing. 3-fix limit prevents endless debugging.

---

## Execution Protocol

### Step 1: Gather Evidence

```markdown
## Investigation: [Issue Description]

### Initial Observation
[What was seen/reported]

### Environment
- Where: [prod/staging/local]
- When: [timestamp]
- Who: [user/automated]
- Frequency: [once/always/sometimes]

### Data Collected
- Logs: [relevant log entries]
- Error messages: [exact errors]
- Reproduction steps: [how to reproduce]
- Impact: [who/what affected]
```

### Step 2: Generate Hypotheses

List 3-5 possible causes, ranked by likelihood:

```markdown
## Hypotheses

| # | Hypothesis | Likelihood | Can Test? |
|---|-----------|------------|-----------|
| 1 | [Cause A] | High/Med/Low | Yes/No |
| 2 | [Cause B] | High/Med/Low | Yes/No |
| 3 | [Cause C] | High/Med/Low | Yes/No |
```

### Step 3: Test Hypotheses

For each testable hypothesis:

```markdown
## Testing Hypothesis 1: [Cause A]

### Test Plan
[How to test this hypothesis]

### Execution
```bash
[commands to run]
```

### Result
- **SUPPORTED** — Evidence points to this
- **RULED OUT** — Evidence contradicts this
- **INCONCLUSIVE** — Need more data
```

### Step 4: Fix (Max 3 Fixes)

After identifying root cause:

```markdown
## Fix Attempt 1/3

### Root Cause
[What caused the issue]

### Fix
- File: [path]
- Change: [what to change]
- Why: [how this fixes the root cause]

### Verification
```bash
[command to verify fix]
```

Result: PASS/FAIL
```

**If Fix Fails:**
- Document what was tried
- Move to Hypothesis 2
- Try Fix 2/3

**If Fix Succeeds:**
- Document the fix
- Verify no regression
- Stop (don't over-engineer)

### Step 5: 3-Fix Limit Protocol

After 3 fixes without resolution:

```markdown
## ESCALATE

### What Was Tried
1. Fix 1: [description] — FAILED
2. Fix 2: [description] — FAILED
3. Fix 3: [description] — FAILED

### What We Know
- [facts established]
- [patterns observed]

### What We Don't Know
- [unanswered questions]

### Recommended Escalation
- Who/where to escalate to
- What information to provide
- What to ask for
```

### Step 6: Final Output

```markdown
## Investigation Results: [Issue]

### Root Cause
[Identified cause]

### Fix Applied
- File: [path]
- Change: [change made]
- Verified: [how]

### Regression Check
- [x] Issue resolved
- [x] No new issues
- [x] Related functionality works

### If Escalated
- Escalation reason: Exceeded 3-fix limit
- Escalation target: [who]
- Information provided: [summary]
```

---

## Quality Gates

- **Must gather evidence before hypothesizing** → BLOCK
- **Must test hypotheses systematically** → BLOCK
- **Maximum 3 fix attempts** → ESCALATE after 3
- **Must verify fix** before closing → BLOCK
- **Must escalate** after 3 failed fixes → BLOCK
- **Cannot skip escalation** after 3 attempts → BLOCK

---

## Anti-Patterns

- Guessing without evidence → BLOCK
- Fixing without identifying root cause → BLOCK
- More than 3 fix attempts → ESCALATE
- Assuming cause without testing → BLOCK
- Not documenting what was tried → BLOCK
- Over-engineering after first fix → WARN
