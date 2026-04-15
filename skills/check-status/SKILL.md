---
name: check-status
description: Poll SLURM and transition JOB_LOG.md row Status per schema v1.0. Does NOT modify Date/Config/Script. Appends transition event to Notes.
allowed-tools: Read, Edit, Bash, Glob, Grep
---

# /check-status — Job 상태 확인 + JOB_LOG Status transition

**Schema reference**: `~/.claude/blueprints/schemas/JOB_LOG.schema.md`.
이 skill은 **Status 컬럼만** 수정. Date/Job ID/Config/Script는 **수정 금지**.

---

## Step 1: Active Jobs 파악

`docs/JOB_LOG.md` 읽고 non-terminal Status인 row 추출:
- `SUBMITTED`, `PENDING`, `RUNNING`

Terminal (`COMPLETED`, `FAILED`, `TIMEOUT`, `CANCELLED`) 행은 건너뜀.

---

## Step 2: sacct 확인

각 active job:
```bash
sacct -j <JOB_ID> --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS --noheader
```

Output의 `State` 필드를 schema `enum.Status` 값으로 매핑:
- `PD` → PENDING
- `R` → RUNNING
- `CD` → COMPLETED
- `F` → FAILED
- `TO` → TIMEOUT
- `CA` → CANCELLED
- 기타 → FAILED + Notes에 원 state 기록

---

## Step 3: 결과 분류 (stdout 출력, 한 줄씩)

```
COMPLETED: Job 12389 (Step 3b) — 2h 15m, output OK
RUNNING:   Job 12500 (Step 5)  — 45m / 24h limit
FAILED:    Job 12301 (Step 4)  — OOM at 32G; slurm-12301.out tail: "...killed"
PENDING:   Job 12450 (Step 6)  — queue position 3
```

FAILED의 경우 `slurm-<JOB_ID>.out` 마지막 30줄 확인해 원인 추정 후 수정안 1줄 제시.

---

## Step 4: JOB_LOG.md Status transition (append-only 준수)

유저 승인 후, 각 Status 변경이 필요한 row에 대해:

### 4-1. Status 셀 update
- 현재 Status → 새 Status로 **그 셀만** 교체.
- Date, Job ID, Config, Script 건들지 않음.

### 4-2. Notes에 transition event append
Terminal state 진입 시 기존 Notes 뒤에 ` →{STATUS}@{YYYY-MM-DD HH:MM}` 추가:

기존:
```
| 3b | 12389 | 2026-04-14 14:30 | RUNNING | ... | ... | mem=64G로 증액 |
```
After COMPLETED:
```
| 3b | 12389 | 2026-04-14 14:30 | COMPLETED | ... | ... | mem=64G로 증액 →COMPLETED@2026-04-14 17:45 |
```

Non-terminal (PENDING→RUNNING 등)은 Notes 수정 불필요.

### 4-3. 재제출 안내
FAILED → 수정안이 있으면 user에게 `/submit-job`으로 재제출 제안. Step 번호는 접미사 (`3b` → `3c`).

---

## Step 5: README.md 업데이트 제안

COMPLETED된 job은 README의 Active Jobs 섹션에서 제거 제안.
FAILED는 제거 대신 "Step N — FAILED, 재제출 검토 중"으로 표시 제안.

**유저 승인 후에만** 수정.

---

## 주의사항
- 간결하게. 문제 없는 job은 한 줄.
- FAILED는 원인 + 수정안 반드시 포함.
- **Schema 위반 감지 시** (Status enum 외 값, 잘못된 Config 포맷 등) STOP하고 schema 참조하라고 user에게 보고.
- Terminal state → non-terminal state 역전이 금지 (schema 위반). 이런 sacct 결과 나오면 hardware/scheduler 이상 가능, user에게 수동 확인 요청.

---

## Handoff
- 다음 단계 액션은 JOB_LOG에 기록된 Notes + stdout 요약 기반.
- 재제출은 `/submit-job`, 분석 자체의 script 수정은 별도 작업.
