# LLM Dark Patterns Hooks Suite — bundled with minmaxing

This harness ships **28 single-purpose Stop hooks** that suppress LLM dark-pattern defaults at the textual boundary. The hooks live in `.claude/hooks/` and are wired into Claude Code's `Stop` / `SubagentStop` / `TaskCreated` / `TaskCompleted` / `PreToolUse` / `PostToolUse` / `PreCompact` / `PostCompact` / `SessionStart` / `UserPromptSubmit` events via `.claude/settings.json`.

**Loadable packs architecture** (Phase 1+3+4 of the upstream roadmap, integrated 2026-05-11): vocabulary, evidence binaries, and destructive command lists are now external `.txt` files under `.claude/packs/`. Operators extend without forking by dropping a `.txt` at `${XDG_CONFIG_HOME:-$HOME/.config}/llm-dark-patterns/packs/<subdir>/<name>.txt`. The shared loader at `.claude/lib/packs.sh` provides `active_locales`, `resolve_pack_paths`, `load_pack_section`, `load_locale_section`.

**Locale coverage**: en (built-in baseline) + es + pl + de + fr + pt (bootstrap; native-speaker PRs welcome). Activated via `LLM_DARK_PATTERNS_LOCALE=en,es,pl` env or auto-detected from `LANG`.

