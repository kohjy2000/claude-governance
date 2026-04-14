---
name: figure-style-extract
description: Extracts publication figure conventions from a reference paper PDF and its companion script library. Outputs STYLE_GUIDE.md (panel density, typography, color, layout norms) and SCRIPT_CATALOG.yml (visual-primitive → script reference index). Run by /figure-init or standalone when reference materials change.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, WebFetch
---

# /figure-style-extract — Layer 2 sub-skill: Reference → Style Spec

$ARGUMENTS:
- `paper=<path>` : reference paper PDF (or directory containing PDFs)
- `scripts=<path>` : script catalog directory (R, Python, etc.)
- optional `output_dir=<path>` (default: `docs_figure/`)
- optional `subset=<glob>` to limit script analysis (e.g., `08_breast/github/*`)
- optional `refresh` : re-analyze even if outputs exist

## Role
Extract **publication style conventions** from existing reference materials so the figure pipeline can replicate that quality.
Two primary outputs:
1. **STYLE_GUIDE.md** — what the reference paper looks like (panel density, typography, color norms)
2. **SCRIPT_CATALOG.yml** — indexed registry of reusable visual primitives from the script library

These outputs feed `/figure-plan` (lookup) and `/figure-implement` (clone-modify).

## Inputs

```
reference/
├── papers/
│   └── *.pdf                 ← published paper(s) to learn style from
└── catalog/
    └── **/*.{R,py}           ← companion R/Python scripts that produced those figures
```

If catalog and paper are from same authors → maximum signal (script ↔ panel cross-ref possible).
If only paper available → STYLE_GUIDE only, SCRIPT_CATALOG empty.
If only scripts available → SCRIPT_CATALOG only, STYLE_GUIDE generic.

## Outputs

```
docs_figure/
├── STYLE_GUIDE.md            ← human-readable style spec
└── SCRIPT_CATALOG.yml        ← machine-readable script index
```

## Process

### Step 1 — Validate inputs
- Glob `paper` → list PDFs
- Glob `scripts` → count R/Py files
- If both empty → STOP, ASK user for at least one source
- If outputs exist and not `refresh` → ASK user (overwrite / abort / merge)

### Step 2 — Paper PDF analysis (per figure)
For each reference paper PDF:
1. Identify figure pages (heuristic: pages with "Fig. N" or "Figure N" caption)
2. For each main figure (Fig 1, Fig 2, ..., Fig N):
   - Use `Read` tool with `pages=` param to load specific pages
   - Extract from layout:
     - **panel count** (number of sub-labels a, b, c, ...)
     - **panel arrangement** (grid pattern from spatial layout)
     - **estimated panel sizes** (approx mm based on page proportions)
     - **panel types** (heatmap, KM, scatter, bar, donut, violin, network, etc.)
       - Visual cue heuristics:
         - rectangular grid with color gradient → heatmap
         - stepped survival lines → KM
         - dense scatter with regression → scatter
         - parallel horizontal bars → bar/forest
         - circular sectors → donut/pie
         - violin shapes → distribution
   - Extract from caption text:
     - Sample sizes (n=)
     - Statistical methods (Wilcoxon, Cox, Fisher, etc.)
     - Color legend semantics (subtype colors, significance levels)
3. Aggregate across all figures:
   - Mean/median panel count per figure
   - Most common panel types
   - Typography hierarchy (font size estimates from caption text size)
   - Color palette (extract dominant colors per panel via heuristic)

### Step 3 — Script library analysis
For each `*.R` (or `*.py`) in `scripts`:
1. `Read` file (or sample first 200 lines if very large)
2. Extract metadata:
   - **library calls**: `library(ggplot2)`, `library(ggsurvfit)`, etc.
   - **visual primitives**: `geom_*`, `geom_tile`, `ggsurvfit`, `ggcorrplot`, `coord_polar`, etc.
   - **theme conventions**: `theme_minimal`, `theme_classic`, custom themes
   - **palette calls**: `pal_jco()`, `pal_nejm()`, `scale_fill_*`
   - **statistical methods**: `coxph`, `survdiff`, `wilcox.test`, `corr.test`, etc.
   - **data structure assumed**: tibble columns referenced
   - **claim type** (heuristic from comments + plot type):
     - KM + ggsurvfit → "stratified survival"
     - corrplot → "co-activation structure"
     - violin + signif → "distribution comparison"
     - donut → "composition"
     - heatmap + dendrogram → "landscape clustering"
   - **panel size** (if `ggsave(width=, height=)` present)
