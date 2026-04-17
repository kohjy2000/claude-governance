---
name: figure-implement
description: Phase 2 — Convert design document to executable figure code with visual storytelling (P1-P13) and content integrity (P14-P16). Supports two granularities (figure-level writes 00_common.R + Fig{N}.R + all panels vs panel-level writes only Fig{N}_{p}.R). When panel design has catalog reference, clones-and-adapts code instead of writing from scratch. Appends PANEL_REGISTRY entries and dispatches figure-reviewer subagent when complete.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Agent
---

# /figure-implement — Phase 2: Design Doc → Code

`$ARGUMENTS`:
- `granularity=figure|panel` (default: figure)
- `target=Fig{N}` (required)
- `panel={letter}` (required when granularity=panel)
- optional: design document path (default: derived from target/panel)

**Schemas**:
- Input: `~/.claude/blueprints/schemas/FIGURE_PLAN.schema.md`
- Output registry: `~/.claude/blueprints/schemas/PANEL_REGISTRY.schema.md`
- Input catalog: `docs_figure/SCRIPT_CATALOG.yml`

## Role
Scientific figure implementer. Design doc을 실행 가능한 코드로 변환.
P8-P13 visual storytelling 원칙을 코드 레벨에서 강제.

**Granularity dispatch**:
- `granularity=figure`: writes `00_common.R` (if missing) + `Fig{N}.R` (entry) + all panel files
- `granularity=panel`: writes only `Fig{N}_{p}.R` for one panel; reads existing `00_common.R`

**Catalog clone-modify pattern** (when design doc has `catalog_ref`): instead of writing visualization from scratch, clones the catalog script's code at the specified line range, then adapts variables/palette/labels.

**PANEL_REGISTRY append**: every `save_panel()` call records variant in `docs_figure/PANEL_REGISTRY.md`.

**Final step**: after panel rendering, dispatch `figure-reviewer` subagent via Task tool (see Step N).

## Step 0: Selective Context Loading — **전체 SSOT Read 금지**

Design doc에서 필요한 claim과 데이터만 추출하여 최소한의 context만 로드한다.
전체 CLAIMS.md나 DATA_MAP.md를 Read하면 관련 없는 claim 숫자가 context를 오염시켜
cross-contamination (다른 figure의 수치를 현재 figure에 혼입) 위험이 높아진다.

### 0-1. Design doc 읽기 (FIRST — 항상 최우선)
```
Read: docs_figure/figure_pipeline/design_docs/Fig{N}_design.md
```

### 0-2. Claim ID 추출
Design doc에서 참조된 claim ID를 수집:
- Figure-level: `**Claims supported**: C2 (main), C3 (supp)` → claim groups = {C2, C3}
- Panel-level: `**Claim**: C2-1` → specific claims = {C2-1}

### 0-3. CLAIMS.md — 해당 claim group 섹션만 읽기
```bash
# 예: C2 그룹만 추출 (## C2 ~ 다음 ## 전까지)
grep -n "^## C" docs/CLAIMS.md          # 섹션 위치 파악
sed -n '/^## C2$/,/^## C[0-9]/p' docs/CLAIMS.md | head -n -1  # C2 섹션만
```
**절대 `Read docs/CLAIMS.md` 전체를 하지 않는다.** Bash grep/sed로 필요 섹션만 추출.

### 0-4. DATA_MAP.md — 해당 SSOT key만 읽기
Design doc의 `**Data source**: SSOT$mutation_matrix; SSOT$cluster_assignment`에서 key 추출 후:
```bash
# Header + 해당 key 행만 추출
head -20 docs/DATA_MAP.md               # Base Paths 섹션 (경로 해석용)
grep -E "^\| (Key|mutation_matrix|cluster_assignment) " docs/DATA_MAP.md  # 필요한 key만
```
**절대 `Read docs/DATA_MAP.md` 전체를 하지 않는다.**

### 0-5. Context budget 확인
로드된 context 요약 출력:
```
Selective load: {N} claims from {M} groups, {K} SSOT keys
Skipped: {total_claims - N} claims, {total_keys - K} keys
```

