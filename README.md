# minmaxing

## Install

Pick the command that matches the folder.

Clean/new folder:

```bash
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --minimax-key 'YOUR_TOKEN_PLAN_KEY' && claude
```

Existing project or harness update:

```bash
curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --import-existing --minimax-key 'YOUR_TOKEN_PLAN_KEY' && claude
```

Get your key from [platform.minimax.io](https://platform.minimax.io).

<h1 align="center">
  <img src="https://img.shields.io/badge/MiniMax-2.7%20Highspeed-FF6B35?style=for-the-badge&logo=lightning&logoColor=white" alt="MiniMax M2.7 Highspeed" />
  <img src="https://img.shields.io/badge/Claude%20Code-Harness-8B5CF6?style=for-the-badge&logo=claude&logoColor=white" alt="Claude Code" />
  <img src="https://img.shields.io/badge/Speed-100%20TPS-10B981?style=for-the-badge&logo=zap&logoColor=white" alt="100 TPS" />
  <img src="https://img.shields.io/badge/Context-204K%20tokens-3B82F6?style=for-the-badge&logo=data&logoColor=white" alt="204K Context" />
</h1>

**Delegate execution. Keep judgment. Require evidence.**

Setup adds a governed Claude Code harness where AI researches with an efficacy-first agent budget, audits the codebase, writes a concrete plan and `SPEC.md`, implements with clear ownership, and produces evidence before you trust the result.

<p align="center">
  <a href="https://github.com/waitdeadai/minmaxing/stargazers"><img src="https://img.shields.io/github/stars/waitdeadai/minmaxing?style=flat-square&logo=github" alt="Stars"></a>
  <a href="https://github.com/waitdeadai/minmaxing/network/members"><img src="https://img.shields.io/github/forks/waitdeadai/minmaxing?style=flat-square&logo=github" alt="Forks"></a>
  <a href="https://github.com/waitdeadai/minmaxing/issues"><img src="https://img.shields.io/github/issues/waitdeadai/minmaxing?style=flat-square&logo=github" alt="Issues"></a>
  <a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache--2.0-green?style=flat-square" alt="License"></a>
</p>

---

## Open-Core Boundary

minmaxing is the open-source core for governed AI workflows. The public repo is
licensed under Apache-2.0 and includes the harness, skills, rules, AgentFactory
contracts, verification patterns, and safe example blueprints.

The private commercial moat is not included: REVCLI/Revis runtime code,
customer-specific Hermes agents, enterprise connectors, memory seeds, audit
logs, operational playbooks, tenant infrastructure, and managed service
delivery remain private unless explicitly published later.

Read the operating boundary before packaging or selling anything from this
repo:

- [OPEN_CORE_STRATEGY.md](OPEN_CORE_STRATEGY.md)
  defines what is public, what stays private, and why the moat lives in runtime
  operation rather than prompt files.
- [COMMERCIAL.md](COMMERCIAL.md) explains the
  managed-service boundary and public-claims rules.
- [SECURITY.md](SECURITY.md) defines safe
  vulnerability reporting and secret/customer-data handling.
- [TRADEMARKS.md](TRADEMARKS.md) keeps project
  names, certification claims, and managed-service branding separate from the
  Apache-2.0 code license.

## Runtime Governance

Use minmaxing as a governed harness, not as an unverifiable autonomy claim. The
public core is safe to validate without secrets:

```bash
bash scripts/test-harness.sh
bash scripts/release-check.sh --static-only
```

Runtime checks are intentionally separate. Authenticated Claude Code smoke tests
require local credentials and must not run by default on public PRs:

```bash
RUN_CLAUDE_INTEGRATION=1 bash scripts/test-harness.sh
```

Choose the runtime profile deliberately:

- **Default in this repo:** trusted-local `bypassPermissions` for the operator's
  solo workflow. This is intentionally fast and intentionally riskier: use it
  only on a private machine/repo where you accept local command authority.
- `solo-fast`: tracked example of the same trusted-local speed posture.
- `team-safe`: shared-work fallback with `acceptEdits`; start from
  `.claude/settings.team-safe.example.json` for teammates, reviews, clients, or
  any workspace where automatic tool permission is too much authority.
- `ci-static`: no-secret static validation for public PRs and release checks.
- `ci-runtime`: manual authenticated validation through
  `.github/workflows/harness-runtime.yml`.

The quickstart is here:

- [docs/runtime-governance-quickstart.md](docs/runtime-governance-quickstart.md)

Public examples must use dummy data only:

- [examples/dummy-harness-run/](examples/dummy-harness-run/)

The harness is effective when its gates produce evidence: `SPEC.md`,
Agent-Native Estimates, parent-verified worker outputs, aggregate verification,
memory health/freshness checks, and command-backed closeout.

## Setup Commands

There are two setup commands and they do different jobs.

- **Clean/new folder:** use this only in an empty folder where minmaxing can
  become the project scaffold.
- **Existing project or harness update:** use this inside a real app/repo. It
  imports or updates harness-owned files only, skips project-file conflicts,
  preserves `.env`, `README.md`, `SPEC.md`, `taste.md`, `taste.vision`, app
  code, package files, and `.git`, and records imported file hashes in
  `.minimaxing/import-manifest.tsv` so future runs can update files it owns.

Both commands default to `/opusworkflow`: Claude/Opus is the planner,
adversary, and final reviewer when runtime identity is proven;
MiniMax-M2.7-highspeed is the bounded executor for bulk coding and repair. The installer
configures the ignored local MiniMax executor profile, keeps the Opus planner
profile provider-clean, uses the default trusted-local `bypassPermissions`
posture, and opens Claude when setup finishes.

Inline token commands can land in shell history. That is the intentional
fast path for trusted solo work; environment-variable, hidden-input, key-file, and explicit
`--mode minimax|opusworkflow|opusminimax` override forms still exist in
`bash setup.sh --help`, but they are not the default path.

If an earlier install did not detect MiniMax, rerun the existing-project command
above from the project root. In `/opusworkflow` split mode, MiniMax is configured
in the ignored executor profile `.claude/settings.minimax-executor.local.json`;
it is not automatically added as a user-scope Claude MCP server.

That's it. Memory system, governed runtime profiles, and 34 skills are
configured.

Claude subscription auth is separate account auth. Run `claude auth login` once
if this machine is not already logged in; the setup command does not store or
fake your Claude subscription session.

**Shared settings are committed on purpose, but they are provider-neutral.** `.claude/settings.json` contains governance hooks, deny rules, and the trusted-local `bypassPermissions` default. This is an explicit operator-speed choice, not a team-safety recommendation. Real credentials and provider identity belong in ignored local files such as `.claude/settings.opusminimax-planner.local.json` and `.claude/settings.minimax-executor.local.json`.

**Fresh repos should start with `/tastebootstrap`.** It asks the 10 kernel questions, writes `taste.md` + `taste.vision`, and gives `/workflow` explicit taste to follow before anything is built.

> **Note:** Setup adds hardware auto-detection to `~/.bashrc` — `MAX_PARALLEL_AGENTS` is set automatically for new Bash sessions that source `~/.bashrc`.

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
4. Run the clean/new-folder command or the existing-project/updater command from the top of this README.

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

4. Open **Git Bash** and run the clean/new-folder command or the existing-project/updater command from the top of this README.

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
| Taste-first: `/workflow` starts from `taste.md` + `taste.vision` | No taste — just "build X" |
| 5-tier memory: captures durable decisions, patterns, and errors when hooks/CLI are healthy | Tabula rasa every session |
| Central orchestrator: `/workflow` runs research → audit → plan → spec → execute → verify with hard gates | Skills are isolated, no chaining |
| Health-checked capture: outcomes and reusable lessons can be logged to memory | Manual documentation |
| SPEC-first: write spec before code | Vague prompts, rebuild loops |
| Efficacy-first parallelism: use the right number of agents for the task | Sequential one-at-a-time |
| Independent verification pass with metadata when isolation can be proved | Casual self-checks |
| Research-first: `/workflow` drafts a plan, runs the repo’s effectiveness-first `deepresearch` `search -> read -> refine` investigation loop, and keeps an inspectable source ledger before planning or edits | AI hallucinates best practices |
| Surgical diffs: vague requests become verifiable contracts, then every meaningful change needs a changed-line trace to `SPEC.md` | Drive-by refactors, speculative abstractions, and "while I was here" churn |

**Taste is the kernel.** `/workflow` starts by checking taste.md and taste.vision. In a fresh repo, define them with `/tastebootstrap` before anything is built.

**Taste is NOT just frontend/aesthetic, and it is not a frontend/backend checklist.** It's the project's operating kernel — design principles, experience direction, interface contracts, observability rules, architecture constraints, code style, intent, non-goals, and values. When `/tastebootstrap` asks its 10 kernel questions, it captures the vision and guardrails that make the whole system coherent.

**Memory is durable when healthy.** minmaxing uses working-state handoffs, flat-file audit notes, and SQLite/FTS5 retrieval so reusable decisions, patterns, and failures can survive beyond one chat. Run `bash scripts/memory.sh health` when memory quality matters.

**Harness quality matters.** The point is not to pretend the model became smarter. The point is to reduce verification debt: force research, write the contract, preserve context, inspect assumptions, and prove the outcome before trust.

---

## Key Features

### Efficacy-First Parallelism
Spawn up to the hardware-aware ceiling when the task genuinely has bounded,
independent packets. Supervisor decomposes tasks, workers execute in parallel,
supervisor verifies.

```
Supervisor (you/AI)
├── Worker 1 → File A
├── Worker 2 → File B
├── Worker 3 → File C
... (up to 10)
└── Supervisor verifies all
```

Auto-detects your hardware: 32GB+ and 8+ cores -> 10 agents, 16GB and 4+ cores -> 6 agents, 8GB and 2+ cores -> 3 agents. For a live profile, run `bash scripts/parallel-capacity.sh --summary`.

The important part is not hitting the ceiling. The important part is using the smallest agent budget that preserves fresh context, clear ownership, and a shorter critical path.

### Planning Time Awareness
minmaxing estimates meaningful work in agent-native wall-clock terms before a
plan or `SPEC.md` is frozen. The required `Agent-Native Estimate` separates
elapsed agent wall-clock, total agent-hours, human touch time, calendar
blockers, critical path, and confidence.

Human-equivalent estimates are allowed only as secondary context. The harness
must not say "6 weeks" as the main estimate when the real plan is a 24/7
agent-native DAG with 5 effective lanes, or when the honest answer is
`blocked/unknown` because credentials, CI, deploy windows, or product decisions
are missing. Current local capacity evidence comes from
`bash scripts/parallel-capacity.sh --json`.

### Parallel Mode
`/parallel` is the dense-work orchestrator. It runs a Parallel Eligibility Audit,
reads the hardware capacity profile, chooses an execution substrate, writes a
Packet DAG and Ownership Matrix, inserts Sync Barriers, aggregates Worker Result
Schema returns, then verifies the aggregate against `SPEC.md`.

Execution substrate selection is explicit:
- `local` for one tight reasoning loop, shared files, low hardware, or high coordination cost.
- `subagents` as the default for bounded same-workspace research, audit, implementation, and review packets.
- `parallel-instances` only for large disjoint work where separate sessions or worktrees materially shorten elapsed time.
- `agent-teams` only as opt-in experimental behavior when explicitly enabled and fallback is documented.

`/workflow` may auto-consider `/parallel` for dense work, but it downgrades when
independent packets, file ownership, host capacity, or verification are weak.
Main stays orchestrator; workers do not own taste, architecture, SPEC,
security, registry, or final verification decisions.

### SPEC-First
File-changing tasks start with research, code audit, and a concrete plan. `SPEC.md` is the formal contract that comes out of that work, and AI implements to spec.

Even tiny local file-changing tasks should still produce a small `SPEC.md` when you invoke the full `/workflow` contract.

### Surgical Diff Discipline
minmaxing does not just ask the model to "be careful." It requires the smallest sufficient implementation, no speculative abstractions, no drive-by refactors, and a changed-line trace from meaningful diff hunks back to `SPEC.md`.

That means vague requests become verifiable contracts before code changes, and unrelated cleanup stays out of the diff unless the spec makes it necessary.

### Active SPEC + Archive
`SPEC.md` stays as the active contract in the project root so `/verify` and fresh agents always know what to read first.

Before a new task replaces a non-reused active spec, minmaxing archives the previous one under `.taste/specs/` with a descriptive task/outcome filename. Verified closeout archives the final spec too, deduplicated by content hash, so repeated closeouts do not create noisy copies.

### Independent Verification Pass
Verification is not a vibe check. `/verify` reads `SPEC.md`, checks every success criterion, records evidence, and now asks the workflow artifact to capture executor/verifier metadata when isolation is known. If the run cannot prove a separate agent/model/workspace, it must say `unknown` instead of pretending.

### Research-First
AI training data can be stale, and repo context can be incomplete. Current external facts get verified when they materially affect the plan; purely local tasks can justify a local-only research brief instead of doing fake research theater.

`/workflow` now treats a research brief as mandatory for all tasks, with the MiniMax MCP as the preferred source whenever current external facts matter. But the brief is not just a search tally. The workflow now uses the repo’s effectiveness-first `deepresearch` protocol: draft a collaborative research plan, run an iterative search -> read -> refine loop, keep a source ledger, challenge conflicting evidence, and do targeted follow-up research before freezing the plan. It still uses up to `MAX_PARALLEL_AGENTS` tracks, but only when the added tracks are distinct and plan-changing. For a purely local task, it can justify a local-only research brief instead of doing pointless external calls.

### Agent Factory
`/agentfactory` is a governed workflow for creating Hermes agents, not a prompt template. It uses the same effectiveness-first spine as `/workflow`: taste gate, 12-question intent intake, deepresearch brief, runtime audit, capacity-aware runtime contract, manifest, least-privilege capability stack, Hermes `SPEC.md`, generated agent files, hard-gate introspection, independent verification, registry closeout, and memory integration.

A Hermes agent can operate one workflow, one department lane, or one bounded subsystem. A fleet can operate a larger business process only by composing narrow agents with explicit handoffs, not by giving one agent omnipotent company authority.

Agent Factory writes its own run artifact under `.taste/workflow-runs/*-agentfactory.md` and keeps the durable registry in `hermes-registry.md`. The secondary factory taste contract lives in `hermes-factory.taste.md`. Production status requires `hermes.runtime.json`, `development_host_profile`, `target_runtime_profile`, `host_capacity_profile`, `capacity_binding`, `concurrency_budget`, queue/backpressure behavior, `degrade_policy`, a passing kill-switch test, verifier metadata, source ledger, memory-coherence check, runtime evidence, and registry links to manifest, spec, verify, kill-switch, and runtime artifacts. The local `scripts/parallel-capacity.sh` profile describes the developer machine unless the target runtime is explicitly local; a cloud server, VPS, container host, CI runner, managed workflow runtime, or REVCLI fleet needs its own target runtime capacity evidence before an agent can be marked active. The dedicated `scripts/agentfactory-smoke.sh` stress test keeps the skill from regressing into a checklist by checking negative fixtures such as raw secrets, read-only agents with write actions, missing capacity budgets, untested kill switches, active `operator_exception`, and verifier overclaims.

For REVCLI/Revis-style products, `/agentfactory` treats Hermes as the role-scoped interaction/runtime shell, REVCLI/Revis as the policy and audit control plane, and Odoo or the configured database as the system of record. The repo includes `REVCLI_HERMES_AGENT_MAP.md` so generated agents map to concrete roles, approval gates, runtime evidence, kill switches, and closed-loop outcomes instead of broad “run the company” authority.

### Permission Mode
- **Project default:** provider-neutral trusted-local `bypassPermissions` with governance hooks and secret-read denies. Warning: this allows Claude Code to act without normal permission prompts, so use it only where you accept local operator risk.
- **solo-fast option:** tracked example of the same trusted-local fast profile for personal repos where you want fewer prompts.
- **Team-safe option:** copy [`.claude/settings.team-safe.example.json`](.claude/settings.team-safe.example.json) to your local settings and keep `defaultMode` at `acceptEdits`.
- **OpusWorkflow default:** use `/opusworkflow` as the recommended daily mode so Opus is reserved for judgment checkpoints while MiniMax-M2.7-highspeed does bounded execution packets.
- **OpusMiniMax option:** use `/opusminimax` directly when you need benchmark or repair mode, or lower-level packet control.
- If you want even more guardrails, switch your local Claude session to `plan` before high-risk work.

### OpenAI Codex Plugin
This repo now ships a project-scoped Codex config under [`.codex/config.toml`](.codex/config.toml) plus focused Codex agents in [`.codex/agents/`](.codex/agents) so the official OpenAI Claude Code plugin can inherit sane defaults when you use Codex from inside Claude Code.

Research-backed take:
- The best plugin for using Codex inside Claude Code is the official OpenAI [`openai/codex-plugin-cc`](https://github.com/openai/codex-plugin-cc).
- It is explicitly built for Claude Code users, uses your local `codex` CLI plus Codex app server, and picks up user-level or project-level `.codex/config.toml`.
- It does not force parallelism by itself. OpenAI’s Codex docs say subagents are only spawned when you explicitly ask for them, so effective concurrency comes from your prompt plus the project `max_threads` ceiling.
- I found no official source saying this official plugin violates OpenAI terms. This is not legal advice, but the repo itself documents Claude Code installation and current OpenAI Terms/Usage Policies do not appear to prohibit this official integration when used compliantly.

What this repo config gives Codex:
- Main Codex default: `gpt-5.5` with `medium` reasoning and detailed reasoning summaries
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

### Temporal Anchor
Claude Code models do not know the present date from pretraining. minmaxing
injects a fresh local-system-clock anchor through `.claude/hooks/time-anchor.sh`
at session start and before each user prompt. The same anchor is written into
`.minimaxing/state/CURRENT.md` snapshots.

Use it directly when needed:

```bash
bash scripts/time-anchor.sh text
```

For "today", "latest", "current", "recent", "SOTA 2026", pricing, models,
provider behavior, laws, docs, benchmarks, schedules, or news, research must
resolve dates against that anchor and verify live sources. If live verification
is not available, the correct answer is `insufficient_data`, stale, or
unverified, not a confident pretrained-memory claim.

### Central Orchestrator
`/workflow` owns the full lifecycle inline: taste gate, deep research, code audit, hard-gate introspection, plan, `SPEC.md`, implementation, verification, and closeout. For file-changing tasks it also leaves a workflow artifact under `.taste/workflow-runs/` and archived specs under `.taste/specs/` so the research plan, loop log, source ledger, audit, introspection, plan, and spec trail stay inspectable. Specialist skills still exist, but `/workflow` no longer depends on nested custom-skill chaining to finish the job.

`/digestflow` is the report-informed sibling route. It adds Report Intake before deep research so Gemini, NotebookLM, ChatGPT Deep Research, Perplexity, or similar reports become provisional evidence instead of hidden assumptions.

---

## How the Workflow System Works

### Taste as OS, Skills as System Calls

Think of minmaxing as an operating system:

```
┌─────────────────────────────────────────────────────┐
│                    /opusworkflow                    │
│        (Default Claude judgment + MiniMax execution) │
│                      /workflow                      │
│                  (Lifecycle Engine Underneath)       │
├─────────────────────────────────────────────────────┤
│  PHASE 0: TASTE CHECK [GATE]  ← taste.md + vision │
│  PHASE 1: ROUTE                                     │
│  PHASE 2: DEEP RESEARCH (plan -> search -> read -> refine) │
│  PHASE 3: CODE AUDIT                               │
│  PHASE 3.5: INTROSPECT [HARD GATE]                 │
│  PHASE 4: PLAN                                     │
│  PHASE 5: SPEC.md                                  │
│  PHASE 6: EXECUTE                                  │
│  PHASE 6.5: INTROSPECT [HARD GATE]                 │
│  PHASE 7: VERIFY                                   │
│  PHASE 8: CLOSEOUT                                 │
├─────────────────────────────────────────────────────┤
│            taste.md + taste.vision                  │
│                  (Kernel / OS)                     │
├─────────────────────────────────────────────────────┤
│  /opusminimax /digestflow /autoplan /verify /ship │
│  /sprint /investigate /memory                     │
│  /audit /council /qa /review /deepresearch        │
│  /webresearch /browse /introspect /codesearch     │
│  /overnight /align /agentfactory                 │
│              (System Calls)                          │
└─────────────────────────────────────────────────────┘
```

**Taste is the kernel.** Every operation checks against your taste.md and taste.vision first. If the kernel is missing, stop and define it with `/tastebootstrap` before execution. Taste covers the full project philosophy — design principles, architecture, code style, intent, non-goals, and values.

**Skills are system calls.** Each skill does one thing well. They are still useful directly, but `/opusworkflow` is the default daily entrypoint and `/workflow` is responsible for finishing the underlying end-to-end lifecycle itself.

**/opusworkflow is the daily shell.** It is the default top-level route for normal build/plan work: Claude/Opus handles judgment checkpoints when proven available, and MiniMax-M2.7-highspeed handles bounded execution packets.

**/workflow is the lifecycle underneath.** It routes tasks to the right phase, performs live research, audits the repo, synthesizes the plan, writes `SPEC.md`, executes the work, verifies output, and gates progression. Use it directly when you explicitly want one local supervisor loop or the provider split is unavailable.

Inside Phase 2, `/workflow` now follows the repo’s effectiveness-first `deepresearch` protocol instead of a generic search fan-out: it drafts a collaborative research plan, launches only the discovery tracks that matter, reads and refines in loops, records a source ledger including reviewed but not cited sources, pressure-tests conflicting evidence, and runs follow-up research before locking the plan.

Before research planning for file-changing work, `/workflow` records a compact `## Metacognitive Route` that explains task class, capacity evidence, effective parallel budget, chosen route, evidence required, confidence threshold, and why the full parallel ceiling was or was not used. This is the steering record; it comes before `## Research Brief` and does not satisfy later `/introspect` gates.

Before confidence is allowed, `/workflow` runs the repo’s hard-gate `/introspect` protocol. It names likely mistakes, checks assumptions, looks for counterexamples, compares implementation against `SPEC.md`, identifies missing verification, downgrades confidence when evidence is weak, and blocks closeout or push when unresolved findings remain.

Before closeout, `/workflow` also applies surgical diff discipline: smallest sufficient implementation, no speculative abstractions, no drive-by refactors, and a changed-line trace for the meaningful diff. This keeps autonomy from turning into "helpful" churn.

### The 4 Execution Paths

| When you say... | /workflow routes to... |
|-----------------|----------------------|
| "build X", "implement Y" | deep research → code audit → plan → `SPEC.md` → implement → verify → closeout |
| "fix Z", "debug this" | deep research → code audit → plan → `SPEC.md` when files change → reproduce/fix → verify → closeout |
| "explain" | deep research → inspect → explain |
| "refactor", "optimize" | deep research → code audit → plan → `SPEC.md` → implement → verify → closeout |
| "audit this", "analyze" | deep research → inspect → findings |

### 5-Tier Memory System

Memory is layered and inspectable, not magic. It captures task state, durable decisions, reusable patterns, error fixes, and causal notes when the hooks and CLI are healthy:

| Tier | What | When |
|------|------|------|
| Episodic | Session start/end | Every shell start/exit |
| Semantic | Decisions & principles | `/council` decisions, `/align` verdicts |
| Procedural | Code patterns | `/codesearch` findings, `/sprint` outcomes |
| Error-Solution | Bugs & fixes | `/investigate` fixes, `/verify` failures |
| Graph | Causal chains | What caused success/failure |
| Commit Log | Git commit summaries | Every `git commit` (auto-summarized) |

Memory uses flat-file audit notes plus SQLite-backed FTS5 search when the Python memory CLI is available. Type `bash scripts/memory.sh health` to see whether the current repo is `healthy`, `degraded`, or `disabled`.

**Commit auto-summarize:** Every `git commit` triggers `commit-summarize.sh` via a git post-commit hook, generating `obsidian/Memory/Stories/commits/{date}-{hash}.md` with structured frontmatter and a brief summary. Also written to SQLite for agent retrieval.

### Working State vs Memory

`.minimaxing/state/CURRENT.md` is the short-lived working state that survives compaction. It is generated by hooks and should be reconciled with live repo state before edits.

SQLite memory is the durable layer for reusable lessons. When a decision, pattern, error fix, or research finding should survive future tasks, log it with `bash scripts/memory.sh add ...` instead of stuffing it into `CURRENT.md`.

---

## From 0 to 100: Fresh Folder

### Step 1: Install

Run the clean/new-folder command from the top of this README.

### Step 2: Define Your Taste

Claude opens at the end of setup. If you closed it, run `claude`.

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
- **Verification** — independent evidence pass against spec, with isolation metadata when known
- **Closeout** — local completion by default, remote push only when you explicitly ask for it
- **Memory** — durable lessons logged to 5-tier memory when the health check supports it

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
```

Then run the existing-project/updater command from the top of this README.

This imports or updates minmaxing harness files without overwriting your
existing code. If a harness file path already exists and was not previously
imported by minmaxing, setup leaves it untouched and prints a conflict warning.

### Step 2: Define Taste for This Project

Claude opens at the end of setup. If you closed it, run `claude`.

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

## The 34 Skills

| Skill | What It Does |
|-------|-------------|
| `/tastebootstrap` | **Fresh-repo bootstrap** — asks the 10 kernel questions and writes `taste.md` + `taste.vision` |
| `/workflow` | **Central execution engine** — drives research → code audit → plan → Agent-Native Estimate → `SPEC.md` → implement → verify → closeout (supervises an efficacy-first agent budget) |
| `/opusworkflow` | **Recommended cost-optimized daily mode** — runs `/opusminimax --mode workflow` with Opus reserved for judgment and MiniMax-M2.7-highspeed as the executor |
| `/opusminimax` | **Primary split-execution mode** — Claude/Opus plans, adversarially reviews, and verifies while MiniMax-M2.7-highspeed executes bounded coding packets |
| `/visualize` | **Taste-to-artifact comprehension check** — creates ignored visual, diagram, prompt, or narrative artifacts without implementation |
| `/visualizeworkflow` | **Approval-first workflow** — drafts SPEC + visualization, stops at `WAITING_FOR_VISUAL_APPROVAL`, then continues only with `--continue` |
| `/demo` | **Governed recorded demo pipeline** — produces product recordings with Playwright evidence, bilingual voiceover, captions, manifests, and safety gates |
| `/digestflow` | **External-report-informed workflow** — digests 1-10 AI research reports as untrusted candidate evidence, then runs the full governed workflow |
| `/deepretaste` | **Intent-to-ICP-to-taste bootstrap** — detects product intent, uses `/deepresearch` for taste-driving evidence, defines ICPs, and bootstraps or proposes/applies taste changes through `/tastebootstrap` or `/defineicp` semantics |
| `/defineicp` | **ICP-to-taste evolution** — defines primary/secondary/anti-ICPs with deepresearch, drafts taste.md + taste.vision changes, and applies only with explicit approval |
| `/icpweek` | **ICP week-in-the-life stress test** — simulates Monday-Sunday real usage with ideal-user, CTO, and senior product-engineer lenses, then delivers the A-J product diagnosis |
| `/align` | Validate idea against taste + vision. Gates /workflow on taste mismatch. |
| `/audit` | Deep codebase audit with risk-based parallelism |
| `/autoplan` | Generate SPEC.md with parallel execution and Agent-Native Estimate in mind |
| `/agentfactory` | Create governed runtime-bound Hermes agents with manifest, `hermes.runtime.json`, capability stack, memory seed, verification, registry, and tested kill switch |
| `/parallel` | Run hardware-aware whole-workflow parallel orchestration with packet DAG, ownership matrix, sync barriers, and aggregate verification |
| `/metacognition` | Parallel-aware control plane for task routing, evidence-grounded reflection, confidence calibration, and verified learning |
| `/claudeproduct` | Official-source answers for Claude, Claude Code, Claude.ai, Anthropic API, connectors, plugins, skills, hooks, MCP, and subagents |
| `/hive` | Governed multi-agent coordination with role map, blackboard, dissent, synthesis, and verified evidence |
| `/hiveworkflow` | Full workflow mode for hive-coordinated planning, execution, aggregation, introspection, and verification |
| `/sprint` | Run an ownership-safe parallel execution wave |
| `/verify` | Check output against SPEC with an independent evidence pass |
| `/review` | AI review + you decide |
| `/qa` | Playwright E2E testing — Pass/Fail only |
| `/ship` | Pre-ship checklist + rollback plan |
| `/investigate` | Debug with 3-fix limit |
| `/overnight` | 8hr session with 30-min checkpoints |
| `/council` | Multi-perspective analysis |
| `/deepresearch` | Deep multi-pass investigation with source ledgers and follow-up loops |
| `/webresearch` | Current web/docs/API verification using the same effectiveness-first method |
| `/browse` | Backward-compatible alias to `/webresearch` or `/deepresearch` |
| `/introspect` | Hard-gate self-audit for likely mistakes, assumptions, missing verification, and confidence downgrades |
| `/codesearch` | Search code by pattern |
| `/memory` | 5-tier memory system — log decisions, search patterns |

**Parallelism:** All skills that support parallelism treat `MAX_PARALLEL_AGENTS`, Codex `max_threads`, and hardware capacity as ceilings, not targets. `/align` remains single-threaded by design because taste alignment is sequential judgment.

## Smart Autorouting

minmaxing has smart autorouting through `/metacognition` and `/workflow`.
Before file-changing work, the harness classifies the task, reads capacity
evidence, computes the smallest useful budget, and chooses the route with the
least coordination overhead that can still improve correctness.

The routing ladder is:

```text
/opusworkflow as the daily default for build/plan work
-> local /workflow when the hybrid provider split is unavailable or explicitly bypassed
-> /deepretaste when product intent, ICP, and taste kernel need a SOTA-2026 research-backed bootstrap or retaste
-> /defineicp when the product kernel needs ICP research before taste changes
-> /opusminimax when Opus should plan/review and MiniMax should execute packets in workflow/benchmark/repair mode
-> /parallel when independent execution packets are enough
-> /claudeproduct for Claude, Claude Code, Claude.ai, API, connector, plugin,
   skill, hook, MCP, subagent, availability, limit, model, or setup questions
-> /hive or /hiveworkflow when coordinated roles, blackboard state, dissent,
   and synthesis materially improve the outcome
-> blocked when evidence, ownership, capacity, or verification is missing
```

Use this rule of thumb:

| Pick | When | The Developer Should Expect |
| --- | --- | --- |
| `/opusworkflow` | You want the daily default for a Claude subscription plus MiniMax Plus-Highspeed: Opus only at plan/review/ship gates and MiniMax for bulk implementation. | One-command split setup, provider doctor, default executor concurrency 1, bounded packets, parent verification, and no silent PAYG. |
| local `/workflow` | One tight reasoning loop, one shared file, unclear ownership, or coordination would slow the work down. | One supervisor does the whole governed lifecycle. |
| `/deepretaste` | You need to detect product intent, define ICPs, and bootstrap or retaste the project kernel from research-backed customer evidence. | `/deepresearch` remains general-purpose; `/deepretaste` uses it only for taste-driving evidence, then routes fresh kernels through `/tastebootstrap` and existing kernels through `/defineicp` proposal/apply semantics. |
| `/defineicp` | You need to define the ICP or ICPs and tailor `taste.md` / `taste.vision` to that customer profile. | Deepresearch plan, primary/secondary/anti-ICPs, source and claim ledgers, taste patch proposal, explicit apply approval, backups, hashes, validation, and rollback evidence. |
| `/opusminimax` | You want to squeeze a Claude subscription by using Opus only for planning, adversarial review, and final judgment while MiniMax does speed/bulk execution. | Provider split doctor, Opus planner artifact, MiniMax executor packets, quota-aware concurrency, parent verification, and no benchmark overclaims. |
| `/claudeproduct` | The question is about Claude, Claude Code, Claude.ai, Anthropic API, connectors, plugins, skills, hooks, MCP, subagents, availability, limits, models, or setup. | Official Anthropic/Claude docs first, surface separation, source ledger, connector permission/trust caveats, confidence downgrade when current docs are missing. |
| `/parallel` | The work splits into independent packets with clear owned files/surfaces and aggregate verification. | Packet DAG, ownership matrix, sync barriers, worker sidecars, `parallel-aggregate`. |
| `/hive` | The task needs multiple perspectives but may not need a full file-changing workflow: research branches, adversarial review, planning alternatives, risk ranking, or synthesis. | Queen/supervisor, role map, blackboard, dissent/conflict log, evidence-backed synthesis. |
| `/hiveworkflow` | The entire implementation lifecycle benefits from hive coordination and packet execution: broad audit plus implementation, multi-surface build, high-stakes verification, or agent/fleet design. | Full workflow plus hive artifact, `hive-run.json`, optional `/parallel` packets, `hive-aggregate`, `/introspect`, `/verify`. |

Do not pick `/hive` because it sounds more powerful. Pick it when role
specialization and dissent improve judgment. Do not pick `/parallel` because
there are available lanes. Pick it when disjoint ownership and aggregation make
the critical path shorter or the evidence better.

If both seem possible, default to `/parallel` for execution throughput and to
`/hive` for judgment breadth. Use `/hiveworkflow` only when the task needs both.

**Metacognitive routing:** `/metacognition` steers work before execution by
classifying the task, reading capacity evidence, computing the effective
parallel budget, naming required evidence, and routing to `/workflow`,
`/claudeproduct`, `/deepresearch`, `/parallel`, `/hive`, `/hiveworkflow`, `/agentfactory`,
`/verify`, `/introspect`, or a blocked state. It is upstream steering, not a
substitute for `/introspect`; required introspection triggers still need
explicit blocker decisions. It does not depend on raw hidden chain-of-thought
and it rejects reflection without evidence. Use
`bash scripts/metacognition-scorecard.sh --fixtures --json` to prove the static
contract.

**Claude product knowledge:** `/claudeproduct` answers user and harness
questions about Claude product behavior from official current docs. It is the
right path for "how do we use X from Claude?", Claude Code configuration,
skills, hooks, MCP, subagents, Claude.ai Projects, Artifacts, connectors,
Research, web search, API/platform behavior, availability, limits, and setup.
It separates Claude Code, Claude.ai, Desktop, Mobile, API, and MCP connector
surfaces, includes connector permission/trust caveats, and never reads `.env`
or secrets for product-doc answers. Use
`bash scripts/claudeproduct-scorecard.sh --fixtures --json` to prove stale
memory answers and unsupported Claude claims are rejected.

**Harness capability map:** `docs/harness-capability-map.md` and
`docs/harness-capability-map.json` are generated from repo truth surfaces and
act as the canonical self-lookup index for minmaxing capabilities. They list
skills, route groups, rules, required script gates, static evals, hooks, and
Codex surfaces without reading secrets. Regenerate and verify them with
`bash scripts/harness-capability-map.sh` and
`bash scripts/harness-capability-map.sh --check`.

**Hive coordination:** `/hive` adds governed multi-agent coordination above
`/parallel`: a queen/supervisor, capability-based roles, visible blackboard,
dissent/conflict log, evidence-backed synthesis, and verification. Use
`/hiveworkflow` only when the whole file-changing lifecycle benefits from that
coordination. Hive reuses `/parallel` packet DAGs, ownership matrices,
sidecars, and aggregation for execution; hive runs also emit
`.taste/hive/{run_id}/hive-run.json` validated by `artifact-lint` and
`hive-aggregate`. Consensus never replaces
`/introspect`, `/verify`, `/workflow`, or command evidence. Use
`bash scripts/hive-scorecard.sh --fixtures --json` and
`bash scripts/hive-aggregate.sh --fixtures` to prove the static contract.

**Visualization approval:** `/workflow` stays autonomous. Use `/visualize` when you only want to see the model's understanding, and `/visualizeworkflow` when you want a draft spec plus visual or operational artifact to approve before implementation.

**Effectiveness gates:** The harness is designed to steer LLMs away from lazy completion. Claude Code runtime hooks and local smokes reject destructive Bash, evidence-free closeout, failed-verification positive closeout, fake source ledgers, tests-passed claims without command evidence, unverified worker claims, shallow metacognition, stale Claude product answers, shallow hive consensus, and linear lane-scaling claims. Use `bash scripts/harness-scorecard.sh --json`, `bash scripts/metacognition-scorecard.sh --fixtures --json`, `bash scripts/claudeproduct-scorecard.sh --fixtures --json`, `bash scripts/hive-scorecard.sh --fixtures --json`, `bash scripts/hook-smoke.sh`, `bash scripts/codex-run-smoke.sh`, and `bash scripts/parallel-plan-lint.sh --fixtures` to prove the first-slice gates.

**Artifact sidecars:** Markdown remains the human contract, but machine gates can consume minimal JSON sidecars for agent-native estimates, verification results, and worker results. Validate the local fixtures with `bash scripts/artifact-lint.sh --fixtures`.

**Static harness evals:** `evals/harness/tasks` and `evals/harness/golden` define local no-network eval tasks over the harness gates. Run `bash scripts/harness-eval.sh --json` or `bash scripts/harness-eval-report.sh --run` to score the current harness behavior.

**Run metrics and session insights:** `bash scripts/run-metrics.sh --json` summarizes local workflow/eval/Codex artifacts, and `bash scripts/session-insights.sh --json` flags unhealthy runs. Missing provider cost, token, ACU, or calibration data is reported as `insufficient_data`.

**Runtime hardening:** `bash scripts/runtime-hardening-smoke.sh` proves the
local trace ledger, hook mesh, worktree runner, scenario evals, learning loop,
and harness doctor without secrets or network access. See
`docs/runtime-hardening.md` for the operator surface.

**Security profiles:** this repo's default is trusted-local `bypassPermissions` for the operator's solo loop. `solo-fast` documents that posture, `team-safe` is the shared-work fallback, `ci-static` is no-secret static validation, and `ci-runtime` is isolated authenticated validation. Run `bash scripts/security-smoke.sh` after profile changes.

**Release governance:** Public harness work should pass `bash scripts/release-check.sh --static-only`. The static GitHub Actions lane runs without secrets; authenticated runtime checks are isolated in the manual/scheduled runtime lane.

---

## Usage

**The full workflow — one command:**
```bash
claude
/workflow "build a REST API for users"
```

`/workflow` now owns the whole lifecycle inline: taste check → `deepresearch` / `webresearch` → code audit → plan → `SPEC.md` → implementation → verification → closeout.

**Report-informed workflow:**
```bash
/digestflow "implement auth hardening based on these reports" ./gemini-report.md ./notebooklm-notes.md
```

`/digestflow` starts with Report Intake. It treats external AI reports as untrusted candidate evidence, labels imported claims `report-derived`, quarantines prompt-like instructions, records contradictions, and then runs the repo's own deepresearch plus the full workflow before any implementation is trusted.

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

For `/opusworkflow`, prove the planner side separately before claiming Opus
runtime identity:

```bash
unset ANTHROPIC_API_KEY ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN
claude auth login
bash scripts/opusminimax-doctor.sh --runtime
claude --model claude-opus-4-7 --settings .claude/settings.opusminimax-planner.local.json -p 'Reply exactly: OPUSWORKFLOW_AUTH_OK'
```

Current local runtime evidence recorded on 2026-05-06: Claude Pro auth and the
Opus 4.7 planner sentinel were proven by operator test. MiniMax live executor
packet runtime remains pending until an explicit tiny executor packet is run.

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

Once the repo is trusted, Codex loads [`.codex/config.toml`](.codex/config.toml):

- `model = "gpt-5.5"`
- `model_reasoning_effort = "medium"`
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
- The shared project standard is already `--model gpt-5.5 --effort medium`; use explicit CLI overrides only for temporary one-off experiments.

---

## Requirements

| | |
|---|---|
| Claude Code | 2.1+ (`npm install -g @anthropic-ai/claude-code`); Opus 4.7 planner mode expects 2.1.111+ |
| Python | 3.11+ |
| MiniMax API Key | [platform.minimax.io](https://platform.minimax.io) |
| Claude Subscription | Required for subscription-backed Opus planner usage; verify with `claude auth status --text` plus the `OPUSWORKFLOW_AUTH_OK` sentinel |
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

Override in your shell or ignored local profile:
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
├── OPEN_CORE_STRATEGY.md         # OSS core vs private moat operating boundary
├── COMMERCIAL.md                 # Managed-service and enterprise boundary
├── SECURITY.md                   # Vulnerability reporting and secret handling
├── TRADEMARKS.md                 # Brand, fork, and certification limits
├── NOTICE                        # Apache-2.0 attribution notice
├── setup.sh                     # One-command installer
├── taste.md                     # Project operating kernel — created by /tastebootstrap
├── taste.vision                 # Product intent + tradeoff contract — created by /tastebootstrap
├── AGENTS.md                    # Project instructions for Codex
├── REVCLI_HERMES_AGENT_MAP.md    # REVCLI/Revis runtime-ready Hermes agent portfolio
├── .codex/
│   ├── config.toml             # Project-scoped Codex defaults
│   └── agents/                 # Codex custom agents for research/review
├── .claude/
│   ├── settings.json           # Provider-neutral governance config
│   ├── settings.opusminimax-planner.example.json
│   ├── settings.minimax-executor.example.json
│   ├── hooks/                  # Lifecycle hooks, including working-state rehydration
│   ├── skills/                 # 34 skills (system calls)
│   │   ├── workflow/           # Central execution engine
│   │   ├── opusworkflow/       # Cost-optimized daily Opus + MiniMax route
│   │   ├── opusminimax/        # Opus planner + MiniMax executor mode
│   │   ├── visualize/          # Taste-to-artifact comprehension check
│   │   ├── visualizeworkflow/  # Approval-first workflow route
│   │   ├── demo/               # Recorded product demo route
│   │   ├── digestflow/         # External report intake + governed workflow
│   │   ├── deepretaste/        # Intent-to-ICP-to-taste bootstrap/retaste
│   │   ├── defineicp/          # ICP-to-taste evolution route
│   │   ├── icpweek/            # ICP week-in-the-life product stress test
│   │   ├── tastebootstrap/     # Fresh-repo taste bootstrap
│   │   ├── align/              # Taste gate
│   │   ├── audit/              # Deep codebase analysis
│   │   ├── autoplan/           # SPEC.md generator
│   │   ├── agentfactory/       # Governed Hermes agent generator
│   │   ├── parallel/           # Hardware-aware workflow parallelizer
│   │   ├── claudeproduct/      # Official Claude product knowledge router
│   │   ├── hive/               # Governed multi-agent coordination
│   │   ├── hiveworkflow/       # Full hive-coordinated workflow
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
│   │   ├── introspect/         # Hard-gate self-audit
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
│   ├── harness-capability-map.sh # Generated harness capability map
│   ├── parallel-capacity.sh     # Hardware-aware parallel budget profile
│   ├── parallel-smoke.sh        # Parallel mode production-contract smoke test
│   ├── agentfactory-smoke.sh    # Agent Factory production-contract smoke test
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

## License

minmaxing is licensed under [Apache-2.0](LICENSE).

The open-source license covers this public core. It does not grant rights to
private REVCLI/Revis runtime code, customer deployments, customer data,
production credentials, managed-service operations, or project branding beyond
the limited trademark language in Apache-2.0. See
[COMMERCIAL.md](COMMERCIAL.md) and
[TRADEMARKS.md](TRADEMARKS.md) for the
commercial and brand boundary.
