# SPEC: GitHub Copywriting Overhaul

## Problem Statement
The minmaxing GitHub page doesn't communicate its competitive advantage clearly. Visitors don't immediately understand why this harness is better than alternatives.

## Success Criteria
- [ ] Hero section clearly states the value proposition in 1 sentence
- [ ] README explains SPEC-first + 10-agent parallelism + bypassPermissions as differentiators
- [ ] README highlights "yolo mode" for power users
- [ ] README shows the one-command setup front and center
- [ ] Copywriting is punchy, not marketing fluff
- [ ] All 13 skills are listed with clear descriptions
- [ ] Agent pool configuration is documented

## Scope
### In
- README.md hero/tagline
- README.md key differentiators section
- README.md "How It Works" section
- README.md skill table
- README.md hardware/agent pool docs

### Out
- Code files (no code changes)
- CLAUDE.md (internal docs)

## Implementation Plan
1. Rewrite hero to focus on "right results, not fast results"
2. Add SPEC-first as the #1 differentiator
3. Add 10-agent parallelism section
4. Add bypassPermissions/acceptEdits note
5. Update skill table with better descriptions
6. Add hardware detection note

## Verification
- [ ] Read README aloud - does it sound like a human wrote it?
- [ ] Can you explain what minmaxing does in one sentence?
- [ ] Is setup command visible without scrolling?

## Rollback
1. `git revert HEAD` to undo README changes
