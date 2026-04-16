---
name: init-project
description: Initialize a new research project with Layer 1 governance structure (docs/ + reference/ + scripts scaffolding). Layer 2 (figure pipeline) is created separately by /figure-init. v1.2 adds CLAIMS.md (hierarchical C0-C4 groups + 4-tag), reference/ directory for figure style/catalog, and explicit "no outputs/ auto-creation" rule.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /init-project — 새 프로젝트 초기 세팅 (Layer 1)

`$ARGUMENTS`에 프로젝트 경로가 주어지면 해당 경로를 사용. 없으면 현재 디렉토리.

**v1.2 변경사항**:
- `docs/CLAIMS.md` 추가 (hierarchical C0-C4 groups + 4-tag placement).
- `reference/{papers,catalog}/` 디렉토리 scaffold (figure pipeline 준비).
- `docs_figure/`, `output/`, `code/` 자동 생성 **안 함** — `/figure-init`이 담당 (Layer 2).

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

## Step 2: 디렉토리 구조 생성 (Layer 1 only)

```
<project_root>/
├── CLAUDE.md
├── docs/                      # Layer 1 SSOT
│   ├── README.md
│   ├── STORY.md
│   ├── CLAIMS.md              # v1.1 hierarchical (C0-C4) + 4-tag
│   ├── DATA_MAP.md
│   ├── PIPELINE.md
│   └── JOB_LOG.md
├── reference/                 # Figure pipeline input (v1.2 추가)
│   ├── papers/                # 레퍼런스 논문 PDF (style 추출용)
│   │   └── .gitkeep
│   └── catalog/               # 레퍼런스 R/Py 스크립트 (SCRIPT_CATALOG 생성)
│       └── .gitkeep
├── 01_data/
├── 02_results/
└── 03_scripts/
```

**만들지 않는 것** (의식적 단계로 분리):
- `docs_figure/`, `code/`, `output/` → figure 작업 시작 시 `/figure-init`이 생성 (Layer 2).
- `outputs/writing/`, `outputs/grant/` → writing/grant 전용 skill이 나중에 설계될 때 도입.

**`reference/papers/`** 와 **`reference/catalog/`** 는 .gitkeep만 있는 빈 디렉토리. User가 수동으로 PDF와 R script를 넣은 후 `/figure-init` 호출 시점에 `/figure-style-extract`가 파싱.

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

### 4-3. CLAIMS.md (v1.1 hierarchical — 필수)
```bash
cp ~/.claude/blueprints/templates/CLAIMS_template.md docs/CLAIMS.md
```
Header의 `{{PROJECT_NAME}}`, `{{DATE}}`, `{{TARGET_PAPER}}`, `{{SECONDARY_PAPER}}` 치환. 빈 claim 템플릿은 `### C0-1` stub으로 유지 — user가 첫 엔트리 작성 (Group + Tag 설정).

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
test -d reference/papers  && echo "OK: reference/papers created"
test -d reference/catalog && echo "OK: reference/catalog created"
test ! -d docs_figure && echo "OK: docs_figure/ not auto-created (use /figure-init)"
test ! -d output      && echo "OK: output/ not auto-created (use /figure-init)"
```

---

## Step 6: 요약 출력

```
--- Project Initialized (Layer 1) ---
Project: <PROJECT_NAME>
Location: <project_root>
SSOT docs: 6 (README, STORY, CLAIMS, DATA_MAP, PIPELINE, JOB_LOG)
Reference scaffold: reference/{papers,catalog}/ (empty, populate before /figure-init)
Conda env: <ENV_NAME>
Target paper: <primary>

다음 단계:
1. docs/DATA_MAP.md 채우기 (입력 데이터 경로)
2. docs/PIPELINE.md 채우기 (분석 step)
3. 첫 claim 발견 시 docs/CLAIMS.md 업데이트 (Group: C0/C1/C2/C3/C4 + Tag: main/supp/...)
4. SLURM job 제출 시 /submit-job
5. Figure 작업 전 reference/papers/에 레퍼런스 논문 PDF, reference/catalog/에 레퍼런스 R script 배치
6. Figure 작업 시작 시 /figure-init — docs_figure/ 생성 + STYLE_GUIDE + SCRIPT_CATALOG 추출
7. 개별 figure 구축 시 /figure-build target=Fig{N}
---
```

---

## 주의사항
- `docs_figure/`, `output/`, `code/` **자동 생성 금지**. `/figure-init`이 담당 (Layer 2 boundary).
- `reference/{papers,catalog}/`는 scaffold만. User가 실제 파일을 넣지 않으면 `/figure-init`이 fallback (Nature 기본값).
- CLAIMS.md는 첫 claim이 없어도 파일 자체는 생성 — C0-1 stub으로. Figure 작업 시작 전에 적어도 1개 claim 필요.
- Advanced project (AGENTS.md)는 현재 스펙에서 제거. 필요하면 user 수동 추가.
