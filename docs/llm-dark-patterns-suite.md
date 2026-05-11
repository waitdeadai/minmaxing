# LLM Dark Patterns Hooks Suite — bundled with minmaxing

This harness ships ten single-purpose Stop hooks that suppress LLM dark-pattern defaults at the textual boundary. The hooks live in `.claude/hooks/` and are wired into Claude Code's `Stop` / `SubagentStop` / `PreCompact` / `PostCompact` / `SessionStart` events via `.claude/settings.json`.

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
| `honest-eta.sh` | vibe time estimates + linear-scaling parallelism claims | [honest-eta](https://github.com/waitdeadai/honest-eta) |

### Fact-fabrication branch — catches *what* the model claims

| Hook script | Catches | Standalone repo |
|---|---|---|
| `no-fake-recall.sh` | "as we discussed earlier" without quoted prior content | [no-fake-recall](https://github.com/waitdeadai/no-fake-recall) |
| `no-fake-stats.sh` | precise percentages / dollar amounts / large counts without source | [no-fake-stats](https://github.com/waitdeadai/no-fake-stats) |
| `no-fake-cite.sh` | academic citation patterns ("Smith et al., 2023", "[1]", "doi:") without verifiable URL | [no-fake-cite](https://github.com/waitdeadai/no-fake-cite) |

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
