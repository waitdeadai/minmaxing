# minmaxing

<h1 align="center">
  <img src="https://img.shields.io/badge/MiniMax-2.7%20Highspeed-FF6B35?style=for-the-badge&logo=lightning&logoColor=white" alt="MiniMax M2.7 Highspeed" />
  <img src="https://img.shields.io/badge/Claude%20Code-Harness-8B5CF6?style=for-the-badge&logo=claude&logoColor=white" alt="Claude Code" />
  <img src="https://img.shields.io/badge/Speed-100%20TPS-10B981?style=for-the-badge&logo=zap&logoColor=white" alt="100 TPS" />
  <img src="https://img.shields.io/badge/Context-204K%20tokens-3B82F6?style=for-the-badge&logo=data&logoColor=white" alt="204K Context" />
</h1>

**Right results, not fast results.**

One command sets up a Claude Code harness where AI researches with an efficacy-first agent budget, audits the codebase, writes a concrete plan and `SPEC.md`, implements, and verifies everything before you accept it.

<p align="center">
  <a href="https://github.com/waitdeadai/minmaxing/stargazers"><img src="https://img.shields.io/github/stars/waitdeadai/minmaxing?style=flat-square&logo=github" alt="Stars"></a>
  <a href="https://github.com/waitdeadai/minmaxing/network/members"><img src="https://img.shields.io/github/forks/waitdeadai/minmaxing?style=flat-square&logo=github" alt="Forks"></a>
  <a href="https://github.com/waitdeadai/minmaxing/issues"><img src="https://img.shields.io/github/issues/waitdeadai/minimaxing?style=flat-square&logo=github" alt="Issues"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License"></a>
</p>

---

## One-Command Setup

```bash
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s YOUR_TOKEN_PLAN_KEY
```

