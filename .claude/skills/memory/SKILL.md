---
name: memory
description: minmaxing 5-tier memory system management
---

Manage the 5-tier memory system and taste system.

**Use when:** User says "show memory", "check memory", "memory stats", "log decision", "how's memory".

**Commands:**
- `bash scripts/memory.sh stats` — Show memory counts per tier
- `bash scripts/memory.sh list` — List recent memories
- `bash scripts/memory.sh add episodic "what happened"` — Log episodic
- `bash scripts/taste.sh review` — Show taste.memory recent entries
- `bash scripts/taste.sh log APPROVE "task" "reasoning"` — Log a verdict

**The 5 tiers:**
| Tier | Storage | Retention |
|------|---------|-----------|
| Episodic | `.taste/sessions/*.jsonl` | 90 days |
| Semantic | `taste.md` + Decisions/ | Indefinite |
| Procedural | `Patterns/` | Indefinite |
| Error-Solution | `Errors/` | Indefinite |
| Graph | `Stories/` | Indefinite |
