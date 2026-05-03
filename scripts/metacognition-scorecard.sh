#!/bin/bash
# Static scorecard for parallel-aware metacognition fixtures.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/metacognition"
FORMAT="text"
RUN_FIXTURES=0

REQUIRED_RULES=(
  "missing_task_classification"
  "missing_parallel_budget"
  "linear_parallel_claim"
  "reflection_without_evidence"
  "unsupported_confidence"
  "raw_cot_dependency"
  "unverified_self_report"
  "unresolved_blocker_closeout"
  "command_boundary_confusion"
  "workflow_route_order"
)

usage() {
  cat >&2 <<'EOF'
usage: scripts/metacognition-scorecard.sh [--json] [--fixtures]

Scores markdown artifacts under .taste/fixtures/metacognition by default.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--json")
      FORMAT="json"
      shift
      ;;
    "--fixtures")
      RUN_FIXTURES=1
      shift
      ;;
    "-h"|"--help")
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

json_escape() {
  local tab
  tab="$(printf '\t')"
  printf '%s' "$1" | sed "s/\\\\/\\\\\\\\/g; s/\"/\\\\\"/g; s/${tab}/\\\\t/g"
}

append_rule() {
  local rules="$1"
  local rule="$2"
  case " $rules " in
    *" $rule "*) printf '%s' "$rules" ;;
    *) [ -n "$rules" ] && printf '%s %s' "$rules" "$rule" || printf '%s' "$rule" ;;
  esac
}

contains_rule() {
  case " $1 " in
    *" $2 "*) return 0 ;;
    *) return 1 ;;
  esac
}

has_evidence_marker() {
  local file="$1"
  grep -Eiq '(Evidence Required|Evidence Checked|Verification Evidence|Source Ledger|Commands? Run|Command:|Exit code:|`(bash|npm|pnpm|python3?|pytest|go test|cargo test)[[:space:]])' "$file"
}

has_task_class() {
  local file="$1"
  grep -Eiq '^## Task Class[[:space:]]*$' "$file" && \
    grep -Eiq '(answer|webresearch|deepresearch|workflow|parallel|agentfactory|verify|introspect|blocked)' "$file"
}

has_parallel_budget() {
  local file="$1"
  grep -Eiq '^## Effective Parallel Budget[[:space:]]*$' "$file" && \
    grep -Eiq 'Effective budget:[[:space:]]*[0-9]+' "$file" && \
    grep -Eiq 'Decision:[[:space:]]*(local|subagents|parallel|blocked)' "$file"
}

workflow_route_order_ok() {
  local file="$1"
  awk '
    /^# Workflow Run:/ { workflow = NR }
    /^## Metacognitive Route$/ { route = NR }
    /^## Research Brief$/ { research = NR }
    /^## Introspection$/ { introspection = NR }
    END {
      if (!workflow) {
        exit 0
      }
      if (route && research && introspection && route < research && research < introspection) {
        exit 0
      }
      exit 1
    }
  ' "$file"
}

