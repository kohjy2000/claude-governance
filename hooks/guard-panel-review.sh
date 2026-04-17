#!/usr/bin/env bash
# Hook 7: PostToolUse — panel PNG/PDF Write 후 figure-reviewer 강제
# Type: PostToolUse
# Matcher: Write|Bash
# Purpose: panel이 렌더링된 후 figure-reviewer 실행을 강제.
#          "reviewer를 아예 안 돌림" 패턴 방지.
#
# 실패 모드:
#   1. Panel render 후 reviewer 안 돌리고 "완료" 보고
#   2. Review → fix → re-render 후 re-review 안 함
#
# Enforcement: figure-implement Step N ("반드시 이 turn 내에 figure-reviewer subagent를 spawn")
#
# stdin: JSON { tool_name, tool_input: { file_path | command }, ... }
# stdout: JSON { additionalContext }

set -euo pipefail

REVIEW_TRACKER="${CLAUDE_SESSION_REVIEWS_LOG:-/tmp/claude_session_reviews.log}"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Case 1: Write tool이 panel PNG/PDF를 직접 생성
if [ "$TOOL_NAME" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  case "$FILE_PATH" in
    */panels/*.png|*/panels/*.pdf|*/panels/*.svg)
      ;;
    *)
      exit 0
      ;;
  esac

  PANEL_NAME=$(basename "$FILE_PATH")
  FIG_NUM=""
  [[ "$PANEL_NAME" =~ [Ff]ig([0-9]+) ]] && FIG_NUM="${BASH_REMATCH[1]}"

  echo "$(date +%s)|RENDER|${FILE_PATH}" >> "$REVIEW_TRACKER"

  cat <<EOF
{"additionalContext":"🔍 Panel ${PANEL_NAME} 렌더링 완료. 반드시 figure-reviewer를 실행하세요.\n\n필수 다음 단계:\n1. PANEL_REGISTRY.md에 이 panel append (save_panel() 또는 수동)\n2. figure-reviewer subagent spawn: Agent(description='Review ${PANEL_NAME}', prompt='Review Fig${FIG_NUM} panel, granularity=panel, multimodal=true')\n\n⚠️ reviewer 없이 다음 panel로 넘어가지 마세요. 생략 금지."}
EOF
  exit 0
fi

# Case 2: Bash로 Rscript 실행하여 panel 생성
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty')

  # Rscript/python 실행인지
  case "$COMMAND" in
    *Rscript*|*python*)
      ;;
    *)
      exit 0
      ;;
  esac

  # 실행 결과에서 panel 파일 생성 흔적 찾기
  # ggsave, save_panel, savefig 등의 output 메시지
  PANEL_CREATED=false

  if echo "$OUTPUT" | grep -qiE 'saved.*panel|ggsave|savefig|save_panel|Writing.*png|Writing.*pdf|panels/Fig'; then
    PANEL_CREATED=true
  fi

  # 또는 command 자체에 Fig 패턴이 있고 성공적으로 실행됨
  if echo "$COMMAND" | grep -qE '[Ff]ig[0-9]+' && ! echo "$OUTPUT" | grep -qE 'Error|error|FAIL|Traceback'; then
    # Figure 관련 R/Python이 에러 없이 끝남 — panel이 생겼을 가능성 높음
    PANEL_CREATED=true
  fi

  [ "$PANEL_CREATED" = true ] || exit 0

  # Figure 번호 추출
  FIG_NUM=""
  if [[ "$COMMAND" =~ [Ff]ig([0-9]+) ]]; then
    FIG_NUM="${BASH_REMATCH[1]}"
  fi

  echo "$(date +%s)|RENDER_BASH|Fig${FIG_NUM}" >> "$REVIEW_TRACKER"

  # 이전에 같은 figure에 대해 review가 있었는지 확인
  LAST_REVIEW=$(grep "|REVIEW|.*Fig${FIG_NUM}" "$REVIEW_TRACKER" 2>/dev/null | tail -1 | cut -d'|' -f1)
  LAST_RENDER=$(grep "|RENDER.*Fig${FIG_NUM}" "$REVIEW_TRACKER" 2>/dev/null | tail -1 | cut -d'|' -f1)

  if [ -n "$LAST_REVIEW" ] && [ -n "$LAST_RENDER" ] && [ "$LAST_RENDER" -gt "$LAST_REVIEW" ]; then
    # Re-render after review — re-review 필요
    cat <<EOF
{"additionalContext":"🔄 Fig${FIG_NUM} re-render 감지 (이전 review 이후 수정됨). RE-REVIEW가 필요합니다.\n\nFix가 새로운 문제를 만들지 않았는지 확인하세요:\n→ figure-reviewer subagent를 다시 실행하세요.\n\n⚠️ Review loop을 닫지 않고 다음으로 넘어가지 마세요."}
EOF
  else
    cat <<EOF
{"additionalContext":"🔍 Fig${FIG_NUM} panel 렌더링 완료 (Rscript). 반드시 figure-reviewer를 실행하세요.\n\n1. PANEL_REGISTRY.md append\n2. figure-reviewer subagent spawn\n\n⚠️ 생략 금지."}
EOF
  fi
fi

exit 0
