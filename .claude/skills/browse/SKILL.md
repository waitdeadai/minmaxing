# /browse

Parallel web research with live data — not stale training data.

**MiniMax MCP is the primary research tool.** Prefer `mcp__MiniMax__web_search` for live research whenever it is available.

**MAX_PARALLEL_AGENTS** — spawns up to 10 parallel web search agents researching different aspects simultaneously.

**Use when:** You need current information about APIs, libraries, errors, best practices, or any domain where AI training data might be outdated.

**Research-First:** Integrated into `/workflow` automatically. Use `/browse` directly when researching something specific.

**Swarm:** "swarm browse" → `/browse` with 10 parallel research agents.

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

**Use all available agents for deep research.** Each agent researches a different aspect simultaneously, and the target is a full `MAX_PARALLEL_AGENTS` search wave unless the tools fail.

### Step 1: Memory Recall (Before Research)

Check if we've already researched this topic recently:

```bash
# Check for existing research
bash scripts/memory.sh recall "[research topic]" --depth simple 2>/dev/null || echo "Memory recall: skipped"

# Search for related findings
bash scripts/memory.sh search "[topic]" 2>/dev/null || true
```

### Step 2: Decompose Research Query

Break the research into exactly `MAX_PARALLEL_AGENTS` parallel tracks:
- Track 1: Official documentation
- Track 2: Recent blog posts/articles (2025-2026)
- Track 3: GitHub issues/discussions
- Track 4: Alternative approaches/competitors
- Track N: [other aspects]

Target: Fill all `MAX_PARALLEL_AGENTS` slots with research tracks.

### Step 3: Parallel Web Searches

Spawn parallel searches for each track. Prefer issuing the whole first wave in one response turn so the searches execute as a batch:

```bash
# Agent 1: Official docs
mcp__MiniMax__web_search "official docs [topic] 2026"

# Agent 2: Recent articles
mcp__MiniMax__web_search "[topic] best practices 2025 2026"

# Agent 3: GitHub/discussions
mcp__MiniMax__web_search "[topic] GitHub issues limitations 2026"

# ... up to MAX_PARALLEL_AGENTS
```

### Step 4: Parallel Source Fetching

While searches run, fetch key sources in parallel:
- Official docs
- Recent blog posts
- GitHub discussions

### Step 5: Synthesize

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

### Coverage
- Research Tracks Used: [completed] / [MAX_PARALLEL_AGENTS]
- MiniMax MCP Searches: [count]
- Fallback Used: yes/no
```

### Step 6: Store Research Findings

Store key findings for future recall:

```bash
# Store findings as semantic memory with sources
bash scripts/memory.sh add semantic "Research [topic]: [key finding 1]. Source: [URL]" --tags "research,[topic],[year]"
bash scripts/memory.sh add semantic "Research [topic]: [key finding 2]. Source: [URL]" --tags "research,[topic],[year]"

# Record research success
python3 -c "
from memory.causal import record_outcome
factors = ['web_research', 'cited_sources', 'parallel_agents']
record_outcome(factors, 'success')
" 2>/dev/null || echo "record_outcome: skipped"
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
- **Full wave or explain why** — under-filling the search wave without a tool failure reason is a failure

---

## Anti-Patterns

- Accepting AI claim without verification → BLOCK
- Using old sources (pre-2024) without noting age → WARN
- Not citing sources → BLOCK
- Research without synthesizing into action → WARN
- Sequential research when parallel possible → BLOCK
- Under-filling the search wave without a tool failure reason → BLOCK
