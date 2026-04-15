---
name: session-resume
description: Resume a session by loading project context from SSOT docs and checking active jobs. v1.2 note — CLAIMS.md is deliberately NOT read here (on-demand by figure-plan/review).
allowed-tools: Read, Bash, Glob, Grep
---

# /session-resume — 세션 재개 프로토콜

프로젝트 context를 자동 복원하여 이전 작업을 이어갈 수 있게 한다. 3줄 요약 원칙 유지.

**v1.2 의도적 제외**: CLAIMS.md는 여기서 읽지 않는다. 이유: CLAIMS는 detail-heavy claim registry이고 session 재개 시 필요한 "지금 어디까지 왔나" 파악에 바로 쓰이지 않는다. Figure 작업을 재개해야 할 때는 `/figure-plan`이나 `/figure-review`가 on-demand로 CLAIMS를 읽음.

---

## 실행 순서

### 1. CLAUDE.md 로드
현재 디렉토리 또는 `$ARGUMENTS` 경로에서 CLAUDE.md 읽는다. 없으면 유저에게 프로젝트 경로 질문.

### 2. README.md — 현재 상태
`docs/README.md`에서 현재 진행 단계 파악.

### 3. STORY.md — 최근 이슈
`docs/STORY.md`의 마지막 섹션 (Key Decisions, Pivots, Bugs & Resolutions 최근 entry) 읽기. 전체 읽되 요약만 출력.

### 4. DATA_MAP.md — 경로 확인
`docs/DATA_MAP.md`에서 base paths와 핵심 경로 파악. 실제 존재 여부 검증은 skip (너무 느림).

### 5. JOB_LOG.md — 최근 Job
`docs/JOB_LOG.md`의 마지막 5개 entry 읽기. Terminal state 아닌 (SUBMITTED/PENDING/RUNNING) 있으면 Step 6에서 확인. Schema: `~/.claude/blueprints/schemas/JOB_LOG.schema.md`.

### 6. Active Jobs 상태 확인
Non-terminal job이 있으면:
```bash
sacct -j <JOB_ID> --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS --noheader
```
- 완료 → JOB_LOG.md Status 업데이트 제안.
- 실패 → 로그 tail 후 원인 파악.

### 7. 요약 출력

정확히 **3줄 요약**:

```
--- Session Resume ---
현재 상태: [README.md 기반 한 줄 요약]
진행 중인 Job: [RUNNING/SUBMITTED job ID + 상태, 없으면 "없음"]
다음 할 일: [README.md / PIPELINE.md 기반 next step]
---
```

---

## 주의사항
- 요약은 **3줄 이내**. 길게 설명 금지.
- Job 상태가 바뀌었으면 업데이트 **제안**만, 자동 실행 금지.
- **CLAIMS.md 읽지 않음** (의도적 제외). Claim 파악 필요 시 `/figure-plan`, `/figure-review`가 담당.
- STORY_SUMMARY 파일이 있으면 참고 가능, 요약 반영은 선택.

---

## v1.2에서 바뀐 점

| 영역 | Before | After |
|-----|-------|-------|
| SSOT read 대상 | CLAUDE, README, STORY, DATA_MAP, JOB_LOG | 동일 (+CLAIMS 명시적 제외) |
| 3줄 요약 | 유지 | 유지 |
| JOB_LOG 해석 | Status 컬럼 자유 읽기 | Schema v1.0 enum.Status 값으로 해석 |
