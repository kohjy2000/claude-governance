---
name: figure-init
description: Layer 2 setup that bridges project docs to figure pipeline. Reads docs_server/ + reference paper + catalog scripts → generates docs_figure/ (BASELINE, OVERVIEW, per-figure TARGETs, STYLE_GUIDE, SCRIPT_CATALOG). Run once per project; use `refresh` mode after narrative or reference changes.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill
---

# /figure-init — Layer 2: Project Docs → Figure Docs

$ARGUMENTS: project_root path (default cwd) | optional `refresh` | optional `figure_count=N`

## Role
**One-time-per-project** orchestrator that builds the figure-pipeline source-of-truth.
Reads Layer 1 (project docs from `/project-init`) and produces Layer 2 (`docs_figure/`).
Layer 3 (`/figure-build target=Fig{N}`) consumes Layer 2 outputs.

## Inputs (must exist)

```
project_root/
├── docs_server/                      ← from /project-init
│   ├── README.md                     ← cohort, status, key parameters
│   ├── STORY.md                      ← thesis, narrative
│   ├── CLAIM_STRUCTURE_v*.md         ← claim hierarchy + numbers
│   ├── DATA_MAP.md                   ← SSOT paths
│   ├── PIPELINE.md                   ← execution log
│   ├── ANALYSIS_SCHEMA_v*.md         ← analysis design
│   └── ...
├── reference/
│   ├── papers/*.pdf                  ← reference publication(s)
│   └── catalog/                      ← reference R/Py scripts
└── ...
```

If `docs_server/` missing → STOP, instruct user: "Run /project-init first."
If `reference/papers/` empty → WARN, fall back to generic Nature defaults.
If `reference/catalog/` empty → WARN, SCRIPT_CATALOG.yml will be empty.

## Outputs (idempotent — `refresh` replaces in-place)

```
project_root/docs_figure/
├── FIGURE_BASELINE.md                ← entity tier, palette, dimensions, rules
├── FIGURE_PLAN_OVERVIEW.md           ← N main figures + cross-figure arc
├── targets/
│   ├── Fig1_TARGET.md                ← per-figure: claims, panels, success
│   ├── Fig2_TARGET.md
│   └── ...
├── STYLE_GUIDE.md                    ← from /figure-style-extract sub-skill
├── SCRIPT_CATALOG.yml                ← from /figure-style-extract sub-skill
└── validation_report.md              ← only if validation issues detected
```

Layer 3 (`/figure-build`) reads BOTH `docs_server/` (for narrative + data) AND `docs_figure/` (for tier + style + targets).

## Process

### Step 1 — Validate inputs
- Glob `docs_server/*.md` — required, fail if empty
- Glob `reference/papers/*.pdf` — flag if empty
- Glob `reference/catalog/**/*.R` (or `*.py`) — flag if empty
- If `docs_figure/` exists and arg ≠ `refresh` → `AskUserQuestion`:
  - "docs_figure already exists. Refresh in-place? (yes/no/abort)"
  - `no` → STOP; `abort` → STOP; `yes` → proceed in refresh mode

### Step 2 — Extract Entity Tier
Parse `docs_server/README.md` "Cohort Structure" section + `STORY.md` cohort sections.
Classify each entity (e.g., diagnosis, cohort) by narrative role:

| Tier | Definition | Identification heuristic |
|------|-----------|-------------------------|
| **PRIMARY** | Always shown; main contrast in thesis | Mentioned in `Thesis`, `Discovery cohort`, key results |
| **SECONDARY** | Shown when narrative invokes specific subgroup | Mentioned in subgroup analyses, supporting roles |
| **CONTEXTUAL** | Shown in specific panels only | Mentioned in cross-cohort comparison, simplex sharing, validation |
| **EXCLUDED** | Default omitted; lumped as "Others" | Small N, not in narrative |

If >2 entities qualify for PRIMARY → `AskUserQuestion` to disambiguate.

