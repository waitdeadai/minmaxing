# /audit

**Deep codebase analysis with 10-agent parallelism.** Audit any repo to understand its structure, identify issues, and plan improvements.

**Use when:** User says "audit this", "analyze codebase", "understand this repo", "due diligence on this code", "swarm audit", "swarm this".

---

## Parallel Audit Protocol

### Phase 1: Decompose Audit (use MAX_PARALLEL_AGENTS)

**Break the audit into parallel tracks, filling all agent slots:**

| Agent | Focus | Output |
|-------|-------|--------|
| 1 | Project structure & architecture | File tree, tech stack |
| 2 | Security audit | Vulnerabilities, secrets, auth |
| 3 | Code quality | Patterns, debt, complexity |
| 4 | Dependencies | Outdated, vulnerable packages |
| 5 | Tests & coverage | Missing tests, coverage % |
| 6 | Documentation | README, API docs, comments |
| 7 | Business logic | Auth, payments, data handling |
| 8 | Performance | N+1, inefficient code |
| 9 | Git history | Authors, commit patterns |
| 10 | Compliance | OWASP, security standards |

### Phase 2: Parallel Execution

Spawn agents for each track simultaneously:

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

### Deep Audit (10 agents)
- All tracks including Performance, Business Logic, Git History, Compliance

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
- Sequential execution when parallel possible → BLOCK
- Skipping security for speed → BLOCK (always audit security)