3. Section/block detection:
   - Many large scripts contain multiple panels (e.g., `figure_1_v1.R` has Fig 1 a, b, c, d sections)
   - Detect by comment headers (`# Figure 1A`, `# panel B`, etc.)
   - Record line ranges per detected panel

### Step 4 — Cross-reference scripts to paper panels
For each script panel block, attempt to match to paper figure panel:
- **Strong match**: script comment explicitly references "Figure N panel X"
- **Medium match**: visual primitive + claim type matches paper panel
- **Weak match**: only library/theme overlap
- **No match**: script orphan (not in paper, but in catalog — still index)

Output cross-ref in SCRIPT_CATALOG.yml.

### Step 5 — Synthesize STYLE_GUIDE.md
Combine paper + script analysis into prescriptive style spec:

- Per-figure panel density: "main figure should have N sub-panels (range observed: X-Y)"
- Per-panel size budget: "panel typically W×H mm (median observed)"
- Typography hierarchy: "panel-tag bold lowercase 8pt | title 7pt | axis 6pt | annotation 5pt"
- Color conventions:
  - Primary palette: extracted hex codes
  - Significance encoding: filled vs hollow (no stars)
  - Focal vs context: alpha/saturation rules
- Layout patterns: "top-heavy (1 large + small grid)" or "uniform grid" with examples
- Annotation patterns: inline tiny labels vs strip headers vs callouts
- Theme baseline: minimal-style, no panel border, no gridlines except major.y

### Step 6 — Generate SCRIPT_CATALOG.yml
Machine-readable index keyed by visual primitive type. See template below.

### Step 7 — Validation
- Every script block has `path` + `lines` + `visual_type` (required fields)
- Every visual primitive type referenced in STYLE_GUIDE has ≥1 catalog entry
- Cross-ref strength distribution: report (e.g., "strong=15, medium=42, weak=28, orphan=5")

If catalog has 0 strong matches and >50 orphans → WARN: catalog may be from different paper.

## Output File Templates

### STYLE_GUIDE.md
```markdown
# Figure Style Guide
Generated: {date} by /figure-style-extract
Source paper(s): {paper_paths}
Source scripts: {scripts_dir} ({N} files indexed)

## Panel Density (per main figure)
- Median: {N_med} sub-panels
- Range: {N_min} – {N_max}
- Typical layout: {top-heavy / grid / mixed}
- Recommended for our paper: 6-10 sub-panels per main figure

## Panel Size Budget (mm)
- Single-column main panel: {W} × {H} mm (median)
- Inset panel: {W} × {H} mm (median)
- Genome landscape (full-width): up to 183 × 50 mm
- Recommended: composite at Nature 183mm full-width, panels 60-80mm

## Typography Hierarchy
- panel tag (a, b, c): 8pt **bold** lowercase
- panel title: 7pt
- axis title: 6pt
- axis text: 5pt
- annotation: 4-5pt
- legend: 5pt
- All Helvetica or Arial

## Color Conventions

### Subtype/Group palette (extracted from paper)
{group_1}: "{hex}"
{group_2}: "{hex}"
...

### Significance encoding
- Significant: filled circle (shape=16) + saturated color
- NS: hollow circle (shape=1) + grey70
- NEVER use stars (★) or asterisks for significance

### Focal vs Context (P8)
- Focal: full saturation, alpha=0.95, larger size (size=2.5)
- Context: grey70, alpha=0.25-0.30, smaller (size=1.0)

## Theme Baseline
- Use theme_minimal() or theme_classic() base
- Remove: panel.border, panel.grid.minor, panel.grid.major.x
- Keep: panel.grid.major.y (if useful for reference lines)
- No decorative elements (shadows, gradients, rounded corners)

## Layout Patterns Observed
1. **Top-heavy** ({N} figures): 1 large landscape panel + grid below
2. **Uniform grid** ({N} figures): equal-size sub-panels in rows
3. **Mixed** ({N} figures): mix of large + small in irregular layout

Recommended: choose layout per figure role (LANDSCAPE → top-heavy, MECHANISM → uniform grid)

## Annotation Patterns
- Sample size: in-panel "n=N" inline label
- p-value: in-panel "p=X" or table form (avoid stars)
- Group label: directly on plot region (no separate legend if possible)
- Reference line: dashed, color="grey60", linewidth=0.3

## Reference Cross-reference
Paper figures analyzed:
- Fig 1: {N_panels} panels, layout={pattern}
- Fig 2: ...
- ...

Catalog scripts indexed: {N} files, {N_blocks} panel blocks detected
- Strong cross-ref to paper: {N_strong}
- Medium cross-ref: {N_medium}
- Weak cross-ref: {N_weak}
- Orphan (not in paper): {N_orphan}
```

