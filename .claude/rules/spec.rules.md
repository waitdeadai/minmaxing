# Spec Rules

## Spec-First Mandate

Every meaningful task requires SPEC.md BEFORE any implementation.

`SPEC.md` is the active contract. Historical contracts belong in `.taste/specs/`
so a new task can get a fresh active spec without erasing what already shipped.

**Protocol:**
1. User describes goal (vague or specific)
2. If vague → Invoke /align first
3. Invoke /autoplan to generate SPEC.md
4. SPEC.md is written and approved
5. `/specqa` reviews the active spec before implementation
6. Implementation follows
7. Verification against SPEC.md
8. SPEC.md is the contract — implementation must match

## Valid Spec Requirements

A valid SPEC.md contains these required sections:

### 1. Problem Statement
What problem does this solve? (1-2 sentences maximum)

### 2. Success Criteria
Measurable outcomes — NOT subjective. Each criterion must be verifiable by:
- A test that passes/fails
- A command that succeeds/fails
- An inspection that finds/doesn't find

**Valid examples:**
- "API responds within 200ms for 95th percentile"
- "Login fails with invalid credentials and shows error message"
- "All existing tests pass after refactor"

**Invalid examples:**
- "Works well"
- "Looks good"
- "Is fast"
- "Seems correct"

### 3. Scope

**In Scope:**
- Component A
- Component B

**Out of Scope:**
- Component C (reason: requires separate project)
- Component D (reason: out of budget)

### 4. Agent-Native Estimate

Every non-trivial `SPEC.md` must include an `## Agent-Native Estimate` before
the implementation plan is frozen. It must separate agent wall-clock,
agent-hours, human touch time, calendar blockers, critical path, and
confidence. Human-equivalent estimates are secondary only.

### 5. Implementation Plan

Tasks with definitions of done. Each task must be:
- Single-responsibility (one clear goal)
- Verifiable (can prove completion)
- Bounded (has clear end)

```
### Task 1: [Name]
Definition of Done:
- [ ] Sub-task A
- [ ] Sub-task B

### Task 2: [Name]
Definition of Done:
- [ ] Sub-task A
```

### 6. Verification
How will we verify each success criterion?
- Criterion 1 → [test name or command]
- Criterion 2 → [inspection method]

### 7. Rollback Plan
How to undo if this breaks production?
1. Step 1: [git revert or rollback command]
2. Step 2: [database rollback if needed]
3. Step 3: [verification command]

## SPEC-Driven Generated Images

When `SPEC.md` asks for generated or edited raster images, treat each image as
a concrete product artifact, not optional visual inspiration. The spec must
include:

- target path and file format
- dimensions or aspect ratio
- intended use in the product or docs
- style and brand constraints
- exact embedded text, or `no embedded text`
- acceptance checks for file existence, dimensions, subject fidelity, and text
  legibility when relevant
- billing/auth route: `Codex subscription via codex-imagegen`, unless the user
  explicitly approves API billing

Use the repo-scoped Codex skill `.agents/skills/codex-imagegen/SKILL.md` for
this lane. Do not use OpenAI API keys, API scripts, or API-priced fallbacks for
SPEC image assets when the spec says Codex subscription. If Codex image
generation is unavailable, write a handoff prompt and mark the asset blocked;
do not claim the image was generated.

## Spec Enforcement

| Failure | Response |
|---------|----------|
| No SPEC.md before code | FAIL — do not write code |
| Vague success criteria | FAIL — must be objective and verifiable |
| No rollback plan for production | FAIL — must have rollback |
| Missing verification method | FAIL — must specify how to verify |
| Out-of-scope not listed | FAIL — scope must be explicit |
| Missing Agent-Native Estimate for non-trivial work | FAIL — must estimate in agent-native wall-clock terms |
| Human-equivalent-only estimate | FAIL — must be secondary only |
| Missing Spec QA before implementation | FAIL — run `/specqa` after SPEC.md and before execution |
| SOTA/current claims without source ledger | FAIL — add webresearched actual-time data or remove the claim |
| SPEC image asset lacks path/checks/billing route | FAIL — must define the artifact contract before generating |

## When to Update Spec

- Scope changes mid-implementation → update spec first, then continue
- New understanding of problem → update spec first
- User-requested changes → update spec first
- **SPEC.md is source of truth, not implementation**

## When to Archive Spec

- Before replacing a non-reused active `SPEC.md` → run `bash scripts/spec-archive.sh prepare "[task]" "superseded-before-new-spec"`
- After verified local closeout → run `bash scripts/spec-archive.sh closeout "[task]" "verified: [short outcome]"`
- Before or after an explicit ship commit → run `bash scripts/spec-archive.sh closeout "[task]" "shipped: [short outcome]"`
- If `SPEC.md` already matches the current task → reuse it and do not archive until closeout
- If the archive helper reports the same hash already exists → treat that as success, not a failure

## Anti-Patterns

- Writing code before SPEC.md → BLOCK
- Writing code before Spec QA on non-trivial file-changing work → BLOCK
- Overwriting a non-reused SPEC.md without archiving it → BLOCK
- Accepting vague criteria ("looks good") → BLOCK
- Skipping rollback plan → BLOCK
- Implementing without verification method → BLOCK
- Scope drift without spec update → BLOCK
