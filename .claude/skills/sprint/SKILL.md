# /sprint

Parallel execution with up to 10 agents and FILE ISOLATION. Each agent works on different files to prevent merge conflicts. Context isolation per agent.

**Default: 10 agents** (configurable via `MAX_PARALLEL_AGENTS` env var)

**Use when:** User says "sprint this", "parallel this", "run in parallel", "split this up", "swarm this", "swarm".

**FILE ISOLATION is mandatory.** Parallel only when agents touch different files.

---

## Purpose

Achieve parallel speedup without merge conflicts. **Always use the full agent pool.** Break tasks into MORE granular pieces to fill all 10 agents. The supervisor's job is to maximize parallelism, not just use "what fits naturally."

---

## Execution Protocol

### Step 0: Read Agent Pool Size

Read `MAX_PARALLEL_AGENTS` from env (default: 10):

```javascript
const MAX_AGENTS = process.env.MAX_PARALLEL_AGENTS || 10;
```

**System presets** (set in `~/.claude/settings.json` env):
| Hardware | MAX_PARALLEL_AGENTS |
|----------|---------------------|
| 32GB+ RAM, 8+ cores | 10 (default) |
| 16GB RAM, 4+ cores | 6 |
| 8GB RAM, 2+ cores | 3 |
| Low-end hardware | 2 |

To configure: add to `settings.json`:
```json
{
  "env": {
    "MAX_PARALLEL_AGENTS": "6"
  }
}
```

### Step 1: Task Analysis — MAXIMIZE PARALLELISM

**Rule: Break tasks into MORE granular pieces to fill all 10 agents.**

For example, a "calculator module" is NOT 2 tasks:
- It could be 10 tasks: add, subtract, multiply, divide, error handling, tests for each, etc.

```markdown
## Sprint Plan: [Feature Name]

### Agent Pool: [N] agents (fill all slots)

### Task Breakdown (targeting full agent pool)
- Task 1: [granular task] → Files: [list]
- Task 2: [granular task] → Files: [list]
- Task 3: [granular task] → Files: [list]
... (fill all [N] agents)

### File Isolation Check
For each task:
- Task 1: Files [list] → ISOLATED / CONFLICT
- Task 2: Files [list] → ISOLATED / CONFLICT
...

### If < [N] Tasks
- Break existing tasks into smaller units
- Split by: function, test suite, error case, edge case, documentation
- NEVER leave agents idle when tasks remain
```

**FILE ISOLATION is mandatory.** If two tasks touch the same file, they cannot run in parallel.

### Step 2: Task Distribution

```markdown
## Sprint Distribution (using all [N] agents)

### Agent 1: [Task 1]
- Files: [file list]
- Context: [clean context for this task]
- Goal: [specific deliverable]

### Agent 2: [Task 2]
...
### Agent [N]: [Task N]

### Aggregator
- Waits for all agents
- Combines results
- Verifies no conflicts
- Reports final status
```

### Step 3: Execute Parallel Agents

```bash
# Launch agents in parallel (example structure)
# Agent 1
claude -p "Execute Task 1: [details]" --context context1.json > agent1.out 2>&1 &

# Agent 2
claude -p "Execute Task 2: [details]" --context context2.json > agent2.out 2>&1 &

# ... up to 10 agents

# Wait for all
wait
```

### Step 4: Aggregate Results

```markdown
## Sprint Results

### Agent 1
- Status: SUCCESS/FAILED
- Output: [summary]
- Files touched: [list]

### Agent 2
- Status: SUCCESS/FAILED
- Output: [summary]
- Files touched: [list]
...

### Conflicts Detected
- [YES/NO]
- If YES: [describe conflict and resolution]

### Final Status
- Total: [N]
- Succeeded: [M]
- Failed: [K]

### Recommendation
- **[MERGE]** — All clean, ready to merge
- **[CONFLICTS]** — Conflicts detected, needs resolution
- **[PARTIAL]** — Some failed, review needed
```

---

## Quality Gates

- **FILE ISOLATION must be verified** before sprint → FAIL if conflicts
- **Each agent must have clean context** (no pollution) → FAIL
- **Aggregator must check for file conflicts** → FAIL if missed
- **Failed agents must be reported explicitly** → FAIL if hidden
- **Cannot proceed with unresolved conflicts** → BLOCK

---

## Anti-Patterns

- Parallel on same files → BLOCK (conflicts guaranteed)
- Shared context between agents → BLOCK (pollution)
- Ignoring failed agents → BLOCK
- Leaving agents idle when tasks remain → BLOCK (fill the pool)
- Not maximizing parallelism → BLOCK (break tasks more granularly)
- Not checking file isolation → BLOCK
