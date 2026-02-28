---
name: figure-plan
description: Phase 1 — Convert narrative/claims to figure design document using 7 principles (P1-P7 funnel methodology)
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# /figure-plan — Phase 1: Story → Design Doc

$ARGUMENTS: narrative/story 문서 경로 또는 claims 목록

## Role
Scientific figure architect. Narrative를 design document로 변환.

## 7 Hard Rules (P1-P7)

```
P1  FUNNEL      scope(P_{i+1}) <= scope(P_i) — 범위가 좁아져야 함
P2  EVIDENCE    dependency DAG = panel order — 증거가 결론보다 먼저
P3  DATA-ONLY   every element maps to data — 스키마/다이어그램 금지
P4  EXHAUSTIVE  show N_total before K_selected — 전체를 먼저, 부분은 나중
P5  VARIANTS    >= 2 visualizations per panel — 패널당 2개 이상 시각화
P6  SSOT        all paths in registry — 모든 경로는 레지스트리에
P7  CONSISTENT  one palette, zero local overrides — 색상/라벨 중앙 관리
```

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
| Visual encoding | x, y, color, facet |
| Variant 1 | name: description |
| Variant 2 | name: description |
| Message | "한 문장 takeaway" |
| Dependencies | 선행 panel 목록 |
| Subtitle template | "scope \| method \| sample" |

### Step 5: Principle 검증 체크리스트

```
[ ] P1 FUNNEL:      scope sequence is monotone non-increasing (per figure)
[ ] P2 EVIDENCE:    dependency DAG matches panel order
[ ] P3 DATA-ONLY:   no panel calls for schematics, DAGs, or diagrams
[ ] P4 EXHAUSTIVE:  every subset panel has a preceding universe panel
[ ] P5 VARIANTS:    every panel has >= 2 variants specified
[ ] P6 SSOT:        every data source references an SSOT key
[ ] P7 CONSISTENT:  entity names/colors reference a single palette spec
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
