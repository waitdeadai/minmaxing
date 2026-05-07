---
name: opusworkflow
description: Run the cost-optimized Opus planner plus MiniMax-M2.7-highspeed executor workflow end to end. Use when the user invokes /opusworkflow or wants the recommended daily mode for a Claude subscription plus MiniMax Plus-Highspeed Token Plan.
argument-hint: [task]
disable-model-invocation: true
---

# /opusworkflow

Run the default cost-optimized workflow for:

$ARGUMENTS

Mode banner:

```text
Claude/Opus is planner, adversary, and final reviewer when proven available.
MiniMax-M2.7-highspeed is the executor for bulk coding and repair.
Default executor concurrency is 1 until provider evidence proves otherwise.
```

Optional Claude-only sibling:

```text
/opussonnet keeps the same workflow governance but requests Claude Code opusplan:
Opus 4.7 planning/judgment and Sonnet 4.6 execution, with no MiniMax token.
```

Model-profile selector:

```text
--model-profile minimax    # default: Opus judgment + MiniMax execution
--model-profile opussonnet # Opus judgment + Sonnet execution
--model-profile sonnet     # Sonnet planning + Sonnet execution
--model-profile opus       # Opus planning + Opus execution, explicit high-cost route
--model-profile default    # Claude Code account default
--model-profile custom --planner-model MODEL --executor-model MODEL
```

## Contract

- Treat `/opusworkflow` as `/opusminimax --mode workflow` with stricter budget
  defaults and as the normal daily route for all mutating work in this harness.
- Keep MiniMax as the standard executor provider. Use `/opussonnet` or
  `--executor-provider claude-sonnet` only when the operator explicitly wants
  the optional Claude-only route.
- Allow explicit model freedom through `--model-profile`; treat it as a
  governed route request, not runtime identity proof.
- Record the specialist being executed as
  `inner_contract=workflow|agentfactory|hiveworkflow|parallel|defineicp|deepretaste|demo|visualizeworkflow`.
- If the task asks for Hermes, Hive, ICP/taste mutation, approved
  visualization implementation, demo artifact production, or dense packet work,
  preserve that specialist contract under the `/opusworkflow` outer route.
- Do not claim Opus planned, reviewed, or verified unless auth/model evidence or
  the run artifact proves it.
- Do not read `.env`, `.env.*`, `.claude/settings.local.json`,
  `.claude/*.local.json`, `secrets/**`, private credentials, customer artifacts,
  or MiniMax key files.
- Do not let the planner inherit
  `ANTHROPIC_BASE_URL=https://api.minimax.io/anthropic`.
- Do not use Opus for bulk file reading, formatting, repetitive edits, or retry
  loops.
- Do not use the full local parallel ceiling by default. MiniMax Token Plan
  capacity, supervisor review capacity, and verifier capacity are the real
  bottlenecks.
- Default MiniMax executor concurrency to `1` for Plus-Highspeed unless the
  provider doctor/runtime evidence proves a higher safe ceiling.
- Run `/introspect` before freezing the plan, after MiniMax execution, after
  failed verification, and before push or ship decisions.
- Run `/verify` against `SPEC.md` before closeout.

## Budget Policy

Use Claude/Opus only at high-leverage judgment gates:

| Phase | Default Model | Rule |
| --- | --- | --- |
| Intake and taste check | Claude normal effort | Keep concise. |
| Repo audit and exploration | local tools or MiniMax packet | Avoid Opus-wide repo reads. |
| Plan and SPEC freeze | Opus if proven available | Use high/xhigh only here when warranted. |
| Implementation | MiniMax-M2.7-highspeed | Bounded packets only. |
| Test failure loop | MiniMax first | Limit retries per packet. |
| Adversarial review | Opus if proven available | Challenge architecture, risk, and evidence. |
| Final ship/no-ship | Claude/Opus if proven available | Verify claims, do not rubber-stamp. |

Practical target for the $20 Claude + $40 MiniMax setup:

```text
80-90% mechanical work: MiniMax-M2.7-highspeed
10-20% judgment work: Claude/Opus when account state proves it
executor lanes: 1 default, 2 only after explicit runtime proof
```

Optional `opussonnet` target:

```text
planner/judgment: claude-opus-4-7 through opusplan
execution: claude-sonnet-4-6 through opusplan/Sonnet profile
MiniMax token: not required
```

Explicit Anthropic-only profiles:

```text
sonnet: claude-sonnet-4-6 for planning and execution
opus: claude-opus-4-7 for planning and execution; use intentionally
default: Claude Code account default; confirm with /status before claims
custom: explicit planner/executor model IDs; static gates only prove request shape
```

## Workflow

1. Run provider/capacity preflight:

```bash
bash scripts/opusminimax-doctor.sh --static
bash scripts/parallel-capacity.sh --json
```

2. Create or update the workflow artifact and `SPEC.md` using the normal
   `/workflow` lifecycle.

3. Route implementation through `/opusminimax` packet artifacts:

```bash
bash scripts/opusworkflow.sh --task "$ARGUMENTS"
```

For specialist mutation, pass the contract explicitly:

```bash
bash scripts/opusworkflow.sh --task "$ARGUMENTS" --inner-contract agentfactory
bash scripts/opusworkflow.sh --task "$ARGUMENTS" --inner-contract hiveworkflow
```

For the optional Claude-only executor:

```bash
bash scripts/opusworkflow.sh --task "$ARGUMENTS" --executor-provider claude-sonnet
```

For explicit model profiles:

```bash
bash scripts/opusworkflow.sh --task "$ARGUMENTS" --model-profile sonnet
bash scripts/opusworkflow.sh --task "$ARGUMENTS" --model-profile opus
bash scripts/opusworkflow.sh --task "$ARGUMENTS" --model-profile custom --planner-model claude-sonnet-4-6 --executor-model claude-sonnet-4-6
```

4. MiniMax executes only planner-approved packets with owned paths,
   forbidden paths, allowed commands, acceptance checks, rollback notes, and
   stop conditions.

5. Parent Claude verifies:

- diffs and touched files
- command evidence
- tests and logs
- packet ownership
- unresolved failures
- final confidence

## Runtime Opt-In

Static preparation is the default. Runtime model calls require explicit opt-in:

```bash
bash scripts/opusworkflow.sh --task "$ARGUMENTS" --execute-planner
```

For a tiny Opus planner identity check, use:

```bash
claude --model claude-opus-4-7 --settings .claude/settings.opusminimax-planner.local.json -p 'Reply exactly: OPUSWORKFLOW_AUTH_OK'
```

Only treat the Opus planner path as runtime-proven when the response is exactly
`OPUSWORKFLOW_AUTH_OK` or an equivalent run artifact proves the model identity.

The planner must still refuse Opus claims if the actual model identity is not
proven. If Claude Code falls back to Sonnet or the subscription does not expose
Opus, record that honestly and continue with downgraded confidence or ask for
runtime/account action.

## Anti-Patterns

- "One command install plugs my subscription in" without `claude auth login`.
- `ANTHROPIC_API_KEY` present while intending subscription billing.
- Planner and executor sharing the MiniMax base URL.
- Ten MiniMax executor lanes on Plus-Highspeed because the machine supports ten
  local agents.
- Opus doing every edit because it feels smarter.
- MiniMax summaries accepted without parent verification.
- Pay-as-you-go fallback enabled silently.
