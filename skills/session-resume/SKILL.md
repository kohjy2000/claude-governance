---
name: session-resume
description: Resume a session by loading project context from SSOT docs and checking active jobs
allowed-tools: Read, Bash, Glob, Grep
---

# /session-resume — 세션 재개 프로토콜

프로젝트 context를 자동 복원하여 이전 작업을 이어갈 수 있게 한다.

## 실행 순서

### 1. CLAUDE.md 로드
현재 디렉토리 또는 $ARGUMENTS 경로에서 CLAUDE.md를 읽는다.
없으면 유저에게 프로젝트 경로를 물어본다.

### 2. README.md — 현재 상태
`docs/README.md`를 읽어서 현재 진행 단계를 파악.

### 3. STORY.md — 최근 이슈
`docs/STORY.md`의 마지막 섹션(최근 버그, 의사결정)을 읽는다.
전체를 읽되 요약만 출력.

### 4. DATA_MAP.md — 경로 확인
`docs/DATA_MAP.md`를 읽어서 base paths와 핵심 경로를 파악.
모든 경로를 실제로 존재하는지 검증할 필요는 없다 (너무 느림).

### 5. JOB_LOG.md — 최근 Job
`docs/JOB_LOG.md`의 마지막 5개 entry를 읽는다.
RUNNING 상태인 job이 있으면 다음 단계에서 확인.

### 6. Active Jobs 상태 확인
RUNNING job이 있으면:
```bash
sacct -j <JOB_ID> --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS --noheader
```
완료되었으면 → JOB_LOG.md 업데이트 제안.
실패했으면 → 로그 파일 tail 후 원인 파악.

### 7. 요약 출력

아래 포맷으로 **3줄 요약** 출력:

```
--- Session Resume ---
현재 상태: [README.md 기반 한 줄 요약]
진행 중인 Job: [RUNNING job이 있으면 ID와 상태, 없으면 "없음"]
다음 할 일: [README.md / PIPELINE.md 기반 next step]
---
```

## 주의사항
- 요약은 반드시 **3줄 이내**. 길게 설명하지 마.
- Job 상태가 바뀌었으면 업데이트를 **제안**만 하고 자동 실행하지 마.
- STORY_SUMMARY 파일이 있으면 추가로 참고하되, 요약에 반영은 선택적.
