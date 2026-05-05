# SPEC: Governed `/demo` Recorded Demo Skill

## Problem Statement

The harness does not have a first-class `/demo` route for producing recorded product demos with voiceover, captions, browser evidence, and safety gates. The user wants a SOTA 2026, deeply researched, bilingual English plus neutral Spanish demo workflow that records what the product actually does without leaking secrets or claiming media proof that did not run.

## Success Criteria

- [x] `.claude/skills/demo/SKILL.md` exists, uses standard skill frontmatter, is manual-only, and defines `/demo` as a governed media-producing route with Playwright capture, bilingual voiceover, WebVTT captions, FFmpeg composition, manifest, retention, safety, and static/runtime proof boundaries.
- [x] `scripts/demo-smoke.sh --fixtures` passes without network, secrets, browser launch, or TTS provider access, and rejects red fixtures for missing Spanish/English artifacts, missing TTS disclosure, unsafe output retention, unsafe media paths, and failed quality gates.
- [x] Generated demo media paths are explicitly ignored by git, including `.taste/demo-recordings/`, `demo-recordings/`, `recordings/`, `.webm`, `.mp4`, `.mov`, `.wav`, `.mp3`, `.trace.zip`, and `.har`.
- [x] The harness capability map discovers `/demo` as the 29th skill, classifies it under `execution`, marks it as a core route, and links `scripts/demo-smoke.sh`.
- [x] README, CLAUDE.md, `scripts/start-session.sh`, `scripts/test-harness.sh`, and `scripts/visualize-smoke.sh` no longer advertise the stale 28-skill contract and include `/demo` where the skill list is manual.
- [x] `scripts/harness-eval.sh --json` includes and passes a `demo-smoke` gate through `evals/harness/tasks/m7-demo-smoke.yaml` and `evals/harness/golden/m7-demo-smoke.json`.
- [x] `bash scripts/release-check.sh --static-only` includes `scripts/demo-smoke.sh --fixtures`, and the no-secret static release gate can verify the new route without runtime media providers.
- [x] Active workflow artifacts record research, parallel packet evidence, pre-plan introspection, post-implementation introspection, verification evidence, and changed-line trace.

## Scope

### In Scope

- Add the `/demo` skill contract.
- Add static demo manifest and safety smoke validation.
- Add deterministic green/red demo fixtures.
- Add generated capability-map route and script ownership wiring.
- Add harness eval metadata/golden for the demo smoke gate.
- Update manual skill lists/counts.
- Wire static release and test-harness checks.
- Regenerate generated capability-map artifacts.

### Out Of Scope

