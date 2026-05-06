# SPEC: Direct MiniMax Token Setup And Safe Import/Update

## Problem Statement

The installer supports direct MiniMax Token Plan key setup, but there are two
different operator jobs that must be clearly separated:

- clean/new-folder install, where minmaxing can scaffold the folder;
- existing-project import/update, where minmaxing must not overwrite app files.

The README should make the split obvious, and the updater path must copy only
harness-owned files while preserving project files and secrets.

## Success Criteria

- [x] `setup.sh` accepts `MINIMAX_TOKEN_KEY=...` as a first-class MiniMax token
  input.
- [x] `setup.sh` accepts `TOKEN_KEY=...` as a short operator alias when
  `MINIMAX_TOKEN_KEY` is not set.
- [x] CLI `--minimax-key` and `--minimax-key-file` continue to work.
- [x] README shows the clean/new-folder setup command:
  `MINIMAX_TOKEN_KEY='YOUR_TOKEN_PLAN_KEY' bash -lc 'curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --mode opusworkflow && claude'`.
- [x] README shows a separate existing-project/updater command:
  `MINIMAX_TOKEN_KEY='YOUR_TOKEN_PLAN_KEY' bash -lc 'curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --mode opusworkflow --import-existing && claude'`.
- [x] Clean install refuses to copy the template into a non-empty non-git
  folder or an existing non-minmaxing git project.
- [x] Existing-project/updater mode copies or updates harness-owned files only.
- [x] Existing-project/updater mode preserves `.env`, `README.md`, `SPEC.md`,
  `taste.md`, `taste.vision`, `.git`, and app/package files.
- [x] Existing-project/updater mode records managed hashes in
  `.minimaxing/import-manifest.tsv` so future runs update files it previously
  installed but skip user-modified conflicts.
- [x] README removes duplicate "recommended" install variants and legacy MiniMax
  key install examples.
- [x] README keeps a concise warning that inline/env token commands can land in
  shell history and points advanced operators to `bash setup.sh --help` instead
  of listing alternate recommended commands.
- [x] `setup.sh` help/no-key closeout prints the clean/new-folder and
  existing-project/updater commands with different labels.
- [x] Static smoke gates validate the env-var route.
- [x] No real token, `.env`, or ignored local settings file is read, printed, or
  committed.

## Local Research Brief

- `setup.sh` initializes `API_KEY` from env aliases, the legacy positional arg,
  `--minimax-key`, or `--minimax-key-file`.
- README already shows the direct `--minimax-key` path but not an env-var token
  assignment, which is the more natural copy-paste shape for "one command".
- The clean install path previously copied the cloned template into non-git
  folders with broad `cp -r`; that is acceptable only for empty folders.
- Existing git folders were treated as already-minmaxing directories, which is
  wrong for normal app repos and made import/update unclear.
- `scripts/opusworkflow-smoke.sh` and `scripts/test-harness.sh` assert setup
  affordances and should include the import/update route.

## Plan

1. Initialize `API_KEY` from `MINIMAX_TOKEN_KEY` or `TOKEN_KEY`.
2. Add `--import-existing` as a safe import/update route with a managed-file
   manifest.
3. Collapse README setup, Windows notes, fresh-folder, and
   existing-folder instructions onto labeled clean vs existing commands.
4. Update setup help/no-key output so the operator path is explicit by folder
   type.
5. Extend static gates for both routes.
6. Run static verification and push.

## Agent-Native Estimate

- Estimate type: agent-native.
- Critical path: safe import/update mode -> README examples -> smoke/test
  patterns -> static gates -> commit/push.
- Agent wall-clock: likely 45-75 minutes.
- Agent-hours: 1-2.
- Human touch time later: none.
- Confidence: high; narrow installer/docs/test update.

## Introspection: Pre-Implementation

- Likely mistake: making the inline env route look safer than it is. Guard:
  README must explicitly mention shell history risk and point advanced operators
  to `bash setup.sh --help` without making alternate commands look recommended.
- Likely mistake: breaking existing `--minimax-key` users. Guard: leave the
  current arg parser intact and only use env vars as defaults.
- Likely mistake: import overwrites project files. Guard: `--import-existing`
  uses a manifest, skips non-managed conflicts, and never copies `README.md`,
  `SPEC.md`, `taste.md`, `taste.vision`, `.git`, or `.env`.
- Likely mistake: accidentally committing a real token. Guard: use placeholder
  strings only and do not inspect secret files.

## Verified 2026-05-06

- `bash scripts/harness-capability-map.sh --write`: refreshed generated map
  docs/JSON after README/script changes.
- `bash -n setup.sh scripts/opusworkflow-smoke.sh scripts/test-harness.sh scripts/release-check.sh`: pass.
- `bash scripts/opusworkflow-smoke.sh`: pass.
- `git diff --check`: pass.
- `env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`: pass (`137 passed`,
  `0 failed`).
- `bash scripts/harness-eval.sh --json`: pass (`22 tasks`, `19 gates`,
  `0 mismatches`).
- `bash scripts/release-check.sh --static-only`: pass (`137 passed`,
  `0 failed`; static-only release gate passed).
- Setup clarity update: README separates the clean/new-folder command from the
  existing-project/updater command, setup no-key output prints both labels, and
  the static gates expect both commands.
- Safe import/update update:
  - `bash -n setup.sh scripts/opusworkflow-smoke.sh scripts/test-harness.sh scripts/release-check.sh`: pass.
  - `bash scripts/opusworkflow-smoke.sh`: pass.
  - Temp non-empty non-git folder test: clean install exits `2` and preserves
    app file.
  - Temp existing non-minmaxing git repo test: clean install exits `2` and
    preserves `README.md`.
  - Temp `--import-existing` test with fake `uvx` and temp `HOME`: preserves
    `README.md` and `.env`, imports `.claude/skills/workflow/SKILL.md`, writes
    `.minimaxing/import-manifest.tsv`, and appends the minmaxing `.gitignore`
    block.

## Introspection: Pre-Closeout

- Likely mistake: encouraging unsafe key exposure. Mitigation: README shows the
  direct env route but explicitly warns it can land in shell history; hidden
  prompt and key-file routes remain available only as advanced setup help.
- Likely mistake: hidden regression for existing setup paths. Mitigation:
  `--minimax-key`, `--minimax-key-file`, and `--prompt-minimax-key` remain in
  setup help and smoke assertions.
- Likely mistake: import/update overwrites real app files. Mitigation: temp
  tests covered non-empty clean-install refusal, existing git clean-install
  refusal, and `--import-existing` preservation of `README.md` and `.env`.
- Likely mistake: over-testing by using a real key. Mitigation: verification
  stayed static/no-secret and used placeholder strings only.
