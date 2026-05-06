#!/bin/bash
# Claude Code hook wrapper for the minmaxing temporal anchor.

set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
exec bash "$ROOT/scripts/time-anchor.sh" hook