detect_rules() {
  local file="$1"
  local rules=""

  if ! has_task_class "$file"; then
    rules="$(append_rule "$rules" "missing_task_classification")"
  fi

  if ! has_parallel_budget "$file"; then
    rules="$(append_rule "$rules" "missing_parallel_budget")"
  fi

  if grep -Eiq '(([0-9]+|ten|max)[ -]?(agents|lanes|workers).*(means|=|=>|therefore|so).*[0-9]+x)|((agents|lanes|workers).*scale.*linear)|(linear parallel)|(linear lane)|(max agents means max quality)|(use all (agents|lanes|workers))' "$file"; then
    rules="$(append_rule "$rules" "linear_parallel_claim")"
  fi

  if grep -Eiq '(reflect|reflection|introspect|metacognitive|metacognition|self-audit)' "$file" && ! has_evidence_marker "$file"; then
    rules="$(append_rule "$rules" "reflection_without_evidence")"
  fi

  if grep -Eiq '(Confidence:[[:space:]]*(high|complete|ready)|Level:[[:space:]]*high|ready to ship|ready for production|verified|complete)' "$file"; then
    if ! has_evidence_marker "$file" || grep -Eiq '(not run|evidence:[[:space:]]*(none|n/a)|no evidence|trust me|missing tests)' "$file"; then
      rules="$(append_rule "$rules" "unsupported_confidence")"
    fi
  fi

  if grep -Eiq '(raw hidden chain-of-thought|required raw chain.of.thought|full chain.of.thought required|depends on hidden cot|score hidden cot|provider thinking blocks required)' "$file"; then
    rules="$(append_rule "$rules" "raw_cot_dependency")"
  fi

  if grep -Eiq '(self-report|self report|model says|model reported|i introspected)' "$file" && \
     grep -Eiq '(promote|promoted|durable memory|memory candidate|lesson|prompt-contract|prompt contract)' "$file" && \
     ! grep -Eiq '(verified outcome|repo-verified|web-verified|command evidence|Verification Evidence|Exit code:[[:space:]]*0)' "$file"; then
    rules="$(append_rule "$rules" "unverified_self_report")"
  fi

  if grep -Eiq '(unresolved blocker|blocker:[[:space:]]*(open|unresolved)|Blocker Decision:[[:space:]]*(BLOCKED|FIX_REQUIRED|REPLAN_REQUIRED))' "$file" && \
     grep -Eiq '(ready|complete|closeout|shipped|verified|PASS)' "$file"; then
    rules="$(append_rule "$rules" "unresolved_blocker_closeout")"
  fi

  if grep -Eiq '(/metacognition|metacognitive route|metacognition).{0,80}(replace|replaces|replacing|satisfy|satisfies|satisfied|skip|skips|instead of|substitute).{0,80}(/introspect|introspection|self-audit|hard gate)' "$file" || \
     grep -Eiq '(/introspect|introspection|self-audit|hard gate).{0,80}(replace|replaces|replacing|satisfy|satisfies|satisfied|skip|skips|instead of|substitute).{0,80}(/metacognition|metacognitive route|metacognition)' "$file"; then
    rules="$(append_rule "$rules" "command_boundary_confusion")"
  fi

  if ! workflow_route_order_ok "$file"; then
    rules="$(append_rule "$rules" "workflow_route_order")"
  fi

  printf '%s' "$rules"
}