### Step 3 — Consolidate Palette + Dimensions
- DATA_MAP.md → existing color/path conventions
- README.md "Key Parameters" → numerical constants (cohort sizes, factor counts, etc.)
- Existing `00_common.R` (if present in project) → reuse palette literals
- Reference paper → typography + panel-size standards (extracted by sub-skill)

Output structures:
- `DX_PALETTE_PRIMARY` (from entity tier)
- `DX_PALETTE_SECONDARY`
- `FACTOR_FAMILY_COLORS` (or domain-equivalent)
- `JOURNAL_DIMS` (default Nature: single=89mm, full=183mm, max_h=247mm)

### Step 4 — Map Claims to Figures
Parse `CLAIM_STRUCTURE_v*.md` hierarchical structure. Default mapping:

| Claim group | Figure |
|-------------|--------|
| C0 (method validity) | Fig 1 |
| C1 (core observation / discovery) | Fig 2 |
| C2 (mechanism / association) | Fig 3 |
| C3 (extension / drug / clinical) | Fig 4 |
| C4 (validation / synthesis) | Fig 5 |

If project structure differs → `AskUserQuestion` with detected groups + suggested mapping.
`figure_count=N` arg overrides default 5 (e.g., `figure_count=4`).

### Step 5 — Generate per-figure TARGET docs
For each figure, write `targets/Fig{N}_TARGET.md`:
- Which claims (e.g., C1-1, C1-2, ...) this figure proves
- Expected panel count (default 6-10 per Nature-style)
- Required data SSOT keys
- Cross-figure transition (from Fig{N-1}, to Fig{N+1})
- Success criteria (Layer 0/1/2/3 PASS conditions)

### Step 6 — Sub-call /figure-style-extract
```
Skill: figure-style-extract
  args: paper=reference/papers/*.pdf
        scripts=reference/catalog/
```
Output: `STYLE_GUIDE.md` + `SCRIPT_CATALOG.yml`.

If sub-skill not yet implemented or reference unavailable → write stub:
- `STYLE_GUIDE.md`: Nature defaults (panel-density 6-10, font hierarchy 5-7-8pt, single/full-width specs)
- `SCRIPT_CATALOG.yml`: `[]` empty list + comment explaining how to populate later

### Step 7 — Generate FIGURE_BASELINE.md
Consolidate Steps 2-3 outputs. See template below.

### Step 8 — Generate FIGURE_PLAN_OVERVIEW.md
Build N-figure summary table with cross-figure narrative arc. See template.

### Step 9 — Validation pass
Cross-check:
- Every TARGET claim must exist in CLAIM_STRUCTURE
- Every TARGET SSOT key must exist in DATA_MAP
- Cross-figure transitions form complete chain (Fig1 → Fig2 → ... → FigN)
- Entity tier consistent across TARGETs
- Palette references (e.g., `DX_PALETTE_PRIMARY[NB]`) defined in BASELINE

If ≥1 validation issue → write `validation_report.md` and report to user.

## Output File Templates

