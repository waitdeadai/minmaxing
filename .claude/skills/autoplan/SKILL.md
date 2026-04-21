# /autoplan

SPEC-first planning that generates SPEC.md before any implementation. Uses plan mode to create the spec — you approve the plan, and it becomes the contract.

**This IS plan mode.** `/autoplan` invokes plan mode to draft SPEC.md. You review and approve. The approved plan becomes the source of truth.

**10-Agent Parallel Mindset is DEFAULT.** Every plan assumes max parallel execution (10 agents by default). Research uses parallel agents for deep research.

**Use when:** User says "plan this", "how do I build", "spec out", "create a plan", "swarm", "swarm this", or when a new feature/project is described.

**NEVER skip to implementation.** SPEC.md is mandatory before any code.

---

## Execution Protocol

### Step 1: Understand the Goal

- Read user's description carefully
- Identify what success looks like (verifiable, not vague)
- If vague → Invoke /office-hours first

### Step 2: Parallel Research (use MAX_PARALLEL_AGENTS)

**Research FIRST using all available agents.** Deep research produces better specs.

Decompose research into parallel tracks:
- Track 1: Current best practices / state of art
- Track 2: API/SDK documentation
- Track 3: Libraries and tools
- Track 4: Similar implementations / patterns
- Track N: [domain-specific aspects]

Spawn MAX_PARALLEL_AGENTS searches simultaneously, then synthesize findings.

### Step 3: Scope Challenge

Before writing spec, challenge the scope:

- **Is this scope creep?** Flag if > 3 major components
- **What's the narrowest wedge?** Can we ship less?
- **What's the 20% that gives 80% of value?
- **What's the smallest shippable thing?**

Ask: "What if we only built X? Would that be enough?"

### Step 4: Generate SPEC.md

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
### Phase 1: Foundation [PARALLEL: 2 agents]
- [ ] Task 1 [PARALLEL] (definition of done)
- [ ] Task 2 [PARALLEL] (definition of done)

### Phase 2: Core Feature [PARALLEL: 4 agents]
- [ ] Task 3 [PARALLEL]
- [ ] Task 4 [PARALLEL]
- [ ] Task 5 [SEQUENTIAL - depends on Task 3]

### Phase 3: Polish [PARALLEL: 2 agents]
- [ ] Task 6 [PARALLEL]
- [ ] Task 7 [PARALLEL]

**Note:** Tasks tagged [PARALLEL] can run simultaneously with 10-agent pool. Group them to maximize throughput.

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

### Step 5: Break Down Tasks (10-Agent Mindset)

**Always plan for parallel execution.** The supervisor pattern decomposes work into tasks that can run simultaneously.

For each task in SPEC.md:

- Define clear "definition of done"
- Identify dependencies (what must come first)
- Estimate complexity (1=single file, 2=few files, 3=architectural)
- **Tag each task for parallelization:**
  - `[PARALLEL]` = Can run with other parallel tasks (different files)
  - `[SEQUENTIAL]` = Must run after dependency completes
  - `[GATE]` = Must pass before next phase starts

**Target: Maximize PARALLEL tasks.** With 10 agents, aim for 6-8 parallel tasks per phase.

### Step 6: Output Format

```
SPEC.md created: /path/to/SPEC.md

## Summary
- Scope: [in/out count] components
- Tasks: [N] verifiable tasks
- Parallel Tasks: [M] (ready for 10-agent pool)
- Sequential Tasks: [K]
- Verification: [N] criteria

## Execution Plan
With 10-agent pool:
- Phase 1: [N] tasks in parallel
- Phase 2: [M] tasks in parallel
- Phase 3: [K] sequential gate

## Next Steps
1. Review SPEC.md
2. Approve or revise
3. Execute via /sprint (parallel by default)

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
