---
name: figure-review
description: Phase 3 — Top-down figure review: Story Arc → Figure Role → Panel Content → Visual/Structural checks
allowed-tools: Read, Bash, Glob, Grep
---

# /figure-review — Phase 3: Top-Down Figure Review

$ARGUMENTS: figure 디렉토리 경로 또는 특정 figure 번호

## Role
Scientific figure reviewer. **Story에서 시작하여 pixel로 내려가는** top-down 방식.
Panel 체크리스트가 아니라, "이 figure set이 논문의 argument를 빌드업하는가"를 먼저 묻는다.

## Review Layers (반드시 이 순서로 실행)

```
Layer 0: Story Arc Review        ← 가장 먼저. Paper 전체 narrative chain.
Layer 1: Figure Role Review      ← Figure별 역할, 패널 필요성, 표현 적절성.
Layer 2: Content & Logic (P14-P16) ← Panel별 claim-visual match, restraint.
Layer 3: Visual & Structural (P1-P13) ← Panel별 체크리스트 (automated + visual).
```

**Layer 0-1이 FAIL이면 Layer 2-3 결과는 무의미.** 구조가 틀리면 pixel을 고쳐봐야 소용없다.

---

## Layer 0: Story Arc Review (Paper-Level)

### 0-1. Narrative Chain 추출
Design doc에서 paper-level story arc를 읽고, 각 figure의 **1-sentence message**를 추출한다.

```
Fig1: "[message]"
Fig2: "[message]"
Fig3: "[message]"
...
```

### 0-2. Argument Chain Test
각 figure 사이에 **transition sentence**를 쓸 수 있는가?

```
Fig1 → Fig2: "Fig1 conclusion이 Fig2의 전제가 되는가?"
  sentence: "[Fig1 showed X] → [so naturally we ask Y] → [Fig2 answers Y]"
Fig2 → Fig3: ...
Fig3 → Fig4: ...
Fig4 → Fig5: ...
```

- PASS: 한 문장으로 자연스럽게 연결. 독자가 "다음에 뭘 보여줄지" 예측 가능.
- FAIL: transition을 쓸 수 없거나, 독자가 "왜 갑자기 이걸?" 이라고 물을 수밖에 없음.
- WARN: 연결은 되지만 비약이 있어서 bridging 설명이 필요.

### 0-3. Premise-Conclusion Chain
각 figure의 결론(conclusion)과 다음 figure의 전제(premise)를 명시적으로 나열한다.

| Figure | Conclusion (독자가 이 figure 후 알게 되는 것) | Next Figure's Premise (다음 figure가 전제하는 것) | Match? |
|--------|---------------------------------------------|--------------------------------------------------|--------|

- Match = PASS: conclusion이 premise를 충분히 커버
- Partial = WARN: conclusion이 premise의 일부만 커버 (독자가 gap을 채워야 함)
- Mismatch = FAIL: conclusion이 premise와 무관하거나 모순

### 0-4. Paper-Level Argument 1문장 요약
전체 figure set을 본 후, 독자가 도달해야 할 최종 결론을 1문장으로:
- "이 논문의 그림만 보고 도달할 수 있는 결론은: ____________"
- Design doc의 intended conclusion과 비교.
- Gap이 있으면 어느 figure에서 빠졌는지 식별.

### 0-5. 불필요한 Figure 검출
각 figure에 대해:
- "이 figure가 없으면 argument가 성립하는가?"
- YES → figure 삭제 또는 Supp 이동 고려
- NO → 필수 figure

---

## Layer 1: Figure Role Review (Figure-Level)

### 1-1. Figure 역할 정의
각 figure가 argument에서 수행하는 역할을 명시:

| Role | 설명 | 예시 |
|------|------|------|
| LANDSCAPE | 전체 데이터를 보여줌 (funnel 시작) | Fig2: 102,758 tests |
| ZOOM | landscape에서 subset을 확대 | Fig2-E: M4 × SBS |
| MECHANISM | HOW/WHY를 설명 | Fig3: CDT→DSB→LOH |
| VALIDATION | 독립 데이터에서 재현 | Fig4: prediction + external |
| SYNTHESIS | 여러 결과를 통합 정리 | Fig5: cross-cohort |

### 1-2. Panel 필요성 심사 (Figure 내부)
각 panel에 4가지 질문:

1. **왜 여기 있는가?** — 이 panel이 figure의 argument에서 맡은 역할
   - 답 불가 → 삭제 후보
2. **없으면 argument가 약해지는가?** — 필수성
   - NO → Supp 이동 후보
3. **앞 panel의 결론에서 자연스럽게 이어지는가?** — 논리적 위치
   - NO → 순서 재배치 또는 bridging 추가
4. **다른 panel과 중복되는가?** — 유일성
   - YES → merge 또는 한쪽 삭제

### 1-3. 표현 적절성 심사
각 panel에 대해: "이 claim을 전달하기에 **이 시각화가 최적인가?**"

