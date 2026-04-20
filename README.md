# minmaxing

<h1 align="center">
  <img src="https://img.shields.io/badge/MiniMax-2.7%20Highspeed-FF6B35?style=for-the-badge&logo=lightning&logoColor=white" alt="MiniMax M2.7 Highspeed" />
  <img src="https://img.shields.io/badge/Claude%20Code-Harness-8B5CF6?style=for-the-badge&logo=claude&logoColor=white" alt="Claude Code" />
  <img src="https://img.shields.io/badge/Speed-100%20TPS-10B981?style=for-the-badge&logo=zap&logoColor=white" alt="100 TPS" />
  <img src="https://img.shields.io/badge/Context-204K%20tokens-3B82F6?style=for-the-badge&logo=data&logoColor=white" alt="204K Context" />
</h1>

Stop spending hours re-doing AI work because it didn't match the spec. This harness runs a separate check after every AI implementation — verifying output against your spec before you accept it.

<p align="center">
  <a href="https://github.com/waitdeadai/minmaxing/stargazers"><img src="https://img.shields.io/github/stars/waitdeadai/minmaxing?style=flat-square&logo=github" alt="Stars"></a>
  <a href="https://github.com/waitdeadai/minmaxing/network/members"><img src="https://img.shields.io/github/forks/waitdeadai/minmaxing?style=flat-square&logo=github" alt="Forks"></a>
  <a href="https://github.com/waitdeadai/minmaxing/issues"><img src="https://img.shields.io/github/issues/waitdeadai/minmaxing?style=flat-square&logo=github" alt="Issues"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License"></a>
</p>

---

## One-Command Setup

```bash
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s YOUR_TOKEN_PLAN_KEY
```

Get your key from [platform.minimax.io](https://platform.minimax.io)

That's it. The setup script installs ForgeGod, uvx, configures your API key, and sets up the MiniMax MCP server.

---

## What This Solves

| Problem | How minmaxing Fixes It |
|---------|------------------------|
| AI builds the wrong thing — you wasted time | SPEC-first forces you to write the spec before code |
| AI code passes tests but doesn't match what you wanted | A separate check verifies output against your spec |
| Hours debugging AI-generated bugs that seemed to work | 3-fix limit pushes you to escalate instead of rabbit-holing |
| Context window overflow mid-task | SPEC.md acts as a reset point for fresh context |
| Setup friction kills your momentum | One command installs everything |

---

## How It Works

**1. Write the spec first.** Before any code, you define what success looks like in plain English.

**2. AI implements against the spec.** Claude Code builds to the spec, not to a vague prompt.

**3. A separate check verifies output.** Not the same AI that wrote the code — a separate verifier checks against your spec.

**4. You accept or reject.** Based on evidence, not "looks good."

---

## Copy to Any Project

minmaxing is a copy-paste harness. Drop it into any project folder and it works immediately.

```bash
# Copy to your project
cp -r minmaxing /path/to/your-project
cd /path/to/your-project

# Install dependencies
pip install forgegod --break-system-packages
curl -LsSf https://astral.sh/uv/install.sh | sh

# Configure once
./setup.sh YOUR_TOKEN_PLAN_KEY

# Verify
./scripts/test-harness.sh

# Start
claude
```

---

## The 12 Skills

| Skill | What It Does |
|-------|-------------|
| `/office-hours` | Asks 6 forcing questions to turn a vague idea into a buildable spec |
| `/autoplan` | Generates SPEC.md before any code gets written |
| `/verify` | Checks output against SPEC.md — separate from the AI that wrote it |
| `/review` | AI review + you decide whether to approve |
| `/qa` | Browser testing with Pass/Fail only |
| `/ship` | Pre-ship checklist + rollback plan |
| `/investigate` | Hypothesis testing — 3 fixes max, then escalate |
| `/sprint` | Run up to 10 tasks in parallel, different files only |
| `/overnight` | 8-hour session with 30-minute checkpoint commits |
| `/council` | Multi-perspective analysis for complex decisions |
| `/codex` | Search code by pattern or function name |
| `/browse` | Web research with citations |

---

## Quick Start

```bash
./scripts/start-session.sh    # Audit memory, check versions, health check
claude                       # Start coding
```

When you have a task:
- Vague idea → `/office-hours` first
- New feature → `/autoplan` to generate SPEC.md
- Implementation done → `/verify` checks against spec
- Ready to ship → `/ship` runs the checklist

---

## Testing & Verification

Run the test suite to verify your setup:

```bash
./scripts/test-harness.sh
```

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

## How minmaxing Differs

| Framework | What It Optimizes | The Problem |
|-----------|------------------|-------------|
| Superpowers | 7-phase TDD pipeline | Assumes you already know what to build |
| GStack | 23 role-based skills | Many skills, no verification step |
| GSD | Context stabilization | Good for large projects, slow setup |
| **minmaxing** | **Output matches spec** | **One command to start** |

Same model. Better harness. The LangChain team moved from Top 30 to Top 5 on Terminal Bench 2.0 with the same model — just better harness design.

---

## Why SPEC-First?

The #1 failure mode for AI coding: **building the wrong thing**.

```
Without SPEC-first:
User: "add user auth"
AI: *builds something that looks like auth*
User: "that's not what I wanted"
AI: *rebuilds*

With SPEC-first:
User: "add user auth"
AI: "What should happen when login fails?"
User: "show error message"
AI: "What's the error message format?"
User: "red text under the field"
AI: *writes SPEC.md with exact behavior*
AI: *implements to spec*
AI: *verifies against spec*
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
├── CLAUDE.md                    # Core instructions
├── README.md                    # This file
├── .gitignore                  # Excludes API keys, memory DB
├── settings.json               # Claude Code root settings
├── .claude/
│   ├── settings.json           # MiniMax env vars
│   ├── settings.local.json     # Local overrides (gitignored)
│   └── rules/                  # Modular rules
│       ├── spec.rules.md        # SPEC-first mandate
│       ├── verify.rules.md      # Separate verification protocol
│       ├── quality.rules.md     # Hard gates
│       ├── context.rules.md     # Fresh context discipline
│       └── delegation.rules.md  # What to delegate
├── .forgegod/
│   ├── config.toml             # Memory config
│   └── skills/                 # 12 skills
│       ├── office-hours/        # 6 forcing questions
│       ├── verify/              # THE VERIFIER
│       ├── autoplan/            # SPEC-first planning
│       ├── review/              # Two-stage review
│       ├── qa/                 # Browser testing
│       ├── ship/               # Pre-ship checklist
│       ├── investigate/         # Hypothesis testing
│       ├── sprint/             # Parallel execution
│       ├── overnight/           # Extended sessions
│       ├── council/            # Multi-perspective
│       ├── codex/              # Code search
│       └── browse/             # Web research
└── scripts/
    ├── start-session.sh        # Full initialization
    ├── sprint.sh              # Parallel execution
    ├── overnight-loop.sh       # Extended sessions
    ├── council.sh              # Multi-perspective
    └── test-harness.sh        # 29 verification tests
```

---

## Contributing

1. Fork the repository
2. Clone your fork
3. Create a feature branch (`git checkout -b feature/amazing`)
4. Commit your changes
5. Push to your branch
6. Open a Pull Request

---

MIT License
