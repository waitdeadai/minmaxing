# Delegation Rules (80/20)

## The 80/20 Principle (Karpathy "Manifesting")

- **80%** of throughput can come from well-chosen delegated packets and strong macro review
- **20%** still belongs to architecture decisions, security reviews, quality gating, and synthesis

**Goal:** State intent → break into bounded objectives → delegate only the truly independent ones → review at macro level

## What to Delegate

Safe to delegate — mechanical, bounded tasks:

- Single file changes
- Test writing and execution
- Documentation updates
- Mechanical refactoring (renaming, formatting)
- Bug fixes (with root cause identified)
- Configuration changes
- Code formatting/linting
- Data migration scripts
- Boilerplate code generation

Usually keep local instead of delegating:

- Quick targeted edits where spawning would cost more than doing
- Tightly coupled multi-file changes with one shared reasoning loop
- Work that needs frequent back-and-forth with the parent thread
- Anything without clear file or surface ownership

## What to KEEP (Never Delegate)

Requires human judgment — never delegate:

- **SPEC.md creation** — defining what to build
- **Architecture decisions** — how components connect
- **Security reviews** — authentication, authorization, data handling
- **Verification decisions** — does output match spec?
- **Quality gate enforcement** — blocking on failures
- **Scope negotiation** — what to include/exclude
- **Verification against spec** — use /verify skill
- **Complex multi-file refactors** — requires understanding
- **Parallel substrate selection** — the main orchestrator chooses local, subagents, parallel-instances, or experimental agent-teams after capacity and ownership checks
- **Packet aggregation** — the main orchestrator reconciles worker evidence, conflicts, sync barriers, and final status

## Delegation Protocol

### 1. Define Clear Task
- SPEC.md exists and is approved
- Success criteria are verifiable
- Definition of done is clear

### 2. Provide Clean Context
- Only pass what's needed for this task
- No stale context from other tasks
- File boundaries are clear
- Dependencies and stop conditions are explicit
- If the packet does not have a clear owner, do not delegate it

### 3. Delegate with Instructions
```
Task: [specific description]
Owned files/surfaces: [list]
Do not touch: [list]
Context: [thin, relevant context only]
Dependencies: [what must already be true]
Estimated duration: [optimistic / likely / pessimistic]
Estimate confidence: [high|medium|low with reason]
Success: [definition of done]
Verify: [how to verify completion]
Stop if: [overlap, missing dependency, stale assumptions]
```

### 4. Verify Output (Mandatory)
- Never skip verification
- Use /verify skill against SPEC.md
- Accept or reject with specific feedback

### 4.5. Aggregate Parallel Output
- For `/parallel`, workers return evidence; they do not decide readiness.
- The main orchestrator checks packet DAG dependencies, ownership matrix, sync barriers, capacity budget, and aggregate verification.
- The main orchestrator estimates elapsed time from the longest dependency path,
  not summed packet effort or linear lane scaling.
- If two packets conflict, stop and reconcile in the main thread instead of asking workers to negotiate authority.

### 5. Accept or Reject
- **Accept:** All criteria met, evidence provided
- **Reject:** Specific failures listed, fix required

## Effective Delegation

| Condition | Action |
|-----------|--------|
| One task per agent | Yes |
| Clear file boundaries | Yes |
| Clear ownership | Yes |
| Verifiable definition of done | Yes |
| Isolated context | Yes |
| Mandatory verification | Yes |
| Independent from sibling packets | Yes |

## Anti-Patterns

- Delegating without SPEC.md → BLOCK
- Not verifying delegate output → BLOCK
- Delegating architecture decisions → BLOCK
- Delegating quality gate enforcement → BLOCK
- Over-delegating (losing oversight) → WARN
- Delegating vague tasks → BLOCK
- Delegating the same file to multiple agents in one wave → BLOCK
- Delegating when no bounded independent packet exists → BLOCK
