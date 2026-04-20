# /verify

**THE VERIFIER** — mandatory output validation against SPEC.md before accepting. This is a **separate check** from the AI that wrote the code.

**This is NOT the same AI that wrote the code.** It verifies independently, adversarially, against the spec.

**Use when:** After every implementation task, code changes, documentation changes, config changes, before shipping, or whenever you need to validate output.

**Never skip verification.** If you can't prove it passes, it fails.

---

## Purpose

Verify implementation output against SPEC.md. This is the critical quality gate that prevents spec drift and catches implementation errors early.

**The Problem:** Implementation verifies itself → confirmation bias → bugs ship.

**The Solution:** You are adversarial to the implementation. Find the flaws.

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

### Step 4: Verification Results

```markdown
## Verification Results: [Task Name]

### Against SPEC.md: /path/to/SPEC.md

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

---

## Evidence Requirements

| Result | Evidence Required |
|--------|-----------------|
| PASS | Test output, command output, screenshot, inspection finding |
| FAIL | Expected value, actual value, specific difference |
| CONDITIONAL | What is uncertain, what would resolve it |

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
- Implementation self-verification → BLOCK, use this skill
