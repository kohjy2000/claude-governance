---
name: figure-implement
description: Phase 2 — Convert design document to executable figure code with visual storytelling (P1-P13) and content integrity (P14-P16). Supports two granularities: figure-level (writes 00_common.R + Fig{N}.R + all panels) and panel-level (writes only Fig{N}_{p}.R + that panel). When panel design has catalog reference, clones-and-adapts code from referenced script instead of writing from scratch.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /figure-implement — Phase 2: Design Doc → Code

$ARGUMENTS:
- `granularity=figure|panel` (default: figure)
- `target=Fig{N}` (required)
- `panel={letter}` (required when granularity=panel)
- optional: design document path (default: derived from target/panel)

## Role
Scientific figure implementer. Design doc을 실행 가능한 코드로 변환.
P8-P13 visual storytelling 원칙을 코드 레벨에서 강제.

**Granularity dispatch**:
- `granularity=figure`: writes `00_common.R` (if missing) + `Fig{N}.R` (entry) + all panel files
- `granularity=panel`: writes only `Fig{N}_{p}.R` for one panel; reads existing `00_common.R`

**Catalog clone-modify pattern** (when design doc has `catalog_ref`): instead of writing visualization from scratch, clones the catalog script's code at the specified line range, then adapts variables/palette/labels.

## Output Structure

```
<project_root>/
├── code/
│   ├── 00_common.R             # Infrastructure (created by figure-level; reused by panel-level)
│   ├── Fig{N}.R                # Figure entry script (sources panel files)
│   └── Fig{N}_{p}.R            # Per-panel R code (catalog-derived if cataloged)
└── output/
    ├── panels/
    │   ├── Fig{N}_{p}.pdf, Fig{N}_{p}.png
    │   └── variants/Fig{N}_{p}_v{X}.pdf  # all variants explored
    └── comparison/
        └── Fig{N}_{p}_comparison.pdf     # side-by-side ≥2 variants
```

## Pattern 1: 00_common.R (Infrastructure — figure-level only)

반드시 포함해야 할 요소:

### 1a. SSOT Registry — 모든 데이터 경로를 여기서 중앙 관리
```r
SSOT <- list(
  metadata   = file.path(DATA_ROOT, "path/to/metadata.tsv"),
  results    = file.path(DATA_ROOT, "path/to/results.tsv")
)
validate_ssot <- function(strict = TRUE) { ... }
```

### 1b. Centralized Palettes (P7 + P8) — 색상/라벨 정의는 오직 여기서만
**Reference `FIGURE_BASELINE.md` → `DX_PALETTE_PRIMARY`, `FACTOR_FAMILY_COLORS`, etc.**
```r
# Primary palette (focal elements) — from BASELINE
DX_PRIMARY    <- c(NB = "#E65100", OS = "#2E7D32")  # exact values from BASELINE
DX_SECONDARY  <- c(MB = "#B71C1C", HGG = "#9C27B0")
# Context (P8 grey-out)
CTX_GREY      <- "grey70"
CTX_ALPHA     <- 0.30
FOCAL_ALPHA   <- 0.95
# Significance (P11 visual encoding, NOT stars)
SIG_FILL      <- "firebrick"
NS_FILL       <- "grey70"
```

### 1c. Publication Theme (P9 + P12 + P13) — extracted from STYLE_GUIDE.md
```r
theme_nature <- function(base_size = 7) {
  theme_classic(base_size = base_size, base_family = "Helvetica") +
    theme(
      plot.title       = element_text(size = base_size + 1, face = "bold", hjust = 0),
      plot.subtitle    = element_text(size = base_size, color = "grey40"),
      axis.title       = element_text(size = base_size),
      axis.text        = element_text(size = base_size - 1, color = "grey30"),
      axis.line        = element_line(color = "grey20", linewidth = 0.3),
      strip.background = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.border     = element_blank(),
      plot.margin      = margin(4, 4, 4, 4),
      panel.background = element_rect(fill = "white", color = NA)
    )
}
PANEL_TAG_THEME <- theme(plot.tag = element_text(size = 8, face = "bold"))
```

