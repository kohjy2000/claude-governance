---
name: figure-plan
description: Phase 1 — Convert CLAIMS + narrative to figure design document using 16 principles (P1-P7 structure + P8-P13 visual + P14-P16 content/logic). Two modes — exploratory (default) and manuscript (strict).
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# /figure-plan — Phase 1: Claims → Design Doc

`$ARGUMENTS`:
- `--exploratory` (default) — CLAIMS.md가 없거나 부분적이어도 진행. 출력은 draft로 표시.
- `--manuscript` — Strict mode. CLAIMS.md가 well-formed이고 `main` tag claim이 존재해야 진행.
- 추가로 figure scope (예: `Fig1-Fig5`, `Fig3 only`). 생략 시 전체 active claim.

예: `/figure-plan --manuscript Fig1-Fig5`

## Role
Scientific figure architect. CLAIMS.md의 구조화된 사실을 panel로 매핑.
Narrative 해석은 STORY.md `Hypothesis Evolution` current framing에서만 참조.

---

## Step 0: Load Layer 1 SSOT

Mode 결정:
1. `$ARGUMENTS`에 `--manuscript` 있으면 manuscript mode.
2. 그 외는 exploratory mode.

다음 파일을 순서대로 읽고 LLM-read로 해석한다 (파서 없음 — CLAIMS.schema.md 참조):

### 0-1. `docs/CLAIMS.md`
- **Exploratory mode**:
  - 파일 없음 → 진행. Narrative에서 candidate claim을 임시 추출 (아래 0-5 참조).
  - 파일 존재하나 well-formed 아님 → 진행하되 user에게 어떤 엔트리가 비었는지 보고.
  - Tag가 `deprecated`인 엔트리는 스킵.
- **Manuscript mode**:
  - 파일 없음 → STOP. User에게 CLAIMS.md 먼저 작성하거나 `--exploratory`로 재호출하라고 지시.
  - Well-formed 아님 → 어떤 엔트리/필드가 문제인지 보고 후 STOP.
  - `main` tag claim 0개 → STOP. "Manuscript mode는 최소 1개의 `main` claim을 요구함."
  - Tag `deprecated`인 엔트리가 FIGURE_PLAN.md에 아직 참조되고 있으면 FAIL.

### 0-2. `docs/STORY.md`
- `Hypothesis Evolution` current framing → 논문 레벨 arc 이해용.
- `Pivots` → 폐기된 방향 확인.
- 사실 추출 용도로 사용 금지. 숫자는 CLAIMS에만 있다.

### 0-3. `docs/DATA_MAP.md`
- 모든 CLAIMS 엔트리의 `Data source: SSOT$<key>` (semicolon 구분)가 여기서 resolve되어야 함.
- 미해결 키 → manuscript mode면 FAIL, exploratory mode면 WARN.

### 0-4. `outputs/figures/FIGURE_PLAN.md` (있으면)
- 있으면 이는 revision. 기존 panel ID와 claim ID 매핑을 보존.
- 없으면 초기 설계.

### 0-5. (Exploratory fallback only) Narrative claim extraction
CLAIMS.md 비어있을 때만. STORY.md + README.md를 읽어 candidate claim 3~10개를 임시 추출.
각 candidate에 명시: `[DRAFT — not in CLAIMS.md yet]`.
Output FIGURE_PLAN.md 상단에 경고 배너:

```
> ⚠️ DRAFT — generated in exploratory mode. Claims were extracted from narrative,
> not CLAIMS.md. This is NOT a design of record. Before using for manuscript,
> promote claims into CLAIMS.md and re-run with --manuscript.
```

### Step 0 output

사용자에게 보여주는 3줄 summary:
```
Mode: <exploratory | manuscript>
Active claims loaded: N  (main: a, supp: b, discussion: c, exploratory-status: d)
Existing FIGURE_PLAN: <yes | no>
```

그리고 machine-readable marker (다음 단계 skill과 figure-review가 grep):
```html
<!-- figure-plan-step0
mode: <exploratory|manuscript>
claims_total: N
claims_main: a
claims_supp: b
claims_discussion: c
claims_deprecated: d
previous_plan: <yes|no>
claims_source: <CLAIMS.md | narrative-draft>
-->
```

---

## Step 1: Tag → Figure Placement Mapping

4-tag 시스템. Mode에 따라 강도 달라짐.

