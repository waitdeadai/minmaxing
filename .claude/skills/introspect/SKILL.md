# /introspect

Hard-gate self-audit mode. Use this when the model must actively find its own likely mistakes before confidence is allowed.

**MAX_PARALLEL_AGENTS** — ceiling for introspection lanes. Split only across distinct risk surfaces that materially improve the self-audit.

**Use when:** The user asks for introspection, self-audit, "find your mistakes", "challenge your plan", or when the workflow reaches a required introspection trigger.

**Alias:** `/instrospect` routes here for compatibility with the requested spelling.

---

## Core Contract

`/introspect` is not a normal review and not a summary.

It must:
- name concrete likely mistakes
- cite the evidence checked
- audit assumptions
- look for counterexamples
- compare implementation against `SPEC.md`
- identify missing verification
- downgrade confidence when evidence is weak
- block closeout when unresolved findings remain

The default posture is adversarial toward the model's own last answer, plan, implementation, or verification claim.

## Trigger Modes

- `pre-plan` — after research and code audit, before the plan or `SPEC.md` is frozen
- `post-implementation` — after files change, before accepting the implementation as ready
- `after-test-failure` — after any failed verification, before trying the same fix path again
- `pre-push` — before commit, push, ship, deploy, or any remote-facing action
- `manual` — when invoked directly by the user

For file-changing `/workflow` runs, `pre-plan` and `post-implementation` are mandatory. `after-test-failure` is mandatory after any failed test or verification check. `pre-push` is mandatory when remote actions are requested or recommended.

## Effective Budget

Choose the smallest useful introspection wave:

```text
effective_introspection_budget = min(MAX_PARALLEL_AGENTS, distinct_risk_surfaces, reviewer_capacity)
```

Typical lanes:
- assumptions and hidden requirements
- spec / plan / implementation mismatch
- missing tests or weak verification
- security / privacy / rollback risk
- concurrency / state / migration risk
- documentation or user-facing promise drift

Do not fill the pool just to look thorough. A tiny local change can use one concise lane when the evidence is simple.

## Execution Protocol

1. Identify the trigger mode.
2. Gather the evidence:
   - user request
   - active `SPEC.md`
   - workflow artifact when present
   - current diff or changed files
   - test output or verification evidence
   - relevant docs or source ledger when research drove the plan
3. List the model's most likely mistakes.
4. Check each mistake against evidence.
5. Look for counterexamples and omitted cases.
6. Decide whether confidence should be downgraded.
7. Return a blocker decision:
   - `PASS` — no unresolved issues remain
   - `FIX_REQUIRED` — issues found and must be fixed before continuing
   - `REPLAN_REQUIRED` — the plan or spec is wrong
   - `BLOCKED` — external input or unavailable evidence prevents a safe decision

## Output

```markdown
## Introspection: [trigger mode]

### Evidence Checked
- ...

### Likely Mistakes
| Risk | Evidence Checked | Result |
|------|------------------|--------|

### Assumption Audit
- ...

### Counterexamples / Missing Edges
- ...

### Spec / Diff / Verification Mismatch
- ...

### Confidence
- Level: [high / medium / low]
- Downgrade: [none / reason]

### Blocker Decision
[PASS / FIX_REQUIRED / REPLAN_REQUIRED / BLOCKED]
```

## Quality Gates

- every finding must point to concrete evidence
- missing tests must be named, not hand-waved
- unresolved blockers must stop the workflow
- confidence must be lowered when evidence is incomplete
- remote actions require a `pre-push` introspection pass
- failed verification requires an `after-test-failure` pass before another fix attempt

## Anti-Patterns

- "looks good" without naming likely mistakes
- restating the plan instead of attacking it
- treating `/review` as a substitute for self-audit
- ignoring failed tests and trying the same fix again
- pushing or closing out with unresolved introspection blockers
