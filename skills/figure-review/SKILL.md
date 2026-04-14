---
name: figure-review
description: Phase 3 — Top-down figure review (Story Arc → Figure Role → Panel Content → Visual/Structural). Supports two granularities: figure-level (Layer 0/1 cross-panel) and panel-level (Layer 2/3 single panel). Catalog cross-ref via paper_panel comparison; optional multi-modal review with rendered PNG inspection. Output verdicts drive iteration loops in /figure-build (Loop F) and /panel-build (Loops V, C).
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /figure-review — Phase 3: Top-Down Figure Review

$ARGUMENTS:
- `granularity=figure|panel` (default: figure)
- `target=Fig{N}` (required)
- `panel={letter}` (required when granularity=panel)
- optional `catalog_xref=true|false` (default: true if SCRIPT_CATALOG.yml exists)
- optional `multimodal=true|false` (default: false; requires Vision LM access)

## Role
Scientific figure reviewer. **Story에서 시작하여 pixel로 내려가는** top-down 방식.
Panel 체크리스트가 아니라, "이 figure set이 논문의 argument를 빌드업하는가"를 먼저 묻는다.

**Granularity dispatch**:
- `granularity=figure`: Layer 0 (story arc) + Layer 1 (figure role + cross-panel consistency)
- `granularity=panel`: Layer 2 (P14-P16 content) + Layer 3 (P8-P13 visual) for one panel + catalog cross-ref + optional multi-modal

**Verdict drives loops**:
- Layer 0/1 FAIL → Loop S (escalate to user, no auto-fix)
- Layer 2 FAIL → Loop C (re-plan, called by /panel-build)
- Layer 3 FAIL → Loop V (re-implement, called by /panel-build)
- Cross-panel FAIL (figure granularity) → Loop F (re-trigger affected panels, called by /figure-build)

## Review Layers (반드시 이 순서로 실행)

```
Layer 0: Story Arc Review        ← 가장 먼저. Paper 전체 narrative chain.
Layer 1: Figure Role Review      ← Figure별 역할, 패널 필요성, 표현 적절성.
Layer 2: Content & Logic (P14-P16) ← Panel별 claim-visual match, restraint.
Layer 3: Visual & Structural (P1-P13) ← Panel별 체크리스트 (automated + visual).
```

**Layer 0-1이 FAIL이면 Layer 2-3 결과는 무의미.** 구조가 틀리면 pixel을 고쳐봐야 소용없다.

## Granularity = `figure` (Layer 0-1 + Cross-Panel)

Used by `/figure-build` Phase F3.

### Layer 0: Story Arc Review (Paper-Level)

#### 0-1. Narrative Chain 추출
Design doc + targets/Fig{N}_TARGET.md 에서 paper-level story arc 읽기.

```
Fig1: "[message]"
Fig2: "[message]"
...
```

#### 0-2. Argument Chain Test
각 figure 사이에 **transition sentence**:

```
Fig1 → Fig2: "[Fig1 conclusion] → [so naturally we ask] → [Fig2 answers]"
```

- PASS: 한 문장으로 자연스럽게 연결
- FAIL: 비약 또는 무관
- WARN: bridging 설명 필요

#### 0-3. Premise-Conclusion Chain
| Figure | Conclusion | Next Premise | Match |
|--------|------------|-------------|-------|

#### 0-4. Paper-Level Argument 1문장 요약
"이 논문의 그림만 보고 도달할 수 있는 결론은: ____"
Design doc의 intended conclusion과 비교. Gap 식별.

#### 0-5. 불필요한 Figure 검출
"이 figure가 없으면 argument가 성립하는가?"

### Layer 1: Figure Role Review (Figure-Level)

#### 1-1. Figure 역할 정의
LANDSCAPE / ZOOM / MECHANISM / VALIDATION / SYNTHESIS

#### 1-2. Panel 필요성 심사 (Figure 내부)
각 panel에 4가지 질문:
1. **왜 여기 있는가?**
2. **없으면 argument가 약해지는가?**
3. **앞 panel의 결론에서 자연스럽게 이어지는가?**
4. **다른 panel과 중복되는가?**

#### 1-3. 표현 적절성 심사
"이 claim을 전달하기에 **이 시각화가 최적인가?**"

(상세 기준은 Common Pitfalls 절 참고)

#### 1-4. Figure 내부 Logic Flow
Panel 순서의 argument chain. Transition sentence 가능한지.

#### 1-5. Panel Count 적정성
Nature: 3-7 panels per main figure (8+ = 과밀)
**Catalog/STYLE_GUIDE 가 다른 N 권장하면 그 값 우선**

### NEW: Cross-Panel Consistency Check (figure granularity)