### 왜 이렇게 하는가
| 방식 | 토큰 | 위험 |
|------|-------|------|
| Read CLAIMS.md 전체 (800줄) | ~3,000 | 다른 figure 숫자 cross-contamination |
| Selective (해당 group만, ~50줄) | ~200 | 해당 claim만 context에 존재 |
| Read DATA_MAP.md 전체 (670줄) | ~2,500 | 불필요한 key가 SSOT registry 오염 |
| Selective (해당 key만, ~5줄) | ~50 | 정확한 path만 |

**절약 추정: panel당 ~5,000 토큰 → ~250 토큰 (95% 절감)**

## Output Structure

```
<project_root>/
├── code/
│   ├── 00_common.R             # Infrastructure (created by figure-level; reused by panel-level)
│   ├── Fig{N}.R                # Figure entry script (sources panel files)
│   └── Fig{N}_{p}.R            # Per-panel R code (catalog-derived if cataloged)
├── docs_figure/
│   └── PANEL_REGISTRY.md       # auto-updated by save_panel()
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

### 1e. Save Helpers — PDF + PNG + PANEL_REGISTRY append
```r
save_panel <- function(p, fig_name, panel, variant = NULL,
                       width_mm = 80, height_mm = 60, dpi = 300,
                       notes = "") {
  base <- if (is.null(variant)) sprintf("%s_%s", fig_name, panel)
          else                  sprintf("%s_%s_%s", fig_name, panel, variant)
  for (ext in c("pdf", "png")) {
    ggsave(file.path(PANEL_DIR, paste0(base, ".", ext)), p,
           width = width_mm/25.4, height = height_mm/25.4, units = "in",
           dpi = if (ext == "pdf") NA else dpi)
  }
  # v1.2: append to PANEL_REGISTRY
  append_panel_registry(fig_name, panel, variant %||% "default",
                        file.path("output/panels", paste0(base, ".pdf")),
                        "pdf", "draft", notes)
}

`%||%` <- function(a, b) if (!is.null(a)) a else b

