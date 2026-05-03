# Metacognition Rules

Metacognition is the harness thinking about its own task selection, evidence,
confidence, and verification. It is not private chain-of-thought exposure and it
is not vague self-reflection.

## Evidence-Grounded Reflection

- Treat model self-reports as candidate evidence only.
- Tie every confidence claim to repo evidence, source ledger entries, command
  evidence, runtime proof, or an explicit blocker.
- Reject reflection that only says "I thought about it", "seems right", or
  "looks good" without concrete evidence.
- Downgrade confidence when evidence is weak, stale, unavailable, or inferred.

## Parallel-Aware Routing

- Always consider parallelism before route selection.
- Read or cite `bash scripts/parallel-capacity.sh --json 2>/dev/null || true`
  when capacity materially affects the route.
- Treat `MAX_PARALLEL_AGENTS`, Codex `max_threads`, and hardware ceiling as
  ceilings, not quotas.
- Use the smallest effective budget that improves the outcome.
- Never claim linear speedup or that max agents means max quality.

## Command Boundary

- `/metacognition` decides route, evidence needs, capacity budget, and
  confidence threshold before execution.
- `/introspect` is the hard-gate audit that decides whether a plan, diff,
  verification claim, or closeout can continue.
- Do not present `/metacognition` as replacing, satisfying, or skipping a
  required `/introspect` trigger.
- When `/metacognition` routes to `/introspect`, record that as a handoff and
  require `/introspect` to produce the blocker decision.

## Raw Chain-Of-Thought Boundary

- Do not depend on raw hidden chain-of-thought.
- Do not require provider-specific thinking blocks for correctness.
- Monitor visible artifacts instead: task class, evidence requirements,
  assumptions, source ledger, verification commands, blocker decisions, and
  confidence downgrades.

## Verified Learning

- Do not promote lessons to durable memory or prompt-contract changes unless
  verified evidence proves the lesson.
- A failed verification can produce a candidate lesson, but the lesson must
  record the failure and cannot be framed as success.
- Worker summaries, model self-reports, and external AI reports remain claims
  until parent verification or source/repo evidence confirms them.

## Required Metacognitive Audits

Every `/metacognition` run or workflow metacognitive route must include:

- task classification
- capacity evidence
- effective parallel budget
- evidence required
- assumption audit
- source/evidence audit
- scope audit
- verification audit
- risk audit
- estimate audit
- route decision
- confidence level and downgrade reason
