#!/bin/bash
# Static anti-lazy scorecard for effectiveness fixtures.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/effectiveness"
FORMAT="text"

REQUIRED_RULES=(
  "evidence_free_closeout"
  "failed_verification_positive_closeout"
  "shallow_fake_source_ledger"
  "tests_passed_without_command_evidence"
  "human_equivalent_only_estimate"
  "linear_lane_scaling"
)

usage() {
  echo "usage: $0 [--json]" >&2
}

case "${1:-}" in
  "")
    ;;
  "--json")
    FORMAT="json"
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

json_escape() {
  local tab
  tab="$(printf '\t')"
  printf '%s' "$1" | sed "s/\\\\/\\\\\\\\/g; s/\"/\\\\\"/g; s/${tab}/\\\\t/g"
}

contains_rule() {
  local rules="$1"
  local wanted="$2"
  case " $rules " in
    *" $wanted "*) return 0 ;;
    *) return 1 ;;
  esac
}

append_rule() {
  local rules="$1"
  local rule="$2"
  if [ -n "$rules" ]; then
    printf '%s %s' "$rules" "$rule"
  else
    printf '%s' "$rule"
  fi
}

has_command_evidence() {
  local file="$1"
  grep -Eiq '(^|[[:space:]-])(Commands? Run|Command|Exit code|stdout|stderr):' "$file" || \
    grep -Eiq '`?(bash|npm|pnpm|yarn|pytest|python3?|go test|cargo test|make)[[:space:]][^`[:cntrl:]]+' "$file"
}

source_marker_count() {
  local file="$1"
  awk '
    function lower(s) { return tolower(s) }
    /^[#]+[[:space:]]/ && in_ledger && lower($0) !~ /source ledger/ { in_ledger = 0 }
    lower($0) ~ /source ledger/ { in_ledger = 1; next }
    in_ledger && /^[-*][[:space:]]/ && ($0 ~ /(https?:\/\/|[A-Za-z0-9_.\/-]+\.(md|sh|json|toml|yaml|yml)(:[0-9]+)?|reviewed|cited|repo|file)/) {
      count++
    }
    END { print count + 0 }
  ' "$file"
}

detect_rules() {
  local file="$1"
  local rules=""

  if grep -Eiq '(^|[[:space:]])(closeout|ship(ped)?|done|complete|verified|ready for production|final status)' "$file"; then
    if ! grep -Eiq '(^|[[:space:]-])(Evidence|Commands Run|Verification Evidence|Source Ledger|Test Evidence|Artifacts?|Exit code):' "$file" || \
       grep -Eiq '(no evidence|evidence:[[:space:]]*(none|n/a|not recorded)|not run|trust me)' "$file"; then
      rules="$(append_rule "$rules" "evidence_free_closeout")"
    fi
  fi

  if grep -Eiq '((verification|tests?|qa)[^[:cntrl:]]*(failed|fail|red|did not pass|broken)|failed verification)' "$file" && \
     grep -Eiq '((closeout|status|result|ship|shipped|complete|done|ready)[^[:cntrl:]]*(pass|passed|green|complete|done|verified|shipped|ready))' "$file"; then
    rules="$(append_rule "$rules" "failed_verification_positive_closeout")"
  fi

  if grep -Eiq 'source ledger' "$file"; then
    if grep -Eiq 'source ledger[^[:cntrl:]]*(done|trust me|google|internet|tbd|placeholder|fake|n/a|none)' "$file" || \
       [ "$(source_marker_count "$file")" -lt 2 ]; then
      rules="$(append_rule "$rules" "shallow_fake_source_ledger")"
    fi
  fi

  if grep -Eiq '(^|[^[:alnum:]_])(tests?|verification|smoke|harness)[^[:cntrl:]]*(^|[^[:alnum:]_])(passed|green|ok|okay)([^[:alnum:]_]|$)' "$file" && ! has_command_evidence "$file"; then
    rules="$(append_rule "$rules" "tests_passed_without_command_evidence")"
  fi

  if grep -Eiq 'Estimate type:[[:space:]]*human[- ]equivalent' "$file" || \
     { grep -Eiq 'human[- ]equivalent' "$file" && ! grep -Eiq 'Agent wall-clock:' "$file"; }; then
    rules="$(append_rule "$rules" "human_equivalent_only_estimate")"
  fi

  if grep -Eiq '(([0-9]+|ten)[ -]?(agents|lanes|workers).*(means|=|=>|therefore|so).*[0-9]+x)|((agents|lanes|workers).*scale.*linear)|(linear lane scaling)|([0-9]+x faster)' "$file"; then
    rules="$(append_rule "$rules" "linear_lane_scaling")"
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
      "green")
        printf 'green:'
        return 0
        ;;
      "red")
        printf 'red:%s' "${2:-}"
        return 0
        ;;
    esac
  fi

  case "$file" in
    */green/*)
      printf 'green:'
      ;;
    */red/*)
      local base
      base="$(basename "$file" .md)"
      base="${base//-/_}"
      printf 'red:%s' "$base"
      ;;
    *)
      printf 'unknown:'
      ;;
  esac
}

rules_json_array() {
  local rules="$1"
  local first=1
  printf '['
  for rule in $rules; do
    if [ "$first" -eq 0 ]; then
      printf ','
    fi
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
        message="green fixture triggered anti-lazy rule(s)"
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
  overall="pass"
  [ "$failures" -eq 0 ] || overall="fail"
  printf '{'
  printf '"status":"%s",' "$overall"
  printf '"fixture_dir":"%s",' "$(json_escape "${FIXTURE_DIR#$ROOT_DIR/}")"
  printf '"totals":{"fixtures":%d,"green_passed":%d,"red_rejected":%d,"failures":%d},' "$total" "$green_passed" "$red_rejected" "$failures"
  printf '"missing_required_red_rules":'
  rules_json_array "$missing_rules"
  printf ',"results":['
  for i in "${!RESULT_FIXTURE[@]}"; do
    if [ "$i" -gt 0 ]; then
      printf ','
    fi
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
  printf ']}\n'
else
  echo "Anti-Lazy Harness Scorecard"
  echo "Fixture dir: ${FIXTURE_DIR#$ROOT_DIR/}"
  echo "Fixtures: $total | green passed: $green_passed | red rejected: $red_rejected | failures: $failures"
  echo ""

  for i in "${!RESULT_FIXTURE[@]}"; do
    marker="[PASS]"
    [ "${RESULT_STATUS[$i]}" = "pass" ] || marker="[FAIL]"
    rules_text="${RESULT_RULES[$i]:-none}"
    if [ "${RESULT_EXPECTED[$i]}" = "red" ]; then
      echo "$marker ${RESULT_FIXTURE[$i]} expected=${RESULT_RULE[$i]} actual=${RESULT_ACTUAL[$i]} rules=$rules_text"
    else
      echo "$marker ${RESULT_FIXTURE[$i]} expected=${RESULT_EXPECTED[$i]} actual=${RESULT_ACTUAL[$i]} rules=$rules_text"
    fi
    if [ "${RESULT_STATUS[$i]}" != "pass" ]; then
      echo "       ${RESULT_MESSAGE[$i]}"
    fi
  done

  if [ -n "$missing_rules" ]; then
    echo ""
    echo "[FAIL] Missing red fixture coverage: $missing_rules"
  fi

  if [ "$failures" -eq 0 ]; then
    echo ""
    echo "[PASS] anti-lazy fixtures validated"
  fi
fi

if [ "$failures" -ne 0 ]; then
  exit 1
fi