Layer 1 보강 항목:
- **Palette 일관성**: 모든 panel의 NB 색상이 BASELINE의 `DX_PRIMARY[["NB"]]` 와 일치하는가?
  - Grep panels 코드: `grep "DX_PRIMARY\|DX_SECONDARY"`
  - Hardcoded hex가 있으면 FAIL
- **Typography 일관성**: 모든 panel이 `theme_nature(base_size=N)` 동일 N 사용?
- **Axis convention**: y-axis Dx 순서 (`DX_SPECTRUM_ORDER`) 동일?
- **Composite feasibility**: panel 합 width <= 183mm AND height <= 247mm
- **Legend 중복**: 모든 panel이 같은 legend 따로 그림? → composite-shared로 통합 권장

Cross-panel FAIL → Loop F trigger (figure-build)

## Granularity = `panel` (Layer 2-3 + Catalog + Multi-modal)

Used by `/panel-build` Phase P3.

### Layer 2: Content & Logic Checks (P14-P16, Panel-Level)

#### Check 14: Claim-Match (P14)
**Visual + data inspection. Most critical panel-level check.**

For the panel:
1. Identify the panel's stated claim (from design doc)
2. Ask: "독자가 이 그림만 보고 이 claim에 도달할 수 있는가?"
3. Check: 시각적 패턴 (slope, separation, overlap)이 claim을 직접 보여주는가?
4. **Data verification**: claim의 수치가 실제 데이터와 일치하는가?
5. **Assertion check (NEW)**: 코드 내 `assert_narrative()` 호출이 PASS 했는가?
   - Read panel R script, check for `assert_narrative` blocks
   - Run script (if not already) and check for assertion stop()

- PASS: 시각적 패턴 + 수치 + assertion 모두 일치
- **FAIL-DATA**: 수치 불일치 (기존 narrative 수정 필요 vs data 재계산 필요)
- **FAIL-VISUAL**: claim은 데이터와 맞지만 그림에서 안 보임 → Loop V 또는 design 재고
- **FAIL-ABSENT**: claim 자체가 없음 (subtitle만 있고 message 불명)

#### Check 15: Logic Flow (P15)
Panel의 prior dependency 확인 (panel-level은 single panel이라 cross-panel은 figure-level에서)

#### Check 16: Restraint (P16)
**Title/subtitle/annotation text inspection.**
```bash
# Causal verbs (forbidden per AGENTS.md)
grep -niE 'demonstrates|proves|causes|drives|induces|leads to' Fig{N}_{p}.R
# 매치 = FAIL

# Overclaiming NS
grep -niE 'trend|suggestive|borderline|approaching' Fig{N}_{p}.R
# 매치 = WARN (acceptable only with explicit p-value)
```

- PASS: "association", "correlated", "observed" only
- PASS: NS는 "NS (p=0.xx)" 명시
- FAIL: causal verb / NS overclaiming
- WARN: "suggestive (p=0.096)" — p-value 동반시 acceptable but flag

### Layer 3: Visual & Structural Checks (P1-P13, Panel-Level)

#### P8 Focal Point
- [ ] focal element visible (saturated color / larger size)
- [ ] context = grey/transparent
- FAIL: 전체 동일 색상/크기

#### P9 Data-Ink
```bash
grep -nE 'theme_bw|theme_grey|theme_classic.*\(\)|panel\.border.*element_rect|panel\.grid\.minor' Fig{N}_{p}.R
# theme_bw/grey 매치 = FAIL (theme_nature() 사용 권장)
```

#### P10 Glance Test
**Multi-modal optional**: 5초 만에 caption 없이 메시지 도달 가능한가?
- 코드만 보고는 불가, rendered PNG 보고 판단 (multi-modal=true 필요)

#### P11 Visual Encoding
```bash
grep -nE "label.*[★✱\\*]|geom_text.*star|annotate.*\\*" Fig{N}_{p}.R
# 매치 = FAIL (filled vs hollow, color saturation으로 대체)
```

#### P12 Typography
- `theme_nature(base_size = N)` 호출에서 N 추출
- `geom_text(size = ...)` annotation 크기 일관성
- Font hierarchy (8 > 7 > 6 > 5pt)

#### P13 Breathing Room
- axis items count: `Read panel design`, count Top-K
- `geom_text` overlap 가능성: rotated 45°? truncated? facet split?

### NEW: Catalog Cross-Reference Check (panel granularity)

If panel design has `catalog_ref` AND `paper_panel` set:

1. **Locate paper PDF panel**:
   - Read `reference/papers/*.pdf` at the page containing `paper_panel: "Fig 2b"` (use heuristic)
   - Extract that panel image (`Read pdf pages=N`)

