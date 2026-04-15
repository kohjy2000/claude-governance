# CLAUDE.md — {{PROJECT_NAME}}

## SSOT 문서

| 문서 | 경로 | 용도 |
|------|------|------|
| README | `docs/README.md` | 진행 상태 |
| STORY | `docs/STORY.md` | 배경, 버그, 가설, 내러티브 |
| CLAIMS | `docs/CLAIMS.md` | 논문-facing 사실 (숫자, statement) |
| DATA_MAP | `docs/DATA_MAP.md` | 모든 경로/파라미터 |
| PIPELINE | `docs/PIPELINE.md` | Step별 실행 계획 |
| JOB_LOG | `docs/JOB_LOG.md` | SLURM 기록 |

**작업 시작 전**: DATA_MAP.md → README.md 순서로 읽을 것. Figure 작업은 CLAIMS.md 추가.

## 프로젝트 속성

- **목적**: {{PURPOSE}}
- **가설**: {{HYPOTHESES}}
- **데이터**: {{DATA_DESCRIPTION}}

## Locked Parameters

{{LOCKED_PARAMS or "없음"}}

## Conda 환경

| 환경 | 용도 |
|------|------|
| {{ENV_NAME}} | {{ENV_PURPOSE}} |

## 실행 환경 / HPC 리소스

{{HPC_BLOCK or "Local execution (HPC 없음)"}}

<!--
HPC_BLOCK 예시:
- Account: `ddp302`, GPU QOS: `hca-ddp302`, CPU QOS: `hcp-ddp302`
- Partitions: {{PARTITIONS}}
- Work dir: {{WORK_DIR}}
-->
