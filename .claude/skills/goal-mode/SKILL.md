---
name: goal-mode
description: Diagnose and document native Claude Code /goal readiness safely inside the minmaxing harness. This route is static readiness and effectiveness guidance only; set native goals manually with /goal inside Claude Code.
argument-hint: [status/troubleshoot/template]
disable-model-invocation: true
---

# /goal-mode

Diagnose native Claude Code `/goal` readiness and safe harness usage for:

$ARGUMENTS

Claude Code `/goal` is a native session-scoped continuation command. In this
harness, `/goal-mode` is a readiness, troubleshooting, and effectiveness route
only. It does not set a live goal, does not run `claude -p`, does not start
Remote Control, does not open Agent View, and does not dispatch `claude --bg`.

Use the native command manually inside Claude Code:

```text
/goal <condition>
/goal
/goal clear
```

Do not create `.claude/skills/goal/SKILL.md`: that would risk shadowing or
confusing the native Claude Code `/goal` command.

## Native Boundary

Native `/goal` is separate from:

- `/opusworkflow`: the governed mutating workflow. `/goal` may continue a
  bounded session, but it does not replace research, code audit, `SPEC.md`,
  `/specqa`, `/introspect`, `/verify`, or release gates.
- `/workflow`: the underlying lifecycle and explicit fallback. `/goal` is not a
  lifecycle, artifact format, or closeout policy.
- `/parallel`: packet orchestration. `/goal` can be used inside an already-owned
  packet, but it does not satisfy packet DAG, ownership matrix, sidecar,
  aggregation, parent verification, or sync-barrier requirements.
- `/hive`: role coordination. `/goal` does not provide queen/supervisor,
  blackboard, dissent log, synthesis, or hive aggregation.
- `/agent-view`: an operator TUI for background sessions. Agent View can monitor
  independent sessions where the operator manually uses `/goal`, but Agent View
  plus `/goal` is still not `/parallel`.
- `/remote-control`: a web/mobile access surface for a local session. Remote
  Control plus `/goal` is not cloud durability or CI.
- Subagents and Agent View background sessions: subagents report back to a
  parent conversation; Agent View sessions report to the operator. `/goal`
  changes neither reporting path.
- Stop hooks: official docs describe `/goal` as a wrapper around a
  session-scoped prompt-based Stop hook. Harness command hooks and release gates
  remain the deterministic enforcement layer.

## Effectiveness Yield Policy

`/goal` increases persistence, not correctness. It can keep Claude working
across turns, but the goal evaluator is not an independent verifier. Parent
verification and command evidence still decide whether the work is done.

High-yield pattern:

```text
main harness session = planner, supervisor, verifier
native /goal = bounded continuation inside one Claude Code session
existing scripts = real pass/fail evidence
parent closeout = command evidence plus repo-state verification
```

Use `/goal` only when the harness already knows the acceptance checks and wants
Claude Code to keep iterating until those checks are shown in the transcript.

Safe template:

```text
/goal bash scripts/release-check.sh --static-only exits 0 and git diff --check exits 0, or stop after 6 turns with a blocker summary
```

## Goal Assist Prompt Pattern

Goal Assist is the harness pattern for composing copy-paste native `/goal`
conditions after `/opusworkflow` has already reached a concrete, repairable
gate. It is not a runner. It must not set `/goal`, run `claude -p`, open Remote
Control, open Agent View, dispatch `claude --bg`, read transcripts, or claim
runtime proof.

Goal Assist may only produce native `/goal` text when the failed gate is
deterministic and already known. Required fields:

- failed gate or exact command
- owned scope
- forbidden paths/actions
- transcript evidence required
- stop bound
- blocker-summary fallback
- parent verification command

Canonical shape:

```text
Goal Assist:
Status: suggest_only
Failed gate: <exact command or artifact check>
Owned scope: <paths/artifacts>
Forbidden: .env, .env.*, .claude/*.local.json, secrets/**, deploy/push/ship, unrelated files
Evidence required: command output and exit status shown in transcript
Stop bound: stop after <N> turns with blocker summary
Parent verification: rerun <commands> before closeout

/goal <exact command(s)> exit 0 and <specific artifact/diff check> is shown, without touching <forbidden paths/actions>, or stop after <N> turns with a blocker summary
```

Eligibility states:

- `not_eligible`: missing research/audit/spec/estimate, missing or failed
  `/specqa`, missing `/introspect`, provider identity proof, secrets/customer
  data, deploy/push/ship, approval waits, security-policy failures, shared-file
  parallel edits, or broad "production ready" goals.
