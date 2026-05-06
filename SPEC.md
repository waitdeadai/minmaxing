# SPEC: `/deepretaste` SOTA 2026 Intent-to-Taste Bootstrap Workflow

## Problem Statement

The harness now has `/tastebootstrap` for fresh taste creation and `/defineicp`
for proposal-first ICP-to-taste evolution. The missing mode is the higher-order
workflow the user is asking for: `/deepretaste`, a SOTA-2026, research-backed,
parallel-aware command that detects the developer's product intent, defines the
right ICP or ICPs, and bootstraps or retastes `taste.md`, `taste.vision`, and a
durable ICP artifact.

The dangerous version would become a theatrical "max agents" persona generator
that overwrites the project kernel with generic market language. The useful
version is governed: it uses current-source deepresearch, capacity-bound
parallel or hive lanes, explicit claim ledgers, protected-kernel preservation,
and mutation gates that distinguish fresh bootstrap from existing-kernel
retaste.

## Success Criteria

- [ ] Add `.claude/skills/deepretaste/SKILL.md` as a manual slash skill.
- [ ] The skill must detect product intent from user prompt plus repo truth
  surfaces before choosing bootstrap, proposal, apply, or research mode.
- [ ] The skill must define primary ICP, secondary ICPs where useful, and
  anti-ICP/disqualified segments.
- [ ] The skill must use SOTA-2026 claim discipline: current sources where
  available, stable foundations labeled as such, and no "SOTA" claim without a
  source ledger.
- [ ] The skill must compute an effective parallel/hive budget from local
  capacity and independent research roles, treating max agents as a ceiling.
- [ ] Fresh repos may write `taste.md`, `taste.vision`, and an ICP artifact
  when intent is explicit enough; existing taste files require proposal-first
  behavior unless exact apply approval exists.
- [ ] Apply/bootstrap mutations must backup existing files when present, record
  hashes, update taste files as one unit, validate required sections, and
  record rollback.
- [ ] Add a no-secret static gate `scripts/deepretaste-smoke.sh --fixtures`.
- [ ] Add green/red fixtures that prove intent detection, SOTA source
  discipline, ICP completeness, parallel budget honesty, fresh bootstrap,
  proposal-first existing-kernel behavior, approval gating, and secret
  rejection.
- [ ] Register the smoke gate in the static eval pack, release gate, capability
  map, startup surface, and test harness.
- [ ] Update README, CLAUDE.md, AGENTS.md, `/workflow`, and `/metacognition` so
  `/deepretaste` is discoverable and distinct from `/tastebootstrap`,
  `/defineicp`, `/icpweek`, `/deepresearch`, and `/hive`.
- [ ] Regenerate `docs/harness-capability-map.md` and
  `docs/harness-capability-map.json`.
- [ ] Static release gates pass without reading `.env`, local Claude settings,
  MiniMax key files, private customer artifacts, or production logs.

## Research Brief

### Collaborative Research Plan

- Deliverable: a safe `/deepretaste` skill that can bootstrap or retaste a
  project kernel from intent + ICP research without destructive overwrites.
- Local branches:
  - skill/frontmatter and route discovery conventions
  - existing `/defineicp` and `/tastebootstrap` mutation semantics
  - harness eval, release, startup, and capability-map wiring
  - adversarial overwrite and fake-SOTA risks
- External branches:
  - current Claude Code skill/subagent/hook behavior
  - current or stable product discovery, ICP, JTBD, persona, and UX research
    evidence standards
- Effective research budget:
  - `scripts/parallel-capacity.sh --json` returned `recommended_ceiling=10`,
    `codex_max_threads=10`, `cores=16`, `ram_gb=32`,
    `hardware_class=workstation`, `agent_teams_available=false`.
  - Used lanes: 4 subagents plus parent synthesis and live web research. This
    uses distinct lenses, not the whole ceiling.
- Stop condition:
  - exact skill contract, static artifacts, registration surfaces, and
    verification commands are known.

### Source Ledger

- Local source surfaces:
  - `AGENTS.md`: deepresearch, hive, parallel, defineicp, tastebootstrap,
    introspect, release-check, spec lifecycle, and surgical diff rules.
  - `docs/harness-capability-map.md`: current 33-skill route map and required
    script gates.
  - `.claude/skills/defineicp/SKILL.md`: proposal-first ICP-to-taste mutation
    precedent.
  - `.claude/skills/tastebootstrap/SKILL.md`: fresh-repo kernel bootstrap
    structure.
  - `.claude/skills/deepresearch/SKILL.md`: collaborative plan,
    search-read-refine loop, source ledger, conflict handling, and effective
    parallel budget.
  - `.claude/skills/hive/SKILL.md`: queen/supervisor, blackboard, dissent, and
    evidence-backed synthesis.
  - `scripts/defineicp-smoke.sh`, `scripts/harness-eval.sh`,
    `scripts/harness-capability-map.sh`, `scripts/release-check.sh`,
    `scripts/test-harness.sh`: static gate patterns.
