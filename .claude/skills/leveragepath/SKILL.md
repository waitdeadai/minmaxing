---
name: leveragepath
description: Identify the highest-leverage actions for the current product based on taste.md, taste.vision, and SPEC.md, with deepresearch-backed channel scanning, RICE+categorization scoring, auto-vs-manual classification, community targets with verified URLs, and (when research surfaces moats or blind spots) a /defineicp-style proposal to update the kernel. Use when the user invokes /leveragepath or asks "what's the highest-leverage move I can make right now?"
argument-hint: [mode: scan|apply <move_id>|kernel-propose]
disable-model-invocation: true
---

# /leveragepath

Run the leverage-path workflow for:

$ARGUMENTS

`/leveragepath` finds the highest-leverage distribution, positioning, and
community moves available to the project right now, ranks them, separates
what Claude Code can run autonomously from what only the operator can do,
and — when deepresearch surfaces a moat or blind spot the dev was not
seeing — proposes a kernel update so the next iteration starts from the
new ground truth.

This command is not a marketing-checklist generator. It is a governed
research-then-route workflow: deepresearch first, ranked move synthesis
second, automation classification third, and kernel mutation only with
explicit `kernel-propose` opt-in and proposal/apply semantics.

For apply mode or any leverage-driven file mutation, `/opusworkflow` is the
default outer route and `/leveragepath` is the inner contract. Direct
`/leveragepath` invocation remains valid, but it must inherit the
Claude/Opus planner-reviewer plus MiniMax-M2.7-highspeed executor policy
before mutation.

```text
outer_route: opusworkflow
inner_contract: leveragepath
```

## When to use this

- The dev just shipped something and asks "where do I distribute?"
- The dev is stuck and asks "what's the highest-leverage move I can make
  right now?"
- The dev suspects they have a moat they are not articulating publicly.
- The dev keeps doing the same medium-leverage moves and wants a fresh
  surface scan.
- A community-led-growth or product-led-growth iteration is about to
  begin and the dev wants the canonical channel list before committing.

Not for: writing the actual marketing copy (use the regular `/workflow`
or specialist channel tools), verifying that an executed move worked
(use `/verify` against `SPEC.md`), or generating a generic checklist
(this is research-first).

## Inputs read at run start

- `taste.md`, `taste.vision` — what the project values, who it serves,
  what it refuses to do.
- `SPEC.md` (active) — what is currently shipping or just shipped.
- Latest `.taste/workflow-runs/*-workflow.md` — what the dev has already
  attempted recently.
- Recent git log — what surfaces have been touched in the last week.
- Any `.taste/leveragepath/*.md` from prior runs — moves already executed
  or already declined, to avoid re-suggesting.

This skill does NOT read `.env`, `.env.*`, `.claude/settings.local.json`,
`secrets/**`, customer artifacts, or private connector files.

## Modes

### `scan` (default)

Run the full leverage-path identification pipeline:

1. Read inputs above.
2. Define the project category (open-source dev tool? B2B SaaS? indie
   game? academic project?) — used to scope which channel surfaces apply.
3. Invoke `/deepresearch` with effective parallel budget on these
   branches (use only the lanes that materially help):
   - **Communities**: which Discord servers, Slack workspaces, subreddits,
     forums, mailing lists are active in this category in 2026?
   - **Marketplaces / directories**: which awesome-lists, plugin
     directories, app stores, package registries are canonical?
   - **Influencers / curators**: who covers this category on blogs,
     newsletters, podcasts, YouTube?
   - **Conferences / events / live windows**: anything time-sensitive
     in the next 30 days?
   - **Adjacent tools / collaborators**: who is building close-but-not-
     competing? PR / mention / collab opportunities?
   - **Academic surfaces**: arXiv, conference workshops, paper-citation
     lanes if the project has academic legitimacy.
4. For each move identified, compute a RICE-style score:
   - **R**each — estimated audience size of the channel (verified live).
   - **I**mpact — expected effect on the operator's stated goal (signups,
     stars, paying customers, citations, etc.) on a 0.25–3 scale.
   - **C**onfidence — how sure we are the move will land (60% / 80% /
     100%).
   - **E**ffort — total operator + Claude Code time in person-hours.
   - Score = (R × I × C) / E.
