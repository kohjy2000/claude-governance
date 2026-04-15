---
name: figure-implement
description: Phase 2 — Convert design document to executable figure code with visual storytelling (P1-P13) and content integrity (P14-P16). v1.2 adds PANEL_REGISTRY append + figure-review auto-invoke.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /figure-implement — Phase 2: Design Doc → Code

`$ARGUMENTS`: design document 경로 또는 figure 번호.

## Role
Scientific figure implementer. Design doc을 실행 가능한 코드로 변환.
P8-P13 visual storytelling 원칙을 코드 레벨에서 강제.

**v1.2 변경**:
- Input: `outputs/figures/FIGURE_PLAN.md` (schema v1.0).
- Output: panel 생성 + `PANEL_REGISTRY.md` append.
- 완료 후 `/figure-review --auto` 자동 호출.

**Schemas**:
- Input: `~/.claude/blueprints/schemas/FIGURE_PLAN.schema.md`
- Output registry: `~/.claude/blueprints/schemas/PANEL_REGISTRY.schema.md`

---

## Output Structure

```
outputs/figures/
├── code/
│   ├── 00_common.R                # Infrastructure (SSOT, palette, theme, helpers)
│   ├── Fig1_<topic>.R             # Per-figure scripts
│   └── Fig2_<topic>.R
├── panels/                        # Individual panel files (PDF + PNG)
│   ├── Fig1_A_v1.pdf
│   ├── Fig1_A_v2.pdf
│   └── ...
└── panels/comparison/             # Side-by-side variant comparisons
    ├── Fig1_A_comparison.pdf
    └── ...
```

---

## Step 0: Read FIGURE_PLAN

`outputs/figures/FIGURE_PLAN.md`가 없으면 STOP. `/figure-plan`을 먼저 돌리라고 지시.

Parse FIGURE_PLAN의 figure-by-figure Panel 엔트리. 각 panel의 Claim ID, Variant 1/2 이름을 확보.

---

## Pattern 1: 00_common.R (Infrastructure)

**1a. SSOT Registry** — 모든 데이터 경로를 여기서 중앙 관리 (DATA_MAP.md와 sync)
```r
SSOT <- list(
  metadata   = file.path(DATA_ROOT, "path/to/metadata.tsv"),
  results    = file.path(DATA_ROOT, "path/to/results.tsv")
)
validate_ssot <- function(strict = TRUE) { ... }
```

**1b. Centralized Palettes (P7 + P8)**
```r
GROUP_COLORS  <- c(GroupA = "#2166AC", GroupB = "#B2182B", GroupC = "#4DAF4A")
CTX_GREY      <- "grey70"
CTX_ALPHA     <- 0.3
SIG_FILL      <- "firebrick"
NS_FILL       <- "grey70"
```

**1c. Publication Theme (P9 + P12 + P13)**
```r
theme_nature <- function(base_size = 7) {
  theme_minimal(base_size = base_size, base_family = "Helvetica") +
    theme(
      plot.title       = element_text(size = base_size + 1, face = "bold", hjust = 0),
      plot.subtitle    = element_text(size = base_size, color = "grey40"),
      axis.title       = element_text(size = base_size),
      axis.text        = element_text(size = base_size - 1, color = "grey30"),
      strip.text       = element_text(size = base_size, face = "bold"),
      legend.text      = element_text(size = base_size - 1),
      legend.title     = element_text(size = base_size, face = "bold"),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.border     = element_blank(),
      plot.margin      = margin(8, 8, 8, 8),
      legend.margin    = margin(0, 0, 0, 4),
      strip.background = element_blank()
    )
}
PANEL_TAG_THEME <- theme(plot.tag = element_text(size = 8, face = "bold"))
```

**1d. Visual Hierarchy Helpers (P8 + P11)**
```r
add_emphasis <- function(df, focal_col, focal_values) {
  df %>% mutate(
    .focal     = .data[[focal_col]] %in% focal_values,
    .fill_col  = if_else(.focal, as.character(.data[[focal_col]]), "context"),
    .alpha_val = if_else(.focal, 1.0, CTX_ALPHA),
    .size_val  = if_else(.focal, 2.5, 1.0)
  )
}
sig_shape_scale <- function() {
  scale_shape_manual(
    values = c("TRUE" = 16, "FALSE" = 1),
    labels = c("TRUE" = "FDR<0.10", "FALSE" = "NS"),
    name   = NULL
  )
}
sig_color_scale <- function(sig_color = SIG_FILL, ns_color = NS_FILL) {
  scale_color_manual(
    values = c("TRUE" = sig_color, "FALSE" = ns_color),
    labels = c("TRUE" = "FDR<0.10", "FALSE" = "NS"),
    name   = NULL
  )
}
```

