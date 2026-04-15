# Outputs Schema v1.0

> **Purpose**: `<project>/outputs/` 디렉토리의 공식 구조. Layer 2 (output pipeline)의 골격.
> **Phase 4 scope**: 디렉토리 + placeholder 파일. 세부 schema는 Phase 5에서 추가.
> **Primary consumer**: `/init-output` skill, figure-plan/implement/review/assemble, 향후 writing/grant skills.

---

## Machine-readable enum lines

```
enum.OutputType   : figures | writing | grant
enum.PanelStatus  : draft | selected | superseded | rejected   (see PANEL_REGISTRY.schema)
```

---

## 원칙

1. **`outputs/`는 derivative**. Analysis 결과를 publication artifact로 변환하는 공간. Analysis 자체는 Layer 1 (`docs/`, `scripts/`, `data/`)에서.
2. **3 type 고정**: `figures`, `writing`, `grant`. Engineering output은 현재 scope 외.
3. **필요할 때 생성**. 프로젝트 시작 시 `outputs/`는 만들지 않는다. 각 output type은 `/init-output <type>` 호출 시점에만 생성.
4. **각 type 하위 구조는 동등한 계층**. Writing이 Figures의 자식이 아님. 셋 모두 `outputs/`의 직속 children.

---

## 디렉토리 구조

```
<project_root>/
├── CLAUDE.md
├── docs/                          # Layer 1 (SSOT)
│   ├── README.md
│   ├── STORY.md
│   ├── CLAIMS.md
│   ├── DATA_MAP.md
│   ├── PIPELINE.md
│   └── JOB_LOG.md
└── outputs/                       # Layer 2 (derivatives) — 필요할 때 생성
    ├── figures/                   # /init-output figures 시 생성
    │   ├── FIGURE_PLAN.md         # design doc (Phase 5 schema)
    │   ├── PANEL_REGISTRY.md      # variant selection log (Phase 5)
    │   ├── REVIEW_LOG.md          # subagent review, append-only
    │   ├── hook.log               # mechanical check log (Phase 6)
    │   ├── code/                  # 00_common.R, Fig1.R, ...
    │   └── panels/                # rendered panel artifacts
    ├── writing/                   # /init-output writing 시 생성
    │   ├── DRAFT_LOG.md           # draft 이력 (Phase 5 schema)
    │   └── drafts/                # 실제 draft .md files
    └── grant/                     # /init-output grant 시 생성
        ├── AIMS.md                # specific aims (Phase 5 schema)
        ├── REVIEW_LOG.md          # append-only review history
        └── submissions/           # submitted package snapshots
```

---

## Output type별 필수 파일 (Phase 4 minimum)

Phase 4에서는 아래 파일만 placeholder로 생성. 세부 schema는 Phase 5.

| Type | 필수 파일 | 필수 디렉토리 |
|------|-----------|--------------|
| figures | `FIGURE_PLAN.md`, `PANEL_REGISTRY.md`, `REVIEW_LOG.md` | `code/`, `panels/` |
| writing | `DRAFT_LOG.md` | `drafts/` |
| grant | `AIMS.md`, `REVIEW_LOG.md` | `submissions/` |

`hook.log`는 figure-implement가 처음 돌 때 생성 (사전 create 불필요).

---

## Cross-Layer References

- `outputs/figures/FIGURE_PLAN.md` → `docs/CLAIMS.md` (claim ID 참조)
- `outputs/figures/code/00_common.R` → `docs/DATA_MAP.md` (SSOT 경로)
- `outputs/writing/drafts/*.md` → `docs/CLAIMS.md` (numerical anchor verbatim)
- `outputs/grant/AIMS.md` → `docs/CLAIMS.md` (Tag: primary 또는 secondary)

Layer 2 → Layer 1 단방향 read-only 원칙 유지. Layer 2 작업 결과가 Layer 1에 쓰여야 할 때 (예: figure review가 claim Tag 변경 제안)는 user confirm을 반드시 거침.

---

## 비워두는 것 (Phase 5 TODO)

- `FIGURE_PLAN.md` / `PANEL_REGISTRY.md` / `DRAFT_LOG.md` / `AIMS.md`의 정식 스키마
- Writing/grant 관련 skill 설계
- 다중 manuscript (target_paper=primary/secondary) 대응 writing 디렉토리 분할
