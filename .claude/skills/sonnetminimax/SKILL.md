---
name: sonnetminimax
description: Run the power-user Sonnet 4.6 judgment plus MiniMax-M2.7-highspeed Token Plan executor route. Use when the operator wants to preserve Opus quota or has exhausted Opus, while keeping the same governed /opusworkflow lifecycle and MiniMax bounded execution.
argument-hint: [task] [--effort high|xhigh|max]
disable-model-invocation: true
---

# /sonnetminimax

Run the Opus-saving Sonnet + MiniMax route for:

$ARGUMENTS

Mode banner:

```text
Sonnet 4.6 is requested for planning, Spec QA/review, adversarial judgment, and final decision work.
MiniMax-M2.7-highspeed from the MiniMax Token Plan is requested for bounded execution packets.
Default effort is max, which records max and maps to Claude CLI xhigh.
/opusworkflow remains the main route: Opus 4.7 high judgment + MiniMax-M2.7-highspeed Token Plan execution.
```

## Contract

- This is a power-user convenience route, not the default.
- Use it when Opus is exhausted, scarce, or intentionally being saved.
- Keep `/opusworkflow` as the primary route when Opus 4.7 judgment is available
  and worth spending.
- Treat this as the exact governed equivalent of:

```text
/opusworkflow "task" --model-profile sonnetminimax --effort max
```

- Preserve all `/opusworkflow` gates: research, code audit, `/introspect`,
  Agent-Native Estimate, `SPEC.md`, `/specqa`, bounded implementation,
  verification, and closeout as verified, partial, or blocked-with-repair.
- Do not claim Sonnet 4.6 planned, reviewed, or verified unless `/status`, a
  runtime sentinel, or a durable artifact proves current account identity.
- Do not claim MiniMax execution happened unless a real executor packet or
  provider artifact proves it.
- Keep MiniMax as `MiniMax-M2.7-highspeed` from the MiniMax Token Plan. Do not
  silently use another MiniMax tier, a generic MiniMax model, or unproven
  higher concurrency.
- Default MiniMax executor concurrency remains conservative until provider or
  runtime evidence proves a higher safe ceiling.
- Do not read `.env`, `.env.*`, `.claude/settings.local.json`,
  `.claude/*.local.json`, `secrets/**`, private credentials, customer artifacts,
  or MiniMax key files.

## Command

Prepare artifacts through the wrapper:

```bash
bash scripts/sonnetminimaxworkflow.sh --task "$ARGUMENTS"
```

Runtime planner execution remains explicit:

```bash
bash scripts/sonnetminimaxworkflow.sh --task "$ARGUMENTS" --execute-planner
```

Equivalent static artifact preparation:

```bash
bash scripts/opusworkflow.sh --task "$ARGUMENTS" --model-profile sonnetminimax --effort max
```

## When To Use

Use `/sonnetminimax` when:

- Opus quota is exhausted or close to exhausted.
- The work still needs governed planning/review but Sonnet is good enough.
- You want MiniMax-M2.7-highspeed Token Plan to keep doing the bulk execution.
- You want one short slash command instead of remembering model-profile flags.

Use `/opusworkflow` when:

- Opus 4.7 judgment is available and the task deserves the main route.
- You want the default harness strategy.
- You are doing high-risk planning, adversarial review, or final ship/no-ship.

## Anti-Patterns

- Treating `/sonnetminimax` as evidence that Sonnet actually ran.
- Letting MiniMax leak into planner settings.
- Using `--model-profile sonnet` when you intended MiniMax execution.
- Presenting this as the main route. The main route remains `/opusworkflow`.