| Tag | Manuscript mode | Exploratory mode |
|-----|-----------------|------------------|
| `main` | MUST appear as focal or supporting in a main figure. 없으면 FAIL. | RECOMMEND main figure. 배치 안 해도 진행. |
| `supp` | ED/supplementary로. Main에 있으면 WARN. | 어디든 OK. |
| `discussion` | Panel 없음. Panel에 배치되면 WARN. | Panel 없음. Panel에 배치되면 INFO. |
| `deprecated` | 모든 output에서 제외. 참조 있으면 FAIL. | 제외. |

초기 figure assignment table:

| Claim | Tag | CLAIMS.Target figures | Recommendation |
|-------|-----|----------------------|----------------|
| C1 | main | Fig1c (focal) | KEEP |
| C2 | supp | FigS3 (supporting) | KEEP |
| C7 | discussion | Fig5d (focal) | REJECT — `discussion` tag cannot be a panel |

Conflict 발생 시 (manuscript mode):
- User에게 결정 요청: "C7은 `discussion` tag인데 Fig5d focal로 지정돼 있음. (a) Tag를 main으로 올릴지, (b) figure 배치를 제거할지?"

Exploratory mode는 같은 충돌을 INFO-level로 남기고 진행.

---

## 16 Hard Rules

### Structural Principles (P1-P7)
```
P1  FUNNEL      scope(P_{i+1}) <= scope(P_i) — 범위가 좁아져야 함
P2  EVIDENCE    dependency DAG = panel order — 증거가 결론보다 먼저
P3  DATA-ONLY   every element maps to data — 스키마/다이어그램 금지
P4  EXHAUSTIVE  show N_total before K_selected — 전체를 먼저, 부분은 나중
P5  VARIANTS    >= 2 visualizations per panel — 패널당 2개 이상 시각화
P6  SSOT        all paths in registry — 모든 경로는 DATA_MAP.md 참조
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
P14 CLAIM-MATCH  panel references a CLAIMS.md C{N} ID (manuscript: FAIL if missing, exploratory: WARN)
P15 LOGIC-FLOW   panel sequence builds an argument — A의 결론 = B의 전제
P16 RESTRAINT    no overclaiming — use claim's `Limitation` field verbatim in subtitle
```

---

## Step 2: Figure-by-Figure Design

### 2-1: Funnel Order (P1 + P2)
- Panel을 scope (large → small)로 정렬
- Dependency DAG이 reading order와 일치 확인
- Zoom level jump 크면 bridging panel 추가

### 2-2: Per-Panel Specification

각 panel이 가져야 하는 필드 (FIGURE_PLAN.md 엔트리가 됨):

| Field | Source | Notes |
|-------|--------|-------|
| Claim ID | CLAIMS.md `C{N}` | 직접 참조 (paraphrase 금지). Exploratory fallback claim이면 `C?-draft` 형식 허용. |
| Statement (verbatim) | CLAIMS.md `Statement` | 그대로 복사. |
| Numerical anchor | CLAIMS.md `Numerical anchor` | Subtitle에 등장. |
| Source script | CLAIMS.md `Source script` | FIGURE_PLAN.md에 기록 — figure-implement가 참조. |
| Data source | CLAIMS.md `Data source` | SSOT 키. |
| Statistical method | 설계 | adjustment 포함. |
| Visual encoding | 설계 | x/y/color/shape/size/alpha mapping. |
| Focal point (P8) | 설계 | 시선이 먼저 닿는 요소. |
| Grey-out strategy | 설계 | 비초점 de-emphasize 방법. |
| Variant 1 | 설계 | name + description. |
| Variant 2 | 설계 | name + description. |
| Message (P10) | 설계 | caption 없이 <5s에 읽히는 메시지. |
| Visual-claim match (P14) | 설계 | 시각 패턴이 claim을 어떻게 지지하는지. |
| Prior panel dependency (P15) | 설계 | 이 panel 전에 와야 하는 panel. |
| Transition sentence (P15) | 설계 | 이전 panel에서 오는 한 문장. |
| Limitation (P16) | CLAIMS.md `Limitation` | 그대로 복사. |
| Subtitle template | 유도 | "scope \| method \| sample". |

### 2-3: Validation Checklist

