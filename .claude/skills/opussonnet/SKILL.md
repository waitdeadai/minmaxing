---
name: opussonnet
description: Run the optional Claude-only Opus 4.7 planner plus Sonnet 4.6 executor workflow. Use when the user invokes /opussonnet or installed with --mode opussonnet and wants the harness without MiniMax.
argument-hint: [task]
disable-model-invocation: true
---

# /opussonnet

Run the optional Claude-only workflow for:

$ARGUMENTS

Mode banner:

```text
Claude Code opusplan is the requested model route.
Opus 4.7 is pinned for planning and judgment.
Sonnet 4.6 is pinned for execution.
MiniMax is not required for this optional route.
```

## Contract

- This is a suggested alternative, not the standard default. The default
  `/opusworkflow` route remains Claude/Opus judgment plus MiniMax-M2.7-highspeed
  execution.
- It is also available as `/opusworkflow --model-profile opussonnet` or the
  backward-compatible `/opusworkflow --executor-provider claude-sonnet`.
- Use the same governed `/workflow` lifecycle: research brief, SPEC, bounded
  implementation, `/introspect`, `/verify`, and command-backed closeout.
- Use Claude Code's `opusplan` behavior for the interactive session when
  available: Opus in plan mode, Sonnet in execution mode.
- Pin aliases through local ignored settings:
  `ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-4-7` and
  `ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-6`.
- Do not claim Opus or Sonnet runtime identity unless `/status`, a runtime
  sentinel, or a run artifact proves it for the current account.
- Do not read `.env`, `.env.*`, `.claude/settings.local.json`,
  `.claude/*.local.json`, `secrets/**`, private credentials, customer artifacts,
  or MiniMax key files.
- If the account lacks Opus access, stop and diagnose. Do not silently pretend
  the Opus planner ran.

## Command

Prepare artifacts through the same workflow wrapper:

```bash
bash scripts/opussonnetworkflow.sh --task "$ARGUMENTS"
```

Runtime planner execution remains explicit:

```bash
bash scripts/opussonnetworkflow.sh --task "$ARGUMENTS" --execute-planner
```

## Install

Clean/new folder:

```bash
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --mode opussonnet
```

Existing project or harness update:

```bash
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --import-existing --mode opussonnet
```

Then run:

```bash
claude
/opussonnet "build or fix the thing"
```

Equivalent static artifact preparation:

```bash
bash scripts/opusworkflow.sh --task "build or fix the thing" --model-profile opussonnet
```

## Anti-Patterns

- Presenting `opussonnet` as the default MiniMax-backed budget strategy.
- Claiming Opus 4.7 was used without runtime evidence.
- Leaving a MiniMax base URL in a Claude-only profile.
- Using Opus for broad repetitive execution when Sonnet can do it under the
  governed workflow.
