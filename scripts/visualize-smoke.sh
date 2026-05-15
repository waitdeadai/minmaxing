#!/bin/bash
# Smoke the /visualize and /visualizeworkflow contracts without secrets or image providers.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/visualize-html"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/visualize-smoke.sh
  bash scripts/visualize-smoke.sh --fixtures
  bash scripts/visualize-smoke.sh --manifest PATH

Validates the /visualize and /visualizeworkflow contracts plus HTML companion
artifact fixture packages.
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

VISUALIZE=".claude/skills/visualize/SKILL.md"
VISUALIZE_WORKFLOW=".claude/skills/visualizeworkflow/SKILL.md"
RULES=".claude/rules/visualization.rules.md"
WORKFLOW=".claude/skills/workflow/SKILL.md"

run_static_contract_checks() {
  require_file "$VISUALIZE"
  require_file "$VISUALIZE_WORKFLOW"
  require_file "$RULES"
  require_file "$WORKFLOW"

  SKILL_COUNT="$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')"
  [ "$SKILL_COUNT" -ge 43 ] || fail "expected at least 43 skills, found $SKILL_COUNT"

  for pattern in \
    "taste.md" \
    "taste.vision" \
    "SPEC.md" \
    ".taste/visualizations" \
    "image generation" \
    "no-image fallback" \
    "Understanding Card" \
    "no-secret" \
    "Never claim an image was generated when it was not" \
    "HTML" \
    "canonical source files"; do
    require_grep "$pattern" "$VISUALIZE"
  done

  for pattern in \
    "WAITING_FOR_VISUAL_APPROVAL" \
    "--continue" \
    "--revise" \
    "draft-SPEC.md" \
    "approval.json" \
    "Plain \`/workflow\` remains autonomous" \
    "Never implement before \`--continue\`" \
    "index.html" \
    "HTML artifacts are companion review surfaces"; do
    require_grep "$pattern" "$VISUALIZE_WORKFLOW"
  done

  for pattern in \
    "Plain \`/workflow\` remains autonomous" \
    "must not be forced into a fake UI mockup" \
    "no image artifact path" \
    "WAITING_FOR_VISUAL_APPROVAL" \
    ".taste/visualizations/" \
    "HTML Companion Artifacts" \
    "must not be the only place where requirements" \
    "remote scripts" \
    "secret-like material"; do
    require_grep "$pattern" "$RULES"
  done

  require_grep "Keep plain \`/workflow\` autonomous" "$WORKFLOW"
  require_grep "route that request to \`/visualizeworkflow\`" "$WORKFLOW"
  require_grep "/visualizeworkflow" "$WORKFLOW"
  require_not_grep "## Visualization Gate" "$WORKFLOW"

  for file in README.md CLAUDE.md AGENTS.md scripts/start-session.sh; do
    require_grep "/visualize" "$file"
    require_grep "/visualizeworkflow" "$file"
  done

  require_grep "43 skills" README.md
  require_grep "Expected 43 skills" scripts/start-session.sh

  if ! git check-ignore -q .taste/visualizations/probe/visualization.md; then
    fail ".taste/visualizations is not ignored by git"
  fi
}

validate_manifest() {
  local manifest="$1"
  python3 - "$ROOT_DIR" "$manifest" <<'PY'
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(sys.argv[1]).resolve()
MANIFEST = pathlib.Path(sys.argv[2]).resolve()
SECRET_RE = re.compile(
    r"(sk-[A-Za-z0-9_-]{12,}|AKIA[0-9A-Z]{12,}|BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY|"
    r"ANTHROPIC_API_KEY|OPENAI_API_KEY|MINIMAX_API_KEY|CLAUDE_CODE_OAUTH_TOKEN|password\s*=|token\s*=)",
    re.I,
)
REMOTE_RE = re.compile(
    r"<script[^>]+\bsrc\s*=|<link[^>]+\bhref\s*=|https?://|//[^/]",
    re.I,
)
ABS_PATH_RE = re.compile(r"(/home/|/Users/|/etc/|file://|[A-Za-z]:\\)")


def fail(message: str) -> None:
    print(f"[visualize-smoke] {MANIFEST.relative_to(ROOT)}: {message}", file=sys.stderr)
    raise SystemExit(1)


def present(value) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value.strip()) and value.strip().lower() not in {"none", "n/a", "null", "todo", "tbd"}
    if isinstance(value, (list, dict)):
        return bool(value)
    return True


def repo_rel(raw: str, field: str) -> str:
    if not present(raw):
        fail(f"missing {field}")
    text = str(raw).replace("\\", "/").strip()
    if pathlib.PurePosixPath(text).is_absolute() or pathlib.PureWindowsPath(text).is_absolute():
        fail(f"{field} must be repo-relative")
    if ".." in pathlib.PurePosixPath(text).parts:
        fail(f"{field} must not contain ..")
    return text.strip("/")


def fixture_path(package_dir: pathlib.Path, raw: str, field: str) -> pathlib.Path:
    rel = repo_rel(raw, field)
    path = (package_dir / rel).resolve()
    try:
        path.relative_to(package_dir)
    except ValueError:
        fail(f"{field} must stay inside fixture package")
    return path


try:
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
except Exception as exc:
    fail(f"invalid manifest JSON: {exc}")

if not isinstance(data, dict):
    fail("manifest must be a JSON object")

if data.get("artifact_type") != "visualization-package":
    fail("artifact_type must be visualization-package")
if data.get("mode") != "HTML":
    fail("mode must be HTML")
if data.get("status") != "WAITING_FOR_VISUAL_APPROVAL":
    fail("status must be WAITING_FOR_VISUAL_APPROVAL")

