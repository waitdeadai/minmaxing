# Dashboard

## 5-Tier Memory System (ForgeGod)

| Tier | Type | Retention |
|------|------|-----------|
| Episodic | Task outcomes | 90 days |
| Semantic | Principles | Indefinite (decay) |
| Procedural | Code patterns | Indefinite |
| Graph | Entity relationships | Indefinite |
| Error-Solution | Error → fix | Indefinite |

Run `/memory` or `forgegod memory` to check current memory state.

## Session Info

- **Model:** MiniMax M2.7 Highspeed (100 TPS, 204K context)
- **Agent Pool:** Auto-detected via `scripts/detect-hardware.sh`
- **Vault:** `obsidian/ForgeGod/`

## Quick Actions

```bash
forgegod memory   # Check 5-tier memory health
forgegod status   # Overall system status
forgegod doctor   # Installation health
```

## Project Stats

Memory stats populated by `forgegod memory` on session start.