- External sources:
  - Claude Code skills docs:
    `https://code.claude.com/docs/en/slash-commands` confirmed project skills
    live under `.claude/skills/<name>/SKILL.md`, can be invoked directly, and
    support `disable-model-invocation: true`.
  - Claude Code subagents docs:
    `https://code.claude.com/docs/en/sub-agents` confirmed subagents can be
    model-scoped, inherit by default, and can have lifecycle hooks.
  - Claude Code hooks docs:
    `https://code.claude.com/docs/en/hooks-guide` confirmed restrictive hook
    decisions can block actions and agent hooks can verify real repo state.
  - Strategyzer Value Proposition Canvas:
    `https://www.strategyzer.com/library/the-value-proposition-canvas`
    published January 28, 2026, supports jobs-to-be-done, pains, gains, and
    product-market-fit evidence mapping.
  - Harvard Business Review JTBD:
    `https://hbr.org/2016/09/know-your-customers-jobs-to-be-done` is a stable
    foundation for centering the job customers hire a product to do.
  - Yale UX archetypes/personas:
    `https://usability.yale.edu/ux/discovery/create-user-representations/archetypes-and-personas`
    supports grounding archetypes/personas in real user research, behavior,
    goals, and pain points.
  - NN/g empathy mapping poster:
    `https://media.nngroup.com/media/articles/attachments/Empathy_Mapping_Poster1-compressed.pdf`
    supports empathy maps as qualitative-research synthesis and gap discovery.
  - NN/g UX research methods poster:
    `https://media.nngroup.com/media/articles/attachments/User_Research_Methods_A4-compressed.pdf`
    supports mixing attitudinal/behavioral and qualitative/quantitative
    methods rather than trusting what users say alone.
  - Shopify ICP guide:
    `https://www.shopify.com/blog/ideal-customer-profile` supports ICPs as
    data-driven descriptions of the customers most valuable to the business.
  - Proto-persona LLM case study:
    `https://arxiv.org/abs/2507.08594` supports GenAI-assisted product
    discovery efficiency while warning about generalization and domain
    specificity.
  - Personagram:
    `https://arxiv.org/abs/2602.06197` supports structured persona-to-product
    ideation with AI, with transparency and engagement benefits over a
    chat-only baseline.

### Reviewed But Not Cited

- Generic ICP and product-discovery blog posts were useful for vocabulary but
  downweighted behind official docs, established UX/product sources, and recent
  AI-persona research.

### Conflicts And Resolutions

- User asked for "max parallel agents or hive"; repo contracts say capacity is
  a ceiling, not a quota. Resolution: `/deepretaste` computes an effective
  budget and uses hive only when distinct roles, blackboard, dissent, and
  synthesis materially improve judgment.
- User wants bootstrap of taste and vision; existing repo kernels are protected
  surfaces. Resolution: fresh repos may be bootstrapped, but existing taste
  files default to proposal mode and require explicit apply approval.
- "SOTA 2026" can become marketing language. Resolution: the skill requires
  current-source evidence for current claims and labels stable foundations
  separately.

## Scope

### In Scope

- New `/deepretaste` skill.
- New no-secret smoke gate and fixtures.
- Eval, release, test harness, capability map, startup, and docs wiring.
- Contract for writing `taste.md`, `taste.vision`, and ICP artifacts in future
  downstream repos.

### Out Of Scope

- Running `/deepretaste` against this repo's own product and rewriting the live
  root taste files during this implementation.
- Authenticated provider calls, CRM/customer-data ingestion, private analytics,
  outreach, or production logs.
- Claiming universal SOTA or PMF proof; the skill can only report evidence
  strength and missing validation.

## Agent-Native Estimate

- Estimate type: agent-native.
- Execution topology: parent orchestrator plus 4 distinct research/review lanes.
- Capacity evidence: `recommended_ceiling=10`, `codex_max_threads=10`,
  `agent_teams_available=false`.
- Effective lanes: 4 subagents plus local implementation. Implementation is
  coupled across skill, script, fixtures, evals, docs, and generated maps, so
  final edits stay local.
- Critical path: spec -> skill -> smoke/fixtures -> eval/release/test wiring ->
  docs/startup -> capability map regeneration -> verification -> commit/push.
- Agent wall-clock: optimistic 45 minutes / likely 90 minutes / pessimistic
  3 hours.