run_dir = repo_rel(data.get("run_dir"), "run_dir")
if not run_dir.startswith(".taste/visualizations/"):
    fail("run_dir must be under .taste/visualizations/")

if "IMPLEMENTED_VERIFIED" in json.dumps(data) or data.get("implementation_started") is True:
    fail("HTML visualization fixture must not start implementation")
if data.get("root_spec_promoted") is True:
    fail("HTML visualization fixture must not promote root SPEC")

text_blob = json.dumps(data, sort_keys=True)
if SECRET_RE.search(text_blob):
    fail("secret-like text found in manifest")

artifacts = data.get("artifacts")
if not isinstance(artifacts, dict):
    fail("missing artifacts object")

package_dir = MANIFEST.parent
required_artifacts = {
    "html": "index.html",
    "visualization": "visualization.md",
    "approval": "approval.json",
}
for key, default_name in required_artifacts.items():
    path = fixture_path(package_dir, artifacts.get(key) or default_name, f"artifacts.{key}")
    if not path.is_file():
        fail(f"artifact missing: {key}")

canonical = data.get("canonical_sources")
if not isinstance(canonical, list) or {"visualization.md", "approval.json"} - {str(item) for item in canonical}:
    fail("canonical_sources must include visualization.md and approval.json")

policy = data.get("html_policy")
if not isinstance(policy, dict):
    fail("missing html_policy")
if policy.get("canonical_contract") != "markdown-json":
    fail("html_policy.canonical_contract must be markdown-json")
for field in ["self_contained", "no_remote_assets", "no_secret_material"]:
    if policy.get(field) is not True:
        fail(f"html_policy.{field} must be true")

html_path = fixture_path(package_dir, artifacts.get("html"), "artifacts.html")
html = html_path.read_text(encoding="utf-8", errors="replace")
if SECRET_RE.search(html):
    fail("secret-like text found in HTML")
if REMOTE_RE.search(html):
    fail("HTML must not include remote scripts, styles, URLs, or protocol-relative assets")
if ABS_PATH_RE.search(html):
    fail("HTML must not include absolute local paths")
if "<!doctype html>" not in html.lower():
    fail("HTML missing doctype")
if "<html" not in html.lower() or " lang=" not in html.lower():
    fail("HTML missing html lang")
if "<title>" not in html.lower() or "</title>" not in html.lower():
    fail("HTML missing title")
if "visualization.md" not in html or "approval.json" not in html:
    fail("HTML must visibly reference canonical source files")
if "HTML is a companion" not in html:
    fail("HTML must state companion-not-canonical semantics")

approval_path = fixture_path(package_dir, artifacts.get("approval"), "artifacts.approval")
try:
    approval = json.loads(approval_path.read_text(encoding="utf-8"))
except Exception as exc:
    fail(f"invalid approval JSON: {exc}")
if approval.get("status") != "WAITING_FOR_VISUAL_APPROVAL":
    fail("approval.json must wait for visual approval")
if approval.get("mode") != "HTML":
    fail("approval.json mode must be HTML")
if approval.get("implementation_started") is not False:
    fail("approval.json implementation_started must be false")
if approval.get("root_spec_promoted") is not False:
    fail("approval.json root_spec_promoted must be false")

gates = data.get("quality_gates")
if not isinstance(gates, dict):
    fail("missing quality_gates")
for gate in ["privacy_no_secret", "static_html", "canonical_sources", "approval_state"]:
    if gates.get(gate) != "pass":
        fail(f"quality gate must pass: {gate}")
if data.get("verdict") != "pass":
    fail("verdict must be pass")
if not present(data.get("commands_run")):
    fail("manifest missing command evidence")

print("[PASS] visualization HTML manifest validation passed")
PY
}

run_fixtures() {
  run_static_contract_checks
  [ -d "$FIXTURE_DIR" ] || fail "missing fixture directory: $FIXTURE_DIR"

  local green_count=0
  local red_count=0
  local failures=0

  while IFS= read -r manifest; do
    [ -n "$manifest" ] || continue
    if validate_manifest "$manifest" >/dev/null; then
      green_count=$((green_count+1))
    else
      echo "[visualize-smoke] green fixture failed: $manifest" >&2
      failures=$((failures+1))
    fi
  done < <(find "$FIXTURE_DIR/green" -name "manifest.json" -type f 2>/dev/null | sort)

  while IFS= read -r manifest; do
    [ -n "$manifest" ] || continue
    if validate_manifest "$manifest" >/dev/null 2>&1; then
      echo "[visualize-smoke] red fixture unexpectedly passed: $manifest" >&2
      failures=$((failures+1))
    else
      red_count=$((red_count+1))
    fi
  done < <(find "$FIXTURE_DIR/red" -name "manifest.json" -type f 2>/dev/null | sort)

  [ "$green_count" -ge 1 ] || fail "expected at least one green visualize HTML fixture"
  [ "$red_count" -ge 5 ] || fail "expected at least five red visualize HTML fixtures"
  [ "$failures" -eq 0 ] || fail "visualize HTML fixtures failed: $failures"

  echo "[PASS] /visualize and /visualizeworkflow contract smoke test passed"
  echo "[PASS] visualize HTML fixtures passed (${green_count} green, ${red_count} red)"
}

case "${1:-}" in
  ""|"--fixtures")
    [ "$#" -le 1 ] || { usage; exit 2; }
    run_fixtures
    ;;
  "--manifest")
    [ "$#" -eq 2 ] || { usage; exit 2; }
    run_static_contract_checks
    validate_manifest "$2"
    ;;
  "-h"|"--help")
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
