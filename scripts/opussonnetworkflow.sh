#!/bin/bash
# Prepare or launch the suggested Claude-only Opus planner + Sonnet executor route.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/opussonnetworkflow.sh --task "..." [--inner-contract CONTRACT] [--run-id ID] [--execute-planner]

This is the optional Claude-only workflow profile. It keeps the normal
/opusworkflow governance but requests Opus 4.7 for planning/judgment and
Sonnet 4.6 for execution. It is not the default MiniMax-backed mode.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

echo "[opussonnetworkflow] optional Claude-only mode: Opus 4.7 planning, Sonnet 4.6 execution"
exec bash "$ROOT_DIR/scripts/opusworkflow.sh" \
  --executor-provider claude-sonnet \
  --planner-model claude-opus-4-7 \
  --executor-model claude-sonnet-4-6 \
  "$@"
