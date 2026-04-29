#!/bin/bash
# Static stress test for the /agentfactory production contract.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/.claude/skills/agentfactory/SKILL.md"
REGISTRY="$ROOT_DIR/hermes-registry.md"
FACTORY_TASTE="$ROOT_DIR/hermes-factory.taste.md"
BLUEPRINT="$ROOT_DIR/AGENT_FACTORY_AUDIT_AND_BLUEPRINT.md"
REVCLI_MAP="$ROOT_DIR/REVCLI_HERMES_AGENT_MAP.md"

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
require_file "$REGISTRY"
require_file "$FACTORY_TASTE"
require_file "$BLUEPRINT"
require_file "$REVCLI_MAP"

for phase in \
  "## Phase 0: Taste Gate" \
  "## Phase 1: Hermes Intent Intake" \
  "## Phase 2: Deep Research" \
  "## Phase 3: Hermes Manifest Drafting" \
  "## Phase 4: Capability Stack Design" \
  "## Phase 5: SPEC.md For The Hermes Agent" \
  "## Phase 6: Agent File Generation" \
  "## Phase 6.5: Introspect Hard Gate" \
  "## Phase 7: Independent Verification" \
  "## Phase 8: Closeout And Registry"; do
  require_text "$SKILL" "$phase"
done

question_count="$(
  awk '
    /^Ask these 12 kernel questions verbatim/ { in_questions = 1; next }
    in_questions && /^Rules:/ { in_questions = 0 }
    in_questions && /^[0-9]+\. / { count++ }
    END { print count + 0 }
  ' "$SKILL"
)"
[ "$question_count" -eq 12 ] || fail "Expected 12 Hermes intent questions, found $question_count"

for pattern in \
  "Agent Factory is a workflow on its own" \
  "AGENT_FACTORY_ARTIFACT" \
  "Compaction Safety" \
  "search -> read -> refine" \
  "reviewed-but-not-cited" \
  "rejected/downweighted" \
  "Research sufficiency gate" \
  "REVCLI Readiness Overlay" \
  "Runtime Control Plane" \
  "runtime_control_plane" \
  "system_of_record" \
  "runtime_identity" \
  "action_authority_matrix" \
  "credential_strategy" \
  "egress_policy" \
  "durable_orchestration" \
  "observability_contract" \
  "Status Transition Matrix" \
  "operator_exception" \
  "Required adversarial stress cases" \
  "Enterprise monolith" \
  "Runtime bypass" \
  "Argument escape" \
  "Audit mirage" \
  "memory-coherent" \
  "HERMES-{SLUG}-SPEC.md" \
  "hermes.manifest.md" \
  "hermes.system-prompt.md" \
  "hermes.memory-seed.json" \
  "hermes.runtime.json" \
  "hermes.deploy.md" \
  "hermes.verify.md" \
  "hermes.kill-switch.md" \
  "hermes-registry.md" \
  "independent verification" \
  "kill switch"; do
  require_text "$SKILL" "$pattern"
done

for status in "active" "experimental" "paused" "deprecated"; do
  require_text "$REGISTRY" "$status"
done

for column in "Runtime" "System Of Record" "Verification Isolation" "Last Kill Test" "Verify" "Kill Switch" "Runtime Evidence"; do
  require_text "$REGISTRY" "$column"
done

if grep -Eq 'verification_status.*draft.*verified.*failed.*waiv' "$SKILL"; then
  fail "verification_status still permits legacy waiver instead of operator_exception"
fi

for section in \
  "## Principles" \
  "## Enterprise Operating Model" \
  "## Approval Philosophy" \
  "## Memory Philosophy" \
  "## Non-Goals"; do
  require_text "$FACTORY_TASTE" "$section"
done

for section in \
  "## AUDIT: minmaxing" \
  "## AUDIT: revcli" \
  "## AGENT FACTORY: Skill Specification" \
  "## FIRST HERMES AGENT BLUEPRINT" \
  "## FAILURE MODE CATALOG" \
  "## CONSTRAINT COMPLIANCE SUMMARY"; do
  require_text "$BLUEPRINT" "$section"
done

for section in \
  "## Authority Chain" \
  "## Required Runtime Evidence For REVCLI-Ready Agents" \
  "## Candidate Hermes Agents" \
  "## REVCLI Runtime Blocks AgentFactory Must Respect" \
  "## REVCLI AgentFactory Overlay Checklist"; do
  require_text "$REVCLI_MAP" "$section"
done

