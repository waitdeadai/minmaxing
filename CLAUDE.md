# minmaxing - MiniMax 2.7 Harness

## Philosophy: Effectiveness Over Efficiency

**Effective = right results. Efficient = fast results.**

We prioritize getting it right over getting it done fast. Parallel agents done properly with a competent supervisor = guaranteed results.

---

## Core Workflow

1. **SPEC-First**: File-changing tasks get a concrete `SPEC.md` before edits
2. **Research-First**: `/workflow` must do live MiniMax MCP-backed research before planning or edits, using as many distinct tracks as materially help
3. **Code Audit Before Spec**: `/workflow` audits the relevant code path before it writes `SPEC.md`
4. **Plan Before Spec**: `/workflow` synthesizes research + audit into a concrete plan before edits
5. **Supervisor Pattern**: AI supervises workers, not the other way around
6. **PEV Loop**: Plan → Execute → Verify. The verifier is separate from the implementer.
7. **Quality Gates**: /verify must pass; tests must pass; no silent failures

## Default Behavior

**When you say "plan this" or "build this":**
1. In a fresh repo, run `/tastebootstrap` once to define the kernel
2. `/workflow` researches with an efficacy-first agent budget
3. `/workflow` audits the current codebase and writes the plan
4. `/workflow` creates `SPEC.md`, executes, verifies, and only then closes out

**Supervisor's job:** Ensure every task is research-backed, audit-backed, spec-backed, and verified before declaring done, without handing the next phase back to the user.

**Taste alignment uses Socratic questions.** When taste is unclear or a proposal conflicts with the project kernel in `taste.md` and `taste.vision`, `/align` asks focused questions before `/workflow` proceeds.

## Skills (invoke with /<skill>)
| Skill | Purpose |
|-------|---------|
| /tastebootstrap | Fresh-repo kernel interview that writes taste.md + taste.vision |
| /workflow | Central execution engine — taste-first, runs the full phases inline |
| /audit | Deep codebase audit with efficacy-first parallelism |
| /align | Validate idea against taste.md + vision before building. Gates /workflow on taste mismatch. |
| /autoplan | Create SPEC.md with efficacy-first parallel planning |
| /verify | Check output against SPEC |
| /review | AI review + human sign-off |
| /qa | Playwright E2E testing |
| /ship | Pre-ship checklist |
| /investigate | Debug with 3-fix limit |
| /sprint | Manual parallel execution with ownership discipline |
| /council | Multi-perspective synthesis |
| /browse | Web research with citations |
| /codesearch | Search code by pattern |
| /overnight | 8hr session with 30-min checkpoints |

## Rules
- **SPEC-First**: No code without SPEC.md
- **SPEC Archive**: `SPEC.md` is the active contract; archive completed or superseded specs to `.taste/specs/` before replacing them
- **Efficacy-First Parallelism**: `MAX_PARALLEL_AGENTS` is a ceiling; use only the number of independent bounded packets that materially help
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
- `taste.md` — Project operating kernel (principles, constraints, and guardrails)
- `taste.vision` — Intent + tradeoff contract (the "why")
- `.taste/taste.memory` — Append-only decision log (JSONL)
- `obsidian/Memory/` — Human-readable audit layer (AI output only)

**Commands:**
- `memory recall` — Inject relevant context from SQLite memory into current session
- `/memory` or `bash scripts/memory.sh stats` — Query memory stats

**Causal graph**: Tracks what caused success/failure, enabling learned patterns across sessions.

## Working State (Compaction-Safe)

minmaxing keeps durable memory and live working state separate.

- **Durable memory**: SQLite + FTS5 stores reusable decisions, patterns, errors, and causal factors.
- **Working state**: `.minimaxing/state/CURRENT.md` stores the current task handoff so compaction, resume, and startup do not lose the thread.

Claude Code lifecycle hooks keep working state fresh by default:
- `Stop` refreshes `CURRENT.md` after each completed turn.
- `PreCompact` snapshots state before manual or automatic compaction.
- `PostCompact` records Claude Code's compact summary.
- `SessionStart` rehydrates `CURRENT.md` into context on startup, resume, and compact.

Treat working state as a continuity hint, not ground truth. Before editing, reconcile it with live `git status`, `SPEC.md`, and the latest `.taste/workflow-runs/*-workflow.md` artifact.

## Quick Start
```bash
./scripts/start-session.sh
```
