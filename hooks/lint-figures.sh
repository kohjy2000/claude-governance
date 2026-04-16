#!/usr/bin/env bash
# lint-figures.sh — PostToolUse hook for figure pipeline
# Trigger: PANEL_REGISTRY.md Edit/Write
# Role: Layer 3 mechanical checks on recently modified R/Python scripts
# Output: hook.log append (5-field pipe-delimited) + REVIEW_LOG.md FAIL escalation
# Schema: HOOK_LOG.schema.md v1.0
#
# Checks performed:
#   C6  — palette literal (#hex direct usage instead of DX_PRIMARY/etc.)
#   A1  — assert_narrative() missing in panel scripts
#   CC1 — ggsave() direct call (should use save_panel())
#   V7  — banned verbs in labels/titles (demonstrates, proves, clearly shows)
#
# Install: ~/.claude/hooks/lint-figures.sh (chmod +x)
# Config:  settings.json PostToolUse hook with matcher Edit|Write

set -euo pipefail

# --- Read stdin JSON ---
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# --- Guard: only fire for PANEL_REGISTRY.md ---
if [[ -z "$FILE_PATH" ]] || [[ ! "$FILE_PATH" =~ PANEL_REGISTRY\.md$ ]]; then
  exit 0
fi

# --- Determine project root ---
# Walk up from file_path to find docs_figure/
PROJECT_ROOT=""
DIR=$(dirname "$FILE_PATH")
while [[ "$DIR" != "/" ]]; do
  if [[ -d "$DIR/../docs" ]]; then
    PROJECT_ROOT=$(cd "$DIR/.." && pwd)
    break
  fi
  DIR=$(dirname "$DIR")
done

if [[ -z "$PROJECT_ROOT" ]]; then
  # Fallback: use cwd
  PROJECT_ROOT="$CWD"
fi

# --- Paths ---
CODE_DIR="$PROJECT_ROOT/code"
HOOK_LOG="$PROJECT_ROOT/docs_figure/hook.log"
REVIEW_LOG="$PROJECT_ROOT/docs_figure/REVIEW_LOG.md"
TS=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")

# --- Find recently modified R/Python scripts (last 5 minutes) ---
SCRIPTS=()
if [[ -d "$CODE_DIR" ]]; then
  while IFS= read -r -d '' f; do
    SCRIPTS+=("$f")
  done < <(find "$CODE_DIR" -maxdepth 1 \( -name "*.R" -o -name "*.py" \) -mmin -5 -print0 2>/dev/null)
fi

