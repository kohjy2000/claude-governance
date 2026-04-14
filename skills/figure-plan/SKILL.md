---
name: figure-plan
description: Phase 1 — Convert narrative/claims to figure design document using 16 principles (P1-P7 structure + P8-P13 visual + P14-P16 content/logic). Supports two granularities: figure-level (cross-panel arc + skeleton) and panel-level (full per-panel detail with catalog lookup). Invoked by /figure-build (figure-level) or /panel-build (panel-level).
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# /figure-plan — Phase 1: Story → Design Doc

$ARGUMENTS:
- `granularity=figure|panel` (default: figure)
- `target=Fig{N}` (required for both)
- `panel={letter}` (required when granularity=panel)
- optional: narrative/story 문서 경로
- optional: `target_doc=docs_figure/targets/Fig{N}_TARGET.md` (default path)

## Role
Scientific figure architect. Narrative + claims를 design document로 변환.

**Granularity dispatch**:
- `granularity=figure`: cross-panel arc + per-panel skeleton (used by /figure-build Phase F1)
- `granularity=panel`: full panel detail with catalog reference (used by /panel-build Phase P1)

Reads from Layer 2 (`docs_figure/`) and Layer 1 (`docs/`):
- `docs_figure/FIGURE_BASELINE.md` — entity tier, palette, dims
- `docs_figure/STYLE_GUIDE.md` — typography, color, layout norms
- `docs_figure/SCRIPT_CATALOG.yml` — visual primitive ↔ script index (panel mode lookup)
- `docs_figure/targets/Fig{N}_TARGET.md` — claims, expected panels, success criteria
- `docs/STORY.md`, `CLAIM_STRUCTURE_v*.md`, `DATA_MAP.md`

## 16 Hard Rules

### Structural Principles (P1-P7)
```
P1  FUNNEL      scope(P_{i+1}) <= scope(P_i) — 범위가 좁아져야 함
P2  EVIDENCE    dependency DAG = panel order — 증거가 결론보다 먼저
P3  DATA-ONLY   every element maps to data — 스키마/다이어그램 금지
P4  EXHAUSTIVE  show N_total before K_selected — 전체를 먼저, 부분은 나중
P5  VARIANTS    >= 2 visualizations per panel — 패널당 2개 이상 시각화
P6  SSOT        all paths in registry — 모든 경로는 레지스트리에
P7  CONSISTENT  one palette, zero local overrides — 색상/라벨 중앙 관리
```

### Visual Storytelling Principles (P8-P13)
```
P8  FOCUS       ONE focal point per panel — 핵심=color/bold, 나머지=grey/alpha
P9  INK         remove non-data elements — gridlines/borders/shadows/patterns 제거
P10 GLANCE      message in <5 seconds without caption — 텍스트 의존 = 디자인 실패
P11 ENCODE      visual channel first (position > color > size > shape > text)
P12 TYPE        Helvetica 5-7pt body, 8pt bold lowercase panel labels, no colored text
P13 BREATHE     generous margins, max ~20 axis items, no label overlap
```

### Content & Logic Principles (P14-P16)
```
P14 CLAIM-MATCH  visual pattern supports the stated claim — 그림이 주장을 시각적으로 증명
P15 LOGIC-FLOW   panel sequence builds an argument — A의 결론 = B의 전제, 독자가 "왜?" 안 물음
P16 RESTRAINT    no overclaiming — NS≠trend, association≠causation, subtitle에 limitation 명시
```

### P8-P13 Design Decision Table
| Principle | Bad (current) | Good (target) |
|-----------|--------------|---------------|
| P8 FOCUS | 모든 데이터 동일 색상/크기 | 핵심 결과 = saturated color, 나머지 = grey70 + alpha 0.3 |
| P9 INK | theme_bw() + panel border + gridlines | theme_minimal() base, panel.grid.major.y only if needed |
| P10 GLANCE | title/subtitle에 메시지, 그래프는 generic | 그래프 자체가 패턴을 보여줌 (e.g., slope direction, cluster separation) |
| P11 ENCODE | 별(★) annotation으로 significance 표시 | filled vs hollow point, color saturation, position above threshold line |
| P12 TYPE | mixed font sizes, bold everywhere | hierarchy: 8pt label > 7pt title > 6pt axis > 5pt annotation |
| P13 BREATHE | 48 arms on one axis, 28 rows in one panel | aggregate or facet; max 15-20 items per axis |

