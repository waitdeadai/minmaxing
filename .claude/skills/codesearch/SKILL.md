---
name: codesearch
description: Search the local codebase for patterns, symbols, implementations, and references. Use when the user wants to find where code lives or understand how a pattern is implemented without invoking the OpenAI Codex plugin namespace.
---

# /codesearch

Code search and pattern understanding across the codebase.

**MAX_PARALLEL_AGENTS** — ceiling for search lanes. Split search only across independent directories or patterns that meaningfully reduce search time.

**Use when:** User says "find code", "search code", "where is this implemented", "grep this", "swarm codesearch", or needs to find patterns across the codebase.

**Swarm:** "swarm codesearch" → `/codesearch` with an efficacy-first search wave up to `MAX_PARALLEL_AGENTS`.

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
# Use fast local search tools
rg -n "[pattern]" .

# For complex searches, spawn parallel agents
claude -p "Search for [pattern] in codebase. Report file paths and line numbers." > codesearch-results.out 2>&1 &
```

### Step 3: Store Found Patterns

After successful pattern discovery, store for future recall:

```bash
# Store successful pattern as procedural memory
bash scripts/memory.sh add procedural "[file]: [found pattern description]" --tags "code-pattern,[language]"
```

### Step 4: Final Output

```markdown
## Codesearch Results: [Search Pattern]

### Files Found
- [file:line] — [brief description]
- [file:line] — [brief description]

### Stored to Memory
- [pattern description] → procedural tier
```
