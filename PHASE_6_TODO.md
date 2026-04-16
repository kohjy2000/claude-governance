# Deferred Issues Tracker (originally Phase 6 TODO, now generalized)

> **Purpose**: Phase 1-5에서 결정을 유보한 사항 중 Phase 6(Hook + Subagent 인프라)
> 작업 시작 시 반드시 재평가해야 할 이슈들.
>
> **Trigger**: Phase 6 kickoff 시점에 이 파일을 처음부터 끝까지 읽고 각 이슈의
> 현재 상태를 평가한 뒤 해결/연기/삭제를 결정.
>
> **Update rule**: 해결된 이슈는 `[x]`로 체크하고 해결 근거/날짜 append.
> 삭제 금지 — 기록은 유지. 새 이슈는 아래에 append.

---

## Open

### [ ] #-1: GitHub remote 연동 + 3개 머신 sync 실제 가동
- **Raised**: 2026-04-15 (Phase 0 복구 시점)
- **Context**: 현재 `~/claude-governance/`는 local git repo만 존재. GitHub에 push 안 됨 (SSH 키 미등록). Cross-phase constraint #7 ("GitHub = source of truth")이 문서상으로만 선언됨.
- **Trigger to evaluate**: 2번째 머신(biotech dev server 또는 HPC)에서 작업 시작해야 할 시점.
- **Action**:
  1. GitHub SSH 키 등록 (or PAT-based HTTPS)
  2. `kohjy2000/claude-governance` repo 생성 확인/신규 생성
  3. `git remote add origin`, `git push -u origin main`
  4. 2번째 머신에서 `git clone` + `/bootstrap-system` 돌려 검증
  5. `/governance-sync pull`/`push` 실제 가동 테스트
- **Owner**: user.
- **Related**: `skills/governance-sync/SKILL.md`, `skills/bootstrap-system/SKILL.md` Step 2.

### [ ] #-4: writing / grant schema 작성 (DRAFT_LOG.schema, AIMS.schema)
- **Raised**: 2026-04-15 (Phase 5)
- **Context**: Phase 5는 figure 3종 schema만 작성. Writing/grant 쪽은 소비자 skill이 없어서 defer. `outputs/writing/DRAFT_LOG.md`와 `outputs/grant/AIMS.md`는 현재 init-output이 빈 placeholder로만 생성.
- **Trigger to evaluate**: 첫 manuscript draft 본격 작성 시작 시점, 또는 grant 작성이 figure-phase를 넘어 활성화될 때.
- **Action**: DRAFT_LOG.schema.md (manuscript 진행 추적) 및 AIMS.schema.md (aims section 구조 + claim linkage) 작성. 해당 skill (draft-helper, grant-helper 등) 설계 동반 필요.
- **Owner**: user.

### [x] #-3: figure-implement / figure-assemble SKILL에 Phase 5 schema reference 추가
- **Raised**: 2026-04-15 (Phase 5). **Closed**: 2026-04-15 (Phase 5.5).
- Phase 5.5에서 figure-implement_SKILL.md와 figure-assemble_SKILL.md 신규본 작성 시 schema reference 라인 + PANEL_REGISTRY 통합 로직 추가.

### [x] #-2: init-project 스킬 Phase 4 원칙 반영
- **Raised**: 2026-04-15 (Phase 4). **Closed**: 2026-04-15 (Phase 5.5).
- init-project_SKILL.md Step 2에 "outputs/는 만들지 않는다. /init-output으로 명시 초기화" 박음.

