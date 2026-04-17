---
name: figure-review
description: Phase 3 — Top-down figure review (Story Arc → Figure Role → Panel Content → Visual/Structural → Rendered Image). Supports two granularities (figure-level Layer 0/1 vs panel-level Layer 2-4) and catalog cross-ref via paper_panel comparison. Layer 4 is optional multi-modal (rendered PNG vision review). Output writes both per-iteration detailed report AND append-only REVIEW_LOG entry. Verdicts drive iteration loops in /figure-build (Loop F) and /panel-build (Loops V, C). Invoked directly (slash) or via figure-reviewer subagent (Task).
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /figure-review — Phase 3: Top-Down Figure Review

`$ARGUMENTS`:
- `granularity=figure|panel` (default: figure)
- `target=Fig{N}` (required)
- `panel={letter}` (required when granularity=panel)
- optional `catalog_xref=true|false` (default: true if SCRIPT_CATALOG.yml exists)
- optional `multimodal=true|false` (default: false; reads rendered PNG via Vision)
- optional `--auto` — auto-invoked by figure-implement Step N (looser gate if CLAIMS stub)
- optional `--hook-log-only` — aggregate hook.log only, skip Layer 0-3

**Schemas**:
- Output: `~/.claude/blueprints/schemas/REVIEW_LOG.schema.md` (audit trail entry format)
- Input: `~/.claude/blueprints/schemas/FIGURE_PLAN.schema.md`, `PANEL_REGISTRY.schema.md`
- Hook log: `~/.claude/blueprints/schemas/HOOK_LOG.schema.md` (Phase 6 Turn 3+)

## Role
Scientific figure reviewer. **Story에서 시작하여 pixel로 내려가는** top-down 방식.
Panel 체크리스트가 아니라, "이 figure set이 논문의 argument를 빌드업하는가"를 먼저 묻는다.

**Granularity dispatch**:
- `granularity=figure`: Layer 0 (story arc) + Layer 1 (figure role + cross-panel consistency)
- `granularity=panel`: Layer 2 (P14-P16) + Layer 3 (P8-P13) + Layer 4 (optional multimodal) + catalog cross-ref

