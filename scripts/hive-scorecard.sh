#!/bin/bash
# Static scorecard for governed hive artifacts.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/hive"
FORMAT="text"

REQUIRED_RULES=(
  "missing_role_map"
  "missing_blackboard"
  "missing_hive_budget"
  "consensus_without_dissent"
  "unverified_hive_claim"
  "shared_state_without_lock"
  "linear_hive_scaling"
  "hive_replaces_core_gate"
)

usage() {
  cat >&2 <<'EOF'
usage: scripts/hive-scorecard.sh [--json] [--fixtures]

Scores markdown artifacts under .taste/fixtures/hive.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--json"|"--fixtures") [ "$1" = "--json" ] && FORMAT="json"; shift ;;
    "-h"|"--help") usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

json_escape() {
  local tab
  tab="$(printf '\t')"
  printf '%s' "$1" | sed "s/\\\\/\\\\\\\\/g; s/\"/\\\\\"/g; s/${tab}/\\\\t/g"
}

append_rule() {
  local rules="$1" rule="$2"
  case " $rules " in
    *" $rule "*) printf '%s' "$rules" ;;
    *) [ -n "$rules" ] && printf '%s %s' "$rules" "$rule" || printf '%s' "$rule" ;;
  esac
}

contains_rule() {
  case " $1 " in *" $2 "*) return 0 ;; *) return 1 ;; esac
}

has_evidence_marker() {
  grep -Eiq '(Evidence|Verification Evidence|Commands? Run|Command:|Exit code:|Source Ledger|repo-verified|web-verified|parent_verified|`(bash|npm|pnpm|python3?|pytest|go test|cargo test)[[:space:]])' "$1"
}

detect_rules() {
  local file="$1" rules=""

  grep -Eiq '^## Role Map[[:space:]]*$' "$file" && grep -Eiq '(queen|supervisor|scout|builder|reviewer|verifier|scribe)' "$file" || rules="$(append_rule "$rules" "missing_role_map")"
  grep -Eiq '^## Blackboard[[:space:]]*$' "$file" && grep -Eiq '(Claim ID|Owner|Evidence|Status|Conflicts)' "$file" || rules="$(append_rule "$rules" "missing_blackboard")"
  grep -Eiq '(Effective hive budget:[[:space:]]*[0-9]+|effective_hive_budget|## Capacity Profile)' "$file" || rules="$(append_rule "$rules" "missing_hive_budget")"

  if grep -Eiq '(consensus|agree|agreement|majority vote|voted)' "$file" && ! grep -Eiq '(Dissent And Conflict Log|skeptic|reviewer|arbitration|minority)' "$file"; then
    rules="$(append_rule "$rules" "consensus_without_dissent")"
  fi

  if grep -Eiq '(hive says|agents agree|consensus says|collective decided|swarm decided|verified|ready|complete|ship)' "$file" && \
     { ! has_evidence_marker "$file" || grep -Eiq '(Evidence:[[:space:]]*(none|n/a)|no evidence|without evidence)' "$file"; }; then
    rules="$(append_rule "$rules" "unverified_hive_claim")"
  fi

  if grep -Eiq '(shared state|shared file|blackboard update|memory update|registry update|shared artifact)' "$file" && \
     { ! grep -Eiq '(lock|merge barrier|owned files|ownership|do not touch)' "$file" || grep -Eiq '(without lock|no lock|Lock/Merge Barrier[[:space:]]*\\|.*none|\\|[[:space:]]*none[[:space:]]*$)' "$file"; }; then
    rules="$(append_rule "$rules" "shared_state_without_lock")"
  fi

  if grep -Eiq '(([0-9]+|ten|max)[ -]?(agents|roles|lanes|workers).*(means|=|=>|therefore|so).*[0-9]+x)|((hive|agents|roles|lanes|workers).*scale.*linear)|(linear hive)|(more agents means)|(max agents means max quality)' "$file"; then
    rules="$(append_rule "$rules" "linear_hive_scaling")"
  fi

  if grep -Eiq '(/hive|hiveworkflow|hive).{0,80}(replace|replaces|satisfy|satisfies|skip|skips|instead of|substitute).{0,80}(/parallel|/workflow|/introspect|/verify|verification|hard gate)' "$file"; then
    rules="$(append_rule "$rules" "hive_replaces_core_gate")"
  fi

  printf '%s' "$rules"
}

