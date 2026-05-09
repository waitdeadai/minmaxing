# SPEC: Automated SOTA Spec QA Agent

## Problem Statement

The harness creates and updates `SPEC.md` as the active contract, but it does
not yet have an automatic quality reviewer that audits every new spec before
implementation. The user wants this review to be automatic in the normal
workflow, aimed at SOTA results, grounded in current webresearch data, and
handled by Opus 4.7 high/xhigh when runtime identity proves that model is
actually available.

## Codebase Anchors

- `.claude/skills/workflow/SKILL.md` owns the default lifecycle and must add
  Spec QA between `SPEC.md` creation/update and execution.
- `.claude/skills/opusworkflow/SKILL.md` owns the default outer route for
  mutating work and must assign the Spec QA judgment gate to Opus 4.7 high/xhigh
  only when model identity is proven.
- `.claude/skills/digestflow/SKILL.md` must run Spec QA after report-derived
  claims become spec content, so external AI reports cannot drive execution
  without current/source-backed validation.
- `.claude/skills/verify/SKILL.md` verifies implementation against `SPEC.md`;
  it should also treat missing non-trivial Spec QA as a planning-contract
  failure before closeout.
- `scripts/release-check.sh`, `scripts/test-harness.sh`,
  `scripts/harness-eval.sh`, and `scripts/harness-capability-map.sh` are the
  static public harness gates that must discover and enforce the new route.
- `docs/harness-capability-map.md` and `docs/harness-capability-map.json` are
  generated truth surfaces and must be regenerated after route/script/eval
  registration.
- Active spec lifecycle requires archiving replaced root specs through
  `scripts/spec-archive.sh`.

## Current Research Brief

Investigation mode: comprehensive.

Effective research budget: 5 tracks of ceiling 10, based on
`bash scripts/parallel-capacity.sh --json` reporting `codex_max_threads=10`,
`recommended_ceiling=10`, `cores=16`, `ram_gb=32`, and
`agent_teams_available=false`. The useful tracks were current Anthropic model
facts, Claude Code skills/subagents/hooks behavior, Spec Kit quality gates,
recent SDD research, and local harness wiring.

Loop log:

1. Discovery found current Anthropic model docs, Claude Code skill/subagent
   docs, GitHub Spec Kit docs, and recent SDD papers.
2. Deep read confirmed Opus 4.7 and Sonnet 4.6 are current documented model
   IDs, Claude Code project skills create slash commands, custom subagents can
   specialize context and model selection, hooks can trigger lifecycle scripts,
   and Spec Kit uses quality checklists plus non-destructive cross-artifact
   analysis before implementation.
3. Pressure test resolved the main risk: the harness may request Opus 4.7 for
   the reviewer, but it must not claim Opus executed unless `/status`, a
   sentinel, or a run artifact proves runtime identity.

Source ledger, accessed 2026-05-09:

- Anthropic model overview:
  https://platform.claude.com/docs/en/about-claude/models/overview
  - Current docs list Claude Opus 4.7 as the most capable generally available
    model for complex reasoning and agentic coding, with API ID
    `claude-opus-4-7`; Sonnet 4.6 is listed as `claude-sonnet-4-6`.
- Claude Code skills:
  https://code.claude.com/docs/en/slash-commands
  - Project skills in `.claude/skills/<name>/SKILL.md` create invocable
    slash-command workflows and can load only when relevant.
- Claude Code subagents:
  https://code.claude.com/docs/en/sub-agents
  - Custom subagents are specialized assistants with independent context,
    tool access, and model routing, suitable for a repeated QA reviewer role.
- Claude Code settings and hooks:
  https://code.claude.com/docs/en/settings
  - Settings expose model and effort configuration, skills, subagents, and hook
    surfaces; sensitive files can be denied through settings.
- GitHub Spec Kit `analyze` template:
  https://raw.githubusercontent.com/github/spec-kit/main/templates/commands/analyze.md
  - Spec analysis is a read-only quality gate that detects ambiguity,
    underspecification, duplication, coverage gaps, and constitution conflicts
    before implementation.
- GitHub Spec Kit `specify` template:
  https://raw.githubusercontent.com/github/spec-kit/main/templates/commands/specify.md
  - Spec generation validates testability, measurable success criteria,
    stakeholder clarity, scope, dependencies, assumptions, and unresolved
    clarifications before planning.
- GitHub Spec Kit SDD overview:
  https://github.com/github/spec-kit/blob/main/spec-driven.md
  - SDD treats the specification as the source of truth and folds testing and
    quality into the spec-driven workflow.
- Spec Kit Agents paper:
  https://arxiv.org/abs/2604.05278
  - Recent SDD work reports better judged quality when phase-level
    context-grounding and validation hooks are added to agentic spec workflows.
- Constitutional SDD paper:
  https://arxiv.org/abs/2602.02584
  - Recent security-focused SDD work argues for non-negotiable constraints in
    the specification layer, not only reactive verification after code.

