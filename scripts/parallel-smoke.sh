#!/bin/bash
# Static smoke test for the /parallel orchestration contract.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/.claude/skills/parallel/SKILL.md"
CAPACITY="$ROOT_DIR/scripts/parallel-capacity.sh"
AGENTFACTORY="$ROOT_DIR/.claude/skills/agentfactory/SKILL.md"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_file() {
  local file="$1"
  [ -f "$file" ] || fail "Missing required file: ${file#$ROOT_DIR/}"
}

require_text() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || fail "Missing '${pattern}' in ${file#$ROOT_DIR/}"
}

require_file "$SKILL"
require_file "$CAPACITY"
require_file "$AGENTFACTORY"

for pattern in \
  "# /parallel" \
  "Parallel Eligibility Audit" \
  "Hardware Capacity Profile" \
  "Execution Substrate Selector" \
  "Auto-Use Policy" \
  "Packet DAG" \
  "Ownership Matrix" \
  "Sync Barrier" \
  "Worker Result Schema" \
  "parallel-instances" \
  "subagents" \
  "Agent teams are opt-in experimental" \
  "MAX_PARALLEL_AGENTS" \
  "The main agent remains the orchestrator" \
  "effective_parallel_budget" \
  "development_host_profile" \
  "target_runtime_profile" \
  "host_capacity_profile" \
  "capacity_binding" \
  "concurrency_budget" \
  "agentfactory" \
  "Do not touch" \
  "Stop if"; do
  require_text "$SKILL" "$pattern"
done

for pattern in \
  "detect_cores" \
  "detect_ram_gb" \
  "read_codex_max_threads" \
  "recommended_ceiling" \
  "default_substrate" \
  "agent_teams_available" \
  "parallel-instances" \
  "agent-teams"; do
  require_text "$CAPACITY" "$pattern"
done

for pattern in \
  "development_host_profile" \
  "target_runtime_profile" \
  "host_capacity_profile" \
  "capacity_binding" \
  "concurrency_budget" \
  "degrade_policy" \
  "Capacity-Aware Runtime" \
  "capacity profile"; do
  require_text "$AGENTFACTORY" "$pattern"
done

JSON_OUTPUT="$(bash "$CAPACITY" --json)"
PARALLEL_CAPACITY_JSON="$JSON_OUTPUT" python3 - <<'PY' || fail "parallel-capacity JSON is invalid"
import json
import os
import sys

data = json.loads(os.environ["PARALLEL_CAPACITY_JSON"])
required = {
    "cores",
    "ram_gb",
    "hardware_class",
    "auto_ceiling",
    "max_parallel_agents",
    "codex_max_threads",
    "recommended_ceiling",
    "default_substrate",
    "agent_teams_available",
}
missing = required - set(data)
if missing:
    raise SystemExit(f"missing keys: {sorted(missing)}")
if data["recommended_ceiling"] < 1:
    raise SystemExit("recommended_ceiling must be positive")
if data["default_substrate"] not in {"local", "subagents"}:
    raise SystemExit("default_substrate has invalid value")
if data["hardware_class"] not in {"low", "standard", "high", "workstation"}:
    raise SystemExit("hardware_class has invalid value")
PY

echo "[PASS] /parallel orchestration contract smoke test passed"