The same hooks are also published as standalone repositories under the [`waitdeadai/llm-dark-patterns`](https://github.com/waitdeadai/llm-dark-patterns) umbrella, so anyone can install one or two without taking the whole minmaxing harness. The methodology behind the suite is documented at [`waitdeadai/llm-dark-patterns/METHODOLOGY.md`](https://github.com/waitdeadai/llm-dark-patterns/blob/main/METHODOLOGY.md).

## What's wired

### Interaction-style branch — catches *how* the model talks

| Hook script | Catches | Standalone repo |
|---|---|---|
| `govern-effectiveness.sh` | false-success closeouts (positive vocabulary without evidence) — the original `no-vibes` mechanism, kept under its harness-native name | [no-vibes](https://github.com/waitdeadai/no-vibes) |
| `time-anchor.sh` | training-cutoff confusion (no current-date awareness) | [time-anchor](https://github.com/waitdeadai/time-anchor) |
| `no-curfew.sh` | unsolicited rest/wellness paternalism in agent-mode sessions | [no-curfew](https://github.com/waitdeadai/no-curfew) |
| `no-sycophancy.sh` | praise-spam at turn open ("Great question!") | [no-sycophancy](https://github.com/waitdeadai/no-sycophancy) |
| `no-cliffhanger.sh` | dangling permission-loop endings ("want me to continue?") | [no-cliffhanger](https://github.com/waitdeadai/no-cliffhanger) |
| `no-wrap-up.sh` | engagement-fishing closures ("anything else?", "hope this helps!") — DarkBench User Retention | [llm-dark-patterns](https://github.com/waitdeadai/llm-dark-patterns) (umbrella-only) |
| `honest-eta.sh` | vibe time estimates + linear-scaling parallelism claims | [honest-eta](https://github.com/waitdeadai/honest-eta) |
| `no-emoji-spam.sh` | message has > N emoji codepoints (default 3, configurable via `LLM_DARK_PATTERNS_EMOJI_THRESHOLD`) | umbrella-only |
| `no-tldr-bait.sh` | "TL;DR:" / "In summary:" / "Bottom line:" tail block on long messages (>200 chars) | umbrella-only |
| `no-meta-commentary.sh` | "Let me think about this" / "Now I'll consider" — narrating CoT instead of producing answer | umbrella-only |
| `no-prompt-restate.sh` | "You asked me to X" / "I understand you want X" — preamble waste | umbrella-only |
| `no-disclaimer-spam.sh` | "Please note that" / "It's important to mention" defensive padding | umbrella-only |
| `no-ai-tells.sh` | known LLM-default phrases ("delve into", "tapestry", "navigate the intricacies", etc.) | umbrella-only |
| `no-roleplay-drift.sh` | "as an AI assistant" / "I'm just an AI" — model breaking agent character | umbrella-only |

### Fact-fabrication branch — catches *what* the model claims

| Hook script | Catches | Standalone repo |
|---|---|---|
| `no-fake-recall.sh` | "as we discussed earlier" without quoted prior content | [no-fake-recall](https://github.com/waitdeadai/no-fake-recall) |
| `no-fake-stats.sh` | precise percentages / dollar amounts / large counts without source | [no-fake-stats](https://github.com/waitdeadai/no-fake-stats) |
| `no-fake-cite.sh` | academic citation patterns ("Smith et al., 2023", "[1]", "doi:") without verifiable URL | [no-fake-cite](https://github.com/waitdeadai/no-fake-cite) |
| `no-phantom-tool-call.sh` | "I ran `tool` and got X" without same-message structural output | umbrella-only |
| `no-rollback-claim-without-evidence.sh` | "I rolled back" / "reverted" / "undid" without same-message rollback command | umbrella-only |
| `no-sandbagging-disguise.sh` | "tried but couldn't" without specific blocker (Anthropic Opus 4.6 sabotage report) | umbrella-only |

### Multi-agent orchestration branch — catches +N-parallel-instance failure modes

| Hook script | Catches | Standalone repo |
|---|---|---|
| `no-aggregator-hallucination.sh` | supervisor "synthesizing the workers' results" without per-worker evidence (Beam AI 2026; arXiv:2603.04474) | umbrella-only |
| `no-silent-worker-success.sh` | "all N workers completed" without per-worker exit codes (arXiv:2604.14228) | umbrella-only |
| `no-cherry-pick-rollup.sh` | partial worker success + positive closeout without handling failed workers | umbrella-only |
| `no-ownership-violation.sh` | TaskCompleted edits files outside agent's declared owned_paths | umbrella-only |
| `no-handoff-loop.sh` | TaskCreated chain shows same agent_id 3+ times in delegation history | umbrella-only |

### Agentic safety branch — credential leak, sandbagging, approval-sneak

| Hook script | Catches | Standalone repo |
|---|---|---|
| `no-credential-leak-in-handoff.sh` | task delegation contains plaintext credentials (sk-*, ghp_*, AWS keys, Bearer, password=) — AgentLeak benchmark (arXiv:2602.11510) | umbrella-only |
| `no-approval-sneak.sh` | Edit/Write to operator-defined sensitive paths (.env*, secrets/, .kube/, terraform/state/, .ssh/, .gnupg/, prod/) without prior approval token | umbrella-only |

### Continuity branch — counters context loss rather than blocking output

| Hook script | Catches | Standalone repo |
|---|---|---|
| `state.sh` + `state-stop.sh` + `state-precompact.sh` + `state-postcompact.sh` + `state-sessionstart.sh` | context loss after Claude Code auto-compaction; snapshots working state on Stop / PreCompact / PostCompact, rehydrates on SessionStart | [no-amnesia](https://github.com/waitdeadai/no-amnesia) |

## Suite-wide design principles

All ten hooks share the same architecture:

1. **Out-of-band textual enforcement.** The judge is bash (or python3 for engine-heavier hooks). The model can't argue with grep.
2. **Trigger + redemption regex sets.** Bad pattern without redemption → block. Bad pattern with redemption → allow.
3. **Repair-template that teaches.** Every block returns a literal compliant shape via stderr. The model copies the template on the next turn.
4. **Conservative on purpose.** Hooks would rather false-positive on legitimate prose than false-negative on the actual dark pattern. Allow-clauses are explicit and documented in each hook's `RECEIPTS.md`.

See the [methodology document](https://github.com/waitdeadai/llm-dark-patterns/blob/main/METHODOLOGY.md) for the full design rationale and the playbook for shipping new hooks.

## Disabling individual hooks

Each hook is independent. To disable one:

1. Remove its entry from the relevant event matcher in `.claude/settings.json`.
2. Optionally remove the script from `.claude/hooks/`.

Removing a hook does not affect the others.

## Receipts

Every standalone hook repo ships with a `RECEIPTS.md` containing reproducible local fixture tests. Run them with `bash <hook>.sh < /tmp/<fixture>.json`. The same fixtures power each repo's GitHub Actions CI (badge in each README).