require_no_invalid_active_rows() {
  local rows
  rows="$(
    awk '
      /^## Active Agents/ { in_active = 1; next }
      /^## / && in_active { in_active = 0 }
      in_active && /^\|/ && $0 !~ /Name/ && $0 !~ /---/ { print }
    ' "$REGISTRY"
  )"

  if [ -z "$rows" ]; then
    return 0
  fi

  while IFS= read -r row; do
    [ -z "$row" ] && continue
    IFS='|' read -r _ name slug purpose version authority runtime system_of_record lifecycle operator created last_verified isolation last_kill manifest spec verify kill runtime_evidence status _ <<< "$row"
    verify="$(trim "$verify")"
    kill="$(trim "$kill")"
    runtime_evidence="$(trim "$runtime_evidence")"
    last_verified="$(trim "$last_verified")"
    isolation="$(trim "$isolation")"
    last_kill="$(trim "$last_kill")"
    status="$(trim "$status")"

    [ "$status" = "active" ] || fail "Active registry row is in Active Agents but status is not active: $row"
    [ -n "$last_verified" ] || fail "Active registry row lacks Last Verified: $row"
    [ "$isolation" != "unknown" ] && [ -n "$isolation" ] || fail "Active registry row lacks verification isolation: $row"
    case "$last_kill" in
      *pass*|*PASS*) ;;
      *) fail "Active registry row lacks passing Last Kill Test: $row" ;;
    esac
    case "$verify" in
      *"hermes.verify.md"*) ;;
      *) fail "Active registry row lacks verify evidence link in Verify column: $row" ;;
    esac
    case "$kill" in
      *"hermes.kill-switch.md"*) ;;
      *) fail "Active registry row lacks kill-switch evidence link in Kill Switch column: $row" ;;
    esac
    case "$runtime_evidence" in
      *"hermes.runtime.json"*) ;;
      *) fail "Active registry row lacks runtime evidence link in Runtime Evidence column: $row" ;;
    esac
  done <<< "$rows"
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

validate_fixture() {
  local dir="$1"
  local manifest="$dir/hermes.manifest.md"
  local runtime="$dir/hermes.runtime.json"
  local verify="$dir/hermes.verify.md"
  local kill="$dir/hermes.kill-switch.md"
  local registry="$dir/registry-row.md"

  [ -f "$manifest" ] || return 1
  [ -f "$runtime" ] || return 1
  [ -f "$verify" ] || return 1
  [ -f "$kill" ] || return 1

  for pattern in \
    'runtime_control_plane' \
    'system_of_record' \
    'runtime_identity' \
    'action_authority_matrix' \
    'credential_strategy' \
    'egress_policy' \
    'durable_orchestration' \
    'observability_contract'; do
    grep -Fq "$pattern" "$manifest" || return 1
  done

  for pattern in \
    '"runtime_control_plane"' \
    '"entrypoint"' \
    '"cwd"' \
    '"argv_allowlist"' \
    '"denied_flags"' \
    '"allowed_config_paths"' \
    '"env_allowlist"' \
    '"input_schema"' \
    '"max_input_bytes"' \
    '"approval_gate"' \
    '"audit_sink"' \
    '"kill_switch"' \
    '"fixtures"' \
    '"expected_statuses"'; do
    grep -Fq "$pattern" "$runtime" || return 1
  done

  if grep -REq '(sk-[A-Za-z0-9]{8,}|password: *[A-Za-z0-9_./:-]{4,}|token: *[A-Za-z0-9_./:-]{8,})' "$manifest" "$runtime" "$verify" "$kill"; then
    return 1
  fi

  if grep -Fq 'decision_authority: "read-only"' "$manifest" && \
     grep -Eq '"side_effect_level":[[:space:]]*"(internal-write|external-effect|destructive)"' "$runtime"; then
    return 1
  fi

  if grep -Fq 'status: "active"' "$manifest"; then
    grep -Fq 'verification_status: "verified"' "$manifest" || return 1
    grep -Fq 'last_test_result: "pass"' "$kill" || return 1
    grep -Fq 'hermes.verify.md' "$registry" || return 1
    grep -Fq 'hermes.kill-switch.md' "$registry" || return 1
    grep -Fq 'hermes.runtime.json' "$registry" || return 1
  fi

  if grep -Fq 'verification_status: "operator_exception"' "$manifest" && \
     grep -Eq 'status: "active"|decision_authority: "read-write"|decision_authority: "destructive-allowed"' "$manifest"; then
    return 1
  fi

  if grep -Fq 'isolation_status: "proved separate"' "$verify" && \
     grep -Fq 'verifier_workspace: "same-session"' "$verify"; then
    return 1
  fi

  return 0
}

expect_invalid_fixture() {
  local dir="$1"
  local label="$2"
  if validate_fixture "$dir"; then
    fail "Negative fixture unexpectedly passed: $label"
  fi
}

