---
name: init-project
description: Initialize a new research project with standard governance structure. v1.2 adds CLAIMS.md as 6th SSOT doc and explicit "no outputs/ auto-creation" rule.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /init-project — 새 프로젝트 초기 세팅

`$ARGUMENTS`에 프로젝트 경로가 주어지면 해당 경로를 사용. 없으면 현재 디렉토리.

**v1.2 변경사항**:
- `docs/CLAIMS.md` 추가 (6번째 SSOT doc).
- `outputs/` 디렉토리는 자동 생성 **안 함** — 필요 시 `/init-output <type>`.

---

## Step 1: 프로젝트 정보 수집

유저에게 질문:

1. **프로젝트 이름** (예: IAH_immune_tension)
2. **한 줄 목적** (예: "TCGA CRC에서 obs vs sim 비교를 통한 immune selection 탐지")
3. **가설** (H1, H2, ... 형태)
4. **데이터 소스와 샘플 수**
5. **사용할 Conda 환경** (이름 + 용도)
6. **Locked parameters** (변경 금지 파라미터)
7. **Target paper** (선택): "Genome Medicine 2026Q3" 같은 명시적 목표 (없으면 `none`)

Advanced/Simple 분기는 CLAUDE.md diet 이후 기본 Simple (CLAUDE.md만).

---

## Step 2: 디렉토리 구조 생성

```
<project_root>/
├── CLAUDE.md
├── docs/
│   ├── README.md
│   ├── STORY.md
│   ├── CLAIMS.md          # v1.2 신규
│   ├── DATA_MAP.md
│   ├── PIPELINE.md
│   └── JOB_LOG.md
├── 01_data/
├── 02_results/
└── 03_scripts/
```

**`outputs/`는 만들지 않는다.** Figure 작업 시작 시 `/init-output figures`, writing 시작 시 `/init-output writing`, grant 시작 시 `/init-output grant` 호출로 각 type 의식적으로 초기화.

---

## Step 3: CLAUDE.md 생성

`~/.claude/blueprints/templates/CLAUDE_template.md`를 읽어서 유저 답변으로 채운다.
Global rules는 `~/.claude/CLAUDE.md`에 있으므로 반복 금지.

치환 대상:
- `{{PROJECT_NAME}}`
- `{{PURPOSE}}`
- `{{HYPOTHESES}}`
- `{{DATA_DESCRIPTION}}`
- `{{LOCKED_PARAMS}}`
- `{{ENV_NAME}}`, `{{ENV_PURPOSE}}`
- `{{HPC_BLOCK}}` (Step 1에서 HPC 없으면 "Local execution (HPC 없음)")

---

## Step 4: docs/ 문서 초기화

각 문서를 `~/.claude/blueprints/templates/<NAME>_template.md` 기반으로 생성. 빈 칸은 `{{TODO}}`.

### 4-1. README.md
```markdown
# <PROJECT_NAME> — 진행 현황
Last updated: <DATE>

## 현재 상태
- [ ] Step 1: {{TODO}}

## Active Jobs
없음
```

### 4-2. STORY.md (v1.2 template)
`STORY_template.md` 복사. Narrative-only 원칙 + Document Discipline 섹션 포함.

### 4-3. CLAIMS.md (v1.2 신규 — 필수)
```bash
cp ~/.claude/blueprints/templates/CLAIMS_template.md docs/CLAIMS.md
```
Header의 `{{PROJECT_NAME}}`, `{{DATE}}`, `{{TARGET_PAPER}}`, `{{SECONDARY_PAPER}}` 치환. 빈 claim (C1) 템플릿은 그대로 유지 — user가 첫 엔트리 작성.

### 4-4. DATA_MAP.md
기존 템플릿 (base paths table, input data TODO, conda).

### 4-5. PIPELINE.md
기존 템플릿 (Step-by-step analysis plan, 초기엔 비어있음).

### 4-6. JOB_LOG.md (v1.2)
`JOB_LOG_template.md` 복사. Schema reference 포함.

---

## Step 5: 검증

```bash
test -f CLAUDE.md || echo "FAIL: CLAUDE.md"
for d in README STORY CLAIMS DATA_MAP PIPELINE JOB_LOG; do
  test -f docs/$d.md || echo "FAIL: docs/$d.md"
done
test ! -d outputs && echo "OK: outputs/ not auto-created"
```

---

## Step 6: 요약 출력

```
--- Project Initialized ---
Project: <PROJECT_NAME>
Location: <project_root>
SSOT docs: 6 (README, STORY, CLAIMS, DATA_MAP, PIPELINE, JOB_LOG)
Conda env: <ENV_NAME>
Target paper: <primary>

다음 단계:
1. docs/DATA_MAP.md 채우기 (입력 데이터 경로)
2. docs/PIPELINE.md 채우기 (분석 step)
3. 첫 claim 발견 시 docs/CLAIMS.md 업데이트
4. Figure 작업 시작 시 /init-output figures
5. SLURM job 제출 시 /submit-job
---
```

---

## 주의사항
- `outputs/` 자동 생성 **금지**. 필요 시 `/init-output`.
- CLAIMS.md는 첫 claim이 없어도 파일 자체는 생성 — figure-plan exploratory mode가 이를 읽을 수 있어야.
- Advanced project (AGENTS.md)는 현재 스펙에서 제거. 필요하면 user 수동 추가.
