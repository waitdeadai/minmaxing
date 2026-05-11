# SPEC: /leveragepath — governed leverage-path skill

## Problem Statement

Devs building products in `/minmaxing` consistently miss high-leverage
distribution and positioning opportunities because (a) they do not see the
full surface of available channels, (b) they conflate auto-by-Claude-Code
work with manual operator work, (c) they forget that some moves are
time-sensitive while others are evergreen, and (d) they sometimes have
unrecognized moats or blind spots that only show up under deep research.

A live example: in a single 2026-05-11 session a dev publicly distributed an
open-source Claude Code hook suite. The "obvious" channels (Reddit, HN,
LinkedIn) were considered. The Anthropic Discord with 95k members — the
single highest-leverage channel — was missed until research was run
explicitly. The skill exists to make that research and ranking systematic.

## Success Criteria (verifiable)

- [ ] `.claude/skills/leveragepath/SKILL.md` exists with required YAML
  frontmatter (name, description, argument-hint, disable-model-invocation).
- [ ] CLAUDE.md `Skills (invoke with /<skill>)` table includes a
  `/leveragepath` row.
- [ ] CLAUDE.md `Default Behavior` section mentions when `/leveragepath`
  should fire.
- [ ] `bash scripts/harness-capability-map.sh --check` either passes or
  the regenerated map is committed alongside the skill in the same PR.
- [ ] The skill body documents three modes: `scan` (default, research +
  ranked move list), `apply <move_id>` (execute one autoable move),
  `kernel-propose` (propose taste.md / taste.vision changes when research
  surfaces moats or blind spots).
- [ ] The skill body specifies the artifact path
  `.taste/leveragepath/<run_id>/leveragepath.md` and the required fields
  per move (RICE score with R/I/C/E components, category tag
  auto/manual/community/kernel, reversibility, time-sensitivity, blocker
  if any, next concrete step).
- [ ] The skill body cites RICE as the scoring frame (research-validated
  as the 2026 standard prioritization framework — Canny 2026, ProductLift
  Feb-2026 comparison) and acknowledges it as one layer alongside
  categorization, time-sensitivity, and reversibility.
- [ ] The skill body integrates the existing `/deepresearch` skill as the
  research engine, `/defineicp` as the kernel-mutation contract for
  `kernel-propose` mode, and `/introspect` as the pre-write gate.

## Scope

In:
- New skill file `.claude/skills/leveragepath/SKILL.md` (one file, no
  sub-scripts in v1).
- CLAUDE.md updates: skills table row + one paragraph in `Default
  Behavior` + one rule line.
- Regenerate `docs/harness-capability-map.md` and `.json`.
- Single commit on `/tmp/minmax-fresh/minmaxing` main.

Out (deferred to v2):
- Helper scripts (`scripts/leverage-scan.sh`, etc.).
- A static eval harness for the skill.
- Auto-execution of identified moves.
- A separate `/leveragepath` apply-mode artifact contract; v1 documents
  apply mode but the operator triggers each move manually.
- The visualization or demo lane integration.
- Touching `taste.md` or `taste.vision` as part of skill installation
  (the skill only proposes kernel changes when invoked in
  `kernel-propose` mode by the operator).

## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local supervisor (single bash session)
- Capacity evidence: not required for single-skill addition
- Effective lanes: 1
- Critical path: SPEC -> SKILL.md -> CLAUDE.md edits -> capability map regen
  -> verify -> commit -> push
- Agent wall-clock: optimistic 15m / likely 30m / pessimistic 50m
- Agent-hours: ~30m
- Human touch time: 0 (operator authorized full execution via
  /opusworkflow)
- Calendar blockers: none
- Confidence: high (close analog `/defineicp`, well-established pattern)

## Implementation Plan

### Task 1: Write SKILL.md
Definition of Done:
- [ ] YAML frontmatter matches the convention used by `/defineicp` and
  `/deepretaste`.
- [ ] Body has sections: contract, invocation modes (scan / apply /
  kernel-propose), inputs read, output artifact, RICE+categorization
  framework, kernel-mutation gate, integration with sibling skills, and
  anti-patterns.
- [ ] Cites at least one external source (RICE framework canonical link
  from research conducted today).

### Task 2: Update CLAUDE.md
Definition of Done:
- [ ] One row added to skills table with `/leveragepath` and a 1-sentence
  description.
- [ ] One paragraph added to `Default Behavior` documenting the trigger
  and routing.
- [ ] No regression: existing entries stay byte-for-byte identical.

### Task 3: Regenerate capability map
Definition of Done:
- [ ] `bash scripts/harness-capability-map.sh` runs and writes new
  `docs/harness-capability-map.md` + `.json` that include the new skill.
- [ ] `bash scripts/harness-capability-map.sh --check` passes.

### Task 4: Verify
Definition of Done:
- [ ] `ls .claude/skills/leveragepath/SKILL.md` succeeds.
- [ ] `grep '/leveragepath' CLAUDE.md` returns at least 2 matches.
- [ ] Capability map check exits 0.

### Task 5: Commit + push
Definition of Done:
- [ ] Single commit, `feat(skill): /leveragepath — governed leverage-path
  scan + apply + kernel-propose`.
- [ ] Push to origin/main.

## Verification
- Skill file exists -> Task 4.
- CLAUDE.md updated -> Task 4 grep.
- Capability map updated -> Task 4 script check.
- Commit shipped -> Task 5 git log.

## Rollback Plan
1. `git revert <commit_hash>` from main.
2. `git push origin main` to deploy the revert.
3. The skill is removed; no other system depends on it (it is greenfield).
