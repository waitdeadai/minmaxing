---
name: opusolo
description: Run the optional all-Opus sibling of /opusworkflow. Use when the operator explicitly wants Opus 4.7 as planner, executor, reviewer, and final judge with default high effort and optional max effort.
argument-hint: [task] [--effort high|max]
disable-model-invocation: true
---

# /opusolo

Run the all-Opus governed workflow for:

$ARGUMENTS

Mode banner:

```text
/opusolo is /opusworkflow with model_profile=opus.
Opus 4.7 is requested for planning, execution, Spec QA, adversarial review, and final judgment.
Default effort is high.
Use --effort max when the operator explicitly wants the highest available Claude CLI effort.
MiniMax is not required for this route.
```

## Contract

- `/opusolo` is an explicit premium route, not the default. The default
  `/opusworkflow` remains Opus judgment plus MiniMax execution for cost-aware
  governed work.
- It keeps the same `/opusworkflow` lifecycle: research brief, code audit,
  `/introspect pre-plan`, Agent-Native Estimate, `SPEC.md`, `/specqa`,
  implementation, verification, post-implementation `/introspect`, and
  verified/partial/blocked-with-repair closeout.
- It is equivalent to `/opusworkflow --model-profile opus --executor-provider
  anthropic --planner-model claude-opus-4-7 --executor-model claude-opus-4-7`
  plus an effort setting.
- Default effort is `high`. `--effort max` is accepted as the operator-facing
  alias for the highest available Claude CLI effort; static artifacts record
  both the requested alias and the CLI value used.
- Runtime identity still needs proof from `/status`, a sentinel, or the run
  artifact. Static profile selection is not proof that Opus actually ran.
- Do not silently downgrade to Sonnet, MiniMax, default, or PAYG behavior. If
  Opus is unavailable, block and report repair steps.
- Do not use this for cheap bulk work by default. Use it when the task justifies
  all-Opus judgment and execution cost: high-stakes architecture, difficult
  refactors, critical safety/security changes, or user-explicit premium runs.
- Do not read `.env`, `.env.*`, `.claude/settings.local.json`,
  `.claude/*.local.json`, `secrets/**`, private credentials, customer artifacts,
  or MiniMax key files.

## Command

Prepare artifacts with default high effort:

```bash
bash scripts/opusoloworkflow.sh --task "$ARGUMENTS"
```

Prepare artifacts with max effort:

```bash
bash scripts/opusoloworkflow.sh --task "$ARGUMENTS" --effort max
```

Runtime planner execution remains explicit:

```bash
bash scripts/opusoloworkflow.sh --task "$ARGUMENTS" --effort high --execute-planner
```

## Install

Clean/new folder:

```bash
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --mode opusolo
```

Existing project or harness update:

```bash
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --import-existing --mode opusolo
```

Then run:

```bash
claude
/opusolo "build or fix the thing"
/opusolo "build or fix the thing" --effort max
```

Equivalent static artifact preparation:

```bash
bash scripts/opusworkflow.sh --task "build or fix the thing" --model-profile opus --executor-provider anthropic --effort high
```

## Anti-Patterns

- Presenting `/opusolo` as the cost-aware default.
- Claiming Opus runtime identity without current account/runtime evidence.
- Allowing MiniMax base URLs, MiniMax model IDs, or Sonnet executor IDs inside
  an all-Opus artifact.
- Using `--effort max` as a default, hidden fallback, or CI requirement.
- Treating all-Opus execution as a replacement for `/specqa`, `/introspect`,
  `/verify`, release checks, source ledgers, or parent verification.