**Model selection (caller가 결정, 이 SKILL은 수동적 수신)**:
- `granularity=figure` 또는 `multimodal=true` → **Opus** 필수. Layer 0-1 narrative reasoning + 이미지 인식 정확도.
- `granularity=panel`, `multimodal=false` → **Sonnet** 충분. Layer 2-4는 구조화된 rule 체크.
- 토큰 절약 근거: panel-level review ~90K → Sonnet이면 비용 ~1/5, 품질은 rule 체크에 충분.

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
Layer 3: Visual & Structural (P1-P13) ← Panel별 체크리스트 (automated grep).
Layer 4: Rendered Image Review (NEW, optional) ← Vision read of rendered PNG.
```

**Layer 0-1이 FAIL이면 Layer 2-4 결과는 무의미.** 구조가 틀리면 pixel을 고쳐봐야 소용없다.

---

## Step 0: Load context + hook.log (both granularities)

### 0-1. FIGURE_PLAN & machine marker
- `docs_figure/figure_pipeline/design_docs/Fig{N}_design.md` (figure) 또는 `Fig{N}_{p}_design.md` (panel) 없으면 STOP.
- 상단 `<!-- figure-plan-step0 -->` 블록 parse → mode (exploratory/manuscript), claims count. Mode 상속.
- Exploratory draft (`claims_source: narrative-draft`)면 review 수행 but 결과에 "design-of-record 아님" 명시.

### 0-2. CLAIMS.md — **Selective Reading (전체 Read 금지)**
Design doc에서 참조된 claim group만 읽는다. 전체 CLAIMS.md Read는 context 오염 (cross-contamination) 위험.

**절차**:
1. Design doc의 `Claims supported` + 각 Panel의 `Claim` 필드에서 claim ID 수집 (e.g., C2-1, C2-3 → group C2)
2. Bash로 해당 group 섹션만 추출:
   ```bash
   grep -n "^## C" docs/CLAIMS.md                                    # 섹션 위치 파악
   sed -n '/^## C2$/,/^## C[0-9]/p' docs/CLAIMS.md | head -n -1     # C2만
   ```
3. 추출된 섹션에서 `deprecated` tag 확인 → 있으면 즉시 Layer 0 FAIL.
4. `Last recomputed` 90일 초과한 `main` tag claim → Layer 1 WARN (stale anchor 위험).

**절대 `Read docs/CLAIMS.md` 전체를 하지 않는다.**

### 0-2b. DATA_MAP.md — **Selective Reading (전체 Read 금지)**
Layer 2 P14 data verification 시 SSOT key의 실제 경로가 필요하다. Design doc의 `Data source` 필드에서 key 추출 후 해당 행만 읽는다.
```bash
head -20 docs/DATA_MAP.md                                              # Base Paths
grep -E "^\| (Key|mutation_matrix|cluster_assignment) " docs/DATA_MAP.md  # 필요한 key만
```
**절대 `Read docs/DATA_MAP.md` 전체를 하지 않는다.**

### 0-3. PANEL_REGISTRY (panel granularity)
- `docs_figure/PANEL_REGISTRY.md` 읽어 이번 panel의 variant/status 확인.
- `Status: selected` 아닌 엔트리를 review 대상으로 하면 WARN.

### 0-4. hook.log (Phase 6 Turn 3+)
- `docs_figure/hook.log` (있으면) 직전 review 이후 엔트리 훑음.
- 반복 패턴 (같은 Panel + Rule이 3회 이상) 식별 → Layer 3 aggregate 엔트리 후보.
- FAIL-level 엔트리가 REVIEW_LOG에 이미 escalate 됐는지 교차 확인.

### 0-5. REVIEW_LOG.md 기존 엔트리
- `docs_figure/REVIEW_LOG.md` 마지막 N 엔트리 읽어 이전 action items resolve 여부 추적.
- Append-only 원칙 — 기존 엔트리 수정 절대 금지. 취소는 supersede 패턴.

### 0-6. Step 0 output (stdout)

```
Mode: <exploratory | manuscript>
Granularity: <figure | panel>
CLAIMS state: N main / M supp / K discussion / D deprecated (stale_main: X)
PANEL_REGISTRY: L variants (S selected)
Hook log since last review: H entries (F FAIL / W WARN / I INFO)
Previous REVIEW_LOG: T entries, last at <timestamp>
```

---

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

#### 0-6. Deprecated claim 감지
FIGURE_PLAN_OVERVIEW의 claim 리스트 중 CLAIMS.md에서 `Tag: deprecated`인 것 있으면 즉시 Layer 0 FAIL.

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

#### 1-4. Figure 내부 Logic Flow
Panel 순서의 argument chain. Transition sentence 가능한지.

#### 1-5. Panel Count 적정성
Nature: 3-7 panels per main figure (8+ = 과밀).
Catalog/STYLE_GUIDE 가 다른 N 권장하면 그 값 우선.

#### 1-6. Claim Tag ↔ Panel role 정합
- Tag: main → focal 또는 supporting panel
- Tag: supp → supplementary 또는 ED
- Tag: discussion → panel 배치 금지 (Layer 1 FAIL)

### Cross-Panel Consistency Check (figure granularity)

Layer 1 보강 항목:
- **Palette 일관성**: 모든 panel의 NB 색상이 BASELINE의 `DX_PRIMARY[["NB"]]` 와 일치?
  - `grep -n '"#[0-9A-Fa-f]\{6\}"' code/Fig{N}_*.R | grep -v '00_common'`
  - Hardcoded hex가 있으면 FAIL
- **Typography 일관성**: 모든 panel이 `theme_nature(base_size=N)` 동일 N 사용?
- **Axis convention**: y-axis Dx 순서 동일?
- **Composite feasibility**: panel 합 width ≤ 183mm AND height ≤ 247mm
- **Legend 중복**: 모든 panel이 separate legend 그림? → composite-shared 권장

Cross-panel FAIL → Loop F trigger (figure-build)

---

## Granularity = `panel` (Layer 2-4 + Catalog + Multi-modal)

Used by `/panel-build` Phase P3.

### Layer 2: Content & Logic Checks (P14-P16, Panel-Level)

#### Check 14: Claim-Match (P14)
**Visual + data inspection. Most critical panel-level check.**

For the panel:
1. Identify panel's stated claim (from design doc, CLAIMS.md C{group}-{N})
2. Ask: "독자가 이 그림만 보고 이 claim에 도달할 수 있는가?"
3. Check: 시각적 패턴이 claim을 직접 보여주는가?
4. **Data verification**: claim의 Numerical anchor가 실제 데이터와 일치?
5. **Assertion check**: 코드 내 `assert_narrative()` 호출 PASS?
   - Read panel R script, check for `assert_narrative` blocks (A1 compliance)
   - Run script (if not already) and check for assertion stop()

- PASS: 시각적 패턴 + 수치 + assertion 모두 일치
- **FAIL-DATA**: 수치 불일치 (narrative 수정 or data 재계산 필요)
- **FAIL-VISUAL**: claim은 데이터와 맞지만 그림에서 안 보임 → Loop V 또는 design 재고
- **FAIL-ABSENT**: claim 자체가 없음 (subtitle만 있고 message 불명)

#### Check 15: Logic Flow (P15)
Panel의 prior dependency 확인. Cross-panel은 figure-level에서.

#### Check 16: Restraint (P16)
**Title/subtitle/annotation text inspection.**
```bash
# Causal verbs (CLAIMS schema banned.CausalVerbs)
grep -niE 'demonstrates|proves|causes|drives|induces|leads to|shows|indicates|establishes|confirms' code/Fig{N}_{p}.R
# 매치 = FAIL

