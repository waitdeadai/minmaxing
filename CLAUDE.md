# minmaxing - MiniMax 2.7 Harness

## Philosophy: Effectiveness Over Efficiency

**Effective = right results. Efficient = fast results.**

We prioritize getting it right over getting it done fast. Parallel agents done properly with a competent supervisor = guaranteed results.

---

## Core Workflow

1. **SPEC-First**: Every task starts with SPEC.md via /autoplan
2. **10-Agent Parallelism**: Always plan with max parallel agents (10 default)
3. **Supervisor Pattern**: AI supervises workers, not the other way around
4. **Research-First**: Verify AI claims with web search (training data is stale)
5. **Quality Gates**: /verify must pass; tests must pass; no silent failures

## Default Behavior

**When you say "plan this" or "build this":**
1. Supervisor decomposes into 10-agent parallel tasks
2. Workers execute in parallel (up to 10)
3. Supervisor aggregates, verifies, and gates production

**Supervisor's job:** Ensure every task passes verification before declaring done.

## Skills (invoke with /<skill>)
| Skill | Purpose |
|-------|---------|
| /workflow | Central execution engine — taste-first, orchestrates all skills |
| /audit | Deep codebase audit with 10-agent parallelism |
| /align | Validate idea against taste.md + vision before building. Gates /workflow on taste mismatch. |
| /autoplan | Create SPEC.md with 10-agent parallel mindset |
| /verify | Check output against SPEC |
| /review | AI review + human sign-off |
| /qa | Playwright E2E testing |
| /ship | Pre-ship checklist |
| /investigate | Debug with 3-fix limit |
| /sprint | Manual 10 parallel agents |
| /council | Multi-perspective synthesis |
| /browse | Web research with citations |
| /codex | Search code by pattern |
| /overnight | 8hr session with 30-min checkpoints |

## Rules
- **SPEC-First**: No code without SPEC.md
- **10-Agent Default**: Plan with 10 agents always (configurable via MAX_PARALLEL_AGENTS)
- **Keep**: Architecture, security, verification decisions
- **Delegate**: Single-file changes, tests, mechanical refactoring
- **Memory**: Run `/memory` or `bash scripts/memory.sh stats`

## Agent Pool (10 default)
| Hardware | MAX_PARALLEL_AGENTS |
|----------|---------------------|
| 32GB+ RAM, 8+ cores | 10 |
| 16GB RAM, 4+ cores | 6 |
| 8GB RAM, 2+ cores | 3 |

Hardware auto-detection runs via `scripts/detect-hardware.sh` on every shell start (added to `~/.bashrc` by setup).

## 5-Tier Memory System

minmaxing maintains a 5-tier memory architecture backed by SQLite + FTS5:

| Tier | Content | Storage |
|------|---------|---------|
| Episodic | Task outcomes | `.taste/sessions/*.jsonl` |
| Semantic | Principles | SQLite + FTS5 (`.minimaxing/memory.db`) |
| Procedural | Code patterns | SQLite + FTS5 (`.minimaxing/memory.db`) |
| Error-Solution | Error → fix | SQLite + FTS5 (`.minimaxing/memory.db`) |
| Graph | Entity relationships (success factors) | SQLite + FTS5 (`.minimaxing/memory.db`) |

**Storage details:**
- **Episodic**: Raw JSONL session logs in `.taste/sessions/`
- **Semantic/Procedural/Error-Solution/Graph**: SQLite database with FTS5 full-text search in `.minimaxing/memory.db`
- **Causal graph tracking**: Records success factors and outcome chains for learned patterns

**Key files:**
- `taste.md` — Design spec (what's acceptable)
- `taste.vision` — Intent document (the "why")
- `.taste/taste.memory` — Append-only decision log (JSONL)

**Commands:**
- `memory recall` — Inject relevant context from SQLite memory into current session
- `/memory` or `bash scripts/memory.sh stats` — Query memory stats

**Causal graph**: Tracks what caused success/failure, enabling learned patterns across sessions.

## Quick Start
```bash
./scripts/start-session.sh
```
