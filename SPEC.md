# SPEC: Harness Capability Map

## Problem Statement

`/claudeproduct` can inspect repo truth surfaces for minmaxing self-lookup, but
the harness does not yet have one canonical capability map that summarizes its
skills, rules, scripts, eval gates, routing relationships, and verification
commands.

The user wants the harness to answer "what can this system do?" with the same
discipline it uses for Claude product questions: evidence-grounded, current
from repo truth, and hostile to stale memory.

## Research Brief

### Collaborative Research Plan

- Deliverable: a generated `docs/harness-capability-map.md` plus a machine
  sidecar that `/claudeproduct` and future self-lookup flows can cite.
- Branches:
  - Official Claude Code extension guidance for skills, rules, subagents,
    plugins, hooks, and context loading.
  - Tool/resource discovery patterns from MCP and agent frameworks.
  - Existing minmaxing registration and verification surfaces.
- Source classes:
  - official Claude Code docs
  - official MCP specification docs
  - official OpenAI Agents SDK docs for deferred tool search and evals
  - repo inspection
- Stop condition: local static generator/check, docs integration, and harness
  release coverage without adding a runtime service.

### Source Ledger

- Claude Code docs, "Extend Claude Code":
  https://code.claude.com/docs/en/features-overview
  - Design implication: capability maps should distinguish always-on
    `CLAUDE.md`, on-demand skills, scoped rules, subagents, hooks, MCP, plugins,
    and agent teams. Claude Code docs explicitly recommend matching features to
    goals instead of loading everything at once.
- Claude Code docs index:
  https://code.claude.com/docs/llms.txt
  - Design implication: discoverable indexes are a good pattern for agent-facing
    capability surfaces; minmaxing should expose a compact local equivalent.
- Claude Code plugin reference:
  https://code.claude.com/docs/en/plugins-reference
  - Design implication: skills, agents, hooks, MCP servers, LSP servers, and
    monitors are separate component classes with paths and descriptions.
- Claude Agent SDK plugins docs:
  https://code.claude.com/docs/en/agent-sdk/plugins
  - Design implication: plugins bundle skills, agents, hooks, and MCP servers;
    local agents benefit from an explicit component inventory.
- MCP resources specification:
  https://modelcontextprotocol.io/specification/2025-06-18/server/resources
  - Design implication: resources use stable URIs, descriptions, optional
    annotations, and list/read semantics; a capability map should use stable
    paths and machine-readable metadata.
- MCP tools specification:
  https://modelcontextprotocol.io/specification/2025-06-18/server/tools
  - Design implication: tools include names, descriptions, schemas, and trust
    considerations; script gates should be listed with purpose and safety
    boundary rather than treated as opaque shell commands.
- OpenAI Agents SDK tools docs:
  https://openai.github.io/openai-agents-python/tools/
  - Design implication: deferred tool search and namespaces reduce token load
    when many capabilities exist; the local map should be a compact index that
    points to detailed files instead of inlining every skill.
- OpenAI agent evals docs:
  https://developers.openai.com/api/docs/guides/agent-evals
  - Design implication: capability claims should be coupled to eval/check gates,
    not just prose.

### Synthesis

The first slice should be a generator/check script:

- reads the repo's actual `.claude/skills/*/SKILL.md` frontmatter
- reads `.claude/rules/*.rules.md`
- inventories scripts and static eval tasks/goldens
- writes a human `docs/harness-capability-map.md`
- writes a machine `docs/harness-capability-map.json`
- supports `--check` so CI/release can reject stale maps
- updates `/claudeproduct` to cite the map for `selflookup`

This should not be a new runtime daemon. It should be a local, no-secret,
deterministic artifact generated from committed repo truth.

## Success Criteria

- [x] Add `scripts/harness-capability-map.sh` with:
  - default generation of `docs/harness-capability-map.md`
  - default generation of `docs/harness-capability-map.json`
  - `--check` mode that fails when generated output differs from disk
  - `--json` mode that prints the machine map
- [x] Add generated `docs/harness-capability-map.md`.
- [x] Add generated `docs/harness-capability-map.json`.
- [x] Add `schemas/harness-capability-map.schema.json`.
- [x] Update `/claudeproduct` Harness Self-Lookup to cite the capability map
      first, then fall back to raw repo surfaces.
- [x] Update README, CLAUDE.md, and AGENTS.md to describe the canonical map.
- [x] Wire `scripts/harness-capability-map.sh --check` into
      `scripts/release-check.sh` and `scripts/test-harness.sh`.
- [x] Add static eval metadata/golden coverage and `scripts/harness-eval.sh`
      known-gate wiring.

## Scope

### In Scope

- Static local generator/check.
- Human and machine capability-map artifacts.
- Skill/rule/script/eval inventory.
- Release/test/eval wiring.
- `/claudeproduct` self-lookup integration.

### Out Of Scope

- New MCP server.
- Runtime docs cache.
- Provider API changes.
- Reading `.env` or secrets.
- Hermes registry changes.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` reported
  `recommended_ceiling=10`, `codex_max_threads=10`, `hardware_class=workstation`.
- Effective lanes: 3 of ceiling 10 for docs research, repo mapping, and local
  implementation.
- Critical path: research -> SPEC -> generator/check -> generated artifacts ->
  routing/docs/test/eval/release wiring -> static verification.
- Agent wall-clock: optimistic 50 minutes / likely 90 minutes / pessimistic
  2.5 hours.
- Human touch time: none expected.
- Confidence: medium-high; risk is stale generated output if the generator
  reads too much hand-maintained prose instead of repo truth.

## Verification

- `bash scripts/harness-capability-map.sh --check`
- `bash scripts/harness-capability-map.sh --json`
- `bash -n scripts/*.sh`
- `bash scripts/harness-eval.sh --json`
- `bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

### Verified 2026-05-04

- `bash scripts/harness-capability-map.sh --check`: pass.
- `bash scripts/harness-capability-map.sh --check --json`: pass.
- `bash scripts/claudeproduct-scorecard.sh --fixtures --json`: pass
  (`green_passed=2`, `red_rejected=7`).
- `bash -n scripts/*.sh`: pass.
- `bash scripts/harness-eval.sh --json`: pass (`tasks=17`, `gates=14`).
- `bash scripts/test-harness.sh`: pass (`120 passed`, `0 failed`).
- `git diff --check`: pass.
