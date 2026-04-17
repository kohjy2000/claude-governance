#!/usr/bin/env bash
# Hook 0: Session Read Tracker (공통 인프라)
# Type: PostToolUse
# Matcher: Read
# Purpose: CSV/데이터 파일 Read 시 session log에 기록.
#          Hook 1 (R script block)과 Hook 3 (CLAIMS source check)의 전제조건.
#
# stdin: JSON { tool_name, tool_input: { file_path, ... }, ... }
# stdout: JSON { additionalContext } (optional)

set -euo pipefail

SESSION_LOG="${CLAUDE_SESSION_READS_LOG:-/tmp/claude_session_reads.log}"

# Read stdin JSON
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only track Read tool
[ "$TOOL_NAME" = "Read" ] || exit 0
[ -n "$FILE_PATH" ] || exit 0

# Track data files: CSV, TSV, RDS paths, and SSOT docs
case "$FILE_PATH" in
  *.csv|*.tsv|*.txt|*.rds|*.RDS|*.rda|*.parquet)
    echo "$(date +%s)|DATA|${FILE_PATH}" >> "$SESSION_LOG"
    ;;
  */docs/CLAIMS.md|*/docs/DATA_MAP.md|*/docs/STORY.md|*/docs/PIPELINE.md|*/docs/README.md)
    echo "$(date +%s)|SSOT|${FILE_PATH}" >> "$SESSION_LOG"
    ;;
  */FIGURE_BASELINE.md|*/STYLE_GUIDE.md|*/SCRIPT_CATALOG.yml|*TARGET*.md|*design*.md)
    echo "$(date +%s)|FIGURE_DOC|${FILE_PATH}" >> "$SESSION_LOG"
    ;;
  *)
    # Not a tracked file type
    exit 0
    ;;
esac

exit 0
