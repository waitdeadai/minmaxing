# /overnight

Extended 8-hour session with 30-minute checkpoints. Results consolidated at end. Auto-resume capability.

**MAX_PARALLEL_AGENTS** — spawns up to 10 parallel agents for long-running task decomposition.

**Use when:** User says "overnight this", "run overnight", "extended session", "long running task".

**Checkpoints every 30 minutes.** No more than 30 minutes of work at risk.

**Swarm:** "swarm overnight" → `/overnight` with 10 parallel agents for long-running tasks.

---

## Purpose

Execute long-running tasks that exceed normal session time. Checkpoints prevent losing progress.

---

## Execution Protocol

### PHASE 0: Taste & Memory Check

**MANDATORY GATE — Read taste files and recall memory before starting.**

```bash
# Check taste files exist
if [ ! -f "taste.md" ] || [ ! -f "taste.vision" ]; then
  echo "WARNING: taste.md or taste.vision missing — invoke /tastebootstrap first"
fi

# Read taste files
cat taste.md 2>/dev/null || echo "taste.md: not found"
cat taste.vision 2>/dev/null || echo "taste.vision: not found"

# Recall past overnight sessions
bash scripts/memory.sh recall "overnight session" --depth simple 2>/dev/null || echo "Memory recall: skipped"

# Log session start
bash scripts/memory.sh add episodic "Overnight session started: [project/feature description]"
```

### Step 1: Define Work Items

```markdown
## Overnight Sprint: [Project/Feature]

### Work Items
1. [Task 1] — [expected time]
2. [Task 2] — [expected time]
3. [Task 3] — [expected time]

### Checkpoint Schedule
- Checkpoint 1: [time + 30 min]
- Checkpoint 2: [time + 60 min]
- Checkpoint 3: [time + 90 min]
...

### Success Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
```

### Step 2: Execute with Checkpoints

```bash
# Execute work item 1
echo "Starting work item 1 at $(date)"
[work]

# Checkpoint 1
echo "Checkpoint 1 at $(date)" >> overnight-checkpoints.log
git add -A && git commit -m "Checkpoint 1: [summary]"

# Execute work item 2
echo "Starting work item 2 at $(date)"
[work]

# Checkpoint 2
echo "Checkpoint 2 at $(date)" >> overnight-checkpoints.log
git add -A && git commit -m "Checkpoint 2: [summary]"
...
```

### Step 3: 30-Minute Status Reports

Every 30 minutes, report:

```markdown
## Overnight Status: [timestamp]

### Current Work Item
[What is running]

### Progress
- Completed: [list]
- In Progress: [current item]
- Remaining: [list]

### Time Elapsed
- Total: [X] minutes
- On Track: [YES/NO]
- Adjustments needed: [if any]
```

### Step 4: Consolidation

At completion or session end:

```markdown
## Overnight Results: [Project]

### Work Completed
1. [Task 1] — [status]
2. [Task 2] — [status]
3. [Task 3] — [status]

### Checkpoints
- Checkpoint 1: [commit hash] — [summary]
- Checkpoint 2: [commit hash] — [summary]
- Checkpoint 3: [commit hash] — [summary]

### Issues Encountered
1. [Issue 1] — resolved/not resolved
2. [Issue 2] — resolved/not resolved

### Next Steps
1. [What to do next]
2. [What to do next]

### Resume Point
- Commit: [hash]
- State: [what was in progress]
- How to resume: [command/instructions]
```

Log session end to memory:
```bash
bash scripts/memory.sh add episodic "Overnight session completed: [project] — [N] tasks done, [M] checkpoints"
python3 -c "
from memory.causal import record_outcome
factors = ['overnight_session', 'checkpoint_discipline', '8_hour_session']
record_outcome(factors, 'success')
" 2>/dev/null || echo "record_outcome: skipped"
```

---

## Quality Gates

- **Checkpoints must be committed** (not just written) → BLOCK
- **Status must be reported every 30 minutes** → BLOCK
- **Resume point must be clearly documented** → BLOCK
- **Cannot lose more than 30 minutes of work** → BLOCK
- **Must aggregate results** from all checkpoints → BLOCK

---

## Anti-Patterns

- No checkpoints for >30 min work → BLOCK
- Working without status updates → BLOCK
- No resume point documented → BLOCK
- Lost progress due to no checkpoint → BLOCK
- Abandoned sessions without final commit → BLOCK