append_panel_registry <- function(fig, panel, variant, file, format,
                                   status = "draft", notes = "") {
  registry_path <- "docs_figure/PANEL_REGISTRY.md"
  date <- format(Sys.time(), "%Y-%m-%d")
  panel_id <- paste0(fig, panel)
  # Selected at is empty when status=draft (schema: only set on transition to selected)
  selected_at <- if (status == "selected") date else ""
  row <- sprintf("| %s | %s | %s | %s | %s | %s | %s |",
                 panel_id, variant, file, format, status, selected_at, notes)
  cat(row, "\n", file = registry_path, append = TRUE)
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

### 1g. Catalog Adapter Helpers
For catalog clone-modify pattern:
```r
# Assert narrative numbers match data (P14 + A1)
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
# CLAIM_REF: {CLAIMS.md C{group}-{N}}

# ─────────────────────────────────────────────────────────────
# Panel {p} for Fig{N}
# Cloned-and-adapted from: {catalog path L{X}-{Y}}
# Original primitive: {primitive_used from catalog}
# ─────────────────────────────────────────────────────────────

# (Adapted code — see "Catalog Clone-Modify Workflow" below)

# ASSERTION (P14 enforcement): narrative number ↔ data
assert_narrative(median(mb_df$entropy[mb_df$subgroup=="WNT"]), 1.8,
                 tolerance = 0.3, label = "MB-WNT median entropy")

# Render + PANEL_REGISTRY append automatic via save_panel()
save_panel(p, "Fig{N}", "{p}", variant = "v1-violin",
           width_mm = 70, height_mm = 60,
           notes = "catalog clone-modify from APOBEC deletion")
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
   - Palette calls (catalog's `pal_nejm()` → our BASELINE palette)
   - Annotation text (catalog's title → narrative claim from CLAIMS.md)
4. **Generate adapted code** preserving structure (geoms, theme, layer order)
5. **Inject MESSAGE/EXPECTED/CATALOG_REF/CLAIM_REF comments** at top
6. **Inject `assert_narrative()` calls** for each `Expected number` from design doc
7. **Render with `save_panel()`** — auto-appends to PANEL_REGISTRY

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

## Hard Rules for Code (C1-C8 + V1-V9 + CC1-CC3 + A1-A2)

### Structural (C1-C8)
```
C1  모든 read_*() 호출은 SSOT key 참조. 원시 경로 금지.
C2  데이터는 스크립트 상단에서 로드. panel 함수 안에서 로드 금지.
C3  Panel 함수는 variant= 인자 + match.arg() 패턴.
C4  save_panel()은 PDF + PNG 동시 생성 + PANEL_REGISTRY append.
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
V7  CLAIM-IN-CODE: title/subtitle이 CLAIMS.md Statement + Limitation과 verbatim.
V8  TRANSITION: 각 panel 상단에 transition comment.
V9  LIMITATION: NS/validation 실패는 subtitle에 명시.
```

### Catalog Compliance (CC1-CC3)
```
CC1 design doc에 catalog_ref 있으면 반드시 clone-modify (from-scratch 금지)
CC2 catalog_ref 없는 경우 implementation log에 warning 기록 (orphan panel)
CC3 catalog code 변경 시 # CATALOG_REF 주석에 변경 요약 명시
```

### Assertion Compliance (A1-A2)
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

for (v in c("v1-violin", "v2-dumbbell")) {
  save_panel(plot_fig{N}_{p}(v), "Fig{N}", "{p}", v,
             width_mm = 70, height_mm = 60)
}

# Comparison sheet
library(patchwork)
comp <- plot_fig{N}_{p}("v1-violin") + plot_fig{N}_{p}("v2-dumbbell") +
  plot_annotation(title = "Fig{N}-{p}: v1 (L) vs v2 (R)")
ggsave(file.path(COMP_DIR, "Fig{N}_{p}_comparison.pdf"), comp,
       width = 160/25.4, height = 70/25.4, units = "in")
```

Variant 이름은 `v{K}-<descriptor>` 형식 (PANEL_REGISTRY.schema 준수).

## Panel Subtitle Convention
모든 panel subtitle 에 포함:
1. **Sample size**: `n=115` or `NP=77, Prog=38`
2. **Scope**: `538 taxa x 191 features`
3. **Method**: `Pearson | FDR (BH)`
4. **Adjustment**: `batch+age adjusted` (해당 시)
5. **Limitation**: CLAIMS.md `Limitation` field verbatim (P16)

Format: `"{scope} | {method} | {sample} | {limitation}"`

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
| `figure` | Fig{N}_design.md, BASELINE, STYLE_GUIDE, CATALOG | 00_common.R + Fig{N}.R + all Fig{N}_{p}.R + all panels | once per panel | 00_common.R if exists (don't overwrite) |
| `panel` | Fig{N}_{p}_design.md, 00_common.R | Fig{N}_{p}.R + Fig{N}_{p}.pdf/png + variants | mandatory if catalog_ref present | (none — always re-render panel) |

## Step N (last): Dispatch figure-reviewer subagent — **SKILL CONTRACT, 생략 금지**

Panel 렌더링 + PANEL_REGISTRY append가 끝나면 **반드시 이 turn 내에 Task tool로 figure-reviewer subagent를 spawn**:

```
# Model selection logic (per-invocation override):
#   opus  — granularity=figure (Layer 0-1 cross-panel story arc) OR multimodal=true (Layer 4 rendered vision)
#   sonnet — granularity=panel (Layer 2-4 content/visual only), multimodal=false
#
# figure-reviewer AGENT.md의 default는 sonnet. 아래 model 파라미터가 per-invocation override.

model_choice = "opus" if (granularity == "figure" or multimodal) else "sonnet"

Agent(subagent_type="figure-reviewer", 
      model=model_choice,
      description="Review Fig{N}",
      prompt="Review Fig{N} (granularity={granularity}, multimodal={true|false}) in the current project. 
              Read docs_figure/figure_pipeline/design_docs/Fig{N}_design.md, 
              docs/CLAIMS.md, docs_figure/PANEL_REGISTRY.md, 
              and docs_figure/hook.log if present.
              {if multimodal: Also read rendered PNG from output/panels/ for Layer 4 vision review.}
              Write one REVIEW_LOG entry per REVIEW_LOG.schema. 
              Return 3-line summary.")
```

**Model selection 근거**:
- `granularity=figure`는 Layer 0 (Story Arc) + Layer 1 (Figure Role) 판단 필요 — narrative reasoning 품질이 중요하므로 opus.
- `multimodal=true`는 Layer 4 (Rendered Image) — 이미지 인식 정확도가 중요하므로 opus.
- `granularity=panel`은 Layer 2-4 content/visual check — 구조화된 rule 체크이므로 sonnet 충분.

### 왜 생략 금지인가
- figure-implement와 figure-review는 **atomic pair**. implement만 돌고 review가 생략되면 REVIEW_LOG append-only audit trail이 끊어짐.
- Smoke test에서 slash command chain skip 확인됨 — Task tool dispatch로 격상.
- Phase 6 Turn 3의 PostToolUse hook이 추가되면 hard enforcement 완성.

### Enforcement checklist

```
[ ] panels/ 디렉토리에 기대한 파일 생성됨
[ ] PANEL_REGISTRY.md에 새 row append됨
[ ] figure-reviewer subagent를 Task tool로 spawn함
[ ] Subagent가 REVIEW_LOG.md에 새 Review entry append함 (grep 확인)
[ ] Subagent 3줄 요약을 user에게 보고함
```

4번째까지 통과하지 못하면 figure-implement는 **불완전 완료**. Subagent FAIL 반환 시 action items를 user에 보고.

### Fallback (subagent 불가 시)
- Main thread가 이미 subagent인 경우 → Task 중첩 불가. Legacy slash command `/figure-review --auto Fig{N}` 사용.
- User가 `--skip-review` argument 전달 시만 생략 허용.

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| 색상 literal (e.g., `"#E65100"`) figure script 안에 | C6 위반. 00_common.R에서 `DX_PRIMARY[["NB"]]` 참조 |
| from-scratch when catalog_ref exists | CC1 위반. Read catalog at L{X}-{Y} → adapt |
| assertion 빠뜨림 | A1 위반. 모든 Expected number → assert_narrative() |
| ComplexHeatmap 사용 | (server viewport bug) → ggplot2 + geom_tile 또는 patchwork composite |
| 변수명 충돌 (catalog `df` ↔ ours `df`) | adapt 시 우리 데이터프레임 변수 이름으로 교체 |
| 00_common.R 중복 source() | granularity=figure 만 source; granularity=panel 은 in-memory 가정 |
| ggplot 객체를 file에 직접 ggsave (variant + PANEL_REGISTRY 누락) | save_panel() 사용 |
| figure-reviewer subagent 호출 skip | Step N enforcement 위반. Smoke test가 감지. |
| PANEL_REGISTRY Selected at이 draft에 채워짐 | schema 위반. append_panel_registry()가 status=draft면 Selected at을 빈 문자열로. |

## Python Equivalent
R이 아닌 Python:
- `SSOT = { "key": Path(...) }` dict
- `fig, ax = plt.subplots()` 패턴
- class-based: `FigureN.panel_A(variant="heatmap")`
- `fig.savefig(path, dpi=300, bbox_inches='tight')`
- PANEL_REGISTRY append helper를 `00_common.py`에 작성 (동일 logic)
- catalog clone-modify 동일 (Read original .py → adapt → save)

## Handoff
- Output design consumer: `figure-reviewer` subagent (Task tool dispatch via Step N).
- PANEL_REGISTRY consumer: `figure-assemble` (selected variant 참조).
- Phase 6 Turn 3 (예정): PostToolUse hook이 Write/Edit matcher로 추가 enforcement.
