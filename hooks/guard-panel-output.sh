#!/usr/bin/env bash
# Hook: PreToolUse — Block direct Write/Edit to active figure output dirs
# Matcher: Write|Edit
# Purpose: Active panel outputs (output/panels/, output/assembled/) must only
#          be populated via figure_gate.py promote. Any direct write is blocked.
#
# stdin: JSON { tool_name, tool_input: { file_path, ... }, ... }
# exit 2 = block the tool call

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -n "$FILE_PATH" ] || exit 0

# Normalize to absolute path for matching
ABS_PATH=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

# Protected directories — only figure_gate.py promote may write here
PROTECTED_PATTERNS=(
  "v4_port_current/output/panels/"
  "v4_port_current/output/assembled/"
)

for PATTERN in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$ABS_PATH" == *"$PATTERN"* ]]; then
    echo '{"error":"BLOCKED: Direct write to active figure output is forbidden. Use: python3 figure/v4_port_current/gate/tools/figure_gate.py promote <RUN_MANIFEST.json>"}'
    exit 2
  fi
done

exit 0
