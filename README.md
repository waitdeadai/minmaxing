# minmaxing

<h1 align="center">
  <img src="https://img.shields.io/badge/MiniMax-2.7%20Highspeed-FF6B35?style=for-the-badge&logo=lightning&logoColor=white" alt="MiniMax M2.7 Highspeed" />
  <img src="https://img.shields.io/badge/Claude%20Code-Harness-8B5CF6?style=for-the-badge&logo=claude&logoColor=white" alt="Claude Code" />
  <img src="https://img.shields.io/badge/Speed-100%20TPS-10B981?style=for-the-badge&logo=zap&logoColor=white" alt="100 TPS" />
  <img src="https://img.shields.io/badge/Context-204K%20tokens-3B82F6?style=for-the-badge&logo=data&logoColor=white" alt="204K Context" />
</h1>

**Right results, not fast results.**

One command sets up a Claude Code harness where AI plans with 10 agents, implements in parallel, and verifies everything against your spec before you accept it.

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

That's it. Memory system, MiniMax MCP, and 15 skills — all configured.

**Taste files are created on-demand.** The first time you run `/workflow`, it detects missing taste.md + taste.vision and triggers `/align --bootstrap` to define them. No empty templates, no guessing.

> **Note:** Setup adds hardware auto-detection to `~/.bashrc` — `MAX_PARALLEL_AGENTS` is set automatically on every shell start.

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
| Taste-first: taste.md + vision gate every decision | No values, no taste — just "build X" |
| 5-tier memory: remembers decisions, patterns, errors across sessions | Tabula rasa every session |
| Central orchestrator: /workflow chains skills automatically | Skills are isolated, no chaining |
| Auto-capture: outcomes logged to memory automatically | Manual documentation |
| SPEC-first: write spec before code | Vague prompts, rebuild loops |
| 10 agents in parallel | Sequential one-at-a-time |
| Separate verifier agent | Same AI checks its own work |
| Research-first: verify AI claims with live web search | AI hallucinates best practices |

**Taste is the kernel.** Every operation checks against your taste.md and taste.vision first. If taste doesn't exist, it asks you to define it — before anything is built.

**Memory is persistent.** Every decision, every fix, every shipped feature is remembered. The second session knows what the first session learned.

**Same model. Better results.** The LangChain team moved from Top 30 to Top 5 on Terminal Bench 2.0 with better harness design.

---

## Key Features

### 10-Agent Parallelism
Spawn up to 10 workers simultaneously. Supervisor decomposes tasks, workers execute in parallel, supervisor verifies.

```
Supervisor (you/AI)
├── Worker 1 → File A
├── Worker 2 → File B
├── Worker 3 → File C
... (up to 10)
└── Supervisor verifies all
```

Auto-detects your hardware: 32GB+ → 10 agents, 16GB → 6 agents, 8GB → 3 agents.

### SPEC-First
Every task starts with SPEC.md. Define success in plain English. AI implements to spec.

### Separate Verifier
Not the same AI that wrote the code. A different agent checks output against your spec.

### Research-First
AI training data is stale. Every external claim gets verified with live web search.

### Permission Mode
- **acceptEdits** (default): File writes auto-approve, safe for parallel agents
- **bypassPermissions** (YOLO): Zero safety checks, true one-command flow

### Taste-First (Kernel)
Every `/workflow` invocation checks `taste.md` + `taste.vision` before doing anything. If they don't exist, it runs `/align --bootstrap` to define them with you — first.

### 5-Tier Memory (Persistent)
SQLite-backed memory that remembers across sessions:
- Every session start/end logged (episodic)
- Decisions, patterns, errors all stored (semantic, procedural, error-solution)
- Causal graph tracks what caused success/failure

### Central Orchestrator
`/workflow` chains skills together — it doesn't just invoke them, it passes context between them and gates progression. Skills are system calls; `/workflow` is the shell.

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
│  PHASE 1: ROUTE (skill_router)                      │
│  PHASE 2: EXECUTE (skill chains)                   │
│  PHASE 3: VERIFY (taste + SPEC compliance)          │
│  PHASE 4: ROUTE OUTPUT                             │
├─────────────────────────────────────────────────────┤
│            taste.md + taste.vision                  │
│                  (Kernel / OS)                     │
├─────────────────────────────────────────────────────┤
│  /autoplan /sprint /verify /ship /investigate     │
│  /audit   /council /qa   /review  /browse         │
│  /codex   /overnight /align                          │
│              (System Calls)                          │
└─────────────────────────────────────────────────────┘
```

**Taste is the kernel.** Every operation checks against your taste.md and taste.vision first. If taste doesn't exist, `/workflow` triggers `/align --bootstrap` to define it.

**Skills are system calls.** Each skill does one thing well. `/workflow` chains them together into execution paths.

**/workflow is the shell.** It orchestrates everything. Routes tasks to skills, passes context between them, verifies output, and gates progression.

### The 4 Execution Paths

| When you say... | /workflow routes to... |
|-----------------|----------------------|
| "build X", "implement Y" | /autoplan → /sprint → /verify → /ship |
| "fix Z", "debug this" | /investigate → /verify |
| "explain", "refactor", "optimize" | /autoplan → /sprint → /verify → /ship |
| "audit this", "analyze" | /audit or /council |

### 5-Tier Memory System

Every skill interaction is remembered:

| Tier | What | When |
|------|------|------|
| Episodic | Session start/end | Every shell start/exit |
| Semantic | Decisions & principles | `/council` decisions, `/align` verdicts |
| Procedural | Code patterns | `/codex` findings, `/sprint` outcomes |
| Error-Solution | Bugs & fixes | `/investigate` fixes, `/verify` failures |
| Graph | Causal chains | What caused success/failure |

Memory is SQLite-backed with FTS5 search. Type `bash scripts/memory.sh stats` to see it.

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

Then tell it what you want to build:

```
/workflow "build a REST API for a todo app"
```

**What happens:**
1. `/workflow` checks taste.md + taste.vision → **don't exist**
2. Triggers `/align --bootstrap` → asks you 10 questions about your design principles, aesthetic, intent, non-goals
3. You answer → taste.md + taste.vision are created
4. `/workflow` continues: `/autoplan` creates SPEC.md → `/sprint` implements (10 agents) → `/verify` checks → `/ship` ships

### What You Get

- **SPEC.md** — exact specification you approved
- **Implementation** — parallel agents building simultaneously
- **Verification** — separate agent adversarial-checking against spec
- **Ship** — checklist, tests, rollback plan, commit, push
- **Memory** — everything logged to 5-tier memory for next session

### After First Build

Your taste is saved. Next time:

```
/workflow "add user authentication"
```

No taste questions. `/workflow` knows your principles, plans, builds, verifies, ships.

---

## Integrate Into Existing Project

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
/align --bootstrap
```

