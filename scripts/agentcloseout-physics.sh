#!/bin/bash
# Repo-local wrapper for the deterministic AgentCloseout physics engine.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE_DIR="$ROOT_DIR/tools/agentcloseout-physics/engine"
BIN="$ENGINE_DIR/target/release/agentcloseout-physics"

if [ -x "$BIN" ]; then
  exec "$BIN" "$@"
fi

if command -v cargo >/dev/null 2>&1; then
  exec cargo run --quiet --manifest-path "$ENGINE_DIR/Cargo.toml" -- "$@"
fi

if [ -f "$HOME/.cargo/env" ]; then
  # shellcheck disable=SC1090
  . "$HOME/.cargo/env"
fi

if command -v cargo >/dev/null 2>&1; then
  exec cargo run --quiet --manifest-path "$ENGINE_DIR/Cargo.toml" -- "$@"
fi

echo "agentcloseout-physics: Rust toolchain not found; install cargo or build $BIN" >&2
exit 127
