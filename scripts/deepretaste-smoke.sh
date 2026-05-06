#!/bin/bash
# Static smoke gate for /deepretaste intent-to-ICP-to-taste workflow.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/deepretaste"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/deepretaste-smoke.sh --fixtures
  bash scripts/deepretaste-smoke.sh --artifact PATH

--fixtures runs deterministic no-network fixtures.
--artifact validates one sanitized deepretaste run artifact.
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
  local skill="$ROOT_DIR/.claude/skills/deepretaste/SKILL.md"
  require_file "$skill"

  for pattern in \
    "name: deepretaste" \
    "argument-hint:" \
    "disable-model-invocation: true" \
    "# /deepretaste" \
    "It is not an independent write path around \`/defineicp\`" \
    "/tastebootstrap" \
    "/defineicp" \
    "/deepresearch" \
    "/hive" \
    "SOTA-2026" \
    "Detect and record" \
    "product_scope" \
    "intent_detection" \
    "taste_state" \
    "Route Arbitration" \
    "effective_deepretaste_budget" \
    "ceilings" \
    "blackboard" \
    "Claim Ledger" \
    "current-source-backed" \
    "stable-source-backed" \
    "RETASTE_BOOTSTRAPPED" \
    "RETASTE_PROPOSED" \
    "RETASTE_APPLIED" \
    "RETASTE_BLOCKED" \
    "changed-line trace" \
    "protected-kernel checklist" \
    "pre-change hashes" \
    "backups" \
    "rollback"; do
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
    require_grep "/deepretaste" "$ROOT_DIR/$file"
  done

  require_grep "deepretaste" "$ROOT_DIR/scripts/harness-capability-map.sh"
  require_grep "deepretaste-smoke" "$ROOT_DIR/scripts/harness-eval.sh"
  require_grep "deepretaste-smoke" "$ROOT_DIR/scripts/release-check.sh"
  require_grep "m11-deepretaste-intent-icp-bootstrap" "$ROOT_DIR/evals/harness/tasks/m11-deepretaste-intent-icp-bootstrap.yaml"
  require_grep "m11-deepretaste-intent-icp-bootstrap" "$ROOT_DIR/evals/harness/golden/m11-deepretaste-intent-icp-bootstrap.json"
}