### FIGURE_BASELINE.md
```markdown
# Figure Pipeline Baseline
Project: {project_name}
Generated: {date} by /figure-init {version}
Source: docs_server/{README,STORY,CLAIM_STRUCTURE,DATA_MAP}.md

## Entity Tier

### PRIMARY (always shown)
- {entity_1}: {description}, n={count}
- {entity_2}: {description}, n={count}

### SECONDARY (narrative-conditional)
- {entity_3}: {description}, n={count}

### CONTEXTUAL (panel-specific)
- {entity_4}: appears in {Fig{N} panel x} only

### EXCLUDED
- All others → "Others" or omitted

## Palette
DX_PALETTE_PRIMARY:
  {entity_1}: "{hex}"
  {entity_2}: "{hex}"
DX_PALETTE_SECONDARY:
  {entity_3}: "{hex}"
FACTOR_FAMILY_COLORS:  # or domain-equivalent
  {family_1}: "{hex}"
  ...
CONTEXT_GREY: "grey70"
CONTEXT_ALPHA: 0.30
FOCAL_ALPHA: 0.95

## Dimensions (Nature spec, override per project)
single_column: 89mm
full_width: 183mm
max_height: 247mm
panel_size_main: 60-80mm
panels_per_figure: 6-10

## Cross-Figure Rules
- All figures use DX_PALETTE_PRIMARY (no overrides)
- Typography: 8pt panel tag > 7pt title > 6pt axis > 5pt annotation
- Theme: theme_nature() (defined in 00_common.R)
- No color literals in figure scripts (must reference 00_common.R)
- Reference catalog scripts before writing new visualization (see SCRIPT_CATALOG.yml)

## Iteration Caps (used by /figure-build)
loop_visual: 3
loop_content: 2
loop_figure: 2
total_max: 5
```

### FIGURE_PLAN_OVERVIEW.md
```markdown
# Figure Plan Overview
Project: {project_name}
Generated: {date} by /figure-init
Total main figures: {N}

## Story Arc
Thesis: {1-line thesis from STORY.md}

| Fig | Role | Claims | Sub-panels | Conclusion → Next premise |
|-----|------|--------|------------|---------------------------|
| 1 | LANDSCAPE / METHOD | C0-1, C0-2, C0-3 | 6-8 panels | "Method validated → apply to cohort (Fig 2)" |
| 2 | CORE OBSERVATION | C1-1..C1-5 | 8-10 panels | "Pattern observed → mechanism? (Fig 3)" |
| 3 | MECHANISM | C2-1..C2-7 | 8-10 panels | "Mechanism explained → drug implication (Fig 4)" |
| 4 | EXTENSION | C3-1..C3-9 | 6-8 panels | "Drug evidence → external validation (Fig 5)" |
| 5 | VALIDATION | C5-1..C5-5 | 6-8 panels | (terminus) |

## Cross-Figure Transitions (for /figure-review Layer 0)
Fig1 → Fig2: "{transition sentence}"
Fig2 → Fig3: "{transition sentence}"
...
Fig{N-1} → Fig{N}: "{transition sentence}"
```

### Fig{N}_TARGET.md
```markdown
# Fig{N} Target Spec
Generated: {date} by /figure-init
Role: {LANDSCAPE | CORE | MECHANISM | EXTENSION | VALIDATION}

## Claims supported (from CLAIM_STRUCTURE_v*)
- C{x.y}: {claim text}
  - Expected number: {e.g., NB entropy = 2.33}
  - Source: {SSOT key}, {transformation if any}
- C{x.z}: ...

## Panel Plan (target 6-10 sub-panels)
| Panel | Visual primitive | Data | Catalog ref | Claim | Focal |
|-------|------------------|------|-------------|-------|-------|
| a | {e.g., stacked bar} | {SSOT key} | {script L{X}-{Y}} | C{x.y} | {what pops} |
| b | ... | ... | ... | ... | ... |

(panels filled in by /figure-plan in Phase F1; this is skeleton)

## Cross-figure transitions
- From Fig{N-1}: {prev figure conclusion}
- To Fig{N+1}: {next figure premise}

## Success criteria
- Layer 0 PASS: story arc Fig{N-1} → Fig{N} → Fig{N+1} transitions valid
- Layer 1 PASS: each panel role distinct, no redundancy with other panels
- Layer 2 PASS: every panel claim verifiable from rendered visual + data
- Layer 3 PASS: P8-P13 visual checks all PASS

## Required data (SSOT keys)
- {key_1}: {brief description}
- {key_2}: ...
```

## Refresh Mode

`/figure-init refresh` re-runs Steps 1-9, replacing in-place. Outputs diff summary:

