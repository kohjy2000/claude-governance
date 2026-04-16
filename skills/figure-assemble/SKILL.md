---
name: figure-assemble
description: Phase 4 — Assemble individual panels into final multi-panel figures at journal dimensions (Nature/Cell/Science). v1.2 reads PANEL_REGISTRY to auto-select variants.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /figure-assemble — Phase 4: Panels → Assembled Figure

`$ARGUMENTS`: figure 번호 (예: `Fig2`) 또는 `all`.

## Role
Figure compositor. 개별 panel PDF/PNG를 최종 multi-panel figure로 조립.
Journal spec에 맞춰 크기, 배치, 라벨링 수행.

**v1.2 변경 (Phase 6+ path update)**:
- Input: `docs_figure/PANEL_REGISTRY.md` (schema v1.0) 우선 참조.
- Variant 자동 선택은 `Status: selected` 엔트리 기준.
- Panels from `output/panels/`, code from `code/`, assembled to `output/figures/`.

**Schemas**:
- `~/.claude/blueprints/schemas/PANEL_REGISTRY.schema.md`
- `~/.claude/blueprints/schemas/FIGURE_PLAN.schema.md` (layout reference)

---

## Journal Dimension Specs

```
                    Single column    1.5 column     Full width      Max height
Nature:             89 mm            -              183 mm          170 mm (247 max)
Cell:               85 mm            114 mm         174 mm          -
Science:            85 mm            114 mm         175 mm          -
Default (Nature):   89 mm            -              183 mm          170 mm
```

---

## Process

### Step 1: Panel Inventory (v1.2)

**First source**: `docs_figure/PANEL_REGISTRY.md` — Status=selected 엔트리만 pick.

```r
# Parse registry
registry <- read_delim("docs_figure/PANEL_REGISTRY.md", 
                       delim="|", trim_ws=TRUE, skip=header_rows) %>%
  filter(Status == "selected", str_detect(Panel, paste0("^", fig_id)))
```

**Fallback** (registry missing 또는 selected 엔트리 없음): 
- `panels/` 디렉토리의 파일 list 후 user에게 variant 선택 요청.
- 마지막 폴백: variant=v1 자동 선택.

```r
panels <- list.files("output/panels", pattern = "^FigN_.*\\.pdf$")
panel_groups <- split(panels, str_extract(panels, "_[A-Z]_"))
```

### Step 2: Layout Design

**Layout 원칙**:
1. Reading order: 좌→우, 상→하 = panel 순서 (a, b, c...).
2. Size = importance: 주요 결과 panel이 더 넓거나 높음.
3. Alignment: 같은 row 상단 정렬, 같은 column 좌측 정렬.
4. Grouping: 관련 panel 인접 배치.

**Common layouts**:
```
# 2-row symmetric (5 panels)
layout <- "
AABBB
CCDDE
"

# Top-heavy (main result large)
layout <- "
AAA
BCD
"

# Side-by-side pairs
layout <- "
AABB
CCDD
EE##
"
```

FIGURE_PLAN.md의 Paper-Level Story Arc를 참조해 figure role에 맞는 layout 선택.

### Step 3: Assemble with patchwork

```r
library(patchwork)

# Load panels
pA <- readRDS("output/panels/Fig1_A_v2-forest.rds")  # if saved as RDS
# OR re-source the figure script and capture plot objects

assembled <- pA + pB + pC + pD + pE +
  plot_layout(design = layout) +
  plot_annotation(
    tag_levels = "a",
    theme = theme(
      plot.tag = element_text(
        size = 8, face = "bold",
        family = "Helvetica"
      )
    )
  )

ggsave(
  "output/figures/Fig1_assembled.pdf",
  assembled,
  width = 183, height = 170,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  "output/figures/Fig1_assembled.png",
  assembled,
  width = 183, height = 170,
  units = "mm",
  dpi = 300
)
```

### Step 4: Non-ggplot Panel Integration

```r
# ComplexHeatmap → grob
ht_grob <- grid::grid.grabExpr(draw(ht_object))
pD_wrapped <- patchwork::wrap_elements(ht_grob)

# gt table → grob (gt >= 0.10)
tbl_grob <- gt::as_gtable(gt_table)
pE_wrapped <- patchwork::wrap_elements(tbl_grob)

assembled <- pA + pB + pC + pD_wrapped + pE_wrapped +
  plot_layout(design = layout)
```