### 1d. Visual Hierarchy Helpers (P8 + P11)
```r
add_emphasis <- function(df, focal_col, focal_values) {
  df %>% mutate(
    .focal     = .data[[focal_col]] %in% focal_values,
    .alpha_val = if_else(.focal, FOCAL_ALPHA, CTX_ALPHA),
    .size_val  = if_else(.focal, 2.5, 1.0)
  )
}

sig_shape_scale <- function(thresh = 0.05) {
  scale_shape_manual(values = c("TRUE" = 16, "FALSE" = 1),
                     labels = c("TRUE" = paste0("p<", thresh), "FALSE" = "NS"),
                     name = NULL)
}
sig_color_scale <- function(thresh = 0.05) {
  scale_color_manual(values = c("TRUE" = SIG_FILL, "FALSE" = NS_FILL),
                     labels = c("TRUE" = paste0("p<", thresh), "FALSE" = "NS"),
                     name = NULL)
}
```

### 1e. Save Helpers — PDF + PNG 동시 저장
```r
save_panel <- function(p, fig_name, panel, variant = NULL,
                       width_mm = 80, height_mm = 60, dpi = 300) {
  base <- if (is.null(variant)) sprintf("%s_%s", fig_name, panel)
          else                  sprintf("%s_%s_%s", fig_name, panel, variant)
  for (ext in c("pdf", "png")) {
    ggsave(file.path(PANEL_DIR, paste0(base, ".", ext)), p,
           width = width_mm/25.4, height = height_mm/25.4, units = "in",
           dpi = if (ext == "pdf") NA else dpi)
  }
}
```

### 1f. Statistical Helpers
```r
fdr_label <- function(q) {
  case_when(q <= 0.001 ~ "q<0.001",
            q <= 0.01  ~ "q<0.01",
            q <= 0.05  ~ "q<0.05",
            q <= 0.10  ~ "q<0.10",
            TRUE       ~ "NS")
}
```

### 1g. Catalog Adapter Helpers (NEW)
For catalog clone-modify pattern:
```r
# Helper used in panel files to assert narrative numbers match data
assert_narrative <- function(actual, expected, tolerance = 0.1, label = "") {
  if (abs(actual - expected) > tolerance) {
    stop(sprintf("[ASSERT FAIL] %s: actual=%.3f, expected=%.3f (tol=%.2f)",
                 label, actual, expected, tolerance))
  }
}
```

## Pattern 2: Per-Figure Script (granularity = figure)

```r
# code/Fig{N}.R — entry point, sources per-panel files
source("00_common.R")

# DATA LOADING — top of script, single load
data_main <- read_tsv(SSOT$key, show_col_types = FALSE)

# SOURCE PER-PANEL FILES (each renders its own panel)
source("Fig{N}_a.R")
source("Fig{N}_b.R")
source("Fig{N}_c.R")
# ...
```

## Pattern 3: Per-Panel Script (granularity = panel)

When design doc has `catalog_ref`, **clone-modify**:

```r
# code/Fig{N}_{p}.R
# MESSAGE: {single-message from design doc}
# EXPECTED: {narrative number, e.g., "MB-WNT median entropy = 1.8"}
# CATALOG_REF: {catalog path L{X}-{Y}, paper_panel: {ref}}

# ─────────────────────────────────────────────────────────────
# Panel {p} for Fig{N}
# Cloned-and-adapted from: {catalog path L{X}-{Y}}
# Original primitive: {primitive_used from catalog}
# ─────────────────────────────────────────────────────────────

# (Adapted code — see "Catalog Clone-Modify Workflow" below)

# ASSERTION (P14 enforcement): narrative number ↔ data
assert_narrative(median(mb_df$entropy[mb_df$subgroup=="WNT"]), 1.8,
                 tolerance = 0.3, label = "MB-WNT median entropy")

# Render
save_panel(p, "Fig{N}", "{p}", width_mm = 70, height_mm = 60)
```

When design doc has NO catalog_ref (orphan / new visualization):
```r
# (Standard from-scratch ggplot — log warning in implementation log)
```

## Catalog Clone-Modify Workflow (panel granularity)

Step-by-step:

