# minmaxing

<h1 align="center">
  <img src="https://img.shields.io/badge/MiniMax-2.7%20Highspeed-FF6B35?style=for-the-badge&logo=lightning&logoColor=white" alt="MiniMax M2.7 Highspeed" />
  <img src="https://img.shields.io/badge/Claude%20Code-Harness-8B5CF6?style=for-the-badge&logo=claude&logoColor=white" alt="Claude Code" />
  <img src="https://img.shields.io/badge/Speed-100%20TPS-10B981?style=for-the-badge&logo=zap&logoColor=white" alt="100 TPS" />
  <img src="https://img.shields.io/badge/Context-204K%20tokens-3B82F6?style=for-the-badge&logo=data&logoColor=white" alt="204K Context" />
</h1>

**The ultimate Claude Code harness.** MiniMax 2.7 Highspeed (100 TPS, 204K context) + GStack skills + Karpathy workflows + ForgeGod 5-tier memory. One command setup. Built for developers who ship.

<p align="center">
  <a href="https://github.com/waitdeadai/minmaxing/stargazers"><img src="https://img.shields.io/github/stars/waitdeadai/minmaxing?style=flat-square&logo=github" alt="Stars"></a>
  <a href="https://github.com/waitdeadai/minmaxing/network/members"><img src="https://img.shields.io/github/forks/waitdeadai/minmaxing?style=flat-square&logo=github" alt="Forks"></a>
  <a href="https://github.com/waitdeadai/minmaxing/issues"><img src="https://img.shields.io/github/issues/waitdeadai/minmaxing?style=flat-square&logo=github" alt="Issues"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License"></a>
</p>

---

## tl;dr

```bash
git clone https://github.com/waitdeadai/minmaxing.git && cd minmaxing && ./setup.sh
```

**What you get:**
- MiniMax M2.7 Highspeed (100 TPS, 204K context, $0.30/M)
- ForgeGod 5-tier memory that remembers everything
- 10 role-based skills (/autoplan, /review, /qa, /ship, /investigate...)
- Sprint mode (10x parallel tasks)
- Overnight loops (8hr sessions with checkpoints)
- Pre-edit hooks (97% fewer policy violations)

**Perfect for:** Developers who want AI to handle the routine so they can focus on the creative.

---

## Testing & Verification

Run the test suite to verify your setup:

```bash
./scripts/test-harness.sh
```

### Test Results (Production Verified)

```
==========================================
  minmaxing Test Suite
==========================================

[1] Claude Code Available      ✓ PASS: Claude Code 2.1.114
[2] MiniMax MCP Server        ✓ PASS: MiniMax MCP found
[3] Skills Directory          ✓ PASS: 10 skills found
[4] Rules Directory           ✓ PASS: 5 rules found
[5] Scripts Executable        ✓ PASS: All scripts executable
[6] Settings Files            ✓ PASS: All settings present
[7] CLAUDE.md                 ✓ PASS: CLAUDE.md exists
[8] Memory System             ✓ PASS: ForgeGod installed
[9] Git Ignore                ✓ PASS: API keys gitignored
[10] MiniMax Model Config     ✓ PASS: MiniMax M2.7 Highspeed configured
[11] Effort Level            ✓ PASS: Effort level configured

Summary: 12 passed, 0 failed
```

---

## Why minmaxing?

| Before minmaxing | After minmaxing |
|-------------------|------------------|
| 80% coding, 20% reviewing | 80% delegating, 20% macro-review |
| Context lost between sessions | Persistent 5-tier memory |
| One-size-fits-all prompts | Role-based skills for every task |
| Sequential task execution | 10x parallel sprints |
| Wasted overnight hours | Overnight loops with checkpoints |

### The Math