- Implementing a full Playwright recorder CLI.
- Calling OpenAI TTS or any paid/external provider.
- Launching browsers during static release checks.
- Creating real demo videos in this repo.
- Custom voice support beyond guarded policy language.
- Publishing demos to YouTube, app stores, or external platforms.
- Reading `.env`, `.env.*`, `.claude/settings.local.json`, personal browser profiles, or production credentials.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock.
- Execution topology: subagents for independent research/review lanes plus local implementation.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` reported `recommended_ceiling=10`, `codex_max_threads=10`, `hardware_class=workstation`, and `default_substrate=subagents`.
- Effective lanes: 10 of ceiling 10 for this dense slice, because the independent packets were distinct: repo skill wiring, artifact/eval wiring, Playwright capture docs, TTS/WebVTT/FFmpeg docs, operator UX/accessibility docs, distribution/platform docs, media validation docs, security review, manual count/list tracing, and parent implementation.
- Critical path: repo contract audit -> external source research -> pre-plan introspection -> SPEC -> skill/smoke/fixtures/docs/eval wiring -> generated map -> static gates -> post-implementation introspection -> closeout.
- Agent wall-clock: optimistic 2 hours / likely 3.5 hours / pessimistic 5 hours.
- Agent-hours: approximately 12-18 across research/review lanes plus implementation and verification.
- Human touch time: none expected for static contract; human review is required before any real recording with credentials, paid TTS, or production data.
- Calendar blockers: runtime media proof depends on local browser, FFmpeg/ffprobe, TTS provider credentials, and approved demo target; static lane has no calendar blocker.
- Confidence: medium-high for static harness integration; medium for runtime media quality because actual browser/TTS recording is intentionally out of this static slice.

## Implementation Plan

### Task 1: Add `/demo` Skill Contract
Definition of Done:
- [ ] `.claude/skills/demo/SKILL.md` uses frontmatter with `name: demo`, description, argument hint, and `disable-model-invocation: true`.
- [ ] Skill defines intake, capture, bilingual voiceover, captions, manifest, quality gates, profile compatibility, static verification, runtime verification, and blockers.
- [ ] Skill explicitly blocks personal browser profiles, `.env` reads, unignored media, missing TTS disclosure, and quality-degrading fallback output.

### Task 2: Add Demo Smoke Gate
Definition of Done:
- [ ] `scripts/demo-smoke.sh` supports `--fixtures`, `--manifest PATH`, and `--runtime PATH`.
- [ ] Static contract checks verify required skill language and gitignore coverage.
- [ ] Manifest validation requires English and Spanish artifacts, TTS disclosure when voiceover is present, retention fields, command evidence, quality gates, and safe `.taste/demo-recordings/` paths.
- [ ] Runtime mode uses `ffprobe`/FFmpeg when actual media files exist and fails for missing/tiny/undecodable video or audio.

### Task 3: Add Fixtures And Eval Wiring
Definition of Done:
- [ ] Add at least one green fixture.
- [ ] Add at least four red fixtures for safety/quality failures.
- [ ] Add `m7-demo-smoke` eval task and golden.
- [ ] Add `demo-smoke` as a known harness-eval gate.

### Task 4: Wire Harness Discovery And Docs
Definition of Done:
- [ ] `scripts/harness-capability-map.sh` classifies `/demo` and links `demo-smoke`.
- [ ] README, CLAUDE.md, start-session, visualize-smoke, and test-harness use the 29-skill contract.
- [ ] `scripts/release-check.sh --static-only` includes `demo-smoke`.
- [ ] Regenerated `docs/harness-capability-map.md` and `.json` are fresh.

### Task 5: Verify And Close Out
Definition of Done:
- [ ] Run focused demo smoke.
- [ ] Run capability-map freshness check.
- [ ] Run harness eval.
- [ ] Run artifact lint fixtures.
- [ ] Run security smoke.
- [ ] Run full static harness and release gate.
- [ ] Run `git diff --check`.
- [ ] Record changed-line trace and post-implementation introspection.

## Verification

- Criterion 1 -> inspect `.claude/skills/demo/SKILL.md` and `docs/harness-capability-map.*`.
- Criterion 2 -> `bash scripts/demo-smoke.sh --fixtures`.
- Criterion 3 -> `git check-ignore -q .taste/demo-recordings/sample.webm demo-recordings/sample.mp4 recordings/sample.wav sample.webm sample.mp4 sample.wav sample.trace.zip sample.har`.
- Criterion 4 -> `bash scripts/harness-capability-map.sh --check --json`.
- Criterion 5 -> `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`.
- Criterion 6 -> `bash scripts/harness-eval.sh --json`.
- Criterion 7 -> `bash scripts/release-check.sh --static-only`.
- Criterion 8 -> inspect `.taste/workflow-runs/20260505-demo-skill-workflow.md` and `.taste/parallel/20260505-demo-skill/`.
- Hygiene -> `bash scripts/artifact-lint.sh --fixtures`, `bash scripts/security-smoke.sh`, `git diff --check`.

### Verified 2026-05-05

- `bash scripts/demo-smoke.sh --fixtures`: pass (`1 green`, `5 red`).
- `bash scripts/parallel-aggregate.sh .taste/parallel/20260505-demo-skill`: pass (`packets=10`, `workers=10`, `effective_lanes=10`, `bottleneck=capacity_ceiling`).
- `bash scripts/harness-capability-map.sh --check --json`: pass (`skills=29`, `scripts=46`, `eval_tasks=18`).
- `bash scripts/harness-eval.sh --metadata-json`: pass.
- `bash scripts/harness-eval.sh --json`: pass (`tasks=18`, `gates=15`, `mismatches=[]`).
- `bash scripts/artifact-lint.sh --fixtures`: pass (`4 green`, `12 red`).
- `bash scripts/security-smoke.sh`: pass.
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`122 passed`, `0 failed`).
- `bash scripts/release-check.sh --static-only`: pass, including `git diff --check`.

## Rollback Plan

1. Revert or remove `.claude/skills/demo/SKILL.md`, `scripts/demo-smoke.sh`, `.taste/fixtures/demo-smoke/`, `evals/harness/tasks/m7-demo-smoke.yaml`, and `evals/harness/golden/m7-demo-smoke.json`.
2. Restore README, CLAUDE.md, start-session, visualize-smoke, test-harness, release-check, harness-eval, and harness-capability-map script changes to the prior 28-skill contract.
3. Regenerate `docs/harness-capability-map.md` and `docs/harness-capability-map.json` with `bash scripts/harness-capability-map.sh`.
4. Remove any generated demo outputs with `rm -rf .taste/demo-recordings demo-recordings recordings`.
5. Verify rollback with `bash scripts/harness-capability-map.sh --check --json`, `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`, `bash scripts/release-check.sh --static-only`, and `git diff --check`.
