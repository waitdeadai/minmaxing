#!/bin/bash
# Report the safe parallel budget for minmaxing workflows.

set -euo pipefail

MODE="${1:-markdown}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
  ROOT_DIR="$CLAUDE_PROJECT_DIR"
fi

detect_cores() {
  if command -v nproc >/dev/null 2>&1; then
    nproc
    return
  fi

  if command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.ncpu 2>/dev/null && return
  fi

  echo "2"
}

detect_ram_gb() {
  if command -v free >/dev/null 2>&1; then
    free -k | awk '/Mem:/ { printf "%d\n", int(($2 + 1048575) / 1048576) }'
    return
  fi

  if [ -r /proc/meminfo ]; then
    awk '/MemTotal/ { printf "%d\n", int(($2 + 1048575) / 1048576) }' /proc/meminfo
    return
  fi

  if command -v sysctl >/dev/null 2>&1; then
    local bytes
    bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
    awk -v bytes="$bytes" 'BEGIN { printf "%d\n", int((bytes + 1073741823) / 1073741824) }'
    return
  fi

  echo "8"
}

read_codex_max_threads() {
  local config="$ROOT_DIR/.codex/config.toml"

  if [ ! -f "$config" ] || ! command -v python3 >/dev/null 2>&1; then
    echo ""
    return
  fi

  python3 - "$config" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
section = None
for raw in path.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    if line.startswith("[") and line.endswith("]"):
        section = line.strip("[]")
        continue
    if section == "agents" and line.startswith("max_threads"):
        match = re.search(r"=\s*([0-9]+)", line)
        if match:
            print(match.group(1))
        break
else:
    print("")
PY
}

is_positive_int() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) [ "$1" -gt 0 ] ;;
  esac
}

min_positive() {
  local current="$1"
  local candidate="$2"

  if is_positive_int "$candidate" && [ "$candidate" -lt "$current" ]; then
    echo "$candidate"
  else
    echo "$current"
  fi
}

CORES="$(detect_cores)"
RAM_GB="$(detect_ram_gb)"

if [ "$RAM_GB" -ge 32 ] && [ "$CORES" -ge 8 ]; then
  HARDWARE_CLASS="workstation"
  AUTO_CEILING=10
elif [ "$RAM_GB" -ge 16 ] && [ "$CORES" -ge 4 ]; then
  HARDWARE_CLASS="high"
  AUTO_CEILING=6
elif [ "$RAM_GB" -ge 8 ] && [ "$CORES" -ge 2 ]; then
  HARDWARE_CLASS="standard"
  AUTO_CEILING=3
else
  HARDWARE_CLASS="low"
  AUTO_CEILING=2
fi

ENV_MAX="${MAX_PARALLEL_AGENTS:-}"
CODEX_MAX_THREADS="$(read_codex_max_threads)"
RECOMMENDED_CEILING="$AUTO_CEILING"
RECOMMENDED_CEILING="$(min_positive "$RECOMMENDED_CEILING" "$ENV_MAX")"
RECOMMENDED_CEILING="$(min_positive "$RECOMMENDED_CEILING" "$CODEX_MAX_THREADS")"

if [ "$RECOMMENDED_CEILING" -le 1 ]; then
  DEFAULT_SUBSTRATE="local"
else
  DEFAULT_SUBSTRATE="subagents"
fi

AGENT_TEAMS_AVAILABLE=false
if [ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-0}" = "1" ]; then
  AGENT_TEAMS_AVAILABLE=true
fi

case "$MODE" in
  --json|json)
    python3 - "$CORES" "$RAM_GB" "$HARDWARE_CLASS" "$AUTO_CEILING" "${ENV_MAX:-}" "${CODEX_MAX_THREADS:-}" "$RECOMMENDED_CEILING" "$DEFAULT_SUBSTRATE" "$AGENT_TEAMS_AVAILABLE" <<'PY'
import json
import sys

keys = [
    "cores",
    "ram_gb",
    "hardware_class",
    "auto_ceiling",
    "max_parallel_agents",
    "codex_max_threads",
    "recommended_ceiling",
    "default_substrate",
    "agent_teams_available",
]
values = dict(zip(keys, sys.argv[1:]))
for key in ("cores", "ram_gb", "auto_ceiling", "recommended_ceiling"):
    values[key] = int(values[key])
values["max_parallel_agents"] = int(values["max_parallel_agents"]) if values["max_parallel_agents"].isdigit() else None
values["codex_max_threads"] = int(values["codex_max_threads"]) if values["codex_max_threads"].isdigit() else None
values["agent_teams_available"] = values["agent_teams_available"] == "true"
print(json.dumps(values, sort_keys=True))
PY
    ;;
  --summary|summary)
    echo "parallel capacity: ${HARDWARE_CLASS}, ${CORES} cores, ${RAM_GB}GB RAM, recommended ${RECOMMENDED_CEILING}, default ${DEFAULT_SUBSTRATE}"
    ;;
  --help|-h|help)
    echo "Usage: bash scripts/parallel-capacity.sh [--json|--summary]"
    ;;
  *)
    cat <<EOF
## Parallel Capacity Profile

- CPU cores: ${CORES}
- RAM GB: ${RAM_GB}
- Hardware class: ${HARDWARE_CLASS}
- Auto ceiling: ${AUTO_CEILING}
- MAX_PARALLEL_AGENTS: ${ENV_MAX:-unset}
- Codex max_threads: ${CODEX_MAX_THREADS:-unset}
- Recommended ceiling: ${RECOMMENDED_CEILING}
- Default execution substrate: ${DEFAULT_SUBSTRATE}
- Agent teams available: ${AGENT_TEAMS_AVAILABLE}

## Execution Substrate Guidance

- local: use for one tight reasoning loop, shared files, low hardware, or when coordination costs exceed speedup.
- subagents: default for bounded same-workspace research, audit, review, and implementation packets with clear ownership.
- parallel-instances: use only for large disjoint work where separate sessions or worktrees materially shorten the critical path and aggregation is planned.
- agent-teams: opt-in experimental only when CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 and peer coordination is necessary.

## Budget Formula

effective_parallel_budget = min(recommended_ceiling, independent_packets, supervisor_review_capacity, verification_capacity)
EOF
    ;;
esac
