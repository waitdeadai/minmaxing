# /browse

**Parallel web research with live data — not stale training data.**

**Use when:** You need current information about APIs, libraries, errors, best practices, "swarm research", "swarm this", or any domain where AI training data might be outdated.

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

## Parallel Research Protocol (MAX_PARALLEL_AGENTS)

**Use all available agents for deep research.** Each agent researches a different aspect simultaneously.

### Step 1: Decompose Research Query

Break the research into parallel tracks:
- Track 1: Official documentation
- Track 2: Recent blog posts/articles (2025-2026)
- Track 3: GitHub issues/discussions
- Track 4: Alternative approaches/competitors
- Track N: [other aspects]

Target: Fill all `MAX_PARALLEL_AGENTS` slots with research tracks.

### Step 2: Parallel Web Searches

Spawn parallel searches for each track:

```bash
# Agent 1: Official docs
mcp__MiniMax__web_search "official docs [topic] 2026"

# Agent 2: Recent articles
mcp__MiniMax__web_search "[topic] best practices 2025 2026"

# Agent 3: GitHub/discussions
mcp__MiniMax__web_search "[topic] GitHub issues limitations 2026"

# ... up to MAX_PARALLEL_AGENTS
```

### Step 3: Parallel Source Fetching

While searches run, fetch key sources in parallel:
- Official docs
- Recent blog posts
- GitHub discussions

### Step 4: Synthesize

```markdown
## Research: [Topic] — [N] Agents Deployed

### Research Tracks
| Track | Query | Sources |
|-------|-------|---------|
| 1 | [Official docs] | [URLs] |
| 2 | [Best practices] | [URLs] |
| ... | ... | ... |

### Current State (2026)
| Source | Finding |
|--------|---------|
| [URL] | [Key fact] |

### Confirmed/Contradicted
- AI said: [what model claimed]
- Reality: [what web search shows]
- Impact: [how this changes approach]

### Action Items
- [What to do based on research]
```

---

## Deep Research Mode

For complex topics, use all agents for deep coverage:

1. **Decompose** topic into 10 aspects
2. **Spawn** MAX_PARALLEL_AGENTS searches simultaneously
3. **Fetch** top sources for each aspect in parallel
4. **Synthesize** findings into comprehensive report

---

## Quality Gates

- **Cite sources** — always include URLs, no "I think"
- **Date check** — prioritize 2025-2026 sources
- **Contradict AI** — if web search contradicts AI claim, flag it
- **No assumptions** — if you can't verify, say "unverified"
- **Fill agent pool** — don't use 1 agent when 10 could research faster

---

## Anti-Patterns

- Accepting AI claim without verification → BLOCK
- Using old sources (pre-2024) without noting age → WARN
- Not citing sources → BLOCK
- Research without synthesizing into action → WARN
- Sequential research when parallel possible → BLOCK
