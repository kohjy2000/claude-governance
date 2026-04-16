---
name: figure-plan
description: Phase 1 — Convert narrative/claims to figure design document using 16 principles (P1-P7 structure + P8-P13 visual + P14-P16 content/logic). Supports two granularities (figure-level cross-panel arc vs panel-level full detail) and two modes (manuscript strict vs exploratory lenient). Invoked by /figure-build (figure-level) or /panel-build (panel-level).
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# /figure-plan — Phase 1: Story + Claims → Design Doc

`$ARGUMENTS`:
- `granularity=figure|panel` (default: figure)
- `mode=manuscript|exploratory` (default: manuscript)
- `target=Fig{N}` (required for both)
- `panel={letter}` (required when granularity=panel)
- optional `target_doc=docs_figure/targets/Fig{N}_TARGET.md` (default path)

**Schema**: `~/.claude/blueprints/schemas/FIGURE_PLAN.schema.md` (output format spec).

## Role
Scientific figure architect. Claims + narrative를 design document로 변환.

**Granularity dispatch**:
- `granularity=figure`: cross-panel arc + per-panel skeleton (used by /figure-build Phase F1)
- `granularity=panel`: full panel detail with catalog reference (used by /panel-build Phase P1)

**Mode dispatch**:
- `mode=manuscript`: strict. CLAIMS.md + TARGET.md + catalog 모두 필수. Drift 감지 시 FAIL.
- `mode=exploratory`: lenient. CLAIMS.md 비어있거나 TARGET 부재 시 STORY.md에서 임시 extract. 출력에 draft 배너.

Reads from Layer 2 (`docs_figure/`) and Layer 1 (`docs/`):
- `docs_figure/FIGURE_BASELINE.md` — entity tier, palette, dims
- `docs_figure/STYLE_GUIDE.md` — typography, color, layout norms
- `docs_figure/SCRIPT_CATALOG.yml` — visual primitive ↔ script index (panel mode lookup)
- `docs_figure/targets/Fig{N}_TARGET.md` — claims, expected panels, success criteria (manuscript 필수)
- `docs/STORY.md`, `docs/CLAIMS.md` (Group 필드 기반 filter), `docs/DATA_MAP.md`

---

## Step 0: Input Validation + Machine Marker

### 0-1. Mode decision
- `$ARGUMENTS`에 `mode=exploratory` → exploratory.
- 그 외 → manuscript.

### 0-2. Input load (manuscript mode)
- `docs/CLAIMS.md` 없거나 해당 figure의 Group claim 0개 → STOP. "CLAIMS.md에 Group={Cx} claim 필요."
- `docs_figure/targets/Fig{N}_TARGET.md` 없음 → STOP. "/figure-init 먼저 돌려라."
- `docs_figure/BASELINE, STYLE_GUIDE, SCRIPT_CATALOG` 없음 → STOP.
- `deprecated` tag claim이 TARGET에 참조됨 → FAIL.

### 0-3. Input load (exploratory mode)
- CLAIMS.md 없음 → STORY에서 candidate claim extract (3-10개). 각 candidate에 `[DRAFT]` 마크.
- TARGET.md 없음 → figure role + panel 수만 추정, skeleton 생성.
- Catalog 없음 → WARN, from-scratch 허용.

### 0-4. Machine marker (output top)

```html
<!-- figure-plan-step0
mode: <manuscript|exploratory>
granularity: <figure|panel>
target: Fig{N}
panel: <letter or null>
claims_total: N
claims_main: a
claims_supp: b
claims_discussion: c
claims_deprecated: d
claims_source: <CLAIMS.md | narrative-draft>
catalog_available: <true|false>
-->
```

Figure-review가 이 마커를 grep해서 mode 상속.

### 0-5. Exploratory draft banner
Exploratory mode 시 output 최상단:
```
> ⚠️ DRAFT — generated in exploratory mode. Claims/TARGET derived from narrative,
> not CLAIMS.md+TARGET.md. NOT a design of record. Promote to manuscript mode
> after CLAIMS + TARGET are populated.
```

---

## 16 Hard Rules

