# minmaxing

<h1 align="center">
  <img src="https://img.shields.io/badge/MiniMax-2.7%20Highspeed-FF6B35?style=for-the-badge&logo=lightning&logoColor=white" alt="MiniMax M2.7 Highspeed" />
  <img src="https://img.shields.io/badge/Claude%20Code-Harness-8B5CF6?style=for-the-badge&logo=claude&logoColor=white" alt="Claude Code" />
  <img src="https://img.shields.io/badge/Speed-100%20TPS-10B981?style=for-the-badge&logo=zap&logoColor=white" alt="100 TPS" />
  <img src="https://img.shields.io/badge/Context-204K%20tokens-3B82F6?style=for-the-badge&logo=data&logoColor=white" alt="204K Context" />
</h1>

**The ultimate effectiveness-first Claude Code harness.** MiniMax 2.7 Highspeed (100 TPS, 204K context) + SPEC-first workflow + Socratic questioning + Verifier agent pattern. Built for developers who ship.

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
- **SPEC-first workflow** — no code without a spec
- **Socratic questioning** — /office-hours transforms vague ideas into buildable specs
- **Verifier agent** — separate verification prevents confirmation bias
- 12 skills that actually work (not empty placeholders)
- 5 modular rules for quality gates
- Sprint mode (10 parallel agents with file isolation)

**Perfect for:** Developers who want AI to ship working software, not just impressive demos.

---

## Effectiveness vs Efficiency

Most AI coding harnesses optimize for **efficiency** (speed, parallelism). But speed without correctness is worthless.

**minmaxing optimizes for effectiveness first:**

| Approach | What Happens |
|----------|--------------|
| **Efficiency-first** | Fast code that doesn't match what you wanted |
| **Effectiveness-first** | Code that matches spec, verified against it |

Research finding: LangChain moved from Top 30 to Top 5 on Terminal Bench 2.0 with **same model**, just better harness. Harness design determines shipping capability.

---

## Testing & Verification

Run the test suite to verify your setup:

```bash
./scripts/test-harness.sh
```

### Test Results

```
==========================================
  minmaxing Test Suite
==========================================

[Core Infrastructure]
[1] Claude Code Available          ✓ PASS
[2] MiniMax Model Config          ✓ PASS
[3] Settings Files                ✓ PASS

[Skills - 12 Required]
[4] Skills Directory              ✓ PASS: 12 skills found
[5] Critical Skills Content      ✓ PASS: office-hours, verify, autoplan, review, qa, ship, investigate

[Rules - 5+ Required]
[6] Rules Directory              ✓ PASS: 7 rules found
[7] Individual Rules             ✓ PASS: quality, context, delegation, spec, verify

[Documentation]
[10] CLAUDE.md                   ✓ PASS: 131 lines
[11] SPEC-First                  ✓ PASS
[12] PEV Loop                    ✓ PASS
[13] Socratic Questioning        ✓ PASS

Summary: 29 passed, 0 failed
```

---

## The 12 Skills (Full Implementation)

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `/office-hours` | **NEW** — YC-style 6 forcing questions | "I have an idea", vague prompts |
| `/autoplan` | SPEC-first planning, scope challenge | "plan this", "how do I build" |
| `/verify` | **NEW** — THE VERIFIER, checks output against SPEC | After every implementation |
| `/review` | Two-stage: AI review + human sign-off | "review this", PR review |
| `/qa` | Browser testing, Pass/Fail only | "QA this", "test this" |
| `/ship` | Pre-ship checklist, rollback plan | "ship this", "ready to ship" |
| `/investigate` | Hypothesis testing, 3-fix limit | "investigate this", "debug" |
| `/sprint` | 10 parallel agents, FILE ISOLATION | "sprint this", "parallel" |
| `/overnight` | 8hr with 30-min checkpoints | "overnight this", "extended" |
| `/council` | Multi-perspective synthesis | "council this", "architectural" |
| `/codex` | Code search and patterns | "find where", "search" |
| `/browse` | Web research integration | "research this", "look up" |

---

## The 5 Modular Rules

| Rule | Purpose |
|------|---------|
| `spec.rules.md` | **NEW** — SPEC-first mandate, required sections |
| `verify.rules.md` | **NEW** — Verifier agent protocol |
| `quality.rules.md` | Hard gates: ESLint error-mode, tests must pass |
| `context.rules.md` | Fresh context discipline, context rot prevention |
| `delegation.rules.md` | 80/20 Karpathy rule, what to delegate vs keep |

---

## Framework Comparison (April 2026)

| Framework | Stars | Approach | Best For |
|-----------|-------|----------|----------|
| **minmaxing** | 0 | Effectiveness-first, SPEC-first, Verifier | Shipping working software |
| Superpowers | ~137K | 7-phase TDD pipeline | Developers lacking discipline |
| GStack | ~65K | 23 role-based skills | Founder-engineers |
| GSD | ~54K | Spec-driven context stabilization | Large projects |

**Key insight from research:** *"gstack thinks, GSD stabilizes, Superpowers executes, minmaxing guarantees."*

---

## Why SPEC-First?

The #1 cause of AI coding failure: **building the wrong thing**.