# Overclaiming NS
grep -niE 'trend|suggestive|borderline|approaching' code/Fig{N}_{p}.R
# 매치 = WARN (p-value 명시하면 acceptable)
```

- PASS: "association", "correlated", "observed" only. NS는 "NS (p=0.xx)" 명시
- PASS: Subtitle에 CLAIMS.md `Limitation` field verbatim 포함
- FAIL: causal verb / NS overclaiming
- WARN: "suggestive (p=0.096)" — p-value 동반 시 acceptable but flag

### Layer 3: Visual & Structural Checks (P1-P13, Panel-Level)

Phase 6 Turn 3에서 PostToolUse hook으로 일부 자동화 예정 (Layer 3 중 grep 가능한 것).

#### P8 Focal Point
- [ ] focal element visible (saturated color / larger size)
- [ ] context = grey/transparent
- FAIL: 전체 동일 색상/크기

#### P9 Data-Ink
```bash
grep -nE 'theme_bw|theme_grey|panel\.border.*element_rect|panel\.grid\.minor' code/Fig{N}_{p}.R
# theme_bw/grey 매치 = FAIL (theme_nature() 권장)
```

#### P10 Glance Test
**Layer 4 multimodal 필요**: 5초 내 caption 없이 메시지 도달 가능한가?
- 코드만으로는 불가, rendered PNG 보고 판단.

#### P11 Visual Encoding
```bash
grep -nE 'label.*[★✱\*]|geom_text.*star|annotate.*\*' code/Fig{N}_{p}.R
# 매치 = FAIL (filled vs hollow, color saturation으로 대체)
```

#### P12 Typography
- `theme_nature(base_size = N)`의 N 추출
- `geom_text(size = ...)` annotation 크기 일관성
- Font hierarchy (8 > 7 > 6 > 5pt)

#### P13 Breathing Room
- axis items count: design doc의 Top-K 명시 확인
- `geom_text` overlap 가능성: rotated 45°? truncated? facet split?

### Catalog Cross-Reference Check (panel granularity)

If panel design has `catalog_ref` AND `paper_panel` set:

1. **Locate paper PDF panel**:
   - Read `reference/papers/*.pdf` at page containing `paper_panel: "Fig 2b"` (heuristic)
   - Extract that panel image (`Read pdf pages=N`)

2. **Compare to our rendered panel** (requires Layer 4 multimodal):
   - Side-by-side: paper panel (left) vs our `output/panels/Fig{N}_{p}.png` (right)
   - Visual diff: plot type match? focal pattern? color palette family? annotation density?

3. **Verdict**:
   - MATCH: ours follows paper's pattern → PASS bonus
   - DIFFERENT_BUT_INTENTIONAL: narrative justified deviation → WARN
   - MISMATCH: shouldn't differ → FAIL (likely catalog clone-modify error)

If `paper_panel` not set (orphan panel) → skip cross-ref.

### Layer 4: Rendered Image Review (NEW, multimodal=true required)

Layer 3까지 FAIL 없으면 진입. FAIL 있으면 Layer 4 skip (렌더링 재검토 낭비).

1. **Read rendered PNG**: Claude vision으로 `output/panels/Fig{N}_{p}.png` 직접 read.
2. **Vision inspection** prompts:
   - "Are any text labels overlapping in this figure?" (P13 render-level)
   - "What is the visual focal point? Does it match the stated focal from design doc?" (P8 render-level)
   - "Is the message clear within 5 seconds without reading caption?" (P10)
   - "Identify potential color contrast issues (e.g., fails WCAG AA)"
   - "Aspect ratio and composition balanced?"
3. **Aggregate findings** into Layer 4 section of review report.

이건 code review로 못 잡는 것만: label collision, actual color contrast, aspect distortion, render artifacts.

---

## Output: Dual-log (per-iter detailed + REVIEW_LOG append-only)

리뷰는 **두 파일**에 기록:

### File 1: Per-iteration detailed report
`docs_figure/figure_pipeline/review_reports/Fig{N}_{iter}.md` (figure) 또는 `Fig{N}_{p}_iter{N}.md` (panel).
Legacy 4-layer 구조 그대로. /panel-build Loop V/C, /figure-build Loop F 용 상세 report.

### File 2: Append-only REVIEW_LOG entry
`docs_figure/REVIEW_LOG.md`. 각 review 세션마다 한 개 entry append. Paper submission audit trail.

Schema: REVIEW_LOG.schema.md.

#### Entry 포맷 (subagent review)

```markdown
## Review YYYY-MM-DDTHH:MM:SS±TZ

<!-- figure-review-run
timestamp: ...
granularity: <figure|panel>
target: Fig{N}
panel: <letter|null>
mode_inherited: <exploratory|manuscript>
hook_log_range: <from>..<to>
claims_audited: C1-1, C1-2, C1-3
-->

### Summary
- Mode: <...>
- Overall: <PASS | L0-FAIL | L1-FAIL | L2-FAIL | L3-issues-only | L4-issues-only>
- Claims audited: ...
- Hook.log aggregate: <N FAIL escalated, M recurring patterns promoted>

### Findings
- [L0-FAIL] <description> (if any)
- [L1-FAIL] <description> (if any)
- [L2-FAIL] <description> (if any)
- [L3-FAIL-from-hook] <description> (escalated from hook.log)
- [L4-WARN] <label overlap | color contrast | etc.>
- [OK] <per-layer pass notes>

### Action items
- [ ] <severity-sorted, owner, target date>

### Reference
- Previous review: <timestamp>
- Detailed report: docs_figure/figure_pipeline/review_reports/Fig{N}_{p}_iter{N}.md
- hook.log range covered: <from>..<to>
```

### Hook FAIL escalation entry (Phase 6 Turn 3+)

Hook이 Severity=FAIL 감지 시 동시에 REVIEW_LOG에 append:

```markdown
## Hook FAIL YYYY-MM-DDTHH:MM:SS±TZ
- Rule: <P{N}>
- Panel: <Fig{N}{X}>
- Detail: <one line>
- Auto-logged from hook.log
- Subagent review pending
```

다음 subagent review에서 이 entry가 정식 Findings로 확장되거나 resolved로 supersede됨.

### Supersede pattern

이전 action item resolve 시 새 entry:
```markdown
### Action items
- [x] ~~Fig3B CI 표시 추가~~ → resolved 2026-04-30 (supersedes action from 2026-04-15)
```
기존 entry는 고치지 않고 새 entry에서 참조.

---

## Detailed report templates (legacy)

### Granularity = `figure` per-iter template

```markdown
# Figure Review Report (Figure-level)
Target: Fig{N}
Granularity: figure
Iteration: {N}
Date: <DATE>

═══════════════════════════════════════════════
## Layer 0: Story Arc
═══════════════════════════════════════════════
(Fig cross-arc, transitions, premise-conclusion chain, paper-level argument, unnecessary figure detection, deprecated claim scan)

═══════════════════════════════════════════════
## Layer 1: Figure Roles & Panel Necessity
═══════════════════════════════════════════════
| Panel | Role | Necessary? | Expression fit | Redundant | Tag-match | Verdict |

### Cross-Panel Consistency
- Palette: {PASS/FAIL}
- Typography: {PASS/FAIL}
- Axis convention: {PASS/FAIL}
- Composite feasibility: {within 183mm × 247mm? Y/N}
- Legend redundancy: {...}

═══════════════════════════════════════════════
## Verdict
═══════════════════════════════════════════════

[ ] Ready (proceed to /figure-assemble)
[ ] Cross-panel fix needed → Loop F (re-trigger panels: {a, c})
[ ] Layer 0/1 FAIL → Loop S, ESCALATE to user
```

### Granularity = `panel` per-iter template

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
| Stated claim | C{group}-{N}: "..." |
| Visual pattern | {match/mismatch} |
| Data verification | {actual: 2.45, expected: 2.33, tolerance: 0.5 → PASS} |
| Assertion in code | {PASS/FAIL — assert_narrative output} |

### P15 Logic Flow
- Prior dependency: {met/not}

### P16 Restraint
| Check | Status |
| Causal verbs | {0 found / found: ["demonstrates"]} |
| NS overclaiming | {0 / found: ["trend"]} |
| Subtitle limitation (CLAIMS verbatim) | {Y/N} |

═══════════════════════════════════════════════
## Layer 3: Visual & Structural (P1-P13)
═══════════════════════════════════════════════

| Principle | Status | Issue |
| P8 FOCUS | PASS/FAIL | ... |
| P9 INK | PASS/FAIL | ... |
| P10 GLANCE | SKIPPED | requires Layer 4 multimodal |
| P11 ENCODE | PASS/FAIL | ... |
| P12 TYPE | PASS/FAIL | ... |
| P13 BREATHE | PASS/FAIL | ... |

═══════════════════════════════════════════════
## Catalog Cross-Reference
═══════════════════════════════════════════════

- catalog_ref: {path L{X}-{Y}}
- paper_panel: "Fig 2b"
- Visual match to paper: {MATCH / DIFFERENT_BUT_INTENTIONAL / MISMATCH}
- Cross-ref strength: {strong / medium / weak / none}

═══════════════════════════════════════════════
## Layer 4: Rendered Image Review (if multimodal=true)
═══════════════════════════════════════════════

- Label overlap: {none / minor / severe}
- Visual focal point: {as designed / different / unclear}
- 5-sec message: {clear / unclear}
- Color contrast: {OK / issues at <ratio>}
- Aspect/composition: {balanced / distorted}

═══════════════════════════════════════════════
## Verdict
═══════════════════════════════════════════════

[ ] Ready (return to /figure-build with status=done)
[ ] Loop V trigger (visual fix, max 3): {issues_list}
[ ] Loop C trigger (content fix, max 2): {issues_list}
[ ] ESCALATE Loop S (story arc / role)
```

---

## Severity Levels

### CRITICAL (Layer 0-1 — structural redesign)
- Story arc break
- Premise-conclusion mismatch
- Panel has no role
- Visualization mismatches claim type
- Deprecated claim in design
→ ESCALATE Loop S to user

### HIGH (Layer 2 — content fixes)
- P14 FAIL: claim unsupported / data mismatch / assertion failure
- P15 FAIL: within-figure logic gap
- P16 FAIL: causal verb / NS overclaiming
→ Loop C in /panel-build

### MEDIUM (Layer 3 — visual fixes)
- P8-P13 individual panel issues
- Catalog cross-ref MISMATCH
→ Loop V in /panel-build

### LOW (cross-panel polish)
- Cross-panel palette hardcode
- Legend redundancy
- Typography slight mismatch
→ Loop F in /figure-build

### INFO (Layer 4 multimodal findings)
- Label overlap minor
- Color contrast borderline
→ Loop V if severe, else note-only

---

## Bash Helpers

### Quick Layer 3 sweep (panel granularity)
```bash
PANEL_R="code/Fig2_c.R"

grep -nE 'geom_tile.*geom_text|gt::|kableExtra' $PANEL_R                    # P3 DATA-ONLY
grep -nE 'theme_bw|theme_grey|panel\.border|panel\.grid\.minor' $PANEL_R    # P9 INK
grep -nE 'label.*[★✱]|geom_text.*"\\*"|annotate.*"\\*"' $PANEL_R            # P11 ENCODE
grep -niE 'demonstrates|proves|causes|drives|induces|leads to|shows|indicates|establishes|confirms' $PANEL_R  # P16
grep -nE '"#[0-9A-Fa-f]{6}"' $PANEL_R | grep -v "00_common.R"               # C6 hardcoded hex
grep -cE 'assert_narrative\(' $PANEL_R                                       # A1 assertions present
```

### Cross-panel palette consistency (figure granularity)
```bash
for f in code/Fig{N}_*.R; do
  echo "=== $f ==="
  grep -nE '"#[0-9A-Fa-f]{6}"' "$f" | grep -v 'DX_PRIMARY\|DX_SECONDARY\|FACTOR_FAMILY' | head -5
done
```

---

## Common Pitfalls

| Pitfall | Layer | Fix |
|---------|-------|-----|
| Reviewing pixels before story arc | (process) | ALWAYS Layer 0 → 1 → 2 → 3 → 4 |
| Missing data ↔ narrative assertion | L2 P14 | Implement should have `assert_narrative()`; if missing, FAIL |
| Catalog cross-ref skipped | (process) | If `paper_panel` set, MUST compare |
| Loop V re-triggered for L2 issue | (verdict mapping) | L2 → Loop C, L3 → Loop V |
| Multimodal disabled but message unclear | L3 P10 | Re-run with `multimodal=true` |
| REVIEW_LOG entry 누락 | (output) | 매 review는 per-iter file + REVIEW_LOG entry 둘 다 기록 |
| Hook FAIL을 REVIEW_LOG에 승격 안 함 | (escalation) | Phase 6 Turn 3 hook → 자동. 이전엔 subagent 수동 승격. |

---

## Invocation Paths

1. **Direct slash**: user가 `/figure-review granularity=... target=...` 호출.
2. **Auto (figure-implement)**: `/figure-implement` Step N의 Task tool dispatch로 figure-reviewer subagent 호출.
3. **Hook-driven escalation (Phase 6 Turn 3+)**: PostToolUse hook이 Layer 3 FAIL 감지 시 subagent invoke (`--hook-log-only`).

---

## Notes for Implementers
- Bash grep helpers는 빠름 — 먼저 run 후 심층 분석
- Multi-modal (Layer 4) uses Read tool on PNG (Claude vision 직접 read)
- Catalog cross-ref needs reference paper PDF accessible
- Output verdict는 machine-parseable해야 /figure-build / /panel-build가 act 가능
- Iteration trend: track P1-P16 점수 (0-2 per principle) — oscillation 감지
- REVIEW_LOG entry의 timestamp는 ISO 8601 with timezone (schema 준수)
- 기존 REVIEW_LOG entry 수정 절대 금지 (append-only). Supersede pattern 사용.
