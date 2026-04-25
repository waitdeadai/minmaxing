# SPEC: Governed Autonomy Messaging And Harness Truth Surfaces

## Problem Statement
minmaxing has a strong harness story, but the public messaging and a few repo surfaces still overclaim or drift from the current implementation. The project should position itself around governed Claude Code autonomy: delegate execution, keep human judgment, and require evidence before trusting the result.

The harness must make that angle credible by correcting stale counts, tightening memory and verifier claims, clarifying permission posture, and updating public copy without implying magical or fully hands-off autonomy.

## Codebase Anchors
- `README.md` is the primary public harness contract.
- `CLAUDE.md` and `AGENTS.md` are operator-facing harness contracts.
- `scripts/start-session.sh` prints setup/session truth and currently has stale skill/rule counts.
- `scripts/memory.sh` and `scripts/memory-auto.sh` define memory durability and fallback behavior.
- `.claude/skills/workflow/SKILL.md` defines the workflow artifact and governed execution path.
- `.claude/skills/verify/SKILL.md` defines verification behavior.
- `.claude/settings.json` is the fast trusted-local default profile.
- `/home/fer/Documents/minmaxing-dev-site` is the separate public site repo and must stay separate from harness internals.

## Success Criteria
- [ ] `scripts/start-session.sh` reports the tested 19-skill / 6+-rule contract and lists current core skills.
- [ ] Memory messaging is changed from absolute "remembers everything" language to durable, layered, best-effort memory with visible health status.
- [ ] `scripts/memory.sh health` reports `healthy`, `degraded`, or `disabled` with concrete evidence about flat files and SQLite availability.
- [ ] Verification messaging no longer claims a guaranteed separate AI unless isolated execution metadata exists; it describes an independent verification pass against `SPEC.md`.
- [ ] `/workflow` artifact requirements include verification metadata fields that can prove executor/verifier isolation when available.
- [ ] Permission copy frames `bypassPermissions` as a trusted-local fast profile and documents stricter team-safe options.
- [ ] README/site copy uses the governed-autonomy angle: delegate execution, keep judgment, require evidence.
- [ ] Public claims avoid unsupported absolutes like "every claim", "everything remembered", and "not the same AI" unless backed by machine-verifiable evidence.
- [ ] Harness tests enforce the new truth surfaces.

## Scope
### In Scope
- Update harness docs and scripts.
- Add a memory health command.
- Add a team-safe settings example if useful.
- Update the separate site copy and verification tokens.
- Run harness and site verification.

### Out of Scope
- Replacing the Claude Code runtime.
- Building a full benchmark suite for autonomous workflow effectiveness.
- Changing the shared `.claude/settings.json` default unless a concrete compatibility need appears.
- Pushing changes unless requested after verification.

## Implementation Plan
1. Update `scripts/start-session.sh` to report 19 skills, 6+ rules, memory health, and current skill list.
2. Add `memory health` to `scripts/memory.sh` and wire it into `start-session.sh`.
3. Add a `.claude/settings.team-safe.example.json` profile for stricter team usage.
4. Tighten `/verify` and `/workflow` language around independent verification and metadata.
5. Update README/CLAUDE/AGENTS copy around governed autonomy, memory, permissions, and evidence.
6. Update the separate site home/workflow/community copy and `llms` briefs with the new angle.
7. Extend tests to catch stale counts, memory health, team-safe profile, and overclaim drift.

## Verification
- `bash -n scripts/start-session.sh`
- `bash -n scripts/memory.sh`
- `bash -n scripts/test-harness.sh`
- `bash -n scripts/workflow-smoke.sh`
- `bash scripts/test-harness.sh`
- Site repo: `npm test`
- Site repo: route smoke / mobile overflow / Lighthouse if site copy changes materially.

## Rollback Plan
- Revert the documentation/script changes and restore the previous site copy if the new contract fails tests or weakens the public story.