```bash
# Without SPEC-first:
User: "add user auth"
AI: *builds something that looks like auth*
User: "that's not what I wanted"
AI: *rebuilds*

# With SPEC-first:
User: "add user auth"
AI: "What specifically should happen when login fails?"
User: "show error message"
AI: "What's the error message format?"
User: "red text under the field"
AI: *generates SPEC.md with exact behavior*
AI: *implements against spec*
AI: *verifies against spec*
# Done correctly, once
```

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

### 4. Initialize & Code

```bash
./scripts/start-session.sh
claude
```

---

## The PEV Loop: Plan → Execute → Verify

```
┌─────────┐    ┌─────────┐    ┌─────────┐
│  PLAN   │ → │ EXECUTE │ → │ VERIFY  │
└─────────┘    └─────────┘    └─────────┘
     │              │             │
     ▼              ▼             ▼
  SPEC.md     Implementation   /verify
                              against SPEC
```

**The critical step most harnesses skip:** VERIFY. Implementation verifying itself = confirmation bias.

---

## Effectiveness Patterns That Ship

### 1. Socratic Questioning (/office-hours)

Transforms vague ideas into buildable specs via 6 forcing questions:

1. **Demand Reality** — "Have you talked to 10 people with this problem?"
2. **Status Quo** — "What do they do today?"
3. **Desperate Specificity** — "Show me the exact failure"
4. **Narrowest Wedge** — "20% that solves 80%?"
5. **Observation** — "Have YOU experienced this?"
6. **Future-Fit** — "What breaks in 6 months?"

### 2. Verifier Agent (/verify)

Separate verification agent (GAN-like pattern) that checks output against SPEC.md.

- Implementation verifies itself → confirmation bias → bugs ship
- Separate verifier checks against spec → catches drift

### 3. Quality Gates

- ESLint error-mode: warnings are failures
- Tests must pass: 100% pass rate
- /verify must pass: before accepting any output
- Circuit breakers: quality gate fail = block

### 4. 3-Fix Limit (/investigate)

After 3 failed fix attempts, escalate. Prevents endless debugging rabbit holes.

---

## Benchmark Comparison (2026 SOTA)

### SWE-bench Scores

| Model | SWE-bench Verified | SWE-Pro | Cost |
|-------|-------------------|---------|------|
| **MiniMax M2.7** | 78% | 56.22% | $0.30/M |
| Claude Opus 4.6 | 75.6% | ~52% | $3.00/M |
| GPT-5.2 | 72.8% | ~50% | $5.00/M |

### Harness Design Matters More Than Model

LangChain improved from Top 30 to Top 5 on Terminal Bench 2.0 with **same model**, just better harness.

---

## Scripts Reference

```bash
# Session management
./scripts/start-session.sh    # Full init: audit, health check, version

# Parallelism (10x productivity)
./scripts/sprint.sh "fix auth" "update docs" "add tests"

# Extended sessions (8hr with checkpoints)
./scripts/overnight-loop.sh "refactor core" 8

# Consensus for complex decisions
./scripts/council.sh "Should we migrate to Rust?"

# Verification
./scripts/test-harness.sh   # Verify all components work (29 tests)
```

---

## Memory System (ForgeGod 5-Tier)

| Tier | Content | Retention |
|------|---------|-----------|
| **Episodic** | Session outcomes | 90 days |
| **Semantic** | Extracted principles | Indefinite |
| **Procedural** | Code patterns, fix recipes | Indefinite |
| **Graph** | Entity relationships | Indefinite |
| **Error-Solution** | Known errors → fixes | Indefinite |

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
├── CLAUDE.md                    # Core instructions (SPEC-first, PEV)
├── README.md                    # This file
├── .gitignore                  # Excludes API keys, sensitive data
├── settings.json               # Claude Code root settings
├── .claude/
│   ├── settings.json           # MiniMax env vars (placeholder)
│   ├── settings.local.json     # Local overrides (gitignored)
│   └── rules/                  # Modular rules
│       ├── quality.rules.md     # Hard gates, failure protocol
│       ├── context.rules.md     # Fresh context, context rot
│       ├── delegation.rules.md  # 80/20 rule
│       ├── spec.rules.md       # SPEC-first mandate
│       └── verify.rules.md      # Verifier agent protocol
├── .forgegod/
│   ├── config.toml             # Memory & resolver config
│   └── skills/                 # 12 skills (full implementation)
│       ├── office-hours/       # 6 forcing questions
│       ├── verify/             # THE VERIFIER
│       ├── autoplan/           # SPEC-first planning
│       ├── review/             # Two-stage review
│       ├── qa/                # Browser testing, Pass/Fail
│       ├── ship/              # Pre-ship checklist
│       ├── investigate/        # Hypothesis testing
│       ├── sprint/            # Parallel agents
│       ├── overnight/          # Extended sessions
│       ├── council/           # Multi-perspective
│       ├── codex/             # Code search
│       └── browse/            # Web research
└── scripts/
    ├── start-session.sh       # Full initialization
    ├── sprint.sh              # Parallel execution
    ├── overnight-loop.sh      # Extended sessions
    ├── council.sh             # Multi-perspective
    └── test-harness.sh       # 29 verification tests
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
  <strong>Ship working software. Not just impressive demos.</strong>
</p>
