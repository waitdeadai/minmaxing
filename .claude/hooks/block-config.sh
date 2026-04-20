#!/bin/bash
# PreToolUse hook: block modification of config files

FILE=$(jq -r '.tool_input.file_path // empty' < /dev/stdin)

if [ -z "$FILE" ]; then
  exit 0
fi

# Protected config files
PROTECTED_REGEX='(\.eslintrc|\.prettierrc|\.prettierrc\.|tsconfig\.json|\.ruff\.toml|\.ruff|package\.json)$'

if echo "$FILE" | grep -qE "$PROTECTED_REGEX"; then
  echo "BLOCKED: Cannot modify protected config file: $FILE" >&2
  echo "To edit this file, use human approval mode or edit manually." >&2
  # Exit code 2 = blocking error
  exit 2
fi

exit 0
