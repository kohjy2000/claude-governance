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
- **Context**: 현재 `~/code/claude-governance/`는 local git repo만 존재. GitHub에 push 안 됨 (SSH 키 미등록). Cross-phase constraint #7 ("GitHub = source of truth")이 문서상으로만 선언됨.
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

### [ ] #-3: figure-implement / figure-assemble SKILL에 Phase 5 schema reference 추가
- **Raised**: 2026-04-15 (Phase 5)
- **Context**: Phase 5에서 FIGURE_PLAN.schema.md, PANEL_REGISTRY.schema.md, REVIEW_LOG.schema.md 작성됨. figure-plan과 figure-review에는 reference line 추가했으나 figure-implement와 figure-assemble은 Phase 1-5에서 건드리지 않음.
- **Trigger to evaluate**: Phase 6 kickoff, 또는 figure-implement/assemble이 schema 불일치로 오동작 시.
- **Action**: 두 SKILL의 Handoff 섹션에 `Schema: ~/.claude/blueprints/schemas/{FIGURE_PLAN|PANEL_REGISTRY}.schema.md` 참조 한 줄씩.
- **Owner**: user.

### [ ] #-2: init-project 스킬 Phase 4 원칙 반영
- **Raised**: 2026-04-15 (Phase 4)
- **Context**: `/init-project`는 신규 프로젝트 생성 시 `docs/`만 만든다. `outputs/`는 `/init-output` 호출로만 생성 (의식적 단계). 현재 init-project SKILL이 이 원칙을 명시하지 않음.
- **Trigger to evaluate**: Phase 5 kickoff.
- **Action**: `skills/init-project/SKILL.md`에 "outputs/ 생성 안 함. 필요 시 /init-output 호출" 한 줄 추가.
- **Owner**: user.

### [ ] #0: figure-implement 스킬에 figure-review auto-invoke 라인 추가
- **Raised**: 2026-04-15 (Phase 1 Turn 2, Q1 결정 이후)
- **Context**: figure-review를 figure-implement 완료 시 자동 호출하기로 결정. figure-review 쪽 스펙은 Turn 2에서 반영됨. figure-implement SKILL.md에 호출 라인 추가는 Phase 2 범위로 보류.
- **Trigger to evaluate**: Phase 2 kickoff.
- **Action**: `skills/figure-implement/SKILL.md` 마지막 step에 "/figure-review --auto 호출" 지시 추가.
- **Owner**: user.

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

### [ ] #6: Strength rating 4-tag의 월간 review 필요성 재평가
- **Raised**: 2026-04-15 (Phase 1, 첫 review 때 지적)
- **Context**: 4-tag 전환으로 rating theater 위험은 낮아졌으나, 프로젝트 framing 변화 시 tag drift는 여전히 발생 가능.
- **Trigger to evaluate**: 첫 manuscript 투고 후 reviewer comment로 framing 수정이 요구된 시점.
- **Question**: Tag 재검토를 scheduled-task로 자동화할지, figure-review Layer 1에 "tag 재확인" 체크 추가할지.
- **Owner**: user.

---

## Closed

(아직 없음)

---

## Meta

- 이 파일은 `~/code/claude-governance/PHASE_6_TODO.md`에 위치. 설치본(`~/.claude/`)에는 포함 안 함 — 개발 문서이므로.
- Phase 진행 중 새로 미뤄지는 이슈는 `## Open` 하단에 append.
- Phase 6 kickoff 외에도 주요 phase transition 시점(Phase 2→3, 3→4 등)에 훑어볼 것.
