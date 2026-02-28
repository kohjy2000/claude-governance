---
name: submit-job
description: Submit a SLURM job and automatically log it to JOB_LOG.md
allowed-tools: Read, Edit, Bash, Glob
---

# /submit-job — SLURM Job 제출 + 자동 로깅

$ARGUMENTS: 제출할 스크립트 경로 또는 sbatch 명령어

## Step 1: 사전 확인

1. docs/DATA_MAP.md에서 conda 환경과 TSCC 리소스 확인
2. 제출할 스크립트를 읽어서 내용 파악
3. `squeue -u $USER` 로 현재 큐 상태 확인

## Step 2: 제출 정보 정리

유저에게 확인:
- **Script**: 어떤 스크립트를 제출하는지
- **Partition/QOS**: 어떤 리소스를 쓰는지
- **Array**: array job인지
- **Conda**: 어떤 환경을 쓰는지

## Step 3: 제출

유저 승인 후 `sbatch` 실행. Job ID를 캡처.

## Step 4: JOB_LOG.md 자동 기록

docs/JOB_LOG.md에 아래 형식으로 추가:

```
| Step N | <JOB_ID> | <DATE> | SUBMITTED | partition=X, qos=Y, cpus=Z, mem=W, time=T, conda=E | <script_path> | <notes> |
```

## Step 5: README.md 업데이트

docs/README.md의 Active Jobs 섹션에 새 job 추가.

## 주의사항
- sbatch 실행 전 반드시 유저 승인을 받을 것.
- QOS 한도는 그룹 공유이므로 대량 submit 시 경고.
- Job ID 캡처 실패 시 수동 기록 안내.