- `suggest_only`: a deterministic gate exists but runtime is unproven, the CLI
  is below the observed launch baseline, `bypassPermissions` risk exists, or
  operator approval is needed. This is the default local state until runtime is
  manually proven.
- `eligible_bounded`: exact failed command, owned scope, forbidden paths, stop
  bound, transcript evidence, and parent verification are all present. The
  harness still emits only a copy-paste template.

Other good uses:

- keep repairing until `bash scripts/hook-smoke.sh`,
  `bash scripts/security-smoke.sh`, and `git diff --check` pass, or stop after
  a named turn limit
- keep a single isolated packet focused until its required artifact and tests
  exist
- use inside an Agent View background session only when the packet has owned
  files/worktree, forbidden paths, expected artifact, stop bound, and parent
  verification

Bad uses:

- broad product building with no `SPEC.md`
- "make it production ready" or "fix everything" without measurable checks,
  stop bounds, forbidden files, and evidence requirements
- shared-file parallel edits
- secrets or customer data work
- deploy, push, or ship decisions
- replacing `/specqa`, `/introspect`, `/verify`, release checks, provider
  identity proof, or CI
- unattended trusted-local `bypassPermissions` loops against the real repo

## Prerequisites

- Official `/goal` docs do not state a `/goal`-specific minimum version.
- The observed launch evidence and Agent View minimum point to Claude Code
  `2.1.139+`; until this machine is updated and manually proven, runtime
  `/goal` remains local-runtime-unproven.
- Runtime `/goal` needs hooks available and workspace trust accepted.
- `disableAllHooks` blocks the native hook mechanism that `/goal` relies on.
- `claude -p "/goal ..."` works according to official docs, but the harness
  treats it as manual/authenticated runtime only, never static CI proof.
- `--max-turns` and `--no-session-persistence` are required for any later
  disposable runtime smoke.
- This repo defaults to trusted-local `bypassPermissions`; unattended `/goal`
  loops in the real repo are high-risk unless the operator explicitly accepts
  that authority.

## Checks

Run the static doctor:

```bash
bash scripts/goal-mode-doctor.sh --static --json
```

Run the fixture gate:

```bash
bash scripts/goal-mode-smoke.sh --fixtures
```

These checks do not set `/goal`, do not run `claude -p`, do not start Remote
Control, do not open Agent View, do not dispatch background sessions, do not
read `~/.claude/jobs`, do not inspect transcripts, and do not prove paid-account
runtime availability. They only prove that the committed harness documents and
validates native `/goal` safely.

## Manual Runtime Evidence

After updating Claude Code, use only a disposable temp workspace with no secrets
for runtime smoke:

```bash
claude --version
claude -p --max-turns 2 --no-session-persistence "/goal <toy condition or stop after 1 turn>"
```

Do not run runtime smoke in the real repo, with Remote Control, with Agent View,
with `--bg`, or with `bypassPermissions`. Report the result as manual runtime
evidence, never as CI/static proof.

## Static Artifact

`scripts/goal-mode-doctor.sh --static --json` emits:

```json
{
  "artifact_type": "goal-mode-readiness",
  "native_claude_code_goal": true,
  "runtime_goal_started": false,
  "runtime_goal_proof_status": "blocked_by_cli_version",
  "official_minimum_required_version": null,
  "minimum_observed_launch_version": "2.1.139",
  "operator_boundary": "manual_or_bounded_runtime_only"
}
```

Allowed `runtime_goal_proof_status` values:

- `blocked_by_cli_version`
- `not_run_static_only`
- `ready_static_only`
- `local_runtime_unproven`

Static artifacts must not claim that `/goal` was set, that `claude -p` ran, that
Remote Control or Agent View opened, that a paid Claude account connected, or
that a goal evaluator verified repo state.

## Anti-Patterns

- Creating `.claude/skills/goal/SKILL.md`.
- Treating `/goal` as `/opusworkflow`, `/workflow`, `/parallel`, `/hive`, or
  `/verify`.
- Claiming the evaluator ran tests, read files, inspected diffs, or proved CI.
- Claiming `claude -p "/goal ..."` is CI-safe by default.
- Running a real-repo `/goal` loop with no stop bound, no command evidence, and
  `bypassPermissions`.
- Claiming Goal Assist passed, verified repo state, or satisfied `/verify`
  without parent command evidence.
- Treating Agent View rows or a `/goal` success message as parent-verified
  worker results.
- Reading `.env`, local Claude settings, `~/.claude/jobs`, transcripts, or
  private session state for static readiness.
