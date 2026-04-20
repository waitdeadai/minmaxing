---
description: Parallel agent supervisor - spawns workers for parallel execution
---

# /workflow

**SUPERVISOR MODE** — AI acts as supervisor, spawning parallel worker agents for speed while ensuring production readiness.

**Use when:** User says "build X", "implement Y", "fix Z", or any substantial task.

---

## Research Findings (2026)

- **Hierarchical Pattern**: Supervisor decomposes → dispatches to workers → reviews results
- **Restricted Comms**: Workers only report to supervisor, not each other
- **Task Gating**: No task is "done" until tests pass
- **Isolated Execution**: Each worker has clean context, no pollution

---

## Supervisor Loop

### Phase 0: Memory Check
- Query `forgegod memory` for similar past tasks
- Apply what worked, avoid what failed

### Phase 0.5: Research First (MANDATORY)
- Verify AI claims with web search (training data is stale)
- Research APIs, libraries, error codes when task involves external dependencies

### Phase 1: Analyze & Decompose
**Supervisor analyzes SPEC.md and decomposes into parallelizable tasks:**

```markdown
## Task Decomposition: [Project Name]

### Supervisor Analysis
- Total tasks: [N]
- Parallelizable: [M] (different files)
- Sequential: [K] (dependencies)

### Worker Pool
- Worker 1: [Task 1] → Files: [list]
- Worker 2: [Task 2] → Files: [list]
...
- Worker M: [Task M] → Files: [list]

### Sequential Gate
- [Task K1] must complete before [Worker 2] starts
```

### Phase 2: Spawn Parallel Workers

**For each parallel task, spawn a worker:**

```bash
# Worker execution (isolated context)
claude -p "Execute Task [N]: [description]
Files to modify: [file list]
Success criteria: [from SPEC.md]
Return results when complete." \
  --context-task task-[n].json > worker-[n].out 2>&1 &
```

**FILE ISOLATION RULE**: Workers can ONLY modify their assigned files. If two tasks touch the same file, they cannot run in parallel — sequential required.

### Phase 3: Aggregate & Verify

**Supervisor waits for all workers, then:**

1. Check each worker's output
2. Verify all modified files against SPEC.md criteria
3. Run test suite (if exists)
4. Any failure → invoke /investigate (3-fix limit)

### Phase 4: Production Gate

**Before marking complete, supervisor verifies:**

- [ ] All SPEC.md criteria met
- [ ] Tests pass (or written if none existed)
- [ ] No lint errors
- [ ] No file conflicts between workers
- [ ] Production-ready output

### Phase 5: Route to User

```
## Implementation Complete

### Workers Completed: [M/M]
### Production Gate: PASS/FAIL
### Files Modified: [list]

[If FAIL: specific blockers listed]
[If PASS: ready for /review]
```

---

## Standard Mode (without /workflow)

When coding without explicit /workflow:

1. **Supervisor always active** — You are the supervisor
2. **Spawn workers for parallel tasks** — Use `/sprint` when ≥3 independent tasks
3. **Worker rule**: Each worker = 1 file or 1 feature, never shared files
4. **Tests gate completion** — Worker must verify tests pass before reporting done

---

## Anti-Patterns (BLOCK)

- Workers modifying shared files → BLOCK (conflicts)
- Skipping research on external deps → BLOCK
- Marking done without tests passing → BLOCK
- Workers communicating directly → BLOCK (supervisor only)
- Ignoring file conflicts → BLOCK
