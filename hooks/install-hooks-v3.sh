#!/usr/bin/env bash
# Hook v3 Installation — figure gate enforcement + plan-lock
#
# New in v3:
#   - guard-panel-output.sh   (PreToolUse Write|Edit) — block active output direct write
#   - guard-plan-lock.sh      (PreToolUse Bash)       — block render without work plan
#   - guard-figure-skill.sh   (PreToolUse Skill)      — block impl skills without plan
#   - guard-render-candidate.sh (PostToolUse Bash)     — audit render goes to candidates
#   - guard-panel-review.sh   (PostToolUse Bash|Write) — enforce review after render (was missing in v2)
#
# Run: bash ~/claude-governance/hooks/install-hooks-v3.sh

set -e

HOOK_SRC="${BASH_SOURCE[0]%/*}"  # hooks/ directory
HOOK_DST="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"

echo "=== Hook v3 Installation (figure gate + plan-lock) ==="
echo ""

# Step 1: ensure hooks directory
mkdir -p "$HOOK_DST"

# Step 2: copy all hook scripts
ALL_HOOKS=(
  # v2 hooks
  track-reads.sh
  session-start.sh
  guard-csv-read.sh
  guard-assert-fail.sh
  guard-design-sync.sh
  guard-claims-source.sh
  lint-figures.sh
  guard-panel-review.sh
  # v3 new hooks
  guard-panel-output.sh
  guard-render-candidate.sh
  guard-plan-lock.sh
  guard-figure-skill.sh
)

for SCRIPT in "${ALL_HOOKS[@]}"; do
  if [ -f "$HOOK_SRC/$SCRIPT" ]; then
    cp "$HOOK_SRC/$SCRIPT" "$HOOK_DST/$SCRIPT"
    chmod +x "$HOOK_DST/$SCRIPT"
    echo "OK: $SCRIPT"
  else
    echo "WARN: $SCRIPT not found in $HOOK_SRC"
  fi
done

echo ""

# Step 3: update settings.json
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "${SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
  echo "OK: settings.json backed up"
fi

HOOKS_CONFIG="$HOOK_SRC/hooks-v3-config.json"
if [ -f "$HOOKS_CONFIG" ]; then
  if command -v jq &>/dev/null; then
    if [ -f "$SETTINGS" ]; then
      jq -s '.[0] * .[1]' "$SETTINGS" "$HOOKS_CONFIG" > "${SETTINGS}.tmp"
      mv "${SETTINGS}.tmp" "$SETTINGS"
    else
      cp "$HOOKS_CONFIG" "$SETTINGS"
    fi
    echo "OK: settings.json hooks merged from v3 config"
  else
    echo "WARN: jq not found. Manually merge $HOOKS_CONFIG into $SETTINGS"
  fi
fi

echo ""

# Step 4: verify
echo "=== Installed hooks ==="
ls "$HOOK_DST"/*.sh 2>/dev/null | while read -r f; do echo "  $(basename "$f")"; done

echo ""
echo "=== Hook v3 Summary ==="
echo ""
echo "  [v2] Hook 0  track-reads.sh          PostToolUse Read       CSV/SSOT read tracking"
echo "  [v2] Hook 1  guard-csv-read.sh       PreToolUse  Edit|Write CSV read-before-write"
echo "  [v2] Hook 2  guard-assert-fail.sh    PostToolUse Bash       assert_narrative fail"
echo "  [v2] Hook 3  guard-claims-source.sh  PreToolUse  Edit|Write CLAIMS source check"
echo "  [v2] Hook 4  session-start.sh        SessionStart           SSOT auto-load"
echo "  [v2] Hook 5  guard-design-sync.sh    PostToolUse Edit|Write design-output mtime"
echo "  [v2] Hook 6  lint-figures.sh         PostToolUse Edit|Write C6/A1/CC1/V7 lint"
echo "  [v2] Hook 7  guard-panel-review.sh   PostToolUse Bash|Write review enforcement"
echo "  [v3] Hook 8  guard-panel-output.sh   PreToolUse  Edit|Write HARD BLOCK active output"
echo "  [v3] Hook 9  guard-plan-lock.sh      PreToolUse  Bash       HARD BLOCK render w/o plan"
echo "  [v3] Hook 10 guard-figure-skill.sh   PreToolUse  Skill      HARD BLOCK impl skill w/o plan"
echo "  [v3] Hook 11 guard-render-candidate.sh PostToolUse Bash     audit render → candidates"
echo ""
echo "Hard blocks (exit 2): Hook 8, 9, 10"
echo "Context inject:       Hook 7, 11"
echo ""
echo "Test: start new session, try 'Rscript code/Fig3_a.R' without FIGURE_WORK_PLAN.md → should BLOCK"
