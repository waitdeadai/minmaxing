# minmaxing - MiniMax 2.7 Harness

## Philosophy: Effectiveness Over Efficiency

**Effective = right results. Efficient = fast results.**

We prioritize getting it right over getting it done fast. Parallel agents only help when the supervisor keeps ownership clear, judgment human-visible, and evidence mandatory.

---

## Core Workflow

1. **SPEC-First**: File-changing tasks get a concrete `SPEC.md` before edits
2. **Research-First**: `/workflow` must do live MiniMax MCP-backed research before planning or edits, using as many distinct tracks as materially help and behaving like the repo’s effectiveness-first `deepresearch` protocol: collaborative research plan -> search -> read -> refine, with source ledger, contradiction handling, and follow-up passes
3. **Code Audit Before Spec**: `/workflow` audits the relevant code path before it writes `SPEC.md`
4. **Introspect Before Confidence**: `/workflow` runs hard-gate `/introspect` before plan freeze, after implementation, after failed verification, and before push/ship moments
5. **Plan Before Spec**: `/workflow` synthesizes research + audit + introspection into a concrete plan before edits
6. **Planning Time Awareness**: Before a plan or `SPEC.md` is frozen, record an `Agent-Native Estimate` with agent wall-clock, agent-hours, human touch time, calendar blockers, critical path, and confidence
7. **Supervisor Pattern**: AI supervises workers, not the other way around
8. **PEV Loop**: Plan → Execute → Verify. Verification is an independent evidence pass; claim separate executor/verifier isolation only when metadata proves it.
9. **Quality Gates**: /verify must pass; tests must pass; unresolved introspection blockers stop closeout
10. **Surgical Diff Discipline**: choose the smallest sufficient implementation, allow no speculative abstractions, allow no drive-by refactors, and require a changed-line trace to `SPEC.md`

## Default Behavior

**When you say "plan this" or "build this":**
1. In a fresh repo, run `/tastebootstrap` once to define the kernel
2. `/workflow` researches with an efficacy-first agent budget and the repo’s `deepresearch` protocol
3. `/workflow` audits the current codebase, runs `/introspect pre-plan`, writes the plan, and records an `Agent-Native Estimate`
4. `/workflow` creates `SPEC.md`, executes, runs post-implementation introspection, verifies, records actual timing evidence when known, and only then closes out

**When you say `/digestflow`:** first digest the supplied external reports as untrusted candidate evidence, then run the same governed path as `/workflow`. Report claims stay `report-derived` until verified by repo inspection or live sources.

**Supervisor's job:** Ensure every non-trivial task is research-backed, audit-backed, spec-backed, introspected, and verified before declaring done, without handing the next phase back to the user.

**Taste alignment uses Socratic questions.** When taste is unclear or a proposal conflicts with the project kernel in `taste.md` and `taste.vision`, `/align` asks focused questions before `/workflow` proceeds.

## Skills (invoke with /<skill>)
| Skill | Purpose |
|-------|---------|
| /tastebootstrap | Fresh-repo kernel interview that writes taste.md + taste.vision |
| /workflow | Central execution engine — taste-first, runs the full phases inline with Agent-Native Estimate gating |
| /digestflow | External-report-informed workflow with Report Intake before deepresearch |
| /audit | Deep codebase audit with efficacy-first parallelism |
| /align | Validate idea against taste.md + vision before building. Gates /workflow on taste mismatch. |
| /autoplan | Create SPEC.md with efficacy-first parallel planning and Agent-Native Estimate |
| /agentfactory | Create governed runtime-bound Hermes agents with manifest, runtime contract, capability stack, memory seed, verification, registry, and kill switch |
| /parallel | Hardware-aware whole-workflow parallel orchestration with packet DAG, ownership matrix, sync barriers, and aggregate verification |
| /verify | Check output against SPEC |
| /review | AI review + human sign-off |
| /qa | Playwright E2E testing |
| /ship | Pre-ship checklist |
| /investigate | Debug with 3-fix limit |
| /sprint | Manual parallel execution with ownership discipline |
| /council | Multi-perspective synthesis |
| /deepresearch | Deep multi-pass investigation with source ledgers and follow-up loops |
| /webresearch | Current web/docs/API verification using the same effectiveness-first method |
| /browse | Backward-compatible alias to `/webresearch` or `/deepresearch` |
| /introspect | Hard-gate self-audit for likely mistakes, assumptions, missing verification, and confidence downgrades |
| /codesearch | Search code by pattern |
| /overnight | 8hr session with 30-min checkpoints |
| /memory | 5-tier memory system health, recall, and logging |