2. **Compare to our rendered panel**:
   - Side-by-side: paper panel (left) vs our `Fig{N}_{p}.png` (right)
   - **Visual diff** (manual or vision LM):
     - Same plot type? (heatmap vs heatmap ✓)
     - Same focal pattern? (corner cluster, diagonal, etc.)
     - Color palette family? (warm vs cool similar?)
     - Annotation density? (paper has ~5 labels, ours has ~5 ✓)

3. **Verdict**:
   - **MATCH**: ours follows paper's pattern → PASS bonus
   - **DIFFERENT_BUT_INTENTIONAL**: our narrative justified deviation (e.g., different data shape) → WARN
   - **MISMATCH**: shouldn't differ → FAIL (likely catalog clone-modify error)

If `paper_panel` not set in design (orphan panel) → skip cross-ref.

### NEW: Multi-Modal Review (panel granularity, optional)

If `multimodal=true` AND Vision LM access available:

1. **Read rendered PNG**: `Read output/panels/Fig{N}_{p}.png`
2. **Vision LM inspection** prompts:
   - "Are any text labels overlapping in this figure?"
   - "What is the visual focal point?"
   - "Is the message clear within 5 seconds without reading caption?"
   - "Identify potential color contrast issues"
3. **Aggregate findings** into Layer 3 report

This catches issues code review misses (label collision, color contrast, axis density visual perception).

## Output: Review Report

리뷰는 Layer 순서대로 출력. Layer 0-1이 가장 중요.

### Granularity = `figure` Output Template
`docs_figure/figure_pipeline/review_reports/Fig{N}_figure_iter{N}.md`:

```markdown
# Figure Review Report (Figure-level)
Target: Fig{N}
Granularity: figure
Iteration: {N}
Date: <DATE>

═══════════════════════════════════════════════
## Layer 0: Story Arc
═══════════════════════════════════════════════

### Paper Story Arc
{per-figure messages}

### Cross-Figure Argument Chain
| Transition | Sentence | Status |
|------------|----------|--------|

### Premise-Conclusion Match
| Figure | Conclusion | Next Premise | Match? |

### Paper-Level Conclusion
- Intended: "..."
- Achievable: "..."
- Gap: ...

═══════════════════════════════════════════════
## Layer 1: Figure Roles & Panel Necessity
═══════════════════════════════════════════════

### Fig{N}: [Role] — "[message]"

| Panel | Role | Necessary? | Expression fit | Redundant | Verdict |
|-------|------|------------|---------------|-----------|---------|

### Cross-Panel Consistency
- Palette: {PASS/FAIL with hardcoded hex list}
- Typography: {PASS/FAIL with theme call audit}
- Axis convention: {PASS/FAIL}
- Composite feasibility: {within 183mm × 247mm? Y/N}
- Legend redundancy: {N panels have separate legends → recommend share}

═══════════════════════════════════════════════
## Verdict
═══════════════════════════════════════════════

[ ] Ready (proceed to /figure-assemble)
[ ] Cross-panel fix needed → Loop F (re-trigger panels: {a, c})
[ ] Layer 0/1 FAIL → Loop S, ESCALATE to user
```

### Granularity = `panel` Output Template
`docs_figure/figure_pipeline/review_reports/Fig{N}_{p}_iter{N}.md`:

```markdown
# Panel Review Report
Target: Fig{N} panel {p}
Granularity: panel
Iteration: {N}
Date: <DATE>

═══════════════════════════════════════════════
## Layer 2: Content & Logic (P14-P16)
═══════════════════════════════════════════════

### P14 Claim-Match
| Item | Status |
|------|--------|
| Stated claim | C{x.y}: "..." |
| Visual pattern | {match/mismatch} |
| Data verification | {actual: 2.45, expected: 2.33, tolerance: 0.5 → PASS} |
| Assertion in code | {PASS/FAIL — assert_narrative output} |

### P15 Logic Flow
- Prior dependency: {met/not} |

### P16 Restraint
| Check | Status |
|-------|--------|
| Causal verbs | {0 found / found: ["demonstrates"]} |
| NS overclaiming | {0 / found: ["trend"]} |
| Subtitle limitation noted | {Y/N} |

═══════════════════════════════════════════════
## Layer 3: Visual & Structural (P8-P13)
═══════════════════════════════════════════════

| Principle | Status | Issue |
|-----------|--------|-------|
| P8 FOCUS | PASS/FAIL | {focal grey-out missing} |
| P9 INK | PASS/FAIL | {theme_bw used} |
| P10 GLANCE | PASS/FAIL/SKIPPED | {requires multi-modal} |
| P11 ENCODE | PASS/FAIL | {star annotation found} |
| P12 TYPE | PASS/FAIL | {mixed font sizes} |
| P13 BREATHE | PASS/FAIL | {28 axis items, no aggregation plan} |

═══════════════════════════════════════════════
## Catalog Cross-Reference
═══════════════════════════════════════════════

- catalog_ref: {path L{X}-{Y}}
- paper_panel: "Fig 2b"
- Visual match to paper: {MATCH / DIFFERENT_BUT_INTENTIONAL / MISMATCH}
- Cross-ref strength: {strong / medium / weak / none}

═══════════════════════════════════════════════
## Multi-Modal Review (if enabled)
═══════════════════════════════════════════════

- Label overlap: {none / minor / severe}
- Visual focal point: {as designed / different / unclear}
- 5-sec message: {clear / unclear}
- Color contrast: {OK / issues at <ratio>}

═══════════════════════════════════════════════
## Verdict
═══════════════════════════════════════════════

[ ] Ready (return to /figure-build with status=done)
[ ] Loop V trigger (visual fix, max 3): {issues_list}
[ ] Loop C trigger (content fix, max 2): {issues_list}
[ ] ESCALATE Loop S (story arc / role)

## Action Items

### Loop V (visual fixes — same design, re-implement)
1. ...

### Loop C (content fixes — partial re-plan)
1. ...
```