if [[ ${#SCRIPTS[@]} -eq 0 ]]; then
  # No recent scripts found — nothing to lint
  exit 0
fi

# --- Lint functions ---
FINDINGS=()
FAIL_COUNT=0

add_finding() {
  local severity="$1" rule="$2" panel="$3" message="$4"
  local line="$TS | $severity | $rule | $panel | $message"
  FINDINGS+=("$line")
  if [[ "$severity" == "FAIL" ]]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# Extract panel ID from filename: Fig1A_violin.R → Fig1A, Fig1.R → Fig1
panel_from_file() {
  local base
  base=$(basename "$1" | sed 's/\.\(R\|py\)$//')
  # Fig1A_descriptor → Fig1A
  echo "$base" | grep -oE '^Fig[0-9]+[A-Z]?' || echo "common"
}

# --- Check each script ---
for script in "${SCRIPTS[@]}"; do
  PANEL=$(panel_from_file "$script")
  FNAME=$(basename "$script")

  # C6: Palette literal — #hex in color arguments (not in comments)
  # Match: "#RRGGBB" or "#RGB" patterns outside comment lines
  HEX_HITS=$(grep -nE '"#[0-9A-Fa-f]{3,8}"' "$script" | grep -v '^\s*#' | head -5)
  if [[ -n "$HEX_HITS" ]]; then
    FIRST_LINE=$(echo "$HEX_HITS" | head -1 | tr -d '\n' | cut -c1-120)
    add_finding "FAIL" "C6" "$PANEL" "hardcoded hex color in $FNAME: $FIRST_LINE"
  fi

  # A1: assert_narrative() missing — panel scripts (not 00_common) should have at least one
  if [[ "$FNAME" != "00_common.R" ]] && [[ "$FNAME" != "00_common.py" ]]; then
    if ! grep -q 'assert_narrative' "$script"; then
      add_finding "FAIL" "A1" "$PANEL" "no assert_narrative() call in $FNAME"
    fi
  fi

  # CC1: ggsave() direct call — should use save_panel()
  GGSAVE_HITS=$(grep -nE '\bggsave\s*\(' "$script" | grep -v '^\s*#' | head -3)
  if [[ -n "$GGSAVE_HITS" ]]; then
    add_finding "FAIL" "CC1" "$PANEL" "direct ggsave() in $FNAME — use save_panel() instead"
  fi

  # Python equivalent: plt.savefig / fig.savefig direct call
  SAVEFIG_HITS=$(grep -nE '\bsavefig\s*\(' "$script" | grep -v '^\s*#' | head -3)
  if [[ -n "$SAVEFIG_HITS" ]]; then
    add_finding "FAIL" "CC1" "$PANEL" "direct savefig() in $FNAME — use save_panel() instead"
  fi

  # V7: Banned verbs in labels/titles/subtitles
  BANNED_HITS=$(grep -niE '(title|label|subtitle|caption).*\b(demonstrates?|proves?|clearly shows?|undeniably|unequivocally)\b' "$script" | head -3)
  if [[ -n "$BANNED_HITS" ]]; then
    FIRST_LINE=$(echo "$BANNED_HITS" | head -1 | tr -d '\n' | cut -c1-120)
    add_finding "WARN" "V7" "$PANEL" "banned verb in label/title in $FNAME: $FIRST_LINE"
  fi

  # INFO: theme_nature() applied (positive signal)
  if grep -q 'theme_nature' "$script"; then
    add_finding "INFO" "V2" "$PANEL" "theme_nature() applied in $FNAME"
  fi
done

# --- Write hook.log ---
if [[ ${#FINDINGS[@]} -gt 0 ]]; then
  # Ensure hook.log exists
  mkdir -p "$(dirname "$HOOK_LOG")"
  for line in "${FINDINGS[@]}"; do
    echo "$line" >> "$HOOK_LOG"
  done
fi

# --- Escalate FAILs to REVIEW_LOG ---
if [[ $FAIL_COUNT -gt 0 ]]; then
  mkdir -p "$(dirname "$REVIEW_LOG")"
  {
    echo ""
    echo "## Hook FAIL $TS"
    for line in "${FINDINGS[@]}"; do
      if echo "$line" | grep -q "| FAIL |"; then
        RULE=$(echo "$line" | awk -F' \\| ' '{print $3}' | xargs)
        PANEL_ID=$(echo "$line" | awk -F' \\| ' '{print $4}' | xargs)
        MSG=$(echo "$line" | awk -F' \\| ' '{print $5}')
        echo "- Rule: $RULE"
        echo "- Panel: $PANEL_ID"
        echo "- Detail: $MSG"
      fi
    done
    echo "- Auto-logged from hook.log"
    echo "- Subagent review pending"
  } >> "$REVIEW_LOG"
fi

# --- Build feedback JSON for Claude ---
if [[ ${#FINDINGS[@]} -gt 0 ]]; then
  SUMMARY="lint-figures hook: ${#FINDINGS[@]} findings ($FAIL_COUNT FAIL). "
  if [[ $FAIL_COUNT -gt 0 ]]; then
    SUMMARY+="FAIL items logged to hook.log and escalated to REVIEW_LOG. "
    SUMMARY+="figure-reviewer subagent (Step N) will process these. "
    SUMMARY+="Fix FAIL issues before marking panel as selected."
  else
    SUMMARY+="No FAILs — WARN/INFO only. Logged to hook.log."
  fi

  # Output JSON for Claude additionalContext
  jq -n --arg ctx "$SUMMARY" '{additionalContext: $ctx}'
else
  # No findings — silent success
  exit 0
fi
