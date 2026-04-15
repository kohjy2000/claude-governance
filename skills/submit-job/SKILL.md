---
name: submit-job
description: Submit a SLURM job and automatically log to JOB_LOG.md per schema v1.0. Initial Status=SUBMITTED; check-status handles transitions.
allowed-tools: Read, Edit, Bash, Glob
---

# /submit-job — SLURM Job 제출 + 자동 로깅

`$ARGUMENTS`: 제출할 스크립트 경로 또는 sbatch 명령어

**Schema reference**: `~/.claude/blueprints/schemas/JOB_LOG.schema.md`. Config 포맷, Status enum, Row 구조는 모두 schema 준수.

---

## Step 1: 사전 확인

1. `docs/DATA_MAP.md`에서 conda 환경과 HPC 리소스 확인.
2. 제출할 스크립트 읽어서 내용 파악.
3. `squeue -u $USER` 로 현재 큐 상태 확인.
4. `docs/JOB_LOG.md` 읽어 다음 Step 번호 결정 (이전 행 기반).
   - 재제출이면 같은 Step 번호 + 접미사 (`3` → `3b` → `3c`).

---

## Step 2: 제출 정보 정리

유저에게 확인:
- **Script**: 경로
- **Step number**: 신규 또는 재제출 (`3b`)
- **Partition/QOS/Time**: required config keys (schema `enum.ConfigKeys.required`)
- **Optional config**: cpus, mem, conda, array, gpu, nodes 중 해당되는 것
- **Notes**: 이 job의 목적 한 줄

---

## Step 3: 제출

유저 승인 후 `sbatch` 실행. Job ID 캡처.

```bash
JOB_ID=$(sbatch <script> | awk '{print $NF}')
echo "Submitted: $JOB_ID"
```

Array job이면 Job ID를 array spec과 함께 기록 (`12345_[0-9]`).

**검증**: Job ID가 `jobid.pattern` (schema) 매칭하는지 확인. 매칭 안 하면 STOP.

---

## Step 4: JOB_LOG.md append (schema 준수)

`docs/JOB_LOG.md` 테이블 마지막에 새 row 추가:

```
| <Step> | <JOB_ID> | <YYYY-MM-DD HH:MM> | SUBMITTED | <config string> | <script_path> | <notes> |
```

**Config string 생성 규칙** (schema):
- Required keys 먼저: `partition=X; qos=Y; time=T`
- Optional keys 뒤에 순서대로: `cpus=N; mem=M; conda=E; array=...`
- Separator: `; ` (semicolon + single space)

예:
```
partition=rtx3090; qos=hca-ddp302; time=24:00:00; cpus=8; mem=64G; conda=nmf-env
```

**Date**: submit 시각 `date +"%Y-%m-%d %H:%M"` 값. 수정 금지.

---

## Step 5: README.md 업데이트

`docs/README.md`의 Active Jobs 섹션에 새 job 요약 1줄 추가:
```
- Step 3b: Job 12389 (RUNNING pending sacct)
```

---

## 주의사항
- `sbatch` 실행 전 반드시 유저 승인.
- QOS 한도 (그룹 공유) 고려 — 대량 submit 시 경고.
- Job ID 캡처 실패 시 STOP, 수동 기록 안내.
- Required config key 3개 (partition/qos/time) 중 하나라도 빠지면 STOP.

---

## Handoff
- Status 전이 (SUBMITTED → RUNNING → COMPLETED 등)는 `/check-status`가 담당.
- 이 skill은 초기 append만. 이후 Status 수정 금지.
