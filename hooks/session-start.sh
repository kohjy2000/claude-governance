#!/usr/bin/env bash
# Hook 4: SessionStart — 필수 문서 자동 로드
# Type: SessionStart
# Purpose: 세션 시작 시 프로젝트 SSOT 요약을 context에 주입.
#          CLAUDE_portable.md "세션 시작 프로토콜"의 hard enforcement.
#
# stdout → Claude context에 주입됨
# 제한: 1초 이내 실행 권장. 파일 전체가 아니라 요약만.

set -euo pipefail

SESSION_LOG="${CLAUDE_SESSION_READS_LOG:-/tmp/claude_session_reads.log}"

# 새 세션이므로 read tracker 초기화
> "$SESSION_LOG"

# 프로젝트 root 감지 (docs/ 폴더가 있는 가장 가까운 상위)
find_project_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/docs" ] && [ -f "$dir/docs/CLAIMS.md" -o -f "$dir/docs/DATA_MAP.md" ]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

PROJECT_ROOT=$(find_project_root 2>/dev/null) || {
  echo "⚠️ No project docs/ folder found. Run /init-project first or cd to a project directory."
  exit 0
}

echo "=== SESSION START: Project Context ==="
echo "Project: $PROJECT_ROOT"
echo ""

# DATA_MAP 요약 (SSOT key 목록만)
if [ -f "$PROJECT_ROOT/docs/DATA_MAP.md" ]; then
  KEY_COUNT=$(grep -c '^\| *SSOT\$' "$PROJECT_ROOT/docs/DATA_MAP.md" 2>/dev/null || echo "0")
  echo "📁 DATA_MAP: ${KEY_COUNT} SSOT keys registered"
  # 최근 수정된 key 3개만 표시
  grep '^\| *SSOT\$' "$PROJECT_ROOT/docs/DATA_MAP.md" 2>/dev/null | tail -3 | while read -r line; do
    echo "   $line"
  done
  echo ""
else
  echo "⚠️ docs/DATA_MAP.md NOT FOUND"
fi

# CLAIMS 요약 (group별 claim 수)
if [ -f "$PROJECT_ROOT/docs/CLAIMS.md" ]; then
  TOTAL=$(grep -c '^### C[0-4]-' "$PROJECT_ROOT/docs/CLAIMS.md" 2>/dev/null || echo "0")
  MAIN=$(grep -c 'Tag.*main' "$PROJECT_ROOT/docs/CLAIMS.md" 2>/dev/null || echo "0")
  DEPRECATED=$(grep -c 'Tag.*deprecated' "$PROJECT_ROOT/docs/CLAIMS.md" 2>/dev/null || echo "0")
  echo "📋 CLAIMS: ${TOTAL} total (${MAIN} main, ${DEPRECATED} deprecated)"
  # Group별 카운트
  for G in C0 C1 C2 C3 C4; do
    COUNT=$(grep -c "^### ${G}-" "$PROJECT_ROOT/docs/CLAIMS.md" 2>/dev/null || echo "0")
    [ "$COUNT" -gt 0 ] && echo "   ${G}: ${COUNT} claims"
  done
  # Stale check (90일 초과 main claim)
  STALE=$(awk -F': ' '/^- \*\*Last recomputed\*\*/ {print $2}' "$PROJECT_ROOT/docs/CLAIMS.md" 2>/dev/null | while read -r d; do
    [ -n "$d" ] && [ "$(date -d "$d" +%s 2>/dev/null || echo 0)" -lt "$(date -d '90 days ago' +%s 2>/dev/null || echo 0)" ] && echo "1"
  done | wc -l 2>/dev/null || echo "0")
  [ "$STALE" -gt 0 ] && echo "   ⚠️ ${STALE} claims with Last recomputed > 90 days"
  echo ""
else
  echo "⚠️ docs/CLAIMS.md NOT FOUND"
fi

# Figure pipeline 상태
if [ -d "$PROJECT_ROOT/docs_figure" ]; then
  DESIGN_COUNT=$(find "$PROJECT_ROOT/docs_figure/figure_pipeline/design_docs" -name "Fig*_design.md" 2>/dev/null | wc -l)
  PANEL_COUNT=$(find "$PROJECT_ROOT/output/panels" -name "*.png" -o -name "*.pdf" 2>/dev/null | wc -l)
  echo "🎨 Figure Pipeline: ${DESIGN_COUNT} design docs, ${PANEL_COUNT} rendered panels"

  # PANEL_REGISTRY 요약
  if [ -f "$PROJECT_ROOT/docs_figure/PANEL_REGISTRY.md" ]; then
    REG_COUNT=$(grep -c '^|' "$PROJECT_ROOT/docs_figure/PANEL_REGISTRY.md" 2>/dev/null || echo "0")
    echo "   PANEL_REGISTRY: ${REG_COUNT} entries"
  fi
  echo ""
fi

# README 마지막 상태
if [ -f "$PROJECT_ROOT/docs/README.md" ]; then
  # 첫 3줄만 (프로젝트명 + 상태)
  head -3 "$PROJECT_ROOT/docs/README.md"
  echo ""
fi

echo "=== ⚠️ MANDATORY: Read canonical CSV BEFORE writing any R/Python code ==="
echo "=== Run figure-reviewer after EVERY panel render (no skip) ==="
echo ""