### [x] #0: figure-implement 스킬에 figure-review auto-invoke 라인 추가
- **Raised**: 2026-04-15 (Phase 1 Turn 2). **Closed**: 2026-04-15 (Phase 5.5).
- figure-implement_SKILL.md의 Step N (last)에 `/figure-review --auto` 호출 지시 추가. Phase 6에서 hook 기반으로 승격 예정 (아래 #P1-P4 참조).

### [ ] #1: CLAIMS.schema.md format upgrade (A → B)
- **Raised**: 2026-04-15 (Phase 1 Turn 2)
- **Context**: Turn 2 현재 schema는 Markdown (Option A). Hook은 `enum.*` 라인을 regex grep.
- **Trigger to evaluate**: Phase 6 hook 구현 시작 시점.
- **Question**: Hook 코드와 schema.md 사이에 enum/rule drift가 실제로 발생했는가?
  - 발생했으면 → Option B (Markdown + trailing YAML/JSON block)로 격상. Hook은 block만 parse.
  - 발생 안 했으면 → A 유지.
- **Owner**: figure-review hook 구현자 (user).
- **Related**: `blueprints/schemas/CLAIMS.schema.md`의 "Primary consumers" 블록.

### [ ] #2: governance-sync conflict resolution 확장
- **Raised**: 2026-04-15 (Phase 1 Turn 2)
- **Context**: 현재 `governance-sync`는 얇은 git 래퍼. Conflict는 user 수동 해결.
- **Trigger to evaluate**: Phase 6 진입 시 multi-machine 충돌 빈도 데이터 누적 후.
- **Question**: 최근 3-6개월 CLAIMS.md/STORY.md conflict 빈도가 몇 번이었나?
  - 월 1회 이하 → 현 상태 유지.
  - 월 2회 이상 → 자동 resolution 로직 추가 (예: claim ID 중복 시 재부여 prompt).
- **Owner**: user.
- **Related**: `skills/governance-sync/SKILL.md`의 "Conflict 처리 원칙" 블록.

### [ ] #3: figure-review Layer 3의 hook 이전
- **Raised**: 2026-04-15 (Phase 1 Turn 2)
- **Context**: 현재 figure-review skill 내부에 Layer 3 (P1-P13 mechanical grep)이 있음. Phase 6에서 PostToolUse hook이 이 역할을 담당하도록 설계됨.
- **Trigger to evaluate**: Phase 6 hook 구현 완료 시점.
- **Action**: figure-review SKILL.md의 Layer 3 섹션을 hook 코드로 이전. SKILL.md에는 "hook이 처리함" 요약과 hook.log 포맷 reference만 남김.
- **Owner**: user.
- **Related**: `skills/figure-review/SKILL.md`의 "Layer 3" 섹션 말미 [hook-owned in Phase 6] 마커.

### [ ] #4: REVIEW_LOG.md aggregate 자동화
- **Raised**: 2026-04-15 (Phase 1 Turn 2)
- **Context**: 현재 subagent가 매 review 시 hook.log를 훑어 반복 패턴을 REVIEW_LOG에 수동 승격.
- **Trigger to evaluate**: hook.log가 일평균 100+ 엔트리로 성장했을 때.
- **Question**: Hook 안에 가벼운 dedup/aggregate 로직을 박아 hook.log 사이즈 자체를 줄일 것인가, 아니면 subagent의 승격 로직을 더 정교하게 할 것인가?
- **Owner**: user.
- **Related**: `skills/figure-review/SKILL.md`의 Step 0-4, hook.log 포맷.

### [ ] #5: CLAIMS Revision history 필수화 여부
- **Raised**: 2026-04-15 (Phase 1 Turn 2 — Turn 1에서도 언급됨)
- **Context**: 현재 Revision history는 optional. Audit-trail 중요성이 커지면 required 승격.
- **Trigger to evaluate**: Phase 6 이후 첫 논문 투고 직전 또는 reviewer 요청 시.
- **Action**: Required로 승격 시 CLAIMS.schema.md v1.1 발표 (optional → required는 non-breaking).
- **Owner**: user.

### [ ] #P1-P4: Claude Code hook/subagent docs 확인 (Phase 6 precondition)
- **Raised**: 2026-04-15 (Dry review #2)
- **Context**: Phase 6 구현이 Claude Code 공식 hook + subagent mechanism에 의존. 현재 내 추정 기반 설계. Docs 확인으로 실제 spec 확정 필요.
- **Action**:
  - P1: PostToolUse hook config 파일 위치 + trigger semantics
  - P2: Hook이 figure-implement "완료" 감지 방법
  - P3: Subagent invocation API (Task tool 여부)
  - P4: Subagent에서 AskUserQuestion 가능 여부
- **Owner**: user (또는 Claude WebFetch로 진행).
- **Trigger**: Phase 6 kickoff 전 필수.

### [x] #SMOKE-AUTO-INVOKE: figure-implement → figure-review auto-invoke soft enforcement 실패 확인
- **Raised**: 2026-04-15 (Phase 1-5 smoke test Level 3)
- **Closed**: 2026-04-15 (Phase 6 Turn 2 Session C)
- **Resolution**: figure-implement Step N을 Task tool dispatch로 격상. `Agent(subagent_type="figure-reviewer", model=model_choice, ...)` 형태로 hard enforcement. Dynamic model selection (opus for figure/multimodal, sonnet otherwise) 포함. Hook enforcement (Turn 3)는 #3에서 별도 추적.

### [x] #R1/R5/R7: Phase 6 구현 위험 체크리스트
- **Raised**: 2026-04-15 (Dry review #2)
- **Closed**: 2026-04-15 (Phase 6 Turn 2 Session D)
- **Resolution**:
  - R1: PostToolUse hook은 tool 단위 matcher (Write/Edit). 스킬 완료 감지 불가 → Task tool dispatch로 해결 (#P2 참조).
  - R5: Subagent는 AskUserQuestion 없음 → REVIEW_LOG Action items에 질문 기록, main agent가 user에 위임 (#P4 참조).
  - R7: Multi-session 계획 실행 중 — Turn 1 (pre-check+docs), Turn 2 (Session A-D legacy merge + schema), Turn 3 (hook), Turn 4 (Layer 4 multimodal test).

### [ ] #MIN-6: Phase 5.5 Minor 정합성 이슈 6개
- **Raised**: 2026-04-15 (Dry review #2)
- **항목**:
  - A: FIGURE_PLAN.schema Panel `Role` 필드 — figure-plan SKILL Step 2-2에도 반영
  - E: CLAIMS_template 주석에 `Source script` exploratory optional 명시
  - F: figure-implement의 `save_panel()` R 코드 — draft Status 시 Selected at 비우기
  - G: session-resume 3줄 요약에서 multi non-terminal jobs 표기 방법
  - J: figure-review가 empty placeholder FIGURE_PLAN (figure-plan-step0 마커 부재) 처리 명시
  - L: session-resume STORY.md refactor 후 "마지막 section" 해석 구체화
- **Action**: 실사용 중 터지면 개별 수정. 선제 수정 불필요.
- **Owner**: user.

### [ ] #ENF: Validation enforcer 부재 보완
- **Raised**: 2026-04-15 (Dry review #2, self-bias #3)
- **Context**: Schema rule들이 현재 아무도 체크 안 함. Hook (Phase 6)이 enforcer 될 예정이지만 그 전까지 gap.
- **Option**: 경량 `/validate-governance` skill — bash+grep 기반 수동 호출. CLAIMS banned verb, JOB_LOG enum, FIGURE_PLAN 필수 필드 정도만.
- **Trigger to evaluate**: Phase 6 착수 지연 시, 또는 첫 schema violation이 user를 혼란시킬 때.
- **Owner**: user (결정).

### [ ] #EXP: Exploratory mode 악용 방지
- **Raised**: 2026-04-15 (Dry review #2, self-bias #4)
- **Context**: `figure-plan --exploratory` 가 "쉬운 길"로 남용되면 manuscript gate 무의미해짐. 첫 리뷰의 "rating theater" 위험이 mode 형태로 재발할 수 있음.
- **Option**:
  - (a) Exploratory draft에 "30일 이상 경과 시 manuscript mode로 승격 권고" soft gate
  - (b) figure-review에서 exploratory-status claim이 FIGURE_PLAN의 main figure에 있으면 WARN 승격
- **Trigger**: 첫 manuscript 작성 단계 진입 시점에 재평가.
- **Owner**: user.

### [ ] #6: Strength rating 4-tag의 월간 review 필요성 재평가
- **Raised**: 2026-04-15 (Phase 1, 첫 review 때 지적)
- **Context**: 4-tag 전환으로 rating theater 위험은 낮아졌으나, 프로젝트 framing 변화 시 tag drift는 여전히 발생 가능.
- **Trigger to evaluate**: 첫 manuscript 투고 후 reviewer comment로 framing 수정이 요구된 시점.
- **Question**: Tag 재검토를 scheduled-task로 자동화할지, figure-review Layer 1에 "tag 재확인" 체크 추가할지.
- **Owner**: user.

---

## Closed

- #-2 (init-project Phase 4 원칙) — Phase 5.5에서 해결
- #-3 (figure-implement/assemble schema reference) — Phase 5.5에서 해결
- #0 (figure-review auto-invoke 라인) — Phase 5.5에서 해결 (slash command 수준)
- #SMOKE-AUTO-INVOKE — Phase 6 Turn 2 Session C에서 완전 해결. Task tool dispatch + dynamic model selection.
- #R1/R5/R7 — Phase 6 Turn 2에서 전부 해결. 상세는 각 항목 참조.
- #P1 (hook config 위치) — `~/.claude/settings.json` 또는 `.claude/settings.json`, JSON 포맷 확정 (Phase 6 Turn 1 pre-check)
- #P2 (hook trigger semantics) — tool 단위 matcher 기반 확정. "스킬 완료 감지"는 불가, "Write/Edit/Bash 단위 매칭"이 실제 메커니즘.
- #P3 (subagent invocation) — Task tool (= Agent tool 2.1.63 rename) 확정. `~/.claude/agents/` + frontmatter YAML 포맷.
- #P4 (AskUserQuestion in subagent) — subagent는 기본 독립 동작 가정. figure-reviewer subagent는 AskUserQuestion 제외, 모호한 질문은 Action items로 REVIEW_LOG에 남기고 main agent가 user에 위임.
- Schema path migration (Turn 2 Session D) — PANEL_REGISTRY, REVIEW_LOG, OUTPUTS 경로를 docs_figure/로 업데이트 완료.

---

## Meta

- 이 파일은 `~/claude-governance/PHASE_6_TODO.md`에 위치. 설치본(`~/.claude/`)에는 포함 안 함 — 개발 문서이므로.
- Phase 진행 중 새로 미뤄지는 이슈는 `## Open` 하단에 append.
- Phase 6 kickoff 외에도 주요 phase transition 시점(Phase 2→3, 3→4 등)에 훑어볼 것.