| Claim 유형 | 좋은 표현 | 나쁜 표현 | 왜? |
|------------|----------|----------|-----|
| 극적 감소 (5490→52) | slopegraph, waterfall | bar chart | 시각적 "절벽"이 필요 |
| 확산/집중 | Lorenz curve, Gini | manhattan | 불균등 분포가 곡선으로 보임 |
| 효과 크기 + 불확실성 | forest + CI | dot chart without CI | CI 없으면 확실성 판단 불가 |
| count 비교 (4 vs 0) | bar chart, annotation | 28-row forest | count는 bar가 직관적 |
| 방향 전환 (sig→NS) | filled/hollow, mirror bar | table | 시각적 대비 필요 |
| 전체 landscape | heatmap, category bar | 개별 나열 | 패턴 인식이 목적 |
| null result (all NS) | p-histogram, compact summary | 48-row heatmap | "없다"를 보여주는 데 48행 불필요 |
| replication status | concordance dot plot | tile+text table | shape/color encoding > text |

**Red flags:**
- 시각화 선택이 claim 유형과 불일치 → "표현이 메시지를 방해한다"
- 같은 정보를 다른 패널에서 이미 보여줌 → 중복
- N_items >> 20 인데 message는 "몇 개만 sig" → Top-K로 축소

### 1-4. Figure 내부 Logic Flow
Figure 내 panel 순서의 argument chain:

```
For each figure:
  Panel A conclusion: "..."
  → Panel B premise: "..." (match? YES/NO/PARTIAL)
  Panel B conclusion: "..."
  → Panel C premise: "..." (match? YES/NO/PARTIAL)
  ...
```

Transition sentence를 각 panel 사이에 작성:
- 쓸 수 있으면 PASS
- 억지스러우면 WARN
- 불가능하면 FAIL

### 1-5. Panel Count 적정성
- Nature: main figure당 3-7 panels가 적정. 8+ = 과밀
- 각 figure panel 수 확인. 과밀 시 merge/split/supp 이동 제안.

---

## Layer 2: Content & Logic Checks (P14-P16, Panel-Level)

### Check 14: Claim-Match (P14)
**Visual + data inspection. Most critical panel-level check.**
For each panel:
1. Identify the panel's stated claim (from title/subtitle or design doc)
2. Ask: "독자가 이 그림만 보고 이 claim에 도달할 수 있는가?"
3. Check: 시각적 패턴 (slope, separation, overlap)이 claim을 직접 보여주는가?
4. **Data verification**: claim의 수치가 실제 데이터/렌더링과 일치하는가?

- PASS: 시각적 패턴이 claim을 직관적으로 증명 + 수치 일치
- FAIL-VISUAL: claim은 맞지만 그림에서 안 보임 → 시각화 재설계
- FAIL-DATA: claim 수치가 데이터와 불일치 → claim 수정 필요
- FAIL-ABSENT: claim이 아예 없음 (title만 있고 what-to-see 불명확)

**Red flag questions:**
- "이 패널의 시각적 패턴이 claim의 반대로도 해석될 수 있는가?" → ambiguity
- "claim에 사용된 수치(3/3, 99.1%, 6×)가 렌더링된 그림에서 확인 가능한가?"

### Check 15: Logic Flow (P15)
(Layer 1-4에서 이미 수행. 여기서는 결과를 기록.)

### Check 16: Restraint (P16)
**Title/subtitle/annotation text inspection.**
```bash
# Code check: causal verbs (forbidden per AGENTS.md)
grep -niE 'demonstrates|proves|causes|drives|induces|leads to' Fig*.R Supp*.R
# 매치 = FAIL

# Code check: overclaiming NS results
grep -niE 'trend|suggestive|borderline|approaching' Fig*.R Supp*.R
# 매치 = WARN (acceptable only if explicit p-value accompanies)
```

- PASS: "association", "correlated", "observed" only
- PASS: NS 결과는 "NS (p=0.xx)" 명시
- FAIL: causal verb 사용
- FAIL: NS를 "trend"으로 표현하면서 p-value 미기재
- WARN: "suggestive (p=0.096)" — p-value 동반이므로 acceptable but flag

**Subtitle limitation check:**
- 모든 NS 패널: subtitle에 "NS" 명시 필수
- Observational 연구: 최소 1곳에 "observational" 또는 "association" 명시
- External validation 실패: "not replicated" 또는 "NS in [cohort]" 명시

---

## Layer 3: Visual & Structural Checks (P1-P13, Panel-Level)

### Structural (P1-P7) — mostly automated

#### P1 Funnel
- 각 panel subtitle에서 scope 추출 → 단조감소 확인

#### P2 Evidence Before Conclusion
- dependency DAG = panel order

#### P3 Data-Only
- 화살표 다이어그램, 개념도, subjective grade 금지
- table-as-figure (geom_tile+geom_text) = P3 FAIL

