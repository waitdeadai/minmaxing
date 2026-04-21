# SPEC: /workflow Memory Integration + Taste Bootstrap

## Problem Statement

`/workflow` doesn't integrate with the memory system during Taste Check. Also, if `taste.md` / `taste.vision` don't exist, `/workflow` and `/align` fail instead of bootstrapping taste definition first.

## Success Criteria

- [ ] `/workflow` Taste Check calls `memory recall` to get relevant past decisions
- [ ] `/workflow` Taste Check reads taste.md + taste.vision first
- [ ] If taste.md or taste.vision missing → prompts to bootstrap via `/align`
- [ ] `/align` can bootstrap taste definition for new projects
- [ ] `/audit` asks taste questions before researching (taste-first audit)
- [ ] Memory recall results injected into Taste Check context

## Scope

### In Scope
- Update `/workflow` Taste Check to call `memory recall`
- Update `/align` to support taste bootstrap mode
- Update `/audit` skill to ask taste questions before research
- Update `/autoplan` to redirect to `/align` if taste undefined

### Out of Scope
- Changes to memory Python code (already complete)
- Changes to other skills

## Architecture

### Taste Bootstrap Flow
```
/workflow [task]
    → taste.md exists? → YES → proceed
    → NO → "Taste not defined. Let's define it."
    → invoke /align --bootstrap
    → /align --bootstrap:
        - 5 questions to define taste.md
        - 5 questions to define taste.vision
        - Writes taste.md + taste.vision
        - Output: TASTE_DEFINED
    → Once TASTE_DEFINED → proceed to Taste Check
```

### /workflow Taste Check (updated)
```
PHASE 0: TASTE CHECK
1. Check: taste.md + taste.vision exist?
   - If NO → invoke /align --bootstrap → wait → retry
2. Read taste.md + taste.vision
3. Call memory recall with task description
   - memory recall → relevant semantic + procedural + error-solutions
4. Score alignment: task vs taste + memory
   - Score 0-10
   - If <5 → invoke /align → wait for approval
   - If >=5 → proceed to PHASE 1
```

### /align Bootstrap Mode
```
/align --bootstrap
    → 5 questions for taste.md (design principles, aesthetic rules, code style, architecture, naming)
    → 5 questions for taste.vision (intent, success criteria, non-goals, taste feel)
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
  - Definition of Done: Taste Check protocol shows memory recall call

- [ ] Task 2: Update `.claude/skills/align/SKILL.md` [PARALLEL]
  - Add `--bootstrap` flag for taste creation
  - 5 questions for taste.md, 5 for taste.vision
  - Writes taste.md + taste.vision to project root
  - Definition of Done: /align --bootstrap creates taste files

### Phase 2: Update /audit + /autoplan [PARALLEL: 2 agents]

- [ ] Task 3: Update `.claude/skills/audit/SKILL.md` [PARALLEL]
  - Add PHASE 0: Taste Check before audit research
  - /align on misalignment before proceeding
  - Definition of Done: audit skill shows taste-first approach

- [ ] Task 4: Update `.claude/skills/autoplan/SKILL.md` [PARALLEL]
  - Step 1: Check taste.md + taste.vision exist
  - If NO → invoke /align --bootstrap first
  - Then proceed with planning
  - Definition of Done: /autoplan bootstraps taste if undefined

## Verification

| Criterion | Method |
|-----------|--------|
| /workflow calls memory recall | Manual: invoke /workflow, observe memory recall output |
| Taste bootstrap creates files | Manual: `rm taste.md taste.vision; /align --bootstrap; ls taste.*` |
| /audit taste-first | Manual: invoke /audit, observe Taste Check before research |
| /autoplan taste bootstrap | Manual: remove taste files, invoke /autoplan, observe bootstrap |
| Memory injected into context | Manual: check /workflow output includes recall results |

## Rollback Plan

1. `git revert <commit>` — undo all changes
2. Restore skill files from git
