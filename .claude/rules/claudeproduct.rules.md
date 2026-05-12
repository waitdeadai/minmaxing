# Claude Product Knowledge Rules

Use these rules for `/claudeproduct` and for any `/workflow`, `/webresearch`,
`/deepresearch`, or `/metacognition` route that depends on Claude, Claude Code,
Claude.ai, Anthropic API, connector, plugin, skill, subagent, Agent View,
background session, or supervisor behavior.

## Official Evidence First

- Current Claude product behavior must be grounded in official Anthropic,
  Claude, Claude Code, or Claude Help Center sources.
- Use docs indexes such as `https://code.claude.com/docs/llms.txt` for discovery
  before guessing the right page.
- Community posts, search snippets, older examples, and model memory are
  candidate leads only.
- Include a source ledger when the answer drives implementation or user
  decisions.

## Freshness And Confidence

- Treat product availability, plan gating, pricing, commands, model names, API
  parameters, and platform support as time-sensitive.
- Downgrade confidence when current docs are unavailable, ambiguous, conflicting,
  or plan/account-specific.
- Do not claim a Claude product feature is supported, unsupported, free,
  deprecated, or generally available without official evidence.

## Harness Boundary

- `/claudeproduct` selects and constrains `/webresearch` or `/deepresearch`; it
  does not replace them.
- `/claudeproduct` does not replace `/workflow`, `/verify`, or `/introspect`.
- For repo self-lookup, inspect `docs/harness-capability-map.md` or
  `docs/harness-capability-map.json` first, then open the referenced repo truth
  surfaces. Separate "repo contract says" from "official Claude docs say".
- OpenAI/Codex product questions still route to the OpenAI/Codex docs path, not
  to Claude product knowledge.

## Secret Safety

- Never read `.env`, `.env.*`, credentials, tokens, private customer memory, or
  connector secrets to answer a Claude product docs question.
- If account, plan, organization policy, or connector state is required, ask for
  explicit evidence or state the limitation.

## Durable Learning

- Do not promote Claude product behavior into memory or prompt contracts unless
  it is verified by current official docs or repo evidence.
- If official docs later change, the old lesson must be treated as stale.
