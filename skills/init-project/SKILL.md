---
name: init-project
description: Initialize a new research project with standard governance structure (CLAUDE.md + docs/ SSOT)
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /init-project — 새 프로젝트 초기 세팅

$ARGUMENTS 에 프로젝트 경로가 주어지면 해당 경로를 사용. 없으면 현재 디렉토리.

## Step 1: 프로젝트 정보 수집

아래 항목을 유저에게 질문:

1. **프로젝트 이름** (예: IAH_immune_tension)
2. **한 줄 목적** (예: "TCGA CRC에서 obs vs sim 비교를 통한 immune selection 탐지")
3. **가설** (H1, H2, ... 형태로)
4. **데이터 소스와 샘플 수** (예: "535 TCGA CRC samples")
5. **사용할 Conda 환경** (이름 + 용도)
6. **Locked parameters** (변경 금지 파라미터가 있는지)
7. **프로젝트 복잡도**: Simple (CLAUDE.md만) vs Advanced (CLAUDE.md + AGENTS.md)

## Step 2: 디렉토리 구조 생성

```
<project_root>/
├── CLAUDE.md
├── docs/
│   ├── README.md
│   ├── STORY.md
│   ├── DATA_MAP.md
│   ├── PIPELINE.md
│   └── JOB_LOG.md
├── 01_data/
├── 02_results/
└── 03_scripts/
```

## Step 3: CLAUDE.md 생성

~/.claude/blueprints/templates/CLAUDE_template.md 를 읽어서 유저 답변으로 채운다.
Global rules (행동원칙, 문서의무 등)는 이미 ~/.claude/CLAUDE.md에 있으므로 **여기서 반복하지 않는다**.
프로젝트 CLAUDE.md에는 프로젝트 고유 내용만:

- SSOT 문서 테이블
- 프로젝트 속성 (목적, 가설, 데이터)
- Locked parameters
- Conda 환경
- (Advanced일 경우) @AGENTS.md import

## Step 4: docs/ 문서 초기화

각 문서를 ~/.claude/blueprints/templates/ 의 템플릿을 기반으로 생성.
빈 칸은 `{{TODO}}` 로 남기고 유저가 채울 수 있도록.

### README.md
```markdown
# <PROJECT_NAME> — 진행 현황
Last updated: <DATE>

## 현재 상태
- [ ] Step 1: {{TODO}}

## Active Jobs
없음
```

### STORY.md
```markdown
# <PROJECT_NAME> — Story & Background

## 프로젝트 개요
{{유저 답변의 한 줄 목적}}

## 가설
{{유저 답변의 가설들}}

## 발견된 버그
없음

## 의사결정 기록
없음
```

### DATA_MAP.md
```markdown
# <PROJECT_NAME> — Data Map (SSOT)

## Base Paths
| 약어 | 경로 |
|------|------|
| PROJECT | <project_root> |
| DATA | <project_root>/01_data |
| RESULTS | <project_root>/02_results |
| SCRIPTS | <project_root>/03_scripts |

## Input Data
{{TODO: 원본 데이터 경로와 설명}}

## Conda 환경
{{유저 답변}}

## Locked Parameters
{{유저 답변 또는 "없음"}}
```

### PIPELINE.md
```markdown
# <PROJECT_NAME> — Pipeline

## Step 1: {{TODO}}
- Input: {{TODO}}
- Output: {{TODO}}
- Script: {{TODO}}
- SLURM: {{TODO}}
```

### JOB_LOG.md
```markdown
# <PROJECT_NAME> — Job Log

| Step | Job ID | Date | Status | Config | Script | Notes |
|------|--------|------|--------|--------|--------|-------|
```

## Step 5: 확인

생성된 파일 목록을 출력하고, 유저에게 검토 요청.
"다음 단계: 데이터 경로를 DATA_MAP.md에 채우고, pipeline을 PIPELINE.md에 정의하세요."
