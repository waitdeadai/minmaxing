# SPEC: Suggested Opus + Sonnet Install Mode

## Problem Statement

The harness default should remain `/opusworkflow`: Claude/Opus judgment plus
MiniMax-M2.7-highspeed execution for the user's preferred cost-optimized split.
The operator also wants a clean, suggested Claude-only install path for repos
where MiniMax should not be required: Opus 4.7 plans, adversarially reviews, and
handles judgment, while Sonnet 4.6 performs execution through Claude Code's
native model behavior.

This must be a first-class suggested install option, not a replacement default
and not a silent model downgrade.

## Success Criteria

- [x] `setup.sh` supports a non-default `--mode opussonnet` install/update path.
- [x] `opussonnet` installs the same harness files and governed hooks while
  preparing ignored local Claude-only profiles.
- [x] The optional profile pins Opus 4.7 and Sonnet 4.6 without MiniMax base URLs
  or secrets.
- [x] Existing MiniMax default install commands remain unchanged.
- [x] `/opusworkflow` script/artifacts can represent either the standard MiniMax
  executor or the optional Claude/Sonnet executor without confusing the two.
- [x] Static gates prove the default MiniMax route still works and the optional
  Sonnet route is lintable.
- [x] README and runtime docs show one clean command for the suggested
  Claude-only install path and clearly mark it as optional.
- [x] No `.env`, `.env.*`, `.claude/*.local.json`, key files, or secrets are read
  by the assistant or committed.

## Research Brief

### Local Evidence

- `setup.sh` already installs clean folders, imports into existing projects, and
  creates ignored split profiles for Opus planner plus MiniMax executor.
- `.claude/skills/opusworkflow/SKILL.md` defines the standard budget policy:
  Opus only at judgment gates, MiniMax-M2.7-highspeed for bounded coding and
  repair packets.
- `scripts/opusworkflow.sh` and `scripts/opusminimax.sh` currently hard-code the
  executor assumption to MiniMax, so optional Sonnet execution needs explicit
  provider metadata to avoid misleading artifacts.
- `scripts/artifact-lint.sh` currently rejects every `opusminimax-run` whose
  executor is not MiniMax, which is correct for the standard path but too narrow
  for an explicit Claude-only optional route.

### Current Product Evidence

- Claude Code model configuration docs say the `opusplan` alias uses Opus during
  plan mode and Sonnet during execution mode.
- The same docs say Anthropic API aliases currently resolve `opus` to Opus 4.7
  and `sonnet` to Sonnet 4.6, and model environment variables can pin alias
  resolution.
- The Claude Help Center lists `claude-opus-4-7` and `claude-sonnet-4-6` as
  supported Claude Code model identifiers.

### Source Ledger

- Claude Code model configuration:
  https://code.claude.com/docs/en/model-config
- Claude Help Center model configuration:
  https://support.claude.com/en/articles/11940350-claude-code-model-configuration

## Plan

1. Add committed `opussonnet`/Sonnet example profiles with no MiniMax endpoint,
   no credentials, explicit secret denies, governance hooks, and pinned model
   env vars.
2. Extend `setup.sh` and `setup.ps1` with `--mode opussonnet`, keeping default
   `opusworkflow` untouched.
3. Extend `scripts/opusworkflow.sh`, `scripts/opusminimax.sh`, and
   `scripts/artifact-lint.sh` with explicit `executor_provider` support for
   `minimax` and `claude-sonnet`.
4. Extend static doctor/security/smoke tests to validate the optional profile
   while preserving MiniMax as the standard route.
5. Update README, AGENTS/CLAUDE guidance, runtime quickstart, and regenerate the
   harness capability map.
6. Run static acceptance gates and archive this SPEC after verified closeout.

## Agent-Native Estimate

- Estimate type: agent-native.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` reported
  `recommended_ceiling=10`, `codex_max_threads=10`, `hardware_class=workstation`
  on 2026-05-07.
- Effective parallel budget: 1 implementation lane. The change is coupled across
  installer, profile examples, artifact validation, docs, and static gates.
- Agent wall-clock: 60-120 minutes.
- Agent-hours: 1.5-3.
- Human touch time: none for static implementation; runtime account access
  remains operator-dependent.
- Calendar blockers: none for static release.
- Confidence: medium. Claude Code model availability is account-dependent, so
  static checks can prove configuration but not live Opus/Sonnet access.

## Introspection: Pre-Implementation

- Likely mistake: making `opussonnet` look like the new default. Mitigation:
  docs and setup output must say it is suggested/optional; default commands stay
  MiniMax-backed `/opusworkflow`.
- Likely mistake: using Sonnet artifacts that still say MiniMax executed.
  Mitigation: add explicit `executor_provider` and provider-specific validation.
- Likely mistake: writing secrets or reading local ignored profiles during this
  implementation. Mitigation: create committed examples only; tests must not
  inspect local credential files.
- Likely mistake: overclaiming runtime proof. Mitigation: all static docs say
  model identity still requires `claude auth login`, `/status`, or explicit
  runtime checks.

## Verified 2026-05-07

- `bash -n setup.sh scripts/opusminimax.sh scripts/opusworkflow.sh scripts/opussonnetworkflow.sh scripts/opusminimax-doctor.sh scripts/opusworkflow-smoke.sh scripts/security-smoke.sh scripts/test-harness.sh scripts/artifact-lint.sh scripts/harness-capability-map.sh`: pass.
- `python3 -m json.tool` on the new OpusSonnet profiles, updated schema, and
  green artifact fixture: pass.
- `env -u MINIMAX_TOKEN_KEY -u TOKEN_KEY bash setup.sh --help`: pass; help shows
  the optional `--mode opussonnet` command without executing setup.
- `bash scripts/opusminimax-doctor.sh --static --executor-provider claude-sonnet`:
  exits 0 with only existing tracked fixture/test placeholder warnings.
- `bash scripts/opusworkflow-smoke.sh`: pass; validates default MiniMax and
  optional `claude-sonnet` artifacts.
- `bash scripts/artifact-lint.sh --fixtures`: pass (`8 green`, `22 red`).
- `bash scripts/security-smoke.sh`: pass.
- `bash scripts/opussonnetworkflow.sh --task "manual optional route check" --run-id manual-opussonnet-check` plus artifact lint: pass; runtime not executed.
- `bash scripts/harness-capability-map.sh --write` and `--check`: pass.
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`,
  `0 mismatches`).
- `bash scripts/metacognition-scorecard.sh --fixtures --json`: pass (`7 green`,
  `11 red`).
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`141 passed`,
  `0 failed`).
- `bash scripts/release-check.sh --static-only`: pass.
- `git diff --check`: pass.

## Introspection: Pre-Closeout

- Likely mistake checked: `opussonnet` could appear to replace the MiniMax
  default. The README, AGENTS, CLAUDE, skill text, and setup output all label it
  as optional/suggested, while default commands still use MiniMax-backed
  `/opusworkflow`.
- Likely mistake checked: Sonnet artifacts could imply MiniMax execution. The
  run artifact now carries `executor_provider`, and artifact lint validates
  MiniMax and Claude/Sonnet providers differently.
- Remaining risk: static gates prove profile shape and artifact honesty, not
  live account model access. Runtime identity still requires authenticated
  Claude Code checks.
