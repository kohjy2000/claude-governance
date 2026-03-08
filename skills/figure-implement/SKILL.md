---
name: figure-implement
description: Phase 2 — Convert design document to executable figure code with visual storytelling (P1-P13) and content integrity (P14-P16)
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /figure-implement — Phase 2: Design Doc → Code

$ARGUMENTS: design document 경로 또는 figure 번호

## Role
Scientific figure implementer. Design doc을 실행 가능한 코드로 변환.
P8-P13 visual storytelling 원칙을 코드 레벨에서 강제.

## Output Structure

```
<figure_dir>/
├── 00_common.R                    # Infrastructure (SSOT, palette, theme, helpers)
├── Fig1_<topic>.R                 # Per-figure scripts
├── Fig2_<topic>.R
└── output/
    ├── panels/                    # Individual panel files (PDF + PNG)
    │   ├── Fig1_A_variant1.pdf
    │   └── ...
    └── comparison/                # Side-by-side variant comparisons
        ├── Fig1_A_comparison.pdf
        └── ...
```

## Pattern 1: 00_common.R (Infrastructure)

반드시 포함해야 할 요소:

**1a. SSOT Registry** — 모든 데이터 경로를 여기서 중앙 관리
```r
SSOT <- list(
  metadata   = file.path(DATA_ROOT, "path/to/metadata.tsv"),
  results    = file.path(DATA_ROOT, "path/to/results.tsv")
)
validate_ssot <- function(strict = TRUE) { ... }
```

**1b. Centralized Palettes (P7 + P8)** — 색상/라벨 정의는 오직 여기서만
```r
# Primary palette (focal elements)
GROUP_COLORS  <- c(GroupA = "#2166AC", GroupB = "#B2182B", GroupC = "#4DAF4A")
# Context color (P8: grey-out for non-focal elements)
CTX_GREY      <- "grey70"
CTX_ALPHA     <- 0.3
# Significance encoding (P11: visual, not text)
SIG_FILL      <- "firebrick"
NS_FILL       <- "grey70"
```

**1c. Publication Theme (P9 + P12 + P13)** — Nature-spec theme
```r
theme_nature <- function(base_size = 7) {
  theme_minimal(base_size = base_size, base_family = "Helvetica") +
    theme(
      # P12: Typography hierarchy
      plot.title       = element_text(size = base_size + 1, face = "bold", hjust = 0),
      plot.subtitle    = element_text(size = base_size, color = "grey40"),
      axis.title       = element_text(size = base_size),
      axis.text        = element_text(size = base_size - 1, color = "grey30"),
      strip.text       = element_text(size = base_size, face = "bold"),
      legend.text      = element_text(size = base_size - 1),
      legend.title     = element_text(size = base_size, face = "bold"),
      # P9: Remove non-data ink
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.border     = element_blank(),
      # P13: Breathing room
      plot.margin      = margin(8, 8, 8, 8),
      legend.margin    = margin(0, 0, 0, 4),
      strip.background = element_blank()
    )
}
# Panel tag theme (P12: 8pt bold lowercase)
PANEL_TAG_THEME <- theme(plot.tag = element_text(size = 8, face = "bold"))
```

**1d. Visual Hierarchy Helpers (P8 + P11)**
```r
# P8: Grey-out helper — emphasize focal rows in a data frame
add_emphasis <- function(df, focal_col, focal_values) {
  df %>% mutate(
    .focal     = .data[[focal_col]] %in% focal_values,
    .fill_col  = if_else(.focal, as.character(.data[[focal_col]]), "context"),
    .alpha_val = if_else(.focal, 1.0, CTX_ALPHA),
    .size_val  = if_else(.focal, 2.5, 1.0)
  )
}

# P11: Significance encoding — filled vs hollow (not stars)
sig_shape_scale <- function() {
  scale_shape_manual(
    values = c("TRUE" = 16, "FALSE" = 1),  # filled circle vs hollow
    labels = c("TRUE" = "FDR<0.10", "FALSE" = "NS"),
    name   = NULL
  )
}

# P11: Significance color scale — saturated vs grey
sig_color_scale <- function(sig_color = SIG_FILL, ns_color = NS_FILL) {
  scale_color_manual(
    values = c("TRUE" = sig_color, "FALSE" = ns_color),
    labels = c("TRUE" = "FDR<0.10", "FALSE" = "NS"),
    name   = NULL
  )
}
```

