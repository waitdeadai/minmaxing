# SPEC: Codex Subscription Image Generation Skill

## Problem Statement

The harness needs a durable way to produce generated or edited image assets
requested by `SPEC.md` through Codex subscription usage, without silently
falling back to OpenAI API-key image generation.

## Success Criteria

- [x] A repo-scoped Codex skill exists under `.agents/skills/codex-imagegen/`
  and can be discovered by Codex when a task or `SPEC.md` requests image
  generation or image editing.
- [x] The skill explicitly prefers Codex/ChatGPT subscription usage and
  forbids OpenAI API-key image generation unless the user explicitly changes
  the billing/auth mode.
- [x] Harness rules explain how `SPEC.md` should express generated image asset
  requirements, including output paths, acceptance criteria, and fail-closed
  behavior when image generation is unavailable.
- [x] The generated harness capability map includes repo-scoped Codex skills
  so self-lookup can find `codex-imagegen`.
- [x] Static validation passes for the new skill and generated capability map.

## Scope

In Scope:

- Add one Codex repo skill for SPEC-driven raster image creation and editing.
- Update harness routing/rules/docs so image requests are treated as product
  artifacts, not vague visual inspiration.
- Regenerate generated harness capability docs.

Out of Scope:

- Running a real image generation job in this turn; runtime image availability
  and account limits are subscription-state dependent.
- Adding OpenAI API scripts, `OPENAI_API_KEY` usage, or Responses API wrappers.
- Adding a Claude slash command for image generation; the requested execution
  lane is Codex subscription, not Claude or API.

## Research Brief

### Local Evidence

- `AGENTS.md` says OpenAI/Codex product questions must use the
  `openaiDeveloperDocs` MCP server before memory.
- `README.md` documents Codex plugin/direct CLI support through
  `.codex/config.toml`, with `gpt-5.5`, `medium` reasoning, `max_threads = 10`,
  and OpenAI docs MCP.
- Existing visualization rules already require honest artifact paths and forbid
  claiming generated images when no image artifact exists.

### Current Product Evidence

- Official Codex skills docs say Codex scans `.agents/skills` from the current
  directory up to the repo root and can invoke skills explicitly or implicitly
  from their descriptions.
- Official OpenAI tool docs list image generation as a built-in tool for
  generating or editing images with GPT Image.
- Official Codex pricing docs say image generation counts toward general Codex
  usage limits, is unavailable on Free, and uses API pricing when Codex is used
  with an API key. Therefore this harness must prefer ChatGPT/Codex login for
  the user's subscription path and fail closed if only API-key mode is present.

### Source Ledger

- OpenAI Codex Agent Skills, accessed 2026-05-07:
  https://developers.openai.com/codex/skills
- OpenAI Codex Pricing FAQ, accessed 2026-05-07:
  https://developers.openai.com/codex/pricing#how-does-image-generation-count-toward-usage-limits
- OpenAI Image Generation Tool docs, accessed 2026-05-07:
  https://developers.openai.com/api/docs/guides/tools-image-generation
- OpenAI Available Tools docs, accessed 2026-05-07:
  https://developers.openai.com/api/docs/guides/tools#available-tools

## Agent-Native Estimate

