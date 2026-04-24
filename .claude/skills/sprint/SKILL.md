# /sprint

Parallel execution with up to `MAX_PARALLEL_AGENTS` agents and strict FILE OWNERSHIP. Each agent works on different files or surfaces to prevent merge conflicts and context thrash.

**MAX_PARALLEL_AGENTS** — ceiling for parallel task execution. Use the smallest effective wave that fits independent work packets.

**Use when:** User says "sprint this", "parallel this", "run in parallel", "split this up", "swarm sprint".

**Swarm:** "swarm sprint" → `/sprint` with an efficacy-first execution wave up to `MAX_PARALLEL_AGENTS`.

**FILE ISOLATION is mandatory.** Parallel only when agents touch different files.

---

## Purpose

Achieve parallel speedup without merge conflicts. Use as many agents as there are independent, ownership-clear work packets. The supervisor's job is to shorten the critical path, not to maximize slot utilization.

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

### Step 0.5: Memory Recall (Before Planning)

Recall similar past sprints to inform task breakdown:

```bash
# Recall similar past sprint patterns
bash scripts/memory.sh recall "[sprint feature type]" --depth simple 2>/dev/null || echo "Memory recall: skipped"

# Check for procedural patterns
bash scripts/memory.sh search "sprint" 2>/dev/null || true
```

### Step 1: Task Analysis — Choose the Effective Budget

**Rule: Do not split work just to fill slots.**

For example, a "calculator module" is not automatically a 10-agent sprint:
- If all operations live in one file or one reasoning loop, keep it local or use a tiny wave
- Only split it if operations, tests, docs, or adapters truly have separate ownership and can return independently

```markdown
## Sprint Plan: [Feature Name]

### Agent Pool
- Ceiling: [MAX_PARALLEL_AGENTS]
- Effective Budget: [N]
- Why: [independent packets that justify N]

### Task Breakdown
- Task 1: [granular task] → Owned Files: [list]
- Task 2: [granular task] → Owned Files: [list]
- Task 3: [granular task] → Owned Files: [list]

### File Isolation Check
For each task:
- Task 1: Files [list] → ISOLATED / CONFLICT
- Task 2: Files [list] → ISOLATED / CONFLICT
...

### If < [N] Tasks
- Lower the effective budget
- Keep tightly coupled work in the parent thread
- Only split further when ownership remains clean
```

**FILE ISOLATION is mandatory.** If two tasks touch the same file, they cannot run in parallel.

### Step 2: Task Distribution

```markdown
## Sprint Distribution

### Agent 1: [Task 1]
- Owned files: [file list]
- Do not touch: [file list]
- Context: [thin current context for this task]
- Dependencies: [what must already be true]
- Freshness checkpoint: [when to stop and re-sync]
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
claude -p "Execute Task 1: [details]. Files you own: [list]. Return only a concise result summary." > agent1.out 2>&1 &

# Agent 2
claude -p "Execute Task 2: [details]. Files you own: [list]. Return only a concise result summary." > agent2.out 2>&1 &

# ... up to the effective budget

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
- Inflating the wave with synthetic task splitting → BLOCK
- Not checking file isolation → BLOCK

---

## Chain Contract

**This skill is an execution playbook.** `/workflow` may reuse this guidance, but it should not depend on invoking `/sprint` as a guaranteed nested continuation step.

When invoked directly by the user, stop after implementation is complete and summarize what changed.

When `/workflow` references this skill, the parent workflow continues inline and decides the next phase.
