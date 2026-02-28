---
name: check-status
description: Check SLURM job status and update JOB_LOG.md with results
allowed-tools: Read, Edit, Bash, Glob, Grep
---

# /check-status — Job 상태 확인 + 자동 업데이트

## Step 1: Active Jobs 파악

docs/JOB_LOG.md에서 RUNNING/SUBMITTED 상태인 job들을 추출.

## Step 2: sacct 확인

각 active job에 대해:
```bash
sacct -j <JOB_ID> --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS --noheader
```

## Step 3: 결과 분류

각 job을:
- **COMPLETED** → JOB_LOG.md 상태 업데이트, output 경로 확인
- **FAILED** → 로그 tail (`slurm-<JOB_ID>.out` 마지막 30줄), 원인 요약
- **RUNNING** → 경과 시간 보고
- **PENDING** → 큐 위치 보고

## Step 4: 요약 출력

```
--- Job Status ---
COMPLETED: Job XXXXX (Step N) — 2h 15m, output OK
RUNNING:   Job YYYYY (Step M) — 45m elapsed / 24h limit
FAILED:    Job ZZZZZ (Step K) — OOM at 32GB, 추천: mem=64GB로 재제출
---
```

## Step 5: 문서 업데이트 제안

- COMPLETED → JOB_LOG.md 업데이트 + README.md step 진행 반영 제안
- FAILED → 원인 + 수정안 제시

**유저 승인 후에만** 문서를 수정한다.

## 주의사항
- 간결하게. 문제 없는 job은 한 줄로.
- FAILED job은 원인과 수정안을 반드시 포함.
