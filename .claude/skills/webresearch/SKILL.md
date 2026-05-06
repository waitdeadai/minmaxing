# /webresearch

Effectiveness-first current web research for APIs, versions, docs, errors, pricing, standards, and other time-sensitive facts.

**MiniMax MCP is the primary research tool.** Prefer `mcp__MiniMax__web_search` whenever it is available.

**MAX_PARALLEL_AGENTS** — ceiling for web research lanes. Use only the number of distinct questions that materially change the answer.

**Use when:** The user wants the latest docs, current behavior, recent changes, known issues, exact error explanations, or source-backed technical guidance from the web.

**Claude product questions:** Route Claude, Claude Code, Claude.ai,
Anthropic API, connector, plugin, skill, hook, MCP, subagent, plan availability,
limit, or setup questions through `/claudeproduct` first. It constrains this
research mode to official Anthropic/Claude sources and separates product
surfaces before answering.

**Research-First:** Integrated into `/workflow` automatically. Use `/webresearch` directly when the main task is current-fact verification.

**Swarm:** "swarm webresearch" → `/webresearch` with an effectiveness-first research wave up to `MAX_PARALLEL_AGENTS`.

If the task becomes multi-branch, strategic, adversarial, or investigation-heavy, escalate to `/deepresearch`.

---

## Contract

`/webresearch` is the focused current-facts sibling of `/deepresearch`.

It still requires:
- the current minmaxing time anchor for relative-date or current-fact claims
- a concise collaborative research plan
- an effective budget up to `MAX_PARALLEL_AGENTS`
- at least one `search -> read -> refine` cycle when external facts matter
- a source ledger when the result will drive implementation or decision-making

Temporal guard:
- Use the `minmaxing temporal anchor` injected by hooks, or run
  `bash scripts/time-anchor.sh text`, before answering current-fact questions.
- For "latest", "today", "current", "recent", "SOTA 2026", model/provider
  behavior, pricing, docs, laws, standards, benchmarks, schedules, or news,
  cite live sources and include source publish/update dates plus access date.
- If current verification cannot be completed, say so explicitly instead of
  filling gaps from pretrained memory.

## When To Escalate To `/deepresearch`

Escalate when:
- more than 3 branches materially affect the answer
- the user explicitly asks for "deep research" or high-confidence investigation
- conflicting evidence appears and the stakes are non-trivial
- the answer will drive architecture, security, or substantial implementation time

## Step 1: Memory Recall

```bash
bash scripts/memory.sh recall "[research topic]" --depth simple 2>/dev/null || echo "Memory recall: skipped"
bash scripts/memory.sh search "[topic]" 2>/dev/null || true
```

## Step 2: Collaborative Research Plan

Define:
- the exact question
- what current facts are needed
- what source classes count as trustworthy
- what would make the answer sufficient

## Step 3: Effective Budget

Typical lanes:
- official docs
- release notes / changelog
- GitHub issues / discussions
- recent practitioner writeups

Use the smallest effective budget:

```text
effective_webresearch_budget = min(MAX_PARALLEL_AGENTS, distinct_questions, reviewer_capacity)
```

## Step 4: Search -> Read -> Refine

1. discovery wave
2. open the highest-value sources
3. run one follow-up wave if the first pass leaves decision-relevant gaps

## Step 5: Source Ledger

When the result materially affects implementation, record:
- cited
- reviewed but not cited
- rejected / downweighted

## Output

```markdown
## WebResearch: [Topic]

### Collaborative Research Plan
- Question: ...
- Needed facts: ...
- Stop Condition: ...

### Research Tracks
| Track | Query | Sources |
|-------|-------|---------|

### Findings
- ...

### Source Ledger
- Cited: ...
- Reviewed but not cited: ...
- Time Anchor: ...
- Access Date: ...

### Coverage
- Research Tracks Used: [completed] / [effective budget]
- MiniMax MCP Searches: [count]
- Follow-up Research: [not needed / completed / escalated to /deepresearch]
```

## Quality Gates

- cite the sources
- prioritize official docs for technical claims
- keep the budget effectiveness-first
- escalate to `/deepresearch` when the problem is no longer narrow

## Anti-Patterns

- answering time-sensitive questions from memory
- using all lanes just because `MAX_PARALLEL_AGENTS` allows it
- pretending a narrow docs lookup was a full deep investigation
