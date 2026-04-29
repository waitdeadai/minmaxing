# /verify

**THE VERIFIER** — mandatory output validation against SPEC.md before accepting. This is an **Independent verification pass** with evidence for each criterion.

**Isolation rule:** Do not claim a different model, agent, process, or workspace performed verification unless the workflow artifact records metadata that proves it. When isolation metadata is unavailable, describe this as an independent verification pass against the spec, not as guaranteed separate execution.

**MAX_PARALLEL_AGENTS** — ceiling for verification lanes. Split verification only when criteria or surfaces are independent enough to check separately.

**Use when:** After every implementation task, code changes, documentation changes, config changes, before shipping, "swarm verify", or whenever you need to validate output.

**Swarm:** "swarm verify" → `/verify` with an efficacy-first verification wave up to `MAX_PARALLEL_AGENTS`.

**Never skip verification.** If you can't prove it passes, it fails.

---

## Purpose

Verify implementation output against SPEC.md. This is the critical quality gate that prevents spec drift and catches implementation errors early.

**The Problem:** Implementation verifies itself too casually → confirmation bias → bugs ship.

**The Solution:** Run a deliberately adversarial pass against `SPEC.md`. Find the flaws before the user does.

---

## Execution Protocol

### Step 1: Locate SPEC.md

- Find the relevant SPEC.md for this task
- If no SPEC.md exists → FAIL immediately:
  ```
  VERIFICATION FAILED: No SPEC.md found. Cannot verify.
  Create SPEC.md first via /autoplan.
  ```

### Step 2: Read Success Criteria

Extract all criteria from SPEC.md:

```markdown
## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

### Step 3: Verify Each Criterion

For each criterion, perform verification:

**For code changes:**
- Read the changed files
- Run relevant tests
- Execute the code if applicable
- Inspect output against criterion

**For documentation:**
- Read the doc
- Verify structure matches spec
- Check all required sections exist

**For config changes:**
- Read the config file
- Verify values match spec
- Test that config takes effect

**For `/parallel` runs:**
- Read the parallel artifact when present
- Verify every worker packet returned the Worker Result Schema
- Check changed files against the ownership matrix
- Confirm sync barriers were honored before dependent work
- Confirm the effective budget did not exceed the hardware capacity profile, `MAX_PARALLEL_AGENTS`, or Codex `max_threads`
- Treat worker summaries as claims until aggregate evidence proves them

### Step 4: Verification Results

```markdown
## Verification Results: [Task Name]

### Against SPEC.md: /path/to/SPEC.md

### Verification Metadata
- Executor identity/model/workspace: [known value or unknown]
- Verifier identity/model/workspace: [known value or unknown]
- Isolation status: [proved separate / same session independent pass / unknown]

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Criterion 1 | PASS | [test output, command result] |
| Criterion 2 | PASS | [inspection finding] |
| Criterion 3 | FAIL | Expected X, got Y |

### Verification Details

**[Criterion 1]**: PASS
- Expected: [what spec says]
- Actual: [what implementation does]
- Evidence: [test output, command, inspection]

**[Criterion 2]**: PASS
- Expected: [what spec says]
- Actual: [what implementation does]
- Evidence: [test output, command, inspection]

**[Criterion 3]**: FAIL
- Expected: [what spec says]
- Actual: [what implementation does]
- Evidence: [exact failure]

### Overall Result
- **ACCEPT** — All criteria pass
- **REJECT** — One or more criteria fail
- **CONDITIONAL** — Minor issues, human decision needed
```

### Step 5: If REJECT

List specific failures and recommend fixes:

```markdown
### Failures Detected

1. **[Criterion] failed**: Expected X, got Y
   - Fix: [specific change needed]

2. **[Criterion] failed**: [reason]
   - Fix: [specific change needed]

### Recommended Fixes
1. [specific fix for failure 1]
2. [specific fix for failure 2]
```

### Step 5.5: Log Failures to Memory

On REJECT, log each failed criterion to error-solution tier:

```bash
# Log each failure as error-solution pair
bash scripts/memory.sh add error-solution "\"Failed criterion: [criterion]\"" "\"Fix: [recommended fix]\""

# Record failure in causal graph
python3 -c "
from memory.causal import record_outcome
factors = ['spec_drift', 'verify_failed', '[specific_failed_criterion]']
record_outcome(factors, 'failure')
" 2>/dev/null || echo "record_outcome: skipped"
```

---

## Evidence Requirements

| Result | Evidence Required |
|--------|-----------------|
| PASS | Test output, command output, screenshot, inspection finding |
| FAIL | Expected value, actual value, specific difference |
| CONDITIONAL | What is uncertain, what would resolve it |

For `/parallel`, PASS also requires packet evidence, ownership-matrix checks,
capacity checks, sync-barrier checks, and aggregate verification against
`SPEC.md`.

**NOT acceptable as evidence:**
- "Looks good"
- "Seems to work"
- "I think it's correct"
- No evidence at all

---

## Quality Gates

- Must read SPEC.md before verifying
- Must verify ALL criteria, not just "most"
- Must provide EVIDENCE for each pass/fail
- Silent pass is not allowed — show evidence
- Silent fail is not allowed — show exactly what failed
- No SPEC.md = automatic FAIL

---

## Anti-Patterns

- Verifying without SPEC.md → FAIL
- Skipping criteria → FAIL
- "Looks good" without evidence → FAIL
- Accepting output that doesn't match spec → FAIL
- Saying "mostly done" without specifics → FAIL
- Silent acceptance → FAIL

---

## Verifier Mindset

You are **adversarial** to the implementation. Your job is to find flaws.

- If you can't prove it passes → it FAILS
- Missing evidence → treat as FAIL
- Vague claims → demand specifics
- "Works fine" without test → FAIL
- Implementation self-verification without a separate evidence pass → BLOCK, use this skill

---

## Chain Contract

**This skill is a verification playbook.** `/workflow` may reuse this guidance, but it should not depend on invoking `/verify` as a guaranteed nested continuation step.

When invoked directly by the user, return ACCEPT or REJECT with evidence.

When `/workflow` references this skill, the parent workflow decides whether to fix, re-verify, close out locally, or ship.
