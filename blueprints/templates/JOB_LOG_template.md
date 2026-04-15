# {{PROJECT_NAME}} — Job Log

> **Schema**: `~/.claude/blueprints/schemas/JOB_LOG.schema.md`
> **Append-only**: 기존 row 삭제 금지. Status transition만 update.
> **Owner**: `submit-job` (row append, Status=SUBMITTED), `check-status` (Status transition).

| Step | Job ID | Date | Status | Config | Script | Notes |
|------|--------|------|--------|--------|--------|-------|

<!--
Config 포맷: `partition=X; qos=Y; time=T` 필수 + `cpus, mem, conda, array, gpu, nodes` optional
Status enum: SUBMITTED | PENDING | RUNNING | COMPLETED | FAILED | CANCELLED | TIMEOUT
재제출 시 Step 접미사 사용: 3 → 3b → 3c
-->