## Process

### Granularity = `figure` (Cross-Panel Arc + Skeleton)

#### Step 1: Read inputs
- `docs_figure/targets/Fig{N}_TARGET.md` → claims, expected panel count
- `docs_figure/FIGURE_BASELINE.md` → entity tier + palette
- `docs/CLAIM_STRUCTURE_v*.md` → claim text + expected numbers
- `docs/STORY.md` (this figure's section) → narrative context

#### Step 2: Define figure role
- LANDSCAPE / CORE / MECHANISM / EXTENSION / VALIDATION / SYNTHESIS

#### Step 3: Cross-figure transitions
- "From Fig{N-1}: {prev conclusion}"
- "To Fig{N+1}: {next premise}"
- These appear in `Fig{N}_design.md` header

#### Step 4: Per-panel SKELETON (NOT full detail)
For each panel (a, b, c, ...), specify:

| Field | Value (skeleton level) |
|-------|------------------------|
| Role | LANDSCAPE / ZOOM / MECHANISM / VALIDATION / SYNTHESIS |
| Claim (P14) | C{x.y} from CLAIM_STRUCTURE |
| Visual primitive (preliminary) | "violin + signif" / "KM + risktable" / "corrplot" |
| Catalog lookup hint | SCRIPT_CATALOG.yml primitive key |
| Data source (SSOT key) | from DATA_MAP |
| Approximate size | (60-80mm typical) |
| Transition from prev panel | one sentence |

Detailed encoding (focal, alpha, exact aesthetic) is deferred to panel-level planning.

#### Step 5: Composite layout sketch
Patchwork-style layout pattern (top-heavy / grid / mixed), referencing STYLE_GUIDE.md examples.

#### Step 6: P1-P16 self-check (figure-level)
- P1 FUNNEL: scope monotone non-increasing across panels
- P2 EVIDENCE: panel dependency DAG matches order
- P15 LOGIC-FLOW: every panel transition writeable
- P14 CLAIM-MATCH: every panel claim from CLAIM_STRUCTURE
- (Other P's deferred to panel-level)

#### Output: `docs_figure/figure_pipeline/design_docs/Fig{N}_design.md`

---

### Granularity = `panel` (Full Detail with Catalog Lookup)

Used by `/panel-build` Phase P1 to flesh out one panel.

#### Step 1: Read inputs
- Parent `Fig{N}_design.md` → panel skeleton (from figure-level plan)
- `docs_figure/SCRIPT_CATALOG.yml` → visual primitive options
- `docs_figure/STYLE_GUIDE.md` → typography, color norms
- `docs_figure/FIGURE_BASELINE.md` → palette refs
- `docs/CLAIM_STRUCTURE_v*.md` → claim text + expected numbers
- `docs/DATA_MAP.md` → SSOT path for data

#### Step 2: CATALOG LOOKUP (panel-level only)
From parent skeleton's `Visual primitive (preliminary)`:

```yaml
# pseudocode
catalog = read("SCRIPT_CATALOG.yml")
matches = catalog.primitives[panel.visual_primitive].catalog
selected = matches.sorted_by(cross_ref_strength).first
panel.catalog_ref = {
  path: selected.path,
  lines: selected.lines,
  primitives_used: selected.primitives_used,
  paper_panel: selected.paper_panel  # for Phase P3 visual diff
}
```

If `matches` empty → log warning, continue with `cross_ref_strength: none`.

#### Step 3: Full panel spec
For the panel:

| Field | Value |
|-------|-------|
| Data source (SSOT key) | exact path + transformation (CLR? raw? subset?) |
| Statistical method | method + adjustment |
| N tested / N sig | scope 수치 |
| Visual encoding | x=position, y=position, color=group, size=effect, alpha=context |
| **Catalog reference** | `path`, `lines`, `primitives_used` (from Step 2) |
| Focal point (P8) | "무엇이 눈에 먼저 들어와야 하는가" |
| Grey-out strategy | "나머지는 어떻게 de-emphasize 하는가" |
| Variant 1 | name: description |
| Variant 2 | name: description |
| Message (P10) | "캡션 없이 이 패널에서 즉시 보이는 것" |
| Claim (P14) | C{x.y} + claim text |
| **Expected number** | from CLAIM_STRUCTURE (e.g., "NB entropy median = 2.33") |
| Visual-claim match (P14) | "시각적 패턴이 claim을 어떻게 증명하는가" |
| Prior panel dependency (P15) | "독자가 이 패널을 이해하려면 어떤 패널을 먼저 봐야 하는가" |
| Transition sentence (P15) | "이전 패널에서 이 패널로의 논리적 연결 한 문장" |
| Limitation (P16) | "이 패널의 해석 한계 (NS, observational, underpowered 등)" |
| Axis item count (P13) | N items — if >20, aggregation strategy 명시 |
| Subtitle template | "scope | method | sample" |
| Panel size | exact mm (W × H) |

#### Step 4: P1-P16 self-check (panel-level, all 16)

```
[ ] P1-P16 (full checklist)
```

#### Output: `docs_figure/figure_pipeline/design_docs/Fig{N}_{p}_design.md`

---

## Catalog Lookup Examples (panel mode)

```yaml
# Panel: Fig2 panel c — MB subgroup entropy violin
# Skeleton from figure-level: visual_primitive = "violin_signif"

# Lookup in SCRIPT_CATALOG.yml:
primitives:
  violin_signif:
    catalog:
      - path: 08_breast/github/APOBEC3A3B_germline_deletion.R
        lines: [10, 16]
        cross_ref_strength: strong
        paper_panel: "Fig 2h"
        ...

# Selected: APOBEC3A3B_germline_deletion.R L10-16
# Panel design records:
catalog_ref:
  path: 08_breast/github/APOBEC3A3B_germline_deletion.R
  lines: [10, 16]
  primitives_used: [geom_violin, geom_signif, scale_fill_nejm]
  paper_panel: "Fig 2h (lower)"
  cross_ref_strength: strong
```

`/figure-implement` (panel granularity) reads this and clones the catalog code at L10-16, adapting variables.

## Principle Verification Checklist

```
[ ] P1  FUNNEL:      scope sequence is monotone non-increasing (per figure)
[ ] P2  EVIDENCE:    dependency DAG matches panel order
[ ] P3  DATA-ONLY:   no panel calls for schematics, DAGs, or diagrams
[ ] P4  EXHAUSTIVE:  every subset panel has a preceding universe panel
[ ] P5  VARIANTS:    every panel has >= 2 variants specified
[ ] P6  SSOT:        every data source references an SSOT key
[ ] P7  CONSISTENT:  entity names/colors reference a single palette spec
[ ] P8  FOCUS:       every panel spec names exactly one focal element + grey-out strategy
[ ] P9  INK:         no panel requires gridlines, borders, or decorative elements
[ ] P10 GLANCE:      every panel message is testable without reading the caption
[ ] P11 ENCODE:      no panel relies solely on text/stars for its key finding
[ ] P12 TYPE:        font hierarchy specified (8pt > 7pt > 6pt > 5pt)
[ ] P13 BREATHE:     no axis exceeds 20 items without aggregation plan
[ ] P14 CLAIM-MATCH: every panel names its claim AND how the visual supports it
[ ] P15 LOGIC-FLOW:  every panel (except A) has a transition sentence from prior panel
[ ] P16 RESTRAINT:   every NS result is labeled as such, no causal verbs, limitations noted
```

Granularity-level checks:
- `figure`: P1, P2, P14, P15 are critical (cross-panel arc)
- `panel`: ALL 16 must PASS for that panel

## Output

### Granularity = `figure`
`docs_figure/figure_pipeline/design_docs/Fig{N}_design.md`:
- Header: figure role, claims supported, transitions
- Per-panel skeleton table (a, b, c, ...) with catalog hint
- Composite layout sketch
- P1-P16 self-check (figure-level subset)

### Granularity = `panel`
`docs_figure/figure_pipeline/design_docs/Fig{N}_{p}_design.md`:
- Full panel spec (all 16 fields above)
- Catalog reference (path + lines + paper_panel)
- ≥2 variants
- Expected numbers (assertion seeds)
- P1-P16 full checklist

This document is Phase 2 (`/figure-implement`)의 input.

## Common Pitfalls

| Pitfall | Violated | Fix |
|---------|----------|-----|
| Star result를 Panel A에 | P1, P2 | 뒤로 보내고 context panel 추가 |
| Hand-drawn summary | P3 | 정량적 visualization으로 대체 |
| Cherry-picked features | P4 | universe panel 추가 + FDR threshold 명시 |
| Viz 1개만 | P5 | alternative 추가 |
| Hardcoded path | P6 | SSOT key 사용 |
| Figure마다 다른 색상 | P7 | 중앙 palette에서 관리 |
| 모든 point 같은 색 | P8 | focal point에만 color, 나머지 grey |
| gridlines + borders | P9 | theme_minimal(), remove panel.border |
| 메시지가 title에만 | P10 | 시각적 패턴으로 메시지 전달하도록 redesign |
| 별(★)로 significance | P11 | filled/hollow encoding 또는 color saturation |
| 10pt text 혼재 | P12 | strict hierarchy 적용 |
| 48 items on y-axis | P13 | top-K + "N others" 또는 facet 분할 |
| 그림은 예쁜데 claim이 안 보임 | P14 | claim을 명시하고 visual pattern과 매칭 재설계 |
| 패널 순서가 비논리적 | P15 | transition sentence 작성 → 순서 재배치 |
| NS를 "suggestive trend"로 표현 | P16 | "NS (p=0.xx)" 명시, trend 삭제 |
| "demonstrates" 등 causal verb | P16 | "associated with", "correlated with"로 교체 |
| **Catalog lookup 무시 (panel)** | (process) | 항상 SCRIPT_CATALOG.yml 먼저 lookup |
| **Catalog 없는데 from-scratch** | (process) | log warning, but acceptable; Phase 2 implements generic |

## Technique Matching Reference (extended)

### Data pattern → primitive
| Data pattern | Recommended technique | Catalog primitive key | Avoid |
|-------------|----------------------|----------------------|-------|
| Dramatic drop (5490→52) | Slopegraph, waterfall | `slopegraph`, `waterfall` | Bar chart |
| Diffuseness/inequality | Lorenz curve, Gini | `lorenz` | Manhattan |
| Effect + uncertainty | Forest plot with CI | `forest_cox` | Bar chart without error |
| Distribution N<100 | Half-violin + beeswarm | `violin_signif`, `beeswarm` | Boxplot alone |
| Comparison 2 conditions | Paired dot/dumbbell | `dumbbell` | Grouped bar |
| Null result (all NS) | Compact summary (volcano, p-histogram) | `volcano`, `p_hist` | 48-row heatmap |
| Binary outcome matrix | Tile with 2 colors | `binary_tile` | Complex gradient |
| Stage gradient | Connected dot plot | `slopegraph` | Separate bar charts |
| Cross-cohort concordance | Mirror/back-to-back plot | `mirror_bar` | Separate panels |
| Stratified survival | KM curves + risk table | `kaplan_meier` | Bar of % survived |
| Co-activation structure | Correlation heatmap | `correlation_heatmap` | Pairwise scatter grid |
| Composition (proportion) | Donut, stacked bar | `donut`, `stacked_bar` | Pie without labels |
| Categorical enrichment | Stacked bar by category/type | `stacked_bar` | Multi-bar with text |
| Genome landscape | Manhattan-style or genome track | `genome_landscape` | Per-chr bar grid |
| Patient-level mutation | OncoPrint | `oncoprint` | Single gene heatmap |

When primitive is selected, **always lookup SCRIPT_CATALOG.yml** for matching script reference.
