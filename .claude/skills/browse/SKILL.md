# /browse

Parallel web research with live data — not stale training data.

**MiniMax MCP is the primary research tool.** Prefer `mcp__MiniMax__web_search` for live research whenever it is available.

**MAX_PARALLEL_AGENTS** — ceiling for parallel web research. Use only the number of distinct tracks that materially change the answer.

**Use when:** You need current information about APIs, libraries, errors, best practices, or any domain where AI training data might be outdated.

**Research-First:** Integrated into `/workflow` automatically. Use `/browse` directly when researching something specific.

**Swarm:** "swarm browse" → `/browse` with an efficacy-first research wave up to `MAX_PARALLEL_AGENTS`.

This skill should feel closer to Gemini Deep Research than to a generic search dump: start with a collaborative research plan, run an iterative search -> read -> refine loop, keep a source ledger, weigh conflicting evidence, and do follow-up research when the first synthesis is not enough.

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

## Gemini-Style Investigation Protocol

**Use only the needed agents for deep research.** Each agent should answer a distinct question or fetch a distinct source class. Redundant tracks reduce signal.

### Step 1: Memory Recall

Check if we've already researched this topic recently:

```bash
# Check for existing research
bash scripts/memory.sh recall "[research topic]" --depth simple 2>/dev/null || echo "Memory recall: skipped"

# Search for related findings
bash scripts/memory.sh search "[topic]" 2>/dev/null || true
```

### Step 2: Draft A Collaborative Research Plan

Before the first search wave, write down:
- the target deliverable
- the core questions or branches
- the source classes to consult
- the likely contradictions or unknowns to pressure-test
- the stop condition for "research is sufficient"

Choose an investigation mode:
- `standard` for a narrow question with a few decisive sources
- `comprehensive` for audits, architecture, high-stakes debugging, strategic research, or whenever the user explicitly wants deep investigation quality

### Step 3: Choose The Effective Budget

Break the work into distinct research tracks:
- Track 1: Official documentation
- Track 2: Recent blog posts/articles (2025-2026)
- Track 3: GitHub issues/discussions
- Track 4: Alternative approaches/competitors
- Track N: [other aspects]

Choose an effective budget up to `MAX_PARALLEL_AGENTS` and stop when additional tracks would be redundant.

### Step 4: Launch The Discovery Wave

Spawn the first wave of searches. Prefer issuing the whole first wave in one response turn so the searches execute as a batch:

```bash
# Agent 1: Official docs
mcp__MiniMax__web_search "official docs [topic] 2026"

# Agent 2: Recent articles
mcp__MiniMax__web_search "[topic] best practices 2025 2026"

# Agent 3: GitHub/discussions
mcp__MiniMax__web_search "[topic] GitHub issues limitations 2026"

# ... up to the chosen research budget
```

### Step 5: Run The Search -> Read -> Refine Loop

Do not stop after the first query batch.

- Loop 1: discovery — map the landscape and surface candidate sources
- Loop 2: deep read — open the highest-value sources, extract facts, and identify gaps
- Loop 3: pressure test — search for conflicting evidence, missing edges, or failure modes when the task is non-trivial
- Follow-up loop: run only when the first synthesis still leaves plan-changing uncertainty

### Step 6: Maintain A Source Ledger

Track sources as you go:
- cited sources
- reviewed but not cited sources
- rejected or downweighted sources when quality is a material issue

This matters because strong investigations usually review more material than they finally cite.

### Step 7: Synthesize

```markdown
## Research: [Topic] — [Mode]

### Collaborative Research Plan
- Deliverable: [what this research must unlock]
- Questions: [core branches]
- Source Classes: [official docs / issues / papers / etc.]
- Stop Condition: [what would make the research sufficient]

### Research Tracks
| Track | Query | Sources |
|-------|-------|---------|
| 1 | [Official docs] | [URLs] |
| 2 | [Best practices] | [URLs] |
| ... | ... | ... |

### Loop Log
| Loop | What changed | Why it mattered |
|------|--------------|-----------------|
| 1 | [landscape] | [impact] |
| 2 | [deepening] | [impact] |

### Source Ledger
- Cited: [URLs]
- Reviewed but not cited: [URLs]
- Rejected / downweighted: [URLs + reason]

### Confirmed / Conflicting Evidence
- Source says: [finding]
- Conflicting source says: [finding]
- Resolution: [how you weighed it]

### Action Items
- [What to do based on research]

### Coverage
- Investigation Mode: [standard / comprehensive]
- Research Tracks Used: [completed] / [effective budget]
- MiniMax MCP Searches: [count]
- Fallback Used: yes/no
- Follow-up Research: [not needed / completed]
```

### Step 8: Store Research Findings

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

## Quality Gates

- **Cite sources** — always include URLs, no "I think"
- **Date check** — prioritize 2025-2026 sources
- **Contradict AI** — if web search contradicts AI claim, flag it
- **No assumptions** — if you can't verify, say "unverified"
- **Distinct tracks only** — redundant searches are wasted budget
- **Collaborative research plan first** — don't jump straight from the prompt to the search batch
- **Keep a source ledger** — include reviewed but not cited sources when external facts matter
- **Do follow-up research when needed** — don't stop at the first summary if the plan still depends on unknowns

---

## Anti-Patterns

- Accepting AI claim without verification → BLOCK
- Using old sources (pre-2024) without noting age → WARN
- Not citing sources → BLOCK
- Research without synthesizing into action → WARN
- Treating deep research as a one-shot search batch → BLOCK
- Skipping the collaborative research plan → BLOCK
- Omitting the source ledger or reviewed but not cited sources → BLOCK
- Ignoring conflicting evidence because one source is convenient → BLOCK
- Inflating the search wave with redundant tracks → BLOCK
