# SPEC: `/defineicp` ICP-to-Taste Evolution Workflow

## Problem Statement

The harness already has `taste.md` and `taste.vision` as the project operating
kernel, and `/icpweek` can stress-test a product from an ideal-user lens. What is
missing is a governed workflow that defines the real ICP or ICPs for the current
product and feeds those findings back into the kernel so future product work is
tailored to the right customer profile.

The dangerous version of this feature would overwrite `taste.md` and
`taste.vision` with market persona fluff. The useful version is
`/defineicp`: a deepresearch-backed ICP discovery and taste-evolution command
that preserves the protected kernel, produces a source-backed ICP artifact, then
drafts and optionally applies a rollbackable rewrite of both taste files.

## Success Criteria

- [x] Add `.claude/skills/defineicp/SKILL.md` as a manual slash skill.
- [x] The skill must use the repo's `/deepresearch` discipline for market,
  customer, competitor, workflow, buying, or current-behavior claims.
- [x] The skill must infer or intake product scope before research: repo-level
  product, feature, customer vertical, or target distribution.
- [x] The skill must define primary ICP, secondary ICPs where warranted, and
  anti-ICP/disqualified segments.
- [x] The skill must default to proposal mode: it writes an ICP artifact and
  taste patch proposal, but does not mutate `taste.md` or `taste.vision`
  without explicit apply approval.
- [x] Apply mode must preserve pre-change hashes, backup both taste files,
  update both files as one unit, and validate semantic kernel preservation.
- [x] Add a no-secret static gate `scripts/defineicp-smoke.sh --fixtures`.
- [x] Add green/red fixtures that prove proposal-first behavior, source-ledger
  discipline, protected-kernel preservation, apply approval, and secret
  rejection.
- [x] Register the smoke gate in the static eval pack, release gate, capability
  map, startup surface, and test harness.
- [x] Update README, CLAUDE.md, and AGENTS.md so `/defineicp` is visible and
  distinct from `/icpweek` and `/tastebootstrap`.
- [x] Regenerate `docs/harness-capability-map.md` and
  `docs/harness-capability-map.json`.
- [x] Static release gates pass without reading `.env`, local Claude settings,
  MiniMax key files, private customer artifacts, or production logs.

## Research Brief

### Collaborative Research Plan

- Deliverable: a safe `/defineicp` route that can define ICPs and evolve the
  taste kernel without destructive or evidence-free rewrites.
- Local branches:
  - skill/frontmatter conventions and route discovery
  - taste creation, validation, and evolution contracts
  - harness registration, eval, release, and docs surfaces
  - adversarial overwrite and semantic-loss risks
- External branches:
  - current Claude Code skill and settings behavior
  - stable ICP/persona/JTBD principles that justify the output structure
- Effective research budget:
  - capacity evidence: `scripts/parallel-capacity.sh --json` returned
    `recommended_ceiling=10`, `codex_max_threads=10`, `cores=16`,
    `ram_gb=32`, `hardware_class=workstation`.
  - used lanes: 5 distinct lanes plus parent synthesis, not the full ceiling.
- Stop condition:
  - identify exact files to edit, safety contract for taste mutation, static
    fixtures, and release gates.

### Source Ledger

- Local source surfaces:
  - `AGENTS.md`: deepresearch, `/icpweek`, `/introspect`, spec lifecycle,
    release-check, surgical diff, and taste/kernel rules.
  - `.claude/skills/icpweek/SKILL.md`: closest ICP-style research route.
  - `.claude/skills/deepresearch/SKILL.md`: collaborative plan, iterative
    search/read/refine, source ledger, conflict handling, and introspection.
  - `.claude/skills/tastebootstrap/SKILL.md`: fresh taste creation contract.
  - `.claude/skills/align/SKILL.md`: taste evolution precedent and approval
    boundary.
  - `.claude/skills/workflow/SKILL.md`: taste gate and route lifecycle.
  - `scripts/taste.sh`: non-overwrite init behavior and required taste
    structure.
  - `scripts/harness-capability-map.sh`, `scripts/harness-eval.sh`,
    `scripts/release-check.sh`, `scripts/test-harness.sh`: registration,
    eval, release, and regression surfaces.
