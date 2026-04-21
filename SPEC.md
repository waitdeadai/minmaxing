# SPEC: minmaxing 5-Tier Memory System v2

## Problem Statement

Current memory system uses flat JSONL files + grep — search is O(n) file scan, no auto-capture, no learning. Need SQLite + FTS5 for fast search and causal graph tracking without replacing the bash interface.

## Success Criteria

- [ ] `memory search "api error"` returns results in <50ms on 1000+ memories
- [ ] `memory add error-solution "err" "fix"` persists to SQLite AND flat file (backward compat)
- [ ] Causal graph tracks: which factors correlate with success/failure
- [ ] `memory recall <task>` returns contextually relevant memories by complexity level
- [ ] Auto-consolidation runs every 24h: merges duplicates, decays confidence, caps growth
- [ ] All existing bash commands (`add`, `list`, `search`, `stats`) unchanged
- [ ] Episodic tier stays as JSONL (sessions/)

## Scope

### In Scope
- SQLite database with FTS5 full-text search for semantic + error-solution tiers
- Causal graph: tracks factor → outcome correlations
- Confidence decay with category-specific halflife
- Bash CLI unchanged; SQLite is internal implementation
- Auto-consolidation job (daily or every N memories)
- `memory recall` command for context injection

### Out of Scope
- LLM-powered MemoryAgent (too expensive, heuristic extraction is enough)
- Bidirectional Obsidian sync (projection only, write-only)
- Project-local vs global memory separation
- Migration of existing flat files to SQLite (new entries only)

## Architecture

```
memory.sh (bash CLI)
  │
  ├── add → writes to SQLite + flat file (dual write, SQLite source of truth for search)
  ├── search → SQLite FTS5 (fast)
  ├── list → flat files (human readable)
  ├── stats → SQLite counts + flat file counts
  └── recall → SQLite smart recall (adaptive depth)

SQLite (minmaxing memory.db)
  ├── semantic (FTS5) — principles, patterns, facts
  ├── error_solutions (FTS5) — error → fix mappings
  ├── causal_edges — factor → outcome weights
  └── memory_meta — key/value for consolidation state

Flat files (kept for backward compat + human readability)
  ├── obsidian/Memory/Decisions/*.md
  ├── obsidian/Memory/Patterns/*.md
  ├── obsidian/Memory/Errors/*.md
  └── .taste/sessions/*.jsonl
```

## Implementation Plan

### Phase 1: SQLite Foundation [PARALLEL: 3 agents]

- [ ] Task 1: `memory/sqlite_db.py` [PARALLEL]
  - SQLite class: init, schema creation, WAL mode, FTS5 setup
  - Tables: semantic, error_solutions, causal_edges, memory_meta
  - PRAGMAs: WAL, page cache, mmap, busy_timeout
  - Definition of Done: `python -c "from memory.sqlite_db import MemoryDB; db = MemoryDB(); print(db.stats())"` works

- [ ] Task 2: `memory/search.py` [PARALLEL]
  - FTS5 search with bm25 ranking on semantic + error_solutions
  - `search(query, tier, limit)` → ranked results
  - Definition of Done: `search("api error", tier="error-solution")` returns results in <50ms

- [ ] Task 3: `memory/recall.py` [PARALLEL]
  - `recall(task_description, depth)` — adaptive retrieval
  - Simple task → 3 memories, no procedural/episodes
  - Complex task → 15 memories, full depth
  - Definition of Done: `recall("fix auth bug", depth="complex")` returns relevant memories

### Phase 2: Core Feature [PARALLEL: 3 agents]

- [ ] Task 4: Update `memory.sh` to dual-write [PARALLEL]
  - `memory add` writes to SQLite + flat file
  - `memory search` queries SQLite FTS5
  - `memory stats` shows SQLite counts
  - Definition of Done: `memory add semantic "test principle" && memory search "test"` finds it

- [ ] Task 5: Causal graph tracking [PARALLEL]
  - After each task outcome: record causal factors
  - `add_causal_edge(factor, outcome)` — Bayesian weight update
  - `get_success_factors()` — returns factors correlated with success
  - Definition of Done: `add_causal_edge("test_first", "success")` persists; `get_success_factors()` returns ranked factors

- [ ] Task 6: `memory/recall.py` causal integration [PARALLEL]
  - `smart_recall()` injects success factors into context
  - Definition of Done: recall output includes causal factors when relevant

### Phase 3: Maintenance [PARALLEL: 2 agents]

- [ ] Task 7: Auto-consolidation [PARALLEL]
  - `consolidate()` — merge similar memories (Jaccard > 0.80), prune low confidence (<0.05), cap semantic at 500, procedural at 200
  - `decay()` — exponential decay by halflife (architecture=90d, security=60d, testing=45d, debugging=14d)
  - `maybe_consolidate()` — triggers every 24h or every 10 episodes
  - Definition of Done: `consolidate()` completes without error; memory counts stay within caps

- [ ] Task 8: Update CLAUDE.md + docs [PARALLEL]
  - Update 5-tier memory section to reflect SQLite backend
  - Add `memory recall` to CLI help
  - Update SPEC.md path if needed
  - Definition of Done: CLAUDE.md reflects SQLite architecture; no mention of forgegod

## Verification

| Criterion | Method |
|-----------|--------|
| Search <50ms on 1000+ memories | `time python -c "from memory.search import search; search('api error')"` |
| Dual-write works | `memory add error-solution "test err" "fix"; grep -r "test err" obsidian/Memory/Errors/` |
| Causal graph tracks factors | `add_causal_edge("test", "success"); get_success_factors()` returns "test" |
| Recall adapts depth | `recall("fix bug", depth="simple")` returns 3 memories; depth="complex" returns 15 |
| Consolidation works | `consolidate()` runs; db.stats() shows capped counts |
| Bash CLI unchanged | `memory add; memory list; memory search; memory stats` all work as before |

## Rollback Plan

1. `git revert <commit>` — undo Python code, restore memory.sh to flat-file-only
2. SQLite file `.minmaxing/memory.db` remains but is not read by bash scripts
3. Flat files in obsidian/Memory/ are source of truth — no data loss
4. Users can delete `.minmaxing/memory.db` to reset SQLite state

## File Structure

```
scripts/memory.sh           # Updated bash CLI (dual-write)
memory/
  __init__.py               # Package init
  sqlite_db.py              # SQLite class, schema, FTS5
  search.py                 # FTS5 search, bm25 ranking
  recall.py                 # Adaptive retrieval, smart_recall
  causal.py                 # Causal graph, Bayesian weight updates
  consolidation.py          # Decay, merge, prune
  cli.py                    # Python CLI wrapper (optional)
.taste/
  sessions/                 # Episodic (JSONL, unchanged)
  taste.memory              # Taste verdicts (unchanged)
obsidian/Memory/            # Human-readable projection (unchanged)
.minimaxing/                 # SQLite DB (gitignored)
  memory.db
CLAUDE.md                   # Updated memory section
```