- Agent-hours: 3-6 including research/review lanes.
- Human touch time later: 5-20 minutes to approve exact retaste apply proposals
  in downstream repos.
- Calendar blockers: none for static route implementation; external research
  quality depends on downstream product evidence.
- Confidence: medium-high for harness implementation; medium for future ICP
  quality because product/customer evidence varies.

## Implementation Plan

### Task 1: Skill Contract

- Add `/deepretaste` with phases:
  - intent detection and product-scope gate
  - taste-state detection
  - SOTA-2026 deepresearch plan
  - parallel or hive role budget
  - ICP synthesis
  - kernel bootstrap/proposal/apply
  - verification and introspection
- Require claim labels: `current-source-backed`, `stable-source-backed`,
  `repo-derived`, `user-stated`, `inference`, `assumption`, `unknown`.
- Require output artifacts under `.taste/deepretaste/{run_id}/`.

### Task 2: Static Gate

- Add `scripts/deepretaste-smoke.sh`.
- Validate:
  - skill/frontmatter/doc patterns
  - source and claim ledger discipline
  - SOTA claim policy
  - intent detection
  - ICP completeness
  - parallel/hive budget honesty
  - fresh bootstrap and existing-kernel proposal-first behavior
  - approval, backups, hashes, rollback, and secret rejection

### Task 3: Eval And Release Wiring

- Add `evals/harness/tasks/m11-deepretaste-intent-icp-bootstrap.yaml`.
- Add `evals/harness/golden/m11-deepretaste-intent-icp-bootstrap.json`.
- Register `deepretaste-smoke` in `scripts/harness-eval.sh`.
- Add the smoke to `scripts/release-check.sh`.
- Add focused assertions to `scripts/test-harness.sh`.

### Task 4: Discovery And Docs

- Add `deepretaste` to route groups, startup, README, CLAUDE.md, AGENTS.md,
  `/workflow`, and `/metacognition`.
- Update exact skill counts from 33 to 34.
- Regenerate generated capability map files.

## Verification Plan

- `bash scripts/deepretaste-smoke.sh --fixtures`
- `bash -n scripts/*.sh`
- `bash scripts/harness-capability-map.sh --check --json`
- `bash scripts/harness-eval.sh --json`
- `bash scripts/artifact-lint.sh --fixtures`
- `bash scripts/security-smoke.sh`
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

## Introspection: Pre-Plan

- Likely mistake: overbuild by merging `/tastebootstrap`, `/defineicp`, and
  `/hiveworkflow` into a second full workflow engine. Mitigation: make
  `/deepretaste` a kernel-discovery/bootstrap skill with bounded outputs.
- Likely mistake: fake "SOTA 2026" confidence. Mitigation: require current
  source ledger and label stable foundations separately.
- Likely mistake: destructive taste overwrite. Mitigation: fresh bootstrap only
  when files are absent; existing files require proposal-first or explicit
  apply approval with backups.
- Likely mistake: max-agent theater. Mitigation: static fixtures reject budgets
  above ceilings or unsupported lane counts.

## Verified 2026-05-06

- `bash scripts/deepretaste-smoke.sh --fixtures`: pass.
- `bash -n scripts/deepretaste-smoke.sh scripts/harness-eval.sh scripts/harness-capability-map.sh scripts/release-check.sh scripts/test-harness.sh scripts/start-session.sh scripts/visualize-smoke.sh`: pass.
- `bash scripts/harness-capability-map.sh --check --json`: pass; generated map reports `skills=34`, `scripts=54`, `eval_tasks=22`, and includes `/deepretaste`.
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`, `0 mismatches`).
- `bash scripts/artifact-lint.sh --fixtures`: pass (`7 green`, `21 red`).
- `bash scripts/security-smoke.sh`: pass.
- `git diff --check`: pass.
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`137 passed`, `0 failed`).
- `bash scripts/release-check.sh --static-only`: pass (`137 passed`, `0 failed`; static-only release gate passed).

## Introspection: Pre-Closeout

- Likely mistake: `/deepretaste` could still be read as a replacement for
  `/deepresearch`. Mitigation: skill, CLAUDE.md, AGENTS.md, and workflow
  routing explicitly state that `/deepresearch` remains general-purpose and
  `/deepretaste` consumes it only for taste-driving evidence.
- Likely mistake: `/deepretaste` could bypass `/defineicp` apply safety.
  Mitigation: skill contract and smoke fixtures require `/defineicp` semantics
  for existing-kernel mutation and reject destructive overwrite, vague
  approval, ambiguous intent apply, worker-summary-as-truth, and route
  confusion.
- Remaining verification risk: none known after the static release gate; runtime
  authenticated Claude checks remain explicit opt-in and were not needed for
  this no-secret harness route.
