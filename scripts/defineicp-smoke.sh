#!/bin/bash
# Static smoke gate for /defineicp ICP-to-taste evolution.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/defineicp"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/defineicp-smoke.sh --fixtures
  bash scripts/defineicp-smoke.sh --artifact PATH

--fixtures runs deterministic no-network fixtures.
--artifact validates one sanitized defineicp run artifact.
EOF
}

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing required file: $1"
}

require_grep() {
  local pattern="$1"
  local file="$2"
  grep -Fq -- "$pattern" "$file" 2>/dev/null || fail "missing pattern '$pattern' in $file"
}

require_not_grep() {
  local pattern="$1"
  local file="$2"
  if grep -Fq -- "$pattern" "$file" 2>/dev/null; then
    fail "forbidden pattern '$pattern' found in $file"
  fi
}

run_static_contract_checks() {
  local skill="$ROOT_DIR/.claude/skills/defineicp/SKILL.md"
  require_file "$skill"

  for pattern in \
    "name: defineicp" \
    "argument-hint:" \
    "disable-model-invocation: true" \
    "# /defineicp" \
    "ICP-to-taste evolution" \
    "proposal-first" \
    "Apply mode requires explicit user approval" \
    "Protected kernel" \
    "SPEC-first" \
    "research-first" \
    "evidence-backed verification" \
    "Anti-ICP" \
    "Source Ledger" \
    "ICP Claim Ledger" \
    "changed-line trace" \
    "pre-change hashes" \
    "backup both taste files" \
    "Write both files as one unit" \
    "ICP_DRAFTED" \
    "ICP_APPLIED" \
    "ICP_BLOCKED" \
    "/deepresearch" \
    "/introspect"; do
    require_grep "$pattern" "$skill"
  done

  for forbidden in \
    "source .env" \
    "cat .env" \
    "dotenv" \
    "printenv" \
    "env >" \
    "read .claude/settings.local.json"; do
    require_not_grep "$forbidden" "$skill"
  done

  for file in README.md CLAUDE.md AGENTS.md scripts/start-session.sh; do
    require_grep "/defineicp" "$ROOT_DIR/$file"
  done

  require_grep "defineicp" "$ROOT_DIR/scripts/harness-capability-map.sh"
  require_grep "defineicp-smoke" "$ROOT_DIR/scripts/harness-eval.sh"
  require_grep "defineicp-smoke" "$ROOT_DIR/scripts/release-check.sh"
  require_grep "m10-defineicp-taste-evolution" "$ROOT_DIR/evals/harness/tasks/m10-defineicp-taste-evolution.yaml"
  require_grep "m10-defineicp-taste-evolution" "$ROOT_DIR/evals/harness/golden/m10-defineicp-taste-evolution.json"
}

validate_artifact() {
  local artifact="$1"
  python3 - "$artifact" <<'PY'
import json
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])

SECRET_RE = re.compile(
    r"(sk-[A-Za-z0-9_-]{20,}|OPENAI_API_KEY|ANTHROPIC_API_KEY|"
    r"MINIMAX_API_KEY|password\s*[:=]|secret\s*[:=]|token\s*[:=]|"
    r"BEGIN [A-Z ]*PRIVATE KEY)",
    re.IGNORECASE,
)

PROTECTED_KERNEL = [
    "SPEC-first",
    "research-first",
    "evidence-backed verification",
    "explicit contracts",
    "single-owner state",
    "structured errors",
    "observability",
    "least privilege",
    "rollback",
    "separate verifier",
    "no silent destructive behavior",
]

VALID_LABELS = {
    "source-backed",
    "repo-derived",
    "user-stated",
    "inference",
    "assumption",
    "unknown",
}


def fail(message: str) -> None:
    print(f"[FAIL] {path}: {message}", file=sys.stderr)
    raise SystemExit(1)


def present(value) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value.strip()) and value.strip().lower() not in {"none", "n/a", "null", "missing", "todo", "tbd"}
    if isinstance(value, (list, tuple, set, dict)):
        return bool(value)
    return True


def as_list(value):
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


try:
    raw = path.read_text(encoding="utf-8")
except FileNotFoundError:
    fail("artifact file does not exist")

if SECRET_RE.search(raw):
    fail("artifact contains secret-like material")

try:
    data = json.loads(raw)
except json.JSONDecodeError as exc:
    fail(f"invalid JSON: {exc}")

if data.get("artifact_type") != "defineicp-run":
    fail("artifact_type must be defineicp-run")

mode = data.get("mode")
status = data.get("status")
if mode not in {"research", "proposal", "apply"}:
    fail("mode must be research, proposal, or apply")
if status not in {"ICP_DRAFTED", "ICP_APPLIED", "ICP_BLOCKED"}:
    fail("status must be ICP_DRAFTED, ICP_APPLIED, or ICP_BLOCKED")

if status == "ICP_APPLIED" and mode != "apply":
    fail("ICP_APPLIED requires apply mode")