**1e. Save Helpers** — PDF + PNG 동시 저장 + PANEL_REGISTRY append (v1.2 신규)
```r
save_panel <- function(plot, fig, panel, variant, notes = "") {
  file_base <- sprintf("outputs/figures/panels/%s_%s_%s", fig, panel, variant)
  ggsave(paste0(file_base, ".pdf"), plot, width=89, height=60, units="mm", device=cairo_pdf)
  ggsave(paste0(file_base, ".png"), plot, width=89, height=60, units="mm", dpi=300)
  # v1.2: append to PANEL_REGISTRY.md
  append_panel_registry(fig, panel, variant, paste0(file_base, ".pdf"), "pdf", "draft", notes)
}

append_panel_registry <- function(fig, panel, variant, file, format, status = "draft", notes = "") {
  registry_path <- "outputs/figures/PANEL_REGISTRY.md"
  date <- format(Sys.time(), "%Y-%m-%d")
  panel_id <- paste0(fig, panel)
  row <- sprintf("| %s | %s | %s | %s | %s | %s | %s |",
                 panel_id, variant, file, format, status, date, notes)
  cat(row, "\n", file=registry_path, append=TRUE)
}
```

**1f. Statistical Helpers** — `fdr_label()` (returns "q<0.001" etc.)

---

## Pattern 2: Per-Figure Script

```r
source("00_common.R")
data1 <- read_tsv(SSOT$key, show_col_types = FALSE)

plot_figN_A <- function(variant = c("v1", "v2")) {
  variant <- match.arg(variant)
  if (variant == "v1") { ... } else { ... }
}

# v1.2: save_panel이 자동으로 PANEL_REGISTRY append
for (v in c("v1", "v2")) save_panel(plot_figN_A(v), "Fig1", "A", v)

# Comparison sheet
comp_A <- plot_figN_A("v1") + plot_figN_A("v2") +
  patchwork::plot_annotation(title = "Fig1-A: v1 (L) vs v2 (R)")
save_comparison(comp_A, "Fig1", "A")
```

---

