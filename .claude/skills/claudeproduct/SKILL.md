---
name: claudeproduct
description: Answer Claude, Claude Code, Anthropic API, skills, connectors, plugins, and Claude product questions using official current docs.
---

# /claudeproduct

Use this skill when the user asks how to use a Claude or Anthropic product
feature, or when the harness needs to look up its own Claude-facing operating
surface.

Examples:

- "How do we use Claude Code skills?"
- "What is the difference between skills and slash commands?"
- "Does Claude Code support subagents in the SDK?"
- "Which Claude product feature should minmaxing use for this?"
- "Look up Claude connectors / plugins / artifacts / API behavior."

This is a current-docs router, not a stale product encyclopedia.

Official Claude Code docs describe "ask Claude about its capabilities" as a
normal workflow. This skill makes that behavior evidence-grounded for
minmaxing: answer from official docs, separate product surfaces, and downgrade
confidence when a feature is account-, plan-, platform-, or time-sensitive.

## Relationship To Research Skills

- Use `/claudeproduct` to frame Claude product questions and enforce the
  official-source policy.
- Use `/webresearch` inside this skill for narrow current facts.
- Use `/deepresearch` inside this skill when the answer spans multiple Claude
  surfaces, plan/feature availability, implementation architecture, or
  conflicting docs.
- Use `/workflow` only after the product answer becomes repo-changing work.
- Use `/metacognition` before execution when the route is ambiguous.

## Official Source Policy

Prefer sources in this order:

1. `https://code.claude.com/docs/llms.txt` for Claude Code docs discovery.
2. Specific pages under `https://code.claude.com/docs/`.
3. `https://claude.com/docs/llms.txt` or specific pages under
   `https://claude.com/docs/`.
4. Official Anthropic docs under `https://docs.anthropic.com/`.
5. Official Claude Help Center pages under `https://support.claude.com/`.
6. Official Anthropic or Claude changelog, blog, or release notes.

Use community posts, Reddit, blog posts, or stale examples only as leads. Do not
cite them as authority unless the user explicitly asks for community practice.

## Question Classes

Choose exactly one:

| Question Class | Use When | Research Mode |
| --- | --- | --- |
| `howto` | user asks how to use a Claude product feature | `/webresearch` unless docs are already in context |
| `capability` | user asks whether Claude can do something | `/webresearch` with current official docs |
| `comparison` | user asks skills vs commands, connectors vs plugins, Claude Code vs Claude.ai, etc. | `/webresearch`; escalate to `/deepresearch` if multi-surface |
| `implementation` | answer will drive harness code, settings, plugin, skill, or API usage | `/deepresearch` for non-trivial changes |
| `troubleshooting` | user asks about an error, missing feature, auth, settings, or runtime behavior | `/webresearch` plus repo/runtime evidence |
| `selflookup` | harness needs to know its own Claude-facing skills, rules, commands, or settings | repo inspection plus `/webresearch` if current Claude behavior matters |
| `blocked` | current docs, account access, permission, or product availability cannot be verified | state blocker and downgrade confidence |

## Product Surface Map

- Claude Code core: CLI, IDE, Desktop, Web, browser integration, CI/CD, Slack,
  non-interactive runs, sessions, permissions, plan mode, routines, and `/loop`.
- Claude Code configuration: `.claude/settings.json`,
  `.claude/settings.local.json`, `~/.claude/settings.json`, managed settings,
  permissions, environment variables, sandboxing, and MCP config.
- Claude Code instructions and extensibility: `CLAUDE.md`, rules, memory,
  skills, legacy commands, plugins, hooks, subagents, agent teams, and Agent SDK.
- Claude.ai apps: chats, Projects, project knowledge, instructions, styles,
  profile preferences, organization instructions, Artifacts, web search,
  Research, extended thinking, connectors, and mobile/desktop app behavior.
- Anthropic API/platform: developer docs, model/API fields, SDKs, tools,
  streaming, batches, usage, billing, and platform limits.