scope = data.get("product_scope")
if not present(scope) or str(scope).lower() in {"ambiguous", "unknown", "current product"}:
    fail("product_scope must be explicit")

approval = data.get("approval", {})
if mode == "apply":
    if approval.get("explicit") is not True:
        fail("apply mode requires explicit approval")
    if not present(approval.get("approved_proposal_id")):
        fail("apply mode requires approved_proposal_id")
else:
    if data.get("taste_mutation", {}).get("applied") is True:
        fail("non-apply modes must not mutate taste files")

research = data.get("research", {})
source_ledger = research.get("source_ledger", {})
claim_ledger = as_list(research.get("claim_ledger"))
if not present(research.get("deepresearch_plan")):
    fail("missing deepresearch_plan")
if not any(present(source_ledger.get(key)) for key in ("cited", "reviewed_but_not_cited", "rejected", "conflicts")):
    fail("source ledger must contain at least one ledger entry")
if not claim_ledger:
    fail("claim ledger is required")

for claim in claim_ledger:
    if not isinstance(claim, dict):
        fail("claim ledger entries must be objects")
    if not present(claim.get("claim")):
        fail("claim ledger entry missing claim")
    if claim.get("label") not in VALID_LABELS:
        fail("claim ledger entry has invalid or missing label")
    if claim.get("label") in {"source-backed", "repo-derived", "user-stated"} and not present(claim.get("evidence")):
        fail("strong claim labels require evidence")

icp = data.get("icp", {})
primary = icp.get("primary", {})
for field in (
    "segment",
    "job_to_be_done",
    "pain_points",
    "trigger_events",
    "buyer_context",
    "adoption_channel",
    "objections",
    "proof_needed",
    "disqualifiers",
):
    if not present(primary.get(field)):
        fail(f"primary ICP missing {field}")

if not present(icp.get("anti_icp")):
    fail("anti_icp is required")

proposal = data.get("taste_evolution", {})
if mode in {"proposal", "apply"}:
    for field in ("taste_md_changes", "taste_vision_changes", "changed_line_trace", "what_not_to_change"):
        if not present(proposal.get(field)):
            fail(f"taste evolution missing {field}")

    checklist = proposal.get("protected_kernel_checklist", {})
    for invariant in PROTECTED_KERNEL:
        if checklist.get(invariant) not in {True, "preserved", "explicitly-approved-change"}:
            fail(f"protected kernel invariant not preserved: {invariant}")

if mode == "apply" or status == "ICP_APPLIED":
    mutation = data.get("taste_mutation", {})
    if mutation.get("applied") is not True:
        fail("apply mode requires taste_mutation.applied=true")
    for field in ("backup_paths", "pre_change_hashes", "post_change_hashes", "rollback_plan"):
        if not present(mutation.get(field)):
            fail(f"apply mode missing {field}")

verification = data.get("verification", {})
if not present(verification.get("commands")):
    fail("verification command evidence is required")
if verification.get("status") not in {"pass", "pass_with_notes", "fail", "blocked"}:
    fail("verification status is invalid")
if status == "ICP_APPLIED" and verification.get("status") not in {"pass", "pass_with_notes"}:
    fail("ICP_APPLIED requires passing verification")

introspection = data.get("introspection", {})
for field in ("likely_mistakes", "evidence_checked", "confidence"):
    if not present(introspection.get(field)):
        fail(f"introspection missing {field}")
PY
}

run_fixture_checks() {
  require_file "$FIXTURE_DIR/green/valid-proposal.json"
  require_file "$FIXTURE_DIR/green/valid-apply.json"

  local green_count=0
  local red_count=0
  local fixture

  while IFS= read -r fixture; do
    validate_artifact "$fixture"
    green_count=$((green_count + 1))
  done < <(find "$FIXTURE_DIR/green" -type f -name '*.json' | sort)

  while IFS= read -r fixture; do
    if validate_artifact "$fixture" >/dev/null 2>&1; then
      fail "red fixture unexpectedly passed: $fixture"
    fi
    red_count=$((red_count + 1))
  done < <(find "$FIXTURE_DIR/red" -type f -name '*.json' | sort)

  [ "$green_count" -ge 2 ] || fail "expected at least 2 green defineicp fixtures"
  [ "$red_count" -ge 6 ] || fail "expected at least 6 red defineicp fixtures"
}

case "${1:-}" in
  "--fixtures")
    run_static_contract_checks
    run_fixture_checks
    echo "[PASS] /defineicp ICP-to-taste smoke passed"
    ;;
  "--artifact")
    [ -n "${2:-}" ] || fail "--artifact requires a path"
    validate_artifact "$2"
    echo "[PASS] defineicp artifact valid: $2"
    ;;
  "-h"|"--help")
    usage
    exit 0
    ;;
  "")
    usage
    exit 2
    ;;
  *)
    usage
    exit 2
    ;;
esac
