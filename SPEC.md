# SPEC: Surgical Diff Discipline

## Problem Statement
minmaxing already forces research, `SPEC.md`, introspection, and verification, but it should make one more failure mode explicit: agents often overbuild, refactor adjacent code, or modify lines that do not trace back to the requested outcome.

Add a harness-level surgical-diff discipline so plans prefer the smallest sufficient implementation and closeout checks verify every meaningful changed line is justified by the active spec.

## Codebase Anchors
- `.claude/skills/workflow/SKILL.md` owns the central inline lifecycle and pre-closeout gate.
- `.claude/skills/autoplan/SKILL.md` owns scope challenge and spec generation guidance.
- `.claude/skills/introspect/SKILL.md` owns self-audit prompts for plan and implementation confidence.
- `.claude/skills/review/SKILL.md` owns review language and blocker classification.
- `README.md`, `CLAUDE.md`, and `AGENTS.md` are public/operator contracts.
- `scripts/test-harness.sh` enforces repo-contract language.
- `/home/fer/Documents/minmaxing-dev-site` is the separate public site repo that should reflect the value prop when docs change.

## Success Criteria
- [ ] `/workflow` requires a surgical diff check during planning, execution, post-implementation introspection, verification, and closeout.
- [ ] `/autoplan` requires the smallest sufficient implementation and blocks speculative abstractions or vague success criteria before writing `SPEC.md`.
- [ ] `/introspect` names drive-by refactors, speculative abstractions, and changed-line trace gaps as self-audit risks.
- [ ] `/review` treats unexplained scope creep, drive-by refactors, and missing changed-line trace as review findings.
- [ ] README, CLAUDE, and AGENTS document the harness value: vague requests become verifiable contracts and diffs stay tied to the spec.
- [ ] `scripts/test-harness.sh` has a static contract test for `changed-line trace`, `no drive-by refactors`, `no speculative abstractions`, and `smallest sufficient implementation`.
- [ ] The separate site repo reflects the same public value proposition without adding harness files to the site or site files to the harness.
- [ ] Harness tests pass and any site verification affected by the page copy passes.

## Scope
### In Scope
- Integrate surgical-diff and simplicity-first language into existing skills and docs.
- Add static harness coverage so the behavior does not silently drift.
- Update public site copy/verification in the separate site repo if necessary.

### Out of Scope
- Adding a new `/karpathy` command or changing the skill count.
- Copying the external repo wholesale.
- Changing runtime model configuration or MiniMax MCP setup.
- Deploying the site unless a configured remote/deployment target exists.

## Implementation Plan
1. Update workflow planning/execution/verification contracts with a named surgical diff check.
2. Update autoplan, introspect, and review contracts with smallest-sufficient and changed-line trace language.
3. Update public/operator docs to explain the new discipline as part of governed execution.
4. Add a harness static contract test for the new phrases.
5. Update the separate site copy and site verification tokens if needed.
6. Run syntax, harness, and site checks; then commit and push repos with configured remotes.

## Verification
- `bash -n scripts/test-harness.sh`
- `bash scripts/test-harness.sh`
- `git diff --check`
- Site repo: `npm test`
- Site repo: `git diff --check`
- Confirm remote availability before pushing each repo.

## Rollback Plan
- Revert the skill/doc/test copy changes.
- Restore the previous public site copy if changed.
- Leave the archived digestflow spec untouched.
