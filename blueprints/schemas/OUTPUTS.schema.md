# Outputs Schema v1.0

> **Purpose**: `<project>/outputs/` 디렉토리의 공식 구조. Layer 2 (output pipeline)의 골격.
> **Phase 4 scope**: 디렉토리 + placeholder 파일. 세부 schema는 Phase 5에서 추가.
> **Primary consumer**: `/figure-init` skill (Phase 6+, replaces deprecated `/init-output`), figure-plan/implement/review/assemble, 향후 writing/grant skills.

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
3. **필요할 때 생성**. 프로젝트 시작 시 `outputs/`는 만들지 않는다. Figure pipeline은 `/figure-init` (Phase 6+)으로 `docs_figure/` + `output/` + `code/`를 생성. Writing/grant는 별도 init skill 필요.
4. **Figure pipeline 경로 변경 (Phase 6+)**: Figure 관련 SSOT는 `docs_figure/`로 이동. `output/panels/`는 rendered artifact 전용. `code/`는 R/Python 스크립트 전용. 기존 `outputs/figures/` 구조는 deprecated.

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
├── docs_figure/                   # Layer 2 figure pipeline (Phase 6+, /figure-init)
│   ├── FIGURE_BASELINE.md         # entity tier, palette, claim-figure mapping
│   ├── STYLE_GUIDE.md             # reference-extracted style conventions
│   ├── SCRIPT_CATALOG.yml         # visual primitive index
│   ├── FIGURE_OVERVIEW.md         # figure目录 + Target claim summary
│   ├── PANEL_REGISTRY.md          # variant selection log
│   ├── REVIEW_LOG.md              # subagent review, append-only
│   ├── hook.log                   # mechanical check log (Phase 6 Turn 3)
│   └── figure_pipeline/
│       ├── design_docs/           # Fig{N}_design.md per figure
│       └── review_reports/        # Fig{N}_iter{N}.md per review
├── code/                          # R/Python scripts
│   ├── 00_common.R                # SSOT + palette + theme + helpers
│   └── Fig{N}.R / Fig{N}_{p}.R   # per-figure / per-panel scripts
├── output/                        # Rendered artifacts
│   ├── panels/                    # individual panel PDFs/PNGs
│   └── figures/                   # assembled multi-panel figures
├── reference/                     # Reference materials (read-only)
│   ├── papers/                    # published PDFs
│   └── catalog/                   # companion scripts
└── outputs/                       # Non-figure output types (legacy structure)
    ├── writing/                   # future writing pipeline
    │   ├── DRAFT_LOG.md
    │   └── drafts/
    └── grant/                     # future grant pipeline
        ├── AIMS.md
        ├── REVIEW_LOG.md
        └── submissions/
```

---

## Output type별 필수 파일

### Figures (Phase 6+ — `/figure-init` creates)

| 필수 파일 | 위치 |
|-----------|------|
| `FIGURE_BASELINE.md`, `STYLE_GUIDE.md`, `SCRIPT_CATALOG.yml`, `FIGURE_OVERVIEW.md` | `docs_figure/` |
| `PANEL_REGISTRY.md`, `REVIEW_LOG.md` | `docs_figure/` |
| `figure_pipeline/design_docs/`, `figure_pipeline/review_reports/` | `docs_figure/` |
| `00_common.R` | `code/` |
| (panels) | `output/panels/` |

`hook.log`는 figure-implement가 처음 돌 때 생성 (사전 create 불필요).

### Writing / Grant (future — no init skill yet)

| Type | 필수 파일 | 필수 디렉토리 |
|------|-----------|--------------|
| writing | `DRAFT_LOG.md` | `outputs/writing/drafts/` |
| grant | `AIMS.md`, `REVIEW_LOG.md` | `outputs/grant/submissions/` |

---

## Cross-Layer References

- `docs_figure/figure_pipeline/design_docs/Fig{N}_design.md` → `docs/CLAIMS.md` (claim ID 참조)
- `code/00_common.R` → `docs/DATA_MAP.md` (SSOT 경로)
- `docs_figure/PANEL_REGISTRY.md` → `docs_figure/figure_pipeline/design_docs/` (Panel ID 일치)
- `outputs/writing/drafts/*.md` → `docs/CLAIMS.md` (numerical anchor verbatim)
- `outputs/grant/AIMS.md` → `docs/CLAIMS.md` (Tag: primary 또는 secondary)

Layer 2 → Layer 1 단방향 read-only 원칙 유지. Layer 2 작업 결과가 Layer 1에 쓰여야 할 때 (예: figure review가 claim Tag 변경 제안)는 user confirm을 반드시 거침.

---

## 비워두는 것 (Phase 5 TODO)

- `FIGURE_PLAN.md` / `PANEL_REGISTRY.md` / `DRAFT_LOG.md` / `AIMS.md`의 정식 스키마
- Writing/grant 관련 skill 설계
- 다중 manuscript (target_paper=primary/secondary) 대응 writing 디렉토리 분할
