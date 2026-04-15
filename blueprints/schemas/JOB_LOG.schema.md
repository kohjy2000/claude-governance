# JOB_LOG.md Schema v1.0

> **Primary consumers**: `submit-job` (row append), `check-status` (status update),
> `session-resume` (active job detection).
> **Format**: Markdown table, LLM-read. No parser shipped.
> **Drift prevention**: 세 skill 모두 이 파일을 참조. 포맷 변경 시 먼저 여기 수정.

---

## Machine-readable enum lines

```
enum.Status       : SUBMITTED | PENDING | RUNNING | COMPLETED | FAILED | CANCELLED | TIMEOUT
enum.ConfigKeys.required : partition | qos | time
enum.ConfigKeys.common   : cpus | mem | conda | array | gpu | nodes
config.separator  : ;   (semicolon + single space between pairs)
date.format       : YYYY-MM-DD HH:MM   (ISO 8601, minute precision)
jobid.pattern     : ^\d+(_\d+|_\*|\[\d+-\d+%?\d*\])?$
```

---

## File Identity
- Path: `<project_root>/docs/JOB_LOG.md`
- One file per project.
- Format: Markdown table with fixed columns.

---

## Row Structure

```
| Step | Job ID | Date | Status | Config | Script | Notes |
```

| Column | Required | Format | Owner |
|--------|----------|--------|-------|
| Step | yes | integer 또는 `Nb`, `Nc` (재제출 시 같은 step 아래 소문자 접미사) | submit-job |
| Job ID | yes | `jobid.pattern` 매칭 | submit-job |
| Date | yes | `date.format`. Submit 시각. **수정 금지** | submit-job |
| Status | yes | `enum.Status` | submit-job initial, check-status transition |
| Config | yes | `key=value; key=value` (separator = `; `) | submit-job |
| Script | yes | project-relative path to submitted script | submit-job |
| Notes | optional | free text, 짧게. Status transition 이벤트 append 가능 | submit-job + check-status |

Array job은 `Job ID` 필드에 `123456_[0-9]` 형태로 기록. 개별 task 단위 추적 안 함 (필요 시 별도 array log 고려 — 현재 defer).

---

## Config 필드 규약

Submit-job이 기록하는 `Config` 셀은 `; ` 구분 key=value 페어.

**Required keys** (`enum.ConfigKeys.required`):
- `partition=<name>`
- `qos=<name>`
- `time=<limit>` (예: `time=24:00:00`)

**Common optional keys** (`enum.ConfigKeys.common`):
- `cpus=<N>` (또는 `cpus-per-task`)
- `mem=<size>` (예: `mem=64G`)
- `conda=<env_name>`
- `array=<spec>` (예: `array=0-9`)
- `gpu=<count or type>`
- `nodes=<N>`

예:
```
partition=rtx3090; qos=hca-ddp302; time=24:00:00; cpus=8; mem=64G; conda=nmf-env
```

---

## Status Transition Rules

```
SUBMITTED ──┬──► PENDING ──► RUNNING ──┬──► COMPLETED
            │                           │
            │                           ├──► FAILED
            │                           ├──► TIMEOUT
            │                           └──► CANCELLED
            └────► (direct failure before queue) ──► FAILED
```

- `submit-job`: 최초 row append. Status=`SUBMITTED`.
- `check-status`: 기존 row의 Status를 sacct 결과 기반으로 update.
- Status가 terminal state (`COMPLETED`, `FAILED`, `TIMEOUT`, `CANCELLED`)가 되면 Notes에 `→COMPLETED@YYYY-MM-DD HH:MM` 같이 전이 시각 append.
- Terminal state 이후 같은 row Status 수정 금지 (drift 방지). 재제출 시 새 row (Step은 `Nb` 등).

---

## Validation Rules

Well-formed JOB_LOG:
1. 테이블 header가 위 Row Structure와 정확히 일치.
2. 모든 row가 7개 column (`| ... |`).
3. Job ID가 `jobid.pattern`에 매칭.
4. Status가 `enum.Status`에서.
5. Date가 `date.format`에 매칭.
6. Config에 `enum.ConfigKeys.required` 3개 모두 존재.
7. Terminal state row의 Status는 변경 이력이 Notes에 기록됨 (soft rule — WARN, not FAIL).

Stale:
- 한 row가 SUBMITTED/PENDING/RUNNING 상태로 24시간 넘게 방치 → `session-resume`에서 WARN.

---

## Append-only principle

- Row 삭제 금지. 실수 submit도 기록 유지 + Notes에 `cancelled/error` 명시.
- Status transition 외에는 기존 row 수정 금지.
- Config/Script 오타 발견 시 같은 row 수정 허용 (이벤트 아니라 정정). Notes에 `corrected <field>` append.

---

## Re-submission pattern

Step 3이 FAILED → 수정해서 재제출 → 같은 Step 번호 + 접미사:

| Step | Job ID | Date | Status | ... |
|------|--------|------|--------|-----|
| 3 | 12345 | 2026-04-14 10:00 | FAILED | ... → OOM at 32G |
| 3b | 12389 | 2026-04-14 14:30 | RUNNING | ... mem=64G 로 증액 |

두 row 모두 보존.

---

## Deliberate non-features

- **Python parser**: 안 만듦. Skill은 markdown table 직접 읽음.
- **Array task 단위 로깅**: job ID 수준에서만 추적. Task 단위는 defer.
- **Cost tracking** (CPU-hr, $): Phase 7 이후 재평가.
- **Automatic re-submission**: 항상 user 확인.