- Estimate type: agent-native.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` reported
  `codex_max_threads=10`, `recommended_ceiling=10`, `hardware_class=workstation`
  on 2026-05-07.
- Effective parallel budget: 1 implementation lane. The change is small and
  coupled across one skill, rule/docs surfaces, and generated capability docs.
- Agent wall-clock: 25-60 minutes.
- Agent-hours: 0.5-1.0.
- Human touch time: none for static implementation. A real image run still
  depends on the operator's Codex subscription/login state.
- Calendar blockers: none for static release.
- Confidence: medium-high for static wiring, medium for runtime image behavior
  because image generation availability depends on current Codex auth/plan.

## Implementation Plan

### Task 1: Add Codex image generation skill

Definition of Done:

- [x] `.agents/skills/codex-imagegen/SKILL.md` has complete frontmatter and
  workflow instructions.
- [x] The skill requires Codex subscription/ChatGPT login preference and no
  API-key fallback.
- [x] The skill defines asset extraction, prompt construction, generation,
  verification, and fail-closed output behavior.

### Task 2: Wire harness contracts

Definition of Done:

- [x] SPEC and visualization rules define how generated image asset contracts
  must be represented and verified.
- [x] Workflow routing mentions SPEC-driven image generation as a Codex
  subscription lane.
- [x] README/AGENTS/CLAUDE explain the Codex image skill without implying API
  billing or guaranteed runtime access.

### Task 3: Update generated self-lookup

Definition of Done:

- [x] `scripts/harness-capability-map.sh` discovers `.agents/skills/*/SKILL.md`.
- [x] `docs/harness-capability-map.md` and `.json` include the new Codex skill.
- [x] Static gates for skill validation, capability map freshness, harness eval,
  release check, and diff hygiene pass.

## Verification

- Success Criteria 1 -> `python3 /home/fer/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/codex-imagegen`
- Success Criteria 2 -> Inspect `.agents/skills/codex-imagegen/SKILL.md` for
  subscription-only and no-API fallback language.
- Success Criteria 3 -> Inspect `.claude/rules/spec.rules.md` and
  `.claude/rules/visualization.rules.md`.
- Success Criteria 4 -> `bash scripts/harness-capability-map.sh --check --json`
  and inspect generated map for `codex-imagegen`.
- Success Criteria 5 -> `bash scripts/harness-eval.sh --json`,
  `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`,
  `bash scripts/release-check.sh --static-only`, and `git diff --check`.

## Rollback Plan

1. Revert the commit or remove `.agents/skills/codex-imagegen/`.
2. Revert the harness rule/docs and capability-map generator changes.
3. Regenerate the capability map with `bash scripts/harness-capability-map.sh`.
4. Verify rollback with `bash scripts/harness-capability-map.sh --check` and
   `bash scripts/release-check.sh --static-only`.

## Introspection: Pre-Implementation

- Likely mistake: accidentally building an OpenAI API wrapper. Mitigation: keep
  the skill instruction-only and explicitly block API-key fallback.
- Likely mistake: claiming Codex subscription image generation is always
  available. Mitigation: document plan/auth dependency and require fail-closed
  output when the image tool is absent.
- Likely mistake: adding a Claude-only route when the user asked for Codex.
  Mitigation: use `.agents/skills`, not only `.claude/skills`.

## Verified 2026-05-07

- `python3 /home/fer/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/codex-imagegen`: pass.
- `bash -n scripts/harness-capability-map.sh`: pass.
- `bash scripts/harness-capability-map.sh --check --json`: pass.
- `python3 -m json.tool docs/harness-capability-map.json`: pass.
- `rg -n 'codex-imagegen|Codex repo skills|codex_skill_count' docs/harness-capability-map.md docs/harness-capability-map.json`: pass; generated map lists one Codex repo skill.
- `git diff --check`: pass.
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`, `0 mismatches`).
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`141 passed`, `0 failed`; runtime workflow smoke intentionally skipped).
- `bash scripts/release-check.sh --static-only`: pass.

## Introspection: Pre-Closeout

- Likely mistake checked: the implementation could accidentally use API billing.
  The skill explicitly forbids OpenAI API keys, API scripts, Responses API
  wrappers, and direct HTTP calls unless the user changes the billing route.
- Likely mistake checked: the harness could claim image generation was proven.
  This static pass proves routing, skill discovery, and policy. It does not
  prove a live image was generated because that depends on the current Codex
  account/session exposing a native image generation tool.
- Likely mistake checked: the skill could be invisible to harness self-lookup.
  `scripts/harness-capability-map.sh` now indexes `.agents/skills/*/SKILL.md`,
  and the generated docs list `codex-imagegen`.