Get your key from [platform.minimax.io](https://platform.minimax.io)

That's it. Memory system, MiniMax MCP, and 18 skills — all configured.

**Shared settings are committed on purpose.** `.claude/settings.json` is the repo template and default shared configuration. Setup still writes your real API key to `.claude/settings.local.json` so secrets do not get committed by accident.

**Fresh repos should start with `/tastebootstrap`.** It asks the 10 kernel questions, writes `taste.md` + `taste.vision`, and gives `/workflow` explicit taste to follow before anything is built.

> **Note:** Setup adds hardware auto-detection to `~/.bashrc` — `MAX_PARALLEL_AGENTS` is set automatically on every shell start.

### Windows Setup

**Recommended:** use **WSL 2** for the smoothest experience.

Claude Code officially supports both:
- **Native Windows + Git Bash**
- **WSL 2**

minmaxing's installer is Bash-first and updates `~/.bashrc`, so:
- **WSL 2** is the best fit if your project already lives in Linux tooling
- **Git Bash** is the best fit if your project lives on native Windows

### Option 1: WSL 2 (recommended)

Install Claude Code inside WSL, then run minmaxing there too.

1. Install WSL 2 and open your Linux distro.
2. Install Claude Code inside WSL:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

3. Move into your project directory inside WSL.
4. Run minmaxing setup:

```bash
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s YOUR_TOKEN_PLAN_KEY
```

If you use the optional OpenAI Codex plugin in WSL, the same Linux flow applies there too.

### Option 2: Native Windows + Git Bash

Claude Code's official Windows docs say native Windows requires **Git for Windows**. Claude can be launched from PowerShell, CMD, or Git Bash, but this repo's setup script should be run from **Git Bash** because it is a Bash script and writes shell config to `~/.bashrc`.

1. Install **Git for Windows**.
2. Install Claude Code from **PowerShell**:

```powershell
irm https://claude.ai/install.ps1 | iex
```

Or install it with **WinGet**:

```powershell
winget install Anthropic.ClaudeCode
```

3. Install **Python 3.11+** and **uv/uvx**:

```powershell
winget install Python.Python.3.11
winget install --id=astral-sh.uv -e
```

4. Open **Git Bash** and run minmaxing setup there:

```bash
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s YOUR_TOKEN_PLAN_KEY
```

5. Verify Claude Code:

```bash
claude --version
claude doctor
```

If Claude Code cannot find your Git Bash installation, Anthropic documents this setting:

```json
{
  "env": {
    "CLAUDE_CODE_GIT_BASH_PATH": "C:\\Program Files\\Git\\bin\\bash.exe"
  }
}
```

### Windows Notes

- Native Windows does **not** support Claude Code sandboxing; WSL 2 does.
- PowerShell support in Claude Code is rolling out progressively, but minmaxing setup is still Bash-based.
- If `uvx` is already available, the installer will use it. If not, preinstalling `uv` on Windows avoids shell-specific installer edge cases.

---

## The Problem

AI coding's #1 failure mode: **building the wrong thing**.

```
Without minmaxing:
"add user auth"
→ AI builds something that looks like auth
→ "that's not what I wanted"
→ AI rebuilds
→ Hours wasted
```

With SPEC-first:
```
"add user auth"
→ AI asks: "What happens when login fails?"
→ You: "show error message"
→ AI writes SPEC.md with exact behavior
→ AI implements to spec
→ AI verifies against spec
→ You accept or reject
```

---

## What Makes minmaxing Different

| This harness | Other harnesses |
|-------------|----------------|
| Taste-first: taste.md + vision gate every decision | No taste — just "build X" |
| 5-tier memory: remembers decisions, patterns, errors across sessions | Tabula rasa every session |
| Central orchestrator: /workflow runs research → audit → plan → spec → execute → verify automatically | Skills are isolated, no chaining |
| Auto-capture: outcomes logged to memory automatically | Manual documentation |
| SPEC-first: write spec before code | Vague prompts, rebuild loops |
| Efficacy-first parallelism: use the right number of agents for the task | Sequential one-at-a-time |
| Separate verifier agent | Same AI checks its own work |
| Research-first: `/workflow` drafts a plan, runs the repo’s effectiveness-first `deepresearch` `search -> read -> refine` investigation loop, and keeps an inspectable source ledger before planning or edits | AI hallucinates best practices |

**Taste is the kernel.** Every operation checks against your taste.md and taste.vision first. In a fresh repo, define them with `/tastebootstrap` before anything is built.

**Taste is NOT just frontend/aesthetic, and it is not a frontend/backend checklist.** It's the project's operating kernel — design principles, experience direction, interface contracts, observability rules, architecture constraints, code style, intent, non-goals, and values. When `/tastebootstrap` asks its 10 kernel questions, it captures the vision and guardrails that make the whole system coherent.

**Memory is persistent.** Every decision, every fix, every shipped feature is remembered. The second session knows what the first session learned.

**Same model. Better results.** The LangChain team moved from Top 30 to Top 5 on Terminal Bench 2.0 with better harness design.

---

## Key Features

### Efficacy-First Parallelism
Spawn up to 10 workers when the task genuinely has 10 bounded, independent packets. Supervisor decomposes tasks, workers execute in parallel, supervisor verifies.

```
Supervisor (you/AI)
├── Worker 1 → File A
├── Worker 2 → File B
├── Worker 3 → File C
... (up to 10)
└── Supervisor verifies all
```

Auto-detects your hardware: 32GB+ → 10 agents, 16GB → 6 agents, 8GB → 3 agents.

The important part is not hitting the ceiling. The important part is using the smallest agent budget that preserves fresh context, clear ownership, and a shorter critical path.

### SPEC-First
File-changing tasks start with research, code audit, and a concrete plan. `SPEC.md` is the formal contract that comes out of that work, and AI implements to spec.

Even tiny local file-changing tasks should still produce a small `SPEC.md` when you invoke the full `/workflow` contract.

### Active SPEC + Archive
`SPEC.md` stays as the active contract in the project root so `/verify` and fresh agents always know what to read first.

Before a new task replaces a non-reused active spec, minmaxing archives the previous one under `.taste/specs/` with a descriptive task/outcome filename. Verified closeout archives the final spec too, deduplicated by content hash, so repeated closeouts do not create noisy copies.

### Separate Verifier
Not the same AI that wrote the code. A different agent checks output against your spec.

### Research-First
AI training data is stale. Every external claim gets verified with live web search.

`/workflow` now treats a research brief as mandatory for all tasks, with the MiniMax MCP as the preferred source whenever current external facts matter. But the brief is not just a search tally. The workflow now uses the repo’s effectiveness-first `deepresearch` protocol: draft a collaborative research plan, run an iterative search -> read -> refine loop, keep a source ledger, challenge conflicting evidence, and do targeted follow-up research before freezing the plan. It still uses up to `MAX_PARALLEL_AGENTS` tracks, but only when the added tracks are distinct and plan-changing. For a purely local task, it can justify a local-only research brief instead of doing pointless external calls.

### Permission Mode
- **bypassPermissions** (shared-project default by design): Zero safety checks for trusted personal setups
- If you want more guardrails, switch your local Claude session to `acceptEdits` or `plan`

### OpenAI Codex Plugin
This repo now ships a project-scoped Codex config under [`.codex/config.toml`](/home/fer/Music/ultimateminimax/.codex/config.toml) plus focused Codex agents in [`.codex/agents/`](/home/fer/Music/ultimateminimax/.codex/agents) so the official OpenAI Claude Code plugin can inherit sane defaults when you use Codex from inside Claude Code.

Research-backed take:
- The best plugin for using Codex inside Claude Code is the official OpenAI [`openai/codex-plugin-cc`](https://github.com/openai/codex-plugin-cc).
- It is explicitly built for Claude Code users, uses your local `codex` CLI plus Codex app server, and picks up user-level or project-level `.codex/config.toml`.
- It does not force parallelism by itself. OpenAI’s Codex docs say subagents are only spawned when you explicitly ask for them, so effective concurrency comes from your prompt plus the project `max_threads` ceiling.
- I found no official source saying this official plugin violates OpenAI terms. This is not legal advice, but the repo itself documents Claude Code installation and current OpenAI Terms/Usage Policies do not appear to prohibit this official integration when used compliantly.

What this repo config gives Codex:
- Main Codex default: `gpt-5.4` with `xhigh` reasoning and detailed reasoning summaries
- Codex Memories enabled where supported, so useful local context can carry into future Codex sessions
- Subagent ceiling: `10` via `[agents].max_threads`
- OpenAI docs MCP: `https://developers.openai.com/mcp`
- Focused helper agents:
  - `repo_explorer`
  - `reviewer`
  - `docs_researcher`

### Taste-First (Kernel)
Every `/workflow` invocation checks `taste.md` + `taste.vision` before doing anything. In a fresh repo, run `/tastebootstrap` first. `/workflow` is the executor, not the bootstrap interview.

### 5-Tier Memory (Persistent)
SQLite-backed memory that remembers across sessions:
- Every session start/end logged (episodic)
- Decisions, patterns, errors all stored (semantic, procedural, error-solution)
- Causal graph tracks what caused success/failure

### Compaction-Safe Working State
LLMs forget because live conversation context is lossy. minmaxing now keeps a compact task handoff in `.minimaxing/state/CURRENT.md` by default.

Claude Code hooks refresh it after each turn, snapshot it before `/compact` or auto-compact, record the compact summary, and rehydrate it on startup, resume, and post-compact. Durable lessons still go to SQLite memory; `CURRENT.md` is only for the active task: files in play, current phase, latest `SPEC.md`, workflow artifact, verification status, and next steps.

### Central Orchestrator
`/workflow` owns the full lifecycle inline: taste gate, deep research, code audit, plan, `SPEC.md`, implementation, verification, and closeout. For file-changing tasks it also leaves a workflow artifact under `.taste/workflow-runs/` and archived specs under `.taste/specs/` so the research plan, loop log, source ledger, audit, plan, and spec trail stay inspectable. Specialist skills still exist, but `/workflow` no longer depends on nested custom-skill chaining to finish the job.

---

## How the Workflow System Works

### Taste as OS, Skills as System Calls

Think of minmaxing as an operating system:

```
┌─────────────────────────────────────────────────────┐
│                      /workflow                      │
│                  (Central Execution Engine)          │
├─────────────────────────────────────────────────────┤
│  PHASE 0: TASTE CHECK [GATE]  ← taste.md + vision │
│  PHASE 1: ROUTE                                     │
│  PHASE 2: DEEP RESEARCH (plan -> search -> read -> refine) │
│  PHASE 3: CODE AUDIT                               │
│  PHASE 4: PLAN                                     │
│  PHASE 5: SPEC.md                                  │
│  PHASE 6: EXECUTE                                  │
│  PHASE 7: VERIFY                                   │
│  PHASE 8: CLOSEOUT                                 │
├─────────────────────────────────────────────────────┤
│            taste.md + taste.vision                  │
│                  (Kernel / OS)                     │
├─────────────────────────────────────────────────────┤
│  /autoplan /sprint /verify /ship /investigate     │
│  /audit /council /qa /review /deepresearch        │
│  /webresearch /browse /codesearch /overnight /align │
│              (System Calls)                          │
└─────────────────────────────────────────────────────┘
```

**Taste is the kernel.** Every operation checks against your taste.md and taste.vision first. If the kernel is missing, stop and define it with `/tastebootstrap` before execution. Taste covers the full project philosophy — design principles, architecture, code style, intent, non-goals, and values.

**Skills are system calls.** Each skill does one thing well. They are still useful directly, but `/workflow` is responsible for finishing the main end-to-end path itself.

**/workflow is the shell.** It orchestrates everything. Routes tasks to the right phase, performs live research, audits the repo, synthesizes the plan, writes `SPEC.md`, executes the work, verifies output, and gates progression.

Inside Phase 2, `/workflow` now follows the repo’s effectiveness-first `deepresearch` protocol instead of a generic search fan-out: it drafts a collaborative research plan, launches only the discovery tracks that matter, reads and refines in loops, records a source ledger including reviewed but not cited sources, pressure-tests conflicting evidence, and runs follow-up research before locking the plan.

### The 4 Execution Paths

| When you say... | /workflow routes to... |
|-----------------|----------------------|
| "build X", "implement Y" | deep research → code audit → plan → `SPEC.md` → implement → verify → closeout |
| "fix Z", "debug this" | deep research → code audit → plan → `SPEC.md` when files change → reproduce/fix → verify → closeout |
| "explain" | deep research → inspect → explain |
| "refactor", "optimize" | deep research → code audit → plan → `SPEC.md` → implement → verify → closeout |
| "audit this", "analyze" | deep research → inspect → findings |

### 5-Tier Memory System

Every action is remembered:

| Tier | What | When |
|------|------|------|
| Episodic | Session start/end | Every shell start/exit |
| Semantic | Decisions & principles | `/council` decisions, `/align` verdicts |
| Procedural | Code patterns | `/codesearch` findings, `/sprint` outcomes |
| Error-Solution | Bugs & fixes | `/investigate` fixes, `/verify` failures |
| Graph | Causal chains | What caused success/failure |
| Commit Log | Git commit summaries | Every `git commit` (auto-summarized) |

Memory is SQLite-backed with FTS5 search. Type `bash scripts/memory.sh stats` to see it.

**Commit auto-summarize:** Every `git commit` triggers `commit-summarize.sh` via a git post-commit hook, generating `obsidian/Memory/Stories/commits/{date}-{hash}.md` with structured frontmatter and a brief summary. Also written to SQLite for agent retrieval.

### Working State vs Memory

`.minimaxing/state/CURRENT.md` is the short-lived working state that survives compaction. It is generated by hooks and should be reconciled with live repo state before edits.

SQLite memory is the durable layer for reusable lessons. When a decision, pattern, error fix, or research finding should survive future tasks, log it with `bash scripts/memory.sh add ...` instead of stuffing it into `CURRENT.md`.

---

## From 0 to 100: Fresh Folder

### Step 1: Install

```bash
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s YOUR_TOKEN_PLAN_KEY
```

### Step 2: Define Your Taste

```bash
claude
```

Then bootstrap the repo kernel:

```
/tastebootstrap
```

**What happens:**
1. `/tastebootstrap` checks taste.md + taste.vision → **don't exist**
2. `/tastebootstrap` asks the 10 kernel questions
3. You answer → taste.md + taste.vision are created
4. The repo is now ready for `/workflow`

Then run:

```
/workflow "build a REST API for a todo app"
```

### What You Get

- **Workflow Artifact** — `.taste/workflow-runs/...` with research brief, code audit, plan, and verification trail
- **SPEC.md** — exact specification created from the researched plan
- **Spec Archive** — `.taste/specs/...` snapshots of completed or superseded specs
- **Implementation** — parallel agents building simultaneously
- **Verification** — separate agent adversarial-checking against spec
- **Closeout** — local completion by default, remote push only when you explicitly ask for it
- **Memory** — everything logged to 5-tier memory for next session

### After Bootstrap

Your taste is saved. From then on:

```
/workflow "add user authentication"
```

No taste questions. `/workflow` knows your principles, plans, builds, verifies, and finishes the task.

### Integrate Into Existing Project

Drop minmaxing into any codebase:

### Step 1: Install Into Existing Folder

```bash
cd your-existing-project
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s YOUR_TOKEN_PLAN_KEY
```

This copies minmaxing files without touching your existing code.

### Step 2: Define Taste for This Project

```bash
claude
```

```
/tastebootstrap
```

Answer the 10 taste questions about your existing project:
- What are your design principles?
- What's your intent?
- What's in/out of scope?
- What experience, interface, and system rules matter?

### Step 3: Use /workflow on Your Codebase

Now you can use any workflow pattern:

| Command | What it does |
|---------|--------------|
| `/workflow "explain this codebase"` | Understand what you have |
| `/workflow "audit this for security issues"` | Deep security + quality audit with risk-based parallel coverage |
| `/workflow "refactor the auth module"` | Research → audit → plan → spec → implement → verify |
| `/workflow "optimize database queries"` | Research → audit → plan → spec → implement → verify |
| `/workflow "investigate why X is slow"` | Root-cause debugging with hypothesis testing |
| `/workflow "add REST API to existing endpoints"` | Research-backed spec-first build respecting existing architecture |

### Key Difference: Existing vs New

| Aspect | Fresh Project | Existing Project |
|--------|--------------|------------------|
| SPEC.md | Greenfield spec | Required for file-changing work; pure analysis can skip |
| Taste | Bootstrap fresh | Define from existing code |
| `/workflow "build"` | Full research-backed spec-first flow | Add features, respect existing patterns |
| `/workflow "explain"` | N/A | Understand existing codebase |
| `/workflow "audit"` | N/A | Find issues in existing code |
| `/workflow "refactor"` | N/A | Improve existing implementation |

---

## The 18 Skills

| Skill | What It Does |
|-------|-------------|
| `/tastebootstrap` | **Fresh-repo bootstrap** — asks the 10 kernel questions and writes `taste.md` + `taste.vision` |
| `/workflow` | **Central execution engine** — drives research → code audit → plan → `SPEC.md` → implement → verify → closeout (supervises an efficacy-first agent budget) |
| `/align` | Validate idea against taste + vision. Gates /workflow on taste mismatch. |
| `/audit` | Deep codebase audit with risk-based parallelism |
| `/autoplan` | Generate SPEC.md with parallel execution in mind |
| `/sprint` | Run an ownership-safe parallel execution wave |
| `/verify` | Check output against SPEC (separate verifier) |
| `/review` | AI review + you decide |
| `/qa` | Playwright E2E testing — Pass/Fail only |
| `/ship` | Pre-ship checklist + rollback plan |
| `/investigate` | Debug with 3-fix limit |
| `/overnight` | 8hr session with 30-min checkpoints |
| `/council` | Multi-perspective analysis |
| `/deepresearch` | Deep multi-pass investigation with source ledgers and follow-up loops |
| `/webresearch` | Current web/docs/API verification using the same effectiveness-first method |
| `/browse` | Backward-compatible alias to `/webresearch` or `/deepresearch` |
| `/codesearch` | Search code by pattern |
| `/memory` | 5-tier memory system — log decisions, search patterns |

**Parallelism:** All skills that support parallelism treat `MAX_PARALLEL_AGENTS` as a ceiling, not a target. `/align` remains single-threaded by design because taste alignment is sequential judgment.

---

## Usage

**The full workflow — one command:**
```bash
claude
/workflow "build a REST API for users"
```

`/workflow` now owns the whole lifecycle inline: taste check → `deepresearch` / `webresearch` → code audit → plan → `SPEC.md` → implementation → verification → closeout.

**Direct skill invocation (advanced):**
```bash
/autoplan "build a login system"   # Generate SPEC.md
/sprint                            # Execute with ownership-safe parallelism
/verify                           # Check against spec
/ship                             # Ship checklist
```
Direct invocation skips the orchestrator — use when you know exactly what you need.

## Verification

Before you trust a setup or a prompt-contract change, run the repo checks:

```bash
bash scripts/test-harness.sh
```

If Claude is authenticated locally, also run the runtime smoke flow:

```bash
bash scripts/workflow-smoke.sh
```

The smoke test validates the real `/workflow` path in a temporary repo and accepts either:
- a justified local-only research brief for a purely local task
- or positive MiniMax MCP research when the task depends on current external facts

## Codex in Claude Code

`/codesearch` is the local repo skill for searching code. `/codex:*` is the official OpenAI plugin namespace.

### Install the official plugin

You can install it from the shell without opening a manual slash-command flow:

```bash
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex
claude plugins list
```

Then open Claude Code and run:

```text
/codex:setup
```

If Codex is not logged in yet:

```bash
codex login
```

### What this repo configures for Codex

Once the repo is trusted, Codex loads [`.codex/config.toml`](/home/fer/Music/ultimateminimax/.codex/config.toml):

- `model = "gpt-5.4"`
- `model_reasoning_effort = "xhigh"`
- `model_reasoning_summary = "detailed"`
- `[agents].max_threads = 10`
- `openaiDeveloperDocs` MCP for official OpenAI/Codex docs

### Deep-Research examples

The Codex plugin exposes reviews plus long-running rescue tasks. For comprehensive research-backed planning, `/codex:rescue` is the better fit because it is steerable.

```text
/codex:rescue --background
Use subagents up to max_threads for a research-backed plan, but only for bounded independent packets.
Have repo_explorer map the code paths, docs_researcher verify external APIs and current docs, and reviewer challenge risks and rollback gaps before proposing the plan.
Task: refactor the auth subsystem without user-visible behavior changes.
```

```text
/codex:adversarial-review --background
Challenge whether this implementation plan is the right one, question hidden assumptions, and look for rollback, race-condition, and test-coverage risks.
```

Notes:
- `/codex:review` and `/codex:adversarial-review` are read-only.
- `/codex:rescue` is the command to use when you want Codex to investigate, plan, and potentially fix.
- Codex only fans out subagents when you explicitly ask it to.
- For the absolute heaviest pass, try `--model gpt-5.4-pro --effort xhigh`, but expect materially higher cost and slower background jobs.

---

## Requirements

| | |
|---|---|
| Claude Code | 2.1+ (`npm install -g @anthropic-ai/claude-code`) |
| Python | 3.11+ |
| MiniMax API Key | [platform.minimax.io](https://platform.minimax.io) |
| Node.js | 18.18+ if you want the optional OpenAI Codex plugin |
| Codex Auth | ChatGPT sign-in or OpenAI API key if you want the optional OpenAI Codex plugin |

---

## Auto-Detection

Harness auto-detects your hardware and sets agent pool:

| RAM | Cores | Agents |
|-----|-------|--------|
| 32GB+ | 8+ | 10 (default) |
| 16GB | 4+ | 6 |
| 8GB | 2+ | 3 |

Override in `.claude/settings.json`:
```json
{
  "env": {
    "MAX_PARALLEL_AGENTS": "6"
  }
}
```

---

## Folder Structure

```
minmaxing/
├── CLAUDE.md                    # Core instructions (for AI)
├── README.md                    # This file (for you)
├── setup.sh                     # One-command installer
├── taste.md                     # Project operating kernel — created by /tastebootstrap
├── taste.vision                 # Product intent + tradeoff contract — created by /tastebootstrap
├── AGENTS.md                    # Project instructions for Codex
├── .codex/
│   ├── config.toml             # Project-scoped Codex defaults
│   └── agents/                 # Codex custom agents for research/review
├── .claude/
│   ├── settings.json           # MiniMax API config
│   ├── hooks/                  # Lifecycle hooks, including working-state rehydration
│   ├── skills/                 # 18 skills (system calls)
│   │   ├── workflow/           # Central execution engine
│   │   ├── tastebootstrap/     # Fresh-repo taste bootstrap
│   │   ├── align/              # Taste gate
│   │   ├── audit/              # Deep codebase analysis
│   │   ├── autoplan/           # SPEC.md generator
│   │   ├── sprint/             # Ownership-safe parallel executor
│   │   ├── verify/             # SPEC compliance checker
│   │   ├── ship/               # Pre-ship checklist
│   │   ├── investigate/        # Root-cause debugging
│   │   ├── council/            # Multi-perspective synthesis
│   │   ├── qa/                 # E2E testing
│   │   ├── review/             # AI review + human sign-off
│   │   ├── deepresearch/        # Canonical deep investigation
│   │   ├── webresearch/        # Focused current web research
│   │   ├── browse/             # Backward-compatible research alias
│   │   ├── codesearch/         # Code search
│   │   ├── memory/             # 5-tier memory skill
│   │   └── overnight/          # 8hr session with checkpoints
│   └── rules/                  # Modular rules (spec, pev, quality, etc.)
├── scripts/
│   ├── memory.sh               # 5-tier memory CLI
│   ├── state.sh                # Compaction-safe working state CLI
│   ├── spec-archive.sh          # Active SPEC.md archive helper
│   ├── memory-auto.sh           # Session start/end hooks
│   ├── taste.sh                 # Taste system CLI
│   ├── start-session.sh         # Session initializer
│   └── detect-hardware.sh       # Auto-detect agent pool
├── memory/                      # Python memory package (SQLite + FTS5)
│   ├── sqlite_db.py
│   ├── causal.py                # Causal graph tracking
│   ├── consolidation.py          # Memory consolidation
│   └── cli.py                   # Memory CLI entry point
├── obsidian/Memory/             # Flat-file memory (git-tracked)
│   ├── Decisions/               # Semantic tier
│   ├── Patterns/                # Procedural tier
│   ├── Errors/                  # Error-solution tier
│   ├── Stories/                 # Graph tier
│   │   └── commits/            # Commit summaries (auto-generated)
├── .minimaxing/
│   └── state/                  # Generated current-task handoff, snapshots, and events
└── .taste/
    ├── sessions/                # Episodic tier (daily JSONL)
    ├── workflow-runs/           # Research/audit/plan/verification artifacts
    ├── specs/                   # Archived completed or superseded specs
    └── taste.memory             # Append-only decision log
```

---

## MIT License
