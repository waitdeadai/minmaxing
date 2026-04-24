# /deepresearch

Effectiveness-first deep investigation with live data — not stale training data.

**MiniMax MCP is the primary research tool.** Prefer `mcp__MiniMax__web_search` for live research whenever it is available.

**MAX_PARALLEL_AGENTS** — ceiling for deep research lanes. Use only the number of distinct branches that materially improve the final investigation.

**Use when:** The user explicitly asks for deep research, high-quality investigation, landscape analysis, architecture research, due diligence, adversarial fact-finding, or any research task where the first search summary is not enough.

**Research-First:** Integrated into `/workflow` automatically. Use `/deepresearch` directly when the main job is investigation.

**Swarm:** "swarm deepresearch" → `/deepresearch` with an effectiveness-first research wave up to `MAX_PARALLEL_AGENTS`.

For narrower current-fact lookups, use `/webresearch`. For older prompts or backwards compatibility, `/browse` should route to this protocol or the `/webresearch` protocol depending on scope.

---

## Core Contract

Deep research is not a search dump.

It must:
- start with a collaborative research plan
- choose an effective budget up to `MAX_PARALLEL_AGENTS`
- run an iterative `search -> read -> refine` loop
- maintain a source ledger
- surface conflicting evidence
- do follow-up research when key unknowns remain

This protocol is effectiveness-first:
- more tracks only when they reduce uncertainty
- more depth only when it changes the plan
- more loops only when open questions remain decision-relevant

## Investigation Modes

- `standard` — a few decisive branches, moderate depth, usually 1-3 loops
- `comprehensive` — multiple branches, high-stakes or strategic work, explicit pressure-testing before conclusions

Default to `comprehensive` when the user says "deepresearch", "investigate deeply", "top notch quality", "reverse engineer", "due diligence", or when errors from shallow research would be expensive.

## Step 1: Memory Recall

```bash
bash scripts/memory.sh recall "[research topic]" --depth simple 2>/dev/null || echo "Memory recall: skipped"
bash scripts/memory.sh search "[topic]" 2>/dev/null || true
```

## Step 2: Collaborative Research Plan

Before the first search wave, define:
- deliverable
- main research branches
- source classes to consult
- likely contradictions / unknowns
- stop condition for "research is sufficient"

Example:

```markdown
### Collaborative Research Plan
- Deliverable: [what this research must unlock]
- Branches:
  - [branch 1]
  - [branch 2]
- Source Classes:
  - official docs
  - recent practitioner writeups
  - issues / discussions
- Stop Condition:
  - [what must be known before we move on]
```

## Step 3: Effective Budget

Choose the smallest useful wave:

```text
effective_research_budget = min(MAX_PARALLEL_AGENTS, distinct_branches, reviewer_capacity)
```

Good defaults:
- `1-2` lanes: narrow technical verification
- `3-4` lanes: architecture or implementation-pattern comparison
- `5+` lanes: due diligence, market / ecosystem / adversarial investigations

Do not fill the pool for theater.

## Step 4: Discovery Wave

Launch only distinct tracks. Good track types:
- official documentation
- recent release notes / migrations
- GitHub issues / discussions
- expert writeups / case studies
- alternatives / competing patterns
- risk / failure-mode lookup

## Step 5: Search -> Read -> Refine Loop

Minimum loop:
1. discovery
2. deep read
3. refine or pressure-test

Use more loops only when:
- evidence conflicts
- key claims remain weak
- the plan still depends on unknowns

## Step 6: Source Ledger

Track:
- cited sources
- reviewed but not cited sources
- rejected or downweighted sources

This is required whenever external facts materially affect the conclusion.

## Step 7: Synthesis

```markdown
## DeepResearch: [Topic]

### Investigation Mode
[standard / comprehensive]

### Collaborative Research Plan
- Deliverable: ...
- Branches: ...
- Stop Condition: ...

### Research Tracks
| Track | Query | Sources |
|-------|-------|---------|

### Loop Log
| Loop | What changed | Why it mattered |
|------|--------------|-----------------|

### Source Ledger
- Cited: ...
- Reviewed but not cited: ...
- Rejected / downweighted: ...

### Conflicting Evidence
- Claim A: ...
- Claim B: ...
- Resolution / open uncertainty: ...

### Implications
- ...

### Coverage
- Research Tracks Used: [completed] / [effective budget]
- MiniMax MCP Searches: [count]
- Follow-up Research: [not needed / completed / blocked]
```

## Quality Gates

- cite sources
- keep the collaborative research plan visible
- use `MAX_PARALLEL_AGENTS` as a ceiling, not a quota
- show what changed between loops
- surface conflicting evidence instead of smoothing it away
- do follow-up research before finalizing when uncertainty still matters

## Anti-Patterns

- one-shot search and summary
- slot-filling to hit `MAX_PARALLEL_AGENTS`
- no source ledger
- no conflict handling
- calling the result "deep research" when only one shallow wave ran