**1e. Save Helpers** — PDF + PNG 동시 저장
**1f. Statistical Helpers** — `fdr_label()` (returns "q<0.001" etc.)

## Pattern 2: Per-Figure Script

```r
source("00_common.R")
# DATA LOADING — 모든 데이터를 스크립트 상단에서 한 번에 로드
data1 <- read_tsv(SSOT$key, show_col_types = FALSE)

# PANEL A — variant dispatch pattern
plot_figN_A <- function(variant = c("v1", "v2")) {
  variant <- match.arg(variant)
  if (variant == "v1") { ... } else { ... }
}
for (v in c("v1", "v2")) save_panel(plot_figN_A(v), "FigN", "A", v)

# COMPARISON SHEETS
comp_A <- plot_figN_A("v1") + plot_figN_A("v2") +
  patchwork::plot_annotation(title = "FigN-A: v1 (L) vs v2 (R)")
save_comparison(comp_A, "FigN", "A")
```

## Hard Rules for Code (C1-C8 + V1-V6)

### Structural (C1-C8)
```
C1  모든 read_*() 호출은 SSOT key 참조. 원시 경로 금지.
C2  데이터는 스크립트 상단에서 로드. panel 함수 안에서 로드 금지.
C3  Panel 함수는 variant= 인자 + match.arg() 패턴.
C4  save_panel()은 PDF + PNG 동시 생성.
C5  2개 이상 variant인 panel은 comparison sheet 생성.
C6  색상/라벨 literals 금지. 00_common palette 사용.
C7  Subtitle에 N, method, adjustment 포함.
C8  Figure script에서 library() 호출 금지 (00_common.R에서만).
```

### Visual Storytelling (V1-V6) — NEW
```
V1  FOCUS: 모든 geom에 .focal 기반 alpha/color/size 분기. 전체 동일 색상 금지.
    - focal element: saturated color, alpha=1, size=2.5+
    - context: grey70, alpha=0.3, size=1.0
    - 구현: add_emphasis() 또는 gghighlight::gghighlight()

V2  INK: theme_nature() 사용 필수. theme_bw()/theme_grey()/theme_classic() 금지.
    - panel.grid.major.y만 허용 (horizontal reference lines)
    - panel.border, panel.grid.minor, panel.grid.major.x 모두 제거
    - geom_vline/geom_hline은 reference (e.g., x=0, y=0.05)에만 사용

V3  ENCODE: significance를 시각적으로 인코딩.
    - 금지: geom_text(label="*") 또는 geom_text(label="★")
    - 대신: filled vs hollow point (sig_shape_scale)
    - 대신: saturated vs grey color (sig_color_scale)
    - 대신: bold vs thin linewidth
    - p-value text는 annotation으로만 (축 밖 또는 facet strip에)

V4  AXIS: 축당 최대 20 items. 초과 시:
    - Top-K + "(N others below threshold)" 방식으로 축약
    - 또는 facet_wrap()으로 분할
    - 또는 aggregation (e.g., chr arm → chr)
    - 48 arms 직렬 나열 금지

V5  LAYER: 전경/배경 분리 패턴 사용.
    - 배경: geom_point(data=context_df, color=CTX_GREY, alpha=CTX_ALPHA)
    - 전경: geom_point(data=focal_df, aes(color=group), size=2.5)
    - 또는 gghighlight(condition, unhighlighted_params=list(colour=CTX_GREY, alpha=CTX_ALPHA))

V6  TABLE-FREE: ggplot으로 표 그리지 않기.

V7  CLAIM-IN-CODE: title/subtitle이 design doc의 claim과 정확히 일치.
    - title = "무엇을 보여주는가" (factual)
    - subtitle = "scope | method | sample" + key finding
    - claim이 NS이면 subtitle에 "NS" 반드시 포함
    - 금지: "demonstrates", "proves", "drives", "causes"
    - 허용: "associated with", "correlated", "observed", "enriched"

V8  TRANSITION: 각 panel 상단 comment에 transition sentence 기록.
    - # Transition from Panel A: "5,490 sig → Cancer에서 어떻게 변하나?"
    - 이 comment는 figure legend 작성의 seed가 됨

V9  LIMITATION: NS 또는 validation 실패 결과의 subtitle에 limitation 명시.
    - e.g., subtitle = "... | Mutograph: rho=-0.11, NS (not replicated)"
    - e.g., subtitle = "... | all NS → no arm specificity"
    - 금지: geom_tile() + geom_text()로 spreadsheet 모방
    - 대신: gt::gt() 또는 kableExtra로 별도 table output
    - Fig5 synthesis 같은 summary → dot plot, forest plot, 또는 real table
```

