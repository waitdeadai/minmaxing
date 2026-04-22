# /autoplan

SPEC-first planning that generates or updates `SPEC.md` before implementation.

**This command writes the spec directly.** It does not switch Claude Code into built-in plan mode for you. If you want Claude Code's read-only planning mode, use the platform's native `/plan` flow or start Claude with `--permission-mode plan`.

**TASTE-FIRST** — If taste.md/vision undefined, bootstraps via /align before planning.

**MAX_PARALLEL_AGENTS** — spawns up to 10 parallel research agents for deep research during planning.

**Use when:** User says "plan this", "how do I build", "spec out", "create a plan", "swarm", or when a new feature/project is described.

**Swarm:** "swarm" → `/autoplan` with 10 parallel research agents.

**NEVER skip to implementation.** SPEC.md is mandatory before any code.

---

## Execution Protocol

### Step 1: Understand the Goal + Taste Bootstrap + Memory Recall

- Read user's description carefully
- Identify what success looks like (verifiable, not vague)
- Check: taste.md + taste.vision exist?
  - If NO → invoke /align --bootstrap first, then continue
  - If YES → proceed to Step 2
- Recall similar past plans to inform scope and approach:
```bash
bash scripts/memory.sh recall "[planning topic]" --depth medium 2>/dev/null || echo "Memory recall: skipped"
bash scripts/memory.sh search "spec" 2>/dev/null || true
```

### Step 2: Parallel Research (use MAX_PARALLEL_AGENTS)

**Research FIRST using all available agents.** Deep research produces better specs.

Decompose research into parallel tracks:
- Track 1: Current best practices / state of art
- Track 2: API/SDK documentation
- Track 3: Libraries and tools
- Track 4: Similar implementations / patterns
- Track N: [domain-specific aspects]

Spawn MAX_PARALLEL_AGENTS searches simultaneously, then synthesize findings.

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
- **What's the 20% that gives 80% of value?
- **What's the smallest shippable thing?**

Ask: "What if we only built X? Would that be enough?"

The plan should state:
- what changes
- what stays untouched
- repo constraints
- verification approach
- rollback approach when relevant

### Step 5: Generate SPEC.md

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

### Step 6: Break Down Tasks (10-Agent Mindset)

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

### Step 7: Output Format

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

---

## Anti-Patterns

- Generating code without SPEC.md → BLOCK
- Writing `SPEC.md` before code audit + plan synthesis → BLOCK
- Vague success criteria ("looks good", "works well") → BLOCK
- No rollback plan for production changes → BLOCK
- Scope not challenged (accepting first solution) → WARN and challenge
- Skipping scope reduction → WARN
- Missing verification method for criteria → BLOCK
