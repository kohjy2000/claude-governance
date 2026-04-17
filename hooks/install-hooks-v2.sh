#!/usr/bin/env bash
# Track A: Hook v2 설치
# 6개 hook + settings.json 업데이트
#
# Run: bash ~/Research_Local/18_claude_governance/hooks/install-hooks-v2.sh

set -e

HOOK_SRC="${BASH_SOURCE[0]%/*}"  # hooks/ 디렉토리
HOOK_DST="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"

echo "=== Track A: Hook v2 Installation ==="
echo ""

# Step 1: hooks 디렉토리 생성
mkdir -p "$HOOK_DST"
echo "OK: $HOOK_DST created"

# Step 2: hook scripts 복사 + 실행 권한
for SCRIPT in track-reads.sh session-start.sh guard-csv-read.sh guard-assert-fail.sh guard-design-sync.sh guard-claims-source.sh; do
  if [ -f "$HOOK_SRC/$SCRIPT" ]; then
    cp "$HOOK_SRC/$SCRIPT" "$HOOK_DST/$SCRIPT"
    chmod +x "$HOOK_DST/$SCRIPT"
    echo "OK: $SCRIPT installed"
  else
    echo "WARN: $SCRIPT not found in $HOOK_SRC"
  fi
done

# 기존 lint-figures.sh도 복사 (있으면)
if [ -f "$HOOK_SRC/../lint-figures.sh" ]; then
  cp "$HOOK_SRC/../lint-figures.sh" "$HOOK_DST/lint-figures.sh"
  chmod +x "$HOOK_DST/lint-figures.sh"
  echo "OK: lint-figures.sh (existing) installed"
elif [ -f "$HOOK_DST/lint-figures.sh" ]; then
  echo "OK: lint-figures.sh already in place"
else
  echo "WARN: lint-figures.sh not found — Phase 6 Turn 3 hook missing"
fi

echo ""

# Step 3: settings.json 업데이트
if [ -f "$SETTINGS" ]; then
  # 기존 settings.json 백업
  cp "$SETTINGS" "${SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
  echo "OK: settings.json backed up"

  # jq로 hooks 섹션 merge
  if command -v jq &>/dev/null; then
    HOOKS_CONFIG="$HOOK_SRC/hooks-v2-config.json"
    if [ -f "$HOOKS_CONFIG" ]; then
      # 기존 settings에 hooks를 merge (기존 hooks는 덮어씀)
      jq -s '.[0] * .[1]' "$SETTINGS" "$HOOKS_CONFIG" > "${SETTINGS}.tmp"
      mv "${SETTINGS}.tmp" "$SETTINGS"
      echo "OK: settings.json hooks merged"
    fi
  else
    echo "WARN: jq not found. settings.json을 수동으로 업데이트하세요."
    echo "      $HOOK_SRC/hooks-v2-config.json 내용을 settings.json에 merge."
  fi
else
  # settings.json이 없으면 새로 생성
  cp "$HOOK_SRC/hooks-v2-config.json" "$SETTINGS"
  echo "OK: settings.json created from hooks config"
fi

echo ""

# Step 4: session reads log 초기화
SESSION_LOG="/tmp/claude_session_reads.log"
> "$SESSION_LOG"
echo "OK: session reads log initialized at $SESSION_LOG"

echo ""
echo "=== Verification ==="

echo "--- Installed hooks ---"
ls -la "$HOOK_DST"/*.sh 2>/dev/null | awk '{print $NF}'

echo ""
echo "--- settings.json hooks section ---"
if command -v jq &>/dev/null && [ -f "$SETTINGS" ]; then
  jq '.hooks | keys' "$SETTINGS" 2>/dev/null || echo "(parse error)"
fi

echo ""
echo "=== Hook v2 Summary ==="
echo ""
echo "  Hook 0 (track-reads.sh)       PostToolUse Read    → CSV/SSOT read 기록"
echo "  Hook 1 (guard-csv-read.sh)    PreToolUse  Edit|Write → R/Python 파일 write시 CSV 미확인 BLOCK"
echo "  Hook 2 (guard-assert-fail.sh) PostToolUse Bash    → assert_narrative FAIL 감지"
echo "  Hook 3 (guard-claims-source.sh) PreToolUse Edit|Write → CLAIMS 숫자 source 미확인 WARNING"
echo "  Hook 4 (session-start.sh)     SessionStart        → 필수 문서 자동 로드"
echo "  Hook 5 (guard-design-sync.sh) PostToolUse Edit|Write → design-output mtime 불일치 WARNING"
echo "  Hook 6 (lint-figures.sh)      PostToolUse Edit|Write → C6/A1/CC1/V7 코드 품질 (기존)"
echo ""
echo "테스트:"
echo "  1. 새 Claude Code 세션 시작 → Hook 4 context 주입 확인"
echo "  2. CSV 안 읽고 Fig2.R Write 시도 → Hook 1 BLOCK 확인"
echo "  3. assert_narrative FAIL이 있는 Rscript 실행 → Hook 2 경고 확인"
echo "  4. CLAIMS.md에 숫자 수정 (CSV 미확인) → Hook 3 경고 확인"
echo "  5. TARGET.md 수정 후 stale panel 존재 → Hook 5 경고 확인"
