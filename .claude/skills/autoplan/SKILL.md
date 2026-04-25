# /autoplan

SPEC-first planning that generates or updates `SPEC.md` before implementation.

**This command writes the spec directly.** It does not switch Claude Code into built-in plan mode for you. If you want Claude Code's read-only planning mode, use the platform's native `/plan` flow or start Claude with `--permission-mode plan`.

**TASTE-FIRST** — If taste.md/vision undefined, bootstrap taste before planning, preferably via `/tastebootstrap`.

**MAX_PARALLEL_AGENTS** — ceiling for parallel planning research. Use the smallest effective wave that covers the distinct questions.

**Use when:** User says "plan this", "how do I build", "spec out", "create a plan", "swarm", or when a new feature/project is described.

**Swarm:** "swarm" → `/autoplan` with an efficacy-first research wave up to `MAX_PARALLEL_AGENTS`.

**NEVER skip to implementation.** SPEC.md is mandatory before any code.

---

## Execution Protocol

### Step 1: Understand the Goal + Taste Bootstrap + Memory Recall

- Read user's description carefully
- Identify what success looks like (verifiable, not vague)
- Check: taste.md + taste.vision exist?
  - If NO → invoke `/tastebootstrap` first, then continue
  - If YES → proceed to Step 2
- Recall similar past plans to inform scope and approach:
```bash
bash scripts/memory.sh recall "[planning topic]" --depth medium 2>/dev/null || echo "Memory recall: skipped"
bash scripts/memory.sh search "spec" 2>/dev/null || true
```

### Step 2: Parallel Research (use MAX_PARALLEL_AGENTS)

**Research FIRST using the right number of agents.** Deep research produces better specs when the tracks are distinct and high-value, but the research should follow the repo’s effectiveness-first `deepresearch` protocol rather than a generic search dump.

Before the first search wave, write a collaborative research plan that names:
- the target deliverable the spec must unlock
- the core questions or branches
- the source classes to consult
- the likely contradictions or unknowns to pressure-test
- the stop condition for "research is sufficient to plan"

Decompose research into distinct tracks:
- Track 1: Current best practices / state of art
- Track 2: API/SDK documentation
- Track 3: Libraries and tools
- Track 4: Similar implementations / patterns
- Track N: [domain-specific aspects]

Choose an effective research budget up to `MAX_PARALLEL_AGENTS`, spawn only the non-redundant tracks, then run an iterative search -> read -> refine loop. Keep a source ledger with cited sources, reviewed but not cited sources, and conflicting evidence that still needs follow-up before the spec is frozen. If the task is narrow and current-fact oriented, this can resemble `/webresearch`; if it broadens materially, treat it like `/deepresearch`.

### Step 3: Code Audit

Before writing the plan or `SPEC.md`, audit the existing codebase:

- Which files are the likely change surface?
- Which tests, scripts, configs, or commands already govern this area?
- Which existing patterns must be preserved?
- What constraints or risks does the current implementation impose?

For greenfield work inside a fresh folder, the "code audit" can be minimal, but still identify the repo structure, available scripts, and any setup constraints.

### Step 4: Scope Challenge + Plan Synthesis

Before writing spec, challenge the scope and synthesize a concrete plan:

- **Is this scope creep?** Flag if > 3 major components
- **What's the narrowest wedge?** Can we ship less?
- **What's the 20% that gives 80% of value?**
- **What's the smallest shippable thing?**
- **What is the smallest sufficient implementation?** Prefer the narrowest implementation that satisfies the user's request and can be verified.
- **Are we inventing speculative abstractions?** Block generic frameworks, adapters, configurability, or future-proofing that no success criterion requires.
- **Are we planning drive-by refactors?** Move unrelated cleanup to out-of-scope unless it is required by the active change.

Ask: "What if we only built X? Would that be enough?"

The plan should state:
- what changes
- what stays untouched
- repo constraints
- verification approach
- rollback approach when relevant

### Step 5: Generate SPEC.md

Before writing, replacing, or reusing `SPEC.md`, run `/introspect pre-plan` inline as a hard gate.

Check:
- whether the research and code audit actually support the plan
- whether the plan is too broad, too vague, or missing a rollback path
- whether success criteria are objective enough to verify
- whether the smallest sufficient implementation has been chosen
- whether speculative abstractions or drive-by refactors slipped into scope
- whether the active spec should be reused or archived
- whether hidden assumptions need user input before the spec is frozen

If introspection returns `FIX_REQUIRED`, correct the plan first. If it returns `REPLAN_REQUIRED`, revise scope before writing `SPEC.md`. If it returns `BLOCKED`, stop and explain the blocker.