validate_artifact() {
  local artifact="$1"
  python3 - "$artifact" <<'PY'
import json
import pathlib
import re
import sys
from typing import Any

path = pathlib.Path(sys.argv[1])

SECRET_RE = re.compile(
    r"(sk-[A-Za-z0-9_-]{20,}|OPENAI_API_KEY|ANTHROPIC_API_KEY|"
    r"MINIMAX_API_KEY|password\s*[:=]|secret\s*[:=]|token\s*[:=]|"
    r"BEGIN [A-Z ]*PRIVATE KEY)",
    re.IGNORECASE,
)

SOTA_RE = re.compile(
    r"(SOTA|state of the art|best current practice|research-backed|2026 standard)",
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
    "current-source-backed",
    "stable-source-backed",
    "repo-derived",
    "user-stated",
    "inference",
    "assumption",
    "unknown",
}

VALID_MODES = {"research", "bootstrap", "proposal", "apply"}
VALID_STATUSES = {
    "RETASTE_RESEARCHED",
    "RETASTE_DRAFTED_LOW_CONFIDENCE",
    "RETASTE_PROPOSED",
    "RETASTE_WAITING_FOR_APPLY_APPROVAL",
    "RETASTE_BOOTSTRAPPED",
    "RETASTE_APPLIED",
    "RETASTE_BLOCKED",
}

VAGUE_APPROVALS = {
    "looks good",
    "go ahead",
    "ok",
    "okay",
    "approved",
    "ship it",
    "do it",
}


def fail(message: str) -> None:
    print(f"[FAIL] {path}: {message}", file=sys.stderr)
    raise SystemExit(1)


def present(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value.strip()) and value.strip().lower() not in {"none", "n/a", "null", "missing", "todo", "tbd"}
    if isinstance(value, (list, tuple, set, dict)):
        return bool(value)
    return True


def as_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def has_entries(value: Any) -> bool:
    return any(present(item) for item in as_list(value))


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

if data.get("artifact_type") != "deepretaste-run":
    fail("artifact_type must be deepretaste-run")

mode = data.get("mode")
status = data.get("status")
if mode not in VALID_MODES:
    fail("mode must be research, bootstrap, proposal, or apply")
if status not in VALID_STATUSES:
    fail("status is invalid")
if status == "RETASTE_BOOTSTRAPPED" and mode != "bootstrap":
    fail("RETASTE_BOOTSTRAPPED requires bootstrap mode")
if status == "RETASTE_APPLIED" and mode != "apply":
    fail("RETASTE_APPLIED requires apply mode")

scope = data.get("product_scope")
if not isinstance(scope, dict):
    fail("product_scope must be an object")
for field in ("scope_type", "product", "source_evidence", "confidence", "ambiguities", "apply_allowed"):
    if field not in scope:
        fail(f"product_scope missing {field}")
if not present(scope.get("product")) or str(scope.get("product")).strip().lower() in {"current product", "developer tool", "unknown"}:
    fail("product_scope.product must be explicit")
if scope.get("confidence") not in {"high", "medium", "low"}:
    fail("product_scope.confidence must be high, medium, or low")
if mode == "apply" and (scope.get("confidence") != "high" or scope.get("apply_allowed") is not True):
    fail("apply requires high-confidence scope and apply_allowed=true")
if mode == "apply" and has_entries(scope.get("ambiguities")):
    fail("apply requires no product scope ambiguities")

intent = data.get("intent_detection")
if not isinstance(intent, dict):
    fail("intent_detection must be an object")
for field in ("developer_intent", "product_intent", "route_decision", "confidence"):
    if not present(intent.get(field)):
        fail(f"intent_detection missing {field}")
if intent.get("confidence") not in {"high", "medium", "low"}:
    fail("intent_detection.confidence must be high, medium, or low")
if mode == "apply" and intent.get("confidence") != "high":
    fail("apply requires high-confidence intent detection")

taste_state = data.get("taste_state")
if not isinstance(taste_state, dict):
    fail("taste_state must be an object")
for field in ("taste_md_exists", "taste_vision_exists", "existing_kernel"):
    if field not in taste_state:
        fail(f"taste_state missing {field}")
existing_kernel = bool(taste_state.get("taste_md_exists") and taste_state.get("taste_vision_exists"))
if bool(taste_state.get("existing_kernel")) != existing_kernel:
    fail("taste_state.existing_kernel must match taste file existence")
if mode == "bootstrap" and existing_kernel:
    fail("bootstrap mode cannot run over an existing complete kernel")
if mode in {"proposal", "apply"} and not existing_kernel:
    fail("proposal/apply modes require existing taste.md and taste.vision")

routing = data.get("routing")
if not isinstance(routing, dict):
    fail("routing must be an object")
declared_route = routing.get("declared_route")
if not present(declared_route):
    fail("routing.declared_route is required")
delegated = set(str(route) for route in as_list(routing.get("delegated_routes")))
if mode == "bootstrap" and "/tastebootstrap" not in delegated:
    fail("bootstrap mode must delegate to /tastebootstrap semantics")
if mode in {"proposal", "apply"} and "/defineicp" not in delegated:
    fail("proposal/apply modes must delegate to /defineicp semantics")
if "/icpweek" in delegated and mode in {"bootstrap", "apply"}:
    fail("icpweek stress tests must not be mixed with mutation modes")

research = data.get("research")
if not isinstance(research, dict):
    fail("research must be an object")
for field in ("deepresearch_plan", "loop_log", "source_ledger", "claim_ledger", "sota_2026_policy"):
    if not present(research.get(field)):
        fail(f"research missing {field}")
if not has_entries(research.get("loop_log")):
    fail("deepresearch requires a search-read-refine loop log")
source_ledger = research.get("source_ledger")
if not isinstance(source_ledger, dict):
    fail("source_ledger must be an object")
if not has_entries(source_ledger.get("cited")):
    fail("source_ledger.cited is required")
if "reviewed_but_not_cited" not in source_ledger or "conflicts" not in source_ledger:
    fail("source_ledger must include reviewed_but_not_cited and conflicts")

sota_policy = research.get("sota_2026_policy")
if not isinstance(sota_policy, dict):
    fail("sota_2026_policy must be an object")
if SOTA_RE.search(raw):
    if sota_policy.get("sota_claims_allowed") is not True:
        fail("SOTA/research-backed language requires sota_claims_allowed=true")
    if not has_entries(sota_policy.get("current_sources")):
        fail("SOTA/research-backed language requires current_sources")
    for source in as_list(sota_policy.get("current_sources")):
        if isinstance(source, dict) and source.get("current") is not True:
            fail("current_sources entries must set current=true")

claim_ledger = as_list(research.get("claim_ledger"))
if not claim_ledger:
    fail("claim_ledger is required")
for claim in claim_ledger:
    if not isinstance(claim, dict):
        fail("claim ledger entries must be objects")
    for field in ("claim", "label", "evidence", "taste_impact"):
        if not present(claim.get(field)):
            fail(f"claim ledger entry missing {field}")
    if claim.get("label") not in VALID_LABELS:
        fail("claim ledger has invalid label")
    if claim.get("direct_taste_driver") is True and claim.get("label") not in {
        "current-source-backed",
        "stable-source-backed",
        "repo-derived",
        "user-stated",
    }:
        fail("direct taste drivers require strong claim labels")
    if claim.get("source") in {"subagent-summary", "worker-summary"} and claim.get("parent_verified") is not True:
        fail("worker/subagent summaries require parent_verified=true")

parallel = data.get("parallel_decision")
if not isinstance(parallel, dict):
    fail("parallel_decision must be an object")
for field in ("ceiling", "effective_budget", "distinct_lenses", "supervisor_capacity", "verifier_capacity", "why_not_more", "substrate"):
    if field not in parallel or not present(parallel.get(field)):
        fail(f"parallel_decision missing {field}")
ceiling = int(parallel.get("ceiling"))
effective = int(parallel.get("effective_budget"))
lens_count = len(as_list(parallel.get("distinct_lenses")))
supervisor_capacity = int(parallel.get("supervisor_capacity"))
verifier_capacity = int(parallel.get("verifier_capacity"))
if effective < 1:
    fail("effective_budget must be at least 1")
if effective > min(ceiling, lens_count, supervisor_capacity, verifier_capacity):
    fail("effective_budget exceeds ceiling, lens count, supervisor capacity, or verifier capacity")
if effective == ceiling and lens_count < ceiling and not present(parallel.get("why_not_more")):
    fail("parallel budget must explain why not more lanes")
if parallel.get("agent_teams_available") is False and parallel.get("substrate") == "agent-teams":
    fail("agent teams require availability and explicit opt-in")
if parallel.get("substrate") == "hive":
    hive = data.get("hive")
    if not isinstance(hive, dict):
        fail("hive substrate requires hive object")
    for field in ("queen", "role_map", "blackboard_claims", "dissent_log", "synthesis", "verification"):
        if not present(hive.get(field)):
            fail(f"hive object missing {field}")

icp = data.get("icp")
if not isinstance(icp, dict):
    fail("icp must be an object")
primary = icp.get("primary")
if not isinstance(primary, dict):
    fail("icp.primary must be an object")
for field in (
    "segment",
    "buyer_user_distinction",
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

mutation = data.get("taste_mutation")
if not isinstance(mutation, dict):
    fail("taste_mutation must be an object")
applied = mutation.get("applied") is True
if mode in {"research", "proposal"} and applied:
    fail("research/proposal modes must not mutate taste files")
if status in {"RETASTE_RESEARCHED", "RETASTE_PROPOSED", "RETASTE_DRAFTED_LOW_CONFIDENCE", "RETASTE_WAITING_FOR_APPLY_APPROVAL"} and applied:
    fail("draft/proposal statuses must not mutate taste files")

if mode == "bootstrap":
    kernel = data.get("kernel_output")
    if not isinstance(kernel, dict):
        fail("bootstrap mode requires kernel_output")
    for field in ("taste_md_created", "taste_vision_created", "icp_artifact_path", "tastebootstrap_semantics", "kernel_questions_answered"):
        if field not in kernel or not present(kernel.get(field)):
            fail(f"kernel_output missing {field}")
    if kernel.get("tastebootstrap_semantics") is not True:
        fail("bootstrap must use /tastebootstrap semantics")
    if int(kernel.get("kernel_questions_answered")) < 10:
        fail("bootstrap requires 10 answered kernel questions")
    if not applied or mutation.get("mutation_kind") != "bootstrap" or mutation.get("authority") != "/tastebootstrap":
        fail("bootstrap status requires taste_mutation applied by /tastebootstrap")

if mode in {"proposal", "apply"}:
    proposal = data.get("taste_evolution")
    if not isinstance(proposal, dict):
        fail("proposal/apply modes require taste_evolution")
    for field in ("taste_md_changes", "taste_vision_changes", "changed_line_trace", "protected_kernel_checklist", "what_not_to_change", "defineicp_semantics"):
        if not present(proposal.get(field)):
            fail(f"taste_evolution missing {field}")
    if proposal.get("defineicp_semantics") is not True:
        fail("existing-kernel retaste must use /defineicp semantics")
    checklist = proposal.get("protected_kernel_checklist", {})
    if not isinstance(checklist, dict):
        fail("protected_kernel_checklist must be an object")
    for invariant in PROTECTED_KERNEL:
        if checklist.get(invariant) not in {True, "preserved", "explicitly-approved-change"}:
            fail(f"protected kernel invariant not preserved: {invariant}")

approval = data.get("approval", {})
if mode == "apply":
    if not isinstance(approval, dict):
        fail("apply requires approval object")
    if approval.get("explicit") is not True:
        fail("apply requires explicit approval")
    if not present(approval.get("approved_proposal_id")):
        fail("apply requires approved_proposal_id")
    text = str(approval.get("approval_text", "")).strip().lower()
    if not text or text in VAGUE_APPROVALS:
        fail("apply approval text is too vague")
    approved_files = set(str(item) for item in as_list(approval.get("approved_files")))
    for required in {"taste.md", "taste.vision", "icp artifact"}:
        if required not in approved_files:
            fail(f"apply approval must name {required}")
    if not applied or mutation.get("mutation_kind") != "apply" or mutation.get("authority") != "/defineicp":
        fail("apply mode requires taste_mutation applied by /defineicp")
    for field in ("backup_paths", "pre_change_hashes", "post_change_hashes", "rollback_plan"):
        if not present(mutation.get(field)):
            fail(f"apply mutation missing {field}")

verification = data.get("verification")
if not isinstance(verification, dict):
    fail("verification must be an object")
if verification.get("status") not in {"pass", "pass_with_notes", "fail", "blocked"}:
    fail("verification status is invalid")
if not present(verification.get("commands")):
    fail("verification command evidence is required")
if status in {"RETASTE_BOOTSTRAPPED", "RETASTE_APPLIED"} and verification.get("status") not in {"pass", "pass_with_notes"}:
    fail("mutation statuses require passing verification")

introspection = data.get("introspection")
if not isinstance(introspection, dict):
    fail("introspection must be an object")
for field in ("likely_mistakes", "evidence_checked", "confidence"):
    if not present(introspection.get(field)):
        fail(f"introspection missing {field}")
if status in {"RETASTE_BOOTSTRAPPED", "RETASTE_APPLIED"} and introspection.get("unresolved_blockers"):
    fail("positive mutation closeout cannot have unresolved introspection blockers")
PY
}

run_fixture_checks() {
  require_file "$FIXTURE_DIR/green/valid-bootstrap.json"
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

  [ "$green_count" -ge 3 ] || fail "expected at least 3 green deepretaste fixtures"
  [ "$red_count" -ge 8 ] || fail "expected at least 8 red deepretaste fixtures"
}

case "${1:-}" in
  "--fixtures")
    run_static_contract_checks
    run_fixture_checks
    echo "[PASS] /deepretaste intent-to-ICP-to-taste smoke passed"
    ;;
  "--artifact")
    [ -n "${2:-}" ] || fail "--artifact requires a path"
    validate_artifact "$2"
    echo "[PASS] deepretaste artifact valid: $2"
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
