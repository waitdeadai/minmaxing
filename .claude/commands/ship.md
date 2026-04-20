# /ship

Pre-ship checklist that ensures everything is ready before production deployment. Includes sync, test, coverage audit, push, and rollback plan.

**Use when:** User says "ship this", "ready to ship", "deploy this", "ship it".

**ALL gates must pass.** No exceptions, no shortcuts.

---

## Purpose

Ensure all quality gates pass before production deployment. This is the last line of defense.

---

## Execution Protocol

### Step 1: Pre-Ship Checklist

```markdown
## Pre-Ship Checklist: [Feature/Change]

### Code Quality
- [ ] ESLint passes (error mode, no warnings)
- [ ] No console.log/debugger statements
- [ ] No hardcoded secrets/credentials
- [ ] Error handling is complete

### Testing
- [ ] Unit tests pass: `npm test` or equivalent
- [ ] Integration tests pass
- [ ] E2E tests pass (if applicable)
- [ ] Test coverage adequate: [X]%

### Documentation
- [ ] README updated (if user-facing)
- [ ] API docs updated (if API changed)
- [ ] CHANGELOG updated

### Verification
- [ ] /verify passed against SPEC.md
- [ ] /review approved
- [ ] All open issues addressed

### Deployment
- [ ] Rollback plan documented
- [ ] Migration scripts ready (if DB changes)
- [ ] Feature flags configured (if applicable)
- [ ] Environment variables set

### Communication
- [ ] Stakeholders notified
- [ ] Runbook updated (if needed)
- [ ] Monitoring alerts configured
```

### Step 2: Run All Tests

```bash
# Run full test suite
npm test 2>&1 | tee test-output.txt

# Check exit code
if [ $? -ne 0 ]; then
  echo "TESTS FAILED — Cannot ship"
  exit 1
fi
```

### Step 3: Coverage Audit

```bash
# Run coverage report
npm run coverage 2>&1 | tee coverage.txt

# Check coverage meets threshold (e.g., 80%)
COVERAGE=$(grep "Coverage" coverage.txt | awk '{print $2}' | tr -d '%')
if [ "$COVERAGE" -lt 80 ]; then
  echo "COVERAGE TOO LOW: $COVERAGE% — Cannot ship"
  exit 1
fi
```

### Step 4: Sync and Push

```bash
# Sync with remote
git fetch origin
git pull origin main

# Run tests one more time
npm test

# Commit if clean
git add -A
git commit -m "Ship: [feature description]"

# Push
git push origin HEAD
```

### Step 5: Rollback Plan Documentation

```markdown
## Rollback Plan: [Feature Name]

### How to Roll Back
1. Command to revert: [git revert or deploy previous version]
2. Database migrations: [how to reverse, if any]
3. External services: [any cleanup needed]

### Rollback Triggers
- Error rate > [X]%
- Latency increase > [Y]ms
- Specific error message: [pattern]

### Verification After Rollback
1. Check [dashboard URL]
2. Run [sanity test]
3. Verify [specific feature] works
```

### Step 6: Final Verification

```bash
# Deploy to production
[deployment command]

# Verify deployment
curl -f https://production/api/health || exit 1

# Check logs for errors
[check logs]

echo "SHIP COMPLETE"
```

### Step 7: Final Output

```markdown
## Ship Results: [Feature Name]

### Checklist Status
- Code Quality: PASS/FAIL
- Testing: PASS/FAIL
- Documentation: PASS/FAIL
- Verification: PASS/FAIL
- Deployment: PASS/FAIL

### Test Results
- Unit Tests: [PASS/FAIL]
- Integration: [PASS/FAIL]
- E2E: [PASS/FAIL]
- Coverage: [X]%

### Deployment
- Commit: [hash]
- Deployed at: [timestamp]
- Rollback ready: [YES/NO]

### Final Verdict
- **[SHIPPED]** — All gates passed
- **[BLOCKED]** — [N] gates failed
```

---

## Quality Gates

- **ALL checklist items must be checked** → FAIL if skipped
- **Tests must pass** (no exceptions) → FAIL
- **Coverage must meet threshold** → FAIL
- **Rollback plan must exist** before push → FAIL
- **Verification must pass** before declaring shipped → FAIL

---

## Anti-Patterns

- Skipping checklist items → BLOCK
- Pushing without tests passing → BLOCK
- No rollback plan → BLOCK
- Missing documentation updates → BLOCK (if user-facing)
- "Good enough to ship" → BLOCK
- Skipping /verify before shipping → BLOCK