## Panel Subtitle Convention
모든 panel subtitle에 포함:
1. **Sample size**: `n=115` or `NP=77, Prog=38`
2. **Scope**: `538 taxa x 191 features = 102,758 tests`
3. **Method**: `Pearson | FDR (BH)`
4. **Adjustment**: `batch+age adjusted` (해당 시)

Format: `"{scope} | {method} | {sample}"`

## Visual Hierarchy Quick Reference

### Forest Plot (most common)
```r
# P8 + V1 + V3: focal module highlighted, sig encoded by shape/color
ggplot(df, aes(x = estimate, y = reorder(feature, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.3, color = "grey60") +
  # V5: background context points
  geom_point(data = df %>% filter(!.focal),
             color = CTX_GREY, size = 1, alpha = CTX_ALPHA) +
  geom_errorbarh(data = df %>% filter(!.focal),
                 aes(xmin = ci_lo, xmax = ci_hi),
                 height = 0, color = CTX_GREY, alpha = CTX_ALPHA, linewidth = 0.3) +
  # V5: foreground focal points
  geom_point(data = df %>% filter(.focal),
             aes(color = sig, shape = sig), size = 2.5) +
  geom_errorbarh(data = df %>% filter(.focal),
                 aes(xmin = ci_lo, xmax = ci_hi, color = sig),
                 height = 0, linewidth = 0.5) +
  sig_color_scale() + sig_shape_scale() +
  theme_nature() + PANEL_TAG_THEME
```

### Scatter with Emphasis
```r
# P8: one group highlighted, rest greyed
ggplot(df, aes(x = x, y = y)) +
  geom_point(data = df %>% filter(!.focal),
             color = CTX_GREY, alpha = CTX_ALPHA, size = 1) +
  geom_point(data = df %>% filter(.focal),
             aes(color = group), size = 2, alpha = 0.8) +
  geom_smooth(data = df %>% filter(.focal),
              method = "lm", se = TRUE, linewidth = 0.6) +
  theme_nature()
```

### Connected Stage Plot (replaces slopegraph for trajectories)
```r
# P11: direction encoded by slope, not by text
ggplot(df, aes(x = stage, y = effect, group = feature)) +
  geom_line(data = df %>% filter(!.focal),
            color = CTX_GREY, alpha = CTX_ALPHA, linewidth = 0.3) +
  geom_line(data = df %>% filter(.focal),
            aes(color = feature), linewidth = 0.8) +
  geom_point(data = df %>% filter(.focal),
             aes(color = feature, shape = sig), size = 2.5) +
  theme_nature()
```

## Python Equivalent
R이 아닌 Python을 쓸 경우:
- `SSOT = { "key": Path(...) }` dict 사용
- `fig, ax = plt.subplots()` 패턴
- class-based: `FigureN.panel_A(variant="heatmap")`
- `fig.savefig(path, dpi=300, bbox_inches='tight')`
