# /codex

Code search and pattern understanding across the codebase.

**MAX_PARALLEL_AGENTS** — spawns up to 10 parallel search agents across different directories simultaneously.

**Use when:** User says "codex this", "find code", "search code", "swarm codex", or needs to find patterns across the codebase.

**Swarm:** "swarm codex" → `/codex` with 10 parallel agents.

---

## Purpose

Find code patterns efficiently and store successful search patterns for future recall.

---

## Execution Protocol

### Step 1: Memory Recall (Before Search)

Recall similar past searches to leverage known patterns:

```bash
# Recall similar code patterns
bash scripts/memory.sh recall "[search topic]" --depth simple 2>/dev/null || echo "Memory recall: skipped"

# Search for procedural patterns
bash scripts/memory.sh search "[code pattern or function name]" 2>/dev/null || true
```

### Step 2: Execute Code Search

```bash
# Use grep or search tools
grep -r --include="*.py" --include="*.js" --include="*.ts" "[pattern]" .

# For complex searches, spawn parallel agents
claude -p "Search for [pattern] in codebase. Report file paths and line numbers." > codex-results.out 2>&1 &
```

### Step 3: Store Found Patterns

After successful pattern discovery, store for future recall:

```bash
# Store successful pattern as procedural memory
bash scripts/memory.sh add procedural "[file]: [found pattern description]" --tags "code-pattern,[language]"
```

### Step 4: Final Output

```markdown
## Codex Results: [Search Pattern]

### Files Found
- [file:line] — [brief description]
- [file:line] — [brief description]

### Stored to Memory
- [pattern description] → procedural tier
```
