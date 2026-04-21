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

That's it. ForgeGod, uvx, MiniMax MCP, and 14 skills — all configured.

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
| SPEC-first: write spec before code | Vague prompts, rebuild loops |
| 10 agents in parallel | Sequential one-at-a-time |
| Separate verifier agent | Same AI checks its own work |
| Research-first: verify AI claims | AI hallucinates best practices |
| YOLO mode available | Locked down by default |

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

---

## The 15 Skills

| Skill | What It Does |
|-------|-------------|
| `/workflow` | **Full loop** — plan → research → implement → verify → review → ship |
| `/audit` | Deep codebase audit with 10-agent parallelism |
| `/autoplan` | Generate SPEC.md with parallel execution in mind |
| `/sprint` | Run up to 10 agents in parallel |
| `/verify` | Check output against SPEC (separate verifier) |
| `/review` | AI review + you decide |
| `/office-hours` | 6 questions to clarify vague ideas |
| `/qa` | Playwright E2E testing — Pass/Fail only |
| `/ship` | Pre-ship checklist + rollback plan |
| `/investigate` | Debug with 3-fix limit |
| `/overnight` | 8hr session with 30-min checkpoints |
| `/council` | Multi-perspective analysis |
| `/codex` | Search code by pattern |
| `/browse` | Web research with citations |
| `/loop` | Schedule recurring tasks (cron-style, up to 3 days) |
| `/memory` | 5-tier memory system — log decisions, search patterns |

**Swarm mode:** Add "swarm" or "swarm this" to any skill trigger to run with 10-agent parallelism. E.g. "swarm audit", "swarm this", "swarm verify".

---

## Usage

**The full workflow:**
```bash
claude
/workflow "build a REST API for users"
```

AI drives: SPEC → parallel research → implement (10 agents) → verify → review → ship

**Or step-by-step:**
```bash
/claude
/autoplan "build a login system"   # Generate SPEC.md
/sprint                            # Execute with 10 agents
/verify                           # Check against spec
/ship                             # Ship checklist
```

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
├── .claude/
│   ├── settings.json           # MiniMax config
│   ├── skills/                 # 15 skills
│   │   ├── workflow/
│   │   ├── sprint/
│   │   ├── verify/
│   │   └── ...
│   └── rules/                  # Modular rules
└── scripts/
    └── test-harness.sh        # Verify setup
```

---

## MIT License
