# SPEC: `/icpweek` Product Week Simulation Skill

## Problem Statement

The user's master prompt is a valuable product stress-test, but as a pasted prompt it is easy to lose the repo's research, parallelism, source-ledger, and hard-gate discipline. The harness needs a first-class `/icpweek` Claude Code skill that turns the prompt into a reusable, manual, research-backed workflow for simulating one full week of real-world product usage by an ideal customer, then producing a brutally honest product/UX/technical diagnosis.

## Success Criteria

- [x] `.claude/skills/icpweek/SKILL.md` exists with Claude Code skill frontmatter, `name: icpweek`, a specific description, an argument hint, and `disable-model-invocation: true`.
- [x] The skill preserves the source prompt's three evaluation lenses: demanding ideal user, CTO / Technical CEO, and senior product engineer.
- [x] The skill requires a Monday-Sunday simulation with the ten daily dimensions from the source prompt.
- [x] The skill requires the final A-J diagnosis from the source prompt.
- [x] The skill uses the repo's effectiveness-first `/deepresearch` discipline: collaborative research plan, effective budget, search -> read -> refine loop, source ledger, conflict handling, and follow-up before freezing recommendations.
- [x] The skill uses parallel agents or packets only when distinct lenses, research branches, or review packets materially improve the output, and treats capacity as a ceiling rather than a quota.
- [x] The skill keeps the main agent as orchestrator and treats worker/subagent findings as claims until synthesized and checked.
- [x] The skill blocks superficial reviews, invented product facts, unmarked assumptions, secret reads, and implementation unless the user explicitly asks for file changes.
- [x] Harness self-lookup discovers `/icpweek` under the research route group after regenerating `docs/harness-capability-map.md` and `docs/harness-capability-map.json`.
- [x] README, CLAUDE.md, AGENTS.md, `scripts/start-session.sh`, and `scripts/test-harness.sh` reflect the 30-skill contract where they maintain manual skill counts or lists.
- [x] Static verification passes with capability-map freshness, static harness, release gate, and `git diff --check`.

## Research Brief

### Collaborative Research Plan

- Deliverable: a project-scoped Claude Code skill that behaves like `/icpweek` and improves the source prompt with Claude Code skill best practices.
- Branches:
  - Repo convention branch: current minmaxing skill locations, discovery, counts, and release gates.
  - Claude Code docs branch: current official skill and slash-command behavior.
  - Skill-quality branch: concise skill design, progressive disclosure, manual invocation, and parallel/subagent use.
- Stop condition: enough evidence to implement the smallest durable skill plus the discovery/docs updates required by the repo's own static checks.

### Source Ledger

- Cited:
  - `docs/harness-capability-map.md` and `scripts/harness-capability-map.sh`: local source of truth for skill discovery and route groups.
  - `.claude/skills/deepresearch/SKILL.md`: local source of truth for research discipline.
  - `.claude/skills/parallel/SKILL.md`: local source of truth for capacity-aware parallel packets.
  - `https://code.claude.com/docs/en/skills`: current Claude Code skill location, frontmatter, invocation, arguments, and support-file behavior.
  - `https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices`: current official skill authoring guidance.
- Reviewed but not cited:
  - `https://code.claude.com/docs/en/sub-agents`: confirms bounded subagent use and context isolation, but the local `/parallel` contract is the stronger repo authority.
  - `https://code.claude.com/docs/en/hooks`: no hook needed for this first slice.
- Conflicts:
  - Older slash-command docs and newer skills docs differ in emphasis. Current Claude Code docs state custom commands have merged into skills and that skills are recommended for supporting files. This spec follows the current skills path.

## Scope

### In Scope

- Add the `/icpweek` skill contract.
- Register `/icpweek` in the generated harness capability map as a research skill.
- Update manual skill counts and lists from 29 to 30.
- Regenerate generated capability-map artifacts.
- Run static verification.

### Out Of Scope

- Add a custom smoke script for `/icpweek`.
- Add eval fixtures for subjective product diagnosis quality.
- Implement product-specific reports for a real product.
- Edit `.env`, credentials, customer artifacts, or unrelated Hermes registry changes.
- Create browser automation, CRM integrations, or product changes from the diagnosis.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock.
- Execution topology: subagents for repo/docs research, local implementation, local verification.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` reported `recommended_ceiling=10`, `codex_max_threads=10`, `hardware_class=workstation`, `default_substrate=subagents`.
- Effective lanes: 2 research lanes plus parent implementation. The task benefits from distinct repo and official-doc research, but not from filling all 10 lanes.
- Critical path: repo/docs research -> pre-plan introspection -> SPEC -> skill and docs patch -> capability-map regeneration -> static verification -> closeout.
- Agent wall-clock: optimistic 25 minutes / likely 45 minutes / pessimistic 75 minutes.
- Agent-hours: approximately 1.5-2.5 across research, implementation, and verification.
- Human touch time: none expected for this static skill addition.
- Calendar blockers: none.
- Confidence: medium-high; downgrade reason is that subjective report quality is best evaluated through later real `/icpweek` usage, not a static smoke alone.

## Implementation Plan

### Task 1: Add Skill Contract

Definition of Done:

- [x] Create `.claude/skills/icpweek/SKILL.md`.
- [x] Keep `SKILL.md` concise and manual-only.
- [x] Include intake, research, parallel packet, daily simulation, final diagnosis, output format, and anti-pattern gates.

### Task 2: Wire Discovery And Manual Docs

Definition of Done:

- [x] Add `icpweek` to `ROUTE_GROUPS` in `scripts/harness-capability-map.sh`.
- [x] Update README, CLAUDE.md, AGENTS.md, `scripts/start-session.sh`, and `scripts/test-harness.sh`.
- [x] Regenerate `docs/harness-capability-map.md` and `.json`.

### Task 3: Verify

Definition of Done:

- [x] `bash scripts/harness-capability-map.sh --check --json` passes.
- [x] `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh` passes.
- [x] `bash scripts/release-check.sh --static-only` passes.
- [x] `git diff --check` passes.
- [x] `hermes-registry.md` remains untouched by this change.

## Verification

- Inspect `.claude/skills/icpweek/SKILL.md` for prompt preservation and Claude Code skill frontmatter.
- Run generated map freshness check.
- Run static harness.
- Run static release gate.
- Run `git diff --check`.
- Review `git diff --stat` and `git status --short` to confirm scope.

### Verified 2026-05-06

- `bash scripts/harness-capability-map.sh --check --json`: pass (`skills=30`, `/icpweek` group=`research`, `model_invocation=false`).
- First `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: failed because `scripts/visualize-smoke.sh` still expected the old `29 skills` text.
- Fixed `scripts/visualize-smoke.sh` to the 30-skill baseline.
- `bash scripts/visualize-smoke.sh`: pass.
- `bash scripts/release-check.sh --static-only`: pass, including static harness summary `123 passed, 0 failed` and `git diff --check`.

## Rollback Plan

1. Remove `.claude/skills/icpweek/SKILL.md`.
2. Remove `icpweek` from `scripts/harness-capability-map.sh`.
3. Restore the manual 29-skill count/list text in README, CLAUDE.md, AGENTS.md, `scripts/start-session.sh`, and `scripts/test-harness.sh`.
4. Regenerate `docs/harness-capability-map.md` and `.json`.
5. Verify rollback with `bash scripts/harness-capability-map.sh --check --json`, `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`, `bash scripts/release-check.sh --static-only`, and `git diff --check`.
