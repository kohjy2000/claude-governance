#!/usr/bin/env bash
# Hook: PreToolUse — Block figure renders without an approved work plan
# Matcher: Bash
# Purpose: Before Rscript/python3 figure render commands, verify that
#          FIGURE_WORK_PLAN.md exists and contains the target panel.
#          Forces Plan Mode → plan → approve → implement workflow.
#
# stdin: JSON { tool_name, tool_input: { command }, ... }
# exit 2 = block the tool call

set -euo pipefail

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -n "$COMMAND" ] || exit 0

# Only fire for figure render commands
case "$COMMAND" in
  *Rscript*[Ff]ig*|*python*[Ff]ig*|*render_fig*|*port_fig*|*figure_gate*render*)
    ;;
  *)
    exit 0
    ;;
esac

# Allow figure_gate.py subcommands that aren't render (preflight, validate, etc.)
case "$COMMAND" in
  *figure_gate*preflight*|*figure_gate*validate*|*figure_gate*review*|*figure_gate*promote*|*figure_gate*hook*|*figure_gate*latest*|*figure_gate*reconcile*)
    exit 0
    ;;
esac

# Find project root
find_project_root() {
  local cwd
  cwd=$(echo "$INPUT" | jq -r '.cwd // empty')
  [ -n "$cwd" ] || cwd="$PWD"
  local dir="$cwd"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/docs_figure" ]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  echo ""
}

PROJECT_ROOT=$(find_project_root)
[ -n "$PROJECT_ROOT" ] || exit 0

PLAN_FILE="$PROJECT_ROOT/docs_figure/FIGURE_WORK_PLAN.md"

# Check 1: Plan exists?
if [ ! -f "$PLAN_FILE" ]; then
  echo '{"error":"BLOCKED: No FIGURE_WORK_PLAN.md found. You must enter Plan Mode (EnterPlanMode), create a figure work plan, get user approval, then save it to docs_figure/FIGURE_WORK_PLAN.md before rendering."}'
  exit 2
fi

# Check 2: Plan is active (contains "Status: ACTIVE")?
if ! grep -qi "Status:.*ACTIVE" "$PLAN_FILE" 2>/dev/null; then
  echo '{"error":"BLOCKED: FIGURE_WORK_PLAN.md exists but is not ACTIVE. Update the plan status to ACTIVE after user approval."}'
  exit 2
fi

# Check 3: Extract figure panel from command and check it is in the plan
FIG_PANEL=""
if [[ "$COMMAND" =~ [Ff]ig([0-9]+)[_]?([a-f]?) ]]; then
  FIG_NUM="${BASH_REMATCH[1]}"
  PANEL_LETTER="${BASH_REMATCH[2]}"
  FIG_PANEL="Fig${FIG_NUM}${PANEL_LETTER}"
fi

if [ -n "$FIG_PANEL" ]; then
  if ! grep -qi "$FIG_PANEL" "$PLAN_FILE" 2>/dev/null; then
    MSG="BLOCKED: ${FIG_PANEL} is not in the current FIGURE_WORK_PLAN.md. Only render panels listed in the approved plan."
    echo "{\"error\":\"${MSG}\"}"
    exit 2
  fi
fi

# All checks passed
exit 0
