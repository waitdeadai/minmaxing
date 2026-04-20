# /browse

**Web research with live data — not stale training data.**

**Use when:** You need current information about APIs, libraries, errors, best practices, or any domain where AI training data might be outdated.

**Research-First:** This is integrated into `/workflow` automatically. Use `/browse` directly when you want to research something specific outside the workflow.

---

## When to Research

**ALWAYS research when:**
- Task involves external APIs (pricing, limits, behavior)
- Task involves libraries/SDKs (versions, breaking changes)
- Debugging error messages (new error codes exist)
- Making technical claims (verify "best practice" is still current)
- Anything AI "knows" — AI training data is stale

**Research trigger phrases:**
- "the API recently..."
- "the latest version of..."
- "error X means..."
- "the standard approach is..."
- "everyone uses X for..."

→ If AI says any of these, verify with `/browse` first.

---

## Execution Protocol

### Step 1: Define Research Query
- What question needs answering?
- What will you do with this information?
- What's the deadline/urgency?

### Step 2: Web Search
Use `mcp__MiniMax__web_search` with specific query:
```
[practical query about current state]
```
Not: "tell me about X"
Yes: "X API pricing 2026", "X library breaking changes 2026"

### Step 3: Fetch Key Sources
Use `WebFetch` on most relevant results:
- Official docs (API, library)
- Recent blog posts (last 6 months)
- GitHub issues/discussions

### Step 4: Synthesize

```markdown
## Research: [Topic]

### Question
[What we needed to know]

### Current State (2026)
| Source | Finding |
|--------|---------|
| [URL] | [Key fact] |
| [URL] | [Key fact] |

### Confirmed/Contradicted
- AI said: [what model claimed in conversation]
- Reality: [what web search shows]
- Impact: [how this changes our approach]

### Action Items
- [What to do based on research]
```

---

## Quality Gates

- **Cite sources** — always include URLs, no "I think"
- **Date check** — prioritize 2025-2026 sources
- **Contradict AI** — if web search contradicts AI claim, flag it
- **No assumptions** — if you can't verify, say "unverified"

---

## Anti-Patterns

- Accepting AI claim without verification → BLOCK
- Using old sources (pre-2024) without noting age → WARN
- Not citing sources → BLOCK
- Research without synthesizing into action → WARN