If an active `SPEC.md` already exists and is not reusable for this exact task, archive it before replacing it:

```bash
bash scripts/spec-archive.sh prepare "[planning topic]" "superseded-by-autoplan" 2>/dev/null || true
```

If the active `SPEC.md` already matches the current task, reuse it instead of archiving or rewriting it.

Write SPEC.md with these sections:

```markdown
# SPEC: [Project/Feature Name]

## Problem Statement
What problem does this solve? (1-2 sentences)

## Codebase Anchors
- Relevant existing files, modules, or constraints
- Patterns this implementation must preserve

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

## Surgical Diff Discipline
- Smallest sufficient implementation: [narrowest version that satisfies the request]
- No speculative abstractions: [what is intentionally not generalized]
- No drive-by refactors: [what adjacent code will stay untouched]
- Changed-line trace: [how planned file changes map to success criteria]

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

**Note:** Tasks tagged [PARALLEL] can run simultaneously when ownership is clear, dependencies are satisfied, and the wave meaningfully shortens the critical path.

## Verification
How will we verify each success criterion?
- Criterion 1 → [test name or command]
- Criterion 2 → [test name or command]
- Criterion 3 → [inspection method]

## Rollback Plan
How do we undo if this breaks production?
1. Step 1: [git revert or rollback command]
2. Step 2: [database rollback if needed]

## Parallelization Notes
- Effective Agent Budget: [B] of [MAX_PARALLEL_AGENTS]
- Why this budget: [distinct independent packets only]
- For every delegated task, record:
  - Owned files/surfaces
  - Dependencies / prerequisites
  - Expected return artifact or evidence
  - Freshness checkpoint / stop condition
```

### Step 6: Break Down Tasks (Efficacy-First Parallelization)

**Plan for parallel execution when it helps.** The supervisor pattern decomposes work into tasks that can run simultaneously without shared-file collisions or coordination thrash.

For each task in SPEC.md:

- Define clear "definition of done"
- Identify dependencies (what must come first)
- Estimate complexity (1=single file, 2=few files, 3=architectural)
- Assign ownership (files or surfaces) for every delegated packet
- **Tag each task for parallelization:**
  - `[PARALLEL]` = Can run with other parallel tasks (different files)
  - `[SEQUENTIAL]` = Must run after dependency completes
  - `[GATE]` = Must pass before next phase starts

**Target: Maximize solved critical path, not slot usage.** Leave tasks sequential when they share context or ownership.

### Step 7: Output Format

```
SPEC.md created: /path/to/SPEC.md
Spec archive: [.taste/specs/... or not needed]

## Summary
- Scope: [in/out count] components
- Tasks: [N] verifiable tasks
- Parallel Tasks: [M] (ownership-clear and ready for delegated execution)
- Sequential Tasks: [K]
- Verification: [N] criteria
- Effective Agent Budget: [B] of [MAX_PARALLEL_AGENTS]

## Execution Plan
With the chosen agent budget:
- Phase 1: [N] tasks in parallel
- Phase 2: [M] tasks in parallel
- Phase 3: [K] sequential gate

## Next Steps
1. Review SPEC.md
2. Revise if needed
3. Execute the implementation yourself or via `/workflow`

---

## Workflow Contract

**This skill is a spec-generation playbook.** `/workflow` may reuse this guidance, but it should not rely on invoking `/autoplan` as a guaranteed nested continuation step.

When invoked directly by the user, stop after the spec is ready.

When `/workflow` references this skill, the parent workflow continues inline and owns the remaining phases.

---

## Quality Gates

- **SPEC.md must exist before any code** → FAIL if code exists without spec
- **Every task must have verifiable "definition of done"** → FAIL if vague
- **Success criteria must be objective** — not "looks good", "works well" → FAIL
- **Out-of-scope items must be explicitly stated** → FAIL if missing
- **Rollback plan must exist for production changes** → FAIL if missing
- **Introspection must pass before SPEC.md is frozen** → FAIL if unresolved blockers remain

---

## Anti-Patterns

- Generating code without SPEC.md → BLOCK
- Writing `SPEC.md` before code audit + plan synthesis → BLOCK
- Vague success criteria ("looks good", "works well") → BLOCK
- No rollback plan for production changes → BLOCK
- Scope not challenged (accepting first solution) → WARN and challenge
- Skipping scope reduction → WARN
- Missing verification method for criteria → BLOCK
- Writing or replacing `SPEC.md` with unresolved `/introspect` blockers → BLOCK
