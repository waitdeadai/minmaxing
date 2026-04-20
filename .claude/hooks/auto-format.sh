#!/bin/bash
# PostToolUse hook: auto-format after file edits

FILE=$(jq -r '.tool_input.file_path // empty' < /dev/stdin)

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  exit 0
fi

# Get file extension
EXT="${FILE##*.}"

# Format based on file type
case "$EXT" in
  js|ts|jsx|tsx)
    npx prettier --write "$FILE" 2>/dev/null || true
    ;;
  py)
    npx prettier --write "$FILE" 2>/dev/null || python3 -m black "$FILE" 2>/dev/null || true
    ;;
  sh|bash)
    npx prettier --write "$FILE" 2>/dev/null || true
    ;;
  json|md|yml|yaml)
    npx prettier --write "$FILE" 2>/dev/null || true
    ;;
esac

exit 0
