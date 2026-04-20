# Harness Leverage Improvements

## Problem Statement
The harness has solid fundamentals (SPEC-first, /verify, research-first) but lacks two critical feedback loops: millisecond-level post-edit formatting and config protection from rule-tampering. Also CLAUDE.md is oversized and E2E testing "eyes" are missing.

## Success Criteria
- [ ] PostToolUse hook auto-formats after every file edit (millisecond feedback)
- [ ] PreToolUse hook blocks modification of .eslintrc, tsconfig.json, .prettierrc
- [ ] E2E testing skill using Playwright exists in skills/
- [ ] CLAUDE.md reduced to ≤50 lines, pointing to tools not explaining them
- [ ] All existing tests pass after changes

## Scope
**In:**
- .claude/settings.local.json hook configuration
- skills/qa/SKILL.md (Playwright E2E)
- CLAUDE.md simplification
- Pre-commit hook if needed

**Out:**
- 183-skill mega-harness approach (overkill)
- Multi-agent delegation patterns
- New scripts directory (not needed yet)

## Implementation Plan

### Task 1: PostToolUse Hook — Auto-format
Add hook in settings.local.json that runs format after every edit.
Definition of Done:
- [ ] Format command runs after any file edit
- [ ] Formats on save for .js, .ts, .py, .sh files
- [ ] No visible latency to user

### Task 2: PreToolUse Hook — Config Protection
Block agents from modifying linter/type config files.
Definition of Done:
- [ ] .eslintrc*, tsconfig.json, .prettierrc*, .ruff.toml protected
- [ ] Edit attempt returns error explaining why
- [ ] Legitimate changes require human approval

### Task 3: E2E Testing Skill (QA)
Add Playwright-based testing capability.
Definition of Done:
- [ ] skills/qa/SKILL.md with Playwright instructions
- [ ] Can run `npx playwright test` via bash
- [ ] Pass/Fail output, no ambiguous results

### Task 4: Simplify CLAUDE.md
Reduce to ≤50 lines, pointer-style not tutorial-style.
Definition of Done:
- [ ] Line count ≤50
- [ ] Points to skills/tools, doesn't explain them
- [ ] Human can read in 2 minutes

## Verification
- Criterion 1 → Run `claude --print "edit test.js"`, verify format runs
- Criterion 2 → Try editing .eslintrc, verify blocked with error
- Criterion 3 → Run `/qa` skill test against a simple page
- Criterion 4 → `wc -l CLAUDE.md` returns ≤50

## Rollback Plan
1. `git revert HEAD~1` to undo hook changes
2. Restore CLAUDE.md from previous commit
3. Delete qa/SKILL.md if problematic