Reviewed but not cited in the implementation decision:

- GitHub blog article on Spec Kit, because the repo templates provided the more
  precise implementation surface.
- General Claude Code overview, because the skills/settings/subagent docs were
  more specific.

Conflicting evidence:

- None that changes the implementation. The only material caveat is that local
  repo policy names Opus 4.7 as preferred reviewer, while runtime access remains
  account-dependent. The implementation must record requested model separately
  from proven model.

## Success Criteria

- [x] A new project skill `.claude/skills/specqa/SKILL.md` defines `/specqa` as
  the Spec QA Agent for every created or updated `SPEC.md`.
- [x] `/workflow` runs Spec QA after `SPEC.md` creation/update/reuse and before
  execution for non-trivial file-changing work.
- [x] `/opusworkflow` assigns the Spec QA reviewer to Opus 4.7 high/xhigh when
  runtime identity is proven and blocks Opus claims when it is not.
- [x] `/digestflow` requires report-derived claims embedded into `SPEC.md` to
  pass Spec QA through repo evidence or live-source evidence before execution.
- [x] `/verify` treats missing non-trivial Spec QA evidence as an incomplete
  planning contract before closeout.
- [x] Spec QA requires current webresearch for SOTA, model/provider, pricing,
  legal/regulatory, security, platform, or other time-sensitive claims.
- [x] Spec QA outputs both human-readable and machine-readable artifacts under
  `.taste/specqa/{run_id}/spec-qa.md` and `.taste/specqa/{run_id}/spec-qa.json`.
- [x] Spec QA blocks execution on critical findings and records actionable
  improvement suggestions for non-critical findings.
- [x] Static fixtures and `scripts/specqa-smoke.sh --fixtures` reject overclaims:
  no webresearch ledger, Opus claim without identity proof, critical findings
  that do not block, missing improvement suggestions, and missing artifacts.
- [x] `scripts/harness-eval.sh`, `scripts/release-check.sh`,
  `scripts/test-harness.sh`, and the generated capability map include the
  Spec QA gate.
- [x] Public docs and project instructions explain that `/opusworkflow` is still
  the default workflow and `/specqa` is the automatic spec-review gate inside it.
- [x] No `.env`, `.env.*`, `.claude/*.local.json`, key files, credentials, or
  private tokens are read or committed.

## Scope

### In Scope

- Add the `/specqa` project skill and static contract.
- Add fixtures, a smoke gate, and a static eval task.
- Wire `/specqa` into `/workflow`, `/opusworkflow`, `/digestflow`, and `/verify`.
- Update README, CLAUDE, AGENTS, startup skill counts, test harness expectations,
  release gates, and capability-map registration.
- Regenerate generated capability-map artifacts.

### Out of Scope

- Building a custom Claude API service, paid API fallback, or external reviewer
  daemon.
- Proving live Opus 4.7 runtime identity in static CI.
- Automatically rewriting every failing spec; V1 suggests improvements and
  blocks critical findings, while workflow execution applies repairs in the
  normal plan/spec loop.
- Reading secrets, local auth tokens, `.env`, or provider-local configuration.

## Spec QA Contract

Spec QA must review the active `SPEC.md` before implementation and produce:

- Spec identity: path, SHA-256, generated/updated/reused status, and task.
- Model evidence: requested reviewer model, proven reviewer model if known,
  identity proof source, and `spec_qa_model_identity_status`.
- Current-fact evidence: source ledger for webresearch, access dates, reviewed
  but not cited sources, rejected/downweighted sources, and unresolved
  uncertainty.
- Evidence states: `repo-verified`, `web-verified`, `report-derived`,
  `conflicting`, and `unverified`.
- Quality findings: requirements clarity, testability, acceptance coverage,
  success metrics, SOTA/currentness, security/compliance, UX/product taste,
  implementation risk, rollback/verification adequacy, and changed-line trace
  readiness.
- Improvement suggestions: concrete, spec-level changes with severity,
  rationale, source/evidence link, and whether they are blocking.
- Decision: `PASS`, `PASS_WITH_SUGGESTIONS`, `FIX_REQUIRED`, or `BLOCKED`.

Critical findings must force `FIX_REQUIRED` or `BLOCKED`. A run with any
critical finding must not allow execution to begin until the spec is repaired or
the blocker is explicitly reclassified with evidence.

## Surgical Diff Discipline

- Smallest sufficient implementation: add a project skill, static fixtures,
  static smoke/eval wiring, and targeted docs/workflow integration.
- No speculative abstractions: do not build a runtime service, hosted reviewer,
  API billing route, or new schema framework beyond the lightweight fixture
  validator needed for the smoke gate.
- No drive-by refactors: do not reorganize existing skills, commands, docs,
  provider scripts, or archived specs outside the touched route.
