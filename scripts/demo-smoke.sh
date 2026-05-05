#!/bin/bash
# Validate the /demo recorded-demo contract without secrets by default.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/.taste/fixtures/demo-smoke"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/demo-smoke.sh --fixtures
  bash scripts/demo-smoke.sh --manifest PATH
  bash scripts/demo-smoke.sh --runtime PATH

--fixtures runs deterministic no-network fixtures.
--manifest validates a sanitized demo manifest statically.
--runtime also checks local media files with ffprobe/ffmpeg when available.
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
  local skill="$ROOT_DIR/.claude/skills/demo/SKILL.md"
  require_file "$skill"

  for pattern in \
    "# /demo" \
    "page.screencast" \
    "gpt-4o-mini-tts" \
    "WebVTT" \
    "FFmpeg" \
    "WCAG" \
    "English" \
    "neutral Spanish" \
    "es-419" \
    "ephemeral browser context" \
    "no persistent user profile" \
    "no imported cookies" \
    "no saved \`storageState\`" \
    ".taste/demo-recordings/{run_id}/" \
    "synthetic audio" \
    "WAITING_FOR_VOICEOVER_APPROVAL" \
    "BLOCKED_NO_TTS_PROVIDER" \
    "solo-fast" \
    "team-safe" \
    "ci-static" \
    "ci-runtime" \
    "git status --short" \
    "nonblank" \
    "non-silent"; do
    require_grep "$pattern" "$skill"
  done

  for forbidden in \
    "source .env" \
    "cat .env" \
    "dotenv" \
    "printenv" \
    "env >" \
    "--user-data-dir=$HOME" \
    "~/.config/google-chrome" \
    "context.addCookies"; do
    require_not_grep "$forbidden" "$skill"
  done

  local ignored_path
  for ignored_path in \
    .taste/demo-recordings/sample.webm \
    demo-recordings/sample.mp4 \
    recordings/sample.wav \
    sample.webm \
    sample.mp4 \
    sample.wav \
    sample.trace.zip \
    sample.har; do
    git check-ignore -q "$ignored_path" || fail "demo media output is not ignored by git: $ignored_path"
  done
}