Answer the 10 taste questions about your existing project:
- What are your design principles?
- What's your intent?
- What's in/out of scope?
- What aesthetic rules?

### Step 3: Use /workflow on Your Codebase

Now you can use any workflow pattern:

| Command | What it does |
|---------|--------------|
| `/workflow "explain this codebase"` | Understand what you have |
| `/workflow "audit this for security issues"` | Deep security + quality audit (10 agents) |
| `/workflow "refactor the auth module"` | Spec → implement → verify → ship |
| `/workflow "optimize database queries"` | Spec → implement → verify → ship |
| `/workflow "investigate why X is slow"` | Root-cause debugging with hypothesis testing |
| `/workflow "add REST API to existing endpoints"` | Spec-first build respecting existing architecture |

### Key Difference: Existing vs New

| Aspect | Fresh Project | Existing Project |
|--------|--------------|------------------|
| SPEC.md | Greenfield spec | May not apply — use `/verify` for bug fixes |
| Taste | Bootstrap fresh | Define from existing code |
| `/workflow "build"` | Full spec-first flow | Add features, respect existing patterns |
| `/workflow "explain"` | N/A | Understand existing codebase |
| `/workflow "audit"` | N/A | Find issues in existing code |
| `/workflow "refactor"` | N/A | Improve existing implementation |

---

## The 15 Skills

| Skill | What It Does |
|-------|-------------|
| `/workflow` | **Central execution engine** — drives plan → research → implement → verify → review → ship (supervises 10 agents) |
| `/align` | Validate idea against taste + vision. Gates /workflow on taste mismatch. |
| `/audit` | Deep codebase audit with 10-agent parallelism |
| `/autoplan` | Generate SPEC.md with parallel execution in mind |
| `/sprint` | Run up to 10 agents in parallel |
| `/verify` | Check output against SPEC (separate verifier) |
| `/review` | AI review + you decide |
| `/qa` | Playwright E2E testing — Pass/Fail only |
| `/ship` | Pre-ship checklist + rollback plan |
| `/investigate` | Debug with 3-fix limit |
| `/overnight` | 8hr session with 30-min checkpoints |
| `/council` | Multi-perspective analysis |
| `/codex` | Search code by pattern |
| `/browse` | Web research with citations |
| `/loop` | Schedule recurring tasks (cron-style, up to 3 days) |
| `/memory` | 5-tier memory system — log decisions, search patterns |

All skills use 10-agent parallelism by default. "Swarm" is already built in — no special invocation needed.

---

## Usage

**The full workflow — one command:**
```bash
claude
/workflow "build a REST API for users"
```

`/workflow` chains: taste check → `/autoplan` → `/sprint` (10 agents) → `/verify` → `/ship`

**Direct skill invocation (advanced):**
```bash
/autoplan "build a login system"   # Generate SPEC.md
/sprint                            # Execute with 10 agents
/verify                           # Check against spec
/ship                             # Ship checklist
```
Direct invocation skips the orchestrator — use when you know exactly what you need.

---

## Requirements

| | |
|---|---|
| Claude Code | 2.1+ (`npm install -g @anthropic-ai/claude-code`) |
| Python | 3.11+ |
| MiniMax API Key | [platform.minimax.io](https://platform.minimax.io) |

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
├── taste.md                     # Design spec (what's acceptable) — created by /align
├── taste.vision                 # Intent document (the why) — created by /align
├── .claude/
│   ├── settings.json           # MiniMax API config
│   ├── skills/                 # 15 skills (system calls)
│   │   ├── workflow/           # Central execution engine
│   │   ├── align/              # Taste gate
│   │   ├── audit/              # Deep codebase analysis
│   │   ├── autoplan/            # SPEC.md generator
│   │   ├── sprint/              # 10-agent parallel executor
│   │   ├── verify/              # SPEC compliance checker
│   │   ├── ship/                # Pre-ship checklist
│   │   ├── investigate/         # Root-cause debugging
│   │   ├── council/             # Multi-perspective synthesis
│   │   ├── qa/                  # E2E testing
│   │   ├── review/              # AI review + human sign-off
│   │   ├── codex/               # Code search
│   │   ├── browse/              # Web research
│   │   ├── overnight/           # 8hr session with checkpoints
│   │   └── loop/                # Cron-style recurring tasks
│   └── rules/                  # Modular rules (spec, pev, quality, etc.)
├── scripts/
│   ├── memory.sh               # 5-tier memory CLI
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
│   └── Stories/                 # Graph tier
└── .taste/
    ├── sessions/                # Episodic tier (daily JSONL)
    └── taste.memory             # Append-only decision log
```

---

## MIT License