- External sources:
  - Claude Code skills docs: `https://code.claude.com/docs/en/skills`
    confirmed project skills live under `.claude/skills/<name>/SKILL.md`,
    can be invoked as `/name`, and `disable-model-invocation: true` makes a
    workflow manual.
  - Claude Code settings docs: `https://code.claude.com/docs/en/settings`
    confirmed shared project settings and ignored local settings boundaries.
  - Claude Code hooks docs: `https://code.claude.com/docs/en/hooks`
    confirmed hook decisions can block actions, reinforcing that safety gates
    should be deterministic when needed.
  - Yale UX archetypes/personas:
    `https://usability.yale.edu/ux/discovery/create-user-representations/archetypes-and-personas`
    confirmed personas/archetypes should be grounded in user research and
    focus on behavior, goals, and pain points.
  - Shopify ICP guide:
    `https://www.shopify.com/blog/ideal-customer-profile` confirmed ICPs
    should be data-driven, focus on highest-value customers, include buyer
    attributes, pains, budget, technology, goals, and can be multiple by
    product/service.
  - Harvard Business Review JTBD article:
    `https://hbr.org/2016/09/know-your-customers-jobs-to-be-done` supported
    using the job customers are trying to accomplish as the center of product
    definition.

### Reviewed But Not Cited

- Secondary ICP blog posts and Reddit discussions were useful for vocabulary
  but downweighted because official/product-neutral sources and repo contracts
  were stronger.

### Conflicts And Resolutions

- User requested rewrite of `taste.md` and `taste.vision`; repo contracts treat
  those files as protected kernel surfaces. Resolution: `/defineicp` may apply
  rewrites, but default mode is proposal-first and apply requires explicit
  approval, backups, changed-line trace, and validation.
- ICP/persona sources sometimes emphasize sales/marketing; this harness needs
  product behavior and engineering taste. Resolution: the skill maps ICP
  findings into product experience, contracts, operations, verification, and
  non-goals, not just positioning copy.

## Scope

### In Scope

- New `/defineicp` skill and no-secret smoke gate.
- Static fixtures for valid and invalid ICP/taste-evolution artifacts.
- Eval, release, test harness, capability map, startup, and docs wiring.
- A guarded contract for rewriting `taste.md` and `taste.vision` when invoked
  later by an operator with explicit apply approval.

### Out Of Scope

- Running `/defineicp` against this repo's own ICP and rewriting the live
  `taste.md` / `taste.vision` during this implementation.
- Authenticated provider calls, customer-data imports, CRM scraping, outreach,
  analytics ingestion, or production-log access.
- Guaranteeing that market research is true when external sources are absent or
  blocked. The skill must label assumptions and downgrade confidence.

## Agent-Native Estimate

- Estimate type: agent-native.
- Execution topology: parent orchestrator plus bounded read-only research lanes.
- Capacity evidence: `recommended_ceiling=10`, `codex_max_threads=10`,
  `agent_teams_available=false`.
- Effective lanes: 5 research/review lanes plus one local implementation lane.
  Edits are coupled across skill, script, fixtures, evals, docs, and generated
  maps, so implementation stays local to avoid integration churn.
- Critical path: spec -> skill -> smoke/fixtures -> eval/release/test wiring ->
  docs/startup -> capability map regeneration -> static verification -> commit
  and push.
- Agent wall-clock: optimistic 1 hour / likely 2 hours / pessimistic 4 hours.
- Agent-hours: 3-6 including research/review lanes.
- Human touch time later: 5-20 minutes to approve an actual ICP-to-taste apply
  patch in a downstream repo.
- Calendar blockers: none for static route implementation; external market
  research can be blocked later by source availability.
- Confidence: medium-high for static harness implementation, medium for future
  ICP quality because each product's evidence quality will vary.

## Implementation Plan

### Task 1: Skill Contract

- Add `/defineicp` with phases:
  - taste gate and product scope
  - ICP intake
  - deepresearch plan
  - parallel lenses
  - ICP synthesis
  - taste evolution proposal
  - optional apply
  - verification and introspection
- Require claim labels: `source-backed`, `repo-derived`, `user-stated`,
  `inference`, `assumption`, `unknown`.
- Require protected-kernel preservation:
  - SPEC-first
  - research-first
  - evidence-backed verification
  - explicit contracts
  - single-owner validated state
  - structured/explainable errors
  - observability
  - least privilege
  - rollbackability
  - separate verifier
  - no silent destructive behavior

### Task 2: Static Gate

- Add `scripts/defineicp-smoke.sh`.
- Validate:
  - skill/frontmatter/doc patterns
  - docs/route visibility
  - fixture artifacts
  - positive proposal/apply artifacts
  - negative artifacts for missing source ledger, generic persona fluff,
    kernel loss, apply without approval, failed verification positive closeout,
    and secret-bearing artifacts.

### Task 3: Eval And Release Wiring

- Add `evals/harness/tasks/m10-defineicp-taste-evolution.yaml`.
- Add `evals/harness/golden/m10-defineicp-taste-evolution.json`.
- Register `defineicp-smoke` in `scripts/harness-eval.sh`.
- Add the smoke to `scripts/release-check.sh`.
- Add focused assertions to `scripts/test-harness.sh`.

