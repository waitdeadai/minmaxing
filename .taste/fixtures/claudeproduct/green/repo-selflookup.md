<!-- scorecard: green -->

## Claude Product Question
- Question Class: selflookup
- User Question: Which Claude-facing product surface does this harness expose?

## Source Policy
- Primary sources: official Anthropic/Claude docs plus repo truth
- Docs index checked: not needed
- Freshness requirement: stable

## Source Ledger
- Cited:
  - docs/harness-capability-map.json - canonical machine map for project skills, rules, scripts, evals, hooks, and Codex surfaces.
  - docs/harness-capability-map.md - human-readable route and capability summary.
  - .claude/skills/claudeproduct/SKILL.md - targeted skill contract for self-lookup behavior.
- Reviewed But Not Cited:
  - scripts/start-session.sh - startup display only; the generated map is the canonical self-lookup index.
- Rejected:
  - Memory-only skill count - counts drift and must be verified from repo files.

## Answer
The repo exposes Claude-facing project skills under `.claude/skills/`, and the
canonical self-lookup index is `docs/harness-capability-map.json` with the
human summary in `docs/harness-capability-map.md`.

## Harness Implication
- Route: direct answer
- Repo impact: none
- Follow-up gate: none

## Confidence
- Level: medium
- Downgrade: repo-only evidence; current Claude Code external behavior was not needed