## Severity Levels

### CRITICAL (Layer 0-1 — structural redesign)
- Story arc break
- Premise-conclusion mismatch
- Panel has no role
- Visualization mismatches claim type
→ ESCALATE Loop S to user

### HIGH (Layer 2 — content fixes)
- P14 FAIL: claim unsupported by visual or data mismatch
- P14 FAIL: assertion failure (narrative ↔ data)
- P15 FAIL: within-figure logic gap
- P16 FAIL: causal verb or NS overclaiming
→ Loop C in /panel-build

### MEDIUM (Layer 3 — visual fixes)
- P8-P13 individual panel issues
- Catalog cross-ref MISMATCH
→ Loop V in /panel-build

### LOW (cross-panel polish)
- Cross-panel palette hardcode (not BASELINE ref)
- Legend redundancy (could share)
- Typography slight mismatch
→ Loop F in /figure-build

## Bash Helpers

### Quick Layer 3 sweep (panel granularity)
```bash
PANEL_R="code/Fig2_c.R"

# P3 (DATA-ONLY) violation
grep -nE 'geom_tile.*geom_text|gt::|kableExtra' $PANEL_R

# P9 INK
grep -nE 'theme_bw|theme_grey|panel\.border|panel\.grid\.minor' $PANEL_R

# P11 ENCODE (star)
grep -nE 'label.*[★✱]|geom_text.*"\\*"|annotate.*"\\*"' $PANEL_R

# P16 RESTRAINT (causal)
grep -niE 'demonstrates|proves|causes|drives|induces|leads to' $PANEL_R

# C6 hardcoded hex
grep -nE '"#[0-9A-Fa-f]{6}"' $PANEL_R | grep -v "00_common.R"

# A1 assertions present
grep -cE 'assert_narrative\(' $PANEL_R
```

### Cross-panel palette consistency (figure granularity)
```bash
# All panels for Fig{N}
PANELS=$(ls code/Fig{N}_*.R 2>/dev/null)

for f in $PANELS; do
  echo "=== $f ==="
  # Hardcoded hex (excluding 00_common references)
  grep -nE '"#[0-9A-Fa-f]{6}"' "$f" | grep -v 'DX_PRIMARY\|DX_SECONDARY\|FACTOR_FAMILY' | head -5
done
```

## Common Pitfalls

| Pitfall | Layer | Fix |
|---------|-------|-----|
| Reviewing pixels before story arc | (process) | ALWAYS Layer 0 → 1 → 2 → 3 |
| Missing data ↔ narrative assertion | L2 P14 | Implement should have `assert_narrative()`; if missing, FAIL |
| Catalog cross-ref skipped | (process) | If `paper_panel` set, MUST compare |
| Loop V re-triggered for L2 issue | (verdict mapping) | L2 → Loop C, L3 → Loop V; never confuse |
| Multi-modal disabled but message unclear | L3 P10 | Re-run with `multimodal=true` if Vision LM available |
| Overclaiming "improvement" without metric | (review prose) | Use objective scoring, not subjective impressions |

## Notes for Implementers

- Bash grep helpers are FAST — run them first before deeper analysis
- Multi-modal review uses Read tool on PNG (Claude can read images directly)
- Catalog cross-ref needs reference paper PDF accessible
- Output verdict must be machine-parseable for /figure-build / /panel-build to act on
- Iteration trend: track P1-P16 score (0-2 per principle) across iterations to detect oscillation