validate_manifest() {
  local manifest="$1"
  local runtime="${2:-0}"
  python3 - "$ROOT_DIR" "$manifest" "$runtime" <<'PY'
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(sys.argv[1]).resolve()
MANIFEST = pathlib.Path(sys.argv[2])
RUNTIME = sys.argv[3] == "1"

SECRET_RE = re.compile(
    r"(sk-[A-Za-z0-9_-]{20,}|OPENAI_API_KEY|ANTHROPIC_API_KEY|"
    r"password\s*[:=]|secret\s*[:=]|token\s*[:=]|BEGIN [A-Z ]*PRIVATE KEY)",
    re.IGNORECASE,
)

PASS_STATUSES = {"pass", "pass_with_notes"}
VALID_STATUSES = PASS_STATUSES | {"fail", "blocked"}
REQUIRED_GATES = {
    "route_load",
    "workflow_truth",
    "operator_comprehension",
    "accessibility",
    "media",
    "safety",
}


def rel(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def fail(message: str) -> None:
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


def present(value) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value.strip()) and value.strip().lower() not in {"none", "n/a", "null", "missing", "todo", "tbd"}
    if isinstance(value, (list, dict, tuple, set)):
        return bool(value)
    return True


def as_list(value):
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def ensure_under_ignored_run_dir(raw: str) -> pathlib.Path:
    if not present(raw):
        fail("manifest missing run_dir")
    if pathlib.PurePosixPath(str(raw)).is_absolute() or pathlib.PureWindowsPath(str(raw)).is_absolute():
        fail("run_dir must be repo-relative")
    normalized = str(raw).replace("\\", "/").strip("/")
    if ".." in pathlib.PurePosixPath(normalized).parts:
        fail("run_dir must not contain ..")
    if not normalized.startswith(".taste/demo-recordings/"):
        fail("run_dir must be under .taste/demo-recordings/")
    return ROOT / normalized


def resolve_artifact(run_dir: pathlib.Path, raw: str, field: str) -> pathlib.Path:
    if not present(raw):
        fail(f"manifest missing artifact path: {field}")
    raw_text = str(raw).replace("\\", "/")
    if pathlib.PurePosixPath(raw_text).is_absolute() or pathlib.PureWindowsPath(raw_text).is_absolute():
        fail(f"{field} must be repo-relative to run_dir, not absolute")
    if ".." in pathlib.PurePosixPath(raw_text).parts:
        fail(f"{field} must not contain ..")
    return run_dir / raw_text


def ffprobe_duration(path: pathlib.Path) -> float:
    output = subprocess.check_output(
        [
            "ffprobe",
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            str(path),
        ],
        text=True,
        stderr=subprocess.STDOUT,
    ).strip()
    return float(output)


def ffmpeg_max_volume(path: pathlib.Path) -> float:
    result = subprocess.run(
        [
            "ffmpeg",
            "-hide_banner",
            "-v",
            "info",
            "-i",
            str(path),
            "-af",
            "volumedetect",
            "-vn",
            "-f",
            "null",
            "-",
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        fail(f"ffmpeg volumedetect failed for {rel(path)}")
    match = re.search(r"max_volume:\s*(-?(?:inf|\d+(?:\.\d+)?))\s*dB", result.stderr)
    if not match or match.group(1) == "-inf":
        return -999.0
    return float(match.group(1))


def scan_text(label: str, text: str) -> None:
    if SECRET_RE.search(text):
        fail(f"obvious secret-like text found in {label}")


try:
    data = json.loads(read_text(MANIFEST))
except Exception as exc:
    fail(f"invalid manifest JSON: {exc}")

if not isinstance(data, dict):
    fail("manifest must be a JSON object")

if data.get("artifact_type") != "demo-recording":
    fail("artifact_type must be demo-recording")
if not present(data.get("demo_id")):
    fail("manifest missing demo_id")

run_dir = ensure_under_ignored_run_dir(data.get("run_dir"))
scan_text("manifest", json.dumps(data, sort_keys=True))

target = data.get("target")
if not isinstance(target, dict):
    fail("manifest missing target object")
for field in ["route_or_path", "audience", "objective"]:
    if not present(target.get(field)):
        fail(f"target missing {field}")

languages = data.get("languages")
if not isinstance(languages, list):
    fail("languages must be a list")
language_codes = {str(item.get("code", "")) for item in languages if isinstance(item, dict)}
if "en" not in language_codes:
    fail("manifest missing English language artifact")
if not ({"es", "es-419"} & language_codes):
    fail("manifest missing Spanish language artifact")

for item in languages:
    if not isinstance(item, dict):
        fail("language entries must be objects")
    for field in ["code", "script", "captions"]:
        if not present(item.get(field)):
            fail(f"language entry missing {field}")
    captions_path = resolve_artifact(run_dir, item["captions"], f"captions[{item.get('code')}]")
    if RUNTIME:
        if not captions_path.is_file():
            fail(f"caption file missing: {rel(captions_path)}")
        text = read_text(captions_path)
        scan_text(rel(captions_path), text)
        if not text.startswith("WEBVTT"):
            fail(f"caption file must start with WEBVTT: {rel(captions_path)}")
        if "-->" not in text:
            fail(f"caption file lacks cue timings: {rel(captions_path)}")
        script_path = resolve_artifact(run_dir, item["script"], f"script[{item.get('code')}]")
        if not script_path.is_file():
            fail(f"script file missing: {rel(script_path)}")
        scan_text(rel(script_path), read_text(script_path))

voiceover = data.get("voiceover")
tts_disclosure = data.get("tts_disclosure")
if voiceover:
    if not isinstance(voiceover, dict):
        fail("voiceover must be an object")
    for field in ["tts_provider", "tts_model_or_voice", "generation_time", "input_script_path", "voice_kind"]:
        if not present(voiceover.get(field)):
            fail(f"voiceover missing {field}")
    if not isinstance(tts_disclosure, dict):
        fail("voiceover requires tts_disclosure")
    if tts_disclosure.get("synthetic_audio") is not True:
        fail("tts_disclosure.synthetic_audio must be true")
    if not present(tts_disclosure.get("end_user_disclosure")):
        fail("tts_disclosure missing end_user_disclosure")

artifacts = data.get("artifacts")
if not isinstance(artifacts, dict):
    fail("manifest missing artifacts object")
video_path = resolve_artifact(run_dir, artifacts.get("video"), "artifacts.video")
audio_paths = [resolve_artifact(run_dir, item, "artifacts.audio") for item in as_list(artifacts.get("audio"))]
caption_paths = [resolve_artifact(run_dir, item, "artifacts.captions") for item in as_list(artifacts.get("captions"))]
if len(caption_paths) < 2:
    fail("artifacts.captions must include English and Spanish sidecars")

quality_gates = data.get("quality_gates")
if not isinstance(quality_gates, dict):
    fail("manifest missing quality_gates")
missing_gates = sorted(REQUIRED_GATES - set(quality_gates))
if missing_gates:
    fail("manifest missing quality gates: " + ", ".join(missing_gates))
for gate, status in quality_gates.items():
    if str(status) not in VALID_STATUSES:
        fail(f"invalid gate status for {gate}: {status}")
if str(quality_gates.get("safety")) not in PASS_STATUSES:
    fail("safety gate must pass before closeout")

retention = data.get("retention")
if not isinstance(retention, dict):
    fail("manifest missing retention object")
for field in ["created_at", "expires_at", "retention_policy", "cleanup_command"]:
    if not present(retention.get(field)):
        fail(f"retention missing {field}")
if not str(retention["cleanup_command"]).startswith("rm -rf .taste/demo-recordings/"):
    fail("cleanup_command must target .taste/demo-recordings/")

if not present(data.get("commands_run")):
    fail("manifest missing command evidence")

verdict = str(data.get("verdict", ""))
if verdict not in VALID_STATUSES:
    fail("invalid verdict")
if verdict in PASS_STATUSES:
    for gate, status in quality_gates.items():
        if str(status) not in PASS_STATUSES:
            fail(f"positive verdict with non-passing gate: {gate}")

if RUNTIME:
    if not video_path.is_file() or video_path.stat().st_size < 1024:
        fail(f"video missing or too small: {rel(video_path)}")
    if not audio_paths:
        fail("runtime manifest requires at least one audio artifact")
    for audio_path in audio_paths:
        if not audio_path.is_file() or audio_path.stat().st_size < 256:
            fail(f"audio missing or too small: {rel(audio_path)}")

    try:
        video_duration = ffprobe_duration(video_path)
    except Exception as exc:
        fail(f"ffprobe could not read video duration: {exc}")
    if video_duration <= 0.5:
        fail("video duration too short")

    for audio_path in audio_paths:
        try:
            audio_duration = ffprobe_duration(audio_path)
        except Exception as exc:
            fail(f"ffprobe could not read audio duration for {rel(audio_path)}: {exc}")
        if audio_duration <= 0.2:
            fail(f"audio duration too short: {rel(audio_path)}")
        max_volume = ffmpeg_max_volume(audio_path)
        if max_volume <= -60:
            fail(f"audio is effectively silent: {rel(audio_path)} max_volume={max_volume}dB")

print("[PASS] demo manifest validation passed")
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
    if validate_manifest "$manifest" 0 >/dev/null; then
      green_count=$((green_count+1))
    else
      echo "[demo-smoke] green fixture failed: $manifest" >&2
      failures=$((failures+1))
    fi
  done < <(find "$FIXTURE_DIR/green" -name "manifest.json" -type f 2>/dev/null | sort)

  while IFS= read -r manifest; do
    [ -n "$manifest" ] || continue
    if validate_manifest "$manifest" 0 >/dev/null 2>&1; then
      echo "[demo-smoke] red fixture unexpectedly passed: $manifest" >&2
      failures=$((failures+1))
    else
      red_count=$((red_count+1))
    fi
  done < <(find "$FIXTURE_DIR/red" -name "manifest.json" -type f 2>/dev/null | sort)

  [ "$green_count" -ge 1 ] || fail "expected at least one green demo fixture"
  [ "$red_count" -ge 4 ] || fail "expected at least four red demo fixtures"
  [ "$failures" -eq 0 ] || fail "demo fixtures failed: $failures"

  echo "[PASS] demo smoke fixtures passed (${green_count} green, ${red_count} red)"
}

case "${1:-}" in
  "--fixtures")
    [ "$#" -eq 1 ] || { usage; exit 2; }
    run_fixtures
    ;;
  "--manifest")
    [ "$#" -eq 2 ] || { usage; exit 2; }
    run_static_contract_checks
    validate_manifest "$2" 0
    ;;
  "--runtime")
    [ "$#" -eq 2 ] || { usage; exit 2; }
    run_static_contract_checks
    validate_manifest "$2" 1
    ;;
  "-h"|"--help")
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
