# minmaxing - MiniMax 2.7 Harness

## Philosophy: Effectiveness Over Efficiency

**Effective = right results. Efficient = fast results.**

We prioritize getting it right over getting it done fast. Parallel agents done properly with a competent supervisor = guaranteed results.

---

## Core Workflow

1. **SPEC-First**: File-changing tasks get a concrete `SPEC.md` before edits
2. **10-Agent Parallelism**: Always plan with max parallel agents (10 default)
3. **Supervisor Pattern**: AI supervises workers, not the other way around
4. **PEV Loop**: Plan → Execute → Verify. The verifier is separate from the implementer.
5. **Research-First**: `/workflow` must saturate the full `MAX_PARALLEL_AGENTS` pool with live MiniMax MCP-backed research before planning or edits
6. **Quality Gates**: /verify must pass; tests must pass; no silent failures

## Default Behavior

**When you say "plan this" or "build this":**
1. Supervisor decomposes into 10-agent parallel tasks
2. Workers execute in parallel (up to 10)
3. Supervisor aggregates, verifies, and gates production through the PEV loop

**Supervisor's job:** Ensure every task is research-backed and verified before declaring done, without handing the next phase back to the user.

**Taste alignment uses Socratic questions.** When taste is unclear or a proposal conflicts with `taste.md` or `taste.vision`, `/align` asks focused questions before `/workflow` proceeds.

## Skills (invoke with /<skill>)
| Skill | Purpose |
|-------|---------|
| /workflow | Central execution engine — taste-first, runs the full phases inline |
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
| /codesearch | Search code by pattern |
| /overnight | 8hr session with 30-min checkpoints |

## Rules
- **SPEC-First**: No code without SPEC.md
- **10-Agent Default**: Plan with 10 agents always (configurable via MAX_PARALLEL_AGENTS)
- **Optional Codex Plugin Support**: If `codex-plugin-cc` is installed in Claude Code, project `.codex/config.toml` gives Codex `gpt-5.4` + `xhigh` defaults with 10 subagent threads
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

**Obsidian layer (output-only):**
`obsidian/Memory/` is the human-readable face of the 5-tier system. **Agents do not read these files** — they query SQLite via `memory recall`. Obsidian is AI output, not human-editable storage.

- **Agents use**: SQLite + FTS5 (`.minimaxing/memory.db`) for retrieval
- **Humans use**: obsidian/Memory/*.md for browsing and auditing
- **Humans add memory**: via `bash scripts/memory.sh add <tier> <content>` — which writes to both SQLite and obsidian

**Do NOT edit obsidian files directly.** Human edits to obsidian will NOT sync back to SQLite. To add memory, always use `memory.sh add`.

**Key files:**
- `taste.md` — Design spec (what's acceptable)
- `taste.vision` — Intent document (the "why")
- `.taste/taste.memory` — Append-only decision log (JSONL)
- `obsidian/Memory/` — Human-readable audit layer (AI output only)

**Commands:**
- `memory recall` — Inject relevant context from SQLite memory into current session
- `/memory` or `bash scripts/memory.sh stats` — Query memory stats

**Causal graph**: Tracks what caused success/failure, enabling learned patterns across sessions.

## Quick Start
```bash
./scripts/start-session.sh
```
