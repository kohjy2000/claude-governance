---
name: figure-assemble
description: Phase 4 — Assemble individual panels into final multi-panel figures at journal dimensions (Nature/Cell/Science)
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /figure-assemble — Phase 4: Panels → Assembled Figure

$ARGUMENTS: figure 번호 (e.g., "Fig2") 또는 "all", + 선택된 variant 목록 (없으면 자동 선택)

## Role
Figure compositor. 개별 panel PDF/PNG를 최종 multi-panel figure로 조립.
Journal spec에 맞춰 크기, 배치, 라벨링 수행.

## Journal Dimension Specs

```
                    Single column    1.5 column     Full width      Max height
Nature:             89 mm            -              183 mm          170 mm (247 max)
Cell:               85 mm            114 mm         174 mm          -
Science:            85 mm            114 mm         175 mm          -
Default (Nature):   89 mm            -              183 mm          170 mm
```

## Process

### Step 1: Panel Inventory
```r
# List available panels for this figure
panels <- list.files("v10/panels", pattern = "^FigN_.*\\.pdf$")
# Group by panel letter
panel_groups <- split(panels, str_extract(panels, "_[A-Z]_"))
```
각 panel에서 사용할 variant 결정:
- User가 지정했으면 그대로
- 지정 안 했으면: /figure-review 결과에서 P8-P13 점수 높은 variant 선택
- 둘 다 없으면: variant 1 (첫 번째)

### Step 2: Layout Design

**Layout 원칙:**
1. **Reading order**: 좌→우, 상→하 = panel 순서 (a, b, c...)
2. **Size = importance**: 주요 결과 panel이 더 넓거나 높음
3. **Alignment**: 같은 row의 panel은 상단 정렬, 같은 column은 좌측 정렬
4. **Grouping**: 관련 panel은 인접 배치 (Gestalt proximity)

**Common layouts:**
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

### Step 3: Assemble with patchwork

```r
library(patchwork)

# Load panels (each is a ggplot object or grob)
pA <- readRDS("panels/FigN_A_selected.rds")  # if saved as RDS
# OR re-source the figure script and capture plot objects

# Compose
assembled <- pA + pB + pC + pD + pE +
  plot_layout(design = layout) +
  plot_annotation(
    tag_levels = "a",                    # lowercase (Nature spec)
    theme = theme(
      plot.tag = element_text(
        size = 8, face = "bold",         # P12: 8pt bold
        family = "Helvetica"
      )
    )
  )

# Export at exact journal dimensions
ggsave(
  "assembled/FigN_assembled.pdf",
  assembled,
  width = 183, height = 170,             # Nature full-width
  units = "mm",
  device = cairo_pdf
)
ggsave(
  "assembled/FigN_assembled.png",
  assembled,
  width = 183, height = 170,
  units = "mm",
  dpi = 300
)
```

### Step 4: Non-ggplot Panel Integration

ComplexHeatmap, tableGrob 등 non-ggplot 객체가 있을 때:
```r
# ComplexHeatmap → grob 변환
ht_grob <- grid::grid.grabExpr(draw(ht_object))
pD_wrapped <- patchwork::wrap_elements(ht_grob)

# gt table → grob 변환 (gt >= 0.10)
tbl_grob <- gt::as_gtable(gt_table)
pE_wrapped <- patchwork::wrap_elements(tbl_grob)

# 이후 patchwork 합성에 동일하게 사용
assembled <- pA + pB + pC + pD_wrapped + pE_wrapped +
  plot_layout(design = layout)
```

### Step 5: Quality Checks

조립 후 반드시 확인:

```
[ ] Panel labels (a-e) 모두 visible, 8pt bold lowercase
[ ] 겹치는 text 없음
[ ] Panel 간 여백 균일 (최소 2mm at print size)
[ ] 총 dimensions이 journal spec 이내
[ ] 가장 작은 text가 5pt 이상 (print size 기준)
[ ] 주요 panel이 가장 큰 면적 차지
[ ] Color 일관성 (같은 group = 같은 color across all panels)
```

**Print-size test:**
```r
# PDF를 실제 크기로 열어서 확인
# 183mm = 7.2in → 모니터에서 7.2인치로 표시될 때 text 읽히는지
```

## Assembly Script Template

```r
# assemble_FigN.R
source("00_common_v10.R")

# --- Re-create selected panels ---
# (각 Fig script에서 plot 객체를 반환하도록 함수화 되어 있어야 함)
source("FigN_v10_topic.R")  # creates pA, pB, pC, pD, pE

# --- Select variants ---
pA <- plot_figN_A("selected_variant")
pB <- plot_figN_B("selected_variant")
pC <- plot_figN_C("selected_variant")
pD <- plot_figN_D("selected_variant")
pE <- plot_figN_E("selected_variant")

# --- Layout ---
layout <- "
AABBB
CCDDE
"

# --- Assemble ---
fig <- pA + pB + pC + pD + pE +
  plot_layout(design = layout) +
  plot_annotation(
    tag_levels = "a",
    theme = theme(
      plot.tag = element_text(size = 8, face = "bold", family = "Helvetica")
    )
  ) &
  theme(plot.margin = margin(2, 2, 2, 2))  # P13: breathing room

# --- Export ---
ggsave(
  file.path(FIGDIR, "assembled", "FigN_assembled.pdf"),
  fig, width = 183, height = 150, units = "mm", device = cairo_pdf
)
ggsave(
  file.path(FIGDIR, "assembled", "FigN_assembled.png"),
  fig, width = 183, height = 150, units = "mm", dpi = 300
)

cat("FigN assembled: 183 x 150 mm\n")
```

## Supplementary Figure Assembly

Supplementary는 제약이 더 유연:
- Width: 183mm (full-width 권장)
- Height: 247mm까지 가능 (Nature max)
- Panel 수 제한 없음
- 하지만 P13 (BREATHE) 여전히 적용 — 읽을 수 있어야 함

```r
# Supp figures: taller allowed
ggsave(..., width = 183, height = 240, units = "mm")
```

## Output

```
<FIGDIR>/assembled/
├── Fig1_assembled.pdf     # 183 x Nmm, Nature full-width
├── Fig1_assembled.png     # 300 dpi
├── Fig2_assembled.pdf
├── ...
└── SuppS_H2S_assembled.pdf
```

## Common Pitfalls
| Pitfall | Fix |
|---------|-----|
| Text too small after assembly | 처음부터 target dimensions에서 디자인 (base_size=7) |
| Nested patchwork crash | wrap_elements() for non-ggplot objects |
| Panel labels missing | plot_annotation(tag_levels="a") 확인 |
| Uneven spacing | `& theme(plot.margin=margin(2,2,2,2))` 추가 |
| Panel aspect ratio distorted | individual panel에서 coord_fixed() 또는 aspect.ratio 설정 |
| PDF font not embedded | cairo_pdf device 사용 |
| Color shift in print | RGB → CMYK 변환 확인 (Nature는 auto) |
