#!/bin/bash
# PostCompact hook: record Claude Code's compact summary as working state.

set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
exec bash "$ROOT/scripts/state.sh" postcompact