## Hard Rules for Code (C1-C8 + V1-V9)

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
V2  INK: theme_nature() 사용 필수. theme_bw/grey/classic 금지.
V3  ENCODE: significance를 시각적으로 (stars/text 금지).
V4  AXIS: 축당 최대 20 items. 초과 시 top-K 또는 facet.
V5  LAYER: 전경/배경 분리 패턴.
V6  TABLE-FREE: ggplot으로 표 그리지 않기. gt/kableExtra 별도 출력.
V7  CLAIM-IN-CODE: title/subtitle이 CLAIMS.md의 Statement + Limitation과 verbatim 일치.
V8  TRANSITION: panel 상단 comment에 transition sentence.
V9  LIMITATION: NS 또는 validation 실패 결과의 subtitle에 limitation 명시.
```

---

## Panel Subtitle Convention
포함:
1. Sample size: `n=115` or `NP=77, Prog=38`
2. Scope: `538 taxa x 191 features = 102,758 tests`
3. Method: `Pearson | FDR (BH)`
4. Adjustment: `batch+age adjusted` (해당 시)

Format: `"{scope} | {method} | {sample}"`

CLAIMS.md의 `Limitation` 필드를 verbatim 포함 (P16 원칙).

---

## Visual Hierarchy Quick Reference

### Forest Plot
```r
ggplot(df, aes(x = estimate, y = reorder(feature, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.3, color = "grey60") +
  geom_point(data = df %>% filter(!.focal),
             color = CTX_GREY, size = 1, alpha = CTX_ALPHA) +
  geom_errorbarh(data = df %>% filter(!.focal),
                 aes(xmin = ci_lo, xmax = ci_hi),
                 height = 0, color = CTX_GREY, alpha = CTX_ALPHA, linewidth = 0.3) +
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
ggplot(df, aes(x = x, y = y)) +
  geom_point(data = df %>% filter(!.focal),
             color = CTX_GREY, alpha = CTX_ALPHA, size = 1) +
  geom_point(data = df %>% filter(.focal),
             aes(color = group), size = 2, alpha = 0.8) +
  geom_smooth(data = df %>% filter(.focal),
              method = "lm", se = TRUE, linewidth = 0.6) +
  theme_nature()
```

### Connected Stage Plot
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

---

## Python Equivalent
R이 아닌 Python:
- `SSOT = { "key": Path(...) }` dict
- `fig, ax = plt.subplots()` 패턴
- class-based: `FigureN.panel_A(variant="heatmap")`
- `fig.savefig(path, dpi=300, bbox_inches='tight')`
- PANEL_REGISTRY append는 Python에서도 동일 helper (`append_panel_registry(...)`) 작성해 `00_common.py`에 배치.

---

## Step N (last): Dispatch figure-reviewer subagent — **SKILL CONTRACT, 생략 금지**

Panel 생성 + PANEL_REGISTRY append가 끝나면 **반드시 이 turn 내에 Task tool로 figure-reviewer subagent를 spawn**:

```
Agent (subagent_type="figure-reviewer", description="Review Fig{N}",
       prompt="Review Fig{N} in the current project. Read outputs/figures/FIGURE_PLAN.md, docs/CLAIMS.md, outputs/figures/PANEL_REGISTRY.md, and outputs/figures/hook.log if present. Write one REVIEW_LOG entry per the REVIEW_LOG schema. Return 3-line summary.")
```

### 왜 subagent인가 (Phase 6 변경)
- figure-implement와 figure-review는 **atomic pair**. implement만 돌고 review가 생략되면 REVIEW_LOG append-only audit trail이 끊어짐.
- Phase 5.5의 slash command chain (`/figure-review --auto`)은 smoke test에서 **skip되는 것 확인됨** (soft enforcement 한계).
- Phase 6에서 Task tool dispatch로 격상 — subagent description이 "Use PROACTIVELY after figure-implement completes"라 Claude가 자동 delegation 경향 강화.
- Full hard enforcement는 PostToolUse hook (Phase 6 Turn 2)에서 추가 보강 예정.

### Enforcement checklist (LLM이 이 turn 완료 전에 체크)

```
[ ] panels/ 디렉토리에 기대한 파일 생성됨
[ ] PANEL_REGISTRY.md에 새 row append됨
[ ] figure-reviewer subagent를 Task tool로 spawn함
[ ] Subagent가 REVIEW_LOG.md에 새 Review entry append함 (subagent 반환 후 grep으로 확인)
[ ] Subagent 3줄 요약을 user에게 보고함
```

4번째까지 통과하지 못하면 figure-implement는 **불완전 완료**. Subagent가 FAIL 반환했으면 원인 + action item을 user에 명시.

### Task tool 사용이 안 되는 경우 (fallback)

- Main thread가 이미 subagent (`claude --agent`로 실행된 경우) → subagent는 또 spawn 못 함. 이때만 legacy slash command `/figure-review --auto Fig{N}` 로 fallback.
- User가 명시적으로 `--skip-review`를 argument로 전달한 경우 생략 허용.

### Return 처리

Subagent가 반환하는 3줄 중 Overall 필드 기반:
- `PASS`: user에게 "Review completed clean." 간단 보고.
- `L0-FAIL` / `L1-FAIL`: user에게 즉시 STOP 권고 + REVIEW_LOG의 Action items 강조.
- `L2-FAIL`: panel-level 수정 action items 안내.
- `L3-issues-only`: 기계적 경고 있음, 최종 review는 다음 invocation에서.

### Phase 6 Turn 2 이후
PostToolUse hook이 figure-implement의 마지막 Write/Edit 감지 → settings.json의 hook config가 이 dispatch를 system-level enforce. 그때 이 Step N의 soft enforcement는 redundant safety layer가 됨.

---

## 주의사항

- PANEL_REGISTRY append 실패 시 panel 파일은 생성됐어도 registry에 기록 안 된 상태. Next figure-review가 mismatch 감지.
- `save_panel()`이 v1.2 계약. 원래 PDF+PNG만 생성하던 것 + registry append 추가.
- Variant 이름은 `v{K}-<descriptor>` 규격 (PANEL_REGISTRY.schema.md 준수).
