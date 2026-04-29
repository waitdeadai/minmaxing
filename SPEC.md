# SPEC: Agent Factory Skill

## Problem Statement
Add `/agent-factory` as a first-class minmaxing skill for creating governed Hermes agents that can operate bounded workflows, departments, or enterprise systems through reproducible contracts rather than ad hoc prompts.

## Codebase Anchors
- `.claude/skills/workflow/SKILL.md` defines the phase/gate conventions that `/agent-factory` must mirror.
- `.claude/skills/verify/SKILL.md` defines independent evidence expectations and verification metadata language.
- `.claude/skills/introspect/SKILL.md` defines hard-gate self-audit behavior.
- `README.md`, `CLAUDE.md`, `AGENTS.md`, and `scripts/start-session.sh` expose the public/operator skill count and command list.
- `scripts/test-harness.sh` statically enforces repo-level harness contracts.
- `hermes-factory.taste.md` and `hermes-registry.md` are new Agent Factory truth surfaces.

## Success Criteria
- [ ] `.claude/skills/agent-factory/SKILL.md` exists and defines the complete Agent Factory phase sequence.
- [ ] `/agent-factory` includes the 12 Hermes intent intake questions verbatim.
- [ ] `/agent-factory` requires taste alignment, spec-first generation, deep research, hard-gate introspection, independent verification, registry closeout, compaction-safe state, memory-coherent seeds, and a tested kill switch.
- [ ] `/agent-factory` explicitly behaves as a workflow on itself with an `AGENT_FACTORY_ARTIFACT`, compaction-resume guidance, research sufficiency gate, and adversarial stress cases.
- [ ] `hermes-factory.taste.md` exists as the secondary taste contract for Hermes agent creation.
- [ ] `hermes-registry.md` exists with a markdown schema supporting active, experimental, paused, and deprecated agents.
- [ ] Public/operator docs and session startup count `/agent-factory` as the 21st skill.
- [ ] `scripts/test-harness.sh` includes a static contract test for `/agent-factory`.
- [ ] `scripts/agent-factory-smoke.sh` stress-tests the Agent Factory contract and is called by `scripts/test-harness.sh`.
- [ ] `AGENT_FACTORY_AUDIT_AND_BLUEPRINT.md` records the requested minmaxing audit, REVCLI audit, Agent Factory design, registry schema, first Hermes blueprint, failure catalog, and constraint trace.
- [ ] Verification commands pass or any blocker is reported with concrete evidence.

## Scope
### In Scope
- Add the `/agent-factory` skill file.
- Add the root Hermes factory taste and registry schema files.
- Update docs and startup/test scripts for 21 skills.
- Add static harness coverage and a dedicated smoke script for Agent Factory invariants.
- Add a durable audit/design/blueprint artifact for the operator.

### Out of Scope
- Generating or deploying a concrete Hermes agent directory in this change.
- Editing the local private `REVCLI` repository.
- Changing Claude Code, Codex, MiniMax, or MCP authentication.
- Reworking the existing `/workflow` implementation.

## Surgical Diff Discipline
- Smallest sufficient implementation: add the new skill, truth surfaces, docs count, and static test.
- No speculative abstractions: do not introduce a new runtime, database schema, or agent orchestration engine.
- No drive-by refactors: preserve existing skill behavior and only update references needed for `/agent-factory`.
- Changed-line trace: every changed file maps to a success criterion above.

## Implementation Plan
1. Create `.claude/skills/agent-factory/SKILL.md` with the complete production-grade workflow.
2. Create `hermes-factory.taste.md` and `hermes-registry.md`.
3. Update `README.md`, `CLAUDE.md`, `AGENTS.md`, and `scripts/start-session.sh` from 20 to 21 skills and include `/agent-factory`.
4. Add `scripts/test-harness.sh` static coverage and `scripts/agent-factory-smoke.sh` for Agent Factory.
5. Write `AGENT_FACTORY_AUDIT_AND_BLUEPRINT.md` with the requested audit and Hermes blueprint.
6. Update README with the production-ready Agent Factory model.
7. Run shell syntax, harness, skill-count, smoke, and diff checks.

## Verification
- `bash -n scripts/start-session.sh`
- `bash -n scripts/test-harness.sh`
- `bash -n scripts/agent-factory-smoke.sh`
- `bash scripts/agent-factory-smoke.sh`
- `bash scripts/test-harness.sh`
- `find .claude/skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l`
- `git diff --check`

## Rollback Plan
- Remove `.claude/skills/agent-factory/`, `hermes-factory.taste.md`, and `hermes-registry.md`.
- Revert docs and scripts from 21 skills to the prior count.
- Restore the previous active `SPEC.md` from `.taste/specs/` if needed.
