# /review

Two-stage code review: AI review followed by human sign-off. AI catches logic errors, security issues, style violations. Human confirms business logic, UX, edge cases.

**Use when:** User says "review this", "review code", "look at these changes", "PR review".

**Must cite specific issues.** "This looks fine" without analysis is not a review.

---

## Purpose

Catch defects, security issues, and quality problems before they reach production. Two stages ensure both mechanical and business concerns are addressed.

---

## Execution Protocol

### Stage 1: AI Review

#### Step 1: Identify Scope

- What files changed?
- What's the purpose of these changes?
- Are there tests?

#### Step 2: Logic Review

For each changed file:

- Read the diff/changes
- Trace execution paths
- Look for: off-by-one errors, null pointer risks, race conditions, logic errors
- Verify error handling exists and is correct

#### Step 3: Security Review

- SQL injection vectors
- Command injection vectors
- Authentication/authorization gaps
- Data exposure risks
- Input validation

#### Step 4: Style/Quality Review

- ESLint/Pylint violations (if error-mode is on)
- Naming clarity
- Comment accuracy (not outdated)
- Code duplication
- Complexity warnings

#### Step 5: Test Coverage

- Are there tests for changed code?
- Do tests cover edge cases?
- Do tests actually run and pass?

### Stage 2: Human Review (Output for User)

Format for human review:

```markdown
## Review Summary: [PR/Changes]

### Files Changed
- file1.ext
- file2.ext

### AI Review Findings

#### Must Fix (Blockers)
1. **[file:line]** [Issue] — [Specific problem]
2. **[file:line]** [Issue] — [Specific problem]

#### Should Fix (Quality)
1. **[file:line]** [Issue] — [Suggestion]

#### Consider (Nice-to-Have)
1. [Suggestion]

### Security Concerns
- [List any security issues found]

### Test Coverage
- [x] Tests exist / [ ] No tests
- Coverage: [adequate/inadequate]

### Recommendation
- **[APPROVE]** — Ready to merge
- **[REQUEST_CHANGES]** — Must address blockers first
- **[COMMENT]** — Feedback provided, decision pending

---

**For Human Reviewer:**
- Does the logic match the intended behavior?
- Are there edge cases not covered?
- Is the UX correct from user perspective?
- Any business logic concerns?

Reply with: APPROVE / REQUEST_CHANGES / COMMENT
```

---

## Quality Gates

- **Must cite specific file and line** for every issue
- **"This looks fine"** without analysis is not a review → FAIL
- **Security issues are always blockers** → FAIL
- **Missing tests are blockers** for new code → FAIL
- **Must verify tests actually run** (not just exist) → FAIL
- **Must read the actual code** (not just diff) → FAIL

---

## Anti-Patterns

- Vague feedback ("could be better", "style issue") → BLOCK
- No specific citations → BLOCK
- Skipping security review → BLOCK
- Not running tests → BLOCK
- Approving without understanding → BLOCK
- Skipping Stage 2 (going straight to approval) → BLOCK