## Rules
- **SPEC-First**: No code without SPEC.md
- **SPEC Archive**: `SPEC.md` is the active contract; archive completed or superseded specs to `.taste/specs/` before replacing them
- **Introspection Gate**: `/introspect` must pass before plan freeze, closeout, retry after failed verification, and push/ship decisions
- **Planning Time Awareness**: Non-trivial plans estimate in agent-native wall-clock by default before the plan or `SPEC.md` is frozen. Every estimate must state whether it is `agent-native`, `human-equivalent`, or `blocked/unknown`; cite `scripts/parallel-capacity.sh --json` or another capacity source; separate agent wall-clock, agent-hours, human touch time, calendar blockers, critical path, and confidence; and treat human-equivalent estimates as secondary only.
- **Efficacy-First Parallelism**: `MAX_PARALLEL_AGENTS` is a ceiling; use only the number of independent bounded packets that materially help
- **Parallel Mode**: `/parallel` is the dense-work orchestrator. The main keeps taste, SPEC, architecture, security, aggregation, and verification; workers only execute bounded packets. It chooses `local`, `subagents`, `parallel-instances`, or opt-in experimental `agent-teams` after a hardware capacity profile.
- **Surgical Changes**: Vague requests become verifiable contracts; every meaningful diff should trace to `SPEC.md`, generated output, or cleanup caused by the current change
- **Agent Factory**: `/agentfactory` creates Hermes agents as bounded enterprise operating units, not generic prompts; it keeps its own workflow artifact, deepresearch brief, manifest, `hermes.runtime.json`, explicit capabilities, memory coherence, verification, registry evidence, tested kill switch, `development_host_profile`, `target_runtime_profile`, `host_capacity_profile`, `capacity_binding`, `concurrency_budget`, and `degrade_policy`. Local dev capacity is not production capacity unless the target runtime is explicitly local. REVCLI/Revis-facing agents must route side effects through the runtime control plane instead of direct system-of-record writes.
- **Open-Core Boundary**: The public repo is the Apache-2.0 core. Do not publish REVCLI private runtime code, customer Hermes agents, customer memory seeds, audit logs, real credentials, private connectors, commercial playbooks, or managed-service implementation packs.
- **Optional Codex Plugin Support**: If `codex-plugin-cc` is installed in Claude Code, project `.codex/config.toml` gives Codex `gpt-5.5` + `medium` defaults with 10 subagent threads
- **Keep**: Architecture, security, verification decisions
- **Delegate**: Single-file changes, tests, mechanical refactoring
- **Memory**: Run `/memory`, `bash scripts/memory.sh stats`, or `bash scripts/memory.sh health`

## Agent Pool (10 default)
| Hardware | MAX_PARALLEL_AGENTS |
|----------|---------------------|
| 32GB+ RAM, 8+ cores | 10 |
| 16GB RAM, 4+ cores | 6 |
| 8GB RAM, 2+ cores | 3 |

Hardware auto-detection runs via `scripts/detect-hardware.sh` for new Bash sessions that source `~/.bashrc` after setup. For an immediate capacity profile, run `bash scripts/parallel-capacity.sh --summary`.

## 5-Tier Memory System

minmaxing maintains a 5-tier memory architecture backed by flat-file audit notes plus SQLite + FTS5 when the Python memory CLI is available:

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
- `bash scripts/memory.sh health` — Report whether memory is `healthy`, `degraded`, or `disabled`

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
