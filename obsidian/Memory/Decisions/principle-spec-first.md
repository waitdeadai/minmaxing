---
type: semantic
date: 2026-04-20
tags: [process, spec-first]
---

# Always Write SPEC.md Before Code

## Decision

Every meaningful task starts with SPEC.md before any code is written.

## Why

Vague prompts lead to rebuild loops. When AI asks "what should happen if X?" and user says "show error", that becomes a line in SPEC.md. Implementation follows spec, verifier checks against spec.

## Status

Active