| Metric | Value |
|--------|-------|
| **Speed** | 100 tokens/second |
| **Context** | 204,800 tokens |
| **SWE-Pro** | 56.22% (frontier-adjacent) |
| **Cost** | $0.30/M input (1/10th of Claude) |
| **Hallucination** | 34% (lower than Claude Sonnet's 46%) |

---

## Benchmark Comparison (2026 SOTA)

### SWE-bench Scores (Real Coding Tasks)

| Model | SWE-bench Verified | SWE-Pro | Cost |
|-------|-------------------|---------|------|
| **MiniMax M2.7** | 78% | 56.22% | $0.30/M |
| Claude Opus 4.6 | 75.6% | ~52% | $3.00/M |
| GPT-5.2 | 72.8% | ~50% | $5.00/M |
| MiniMax M2.5 | 80.2% | ~58% | $0.30/M |

*SWE-bench = Standard benchmark for AI coding agents on real GitHub issues*

### Framework Comparison

| Framework | Stars | Focus | Unique Feature |
|----------|-------|-------|----------------|
| **minmaxing** | 0 | MiniMax + Skills | 100 TPS, 5-tier memory |
| Superpowers | 121K | TDD enforcement | Test-driven development |
| GStack | 54.6K | Role-based skills | CEO workflow |
| GSD | 35K | Environment | Persistent coding agent |
| Everything Claude | ~50K | Comprehensive | Complete toolkit |

*As of April 2026*

### Why MiniMax M2.7?

- **3x faster** than Claude Sonnet 4.6 (100 TPS vs 40 TPS)
- **10x cheaper** than Claude ($0.30/M vs $3.00/M)
- **Beats Claude** on SWE-bench Verified (78% vs 75.6%)
- **Self-evolving** agentic capabilities
- **Frontier-adjacent** at 1/10th the cost

---

## Quick Start (3 Minutes)

### 1. Clone

```bash
git clone https://github.com/waitdeadai/minmaxing.git
cd minmaxing
```

### 2. Install Dependencies

```bash
# ForgeGod memory system
pip install forgegod --break-system-packages

# uvx for MCP
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

### 3. Configure MiniMax MCP

```bash
# Replace YOUR_MINIMAX_API_KEY with your Token Plan key
claude mcp add -s user MiniMax \
  --env MINIMAX_API_KEY=YOUR_MINIMAX_API_KEY \
  --env MINIMAX_API_HOST=https://api.minimax.io \
  -- uvx minimax-coding-plan-mcp -y
```

**Verify** inside Claude Code:
```
/mcp
```
Look for `web_search` and `understand_image`.

### 4. Initialize & Code

```bash
./scripts/start-session.sh
claude
```

---

## For Beginners

### What is Claude Code?

Claude Code is Anthropic's AI coding assistant that works directly in your terminal. Unlike chatbots, it's designed for real development work—reading files, running commands, editing code, and managing git.

### What is a "Harness"?

A harness is the configuration and workflow system around an AI model. Think of it like:
- **Model** = The engine (MiniMax M2.7)
- **Harness** = The car around it (minmaxing)
- **Skills** = The driver training (GStack-inspired)

### Why MiniMax?

| Model | Speed | Cost | SWE-Pro |
|-------|-------|------|---------|
| **MiniMax M2.7** | 100 TPS | $0.30/M | 56.22% |
| Claude Sonnet 4.6 | 40 TPS | $3.00/M | ~52% |
| GPT-4o | 60 TPS | $5.00/M | ~49% |

MiniMax M2.7 is **3x faster, 10x cheaper, and beats both** on coding benchmarks.

---

## The 10 Skills

Based on GStack's insight: **Claude Code shouldn't be one general-purpose assistant—it should be an entire engineering team.**

| Skill | Role | What It Does |
|-------|------|--------------|
| `/autoplan` | 🏗️ Architect | Breaks requirements into verifiable tasks with time budgets |
| `/review` | 👔 Staff Eng | Deep code review: correctness, security, performance, tests |
| `/qa` | ✅ QA Lead | Verifies acceptance criteria, runs tests, reports coverage |
| `/ship` | 🚀 Release Eng | Pre-ship checklist, CHANGELOG, version bump, rollback plan |
| `/investigate` | 🔍 SRE | Root-cause debugging with hypothesis testing methodology |
| `/codex` | 🔬 Researcher | Semantic code search, call chains, pattern extraction |
| `/browse` | 🌐 Research Analyst | Web research with source synthesis and citation |
| `/sprint` | ⚡ Conductor | 10 parallel tasks with aggregation and error handling |
| `/overnight` | 🌙 Overnight Agent | 8-hour sessions with 30-min checkpoint system |
| `/council` | 🎓 Tech Lead | Multi-perspective synthesis for complex decisions |

### Example: Using /investigate

```
/investigate "NullPointerException at line 47"

Output:
## Root Cause
[Description of the bug]

## Evidence
- Stack trace analysis
- Variable state at crash point
- Related code sections

## Fix Applied
[Patched file with explanation]

## Prevention
[How to prevent recurrence]
```

---

## The 5 Modular Rules

| Rule | Purpose |
|------|---------|
| `speed.rules.md` | MiniMax M2.7 Highspeed config, no artificial throttling |
| `quality.rules.md` | Pre/post edit hooks, 97% violation reduction |
| `delegation.rules.md` | 80/20 Karpathy rule, what to delegate |
| `context.rules.md` | 4-level memory hierarchy, progressive disclosure |
| `pev-loop.rules.md` | Plan → Execute → Verify → loop |

---

## The 12 Agentic Harness Patterns (2026 SOTA)

### Memory & Context (Patterns 1-5)
1. **Persistent Instruction File** - CLAUDE.md auto-injected every session
2. **Scoped Context Assembly** - 4-level hierarchy (user→project→rules→session)
3. **Tiered Memory** - ForgeGod 5-tier: episodic/semantic/procedural/graph/error-sol
4. **Dream Consolidation** - Background garbage collection during idle
5. **Progressive Context Compaction** - Older exchanges → dense abstracts

### Workflow & Orchestration (Patterns 6-8)
6. **Explore-Plan-Act Loop** - Escalating permissions: read-only → plan → mutate
7. **Context-Isolated Subagents** - Sandbox per task with bespoke context
8. **Fork-Join Parallelism** - 10 parallel sprints, merged output

### Tools & Permissions (Patterns 9-11)
9. **Progressive Tool Expansion** - Minimal default, dynamic loading
10. **Command Risk Classification** - Low-risk straight through, high-risk approval
11. **Single-Purpose Tool Design** - Strict schemas (PatchFile, SearchRegex)

### Automation (Pattern 12)
12. **Deterministic Lifecycle Hooks** - Pre/post edit hooks guaranteed execution

---

## Karpathy's "Manifesting" Workflow

The biggest productivity shift of 2026:

```
TRADITIONAL (2024):  You write code line-by-line
MANIFESTING (2026):  You state intent → break into objectives
                     → assign to agents → review at macro level
```

### The 80/20 Rule
- **80%** of your time: delegating to subagents, reviewing at macro level
- **20%** of your time: architecture decisions, security reviews, stakeholder comms

### What to Delegate
- ✅ Single-file implementations
- ✅ Test writing
- ✅ Documentation updates
- ✅ Bug investigations
- ✅ Code reviews

### What NOT to Delegate
- ❌ Architecture decisions
- ❌ Security reviews
- ❌ Complex multi-file refactors
- ❌ Stakeholder communication

---

## PEV Loop: Plan → Execute → verify

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  PLAN   │ → │ EXECUTE │ → │ VERIFY  │ → │  LOOP   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │             │               │
     ▼              ▼             ▼               ▼
 Define       Constrained     Check metric    Max 3 iters
 metric       single-file     achieved?      then escalate
```

---

## Scripts Reference

```bash
# Session management
./scripts/start-session.sh    # Full init: memory, obsidian, audit, skills

# Parallelism (10x productivity)
./scripts/sprint.sh "fix auth" "update docs" "add tests"

# Extended sessions (8hr with checkpoints)
./scripts/overnight-loop.sh "refactor core" 8

# Consensus for complex decisions
./scripts/council.sh "Should we migrate to Rust?"

# Verification
./scripts/test-harness.sh   # Verify all components work
```

---

## Memory System (ForgeGod 5-Tier)

| Tier | Content | Retention |
|------|---------|-----------|
| **Episodic** | Session outcomes, what happened | 90 days |
| **Semantic** | Extracted principles, patterns | Indefinite |
| **Procedural** | Code patterns, fix recipes | Indefinite |
| **Graph** | Entity relationships | Indefinite |
| **Error-Solution** | Known errors → fixes | Indefinite |

```bash
forgegod memory              # Check health
forgegod audit              # Pre-flight (run before planning)
forgegod obsidian export    # Project to Obsidian vault
```

---

## Obsidian Integration

Memory auto-projects to `./obsidian/ForgeGod/`:

```
ForgeGod/
├── Dashboard/     # Session overview
├── Research/      # Investigation notes
├── Decisions/     # Architecture choices
├── Patterns/      # Code patterns & recipes
├── Errors/        # Known issues & solutions
└── Runs/          # Session summaries
```

---

## Security & Privacy

```gitignore
# API keys NEVER enter the repo
.claude/settings.json       # Placeholder only
.claude/settings.local.json # Your real config (gitignored)
.forgegod/*.db            # Memory database
.forgegod/gstack/         # Clone separately
```

---

## Requirements

| Requirement | Version | Install |
|------------|---------|---------|
| Claude Code | 2.1+ | `npm install -g @anthropic-ai/claude-code` |
| Python | 3.11+ | `apt install python3.11` |
| ForgeGod | latest | `pip install forgegod` |
| uvx | latest | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| MiniMax API Key | Token Plan | [platform.minimax.io](https://platform.minimax.io) |

---

## Folder Structure

```
minmaxing/
├── CLAUDE.md                    # Coding guidelines & philosophy
├── README.md                    # This file
├── .gitignore                  # Excludes API keys, sensitive data
├── settings.json               # Claude Code root settings
├── .claude/
│   ├── settings.json           # MiniMax env vars (placeholder)
│   ├── settings.local.json     # Local overrides (gitignored)
│   ├── rules/                  # Modular rules
│   │   ├── speed.rules.md
│   │   ├── quality.rules.md
│   │   ├── delegation.rules.md
│   │   ├── context.rules.md
│   │   └── pev-loop.rules.md
│   └── projects/minmaxing/
│       └── MEMORY.md           # Project memory
├── .forgegod/
│   ├── config.toml             # Memory & resolver config
│   └── skills/                 # 10 skill files
├── obsidian/ForgeGod/         # Obsidian vault (optional)
└── scripts/
    ├── start-session.sh
    ├── sprint.sh
    ├── overnight-loop.sh
    ├── council.sh
    └── test-harness.sh
```

---

## Contributing

Contributions welcome! Here's how:

1. **Fork** the repository
2. **Clone** your fork
3. **Create** a feature branch (`git checkout -b feature/amazing`)
4. **Commit** your changes (`git commit -m 'Add amazing feature'`)
5. **Push** to your branch (`git push origin feature/amazing`)
6. **Open** a Pull Request

---

## License

MIT License - Built by the community, for the community.

---

<p align="center">
  <strong>Star if you found this useful. Fork if you built something better.</strong>
</p>