1. **Read panel design** → extract `catalog_ref: {path, lines, primitives_used}`
2. **`Read` catalog file** at specified line range (e.g., `Read(path, offset=10, limit=7)`)
3. **Identify replacement points**:
   - Variable names (catalog's `df_apobec` → our `mb_df`)
   - Column references (catalog's `gdel` → our `subgroup`)
   - Palette calls (catalog's `pal_nejm()` → our `MB_SUBTYPE_COLORS`)
   - Annotation text (catalog's title → narrative claim)
4. **Generate adapted code** preserving structure (geoms, theme, layer order)
5. **Inject MESSAGE/EXPECTED/CATALOG_REF comments** at top
6. **Inject `assert_narrative()` calls** for each `Expected number` from design doc
7. **Render with `save_panel()`** using design doc's panel size

Example transformation:

```r
# CATALOG ORIGINAL (08_breast/github/APOBEC3A3B_germline_deletion.R L10-16):
df_tmb %>% left_join(df_apobec) %>%
  ggplot(aes(x=gdel, y=log(tmb), fill=gdel)) +
  geom_violin(draw_quantiles = c(0.5)) +
  geom_signif(comparisons=list(c("homo","hetero"), c("hetero","wt"))) +
  scale_fill_nejm() +
  theme_minimal() + theme(legend.position='none')

# ADAPTED for our Fig2 panel c:
mb_df %>%
  ggplot(aes(x = subgroup, y = entropy, fill = subgroup)) +
  geom_violin(draw_quantiles = c(0.5)) +
  geom_signif(comparisons = list(c("WNT","SHH"), c("SHH","G3"), c("G3","G4"))) +
  scale_fill_manual(values = MB_SUBTYPE_COLORS) +  # from 00_common
  theme_nature() + theme(legend.position = "none")
```

## Hard Rules for Code (C1-C8 + V1-V9)

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

### Visual Storytelling (V1-V9)
```
V1  FOCUS: 모든 geom에 .focal 기반 alpha/color/size 분기.
V2  INK: theme_nature() 사용 필수.
V3  ENCODE: significance를 시각적으로 인코딩 (filled vs hollow, NOT stars).
V4  AXIS: 축당 최대 20 items.
V5  LAYER: 전경/배경 분리 (background grey first, focal colored last).
V6  TABLE-FREE: ggplot으로 표 그리지 않기.
V7  CLAIM-IN-CODE: title/subtitle이 design doc claim과 일치.
V8  TRANSITION: 각 panel 상단에 transition comment.
V9  LIMITATION: NS/validation 실패는 subtitle에 명시.
```

### NEW: Catalog Compliance (CC1-CC3)
```
CC1 design doc에 catalog_ref 있으면 반드시 clone-modify (from-scratch 금지)
CC2 catalog_ref 없는 경우 implementation log에 warning 기록 (orphan panel)
CC3 catalog code 변경 시 # CATALOG_REF 주석에 변경 요약 명시
```

### NEW: Assertion Compliance (A1-A2)
```
A1 design doc의 모든 "Expected number"는 코드 내 assert_narrative() 호출로 검증
A2 assertion 실패 시 stop() — 사용자가 반드시 인지해야 함 (silent fail 금지)
```

## Variant Generation (P5)

For panels with ≥2 variants (per design doc):

```r
# Each variant rendered separately
plot_fig{N}_{p} <- function(variant = c("v1", "v2")) {
  variant <- match.arg(variant)
  if (variant == "v1") {
    # layout 1
  } else {
    # layout 2 (alt aesthetic, e.g., dot vs bar)
  }
}

for (v in c("v1", "v2")) {
  save_panel(plot_fig{N}_{p}(v), "Fig{N}", "{p}", v,
             width_mm = 70, height_mm = 60)
}

# Comparison sheet (auto-generated)
library(patchwork)
comp <- plot_fig{N}_{p}("v1") + plot_fig{N}_{p}("v2") +
  plot_annotation(title = "Fig{N}-{p}: v1 (L) vs v2 (R)")
ggsave(file.path(COMP_DIR, "Fig{N}_{p}_comparison.pdf"), comp,
       width = 160/25.4, height = 70/25.4, units = "in")
```

User selects preferred variant via `/figure-build` Phase F2 result tracking.

## Panel Subtitle Convention
모든 panel subtitle 에 포함:
1. **Sample size**: `n=115` or `NP=77, Prog=38`
2. **Scope**: `538 taxa x 191 features`
3. **Method**: `Pearson | FDR (BH)`
4. **Adjustment**: `batch+age adjusted` (해당 시)

Format: `"{scope} | {method} | {sample}"`

## Visual Hierarchy Quick Reference

### Forest Plot
```r
ggplot(df, aes(x = estimate, y = reorder(feature, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.3, color = "grey60") +
  geom_point(data = df %>% filter(!.focal),
             color = CTX_GREY, size = 1, alpha = CTX_ALPHA) +
  geom_errorbarh(data = df %>% filter(!.focal),
                 aes(xmin = ci_lo, xmax = ci_hi),
                 height = 0, color = CTX_GREY, alpha = CTX_ALPHA) +
  geom_point(data = df %>% filter(.focal),
             aes(color = sig, shape = sig), size = 2.5) +
  geom_errorbarh(data = df %>% filter(.focal),
                 aes(xmin = ci_lo, xmax = ci_hi, color = sig),
                 height = 0) +
  sig_color_scale() + sig_shape_scale() +
  theme_nature() + PANEL_TAG_THEME
```

### Scatter with Emphasis
```r
ggplot(df, aes(x = x, y = y)) +
  geom_point(data = df %>% filter(!.focal),
             color = CTX_GREY, alpha = CTX_ALPHA, size = 1) +
  geom_point(data = df %>% filter(.focal),
             aes(color = group), size = 2, alpha = FOCAL_ALPHA) +
  geom_smooth(data = df %>% filter(.focal),
              method = "lm", se = TRUE, linewidth = 0.6) +
  theme_nature()
```

### Connected Stage Plot (slopegraph alternative)
```r
ggplot(df, aes(x = stage, y = effect, group = feature)) +
  geom_line(data = df %>% filter(!.focal),
            color = CTX_GREY, alpha = CTX_ALPHA, linewidth = 0.3) +
  geom_line(data = df %>% filter(.focal),
            aes(color = feature), linewidth = 0.8) +
  geom_point(data = df %>% filter(.focal),
             aes(color = feature, shape = sig), size = 2.5) +
  theme_nature()
```

## Granularity Behavior Summary

| Granularity | Reads | Writes | Catalog usage | Skip if exists |
|-------------|-------|--------|---------------|----------------|
| `figure` | Fig{N}_design.md, BASELINE, STYLE_GUIDE | 00_common.R + Fig{N}.R + all Fig{N}_{p}.R + all panels | once per panel | 00_common.R if exists (don't overwrite) |
| `panel` | Fig{N}_{p}_design.md, 00_common.R | Fig{N}_{p}.R + Fig{N}_{p}.pdf/png + variants | mandatory if catalog_ref present | (none — always re-render panel) |

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| 색상 literal (e.g., `"#E65100"`) figure script 안에 | C6 위반. 00_common.R에서 `DX_PRIMARY[["NB"]]` 참조 |
| from-scratch when catalog_ref exists | CC1 위반. Read catalog at L{X}-{Y} → adapt |
| assertion 빠뜨림 | A1 위반. 모든 Expected number → assert_narrative() |
| ComplexHeatmap 사용 | (server viewport bug) → ggplot2 + geom_tile 또는 patchwork composite |
| 변수명 충돌 (catalog `df` ↔ ours `df`) | adapt 시 우리 데이터프레임 변수 이름으로 교체 |
| 00_common.R 중복 source() | granularity=figure 만 source; granularity=panel 은 in-memory 가정 |
| ggplot 객체를 file에 직접 ggsave (variant 누락) | save_panel() 사용 (PDF+PNG 자동) |

## Python Equivalent
R이 아닌 Python을 쓸 경우:
- `SSOT = { "key": Path(...) }` dict 사용
- `fig, ax = plt.subplots()` 패턴
- class-based: `FigureN.panel_A(variant="heatmap")`
- `fig.savefig(path, dpi=300, bbox_inches='tight')`
- catalog clone-modify는 동일 (Read original .py → adapt → save)
