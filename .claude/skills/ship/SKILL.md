# /ship

Pre-ship checklist that ensures everything is ready before a requested release action. Includes verification, test selection, rollback planning, and only performs remote actions when the user explicitly wants them.

**MAX_PARALLEL_AGENTS** — ceiling for pre-ship lanes. Split checks only when they can run independently and still be reviewed coherently.

**Use when:** User says "ship this", "ready to ship", "deploy this", "ship it", "swarm ship".

**Swarm:** "swarm ship" → `/ship` with an efficacy-first pre-ship wave up to `MAX_PARALLEL_AGENTS`.

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
- [ ] SPEC.md archived with shipped/verified outcome
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

### Step 2: Run The Right Tests

```bash
# Detect the project's real test command instead of assuming npm
# Examples: npm test, pnpm test, pytest, cargo test, go test ./...
# If no automated tests exist, say so explicitly and treat that as risk.
```

### Step 3: Coverage Audit

```bash
# Use a coverage command only if the repo actually has one.
# Do not fabricate an 80% threshold for repos that do not define coverage tooling.
```

### Step 4: Sync and Push

```bash
# Remote actions are conditional.
# Only fetch, commit, push, tag, or deploy when the user explicitly asked for that outcome.
# For local-only completion, stop after verified local readiness and report that no remote action was taken.
bash scripts/spec-archive.sh closeout "[feature/change]" "shipped: [short outcome]" 2>/dev/null || true
```

### Step 6: Write Workflow Completion Artifact

After successful ship, write a completion record:

```bash
# Write workflow completion artifact
WORKFLOW_DIR="${TASTE_DIR:-$(pwd)/.taste}/workflow-runs"
mkdir -p "$WORKFLOW_DIR"

TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)
HASH=$(git rev-parse HEAD 2>/dev/null)

cat > "${WORKFLOW_DIR}/${TIMESTAMP}.json" <<EOF
{
  "timestamp": "${TIMESTAMP}",
  "task": "[user task description]",
  "commit": "${HASH}",
  "chain": ["autoplan", "sprint", "verify", "ship"],
  "status": "COMPLETE",
  "verification": "ACCEPT"
}
EOF

echo "[Workflow] Completion artifact written to ${WORKFLOW_DIR}/"
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

### Step 6.5: Record Outcome to Memory

After successful ship, record the causal factors:

```bash
# Record success with contributing factors
python3 -c "
from memory.causal import record_outcome
factors = ['spec_first', 'verify_passed', 'review_approved', 'tests_passed', 'coverage_adequate']
record_outcome(factors, 'success')
" 2>/dev/null || echo "record_outcome: skipped (memory not available)"

# Also log to episodic memory
bash scripts/memory.sh add episodic "Shipped: [feature description] — all gates passed"
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
- **SPEC.md must be archived before replacing or shipping** → FAIL

---

## Anti-Patterns

- Skipping checklist items → BLOCK
- Pushing without tests passing → BLOCK
- No rollback plan → BLOCK
- Missing documentation updates → BLOCK (if user-facing)
- "Good enough to ship" → BLOCK
- Skipping /verify before shipping → BLOCK
- Shipping without archiving the final SPEC.md → BLOCK

---

## Chain Contract

**This skill is a ship checklist playbook.** Use it when the user explicitly wants commit, push, or deploy behavior.

`/workflow` may reference this guidance, but it should not assume `/ship` is always the final nested continuation step.

When invoked directly by the user, finish with a clear summary of what remote-facing actions were or were not performed.