5. Add four orthogonal tags per move:
   - `auto` (Claude Code can run it via tools) | `manual` (operator only)
   - `community` (targeted) | `mass` (broad)
   - `time-sensitive` (window in next 30d) | `evergreen`
   - `reversible` (can undo in <1 day) | `hard-to-reverse` (public commit
     to a brand or relationship)
6. Run `/introspect` pre-write gate — challenge weak sources, missing
   surfaces, over-confidence in unverified channel sizes, missed
   blind spots.
7. Write the artifact to
   `.taste/leveragepath/<run_id>/leveragepath.md` with sections:
   - **Top 5 moves by RICE** (the leverage punch list)
   - **Auto-by-Claude Code** (with the exact tool calls it should run)
   - **Manual-by-operator** (with copy-paste assets where applicable)
   - **Time-sensitive (next 30 days)** (windows ranked by start date)
   - **Communities to target** (Discord/Slack/forum invite URLs verified
     live this run)
   - **Adjacent collaborators** (named, with public outreach surface)
   - **Moats observed** (research-surfaced advantages the dev is not
     publicly articulating)
   - **Blind spots observed** (channels or angles the dev has not
     considered, ranked by leverage)
   - **Source ledger** (cited / reviewed / rejected, with access date)
   - **Kernel mutation candidates** (if any — proposal-only, never
     applied in scan mode)

### `apply <move_id>`

Execute one move from the most recent `scan` artifact. Only `auto`-tagged
moves are eligible for `apply`; manual moves return a "blocked: operator
must execute" status.

Auto moves typically include:
- Open a GitHub issue or PR via `gh` CLI.
- Submit a directory-listing PR to an awesome-list.
- Update a static site with a positioning shift.
- Write and queue a draft email via `mailto:` link generation.
- Pin GitHub repos via API (where the operator has token).

`apply` mode runs the standard `/opusworkflow` outer route inside it:
SPEC fragment for the move, `/specqa`, execute, verify against the
move's success criteria from the scan artifact, post-execution
`/introspect`. Closeout records the move's outcome back to the scan
artifact for future iterations to skip.

### `kernel-propose`

Read the most recent `scan` artifact. Extract the **Moats observed** and
**Blind spots observed** sections. For each, produce a proposed diff to
`taste.md` and/or `taste.vision` that surfaces the moat in the project's
public positioning OR closes the blind spot in the project's strategic
view.

`kernel-propose` produces a proposal artifact only. It does NOT modify
`taste.md` or `taste.vision`. Apply uses the standard `/defineicp`
proposal/apply semantics: explicit operator approval, file backup, hash
record, changed-line trace, validation, rollback evidence.

## Required scoring shape

Every move in the artifact must include:

```markdown
### Move N: <short name>

| Field | Value |
|---|---|
| RICE | (R × I × C) / E = <score> |
| R (Reach) | <number with unit and live source> |
| I (Impact) | <0.25 / 0.5 / 1 / 2 / 3> with one-line rationale |
| C (Confidence) | <0.6 / 0.8 / 1.0> with one-line rationale |
| E (Effort) | <person-hours, sum operator + Claude Code time> |
| Auto/Manual | <auto with tool list, OR manual with reason> |
| Community/Mass | <community: target> OR mass |
| Time | <evergreen, OR sensitive: window start–end dates> |
| Reversibility | <reversible, OR hard-to-reverse with reason> |
| Blocker if any | <none, OR explicit blocker> |
| Next concrete step | <single command, URL, or copy-paste asset> |
```

The Top 5 list orders by descending RICE.

## RICE framework lineage

RICE (Reach × Impact × Confidence / Effort) is the canonical product
and growth prioritization framework as of 2026. Sources verified live:

- [Canny — 2026 product prioritization guide](https://canny.io/blog/product-prioritization-frameworks/)
- [ProductLift — RICE vs ICE vs MoSCoW comparison, Feb 2026](https://www.productlift.dev/blog/product-prioritization-framework-comparison/)
- [Plane.so — 2025 framework comparison (RICE recommended for growth teams)](https://plane.so/blog/rice-vs-ice-vs-kano-which-framework-works-best-in-2025-)

This skill uses RICE as one layer in a four-layer stack:
- Layer 1: RICE numeric ranking.
- Layer 2: auto/manual orthogonal tag.
- Layer 3: time-sensitivity orthogonal tag.
- Layer 4: reversibility orthogonal tag.

The numeric ranking decides ordering; the orthogonal tags decide which
moves the dev should execute first this hour vs this week vs this month.

## Sibling-skill integration

- `/deepresearch` is the research engine. `/leveragepath scan` invokes it
  internally with the effective parallel budget computed via
  `bash scripts/parallel-capacity.sh --json`.
- `/introspect` runs as the pre-write gate before the artifact is
  written. Same hard-block semantics as the rest of the harness.
- `/defineicp` is the kernel-mutation contract for `kernel-propose`
  mode. The proposal artifact uses the same shape: target file backup,
  hash, changed-line trace, validation, rollback.
- `/opusworkflow` is the outer route when `apply <move_id>` mutates
  files. Records `inner_contract=leveragepath` in the run artifact.
- `/icpweek` is a sibling product-stress lens, not a substitute. ICP
  week-in-the-life surfaces product mismatches with users; leveragepath
  surfaces channel mismatches with reach.
- `/visualizeworkflow --continue` may follow a leveragepath scan when
  the dev wants a visual of the channel surface before committing to
  any move.

## Hard rules (no exceptions)

- Every channel reach number must be verified live this run (citation
  with access date). No pretrained-memory-only audience sizes.
- Every community URL must be verified to resolve to an active
  surface this run. Dead/stale links flagged or removed.
- Move rankings must show R/I/C/E components, not just the score, so
  the operator can challenge the inputs.
- `apply` mode must not execute a move whose `Auto/Manual` field is
  `manual` — it returns "blocked: operator action required" instead.
- `kernel-propose` mode must not write to `taste.md` or `taste.vision`
  — the proposal is artifact-only; mutation requires a separate
  operator-triggered `/defineicp apply` invocation.
- The skill must surface at least one **moat** and at least one **blind
  spot** in scan mode, OR explicitly state "no moats / blind spots
  surfaced this run" with the introspection rationale. Silence is
  not acceptable.
- The artifact source ledger must list at least three distinct sources
  and may not consist entirely of the project's own surfaces.

## Anti-patterns

- One-shot search-and-summary masquerading as a leverage scan.
- Ranking only by reach (ignoring effort and confidence).
- Mixing automatable and manual moves in a single execute command.
- Recommending a time-sensitive move whose window already closed.
- Skipping `/introspect` because the channel list "looks complete."
- Proposing kernel changes in scan mode (kernel-propose is opt-in).
- Failing to cite live URLs for community / directory targets.
- Promising linear scaling: "post on N channels = N× the leverage" — same
  problem honest-eta blocks for time estimates.

## Output artifact contract

```
.taste/leveragepath/<run_id>/
  leveragepath.md            (the human-readable artifact)
  leveragepath.json          (the machine-readable summary, if scripts
                              are added in v2; v1 ships markdown only)
  source-ledger.md           (cited / reviewed / rejected sources;
                              optional — may be inlined in leveragepath.md
                              for v1)
```

Run IDs use the convention `YYYYMMDD-HHMMSS` UTC, matching other
`.taste/` subtree run IDs.

## Provenance

This skill exists because in the 2026-05-11 session that produced the
`waitdeadai/llm-dark-patterns` distribution wave, the operator and Claude
Code organically performed all of these steps in an ad-hoc manner —
identifying the Anthropic Discord (95k members) only after explicit
research, sorting moves into auto vs manual under live time pressure,
and missing several time-sensitive windows because no canonical surface
scan ran first. `/leveragepath` codifies that ad-hoc work into a
governed, repeatable skill.
