---
type: error-solution
date: 2026-04-20
error: "API key not found in environment"
---

## Error

```
API Error: 2049-invalid api key
```

## Solution

Set `MINIMAX_API_KEY` in environment or `~/.claude.json` MCP config. Get key from platform.minimax.io.

## Prevention

setup.sh should auto-configure this. Verify `claude mcp list` shows MiniMax connected.