### Structural Principles (P1-P7)
```
P1  FUNNEL      scope(P_{i+1}) <= scope(P_i) — 범위가 좁아져야 함
P2  EVIDENCE    dependency DAG = panel order — 증거가 결론보다 먼저
P3  DATA-ONLY   every element maps to data — 스키마/다이어그램 금지
P4  EXHAUSTIVE  show N_total before K_selected — 전체를 먼저, 부분은 나중
P5  VARIANTS    >= 2 visualizations per panel — 패널당 2개 이상 시각화
P6  SSOT        all paths in registry — 모든 경로는 DATA_MAP.md SSOT 키 참조
P7  CONSISTENT  one palette, zero local overrides — 색상/라벨 중앙 관리 (BASELINE)
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
P14 CLAIM-MATCH  panel references CLAIMS.md C{group}-{N} ID (manuscript: FAIL if missing, exploratory: WARN)
P15 LOGIC-FLOW   panel sequence builds an argument — A의 결론 = B의 전제
P16 RESTRAINT    no overclaiming — use claim's `Limitation` field verbatim in subtitle
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

---

## Process

### Granularity = `figure` (Cross-Panel Arc + Skeleton)

#### Step 1: Read inputs
- `docs_figure/targets/Fig{N}_TARGET.md` → claims, expected panel count, cross-figure transitions
- `docs_figure/FIGURE_BASELINE.md` → entity tier + palette
- `docs/CLAIMS.md` (Group filter by figure) → claim statements, numerical anchors, Tags
- `docs/STORY.md` (this figure's section) → narrative context

#### Step 2: Define figure role
- LANDSCAPE / CORE / MECHANISM / EXTENSION / VALIDATION / SYNTHESIS

#### Step 3: Cross-figure transitions
- "From Fig{N-1}: {prev conclusion}"
- "To Fig{N+1}: {next premise}"
- 이 내용은 `Fig{N}_design.md` header에 기록

#### Step 4: Per-panel SKELETON (NOT full detail)
For each panel (a, b, c, ...), specify:

| Field | Value (skeleton level) |
|-------|------------------------|
| Role | LANDSCAPE / ZOOM / MECHANISM / VALIDATION / SYNTHESIS |
| Claim (P14) | C{group}-{N} from CLAIMS.md |
| Tag (from CLAIMS) | main / supp / discussion / deprecated |
| Visual primitive (preliminary) | "violin + signif" / "KM + risktable" / "corrplot" |
| Catalog lookup hint | SCRIPT_CATALOG.yml primitive key |
| Data source (SSOT key) | from DATA_MAP |
| Approximate size | (60-80mm typical) |
| Transition from prev panel | one sentence |

`discussion` or `deprecated` tag claims → panel 배치 금지 (exploratory: WARN, manuscript: FAIL).

Detailed encoding은 panel-level planning에서.

#### Step 5: Composite layout sketch
Patchwork-style layout pattern (top-heavy / grid / mixed), STYLE_GUIDE.md 예시 참조.

#### Step 6: P1-P16 self-check (figure-level)
- P1 FUNNEL: scope monotone non-increasing across panels
- P2 EVIDENCE: panel dependency DAG matches order
- P15 LOGIC-FLOW: every panel transition writeable
- P14 CLAIM-MATCH: every panel claim resolves to CLAIMS.md (manuscript FAIL / exploratory WARN if `C?-draft`)
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
- `docs/CLAIMS.md` → claim full entry (Statement, Numerical anchor, Limitation verbatim)
- `docs/DATA_MAP.md` → SSOT path for data

#### Step 2: CATALOG LOOKUP
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

If `matches` empty:
- manuscript: WARN + log + continue with `cross_ref_strength: none`
- exploratory: WARN only

#### Step 3: Full panel spec
For the panel:

| Field | Value |
|-------|-------|
| Claim ID | CLAIMS.md `C{group}-{N}` (verbatim) |
| Statement (verbatim) | from CLAIMS.md |
| Numerical anchor | from CLAIMS.md |
| Source script | from CLAIMS.md |
| Data source (SSOT key) | exact path + transformation (CLR? raw? subset?) |
| Statistical method | method + adjustment |
| N tested / N sig | scope 수치 |
| Visual encoding | x/y/color/size/shape/alpha |
| **Catalog reference** | `path`, `lines`, `primitives_used`, `paper_panel` (from Step 2) |
| Focal point (P8) | "무엇이 눈에 먼저 들어와야 하는가" |
| Grey-out strategy | "나머지는 어떻게 de-emphasize 하는가" |
| Variant 1 | name: description |
| Variant 2 | name: description |
| Message (P10) | "캡션 없이 이 패널에서 즉시 보이는 것" |
| Visual-claim match (P14) | "시각적 패턴이 claim을 어떻게 증명하는가" |
| Prior panel dependency (P15) | Panel ID |
| Transition sentence (P15) | one sentence from prior panel |
| Limitation (P16) | CLAIMS.md `Limitation` field verbatim |
| Axis item count (P13) | N items — if >20, aggregation strategy 명시 |
| Subtitle template | "scope | method | sample" + Limitation |
| Panel size | exact mm (W × H) |
| Role | focal / supporting / mention |

#### Step 4: P1-P16 self-check (panel-level, all 16)
모든 16개 rule 체크. Manuscript mode FAIL 시 STOP. Exploratory는 P14만 WARN으로 완화.

#### Output: `docs_figure/figure_pipeline/design_docs/Fig{N}_{p}_design.md`

---

## Catalog Lookup Example (panel mode)

```yaml
# Panel: Fig2c — MB subgroup entropy violin
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
[ ] P14 CLAIM-MATCH: every panel cites CLAIMS.md C{group}-{N} ID (exploratory: C?-draft 허용)
[ ] P15 LOGIC-FLOW:  every panel (except A) has a transition sentence from prior panel
[ ] P16 RESTRAINT:   Limitation from CLAIMS.md copied verbatim, no causal verbs
```

Granularity-level 우선순위:
- `figure`: P1, P2, P14, P15 critical (cross-panel arc)
- `panel`: ALL 16 must PASS

## Output

### Granularity = `figure`
`docs_figure/figure_pipeline/design_docs/Fig{N}_design.md`:
- `<!-- figure-plan-step0 ... -->` machine marker
- Header: figure role, claims supported, transitions
- Per-panel skeleton table (a, b, c, ...) with catalog hint
- Composite layout sketch
- P1-P16 self-check (figure-level subset)

### Granularity = `panel`
`docs_figure/figure_pipeline/design_docs/Fig{N}_{p}_design.md`:
- Full panel spec (all fields above)
- Catalog reference (path + lines + paper_panel)
- ≥2 variants
- Expected numbers (assertion seeds)
- P1-P16 full checklist

Downstream consumer:
- Phase 2 `/figure-implement` reads this doc.
- Phase 3 `/figure-review` (via figure-reviewer subagent) audits.

## Decision Surface

**Silent**: visual encoding choice, palette assignment within BASELINE, panel layout.
**Ask user**: Tag와 TARGET figures 충돌, deprecated claim 참조, exploratory→manuscript 전환 시점.
**Ask user (manuscript only)**: stale anchor 의심 (90+ days), catalog match 0인 panel.

## Common Pitfalls

| Pitfall | Violated | Fix |
|---------|----------|-----|
| Star result를 Panel A에 | P1, P2 | 뒤로 보내고 context panel 추가 |
| Hand-drawn summary | P3 | 정량적 visualization으로 대체 |
| Cherry-picked features | P4 | universe panel 추가 + FDR threshold 명시 |
| Viz 1개만 | P5 | alternative 추가 |
| Hardcoded path | P6 | SSOT key 사용 |
| Figure마다 다른 색상 | P7 | BASELINE palette 참조 |
| 모든 point 같은 색 | P8 | focal point에만 color |
| gridlines + borders | P9 | theme_nature() |
| 메시지가 title에만 | P10 | 시각적 패턴으로 전달 |
| 별(★)로 significance | P11 | filled/hollow 또는 color saturation |
| 10pt text 혼재 | P12 | strict hierarchy |
| 48 items on y-axis | P13 | top-K + "N others" 또는 facet |
| CLAIMS에 없는 claim invent | P14 | CLAIMS 먼저 추가하거나 panel 제거 |
| 패널 순서가 비논리적 | P15 | transition sentence 작성 → 순서 재배치 |
| NS를 "suggestive trend"로 표현 | P16 | CLAIMS Limitation verbatim 사용 |
| "demonstrates" 등 causal verb | P16 | "associated with", "correlated with"로 교체 |
| Catalog lookup 건너뛰기 (panel) | process | 항상 SCRIPT_CATALOG.yml 먼저 lookup |
| `discussion` tag를 main panel focal로 | Step 4 | Tag를 main으로 promote하거나 panel 제거 |
| Exploratory draft를 manuscript로 사용 | Step 0-5 | `mode=manuscript` 재실행, gate 통과 확인 |

## Technique Matching Reference

### Data pattern → primitive (catalog lookup hint)

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

Primitive 선택 후 **SCRIPT_CATALOG.yml lookup** (panel mode에서 필수).

## Handoff
- Figure-level output → `/figure-build` Phase F1이 consume하여 Phase F2로 각 panel에 panel-build dispatch.
- Panel-level output → `/figure-implement granularity=panel`이 consume하여 catalog clone-modify로 code 생성.
- Schema: `~/.claude/blueprints/schemas/FIGURE_PLAN.schema.md`가 canonical. 이 SKILL의 필드 목록과 schema 충돌 시 schema 우선.
