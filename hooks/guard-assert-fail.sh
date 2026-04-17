#!/usr/bin/env bash
# Hook 2: PostToolUse — assert_narrative FAIL 감지
# Type: PostToolUse
# Matcher: Bash
# Purpose: Rscript/python 실행 후 [ASSERT FAIL] 패턴 감지.
#          assert_narrative()가 stop()을 던졌는데 AI가 무시하는 것을 방지.
#
# 실패 모드: expected=2.33인데 actual=2.563이면 assert가 stop() 던짐.
#            AI가 "그냥 에러네" 하고 넘어감.
# Enforcement: figure-implement A2 ("assertion 실패 시 stop() — silent fail 금지")
#
# stdin: JSON { tool_name, tool_input: { command }, tool_output, ... }
# stdout: JSON { additionalContext }

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only check Bash tool
[ "$TOOL_NAME" = "Bash" ] || exit 0

# command 내용 확인 — Rscript 또는 python 실행인지
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
case "$COMMAND" in
  *Rscript*|*Rscript\ *|*python*|*python3*)
    ;;
  *)
    exit 0  # R/Python 실행이 아님
    ;;
esac

# 실행 결과에서 assert 실패 패턴 탐색
# tool_output이 있으면 거기서, 없으면 stderr 패턴
OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty')

# 패턴 목록: assert_narrative의 stop() 메시지, testthat 실패, Python assert
FAIL_PATTERNS='ASSERT FAIL|assert_narrative.*FAIL|Error.*stop\(|AssertionError|MISMATCH.*expected|Expected.*but got|Assertion failed'

if echo "$OUTPUT" | grep -qiE "$FAIL_PATTERNS"; then
  # 실패 상세 추출 (첫 3줄)
  FAIL_DETAIL=$(echo "$OUTPUT" | grep -iE "$FAIL_PATTERNS" | head -3 | tr '\n' ' ')

  cat <<EOF
{"additionalContext":"🚨 ASSERTION FAILURE 감지: ${FAIL_DETAIL}\n\n이것은 무시할 수 없는 오류입니다. Expected 값과 actual 값이 불일치합니다.\n\n다음 중 하나를 수행하세요:\n1. CSV 데이터를 다시 Read하고 expected 값을 actual에 맞게 수정\n2. CLAIMS.md의 Numerical anchor가 stale이면 CLAIMS도 업데이트\n3. 코드의 데이터 처리 로직에 버그가 있으면 수정\n\n절대 assert를 주석 처리하거나 expected 값을 임의로 바꾸지 마세요."}
EOF
  exit 0
fi

# Execution error (non-assert) — R이 에러로 종료
if echo "$OUTPUT" | grep -qE 'Execution halted|Error in|Traceback|Fatal error'; then
  EXEC_ERR=$(echo "$OUTPUT" | grep -E 'Error in|Traceback|Fatal error' | head -2 | tr '\n' ' ')
  cat <<EOF
{"additionalContext":"⚠️ Script 실행 오류 감지: ${EXEC_ERR}\n\n오류를 확인하고 수정하세요. '완료'로 보고하지 마세요."}
EOF
fi

exit 0