### Task 4: Discovery And Docs

- Add `defineicp` to the capability-map route group and script owner maps.
- Update README, CLAUDE.md, AGENTS.md, and `scripts/start-session.sh`.
- Update skill counts from 32 to 33 where exact text is asserted.
- Regenerate generated capability map files.

## Verification Plan

- `bash -n scripts/*.sh`
- `bash scripts/defineicp-smoke.sh --fixtures`
- `bash scripts/harness-capability-map.sh --check --json`
- `bash scripts/harness-eval.sh --json`
- `bash scripts/artifact-lint.sh --fixtures`
- `bash scripts/security-smoke.sh`
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

## Verified 2026-05-06

- `bash -n scripts/defineicp-smoke.sh scripts/harness-eval.sh scripts/harness-capability-map.sh scripts/release-check.sh scripts/test-harness.sh scripts/start-session.sh scripts/visualize-smoke.sh`: pass.
- `bash scripts/defineicp-smoke.sh --fixtures`: pass.
- `bash scripts/harness-capability-map.sh --check --json`: pass; generated map reports `skills=33`, `scripts=53`, `eval_tasks=21`, and includes `/defineicp`.
- `bash scripts/artifact-lint.sh --fixtures`: pass (`7 green`, `21 red`).
- `bash scripts/security-smoke.sh`: pass.
- `bash scripts/harness-eval.sh --json`: pass (`21 tasks`, `18 gates`, `0 mismatches`).
- `git diff --check`: pass.
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`134 passed`, `0 failed`; runtime Claude integration intentionally skipped).
- `bash scripts/release-check.sh --static-only`: pass, including `git diff --check`.

No runtime provider smoke, customer-data import, `.env` read, local Claude
settings read, or actual live `taste.md` / `taste.vision` ICP rewrite was
performed.

## Introspection Pre-Plan

- Likely mistake: honoring the user's "rewrite taste" wording too literally and
  creating a destructive overwrite path. Mitigation: proposal-first default,
  apply-only with explicit approval, backups, hashes, and validation.
- Likely mistake: duplicating `/icpweek`. Mitigation: `/defineicp` owns ICP
  definition and taste evolution; `/icpweek` owns seven-day product stress
  simulation.
- Likely mistake: turning ICP into a marketing persona instead of product taste.
  Mitigation: require JTBD, buying context, disqualifiers, proof needed, and
  mapping into experience, contracts, system behavior, and non-goals.
- Likely mistake: relying on structural tests only. Mitigation: smoke fixtures
  reject semantic kernel loss and evidence-free ICP claims.
- Missing verification before implementation: docs researcher lane may return
  additional Claude Code source details later, but parent web research already
  verified the needed official skill/settings behavior.
- Blocker decision: PASS.

## Introspection Post-Implementation

- Checked destructive-overwrite risk: `/defineicp` defaults to proposal mode and
  requires explicit approval, backups, hashes, changed-line trace, validation,
  and rollback evidence before `ICP_APPLIED`.
- Checked semantic kernel preservation: the skill and smoke fixtures require
  protected invariants for spec-first, research-first, verification, explicit
  contracts, state boundaries, errors, observability, least privilege, rollback,
  separate verifier, and no silent destructive behavior.
- Checked `/icpweek` overlap: `/defineicp` owns ICP definition and taste
  evolution, while `/icpweek` remains the Monday-Sunday product stress test.
- Checked evidence quality: source ledger, claim ledger, claim labels,
  anti-ICP, disqualifiers, and missing-evidence handling are mandatory in the
  skill and in fixture validation.
- Checked docs and generated truth: README, CLAUDE.md, AGENTS.md,
  `scripts/start-session.sh`, generated capability maps, harness eval,
  release-check, and test-harness all include the new route.
- Changed-line trace: every meaningful edit maps to this spec's skill contract,
  static gate, fixtures, eval/release/test wiring, docs/discovery, or generated
  capability map.
- Confidence: high for static route behavior; medium for future ICP quality
  because real product evidence will vary by repo.
- Blocker decision: PASS.

## Rollback Plan

1. Remove `.claude/skills/defineicp/`.
2. Remove `scripts/defineicp-smoke.sh` and `.taste/fixtures/defineicp/`.
3. Remove the defineicp eval task/golden and harness-eval registration.
4. Remove route/script mappings from `scripts/harness-capability-map.sh`.
5. Remove docs/startup/test-harness/release-check references.
6. Regenerate capability map and rerun static release checks.
