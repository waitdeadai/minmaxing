---
name: metacognition
description: Route and calibrate work with model-agnostic metacognitive control. Use when the user asks for thinking-about-thinking, harness effectiveness, task routing, self-correction, confidence calibration, or strategy improvement before execution.
argument-hint: [task]
disable-model-invocation: true
---

# /metacognition

Steered metacognition mode for:

$ARGUMENTS

`/metacognition` is the harness-level control plane for thinking about the
work, not a replacement executor.

It classifies the task, chooses the smallest useful reasoning and verification
budget, accounts for parallel capacity, records evidence requirements, and
routes to the existing harness command that should do the work.

It does not replace `/workflow`; it steers `/workflow`.
It does not replace `/introspect`; `/introspect` remains the canonical hard-gate
self-audit command.

## Core Contract

Metacognition is useful only when it is evidence-grounded.

It must:

- classify the task before choosing a route
- inspect or cite capacity evidence before deciding parallelism
- treat `MAX_PARALLEL_AGENTS`, Codex `max_threads`, and hardware ceiling as
  ceilings, not quotas
- name required evidence before confidence is allowed
- treat model self-reports as candidate evidence, not ground truth
- avoid depending on raw hidden chain-of-thought or provider-specific thinking
  blocks
- downgrade confidence when sources, tests, repo evidence, credentials, or
  runtime proof are missing
- route execution to existing commands instead of becoming a second workflow
  engine

## Task Classes

Choose exactly one:

| Task Class | Use When | Route |
| --- | --- | --- |
| `answer` | direct answer, no repo mutation, no current facts required | answer directly |
| `webresearch` | narrow current fact check | `/webresearch` |
| `deepresearch` | landscape, architecture, due diligence, strategic research | `/deepresearch` |
| `workflow` | repo-changing build/fix/refactor/docs/config work | `/workflow` |
| `parallel` | dense independent packets with clear ownership and verification | `/parallel` |
| `agentfactory` | governed Hermes agent creation or runtime-bound agent design | `/agentfactory` |
| `verify` | check an output against `SPEC.md` | `/verify` |
| `introspect` | hard-gate self-audit or confidence challenge | `/introspect` |
| `blocked` | credentials, policy, source truth, safety, or approval is missing | stop and state blocker |

## Capacity Evidence

Every metacognitive run must inspect or cite current capacity evidence:

```bash
bash scripts/parallel-capacity.sh --json 2>/dev/null || true
```

If the command is unavailable, use the conservative path and say capacity
evidence is unavailable.

## Effective Parallel Budget

Compute:

```text
effective_metacognition_budget =
  min(MAX_PARALLEL_AGENTS, codex_max_threads, hardware_recommended_ceiling,
      independent_questions_or_packets, supervisor_capacity, verifier_capacity)
```

Use the smallest useful budget:

- `1` lane: tightly coupled work, one file/surface, or one decision loop
- `2-4` lanes: independent research tracks, risk review, or code-path exploration
- `5+` lanes: broad audits, dense planning, independent packet DAGs, or
  multi-surface verification

Never claim that max agents means max quality. Never claim linear speedup such
as "10 agents means 10x faster."

## Required Output

```markdown
## Task Class
[answer / webresearch / deepresearch / workflow / parallel / agentfactory / verify / introspect / blocked]

## Capacity Evidence
- Source: [`scripts/parallel-capacity.sh --json` output, repo config, or unavailable]
- MAX_PARALLEL_AGENTS: [value or unknown]
- Codex max_threads: [value or unknown]
- Hardware ceiling: [value or unknown]

## Effective Parallel Budget
- MAX_PARALLEL_AGENTS: [value or unknown]
- Codex max_threads: [value or unknown]
- Hardware ceiling: [value or unknown]
- Independent lanes available: [number]
- Effective budget: [number]
- Decision: [local / subagents / parallel / blocked]
- Reason: [why this is the smallest useful budget]

## Reasoning Budget
[low / medium / high / xhigh] as harness effort, not hidden chain-of-thought

## Evidence Required
- [repo files, source ledger, tests, runtime proof, human approval, credentials, or blocked input]

## Metacognitive Audits
- Assumption audit: ...
- Source/evidence audit: ...
- Scope audit: ...
- Verification audit: ...
- Risk audit: ...
- Estimate audit: ...

## Route Decision
- Route: [/workflow, /deepresearch, /parallel, /agentfactory, /verify, /introspect, direct answer, or blocked]
- Reason: ...

## Confidence
- Level: [high / medium / low]
- Downgrade: [none / reason]
```

## Route Behavior

- If effective budget is `1`, continue local.
- If effective budget is `2+` for research only, split independent
  research/risk tracks.
- If implementation packets are independent and file ownership is clear,
  recommend `/parallel`.
- If packets overlap or verification cannot aggregate results, downgrade to
  local `/workflow`.
- If capacity evidence is unavailable, choose a conservative budget and state
  the downgrade.

## Workflow Integration

When `/workflow` handles file-changing work, record a compact
`## Metacognitive Route` section before `## Research Brief` in the workflow
artifact. It must include:

- task class
- capacity evidence
- effective parallel budget
- chosen route
- evidence required
- confidence threshold
- why the full parallel ceiling was or was not used

## Quality Gates

The metacognitive route must fail or block when:

- task class is missing
- effective parallel budget is missing
- max agents are treated as a quota
- reflection is not tied to evidence
- hidden/raw chain-of-thought is required
- model self-report is promoted without verified outcome
- confidence is high while evidence is missing
- unresolved blockers are followed by positive closeout

Use `bash scripts/metacognition-scorecard.sh --fixtures --json` to prove the
static contract.

## Anti-Patterns

- "I reflected and it seems good" without evidence
- using `/metacognition` as a second implementation engine
- treating `/review` or `/metacognition` as a substitute for `/introspect`
- using all parallel lanes because they exist
- scoring raw hidden chain-of-thought
- promoting self-reported lessons into memory without verified outcomes
