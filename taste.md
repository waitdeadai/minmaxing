---
taste: spec
created: 2026-04-20
---

# Taste Spec

Define what is acceptable in this project. AI agents consult this before accepting output.

## Design Principles

- SPEC-first: write spec before code
- 10-agent parallelism for max throughput
- Separate verifier from implementer (PEV loop)
- Research-first: verify AI claims with web search

## Code Style

- Small functions, single responsibility
- No premature optimization
- Explicit over implicit

## Architecture

- Supervisor/worker pattern for parallelism
- File isolation between parallel agents
- Quality gates before progression
