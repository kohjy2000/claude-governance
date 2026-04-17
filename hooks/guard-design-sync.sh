#!/usr/bin/env bash
# Hook 5: PostToolUse — design doc 수정 후 output stale 감지
# Type: PostToolUse
# Matcher: Edit|Write
# Purpose: TARGET.md / design doc 수정 시 rendered panel이 outdated인지 mtime 비교.
#          "계획서만 쌓이고 출력물은 안 바뀌는" 패턴 방지.
#
# 실패 모드: AI가 TARGET.md나 design doc을 업데이트하지만 R script/panel을 안 고침.
# Enforcement: figure-build state machine의 우회를 잡는다.
#
# stdin: JSON { tool_name, tool_input: { file_path }, ... }
# stdout: JSON { additionalContext }

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -n "$FILE_PATH" ] || exit 0

# design doc 또는 TARGET 파일인지 확인
IS_DESIGN=false
case "$FILE_PATH" in
  *TARGET*.md|*target*.md|*_design.md|*design_docs/*.md)
    IS_DESIGN=true
    ;;
esac

[ "$IS_DESIGN" = true ] || exit 0

# Figure 번호 추출
FIG_NUM=""
if [[ "$FILE_PATH" =~ [Ff]ig([0-9]+) ]]; then
  FIG_NUM="${BASH_REMATCH[1]}"
fi
[ -n "$FIG_NUM" ] || exit 0

# 프로젝트 root 탐색
find_project_root() {
  local dir=$(dirname "$FILE_PATH")
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/docs" ] || [ -d "$dir/docs_figure" ]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  echo ""
}

PROJECT_ROOT=$(find_project_root)
[ -n "$PROJECT_ROOT" ] || exit 0

# Design doc의 mtime
DESIGN_MTIME=$(stat -c %Y "$FILE_PATH" 2>/dev/null || echo "0")

# 해당 figure의 rendered panels 찾기
STALE_PANELS=""
PANEL_DIR="$PROJECT_ROOT/output/panels"

if [ -d "$PANEL_DIR" ]; then
  for PANEL in "$PANEL_DIR"/Fig${FIG_NUM}_*.png "$PANEL_DIR"/Fig${FIG_NUM}_*.pdf; do
    [ -f "$PANEL" ] || continue
    PANEL_MTIME=$(stat -c %Y "$PANEL" 2>/dev/null || echo "0")
    if [ "$PANEL_MTIME" -lt "$DESIGN_MTIME" ]; then
      STALE_PANELS="${STALE_PANELS} $(basename "$PANEL")"
    fi
  done
fi

# 해당 figure의 R/Python 코드 찾기
STALE_CODE=""
CODE_DIR="$PROJECT_ROOT/code"

if [ -d "$CODE_DIR" ]; then
  for CODE in "$CODE_DIR"/Fig${FIG_NUM}*.R "$CODE_DIR"/Fig${FIG_NUM}*.py; do
    [ -f "$CODE" ] || continue
    CODE_MTIME=$(stat -c %Y "$CODE" 2>/dev/null || echo "0")
    if [ "$CODE_MTIME" -lt "$DESIGN_MTIME" ]; then
      STALE_CODE="${STALE_CODE} $(basename "$CODE")"
    fi
  done
fi

# 경고 생성
if [ -n "$STALE_PANELS" ] || [ -n "$STALE_CODE" ]; then
  MSG="⚠️ Fig${FIG_NUM} design doc가 업데이트됐지만 downstream이 stale합니다:\n"
  [ -n "$STALE_CODE" ] && MSG="${MSG}\n  Stale code:${STALE_CODE}"
  [ -n "$STALE_PANELS" ] && MSG="${MSG}\n  Stale panels:${STALE_PANELS}"
  MSG="${MSG}\n\nfigure-implement를 다시 실행하여 design 변경을 코드/output에 반영하세요."

  cat <<EOF
{"additionalContext":"${MSG}"}
EOF
fi

exit 0
