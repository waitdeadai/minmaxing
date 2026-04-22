# SPEC: /workflow Memory Integration + Taste Bootstrap

## Problem Statement

`/workflow` needs memory-aware taste checking, but it also needs a coherent kernel lifecycle. Fresh repos should define the kernel explicitly with `/tastebootstrap` before execution, and the kernel itself should describe project vision and operating guardrails rather than forcing a frontend/backend questionnaire.

## Success Criteria

- [ ] `/workflow` Taste Check calls `memory recall` to get relevant past decisions
- [ ] `/workflow` Taste Check reads taste.md + taste.vision first
- [ ] If taste.md or taste.vision missing → `/workflow` stops and redirects to `/tastebootstrap`
- [ ] `/tastebootstrap` defines taste for new projects before `/workflow` proceeds
- [ ] `/audit` asks taste questions before researching (taste-first audit)
- [ ] taste.md uses an operating-kernel structure that is broader than frontend/backend
- [ ] Memory recall results injected into Taste Check context

## Scope

### In Scope
- Update `/workflow` Taste Check to call `memory recall`
- Add an explicit `/tastebootstrap` entrypoint for fresh repos
- Update taste kernel templates to center vision, experience, interfaces, and system behavior
- Update `/audit` skill to ask taste questions before research
- Update `/autoplan` to redirect to `/tastebootstrap` if taste undefined

### Out of Scope
- Changes to memory Python code (already complete)
- Changes to other skills

## Architecture

### Taste Bootstrap Flow
```
/workflow [task]
    → taste.md exists? → YES → proceed
    → NO → "Kernel not defined. Run /tastebootstrap first."
    → /tastebootstrap:
        - 10 questions for project principles, experience, interfaces, system behavior, and vision
        - Writes taste.md + taste.vision
        - Output: TASTE_DEFINED
    → Once TASTE_DEFINED → proceed to Taste Check
```

### /workflow Taste Check (updated)
```
PHASE 0: TASTE CHECK
1. Check: taste.md + taste.vision exist?
   - If NO → stop and redirect to /tastebootstrap
2. Read taste.md + taste.vision
3. Call memory recall with task description
   - memory recall → relevant semantic + procedural + error-solutions
4. Score alignment: task vs taste + memory
   - Score 0-10
   - If <5 → invoke /align → wait for approval
   - If >=5 → proceed to PHASE 1
```

### /tastebootstrap
```
/tastebootstrap
    → 10 questions for principles, intent, experience, interfaces, operations, code, architecture, and non-goals
    → Write taste.md + taste.vision
    → Output: TASTE_DEFINED
```

### /audit Taste Integration
```
/audit [target]
    → PHASE 0: Taste Check (same as /workflow)
        - Read taste.md + taste.vision
        - memory recall relevant decisions
        - Does target align with taste?
    → If misaligned → /align before audit
    → PHASE 1: Research (with taste context)
```

## Implementation Plan

### Phase 1: Update /workflow [PARALLEL: 2 agents]

- [ ] Task 1: Update `.claude/skills/workflow/SKILL.md` [PARALLEL]
  - Taste Check calls `memory recall <task> --depth medium`
  - Injects memory recall results into context
  - Stops and redirects to `/tastebootstrap` if kernel files are missing
  - Definition of Done: Taste Check protocol shows memory recall call and bootstrap redirect

- [ ] Task 2: Add `.claude/skills/tastebootstrap/SKILL.md` [PARALLEL]
  - Dedicated bootstrap contract for fresh repos
  - 10 questions for the operating kernel and vision
  - Writes taste.md + taste.vision to project root
  - Definition of Done: /tastebootstrap creates taste files before /workflow runs

### Phase 2: Update /audit + /autoplan [PARALLEL: 2 agents]

- [ ] Task 3: Update `.claude/skills/audit/SKILL.md` [PARALLEL]
  - Add PHASE 0: Taste Check before audit research
  - /align on misalignment before proceeding
  - Definition of Done: audit skill shows taste-first approach

- [ ] Task 4: Update `.claude/skills/autoplan/SKILL.md` [PARALLEL]
  - Step 1: Check taste.md + taste.vision exist
  - If NO → invoke /tastebootstrap first
  - Then proceed with planning
  - Definition of Done: /autoplan bootstraps taste if undefined

## Verification

| Criterion | Method |
|-----------|--------|
| /workflow calls memory recall | Manual: invoke /workflow, observe memory recall output |
| Taste bootstrap creates files | Manual: `rm taste.md taste.vision; /tastebootstrap; ls taste.*` |
| /audit taste-first | Manual: invoke /audit, observe Taste Check before research |
| /autoplan taste bootstrap | Manual: remove taste files, invoke /autoplan, observe bootstrap |
| Memory injected into context | Manual: check /workflow output includes recall results |

## Rollback Plan

1. `git revert <commit>` — undo all changes
2. Restore skill files from git
