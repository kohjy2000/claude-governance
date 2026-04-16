---
name: init-output
description: DEPRECATED in Phase 6 Turn 2. Figure pipeline initialization moved to /figure-init (Layer 2). Writing and grant output types are deferred to later phases. This skill file is retained as a tombstone to prevent name collision; invoking it returns an instruction to use /figure-init instead.
allowed-tools: Read
---

# /init-output — DEPRECATED

**Status**: DEPRECATED as of 2026-04-15 (Phase 6 Turn 2, legacy-merge).

**이 skill은 더 이상 동작하지 않는다.** 호출 시 아래 안내만 출력하고 종료.

## 대체 경로

| 원래 의도 | 새 경로 |
|-----------|--------|
| `/init-output figures` | `/figure-init` (Layer 2 orchestrator, Phase 6 Turn 2 신설). reference/ 기반 docs_figure/ 생성. |
| `/init-output writing` | 현재 없음. Writing skill은 phase 7+ 계획 (DRAFT_LOG schema 별도 작성 필요). |
| `/init-output grant` | 현재 없음. Grant skill은 phase 7+ 계획 (AIMS schema 별도 작성 필요). |

## 왜 폐기되었나

Feature branch(2026-04-14)의 `/figure-init` + `/figure-style-extract`이 훨씬 정교한 figure 초기화를 제공:
- Reference paper PDF + catalog script 파싱
- STYLE_GUIDE.md + SCRIPT_CATALOG.yml 자동 생성
- docs_figure/ 구조 (FIGURE_BASELINE, FIGURE_PLAN_OVERVIEW, per-figure TARGETs)
- Entity tier 분류 (PRIMARY/SECONDARY/CONTEXTUAL/EXCLUDED)
- Claim → Figure 매핑 (Group 기반)

Phase 6 Turn 2 legacy-merge에서 이 기능을 흡수하며 /init-output은 redundant가 됨.

## 호출 시 동작

```
/init-output <args>
```

→ stdout에 아래 안내만 출력:

```
/init-output is DEPRECATED.

For figure pipeline initialization, use:
  /figure-init

For writing/grant initialization, these output types are not yet implemented.
See PHASE_6_TODO.md issue #-4 for roadmap.
```

그리고 종료. 디렉토리 생성/파일 작성 없음.

## 제거 시점

- 이 tombstone 파일은 최소 3개월 유지. User가 구 문서나 기억으로 `/init-output`을 쳐도 혼란 없도록.
- 2026-07-15 이후 이 파일 전체 삭제 고려. 그 전에 governance-sync의 install 로그에 deprecation warning 추가하는 방안도 검토.
