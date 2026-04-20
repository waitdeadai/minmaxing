# Verify Rules

## The Verifier Agent Protocol

Every output must be verified against its SPEC.md before accepting. This is the PEV loop's critical quality gate — and the most commonly skipped step.

**The Problem:** Implementation verifies itself → confirmation bias → bugs ship.

**The Solution:** Separate verifier agent that checks output against spec.

## When to Invoke /verify

- After every implementation task
- After code changes (even "small" ones)
- After documentation changes
- After config changes
- Before shipping (mandatory)
- When in doubt (always better to verify)

## Verification Protocol

### Step 1: Locate SPEC.md
- Find the relevant SPEC.md for this task
- If no SPEC.md exists → automatic FAIL
  ```
  VERIFICATION FAILED: No SPEC.md found. Cannot verify.
  Create SPEC.md first via /autoplan.
  ```

### Step 2: Extract Success Criteria
Read the Success Criteria section from SPEC.md:
```
## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

### Step 3: Verify Each Criterion

For **each** criterion, perform verification and record evidence:

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

### Step 4: Report Results

```
## Verification Results: [Task Name]

### Against SPEC.md: /path/to/SPEC.md

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Criterion 1 | PASS | [test output, command result] |
| Criterion 2 | PASS | [inspection finding] |
| Criterion 3 | FAIL | Expected X, got Y |

### Overall Result
- **ACCEPT** — All criteria pass
- **REJECT** — One or more criteria fail
- **CONDITIONAL** — Minor issues, human decision needed
```

## Evidence Requirements

| Result | Evidence Required |
|--------|-------------------|
| PASS | Test output, command output, inspection screenshot |
| FAIL | Expected value, actual value, specific difference |
| CONDITIONAL | What is uncertain, what would resolve it |

**NOT acceptable as evidence:**
- "Looks good"
- "Seems to work"
- "I think it's correct"
- No evidence at all

## Fail Conditions

These are automatic failures:

| Condition | Why |
|-----------|-----|
| No SPEC.md | Nothing to verify against |
| Skipping criteria | Verification is incomplete |
| Missing evidence | Cannot verify claims |
| Silent acceptance | Confirmation bias |
| Output doesn't match spec | Implementation is wrong |

## Verifier Mindset

You are **adversarial** to the implementation. Your job is to find flaws.

- If you can't prove it passes → it FAILS
- Missing evidence → treat as FAIL
- Vague claims → demand specifics
- "Works fine" without test → FAIL

## Integration with PEV Loop

```
Plan → Execute → [INVOKE /verify] → Loop
              ↑
         If reject: fix and re-verify
```

## Anti-Patterns

- Verifying without SPEC.md → BLOCK
- Skipping criteria → BLOCK
- Accepting "looks good" as evidence → BLOCK
- Silent pass (no evidence shown) → BLOCK
- Approving output that doesn't match spec → BLOCK
