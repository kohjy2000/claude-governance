#!/usr/bin/env bash
# Hook: PostToolUse — Audit that renders go to candidates, not active output
# Matcher: Bash
# Purpose: After Rscript/python3 fig* render commands, check that no new files
#          appeared in active output dirs. Candidate-only enforcement.
#
# stdin: JSON { tool_name, tool_input: { command }, tool_output, ... }
# stdout: JSON { additionalContext } — warning if violation detected

set -euo pipefail

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -n "$COMMAND" ] || exit 0

# Only fire for render-like commands
case "$COMMAND" in
  *Rscript*[Ff]ig*|*python*[Ff]ig*|*render_fig*|*port_fig*)
    ;;
  *)
    exit 0
    ;;
esac

# Find project root by looking for figure/v4_port_current
find_project_root() {
  local cwd
  cwd=$(echo "$INPUT" | jq -r '.cwd // empty')
  [ -n "$cwd" ] || cwd="$PWD"
  local dir="$cwd"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/figure/v4_port_current" ]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  echo ""
}

PROJECT_ROOT=$(find_project_root)
[ -n "$PROJECT_ROOT" ] || exit 0

ACTIVE_PANELS="$PROJECT_ROOT/figure/v4_port_current/output/panels"
ACTIVE_ASSEMBLED="$PROJECT_ROOT/figure/v4_port_current/output/assembled"

# Check for recently modified files in active dirs (last 60 seconds)
VIOLATIONS=""
NOW=$(date +%s)

for DIR in "$ACTIVE_PANELS" "$ACTIVE_ASSEMBLED"; do
  [ -d "$DIR" ] || continue
  while IFS= read -r -d '' FILE; do
    MTIME=$(stat -c %Y "$FILE" 2>/dev/null || echo "0")
    AGE=$(( NOW - MTIME ))
    if [ "$AGE" -lt 60 ]; then
      VIOLATIONS="${VIOLATIONS}\n  $(basename "$FILE") (${AGE}s ago)"
    fi
  done < <(find "$DIR" -type f -newer "$DIR" -print0 2>/dev/null)
done

if [ -n "$VIOLATIONS" ]; then
  MSG="WARNING: Render appears to have written to active output (not candidates):${VIOLATIONS}\n\nFigure output must go to output/candidates/ first.\nUse figure_gate.py render to enforce candidate routing."
  cat <<EOF
{"additionalContext":"${MSG}"}
EOF
fi

exit 0