expect_valid_fixture() {
  local dir="$1"
  local label="$2"
  if ! validate_fixture "$dir"; then
    fail "Positive fixture unexpectedly failed: $label"
  fi
}

run_negative_fixture_checks() {
  AGENTFACTORY_SMOKE_TMP="$(mktemp -d)"
  trap 'rm -rf "${AGENTFACTORY_SMOKE_TMP:-}"' EXIT
  local tmp="$AGENTFACTORY_SMOKE_TMP"

  mkdir -p "$tmp/positive" "$tmp/raw-secret" "$tmp/read-only-write" "$tmp/no-kill-evidence" "$tmp/operator-exception-active" "$tmp/verifier-overclaim"

  cat > "$tmp/positive/hermes.manifest.md" <<'EOF'
status: "active"
decision_authority: "read-only"
verification_status: "verified"
runtime_control_plane: {}
system_of_record: {}
runtime_identity: {}
action_authority_matrix: []
credential_strategy: {}
egress_policy: {}
durable_orchestration: {}
observability_contract: {}
EOF
  cat > "$tmp/positive/hermes.runtime.json" <<'EOF'
{
  "runtime_control_plane": {
    "audit_sink": "runtime-events.jsonl"
  },
  "entrypoint": {
    "cwd": ".",
    "argv_allowlist": [],
    "denied_flags": [],
    "allowed_config_paths": [],
    "env_allowlist": [],
    "input_schema": "fixtures/input.schema.json",
    "max_input_bytes": 32768
  },
  "actions": {
    "allowed": [
      {
        "side_effect_level": "none",
        "approval_gate": "none"
      }
    ]
  },
  "kill_switch": {
    "test_command": "true"
  },
  "fixtures": [],
  "expected_statuses": ["processed", "disabled"]
}
EOF
  cat > "$tmp/positive/hermes.verify.md" <<'EOF'
isolation_status: "same session independent pass"
verifier_workspace: "same-session"
EOF
  cat > "$tmp/positive/hermes.kill-switch.md" <<'EOF'
last_test_result: "pass"
EOF
  cat > "$tmp/positive/registry-row.md" <<'EOF'
hermes.verify.md hermes.kill-switch.md hermes.runtime.json
EOF

  cp "$tmp/positive/"* "$tmp/raw-secret/"
  printf 'token: sk-abcdef1234567890\n' >> "$tmp/raw-secret/hermes.manifest.md"

  cp "$tmp/positive/"* "$tmp/read-only-write/"
  cat > "$tmp/read-only-write/hermes.runtime.json" <<'EOF'
{
  "runtime_control_plane": {
    "audit_sink": "runtime-events.jsonl"
  },
  "entrypoint": {
    "cwd": ".",
    "argv_allowlist": [],
    "denied_flags": [],
    "allowed_config_paths": [],
    "env_allowlist": [],
    "input_schema": "fixtures/input.schema.json",
    "max_input_bytes": 32768
  },
  "actions": {
    "allowed": [
      {
        "side_effect_level": "internal-write",
        "approval_gate": "approval-required"
      }
    ]
  },
  "kill_switch": {
    "test_command": "true"
  },
  "fixtures": [],
  "expected_statuses": ["processed", "disabled"]
}
EOF

  cp "$tmp/positive/"* "$tmp/no-kill-evidence/"
  cat > "$tmp/no-kill-evidence/hermes.kill-switch.md" <<'EOF'
last_test_result: "not-tested"
EOF

  cp "$tmp/positive/"* "$tmp/operator-exception-active/"
  cat > "$tmp/operator-exception-active/hermes.manifest.md" <<'EOF'
status: "active"
decision_authority: "read-write"
verification_status: "operator_exception"
runtime_control_plane: {}
system_of_record: {}
runtime_identity: {}
action_authority_matrix: []
credential_strategy: {}
egress_policy: {}
durable_orchestration: {}
observability_contract: {}
EOF

  cp "$tmp/positive/"* "$tmp/verifier-overclaim/"
  cat > "$tmp/verifier-overclaim/hermes.verify.md" <<'EOF'
isolation_status: "proved separate"
verifier_workspace: "same-session"
EOF

  expect_valid_fixture "$tmp/positive" "positive-runtime-contract"
  expect_invalid_fixture "$tmp/raw-secret" "raw-secret"
  expect_invalid_fixture "$tmp/read-only-write" "read-only-with-write-action"
  expect_invalid_fixture "$tmp/no-kill-evidence" "active-without-kill-evidence"
  expect_invalid_fixture "$tmp/operator-exception-active" "operator-exception-active"
  expect_invalid_fixture "$tmp/verifier-overclaim" "verifier-overclaim"
}

require_no_invalid_active_rows
run_negative_fixture_checks

echo "[PASS] /agentfactory production contract smoke test passed"