expected_for_file() {
  local file="$1"
  local directive
  directive="$(
    sed -n \
      -e 's/.*scorecard:[[:space:]]*\([^>]*\).*/\1/p' \
      -e 's/^scorecard:[[:space:]]*\(.*\)$/\1/p' \
      "$file" | sed -n '1p'
  )"

  if [ -n "$directive" ]; then
    set -- $directive
    case "${1:-}" in
      "green") printf 'green:'; return 0 ;;
      "red") printf 'red:%s' "${2:-}"; return 0 ;;
    esac
  fi

  case "$file" in
    */green/*) printf 'green:' ;;
    */red/*)
      local base
      base="$(basename "$file" .md)"
      base="${base//-/_}"
      printf 'red:%s' "$base"
      ;;
    *) printf 'unknown:' ;;
  esac
}

rules_json_array() {
  local rules="$1"
  local first=1
  printf '['
  for rule in $rules; do
    [ "$first" -eq 0 ] && printf ','
    printf '"%s"' "$(json_escape "$rule")"
    first=0
  done
  printf ']'
}

declare -a RESULT_FIXTURE=()
declare -a RESULT_EXPECTED=()
declare -a RESULT_RULE=()
declare -a RESULT_ACTUAL=()
declare -a RESULT_RULES=()
declare -a RESULT_STATUS=()
declare -a RESULT_MESSAGE=()

add_result() {
  RESULT_FIXTURE+=("$1")
  RESULT_EXPECTED+=("$2")
  RESULT_RULE+=("$3")
  RESULT_ACTUAL+=("$4")
  RESULT_RULES+=("$5")
  RESULT_STATUS+=("$6")
  RESULT_MESSAGE+=("$7")
}

if [ ! -d "$FIXTURE_DIR" ]; then
  echo "[FAIL] Missing fixture directory: ${FIXTURE_DIR#$ROOT_DIR/}" >&2
  exit 1
fi

total=0
green_passed=0
red_rejected=0
failures=0
covered_rules=""

while IFS= read -r file; do
  [ -n "$file" ] || continue
  total=$((total + 1))

  rel="${file#$FIXTURE_DIR/}"
  expected="$(expected_for_file "$file")"
  expected_kind="${expected%%:*}"
  expected_rule="${expected#*:}"
  rules="$(detect_rules "$file")"
  actual="pass"
  [ -n "$rules" ] && actual="fail"
  status="pass"
  message="ok"

  case "$expected_kind" in
    "green")
      if [ "$actual" = "pass" ]; then
        green_passed=$((green_passed + 1))
      else
        status="fail"
        message="green fixture triggered metacognition rule(s)"
      fi
      ;;
    "red")
      if [ -z "$expected_rule" ]; then
        status="fail"
        message="red fixture lacks expected rule id"
      elif [ "$actual" = "fail" ] && contains_rule "$rules" "$expected_rule"; then
        red_rejected=$((red_rejected + 1))
        covered_rules="$(append_rule "$covered_rules" "$expected_rule")"
      else
        status="fail"
        message="red fixture did not trigger expected rule"
      fi
      ;;
    *)
      status="fail"
      message="fixture lacks green/red expectation"
      ;;
  esac

  [ "$status" = "pass" ] || failures=$((failures + 1))
  add_result "$rel" "$expected_kind" "$expected_rule" "$actual" "$rules" "$status" "$message"
done < <(find "$FIXTURE_DIR" -type f -name '*.md' | sort)

if [ "$total" -eq 0 ]; then
  failures=$((failures + 1))
fi

missing_rules=""
for rule in "${REQUIRED_RULES[@]}"; do
  if ! contains_rule "$covered_rules" "$rule"; then
    missing_rules="$(append_rule "$missing_rules" "$rule")"
    failures=$((failures + 1))
  fi
done

if [ "$FORMAT" = "json" ]; then
  status="pass"
  [ "$failures" -eq 0 ] || status="fail"
  printf '{'
  printf '"status":"%s",' "$status"
  printf '"total":%s,' "$total"
  printf '"green_passed":%s,' "$green_passed"
  printf '"red_rejected":%s,' "$red_rejected"
  printf '"missing_rules":'
  rules_json_array "$missing_rules"
  printf ',"results":['
  for i in "${!RESULT_FIXTURE[@]}"; do
    [ "$i" -gt 0 ] && printf ','
    printf '{'
    printf '"fixture":"%s",' "$(json_escape "${RESULT_FIXTURE[$i]}")"
    printf '"expected":"%s",' "$(json_escape "${RESULT_EXPECTED[$i]}")"
    printf '"expected_rule":"%s",' "$(json_escape "${RESULT_RULE[$i]}")"
    printf '"actual":"%s",' "$(json_escape "${RESULT_ACTUAL[$i]}")"
    printf '"rules":'
    rules_json_array "${RESULT_RULES[$i]}"
    printf ',"status":"%s",' "$(json_escape "${RESULT_STATUS[$i]}")"
    printf '"message":"%s"' "$(json_escape "${RESULT_MESSAGE[$i]}")"
    printf '}'
  done
  printf ']}'
  printf '\n'
else
  for i in "${!RESULT_FIXTURE[@]}"; do
    printf '[%s] %s expected=%s rule=%s actual=%s rules=%s\n' \
      "${RESULT_STATUS[$i]}" "${RESULT_FIXTURE[$i]}" "${RESULT_EXPECTED[$i]}" \
      "${RESULT_RULE[$i]:-none}" "${RESULT_ACTUAL[$i]}" "${RESULT_RULES[$i]:-none}"
  done
  if [ "$failures" -eq 0 ]; then
    echo "[PASS] metacognition scorecard fixtures passed (${green_passed} green, ${red_rejected} red)"
  else
    echo "[FAIL] metacognition scorecard failures=${failures} missing_rules=${missing_rules:-none}" >&2
  fi
fi

[ "$failures" -eq 0 ]