### SCRIPT_CATALOG.yml
```yaml
# Generated by /figure-style-extract
# Indexed by visual primitive type
# Used by /figure-plan (lookup) and /figure-implement (clone-modify)

_meta:
  generated_at: 2026-04-14T15:30:00
  source_paper: reference/papers/sxxxxx-2025.pdf
  source_scripts: reference/catalog/
  total_scripts: 112
  total_panel_blocks: 145

primitives:

  kaplan_meier:
    description: "Stratified survival curves with risk table"
    catalog:
      - path: 08_breast/github/HRD_for_adjuvant_chemotherapy.R
        lines: [17, 25]
        primitives_used: [ggsurvfit, add_risktable, scale_color_jco]
        claim_type: "stratified survival"
        panel_size_mm: [60, 80]
        paper_panel: "Fig 2f"
        cross_ref_strength: strong
        notes: "DFS by HRD status, multivariate Cox forest adjacent"

      - path: 08_breast/github/another_km.R
        lines: [50, 75]
        ...

  correlation_heatmap:
    description: "Pairwise correlation with significance encoding"
    catalog:
      - path: 08_breast/github/signature_interactions.R
        lines: [3, 11]
        primitives_used: [ggcorrplot, corr.test, scale_fill_continuous_diverging]
        claim_type: "co-activation structure"
        panel_size_mm: [70, 70]
        paper_panel: "Fig 2b"
        cross_ref_strength: strong
        notes: "Signature × signature correlation, focal cluster highlighted"

  stacked_bar:
    description: "Categorical proportion bar"
    catalog:
      - path: 08_breast/github/mutations_in_HR_pathway.R
        lines: [259, 273]
        primitives_used: [geom_bar, scale_fill_manual, coord_flip]
        claim_type: "category enrichment"
        panel_size_mm: [80, 60]
        paper_panel: "Fig 2e"
        cross_ref_strength: strong

  violin_signif:
    description: "Distribution + pairwise significance"
    catalog:
      - path: 08_breast/github/APOBEC3A3B_germline_deletion.R
        lines: [10, 16]
        primitives_used: [geom_violin, geom_signif, scale_fill_nejm]
        claim_type: "distribution comparison"
        paper_panel: "Fig 2h (lower)"

  scatter_2d:
    description: "2D scatter with category coloring"
    catalog:
      - path: 08_breast/github/ERBB2_amplification.R
        lines: [59, 63]
        primitives_used: [geom_point, geom_hline, geom_vline, scale_color_jco]
        claim_type: "two-feature segregation"
        notes: "aspect.ratio=1, no grid"

  donut:
    catalog:
      - path: 08_breast/github/APOBEC3A3B_germline_deletion.R
        lines: [5, 7]
        primitives_used: [geom_col, coord_polar]

  binned_sliding_bar:
    catalog:
      - path: 08_breast/github/APOBEC3A3B_germline_deletion.R
        lines: [19, 24]

  signature_landscape:
    catalog:
      - path: 08_breast/github/signature_landscape.R
        lines: [1, 25]
        primitives_used: [plot_grid, geom_tile, geom_point, facet_grid]
        claim_type: "samples × signatures landscape"

  oncoprint:
    catalog:
      - path: 08_breast/github/oncoprint.R
        lines: [1, 198]
        primitives_used: [oncoPrint, HeatmapAnnotation, alter_fun]
        notes: "Uses ComplexHeatmap (NOT ggplot2)"

  cnv_landscape:
    catalog:
      - path: 08_breast/github/cnv.R
        lines: [44, 84]
        notes: "Genome-wide CNV heatmap, GISTIC integration"

  forest_cox:
    catalog:
      - path: 08_breast/github/HRD_for_adjuvant_chemotherapy.R
        lines: [36, 43]
        primitives_used: [coxph, confint, exp, geom_errorbar, coord_flip]
        claim_type: "multivariate hazard ratio"

  composite_layout_topheavy:
    description: "1 large landscape + small grid below"
    catalog:
      - path: 08_breast/figure_3_v1.R
        lines: [1, 654]
        notes: "Full Fig 3 composite (focal amp / ecDNA)"

# (Many more primitives — only sample shown above)

# Orphan catalog scripts (in library but not matched to paper):
orphans:
  - path: 08_breast/code_backup/cnv.R   # backup version, ignore
  - path: 99_bracness/main_HER2.R       # different paper
  ...
```

