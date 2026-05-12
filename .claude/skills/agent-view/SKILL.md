---
name: agent-view
description: Diagnose Claude Code Agent View readiness safely inside the minmaxing harness. This route is static readiness and troubleshooting only; open the live Agent View TUI manually with claude agents.
argument-hint: [status/troubleshoot]
disable-model-invocation: true
---

# /agent-view

Diagnose Claude Code Agent View readiness for:

$ARGUMENTS

Agent View is Claude Code's local background-session dashboard. In this harness,
`/agent-view` is a readiness and troubleshooting route only. It does not open
the live TUI, does not dispatch background sessions, and does not run
`claude --bg`.

To open the live native Agent View TUI manually, run this from a shell:

```bash
claude agents
```

## Native Boundary

Agent View is separate from:

- `/remote-control`: continues a local Claude Code session from `claude.ai/code`
  or mobile. Agent View is a terminal dashboard for local background sessions.
- `/agents`: the interactive Claude Code subagent panel. `claude agents` opens
  Agent View from the shell.
- Subagents: subagents report back to the parent conversation. Agent View
  sessions report only to the operator.
- Agent teams: experimental peer coordination. Agent View sessions are
  independent unless the operator or another harness contract coordinates them.
- `/parallel`: minmaxing packet orchestration. Agent View can help an operator
  monitor independent sessions, but it does not satisfy packet DAG, ownership
  matrix, sidecar, aggregation, `/introspect`, or `/verify` requirements.

Do not build a custom dashboard, websocket bridge, browser backdoor, MCP control
plane, or API-key fallback for this route.

## Effectiveness Yield Policy

Use Agent View for effectiveness only when it increases operator awareness over
independent top-level lanes. The high-yield pattern is:

```text
main harness session = orchestrator, judge, and verifier
Agent View sessions = optional independent evidence lanes
artifacts = bridge back into /parallel, /workflow, or /hiveworkflow
```

Do not optimize for the number of running sessions. Optimize for verified
evidence per operator minute, reduced blocked-session time, fewer context
switches, and cleaner stop/attach decisions. Three scoped sessions with clear
artifacts are better than ten busy sessions that produce merge conflicts,
unverified claims, or stale context.

Agent View is appropriate when each background session has explicit scope,
owned files or read-only surfaces, a required output artifact, stop conditions,
and a parent verification path. Move on to `/opusworkflow`, `/parallel`, or
local work when the task is tightly coupled, touches shared files, involves
secrets/security-sensitive authority, or needs one shared reasoning loop.

## Prerequisites

- Claude Code must be `v2.1.139` or newer.
- Check the local CLI with `claude --version`.
- Agent View can be disabled with the shared `disableAgentView` setting or
  `CLAUDE_CODE_DISABLE_AGENT_VIEW`.
- Background sessions read settings and permission mode from their target
  directory, so this repo's trusted-local `bypassPermissions` posture is a real
  unattended authority risk.
- Background sessions are local, consume subscription quota independently, are
  stopped by sleep or shutdown, and can use `.claude/worktrees/` for file edits.
- Worktrees created by Agent View are not a minmaxing merge strategy. Keep
  `/parallel` aggregation and parent verification as the source of truth for
  governed packet work.

## Checks

Run the static doctor:

```bash
bash scripts/agent-view-doctor.sh --static --json
```

Run the fixture gate:

```bash
bash scripts/agent-view-smoke.sh --fixtures
```

These checks do not open Agent View, do not dispatch background sessions, do not
read `~/.claude/jobs`, do not inspect transcripts, and do not prove paid-account
runtime availability. They only prove that the committed harness documents and
validates Agent View safely.

## Runtime Use

Manual runtime check after upgrading Claude Code:

```bash
claude --version
claude agents --help
claude agents
```

Only the operator should open the TUI. A manual runtime result must be reported
as manual evidence, never as CI/static proof. Do not dispatch mutating background
sessions unless the task has explicit ownership, verification, and rollback
boundaries.

## Static Artifact

`scripts/agent-view-doctor.sh --static --json` emits:

```json
{
  "artifact_type": "agent-view-readiness",
  "runtime_agent_view_started": false,
  "runtime_proof_status": "blocked_by_cli_version",
  "minimum_required_version": "2.1.139",
  "operator_boundary": "manual_operator_monitor_only"
}
```

Allowed `runtime_proof_status` values:

- `blocked_by_cli_version`
- `not_run_static_only`
- `ready_static_only`

Static artifacts must not claim that Agent View opened, that a background
session ran, that a paid Claude account connected, or that background sessions
replace minmaxing verification.

## Anti-Patterns

- Treating Agent View rows as verified worker results.
- Treating `claude agents` as `/parallel`, `/hive`, or `/opusworkflow`.
- Claiming ten background sessions means 10x throughput.
- Claiming background sessions are cloud durable.
- Reading `.env`, local Claude settings, `~/.claude/jobs`, transcripts, or
  session state for a static readiness answer.
- Hiding the `bypassPermissions` risk for unattended background sessions.
