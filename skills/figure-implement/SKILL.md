---
name: figure-implement
description: Phase 2 — Convert design document to executable figure code (R/ggplot2 or Python/matplotlib)
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /figure-implement — Phase 2: Design Doc → Code

$ARGUMENTS: design document 경로 또는 figure 번호

## Role
Scientific figure implementer. Design doc을 실행 가능한 코드로 변환.

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

**1b. Centralized Palettes (P7)** — 색상/라벨 정의는 오직 여기서만
```r
GROUP_COLORS  <- c(GroupA = "#color1", GroupB = "#color2")
MODULE_COLORS <- c(...)
```

**1c. Theme** — `theme_paper(base_size = 8)` 정의
**1d. Save Helpers** — `save_panel()`, `save_comparison()` — PDF + PNG 동시 저장
**1e. Statistical Helpers** — `fdr_star()`, `fdr_label()`

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

## Hard Rules for Code

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

## Panel Subtitle Convention
모든 panel subtitle에 포함:
1. **Sample size**: `n=115` or `NP=77, Prog=38`
2. **Scope**: `538 taxa x 191 features = 102,758 tests`
3. **Method**: `Pearson | FDR (BH)`
4. **Adjustment**: `batch+age adjusted` (해당 시)

Format: `"{scope} | {method} | {sample}"`

## Python Equivalent
R이 아닌 Python을 쓸 경우:
- `SSOT = { "key": Path(...) }` dict 사용
- `fig, ax = plt.subplots()` 패턴
- class-based: `FigureN.panel_A(variant="heatmap")`
- `fig.savefig(path, dpi=300, bbox_inches='tight')`
