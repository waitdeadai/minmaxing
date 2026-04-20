# Delegation Rules (80/20)

## The 80/20 Principle (Karpathy "Manifesting")

- **80%** of time: delegating to subagents, macro review
- **20%** of time: architecture decisions, security reviews, quality gating

**Goal:** State intent → break into objectives → assign to agents → review at macro level

## What to Delegate

Safe to delegate — mechanical, bounded tasks:

- Single file changes
- Test writing and execution
- Documentation updates
- Mechanical refactoring (renaming, formatting)
- Bug fixes (with root cause identified)
- Configuration changes
- Code formatting/linting
- Data migration scripts
- Boilerplate code generation

## What to KEEP (Never Delegate)

Requires human judgment — never delegate:

- **SPEC.md creation** — defining what to build
- **Architecture decisions** — how components connect
- **Security reviews** — authentication, authorization, data handling
- **Verification decisions** — does output match spec?
- **Quality gate enforcement** — blocking on failures
- **Scope negotiation** — what to include/exclude
- **Verification against spec** — use /verify skill
- **Complex multi-file refactors** — requires understanding

## Delegation Protocol

### 1. Define Clear Task
- SPEC.md exists and is approved
- Success criteria are verifiable
- Definition of done is clear

### 2. Provide Clean Context
- Only pass what's needed for this task
- No stale context from other tasks
- File boundaries are clear

### 3. Delegate with Instructions
```
Task: [specific description]
Files: [list]
Context: [relevant context]
Success: [definition of done]
Verify: [how to verify completion]
```

### 4. Verify Output (Mandatory)
- Never skip verification
- Use /verify skill against SPEC.md
- Accept or reject with specific feedback

### 5. Accept or Reject
- **Accept:** All criteria met, evidence provided
- **Reject:** Specific failures listed, fix required

## Effective Delegation

| Condition | Action |
|-----------|--------|
| One task per agent | Yes |
| Clear file boundaries | Yes |
| Verifiable definition of done | Yes |
| Isolated context | Yes |
| Mandatory verification | Yes |

## Anti-Patterns

- Delegating without SPEC.md → BLOCK
- Not verifying delegate output → BLOCK
- Delegating architecture decisions → BLOCK
- Delegating quality gate enforcement → BLOCK
- Over-delegating (losing oversight) → WARN
- Delegating vague tasks → BLOCK
