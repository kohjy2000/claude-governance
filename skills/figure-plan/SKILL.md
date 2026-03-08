---
name: figure-plan
description: Phase 1 — Convert narrative/claims to figure design document using 16 principles (P1-P7 structure + P8-P13 visual + P14-P16 content/logic)
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# /figure-plan — Phase 1: Story → Design Doc

$ARGUMENTS: narrative/story 문서 경로 또는 claims 목록

## Role
Scientific figure architect. Narrative를 design document로 변환.

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

### Step 1: Claim 추출
- Narrative에서 모든 testable claim을 추출
- 각 claim에 data source 명시. 없으면 "needs data"로 플래그
- Subjective/interpretive claim → figure legend으로 분류, panel 아님

### Step 2: Figure별 Claim 그룹핑
- 전형적 구조: Fig1(overview) → Fig2(core association) → Fig3(mechanism) → Fig4(validation) → Fig5(synthesis)
- 한 figure당 3-9 panels

### Step 3: Funnel 순서 적용 (P1 + P2)
- 각 panel의 scope (N_tested) 기록
- 의존성 DAG 작성 → topological sort
- Scope가 단조감소하는지 검증
- Zoom level 전환 시 bridging panel 추가

### Step 4: Panel 상세 명세
각 panel에 대해:

| Field | Value |
|-------|-------|
| Data source | `SSOT$key` |
| Statistical method | method + adjustment |
| N tested / N sig | scope 수치 |
| Visual encoding | x=position, y=position, color=group, size=effect, alpha=context |
| Focal point (P8) | "무엇이 눈에 먼저 들어와야 하는가" |
| Grey-out strategy | "나머지는 어떻게 de-emphasize 하는가" |
| Variant 1 | name: description |
| Variant 2 | name: description |
| Message (P10) | "캡션 없이 이 패널에서 즉시 보이는 것" |
| Claim (P14) | "이 패널이 지지하는 구체적 주장" |
| Visual-claim match (P14) | "시각적 패턴이 claim을 어떻게 증명하는가" |
| Prior panel dependency (P15) | "독자가 이 패널을 이해하려면 어떤 패널을 먼저 봐야 하는가" |
| Transition sentence (P15) | "이전 패널에서 이 패널로의 논리적 연결 한 문장" |
| Limitation (P16) | "이 패널의 해석 한계 (NS, observational, underpowered 등)" |
| Dependencies | 선행 panel 목록 |
| Axis item count (P13) | N items — if >20, aggregation strategy 명시 |
| Subtitle template | "scope | method | sample" |

### Step 5: Principle 검증 체크리스트

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

## Output
Design document (markdown)를 `docs/` 또는 figure 디렉토리에 저장.
이 문서는 Phase 2 (`/figure-implement`)의 input이 된다.

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

## Technique Matching Reference
| Data pattern | Recommended technique | Avoid |
|-------------|----------------------|-------|
| Dramatic drop (5490→52) | Slopegraph, waterfall | Bar chart |
| Diffuseness/inequality | Lorenz curve, Gini | Manhattan |
| Effect + uncertainty | Forest plot with CI | Bar chart without error |
| Distribution N<100 | Half-violin + beeswarm | Boxplot alone |
| Comparison 2 conditions | Paired dot/dumbbell | Grouped bar |
| Null result (all NS) | Compact summary (volcano, histogram of p) | 48-row heatmap |
| Binary outcome matrix | Tile with 2 colors | Complex gradient |
| Stage gradient | Connected dot plot | Separate bar charts |
| Cross-cohort concordance | Mirror/back-to-back plot | Separate panels |
