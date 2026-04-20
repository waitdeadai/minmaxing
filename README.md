# minmaxing

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
git clone https://github.com/waitdeadai/minmaxing && cd minmaxing && ./setup.sh
```

**What you get:**
- MiniMax M2.7 Highspeed (100 TPS, 204K context, $0.30/M)
- ForgeGod 5-tier memory
- 10 role-based skills (/autoplan, /review, /qa, /ship, /investigate...)
- Sprint mode (10x parallel tasks)
- Overnight loops (8hr with checkpoints)

---

## Why minmaxing?

| Before | After |
|--------|-------|
| 80% coding, 20% reviewing | 80% delegating, 20% macro-review |
| Context lost between sessions | Persistent 5-tier memory |
| One-size-fits-all prompts | Role-based skills |
| Sequential tasks | 10x parallel sprints |

### Benchmarks

| Model | Speed | Cost | SWE-Pro |
|-------|-------|------|---------|
| **MiniMax M2.7** | 100 TPS | $0.30/M | 56.22% |
| Claude Sonnet 4.6 | 40 TPS | $3.00/M | ~52% |
| GPT-4o | 60 TPS | $5.00/M | ~49% |

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/waitdeadai/minmaxing
cd minmaxing

# 2. Install deps
pip install forgegod --break-system-packages
curl -LsSf https://astral.sh/uv/install.sh | sh

# 3. Configure MiniMax MCP
claude mcp add -s user MiniMax \
  --env MINIMAX_API_KEY=YOUR_KEY \
  --env MINIMAX_API_HOST=https://api.minimax.io \
  -- uvx minimax-coding-plan-mcp -y

# 4. Initialize & code
./scripts/start-session.sh
claude
```

---

## The 10 Skills

| Skill | Role | What It Does |
|-------|------|--------------|
| `/autoplan` | Architect | Breaks requirements into verifiable tasks |
| `/review` | Staff Eng | Deep code review |
| `/qa` | QA Lead | Verifies acceptance criteria |
| `/ship` | Release Eng | Pre-ship checklist |
| `/investigate` | SRE | Root-cause debugging |
| `/codex` | Researcher | Code search & understanding |
| `/browse` | Research Analyst | Web research |
| `/sprint` | Conductor | 10 parallel tasks |
| `/overnight` | Overnight Agent | 8hr sessions with checkpoints |
| `/council` | Tech Lead | Multi-perspective synthesis |

---

## The 5 Rules

| Rule | Purpose |
|------|---------|
| `speed.rules.md` | MiniMax M2.7 Highspeed config |
| `quality.rules.md` | Pre/post edit hooks |
| `delegation.rules.md` | 80/20 Karpathy rule |
| `context.rules.md` | 4-level memory hierarchy |
| `pev-loop.rules.md` | Plan Execute Verify loop |

---

## Scripts

```bash
./scripts/start-session.sh    # Full init
./scripts/sprint.sh "task1" "task2"  # 10 parallel
./scripts/overnight-loop.sh "task" 8  # 8hr with checkpoints
./scripts/council.sh "question"      # Consensus
./scripts/test-harness.sh           # Verify
```

---

## Memory (ForgeGod 5-Tier)

| Tier | Content | Retention |
|------|---------|-----------|
| Episodic | Session outcomes | 90 days |
| Semantic | Principles, patterns | Indefinite |
| Procedural | Code patterns, fixes | Indefinite |
| Graph | Entity relationships | Indefinite |
| Error-Solution | Known errors fixes | Indefinite |

---

## Security

API keys are gitignored. Your config goes in `settings.local.json`.

---

## Requirements

- Claude Code 2.1+
- Python 3.11+
- ForgeGod
- uvx
- MiniMax API key

---

## License

MIT