```
[ ] P1  FUNNEL:      scope sequence is monotone non-increasing
[ ] P2  EVIDENCE:    dependency DAG matches panel order
[ ] P3  DATA-ONLY:   no panel calls for schematics or diagrams
[ ] P4  EXHAUSTIVE:  every subset panel has a preceding universe panel
[ ] P5  VARIANTS:    every panel has >= 2 variants specified
[ ] P6  SSOT:        every Data source resolves in DATA_MAP.md
[ ] P7  CONSISTENT:  palette spec referenced (00_common)
[ ] P8  FOCUS:       every panel names exactly one focal element
[ ] P9  INK:         no panel requires gridlines/borders
[ ] P10 GLANCE:      every panel message is testable without caption
[ ] P11 ENCODE:      no panel relies solely on text/stars
[ ] P12 TYPE:        font hierarchy specified (8pt > 7pt > 6pt > 5pt)
[ ] P13 BREATHE:     no axis exceeds 20 items without aggregation
[ ] P14 CLAIM-MATCH: every panel cites a CLAIMS.md C{N} ID (exploratory allows C?-draft)
[ ] P15 LOGIC-FLOW:  every panel (except A) has transition sentence
[ ] P16 RESTRAINT:   every panel's Limitation field copied from CLAIMS.md
```

Manuscript mode는 모든 항목 FAIL on miss. Exploratory mode는 P14만 WARN으로 완화, 나머지는 동일.

---

## Step 3: Output

`outputs/figures/FIGURE_PLAN.md` 기록 구조:

```markdown
# Figure Plan
Last updated: {{DATE}}
Mode: <exploratory | manuscript>
CLAIMS source: <docs/CLAIMS.md parsed {{DATE}} | narrative-draft>

<!-- figure-plan-step0
... (Step 0 marker block)
-->

## Paper-Level Story Arc
- Fig1: <message, 1 sentence — based on which claims>
- Fig2: <...>
...

## Figure-by-Figure

### Fig1 — <ROLE>
**Message**: <one sentence>
**Claims supported**: C1 (main), C3 (main)

#### Panel A
- **Claim**: C1
- **Statement (from CLAIMS)**: <verbatim>
- **Numerical anchor**: <verbatim>
- **Source script**: <from CLAIMS>
- **Data source**: SSOT$<key>
- ... (Step 2-2의 모든 field)

#### Panel B
- ...
```

Exploratory mode 출력 시 파일 최상단에 경고 배너 (Step 0-5 참조) 필수.

---

## Decision Surface

**Silent**: visual encoding choice, palette assignment within constraints, panel layout.
**Ask user (both modes)**: Tag와 CLAIMS.Target figures 충돌, deprecated claim의 figure 참조.
**Ask user (manuscript only)**: stale anchor 의심, `Last recomputed` 90일 초과한 `main` claim.

---

## Common Pitfalls

| Pitfall | Violated | Fix |
|---------|----------|-----|
| CLAIMS.md에 없는 claim을 invent | P14 | CLAIMS에 먼저 추가하거나 panel 제거 |
| `discussion` tag를 main panel focal로 | Step 1 | Tag를 main으로 promote하거나 discussion으로 강등 |
| CLAIMS 건너뛰고 STORY만 읽기 | Step 0 | 항상 CLAIMS 먼저 |
| Hardcoded path | P6 | DATA_MAP.md SSOT 키 사용 |
| Panel A에 star result | P1, P2 | 뒤로 옮기고 context panel 먼저 |
| Y축 48 items | P13 | top-K + "N others" 또는 facet split |
| Subtitle에 "demonstrates" | P16 | Limitation field verbatim |
| Exploratory draft를 manuscript로 쓰기 | Step 0-5 | `--manuscript`로 재실행, gate 통과 확인 |

---

## Technique Matching Reference
| Data pattern | Recommended | Avoid |
|-------------|-------------|-------|
| Dramatic drop | Slopegraph, waterfall | Bar chart |
| Inequality | Lorenz curve, Gini | Manhattan |
| Effect + uncertainty | Forest plot with CI | Bar chart without error |
| Distribution N<100 | Half-violin + beeswarm | Boxplot alone |
| Comparison 2 conditions | Paired dot/dumbbell | Grouped bar |
| Null result (all NS) | Compact summary | 48-row heatmap |
| Stage gradient | Connected dot plot | Separate bars |
| Cross-cohort concordance | Mirror plot | Separate panels |

---

## Handoff
Output `outputs/figures/FIGURE_PLAN.md`는 `figure-implement` (Phase 2)가 소비.

**Schema** (Phase 5 이후 정식):
- `~/.claude/blueprints/schemas/FIGURE_PLAN.schema.md` — 출력 포맷 정식 스펙.
- 이 SKILL의 Step 2-2/3는 schema와 동일 내용. Schema가 canonical, 충돌 시 schema 우선.