#### P4 Exhaustive Before Selective
- Subset panel은 선행 universe panel 필요

#### P5 Multi-Variant
```bash
for panel in A B C D E F G H I; do
  n=$(ls panels/Fig*_${panel}_*.png 2>/dev/null | wc -l)
  echo "Panel $panel: $n variants $([ $n -ge 2 ] && echo OK || echo FAIL)"
done
```

#### P6 SSOT Provenance
```bash
grep -n 'read_tsv\|read_csv\|fread' Fig*.R | grep -v 'SSOT\$'
```

#### P7 Cross-Figure Consistency
- Hex literals outside 00_common = FAIL

### Visual Storytelling (P8-P13) — visual + code

#### P8 Focal Point
- [ ] focal element 있는가? (saturated color / larger size)
- [ ] context = grey/transparent?
- FAIL: 전체 동일 색상/크기

#### P9 Data-Ink
```bash
grep -nE 'theme_bw|theme_grey|theme_classic|panel\.border.*element_rect|panel\.grid\.minor' Fig*.R Supp*.R
```

#### P10 Glance Test
- 5초 만에 캡션 없이 메시지 도달 가능한가?

#### P11 Visual Encoding
```bash
grep -nE "label.*[★✱\\*]|geom_text.*star|annotate.*\\*" Fig*.R Supp*.R
```

#### P12 Typography
- 5-7pt body, 8pt bold lowercase labels

#### P13 Breathing Room
- axis items ≤ 20, no overlap

---

## Output: Review Report

리뷰는 Layer 순서대로 출력한다. Layer 0-1이 가장 중요.

```markdown
# Figure Review Report
Date: <DATE>

═══════════════════════════════════════════════
## Layer 0: Story Arc
═══════════════════════════════════════════════

### Paper Story Arc
Fig1: "[message]"
Fig2: "[message]"
...

### Cross-Figure Argument Chain
| Transition | Sentence | Status |
|------------|----------|--------|
| Fig1→Fig2  | "[conclusion] → [question] → [answer]" | PASS/FAIL |
| Fig2→Fig3  | ... | ... |

### Premise-Conclusion Match
| Figure | Conclusion | Next Premise | Match? |
|--------|------------|-------------|--------|

### Paper-Level Conclusion
- Intended: "..."
- Achievable from figures alone: "..."
- Gap: <where the argument breaks>

═══════════════════════════════════════════════
## Layer 1: Figure Roles & Panel Necessity
═══════════════════════════════════════════════

### FigX: [Role] — "[1-sentence message]"

| Panel | Role in argument | Necessary? | Expression fit? | Redundant? | Verdict |
|-------|-----------------|------------|-----------------|------------|---------|

#### Panel flow: A → B → C → ...
- A→B transition: "..."
- B→C transition: "..."

#### Issues
- <panel X is redundant with Y>
- <panel Z uses wrong visualization for its claim type>
- <panel count: N panels (OK / too many)>

(Repeat for each figure)

═══════════════════════════════════════════════
## Layer 2: Content & Logic (P14-P16)
═══════════════════════════════════════════════

### P14 Claim-Match
| Panel | Claim | Visual pattern | Data match? | Status |
|-------|-------|---------------|-------------|--------|

### P16 Restraint
| Panel | Language check | NS labeled? | Status |
|-------|--------------|-------------|--------|

═══════════════════════════════════════════════
## Layer 3: Visual & Structural (P1-P13)
═══════════════════════════════════════════════

### Summary
| Figure | P1-P7 | P8-P13 | Issues |
|--------|-------|--------|--------|

### Specific failures
(only list actual failures, not PASS items)

═══════════════════════════════════════════════
## Action Items (prioritized)
═══════════════════════════════════════════════

### STORY-LEVEL (fix first — structure changes)
1. ...

### CONTENT-LEVEL (fix second — claim/data issues)
1. ...

### VISUAL-LEVEL (fix last — polish)
1. ...

## Verdict
[ ] Ready
[ ] Visual fixes only
[ ] Content fixes needed
[ ] Structural redesign required ← Layer 0-1 failures
```

---

## Severity (updated with Layer 0-1)

### CRITICAL (Layer 0-1 failures — structural redesign)
- Story arc break: figure transition 불가
- Premise-conclusion mismatch between figures
- Panel has no role in argument (unnecessary)
- Panel shows same info as another (redundant)
- Visualization type mismatches claim type (wrong expression)
- Figure-level conclusion doesn't support paper conclusion

### HIGH (Layer 2 failures — content fixes)
- P14 FAIL: claim unsupported by visual or data mismatch
- P15 FAIL: within-figure logic gap
- P16 FAIL: causal verb or NS overclaiming

### MEDIUM (Layer 3 failures — visual fixes)
- P8-P13 individual panel issues

### LOW (minor polish)
- P1-P7 minor structural issues