- MCP/connectors: setup, permissions, read/write capability, prompt-injection
  and trust boundaries, availability by Claude surface.

Do not assume feature parity across surfaces. A feature documented for
Claude.ai is not automatically available in Claude Code, and a Claude Code
feature is not automatically available through the Anthropic API.

## Freshness Rules

- Start from the current `minmaxing temporal anchor` injected by hooks, or run
  `bash scripts/time-anchor.sh text`, before answering time-sensitive Claude
  product questions.
- For current product behavior, plan gating, pricing, availability, commands,
  model names, API fields, or installation instructions, run current research
  or cite official docs already opened in the current turn.
- Do not answer from memory alone when there is a meaningful chance the product
  changed.
- State the time anchor date, source publish/update date when available, and
  access date for official docs used.
- If official docs conflict, cite both and mark the answer as uncertain.
- If docs are unavailable, answer conservatively and say what could not be
  verified.

## Harness Self-Lookup

When the question is about this repo's Claude-facing surface:

1. Read the canonical generated map first:
   - `docs/harness-capability-map.md` for human route/capability summaries
   - `docs/harness-capability-map.json` for exact counts, paths, related
     rules, scripts, evals, hooks, and Codex surfaces
2. If the map is missing or stale, run or cite:
   - `bash scripts/harness-capability-map.sh --check`
3. Open only the referenced source files needed for the answer:
   - `.claude/skills/`
   - `.claude/rules/`
   - `.claude/settings.json`
   - `.claude/hooks/`
   - `.codex/`
   - `CLAUDE.md`
   - `AGENTS.md`
   - `README.md`
   - `scripts/start-session.sh`
4. Use `/webresearch` only for external Claude Code behavior that may have
   changed.
5. Separate "repo contract says" from "official Claude docs say".

Never read `.env`, `.env.*`, credentials, tokens, customer memory seeds, or
private connector secrets just to answer a Claude product question.

## Required Output

```markdown
## Claude Product Question
- Question Class: [howto / capability / comparison / implementation / troubleshooting / selflookup / blocked]
- User Question: ...

## Source Policy
- Primary sources: official Anthropic/Claude docs
- Docs index checked: [yes / no / already in context / not needed]
- Freshness requirement: [current / stable / blocked]

## Source Ledger
- Cited:
  - [URL or repo path] - [why it matters]
- Reviewed But Not Cited:
  - [URL or repo path] - [why it was downweighted]
- Rejected:
  - [source] - [reason]

## Answer
[Clear user-facing answer. Include exact commands or steps when helpful.]

## Harness Implication
- Route: [/webresearch / /deepresearch / /workflow / /metacognition / direct answer / blocked]
- Repo impact: [none / docs / settings / skill / script / blocked]
- Follow-up gate: [none / /introspect / /verify / release-check]

## Confidence
- Level: [high / medium / low]
- Downgrade: [none / missing current docs / conflicting docs / missing account access / repo-only evidence]
```

## Routing Rules

- If the answer is simple, stable, and already supported by official docs in
  context, answer directly with citations or repo evidence.
- If the answer is current or product-availability sensitive, run
  `/webresearch`.
- If implementation depends on the answer, run `/deepresearch` or route into
  `/workflow` after the research brief is sufficient.
- If account, plan, organization settings, or private connector state is
  required, block or downgrade instead of guessing.

## Anti-Patterns

- "I remember Claude supports X" without current official evidence.
- Citing a community post as if it were product truth.
- Claiming a feature is available on all plans without official plan evidence.
- Reading secrets or `.env` for a product docs answer.
- Hiding uncertainty when docs conflict or are unavailable.
- Treating `/claudeproduct` as a replacement for `/webresearch`,
  `/deepresearch`, `/workflow`, or `/introspect`.

## Static Gate

Use this fixture gate after changing the skill:

```bash
bash scripts/claudeproduct-scorecard.sh --fixtures --json
```
