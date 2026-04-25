# /review

Two-stage code review: AI review followed by human sign-off. AI catches logic errors, security issues, style violations. Human confirms business logic, UX, edge cases.

**MAX_PARALLEL_AGENTS** — ceiling for review lanes. Split review only across distinct concerns or file groups that can be examined independently.

**Use when:** User says "review this", "review code", "look at these changes", "PR review", "swarm review".

**Swarm:** "swarm review" → `/review` with an efficacy-first review wave up to `MAX_PARALLEL_AGENTS`.

---

## Purpose

Catch defects, security issues, and quality problems before they reach production. Two stages ensure both mechanical and business concerns are addressed.

`/review` is not a substitute for `/introspect`. Review evaluates code and change quality; introspection is the model's hard-gate self-audit before confidence, closeout, or push. When reviewing your own implementation, run `/introspect post-implementation` before treating the review as complete.

---

## Execution Protocol

### Stage 1: AI Review

#### Step 1: Identify Scope

- What files changed?
- What's the purpose of these changes?
- Are there tests?
- Does each changed file have a changed-line trace back to the user request, `SPEC.md`, generated output, or cleanup caused by this change?

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
- Speculative abstractions, generic adapters, or configurability not required by the current spec
- Drive-by refactors, formatting churn, comment rewrites, or adjacent cleanup outside the requested scope

#### Step 5: Test Coverage

- Are there tests for changed code?
- Do tests cover edge cases?
- Do tests actually run and pass?

### Stage 2: Human Review (Output for User)

Before producing the final recommendation, run an introspection pass:
- Did the review miss changed files or generated artifacts?
- Did it rely on the diff without reading the actual code?
- Are there missing tests that should be blockers?
- Are security or rollback risks under-classified?
- Should confidence be downgraded because verification did not run?
- Did the implementation stay to the smallest sufficient implementation?
- Are any changed-line trace gaps, speculative abstractions, or drive-by refactors still unresolved?

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
- **Self-review requires `/introspect post-implementation`** → FAIL if unresolved introspection blockers remain
- **Changed-line trace gaps** are findings → FAIL if meaningful diff cannot be tied to `SPEC.md` or requested scope
- **No drive-by refactors** → FAIL if unrelated cleanup, formatting churn, or comment rewrites are mixed into the change
- **No speculative abstractions** → FAIL if the diff adds generic flexibility not required by current success criteria

---

## Anti-Patterns

- Vague feedback ("could be better", "style issue") → BLOCK
- No specific citations → BLOCK
- Skipping security review → BLOCK
- Not running tests → BLOCK
- Approving without understanding → BLOCK
- Skipping Stage 2 (going straight to approval) → BLOCK
- Treating review as a replacement for `/introspect` → BLOCK
- Ignoring changed-line trace gaps → BLOCK
- Approving speculative abstractions or drive-by refactors as harmless polish → BLOCK
