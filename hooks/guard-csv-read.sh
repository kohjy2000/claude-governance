#!/usr/bin/env bash
# Hook 1: PreToolUse — CSV 미확인 시 R/Python script Write BLOCK
# Type: PreToolUse
# Matcher: Edit|Write
# Purpose: R/Python 파일 수정 전 해당 figure의 canonical CSV를 이 세션에서
#          Read했는지 확인. 안 읽었으면 exit 2 (block).
#
# 실패 모드: AI가 CSV를 안 읽고 기억 속 숫자로 코드를 작성
# Enforcement: figure-implement C1 ("모든 read_*() 호출은 SSOT key 참조")
#
# stdin: JSON { tool_name, tool_input: { file_path, ... }, ... }
# stdout: JSON (deny시)
# exit 0: allow, exit 2: block

set -euo pipefail

SESSION_LOG="${CLAUDE_SESSION_READS_LOG:-/tmp/claude_session_reads.log}"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only guard Write/Edit to R or Python files
case "$FILE_PATH" in
  *.R|*.r|*.py)
    ;;
  *)
    exit 0  # Not an R/Python file, allow
    ;;
esac

# 예외: 00_common.R, utility scripts는 CSV 불필요
BASENAME=$(basename "$FILE_PATH")
case "$BASENAME" in
  00_common.*|utils.*|helpers.*|setup.*|config.*)
    exit 0
    ;;
esac

# Figure 번호 추출 (Fig1, Fig2, ... 패턴)
FIG_NUM=""
if [[ "$FILE_PATH" =~ [Ff]ig([0-9]+) ]]; then
  FIG_NUM="${BASH_REMATCH[1]}"
fi

# Session read log 확인
if [ ! -f "$SESSION_LOG" ]; then
  # Log 자체가 없음 = 아무것도 안 읽음
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"이 세션에서 아직 데이터 파일을 읽지 않았습니다. 코드 작성 전에 docs/DATA_MAP.md에서 canonical CSV 경로를 확인하고, 해당 CSV를 Read하세요."}}' >&2
  exit 2
fi

# DATA 타입 읽기 기록이 있는지
DATA_READS=$(grep "|DATA|" "$SESSION_LOG" 2>/dev/null | wc -l)

if [ "$DATA_READS" -eq 0 ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"이 세션에서 CSV/데이터 파일을 아직 읽지 않았습니다. R/Python 코드 작성 전에 반드시 canonical CSV를 Read하세요. docs/DATA_MAP.md → SSOT key 확인 → Read(csv_path) 순서."}}' >&2
  exit 2
fi

# SSOT 문서도 읽었는지 확인 (CLAIMS or DATA_MAP)
SSOT_READS=$(grep "|SSOT|" "$SESSION_LOG" 2>/dev/null | wc -l)

if [ "$SSOT_READS" -eq 0 ]; then
  # Block은 안 하지만 강한 warning
  cat <<'WARN'
{"additionalContext":"⚠️ 데이터 CSV는 읽었지만 docs/CLAIMS.md 또는 docs/DATA_MAP.md를 이 세션에서 읽지 않았습니다. 숫자가 CLAIMS와 일치하는지 확인하세요."}
WARN
  exit 0
fi

# 모든 체크 통과
exit 0
