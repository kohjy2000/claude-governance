# Global Rules — JYK Computational Biology Lab

## 행동 원칙
- 가정하지 마. 불확실하면 멈추고 물어.
- 여러 해석이 있으면 제시하고 조용히 고르지 마.
- 최소 코드. 추상화/유연성/speculative feature 없이. 요청받은 것만.
- Surgical changes. 인접 코드/주석/포맷 건들지 마.
- Plan → Verify loop. 모든 multi-step 작업에 적용:
  ```
  1. [Step] → verify: [check]
  2. [Step] → verify: [check]
  ```

## 세션 시작 프로토콜
- 프로젝트 CLAUDE.md가 있으면 **반드시 먼저 읽을 것**.
- docs/README.md → docs/DATA_MAP.md 순서로 현재 상태 파악.
- 상태 파악 완료 전까지 코드 작성/수정 금지.
- 세션 재개 시 `/session-resume` 사용 권장.

## 문서 업데이트 의무 (SSOT)
- 모든 프로젝트는 docs/ 폴더에 6개 SSOT 문서를 유지:
  README.md(상태), STORY.md(배경/버그/내러티브), **CLAIMS.md(구조화된 사실)**, DATA_MAP.md(경로), PIPELINE.md(실행계획), JOB_LOG.md(Job기록)
- **계획 변경** → PIPELINE.md, **경로 추가** → DATA_MAP.md, **Job 제출** → JOB_LOG.md
- **Step 완료** → README.md 업데이트, **버그 발견** → STORY.md 추가
- **논문-facing 사실** → CLAIMS.md (숫자, statement). **내러티브/결정 이유** → STORY.md. 경계 헷갈리면 STORY.md의 Document Discipline 참조.

## 재현성 (Reproducibility)
- 모든 분석은 스크립트로 남길 것. interactive 실행 → 스크립트화 필수.
- 스크립트 대폭 변경 → 버전업 (v09 → v10). 기존 버전 보존.
- CLAIMS.md의 `Source script` 필드는 항상 재생 가능한 script path. Notebook cell은 `path` 수준에서 허용, 안정화되면 `path:line`으로 승격.

## 상태 점검
- 간결하게. 빠르게 확인.
- 문제 없으면 길게 설명하지 말 것.
- 문제 발견 → 원인 파악 → 수정안 제시 → 확인 후 실행.

## Auto-memory 관리
- MEMORY.md = 인덱스만 (< 50줄). 주제별 파일에 상세 내용.
- 상태/사실 → docs/ (SSOT). Memory에 넣지 않음.
- 패턴/교훈 → memory/ 주제별 파일. 짧게.

## Governance sync
- 이 파일의 소스는 `~/code/claude-governance/global/CLAUDE_portable.md`.
- `~/.claude/CLAUDE.md`는 `bootstrap-system` 또는 `governance-sync`가 생성한 복사본 — 직접 편집 지양.
- 수정은 source에서 → commit → push → 다른 머신에서 pull + rsync.
