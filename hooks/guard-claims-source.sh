#!/usr/bin/env bash
# Hook 3: PreToolUse — CLAIMS 숫자 source tag 체크
# Type: PreToolUse
# Matcher: Edit|Write
# Purpose: CLAIMS.md에 숫자를 쓸 때 CSV Read 기록이 없으면 warning.
#          Source tag 없는 숫자 삽입 감지.
#
# 실패 모드: AI가 대화 맥락이나 이전 문서에서 숫자를 복사해 CLAIMS에 넣음.
# Enforcement: CLAIMS.schema.md Source script 필드 + CLAUDE_portable.md "논문-facing 사실"
#
# stdin: JSON { tool_name, tool_input: { file_path, new_string }, ... }
# stdout: JSON { additionalContext } (warning only, no block)
# exit 0 항상 (block 안 함, warning만)

set -euo pipefail

SESSION_LOG="${CLAUDE_SESSION_READS_LOG:-/tmp/claude_session_reads.log}"

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# CLAIMS 파일인지 확인
case "$FILE_PATH" in
  *CLAIMS*.md|*claims*.md|*CLAIM_STRUCTURE*)
    ;;
  *)
    exit 0
    ;;
esac

# 수정 내용에 숫자가 포함되어 있는지 확인
# Edit의 경우 new_string, Write의 경우 content
NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')
[ -n "$NEW_CONTENT" ] || exit 0

# 유의미한 숫자 패턴 (p-value, OR, HR, n=, %, 소수점 등)
# 단순 날짜(2026-04-16)나 claim ID(C1-3)는 제외
HAS_NUMBERS=false
if echo "$NEW_CONTENT" | grep -qE '[0-9]+\.[0-9]+[eE]?[-+]?[0-9]*|[pP]\s*[=<>]\s*[0-9]|OR\s*=|HR\s*=|n\s*=\s*[0-9]|[0-9]+%|[0-9]{2,}\s*→\s*[0-9]'; then
  HAS_NUMBERS=true
fi

[ "$HAS_NUMBERS" = true ] || exit 0

# CSV Read 기록 확인
DATA_READS=0
if [ -f "$SESSION_LOG" ]; then
  DATA_READS=$(grep -c "|DATA|" "$SESSION_LOG" 2>/dev/null || echo "0")
fi

WARNINGS=""

if [ "$DATA_READS" -eq 0 ]; then
  WARNINGS="🚨 CLAIMS에 숫자를 쓰려 하는데, 이 세션에서 CSV/데이터 파일을 아직 읽지 않았습니다. 이 숫자의 출처가 canonical CSV인지 확인하세요. 기억이나 이전 대화에서 복사한 숫자는 stale일 수 있습니다."
fi

# Source script 필드가 포함되어 있는지 확인
if ! echo "$NEW_CONTENT" | grep -qi 'Source script'; then
  if [ -n "$WARNINGS" ]; then
    WARNINGS="${WARNINGS}\n\n또한, Numerical anchor를 추가하면서 Source script 필드도 함께 업데이트하세요 (path:line 형식 권장)."
  fi
fi

# Last recomputed 업데이트 확인
if echo "$NEW_CONTENT" | grep -qE 'Numerical anchor|anchor'; then
  if ! echo "$NEW_CONTENT" | grep -qi 'Last recomputed'; then
    EXTRA="Numerical anchor를 변경했으면 Last recomputed 날짜도 오늘로 업데이트하세요."
    WARNINGS="${WARNINGS:+${WARNINGS}\n\n}${EXTRA}"
  fi
fi

if [ -n "$WARNINGS" ]; then
  cat <<EOF
{"additionalContext":"${WARNINGS}"}
EOF
fi

exit 0
