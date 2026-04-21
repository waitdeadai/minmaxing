# SPEC: /workflow Redesign + /align Skill

## Problem Statement

`/workflow` is just a parallel execution supervisor with no taste awareness. `/office-hours` is poorly named and doesn't integrate with taste/vision. Need `/workflow` to be the central execution engine and `/align` to gate it with taste validation.

## Success Criteria

- [ ] `/workflow` reads taste.md + taste.vision before any task
- [ ] `/workflow` taste-checks and gates on misalignment
- [ ] `/workflow` skill-router selects appropriate skills by task type
- [ ] `/align` replaces `/office-hours` with taste-first questioning
- [ ] `/align` outputs ALIGNED / REVISION_NEEDED / REJECTED
- [ ] `/workflow` invokes `/align` automatically when taste mismatch detected
- [ ] All skill docs updated: workflow, align (renamed from office-hours)
- [ ] CLAUDE.md and README.md updated with new skill names

## Scope

### In Scope
- `/workflow` redesign as Skill Orchestrator with Taste OS
- `/align` skill (renamed from `/office-hours`)
- Taste/vision integration in both skills
- Skill routing table in `/workflow`
- Documentation updates (CLAUDE.md, README.md)

### Out of Scope
- Rewriting other skills (they remain unchanged)
- New skill creation
- Memory system changes

## Architecture

```
/workflow [task]
    │
    ├─► PHASE 0: TASTE CHECK [GATE]
    │     Read taste.md + taste.vision
    │     Score task alignment: 0-10
    │     If alignment < 5 → invoke /align, wait for approval
    │     If alignment >= 5 → proceed
    │
    ├─► PHASE 1: ROUTE
    │     skill_router(task) → which skills to invoke
    │
    ├─► PHASE 2: EXECUTE
    │     skill_execute() — parallel agents where applicable
    │     Each skill respects taste/vision
    │
    ├─► PHASE 3: VERIFY
    │     taste_verify() — does output match taste?
    │     SPEC_verify() — does output match SPEC?
    │
    └─► PHASE 4: ROUTE OUTPUT
          Ship? → /ship
          Review? → /review
          Done.

/align [task]
    │
    ├─► Read taste.md + taste.vision
    ├─► 4-5 taste-aligned questions
    ├─► Score: ALIGNED / REVISION_NEEDED / REJECTED
    └─► If REJECTED → /workflow blocked
          If REVISION_NEEDED → /workflow pauses until revised
```

## Skill Routing Table

| Task Pattern | Skills to Invoke |
|--------------|-----------------|
| "build X" / "implement Y" | `/autoplan` → `/sprint` → `/verify` → `/ship` |
| "fix Z" / "debug this" | `/investigate` → `/verify` |
| "analyze decision" / "weigh options" | `/council` → `/align` if needed |
| "audit this" / "analyze codebase" | `/audit` |
| "test this" / "QA" | `/qa` |
| "review code" / "review PR" | `/review` |
| "plan this" / "spec out" | `/autoplan` |
| "search code" / "find patterns" | `/codex` |
| "research X" | `/browse` |
| "run overnight" / "long task" | `/overnight` |

## Implementation Plan

### Phase 1: /align Skill [PARALLEL: 2 agents]

- [ ] Task 1: Create `.claude/skills/align/SKILL.md` [PARALLEL]
  - Rename from /office-hours, 4-5 taste-aligned questions
  - Reads taste.md + taste.vision first
  - Outputs ALIGNED / REVISION_NEEDED / REJECTED
  - Definition of Done: skill file created with correct structure

- [ ] Task 2: Update `scripts/taste.sh` to support `/align` [PARALLEL]
  - May need taste.sh enhancements for alignment scoring
  - Definition of Done: taste.sh can score alignment

### Phase 2: /workflow Redesign [PARALLEL: 2 agents]

- [ ] Task 3: Rewrite `.claude/skills/workflow/SKILL.md` [PARALLEL]
  - PHASE 0: Taste Check with scoring
  - PHASE 1: Skill Router with table
  - PHASE 2: Execute with taste awareness
  - PHASE 3: Verify against taste + SPEC
  - PHASE 4: Route output
  - Definition of Done: workflow skill doc complete

- [ ] Task 4: Update CLAUDE.md skill table [PARALLEL]
  - Replace /office-hours with /align
  - Update /workflow description
  - Update skill routing notes
  - Definition of Done: CLAUDE.md reflects new architecture

### Phase 3: Documentation + Cleanup [PARALLEL: 2 agents]

- [ ] Task 5: Update README.md skill table [PARALLEL]
  - Replace /office-hours with /align description
  - Update /workflow description
  - Definition of Done: README.md updated

- [ ] Task 6: Remove old `/office-hours` skill file [PARALLEL]
  - Delete `.claude/skills/office-hours/SKILL.md`
  - Definition of Done: office-hours directory removed

## Verification

| Criterion | Method |
|-----------|--------|
| /workflow reads taste.md first | Manual: invoke /workflow, observe taste check output |
| /workflow gates on misalignment | Manual: propose misaligned task, observe /align invocation |
| /align questions are taste-aligned | Manual: invoke /align, verify questions reference taste |
| /align outputs ALIGNED/REVISION_NEEDED/REJECTED | Manual: test /align with aligned vs misaligned task |
| /workflow routes to correct skills | Manual: test each task pattern, verify skill invoked |
| CLAUDE.md updated | `grep -c "/align" CLAUDE.md` > 0 |
| README.md updated | `grep -c "/align" README.md` > 0 |
| /office-hours removed | File does not exist |

## Rollback Plan

1. `git revert <commit>` — undo all changes
2. Restore `.claude/skills/office-hours/SKILL.md` from git
3. Restore `.claude/skills/workflow/SKILL.md` from git
4. Restore CLAUDE.md and README.md from git