```
Refreshed:
- FIGURE_BASELINE.md (entity tier: NB,OS,MB unchanged; HGG promoted PRIMARY → SECONDARY)
- targets/Fig2_TARGET.md (added panel 'f' for new claim C1-6)
- SCRIPT_CATALOG.yml (3 new catalog scripts indexed)

Unchanged:
- FIGURE_PLAN_OVERVIEW.md
- targets/Fig1_TARGET.md, Fig3_TARGET.md, Fig4_TARGET.md, Fig5_TARGET.md
- STYLE_GUIDE.md
```

If user manually edited a file after last `/figure-init` run (mtime > generated_at) → ASK before overwrite.

## Escalation Triggers (STOP & ask user)

| Trigger | Action |
|---------|--------|
| `docs_server/` missing | STOP, instruct user to run `/project-init` first |
| Multiple `CLAIM_STRUCTURE_v*.md` versions | ASK which is canonical (default: latest version number) |
| Entity tier ambiguous (>2 candidates for PRIMARY) | ASK with options |
| Reference paper missing | WARN, fall back to Nature defaults, flag in BASELINE |
| Catalog scripts missing | WARN, SCRIPT_CATALOG empty, flag in BASELINE |
| Validation: claim referenced in TARGET but not in CLAIM_STRUCTURE | ASK (typo? new claim? deprecate?) |
| User manually edited generated file (refresh mode) | ASK before overwrite |
| `figure_count` arg conflicts with detected claim groups | ASK to confirm or override |

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Running on incomplete project docs (missing CLAIM_STRUCTURE) | Step 1 validates; STOP if missing |
| Re-run silently overwrites user manual edits | Refresh mode checks mtime; ASKs first |
| Entity tier extracted from outdated STORY | User updates STORY first, then `refresh` |
| TARGET claims drift from CLAIM_STRUCTURE silently | Step 9 validation catches |
| Reference paper from unrelated field | User curates `reference/papers/`; no semantic check |
| Default 5-figure mapping doesn't match project | `figure_count=N` arg + interactive disambiguation |
| Long claim names break TARGET tables | Truncate display name, full name in CSV/yaml metadata |

## Output Manifest

After successful run, user sees:
```
docs_figure/
├── FIGURE_BASELINE.md           [generated, review for entity tier accuracy]
├── FIGURE_PLAN_OVERVIEW.md      [generated, review for story arc]
├── targets/
│   ├── Fig1_TARGET.md           [generated, skeleton — fleshed out by /figure-plan]
│   ├── Fig2_TARGET.md           [generated, skeleton]
│   ├── Fig3_TARGET.md           [generated, skeleton]
│   ├── Fig4_TARGET.md           [generated, skeleton]
│   └── Fig5_TARGET.md           [generated, skeleton]
├── STYLE_GUIDE.md               [from sub-skill, may be stub]
├── SCRIPT_CATALOG.yml           [from sub-skill, may be empty]
└── validation_report.md         [present only if issues detected]
```

User reviews `FIGURE_BASELINE.md` + `FIGURE_PLAN_OVERVIEW.md` (story arc + entity tier) before proceeding to:

```
$ /figure-build target=Fig2
```

## Versioning
This skill emits `_meta` block at top of each generated file:
```
<!-- _meta: figure-init v0.1.0 | generated 2026-04-14T15:30:00 | source mtime 2026-04-13T22:07:00 -->
```
Used by refresh mode for diff detection.

## Notes for Implementers
- Sub-skill `figure-style-extract` may not exist yet; output stub if Skill tool returns "not found"
- Idempotency: re-running with same inputs → identical outputs (deterministic)
- Use `Glob` for input discovery (not Bash `find`)
- Use `Read` for parsing markdown sections (heading-based extraction)
- Use `AskUserQuestion` for ambiguity resolution (do not hallucinate decisions)
- Generated files use markdown tables (not yaml) for human readability EXCEPT `SCRIPT_CATALOG.yml`
