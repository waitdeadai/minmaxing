# /autoplan

SPEC-first planning that generates SPEC.md before any implementation. Challenges scope, breaks objectives into verifiable tasks with metrics.

**Use when:** User says "plan this", "how do I build", "spec out", "create a plan", or when a new feature/project is described.

**NEVER skip to implementation.** SPEC.md is mandatory before any code.

---

## Purpose

Generate SPEC.md that defines what to build, how to verify it, and how to undo it. This is the contract between user and implementation.

**This is not a todo list.** It's a specification document with verifiable success criteria.

---

## Execution Protocol

### Step 1: Understand the Goal

- Read user's description carefully
- Identify what success looks like (verifiable, not vague)
- If vague → Invoke /office-hours first

### Step 2: Scope Challenge

Before writing spec, challenge the scope:

- **Is this scope creep?** Flag if > 3 major components
- **What's the narrowest wedge?** Can we ship less?
- **What's the 20% that gives 80% of value?**
- **What's the smallest shippable thing?**

Ask: "What if we only built X? Would that be enough?"

### Step 3: Generate SPEC.md

Write SPEC.md with these sections:

```markdown
# SPEC: [Project/Feature Name]

## Problem Statement
What problem does this solve? (1-2 sentences)

## Success Criteria
- [ ] Criterion 1 (verifiable, not subjective)
- [ ] Criterion 2 (verifiable, not subjective)
- [ ] Criterion 3 (verifiable, not subjective)

## Scope
### In Scope
- Component A
- Component B

### Out of Scope
- Component C (reason: requires separate project)
- Component D (reason: out of budget)

## Implementation Plan
### Phase 1: Foundation
- [ ] Task 1 (definition of done)
- [ ] Task 2 (definition of done)

### Phase 2: Core Feature
- [ ] Task 3
- [ ] Task 4

### Phase 3: Polish
- [ ] Task 5

## Verification
How will we verify each success criterion?
- Criterion 1 → [test name or command]
- Criterion 2 → [test name or command]
- Criterion 3 → [inspection method]

## Rollback Plan
How do we undo if this breaks production?
1. Step 1: [git revert or rollback command]
2. Step 2: [database rollback if needed]
```

### Step 4: Break Down Tasks

For each task in SPEC.md:

- Define clear "definition of done"
- Identify dependencies (what must come first)
- Estimate complexity (1=single file, 2=few files, 3=architectural)

### Step 5: Output Format

```
SPEC.md created: /path/to/SPEC.md

## Summary
- Scope: [in/out count] components
- Tasks: [N] verifiable tasks
- Verification: [N] criteria

## Next Steps
1. Review SPEC.md
2. Approve or revise
3. Execute via /sprint or sequential implementation

Ready for /sprint when approved.
```

---

## Quality Gates

- **SPEC.md must exist before any code** → FAIL if code exists without spec
- **Every task must have verifiable "definition of done"** → FAIL if vague
- **Success criteria must be objective** — not "looks good", "works well" → FAIL
- **Out-of-scope items must be explicitly stated** → FAIL if missing
- **Rollback plan must exist for production changes** → FAIL if missing

---

## Anti-Patterns

- Generating code without SPEC.md → BLOCK
- Vague success criteria ("looks good", "works well") → BLOCK
- No rollback plan for production changes → BLOCK
- Scope not challenged (accepting first solution) → WARN and challenge
- Skipping scope reduction → WARN
- Missing verification method for criteria → BLOCK
