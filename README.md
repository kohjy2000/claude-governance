# Claude Governance System

Computational biology 프로젝트를 위한 Claude Code 거버넌스 체계.

## Quick Start

```bash
# 1. Clone
git clone <repo-url> ~/claude-governance

# 2. Install
bash ~/claude-governance/setup.sh

# 3. Configure HPC (optional)
cd <project-dir> && claude
# then: /bootstrap-system ~/claude-governance

# 4. Start a project
# /init-project
```

## Architecture

```
3-Layer Governance
├── Layer 1: Global (~/.claude/CLAUDE.md)     ← 행동원칙, 세션 프로토콜
├── Layer 2: Project (<project>/CLAUDE.md)    ← 프로젝트 고유 규칙
└── Layer 3: Documentation (<project>/docs/)  ← SSOT 문서 5종
```

## Skills (8 + 1)

| Skill | Phase | Purpose |
|-------|-------|---------|
| `/bootstrap-system` | Setup | 새 시스템에 체계 설치 + HPC 설정 |
| `/init-project` | Setup | 새 프로젝트 scaffolding |
| `/session-resume` | Daily | 세션 재개 시 context 복원 |
| `/figure-plan` | Figure | Phase 1: narrative → design doc (P1-P16) |
| `/figure-implement` | Figure | Phase 2: design doc → code (C1-C8 + V1-V9) |
| `/figure-review` | Figure | Phase 3: top-down review (Layer 0-3) |
| `/figure-assemble` | Figure | Phase 4: panels → assembled figure (journal specs) |
| `/submit-job` | HPC | SLURM 제출 + 자동 로깅 |
| `/check-status` | HPC | Job 상태 확인 + 문서 업데이트 |

## SSOT Documents (per project)

| Doc | Purpose |
|-----|---------|
| `docs/README.md` | 진행 상태 |
| `docs/STORY.md` | 배경, 버그, 가설, 의사결정 |
| `docs/DATA_MAP.md` | 모든 경로, 파라미터, 환경 |
| `docs/PIPELINE.md` | Step별 실행 계획 |
| `docs/JOB_LOG.md` | SLURM 제출/완료/실패 기록 |

## Figure Methodology (P1-P16)

```
Structural (P1-P7)
P1  FUNNEL      scope(P_{i+1}) <= scope(P_i)
P2  EVIDENCE    dependency DAG = panel order
P3  DATA-ONLY   every element maps to data
P4  EXHAUSTIVE  show N_total before K_selected
P5  VARIANTS    >= 2 visualizations per panel
P6  SSOT        all paths in registry
P7  CONSISTENT  one palette, zero local overrides

Visual Storytelling (P8-P13)
P8  FOCUS       ONE focal point per panel (color/bold vs grey/alpha)
P9  INK         remove non-data elements
P10 GLANCE      message in <5 seconds without caption
P11 ENCODE      visual channel first (position > color > size > shape > text)
P12 TYPE        Helvetica 5-7pt body, 8pt bold lowercase panel labels
P13 BREATHE     generous margins, max ~20 axis items

Content & Logic (P14-P16)
P14 CLAIM-MATCH visual pattern supports the stated claim
P15 LOGIC-FLOW  panel sequence builds an argument
P16 RESTRAINT   no overclaiming (NS≠trend, association≠causation)
```

## Figure Pipeline

```
/figure-plan → Design Doc → /figure-implement → panels/ → /figure-review → fix → /figure-assemble → assembled/
```

## Memory Management

- `MEMORY.md` = 인덱스만 (< 50줄)
- 주제별 파일: `tscc-patterns.md`, `figure-patterns.md`, `project-prefs.md`
- 상태/사실 → docs/ (SSOT). Memory에는 패턴/교훈만.

## Repo Structure

```
claude-governance/
├── README.md
├── setup.sh                          ← Quick install script
├── global/
│   └── CLAUDE_portable.md            ← Global rules template
├── skills/
│   ├── bootstrap-system/SKILL.md
│   ├── init-project/SKILL.md
│   ├── session-resume/SKILL.md
│   ├── figure-plan/SKILL.md
│   ├── figure-implement/SKILL.md
│   ├── figure-review/SKILL.md
│   ├── figure-assemble/SKILL.md
│   ├── submit-job/SKILL.md
│   └── check-status/SKILL.md
└── blueprints/templates/
    ├── CLAUDE_template.md
    ├── README_template.md
    ├── STORY_template.md
    ├── DATA_MAP_template.md
    ├── PIPELINE_template.md
    └── JOB_LOG_template.md
```

## For Non-HPC Systems

```bash
bash setup.sh --no-hpc
```

HPC 섹션 없이 설치됩니다. `/submit-job`과 `/check-status`는 SLURM이 없는 환경에서는 사용하지 마세요.
