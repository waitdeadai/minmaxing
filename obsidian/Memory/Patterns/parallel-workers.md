---
type: procedural
date: 2026-04-20
tags: [pattern, parallel]
---

# Use 10-Agent Pool for Parallel Tasks

## Pattern

When任务是 independent files/components, spawn up to 10 workers. Each worker gets a different file. Supervisor verifies all at the end.

## When to Use

- Multiple files need changes
- Research can run in parallel
- Audit across different areas

## When NOT to Use

- Sequential dependencies exist
- Single file changes
- Architectural decisions
