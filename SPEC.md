# SPEC: Claude Code Time Anchor For Current Research

## Problem Statement

The model running inside Claude Code can answer from pretrained memory unless
the harness gives it a fresh temporal anchor. This creates hallucination risk
when the user asks for "today", "latest", "current", "SOTA 2026", recent model
behavior, pricing, provider docs, benchmarks, laws, or any fast-moving fact.

The harness needs a small, deterministic time source that uses the local system
clock and is injected into Claude Code context at session start and before each
user prompt. The model must know the exact current local date, hour, timezone,
UTC time, and the rule: current/SOTA claims require live verification, not
pretraining.

## Success Criteria

- [x] Add a committed `scripts/time-anchor.sh` tool that emits a local-system
  clock anchor in text, JSON, and Claude Code hook-context forms.
- [x] Add `.claude/hooks/time-anchor.sh` as the Claude Code hook wrapper.
- [x] Wire the time anchor into `.claude/settings.json` through
  `SessionStart` and `UserPromptSubmit`.
- [x] Wire the same anchor into `solo-fast`, `team-safe`, planner, and executor
  example profiles so local profile users keep the guard.
- [x] Include the anchor in `.minimaxing/state/CURRENT.md` snapshots so
  compaction/resume artifacts preserve the time context that was used.
- [x] Update `/deepresearch`, `/webresearch`, `/claudeproduct`, `/deepretaste`,
  and `/defineicp` docs so current/SOTA research must cite the time anchor and
  live-source access dates.
- [x] Update README/CLAUDE/AGENTS docs to explain that model memory is not a
  current-date source and that time-sensitive claims must refresh from the
  system clock plus live evidence.
- [x] Add static tests proving the hook emits valid `additionalContext`,
  includes local/UTC timestamps, and contains the SOTA/current verification
  warning.
- [x] No `.env`, local profile, credential file, or secret is read or printed.

## Research Brief

- Official Claude Code hook docs say `SessionStart` can add
  `hookSpecificOutput.additionalContext` to load development context at startup,
  resume, clear, or compact.
- Official Claude Code hook docs say `UserPromptSubmit` can add additional
  context before Claude processes a prompt.
- The current repo already wires `SessionStart` to
  `.claude/hooks/state-sessionstart.sh`, which calls `scripts/state.sh hydrate`.
  That is the right lifecycle surface for startup/resume/compact context.
- The current repo does not wire `UserPromptSubmit`, so it does not refresh
  time on every user prompt.
- `scripts/state.sh` records `updated_at`, but it does not label that timestamp
  as a temporal authority or enforce current-fact verification behavior.

## Source Ledger

- Cited:
  - Claude Code hooks reference:
    https://code.claude.com/docs/en/hooks
  - Anthropic Claude Code hooks reference mirror:
    https://docs.anthropic.com/en/docs/claude-code/hooks
- Repo evidence:
  - `.claude/settings.json`
  - `.claude/hooks/state-sessionstart.sh`
  - `scripts/state.sh`
  - `.claude/skills/deepresearch/SKILL.md`
  - `.claude/skills/webresearch/SKILL.md`
  - `.claude/skills/claudeproduct/SKILL.md`

## Plan

1. Add `scripts/time-anchor.sh` with `text`, `json`, and `hook` commands.
2. Add `.claude/hooks/time-anchor.sh` wrapper.
3. Wire `SessionStart` plus `UserPromptSubmit` in project and profile settings.
4. Add time anchor fields and research warning to `scripts/state.sh` snapshots.
5. Update research and product-doc skills to require a time anchor for current
   or SOTA claims.
6. Update README/CLAUDE/AGENTS and static tests.
7. Regenerate capability map, run static gates, commit, push, and refresh
   `holan8n2`.

## Agent-Native Estimate

- Estimate type: agent-native.
- Critical path: hook script -> settings wiring -> state integration -> docs and
  skill contracts -> tests -> static gates -> push.
- Agent wall-clock: 45-90 minutes.
- Agent-hours: 1-2.
- Human touch time later: none.
- Calendar blockers: none.
- Confidence: medium-high; hook surfaces are documented, but exact Claude Code
  runtime behavior remains a static contract unless the user opts into runtime
  Claude checks.

## Introspection: Pre-Implementation

- Likely mistake: injecting time only at startup. Guard: also wire
  `UserPromptSubmit` so every prompt gets a fresh anchor.
- Likely mistake: treating the clock as enough for "latest" facts. Guard:
  anchor text must explicitly require live source verification for current,
  latest, SOTA, pricing, benchmarks, providers, laws, and docs.
- Likely mistake: breaking local profiles by wiring only project settings.
  Guard: update committed example profiles too.
- Likely mistake: runtime hook claims without proof. Guard: static tests prove
  valid hook JSON; runtime Claude checks remain opt-in.
- Likely mistake: secret leakage. Guard: the time anchor reads only the system
  clock and hook metadata, never `.env` or local profiles.

## Verified 2026-05-06

- `python3 -m json.tool` on project settings and all profile examples: pass.
- `bash -n scripts/time-anchor.sh .claude/hooks/time-anchor.sh scripts/state.sh setup.sh scripts/test-harness.sh scripts/security-smoke.sh`: pass.
- `printf '{"hook_event_name":"UserPromptSubmit","prompt":"latest SOTA 2026"}' | CLAUDE_PROJECT_DIR=/home/fer/Music/holan8n bash scripts/time-anchor.sh hook`: emits valid JSON with `hookSpecificOutput.hookEventName=UserPromptSubmit`, local/UTC timestamps, and current/SOTA/pretrained-memory warning.
- `bash scripts/security-smoke.sh`: pass.
- `bash scripts/harness-capability-map.sh --write`: regenerated generated map docs/JSON after hook/script/settings changes.
- `bash scripts/harness-capability-map.sh --check`: pass.
- `git diff --check`: pass.
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`138 passed`, `0 failed`).
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`, `0 mismatches`).
- `bash scripts/release-check.sh --static-only`: pass (`138 passed`, `0 failed`; static-only release gate passed).

## Introspection: Pre-Closeout

- Likely mistake: claiming runtime Claude Code proof from static tests.
  Mitigation: the gates prove committed hook wiring and valid hook JSON; actual
  Claude Code runtime behavior remains opt-in to test in an authenticated CLI
  session.
- Likely mistake: making the time anchor replace web research. Mitigation:
  script, skills, README, CLAUDE, and AGENTS all state that current/SOTA claims
  require live verification and access dates.
- Likely mistake: local profiles losing the hook. Mitigation: project,
  solo-fast, team-safe, Opus planner, and MiniMax executor settings examples
  all include `SessionStart`/`UserPromptSubmit` time-anchor wiring.
- Likely mistake: secret exposure. Mitigation: implementation reads only stdin
  hook metadata and the system clock; verification did not read `.env` or local
  profile files.
