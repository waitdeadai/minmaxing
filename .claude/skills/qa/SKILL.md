# /qa

Browser-based QA with atomic bug fixes and regression tests. Pass/Fail only — no "mostly works", no "looks okay".

**Use when:** User says "QA this", "test this feature", "browser test", "verify this works", "regression test".

**Pass/Fail only.** "Mostly", "seems", "probably" are not acceptable.

---

## Purpose

Verify that features work correctly in a browser environment. Atomic bug fixes ensure no regression.

---

## Execution Protocol

### Step 1: Define Test Plan

For the feature being tested:

```markdown
## QA Test Plan: [Feature Name]

### Test Cases
1. **TC-1: [Name]**
   - Steps: [numbered steps]
   - Expected: [result]
   - Pass/Fail: ___

2. **TC-2: [Name]**
   - Steps: [numbered steps]
   - Expected: [result]
   - Pass/Fail: ___

### Browser Environment
- Browser: [Chrome/Firefox/Safari]
- Headless: [yes/no]
- Viewport: [size]

### Special Setup
- Login required: [yes/no]
- Test data needed: [description]
```

### Step 2: Execute Tests

For each test case:

1. Launch browser (or use existing session)
2. Execute steps precisely
3. Compare actual vs expected
4. Record PASS or FAIL with evidence

### Step 3: Bug Fix Protocol (If QA Finds Issues)

For each failing test:

```markdown
## Bug: [ID] — [Title]

### Reproduction
Steps to reproduce:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Expected: [what should happen]
Actual: [what happened]

### Root Cause
[Analysis of why it fails]

### Fix
[Specific change to make]
File: [path]
Line: [number]
Change: [exact change]

### Verification
After fix, re-run TC-[N] and confirm PASS
```

### Step 4: Regression Testing

After any fix:

1. Re-run failing test — must PASS
2. Run related tests — must PASS
3. Run full suite — must PASS
4. Document what was re-tested

### Step 5: Final Output

```markdown
## QA Results: [Feature Name]
**Date**: [timestamp]
**Browser**: [browser/version]
**Tester**: Claude Code

### Summary
- Total Tests: [N]
- Passed: [N]
- Failed: [N]
- Pass Rate: [X%]

### Test Results

| TC-ID | Test Case | Result | Evidence |
|-------|-----------|--------|----------|
| TC-1 | [Name] | PASS | [screenshot/error/output] |
| TC-2 | [Name] | FAIL | [screenshot/error/output] |

### Bugs Found
- Bug-1: [Title] — [file:line] — FIXED
- Bug-2: [Title] — [file:line] — FIXED

### Regression Status
- All fixes verified: [YES/NO]
- Full suite: [PASS/FAIL]

### Final Verdict
- **[PASS]** — All tests pass, ready to ship
- **[FAIL]** — [N] tests failing, blocking
```

---

## Quality Gates

- **Pass/Fail only** — no "mostly", "seems", "probably"
- **Must have evidence** for every pass (screenshot, output, test result)
- **Must have reproduction steps** for every fail
- **Must verify fix** before marking fixed
- **Must run regression tests** after fix

---

## Anti-Patterns

- "Looks okay" without verification → BLOCK
- Skipping edge cases → WARN
- Fixing without understanding root cause → BLOCK
- Marking fixed without re-testing → BLOCK
- Missing test coverage for new features → FAIL
- "Good enough" mentality → BLOCK