## Refresh Mode
`/figure-style-extract refresh` re-analyzes even if outputs exist. Useful after:
- New paper added to `reference/papers/`
- New scripts added to `reference/catalog/`
- Existing scripts modified

Outputs diff at end:
```
Refreshed:
- STYLE_GUIDE.md (panel density updated: 6-10 → 7-12 after new paper)
- SCRIPT_CATALOG.yml (12 new primitives indexed, 5 paper_panel cross-refs added)
```

## Subagent Delegation
Heavy work (PDF parsing per figure, 100+ script analysis) should be delegated to a subagent for parallelism:

```
Skill delegation pattern:
  for paper in papers:
    Agent(subagent_type="general-purpose",
          prompt="Analyze {paper} figures, return structured JSON of per-figure metadata")
  for script_batch in chunked(scripts, 20):
    Agent(subagent_type="general-purpose",
          prompt="Index {batch} scripts, return SCRIPT_CATALOG fragments")
  Merge results.
```

Single-agent fallback: process serially with progress logs.

## Escalation Triggers

| Trigger | Action |
|---------|--------|
| Both paper and scripts empty | STOP, ASK user for at least one source |
| Paper PDF unparseable (corrupt / scanned image) | WARN, attempt OCR via Read fallback, log issues |
| Script library has 0 visual primitives detected | WARN, may not be figure scripts (suggest user verify) |
| Script ↔ paper cross-ref: 0 strong matches with >50 scripts | WARN, may be wrong reference set |
| Ambiguous panel arrangement in paper (single-column vs grid) | ASK user to confirm |
| Outputs exist + user manual edit detected (mtime check) | ASK before overwrite |

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Treating supplementary figures as main figures | Detect "Extended Data" or "Supplementary" caption prefix → tag separately |
| Misclassifying composite as single panel | Look for sub-labels (a, b, c) within figure, not just "Fig N" headers |
| Color extraction noisy for low-contrast palettes | Limit to top-N dominant colors per panel |
| Script blocks split across multiple files | Detect via filename pattern (`make_df_*`, `figure_3_v1.R` ↔ `figure_3_data.R`) |
| Library version differences (ggplot2 v2 vs v3) | Note in script metadata, do not auto-resolve |
| Catalog has scripts in mixed languages (R + Py) | Index both, tag `language` field |

## Output Manifest

After successful run:
```
docs_figure/
├── STYLE_GUIDE.md           [generated, ~200-400 lines]
└── SCRIPT_CATALOG.yml       [generated, ~500-2000 lines for ~100 scripts]
```

User reviews STYLE_GUIDE for accuracy (especially color extraction, panel density). SCRIPT_CATALOG is consumed by `/figure-plan` automatically.

## Versioning
Each output emits `_meta` block with:
- `generated_at`
- `source_paper` paths + mtimes
- `source_scripts` dir + total file count
- `figure-style-extract` version

`/figure-init refresh` checks `_meta` to decide whether re-run needed.

## Notes for Implementers
- PDF reading: use `Read` tool with `pages=` param to load 1-2 pages at a time (large PDFs choke if loaded whole)
- Script reading: use `Read` for small scripts, `head -200` via `Bash` for large (>500 lines)
- Pattern matching: use `Grep` for `geom_*` extraction across many scripts (efficient batch)
- Subagent for >20 scripts: avoid single-agent context blowout
- Output yaml: use 2-space indent, no anchors/aliases (keep human-editable)
- Cross-ref strength: `strong` = explicit comment / `medium` = primitive+claim match / `weak` = only theme match / `orphan` = no match
- Catalog YAML order: most-common primitives first (kaplan_meier, scatter, bar typically near top)
- Generic Nature defaults if reference unavailable: panel-density 6-8, font 5-7-8pt hierarchy, single=89mm/full=183mm