### Step 5: Quality Checks

조립 후:

```
[ ] Panel labels (a-e) 모두 visible, 8pt bold lowercase
[ ] 겹치는 text 없음
[ ] Panel 간 여백 균일 (최소 2mm at print size)
[ ] 총 dimensions이 journal spec 이내
[ ] 가장 작은 text가 5pt 이상
[ ] 주요 panel이 가장 큰 면적
[ ] Color 일관성 (같은 group = 같은 color across panels)
```

**Print-size test**: PDF를 실제 크기로 열어 text 가독성 확인 (183mm = 7.2in).

---

## Assembly Script Template

```r
# assemble_Fig1.R
source("code/00_common.R")
source("code/Fig1_<topic>.R")  # creates plot_fig1_X functions

# --- PANEL_REGISTRY에서 selected variant 읽기 ---
# (pseudo — 실제 구현은 registry parsing helper 필요)
variants <- read_registry_selected("Fig1")  # returns list(A="v2-forest", B="v1-violin", ...)

pA <- plot_fig1_A(variants$A)
pB <- plot_fig1_B(variants$B)
pC <- plot_fig1_C(variants$C)
pD <- plot_fig1_D(variants$D)
pE <- plot_fig1_E(variants$E)

layout <- "
AABBB
CCDDE
"

fig <- pA + pB + pC + pD + pE +
  plot_layout(design = layout) +
  plot_annotation(
    tag_levels = "a",
    theme = theme(
      plot.tag = element_text(size = 8, face = "bold", family = "Helvetica")
    )
  ) &
  theme(plot.margin = margin(2, 2, 2, 2))

ggsave(
  "output/figures/Fig1_assembled.pdf",
  fig, width = 183, height = 150, units = "mm", device = cairo_pdf
)
ggsave(
  "output/figures/Fig1_assembled.png",
  fig, width = 183, height = 150, units = "mm", dpi = 300
)

cat("Fig1 assembled: 183 x 150 mm\n")
```

---

## Supplementary Figure Assembly

- Width: 183mm (full-width 권장).
- Height: 247mm까지 가능 (Nature max).
- Panel 수 제한 없음.
- P13 (BREATHE) 여전히 적용.

```r
ggsave(..., width = 183, height = 240, units = "mm")
```

---

## Output

```
output/figures/
├── Fig1_assembled.pdf     # 183 x Nmm, Nature full-width
├── Fig1_assembled.png     # 300 dpi
├── Fig2_assembled.pdf
└── SuppS_H2S_assembled.pdf

# Phase 6+ directory structure:
# docs_figure/PANEL_REGISTRY.md  ← variant selection (input)
# code/00_common.R               ← shared theme/palette
# code/Fig{N}.R                   ← per-figure scripts
# output/panels/                  ← individual panel artifacts
# output/figures/                 ← assembled figures (output)
```

---

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Text too small after assembly | 처음부터 target dimensions에서 디자인 (base_size=7) |
| Nested patchwork crash | wrap_elements() for non-ggplot objects |
| Panel labels missing | plot_annotation(tag_levels="a") 확인 |
| Uneven spacing | `& theme(plot.margin=margin(2,2,2,2))` 추가 |
| Aspect ratio distorted | individual panel에서 coord_fixed() 또는 aspect.ratio |
| PDF font not embedded | cairo_pdf device 사용 |
| Color shift in print | RGB → CMYK 변환 확인 (Nature는 auto) |
| **Registry와 panels/ mismatch (v1.2)** | Registry의 Status=selected 파일이 실제 존재하는지 확인. 없으면 figure-implement 재실행 필요. |

---

## v1.2 요약

- Input: `docs_figure/PANEL_REGISTRY.md` 우선.
- Fallback: `output/panels/` 디렉토리 스캔 + user 확인.
- 경로: 코드 `code/`, 패널 `output/panels/`, 조립 결과 `output/figures/`.
- Status=selected 아닌 variant는 assembled figure에 포함하지 않음.
