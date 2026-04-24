# /audit

Deep codebase analysis with parallel agents. Audit any repo to understand its structure, identify issues, and plan improvements.

**TASTE-FIRST** — Reads taste.md + vision before audit research. Gates on misalignment.

**MAX_PARALLEL_AGENTS** — ceiling for parallel audit tracks. Choose a risk-based budget that covers the repo without redundant tracks.

**Use when:** User says "audit this", "analyze codebase", "understand this repo", "due diligence on this code", "swarm audit".

**Swarm:** "swarm audit" → `/audit` with a risk-based audit wave up to `MAX_PARALLEL_AGENTS`.

---

## Execution Protocol

### Phase 0: Taste Check [GATE]
1. Check: taste.md + taste.vision exist?
   - If NO → invoke `/tastebootstrap` → wait → proceed
2. Read taste.md + taste.vision
3. Call memory recall:
   - `bash scripts/memory.sh recall "<audit target>" --depth simple`
4. Score: does the audit target align with taste?
   - If misaligned → /align before proceeding
   - If aligned → proceed to Phase 1

### Phase 1: Decompose Audit (use MAX_PARALLEL_AGENTS)

**Break the audit into parallel tracks that materially improve coverage:**

| Track | Focus | Always? | Output |
|-------|-------|---------|--------|
| 1 | Project structure & architecture | Yes | File tree, tech stack |
| 2 | Security audit | Yes | Vulnerabilities, secrets, auth |
| 3 | Correctness & code quality | Yes | Patterns, debt, complexity |
| 4 | Tests & verification surface | Yes | Missing tests, confidence gaps |
| 5 | Dependencies | If relevant | Outdated or risky packages |
| 6 | Documentation & contracts | If relevant | Drift, missing docs |
| 7 | Business logic | If relevant | Domain-specific risks |
| 8 | Performance | If relevant | Hot spots, inefficiencies |
| 9 | Git history | If relevant | Churn, ownership, risky areas |
| 10 | Compliance / policy | If relevant | Standards gaps |

### Phase 2: Parallel Execution

Spawn agents only for the tracks the repo actually needs. Give each track a clear surface and return format.

```bash
# Agent 1: Structure
claude -p "Analyze project structure. File tree, tech stack, framework. Output: structured summary" > audit-structure.out 2>&1 &

# Agent 2: Security
claude -p "Audit for security issues: SQL injection, XSS, secrets in code, auth flaws. Output: vulnerability list" > audit-security.out 2>&1 &

# ... up to MAX_PARALLEL_AGENTS
```

### Phase 3: Synthesize Findings

```markdown
## Audit Report: [Repository Name]

### Executive Summary
[2-3 sentences on overall health]

### Project Structure
| Component | Technology | Status |
|-----------|------------|--------|
| API | Node.js | 🟢 |

### Security Findings
| Issue | Severity | Location |
|-------|----------|----------|
| Hardcoded API key | CRITICAL | config.js:5 |

### Code Quality
| Metric | Value |
|--------|-------|
| Files | N |
| Complexity | HIGH/MEDIUM/LOW |

### Action Items
1. [P0] Remove hardcoded secrets
2. [P1] Add authentication middleware

### Recommendation
[PROCEED/CAUTION/STOP]
```

---

## Audit Focus Options

### Quick Audit (3 agents)
- Structure + Security + Quality

### Standard Audit (6 agents)
- Structure, Security, Quality, Dependencies, Tests, Docs

### Deep Audit (up to 10 agents)
- Core tracks plus any optional tracks justified by repo risk or task scope

---

## Quality Gates

- **Cite specific files/lines** — no vague "probably insecure"
- **Severity classification** — CRITICAL/HIGH/MEDIUM/LOW
- **Actionable recommendations** — not just "this is bad"
- **Evidence-based** — show the code that triggered finding

---

## Anti-Patterns

- Vague findings without file references → BLOCK
- No severity ranking → BLOCK
- No actionable next steps → BLOCK
- Sequential execution when distinct high-value tracks exist → BLOCK
- Inflating the audit with low-value filler tracks → BLOCK
- Skipping security for speed → BLOCK (always audit security)
