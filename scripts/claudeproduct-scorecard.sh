#!/bin/bash
# Static scorecard for Claude product knowledge artifacts.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/claudeproduct"
FORMAT="text"

REQUIRED_RULES=(
  "missing_question_class"
  "missing_official_source_policy"
  "missing_source_ledger"
  "unsupported_claude_claim"
  "stale_memory_answer"
  "unsafe_secret_dependency"
  "missing_harness_implication"
)

usage() {
  cat >&2 <<'EOF'
usage: scripts/claudeproduct-scorecard.sh [--json] [--fixtures]

Scores markdown artifacts under .taste/fixtures/claudeproduct.
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

has_question_class() {
  grep -Eiq '^## Claude Product Question[[:space:]]*$' "$1" && \
    grep -Eiq 'Question Class:[[:space:]]*(howto|capability|comparison|implementation|troubleshooting|selflookup|blocked)' "$1"
}

has_official_policy() {
  grep -Eiq '^## Source Policy[[:space:]]*$' "$1" && \
    grep -Eiq '(official Anthropic|official Claude|code\.claude\.com|claude\.com/docs|docs\.anthropic\.com|support\.claude\.com)' "$1"
}

has_source_ledger() {
  grep -Eiq '^## Source Ledger[[:space:]]*$' "$1" && \
    grep -Eiq '(Cited:|Reviewed But Not Cited:|Reviewed but not cited:)' "$1" && \
    grep -Eiq '(https://code\.claude\.com/docs|https://claude\.com/docs|https://docs\.anthropic\.com|https://support\.claude\.com|docs/harness-capability-map\.(md|json)|\.claude/|CLAUDE\.md|AGENTS\.md|README\.md|scripts/start-session\.sh|scripts/harness-capability-map\.sh)' "$1"
}

has_harness_implication() {
  grep -Eiq '^## Harness Implication[[:space:]]*$' "$1" && \
    grep -Eiq 'Route:[[:space:]]*(/webresearch|/deepresearch|/workflow|/metacognition|direct answer|blocked)' "$1" && \
    grep -Eiq 'Repo impact:' "$1"
}

detect_rules() {
  local file="$1" rules=""

  has_question_class "$file" || rules="$(append_rule "$rules" "missing_question_class")"
  has_official_policy "$file" || rules="$(append_rule "$rules" "missing_official_source_policy")"
  has_source_ledger "$file" || rules="$(append_rule "$rules" "missing_source_ledger")"
  has_harness_implication "$file" || rules="$(append_rule "$rules" "missing_harness_implication")"

  if grep -Eiq '(Claude|Claude Code|Claude\.ai|Anthropic|connectors?|plugins?|skills?|subagents?|artifacts?|API|MCP).{0,80}(supports|uses|requires|available|included|free|paid|deprecated|removed|always|never|all plans|every plan|generally available|beta|GA)' "$file"; then
    if ! grep -Eiq '(https://code\.claude\.com/docs|https://claude\.com/docs|https://docs\.anthropic\.com|https://support\.claude\.com)' "$file"; then
      rules="$(append_rule "$rules" "unsupported_claude_claim")"
    fi
  fi

  if grep -Eiq '(I remember|from memory|my training data|as of my knowledge cutoff|I think Claude|probably Claude|Claude usually)' "$file"; then
    if ! grep -Eiq '(https://code\.claude\.com/docs|https://claude\.com/docs|https://docs\.anthropic\.com|https://support\.claude\.com)' "$file"; then
      rules="$(append_rule "$rules" "stale_memory_answer")"
    fi
  fi

  if grep -Eiq '(read|inspect|open|cat|grep|rg).{0,40}(\.env|\.env\.\*|secrets?/|credentials|TOKEN|API_KEY|private connector|customer memory)' "$file"; then
    rules="$(append_rule "$rules" "unsafe_secret_dependency")"
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
    green) [ "$actual" = "pass" ] && green_passed=$((green_passed + 1)) || { status="fail"; message="green fixture triggered claudeproduct rule(s)"; } ;;
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
  [ "$failures" -eq 0 ] && echo "[PASS] claudeproduct scorecard fixtures passed (${green_passed} green, ${red_rejected} red)" || echo "[FAIL] claudeproduct scorecard failures=${failures} missing_rules=${missing_rules:-none}" >&2
fi

[ "$failures" -eq 0 ]