expected_for_file() {
  local file="$1" directive
  directive="$(sed -n -e 's/.*scorecard:[[:space:]]*\([^>]*\).*/\1/p' -e 's/^scorecard:[[:space:]]*\(.*\)$/\1/p' "$file" | sed -n '1p')"
  if [ -n "$directive" ]; then
    set -- $directive
    [ "${1:-}" = "green" ] && { printf 'green:'; return; }
    [ "${1:-}" = "red" ] && { printf 'red:%s' "${2:-}"; return; }
  fi
  case "$file" in
    */green/*) printf 'green:' ;;
    */red/*) local base; base="$(basename "$file" .md)"; printf 'red:%s' "${base//-/_}" ;;
    *) printf 'unknown:' ;;
  esac
}

rules_json_array() {
  local rules="$1" first=1 rule
  printf '['
  for rule in $rules; do
    [ "$first" -eq 0 ] && printf ','
    printf '"%s"' "$(json_escape "$rule")"
    first=0
  done
  printf ']'
}

[ -d "$FIXTURE_DIR" ] || { echo "[FAIL] Missing fixture directory: ${FIXTURE_DIR#$ROOT_DIR/}" >&2; exit 1; }

declare -a RESULT_FIXTURE=() RESULT_EXPECTED=() RESULT_RULE=() RESULT_ACTUAL=() RESULT_RULES=() RESULT_STATUS=() RESULT_MESSAGE=()
add_result() {
  RESULT_FIXTURE+=("$1"); RESULT_EXPECTED+=("$2"); RESULT_RULE+=("$3"); RESULT_ACTUAL+=("$4"); RESULT_RULES+=("$5"); RESULT_STATUS+=("$6"); RESULT_MESSAGE+=("$7")
}

total=0; green_passed=0; red_rejected=0; failures=0; covered_rules=""
while IFS= read -r file; do
  [ -n "$file" ] || continue
  total=$((total + 1))
  rel="${file#$FIXTURE_DIR/}"
  expected="$(expected_for_file "$file")"
  expected_kind="${expected%%:*}"
  expected_rule="${expected#*:}"
  rules="$(detect_rules "$file")"
  actual="pass"; [ -n "$rules" ] && actual="fail"
  status="pass"; message="ok"
  case "$expected_kind" in
    green) [ "$actual" = "pass" ] && green_passed=$((green_passed + 1)) || { status="fail"; message="green fixture triggered hive rule(s)"; } ;;
    red)
      if [ "$actual" = "fail" ] && contains_rule "$rules" "$expected_rule"; then
        red_rejected=$((red_rejected + 1)); covered_rules="$(append_rule "$covered_rules" "$expected_rule")"
      else
        status="fail"; message="red fixture did not trigger expected rule"
      fi ;;
    *) status="fail"; message="fixture lacks green/red expectation" ;;
  esac
  [ "$status" = "pass" ] || failures=$((failures + 1))
  add_result "$rel" "$expected_kind" "$expected_rule" "$actual" "$rules" "$status" "$message"
done < <(find "$FIXTURE_DIR" -type f -name '*.md' | sort)

[ "$total" -gt 0 ] || failures=$((failures + 1))
missing_rules=""
for rule in "${REQUIRED_RULES[@]}"; do
  if ! contains_rule "$covered_rules" "$rule"; then
    missing_rules="$(append_rule "$missing_rules" "$rule")"
    failures=$((failures + 1))
  fi
done

if [ "$FORMAT" = "json" ]; then
  status="pass"; [ "$failures" -eq 0 ] || status="fail"
  printf '{"status":"%s","total":%s,"green_passed":%s,"red_rejected":%s,"missing_rules":' "$status" "$total" "$green_passed" "$red_rejected"
  rules_json_array "$missing_rules"
  printf ',"results":['
  for i in "${!RESULT_FIXTURE[@]}"; do
    [ "$i" -gt 0 ] && printf ','
    printf '{"fixture":"%s","expected":"%s","expected_rule":"%s","actual":"%s","rules":' "$(json_escape "${RESULT_FIXTURE[$i]}")" "$(json_escape "${RESULT_EXPECTED[$i]}")" "$(json_escape "${RESULT_RULE[$i]}")" "$(json_escape "${RESULT_ACTUAL[$i]}")"
    rules_json_array "${RESULT_RULES[$i]}"
    printf ',"status":"%s","message":"%s"}' "$(json_escape "${RESULT_STATUS[$i]}")" "$(json_escape "${RESULT_MESSAGE[$i]}")"
  done
  printf ']}\n'
else
  for i in "${!RESULT_FIXTURE[@]}"; do
    printf '[%s] %s expected=%s rule=%s actual=%s rules=%s\n' "${RESULT_STATUS[$i]}" "${RESULT_FIXTURE[$i]}" "${RESULT_EXPECTED[$i]}" "${RESULT_RULE[$i]:-none}" "${RESULT_ACTUAL[$i]}" "${RESULT_RULES[$i]:-none}"
  done
  [ "$failures" -eq 0 ] && echo "[PASS] hive scorecard fixtures passed (${green_passed} green, ${red_rejected} red)" || echo "[FAIL] hive scorecard failures=${failures} missing_rules=${missing_rules:-none}" >&2
fi

[ "$failures" -eq 0 ]
