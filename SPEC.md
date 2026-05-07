# SPEC: Governance Hook Ergonomics

## Problem Statement

The project Stop hook intentionally blocks low-evidence positive closeout, but
its current message is terse enough to feel like a recurring hook error instead
of a repairable governance signal. The hook also treats read-only audit closeout
the same as implementation closeout and lets some "tests not run" wording count
as evidence.

The harness should keep the anti-hallucination gate strong while making the
blocked path obvious to Claude and the operator.

## Success Criteria

- [x] Keep `exit 2` blocking behavior for destructive Bash, evidence-free
  positive closeout, and failed-verification positive closeout.
- [x] Replace terse Stop/SubagentStop block text with actionable guidance that
  says exactly how to repair the final answer.
- [x] Distinguish read-only/audit closeout from implementation closeout without
  weakening failed-verification blocking.
- [x] Treat "tests not run", "verification not run", and equivalent caveats as
  missing verification when paired with positive closeout.
- [x] Add fixtures for the noisy path and the missing-verification path.
- [x] Keep hook execution local, shell-only, no network, no secret reads.
- [x] Run static hook, harness, and release gates before push.

## Research Brief

### Local Evidence

- `.claude/settings.json` wires `govern-effectiveness.sh` into many events,
  including `Stop` before `state-stop.sh`.
- `.claude/hooks/govern-effectiveness.sh` blocks `Stop` when the final answer has
  positive closeout words but lacks evidence, or when positive closeout conflicts
  with failed/missing verification.
- `scripts/hook-smoke.sh` already proves the high-risk block cases, but does not
  cover read-only/audit Stop ergonomics.
- Parallel repo audit found the common noisy path: a harmless read-only final
  answer like "Read-only audit done" is blocked because Stop does not consult the
  existing read-only detector.

### Current Docs Evidence

- Official Claude Code hooks docs say command hooks receive JSON on stdin and
  communicate with exit codes, stdout, and stderr.
- Exit code `2` is the blocking path. For `Stop` and `SubagentStop`, it prevents
  Claude from stopping and sends stderr back to Claude.
- Official docs also support structured JSON output, but the existing shell hook
  already uses simple exit-code semantics correctly.
- Official hook guide says Stop hooks must check `stop_hook_active` to avoid
  loops; this hook already does.
- Official configuration docs say `/hooks` can inspect hook sources and settings
  precedence. Project settings are a real shared source, and local/global hooks
  may add extra visible hook counts.

### Source Ledger

- Claude Code hooks reference:
  https://code.claude.com/docs/en/hooks
- Claude Code hooks guide:
  https://code.claude.com/docs/en/hooks-guide
- Claude Code settings/configuration:
  https://code.claude.com/docs/en/configuration
- Claude Code systems paper, April 2026:
  https://arxiv.org/abs/2604.14228

## Plan

1. Add small helper functions:
   - `has_missing_verification`
   - `has_read_only_evidence`
   - `block_closeout_conflict`
   - `block_evidence_missing`
2. Keep failed/missing verification as a hard block for positive closeout.
3. Allow read-only positive closeout only when it includes read-only wording plus
   concrete evidence such as files inspected, sources reviewed, commands run, or
   verification notes.
4. Keep implementation positive closeout evidence requirements intact.
5. Expand `scripts/hook-smoke.sh` fixtures for:
   - terse read-only closeout still blocked with actionable message
   - evidence-backed read-only closeout passes
   - "tests not run" positive closeout blocks
   - block messages include repair guidance
6. Run hook smoke, hook mesh, runtime hardening smoke, harness eval, full static
   harness, release check, and `git diff --check`.

## Agent-Native Estimate

- Estimate type: agent-native.
- Agent wall-clock: 35-70 minutes.
- Agent-hours: 1-2.
- Human touch time: none expected.
- Calendar blockers: none.
- Confidence: medium-high. The change is narrow and testable, but hook wording
  impacts operator experience, so fixture coverage matters.

## Introspection: Pre-Implementation

- Likely mistake: weakening the hook because the error is annoying. Mitigation:
  keep `exit 2` for all high-risk closeout conflicts.
- Likely mistake: allowing read-only closeouts with no evidence. Mitigation:
  read-only closeout still needs files/sources/commands/verification evidence.
- Likely mistake: treating "tests not run" as evidence because the word `tests`
  appears. Mitigation: detect missing-verification wording before evidence pass.
- Likely mistake: changing hook wiring instead of hook behavior. Mitigation:
  leave `.claude/settings.json` unchanged unless tests prove wiring is wrong.

## Verified 2026-05-07

- `bash -n .claude/hooks/govern-effectiveness.sh scripts/hook-smoke.sh scripts/hook-mesh-smoke.sh scripts/security-smoke.sh scripts/runtime-hardening-smoke.sh`: pass.
- `bash scripts/hook-smoke.sh`: pass; new fixtures cover indirect destructive Bash, `Done. No tests run.`, `Done. Unverified.`, terse read-only closeout, read-only closeout with evidence, and path-only implementation closeout.
- `bash scripts/hook-mesh-smoke.sh`: pass.
- Direct fixture: `Done. No tests run.` returns `exit 2` with repair guidance.
- Direct fixture: read-only closeout with `Files inspected:` returns `exit 0`.
- `bash scripts/security-smoke.sh`: pass.
- `bash scripts/runtime-hardening-smoke.sh`: pass.
- `bash scripts/harness-capability-map.sh --check`: pass.
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`, `0 mismatches`).
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`138 passed`, `0 failed`; workflow smoke skipped by static CI mode).
- `git diff --check`: pass.
- `bash scripts/release-check.sh --static-only`: pass (`138 passed`, `0 failed`; static-only release gate passed).

## Introspection: Pre-Closeout

- Likely mistake: claiming the hook can catch all destructive shell indirection.
  It now catches obvious quoted `bash -c` / `sh -c` forms, but generated command
  strings or variable indirection can still bypass regex scanning. This remains
  a trusted-local tripwire, not a full sandbox.
- Likely mistake: making read-only closeout too lax. The new rule allows
  read-only positive closeout only with evidence labels such as `Files
  inspected:` or `Sources reviewed:`.
- Likely mistake: overblocking implementation closeouts that list only changed
  files. This is intentional: implementation closeout needs command or
  verification evidence. If unavailable, close as partial/blocked.
- Remaining risk: `jq` is still a runtime dependency. The hook now says so and
  fails open if unavailable; static smokes fail if `jq` is absent in this repo
  environment.
