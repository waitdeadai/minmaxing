---
taste: spec
version: "2.1"
created: 2026-04-20
principles:
  - spec-first
  - research-first
  - evidence-backed-verification
experience:
  posture: calm-deliberate-trustworthy
  accessibility: inclusive-by-default
interfaces:
  contractStyle: explicit-and-stable
  stateBoundaries: single-owner-and-validated-at-the-edge
system:
  errorModel: structured-and-explainable
  observability: logs-metrics-traces-with-correlation-id
  security: least-privilege-and-explicit-boundaries
  rollback: reversible-and-evidence-backed
delivery:
  verification: separate-verifier-with-concrete-evidence
---

# Taste Spec

Define the operating kernel for this project. AI agents consult this before accepting output.

This kernel is not limited to frontend or backend work. It covers the principles, experience, contracts, system behavior, and delivery discipline that keep the whole project coherent.

## Overview

This kernel defines a correctness-first working system for minmaxing. The goal is not to force every repo into a frontend/backend mold. The goal is to make agents act with the same intent, discipline, and tradeoff posture whether they are touching docs, workflows, APIs, CLIs, automation, or user-facing surfaces.

The project should feel deliberate rather than improvised, explicit rather than magical, and inspectable rather than trust-me. We optimize for work that can be understood, verified, rolled back, and extended without guesswork.

## Design Principles

- SPEC-first: write the contract before code.
- Research-first: verify external claims with current sources before committing to a plan.
- Separate verifier from implementer: the PEV loop is mandatory for file-changing work.
- Correctness over speed: throughput matters only after the task is well understood.
- Explicit over implicit: interfaces, assumptions, and failure modes should be named clearly.
- Reusable systems over one-off cleverness: favor primitives and patterns that compound across sessions.
- Accessibility and clarity are not optional polish: humans should be able to understand what the system is doing.

## Experience & Interaction

### Voice & UX

The human experience should feel calm, direct, and trustworthy.

- Prefer concise, specific language over hype or vagueness.
- Make the system feel premeditated, not improvised in public.
- Show evidence, constraints, and decisions instead of hand-wavy reassurance.
- When the project has a UI, prefer structured, legible surfaces over decorative novelty.
- When the project is mostly CLI, workflow, or docs, the same standard applies: clarity first, friction only when it buys safety.

### Interaction Patterns

Default interaction behavior should reduce ambiguity.

- State transitions should be visible and named.
- Empty, loading, success, warning, and failure states should be explicit.
- Important flows should be decomposed into understandable phases.
- Prefer stable commands, predictable output shapes, and obvious next steps.
- Do not surprise users with hidden side effects, silent destructive behavior, or unexplained automation.

### Accessibility & Inclusion

Accessibility is part of correctness.

- Write copy that is scannable, plain-language, and calm under stress.
- Never rely on color alone to communicate status or required action.
- Keyboard reachability and visible focus remain mandatory for any interactive UI.
- Prefer naming and structure that welcome new contributors instead of insider shorthand.
- Optimize for users who are tired, context-switching, or debugging under pressure.

## Interfaces & Contracts

### Public Surfaces

Anything another human, process, or system depends on is a contract.

- APIs, CLIs, workflow commands, file formats, and generated artifacts should have stable, explicit shapes.
- Break behavior intentionally, never accidentally.
- Additive evolution is preferred over silent semantic drift.
- If a surface matters enough to expose, it matters enough to document and verify.
- Keep input/output conventions consistent across commands, scripts, and workflow artifacts.

### Data & State Boundaries

Ownership should be obvious.

- One subsystem should own one source of truth.
- Validate at boundaries, not only deep inside the implementation.
- Avoid hidden coupling between memory, workflow state, runtime output, and persistent artifacts.
- Preserve traceability when information crosses files, commands, or agents.
- Prefer reversible migrations and obvious state transitions over clever compactness.

## System Behavior

### Errors & Resilience

Failure should be modeled, not hand-waved.

- Prefer structured errors with concise human meaning and stable machine meaning.
- Timeouts, retries, and fallback behavior should be explicit in the plan.
- Mutating operations should consider idempotency and duplication risk where relevant.
- Do not leak implementation details or secrets through error output.
- When safety and convenience conflict, default to the safer behavior and explain the tradeoff.

### Observability & Operations

If the system matters, it must be debuggable.

- Emit evidence for meaningful state transitions and failures.
- Preserve correlation or run identifiers across workflow artifacts when possible.
- Prefer inspectable artifacts over ephemeral reasoning.
- Recurring operational questions should be answerable from logs, metrics, traces, or durable records.
- Debugging paths should be obvious enough that another engineer can reproduce the reasoning trail.

### Security & Privacy

Security should be boring, explicit, and preventative.

- Use least privilege and clear boundary ownership.
- Keep secrets out of committed config and out of human-readable error output.
- Make risky actions visible and intentional.
- Treat rollbackability as part of safety, not an afterthought.
- Avoid designs that depend on humans remembering invisible constraints.

## Code Style

- Prefer small, explicit units over sprawling abstractions.
- Name code for behavior and responsibility, not cleverness.
- Comments should explain why a decision matters, not restate syntax.
- Keep formatting and structure predictable enough that diffs are easy to scan.
- Favor maintainability and explanation quality over terseness.

## Architecture

- Separate orchestration from execution.
- Keep critical-path responsibilities owned by the command that promises them.
- Use specialist helpers when useful, but do not let the main workflow silently delegate away its contract.
- Prefer boundaries that reduce rollback risk and make testing surfaces clear.
- The architecture should make the correct path the easiest path for both humans and agents.

## Naming Conventions

- Use names that reveal intent and scope.
- Prefer stable verbs for commands and stable nouns for durable artifacts.
- Name workflow phases consistently across docs, logs, specs, and output.
- Avoid overloaded terms that mean different things in different files.
- If a name needs a paragraph to defend it, it is probably not the right name.

## Do's and Don'ts

### Do's

- Do force clarity before execution.
- Do preserve inspectable artifacts for meaningful work.
- Do make contracts, constraints, and success criteria explicit.
- Do bias toward reversible, evidence-backed changes.
- Do keep the kernel broad enough to fit many project shapes.

### Don'ts

- Don't treat taste as a frontend/backend questionnaire by default.
- Don't hide critical decisions inside implicit behavior.
- Don't optimize for shortest-path generation at the expense of recoverability.
- Don't collapse distinct system roles into one vague blob.
- Don't let the docs promise a flow the runtime contract does not enforce.
