---
type: procedural
date: 2026-04-20
tags: [pattern, parallel]
---

# Use an Effective Agent Budget for Parallel Tasks

## Pattern

When tasks cover independent files or surfaces, choose only the number of workers that materially shortens the critical path. Each worker should own a clear surface, receive a thin brief, and return evidence for the supervisor to verify.

## When to Use

- Multiple files need changes
- Research can run in parallel
- Audit across different areas
- The work packets are bounded and ownership is clear

## When NOT to Use

- Sequential dependencies exist
- Single file changes
- Architectural decisions
- Extra workers would create synthetic task splitting or context thrash
