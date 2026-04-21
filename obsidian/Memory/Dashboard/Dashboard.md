# Dashboard

## 5-Tier Memory System (minmaxing)

| Tier | Type | Storage | Retention |
|------|------|---------|-----------|
| Episodic | Task outcomes | `.taste/sessions/*.jsonl` | 90 days |
| Semantic | Principles | `taste.md` + Decisions/ | Indefinite |
| Procedural | Code patterns | `Patterns/` | Indefinite |
| Error-Solution | Error → fix | `Errors/` | Indefinite |
| Graph | Entity relationships | `Stories/` | Indefinite |

## Quick Commands

```bash
bash scripts/memory.sh stats      # Show memory stats
bash scripts/taste.sh review       # Show recent decisions
```

## Session Info

- **Model:** MiniMax M2.7 Highspeed (100 TPS, 204K context)
- **Agent Pool:** Auto-detected via `scripts/detect-hardware.sh`
- **Vault:** `obsidian/Memory/`

## Taste System

- `taste.md` — Design spec (what's acceptable)
- `taste.vision` — Intent document (the "why")
- `.taste/taste.memory` — Append-only decision log
