#!/usr/bin/env bash
# Hook: PreToolUse — Enforce plan-first workflow for figure implementation skills
# Matcher: Skill
# Purpose: When figure-implement, panel-build, or figure-build skills are invoked,
#          check that FIGURE_WORK_PLAN.md exists. If not, inject context requiring
#          Plan Mode entry first. figure-plan skill is always allowed.
#
# stdin: JSON { tool_name, tool_input: { skill, args }, ... }
# stdout: JSON { additionalContext } or exit 2

set -euo pipefail

INPUT=$(cat)

SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty')
[ -n "$SKILL" ] || exit 0

# Skills that require a plan first
case "$SKILL" in
  figure-implement|panel-build|figure-build|figure-assemble)
    ;;
  *)
    # figure-plan, figure-review, figure-init, etc. are always allowed
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

if [ ! -f "$PLAN_FILE" ]; then
  echo '{"error":"BLOCKED: Cannot run '"$SKILL"' without an approved work plan. Steps required:\n1. Enter Plan Mode (EnterPlanMode)\n2. Read TARGET docs and design implementation plan\n3. Get user approval (ExitPlanMode)\n4. Save plan to docs_figure/FIGURE_WORK_PLAN.md with Status: ACTIVE\n5. Then run '"$SKILL"'"}'
  exit 2
fi

if ! grep -qi "Status:.*ACTIVE" "$PLAN_FILE" 2>/dev/null; then
  echo '{"error":"BLOCKED: FIGURE_WORK_PLAN.md exists but Status is not ACTIVE. Get user approval and set Status: ACTIVE before running '"$SKILL"'."}'
  exit 2
fi

# Plan exists and is active — inject gate reminder as context
cat <<EOF
{"additionalContext":"FIGURE_WORK_PLAN.md is active. Remember: all renders must go through figure_gate.py (preflight -> init-run -> render -> validate -> review-template -> promote). Do not write directly to output/panels/ or output/assembled/."}
EOF

exit 0
