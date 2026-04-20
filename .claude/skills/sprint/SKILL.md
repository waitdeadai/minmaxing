# /sprint

Parallel execution with up to 10 agents and FILE ISOLATION. Each agent works on different files to prevent merge conflicts. Context isolation per agent.

**Default: 10 agents** (configurable via `MAX_PARALLEL_AGENTS` env var)

**Use when:** User says "sprint this", "parallel this", "run in parallel", "split this up".

**FILE ISOLATION is mandatory.** Parallel only when agents touch different files.

---

## Purpose

Achieve parallel speedup without merge conflicts. Realistic speedup ~1/(N × 0.7), not theoretical 1/N.

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

### Step 1: Task Analysis

```markdown
## Sprint Plan: [Feature Name]

### Can Parallelize?
- Total tasks: [N]
- Parallelizable tasks: [M]
- Sequential tasks: [K]

### File Isolation Check
For each parallel task:
- Task 1: Files [list] → ISOLATED / CONFLICT
- Task 2: Files [list] → ISOLATED / CONFLICT
...

### If Conflicts Exist
- Rearrange tasks to avoid file overlap
- OR run conflicting tasks sequentially
```

**FILE ISOLATION is mandatory.** If two tasks touch the same file, they cannot run in parallel.

### Step 2: Task Distribution

```markdown
## Sprint Distribution

### Agent 1: [Task 1]
- Files: [file list]
- Context: [clean context for this task]
- Goal: [specific deliverable]

### Agent 2: [Task 2]
- Files: [file list]
- Context: [clean context for this task]
- Goal: [specific deliverable]
...

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
- Forcing parallel when sequential makes sense → WARN
- Over-parallelizing (10 agents for simple tasks) → WARN
- Not checking file isolation → BLOCK