- Changed-line trace:
  - Skill/docs edits map to success criteria 1-7 and 10-11.
  - Smoke/eval/release/test edits map to success criteria 8-10.
  - Capability-map regeneration maps to success criterion 10.
  - Active `SPEC.md` replacement maps to this requested implementation plan.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock.
- Execution topology: local supervisor, no spawned subagents in this Codex turn.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` returned
  `codex_max_threads=10`, `recommended_ceiling=10`, `cores=16`, `ram_gb=32`,
  `default_substrate=subagents`, and `agent_teams_available=false`.
- Effective lanes: 5 research tracks of ceiling 10; 1 implementation lane.
- Critical path: current-source research -> spec/archive -> skill + smoke
  implementation -> workflow/docs wiring -> static gates -> capability map.
- Agent wall-clock: optimistic 75 minutes / likely 2.5 hours / pessimistic 4
  hours.
- Agent-hours: 3-5 active hours across research, edits, verification, and
  repair loops.
- Human touch time: none for static harness implementation; live Opus identity
  proof remains operator/account-dependent.
- Calendar blockers: none for static local release; runtime Opus proof may be
  blocked by subscription/account availability.
- Confidence: medium-high for static automation; medium for live Opus execution
  claims because they require runtime evidence outside static CI.
- Human-equivalent baseline: roughly 1 working day for a careful developer
  because the change touches workflow docs, tests, fixtures, generated maps, and
  release gates.

## Implementation Plan

1. Add `.claude/skills/specqa/SKILL.md` with a concise, evidence-bound Spec QA
   procedure.
2. Add `.taste/fixtures/specqa/*` fixture artifacts and
   `scripts/specqa-smoke.sh` to validate the static contract.
3. Register `specqa-smoke` in `scripts/harness-eval.sh`,
   `scripts/release-check.sh`, `scripts/test-harness.sh`, and
   `scripts/harness-capability-map.sh`.
4. Add `m13-specqa-sota-gate` eval task and golden metadata.
5. Wire Spec QA into `/workflow`, `/opusworkflow`, `/digestflow`, and `/verify`.
6. Update README, CLAUDE, AGENTS, `scripts/start-session.sh`, and skill-count
   expectations from 36 to 37.
7. Regenerate `docs/harness-capability-map.md` and
   `docs/harness-capability-map.json`.
8. Run static verification and repair failures.

## Verification

- Success criteria 1-8 -> `bash scripts/specqa-smoke.sh --fixtures`
- Success criterion 9 -> negative fixture rejection in `specqa-smoke`
- Success criterion 10 -> `bash scripts/harness-eval.sh --json`,
  `bash scripts/harness-capability-map.sh --check --json`, and
  `bash scripts/release-check.sh --static-only`
- Success criterion 11 -> `rg -n "specqa|Spec QA|37 skills" README.md CLAUDE.md AGENTS.md .claude/skills`
- Success criterion 12 -> `git diff --check` plus no reads of `.env` or local
  secret paths
- Script syntax -> `bash -n scripts/*.sh`
- JSON validity -> `python3 -m json.tool` on added fixtures and golden JSON

Verification results:

- [x] `bash scripts/specqa-smoke.sh --fixtures` passed.
- [x] `bash scripts/opusworkflow-smoke.sh` passed with the new `spec_qa`
  artifact contract.
- [x] `bash scripts/visualize-smoke.sh` passed after the skill-count update.
- [x] `bash scripts/harness-capability-map.sh --write` regenerated generated
  docs.
- [x] `bash scripts/harness-capability-map.sh --check --json` passed with 37
  skills, 59 scripts, and 24 eval tasks.
- [x] `bash scripts/harness-eval.sh --json` passed with 24 tasks and 21 gates,
  including `specqa-smoke`.
- [x] `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh` passed: 148
  passed, 0 failed.
- [x] `bash scripts/release-check.sh --static-only` passed, including
  `git diff --check`.

## Rollback Plan

1. Revert this commit or restore the touched files from git.
2. Run `bash scripts/harness-capability-map.sh --write` if generated map files
   were changed.
3. Run `bash scripts/release-check.sh --static-only`.
4. Restore the previous active spec from the archive if needed:
   `.taste/specs/20260509-015957-claude-code-native-remote-control-harness-superseded-before-new-spec.md`.

## Introspection: Pre-Implementation

- Likely mistake: overclaiming that Opus 4.7 actually performed the QA review.
  Mitigation: require identity evidence fields and make static gates reject
  Opus claims without proof.
- Likely mistake: turning Spec QA into a manual side route that workflows forget.
  Mitigation: wire it into `/workflow`, `/opusworkflow`, `/digestflow`,
  `/verify`, release checks, and eval metadata.
- Likely mistake: using stale "SOTA" knowledge. Mitigation: require current
  webresearch and source ledger when SOTA or time-sensitive claims matter.
- Likely mistake: blocking every minor suggestion. Mitigation: use severity and
  decision states so critical issues block, while lower-severity improvements
  become actionable suggestions.
