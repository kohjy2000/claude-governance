---
name: figure-review
description: Phase 3 — Top-down figure review. Layer 0 (Story Arc with CLAIMS) → Layer 1 (Figure Role) → Layer 2 (Content/Logic) → Layer 3 (Visual/Structural). Layer 0-1 FAIL = Layer 2-3 meaningless. Writes narrative audit trail to REVIEW_LOG.md.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# /figure-review — Phase 3: Top-down figure review

`$ARGUMENTS`:
- Figure scope (예: `Fig1-Fig5`, `Fig3 only`). 생략 시 전체.
- `--hook-log-only` — hook.log만 aggregate 훑고 REVIEW_LOG 갱신. Layer 전체 review 안 함.
- `--auto` — figure-implement 종료 시 자동 invoke됨을 표시. Step 0 요구사항 완화 (missing 파일 시 STOP 대신 WARN + 부분 review).

예: `/figure-review Fig1-Fig5`

## Invocation
1. **Manual**: user가 명시적으로 `/figure-review` 호출 (figure work 중간 점검).
2. **Auto (from figure-implement)**: `figure-implement` 스킬이 panel 생성 완료 직후 `/figure-review --auto` 자동 호출. 기본 동작.
   - Phase 1-5: `figure-implement` 스킬 마지막 step에 "이 스킬 끝나면 `/figure-review --auto` 호출하라"는 지시를 박음. 기술적으로 LLM의 tool-chain으로 구현.
   - Phase 6 이후: PostToolUse hook이 `figure-implement` 완료 감지 → subagent로 `/figure-review` 자동 dispatch.
3. **Hook-driven FAIL escalation**: Phase 6 이후 hook이 Layer 3 FAIL 감지 시 즉시 subagent invoke (`--hook-log-only`).

> **Phase 2 TODO**: `figure-implement/SKILL.md`에 "Step N (last): 완료 후 `/figure-review --auto` 호출" 라인을 추가해야 함. 이 Turn 2에서는 figure-review 쪽만 스펙 고정. figure-implement 파일 수정은 Phase 2 범위.

## Role
Independent reviewer. Story → Figure → Panel 순의 top-down. 각 layer가 자체 pass criterion 가짐.
"Layer 0-1이 FAIL이면 Layer 2-3는 의미 없다" — 상위 layer 실패 시 즉시 escalate, 하위 layer는 skip.

---

## Step 0: Load context + hook.log

### 0-1. `outputs/figures/FIGURE_PLAN.md`
- 없으면 STOP. "`/figure-plan` 먼저 돌려라."
- 상단 `<!-- figure-plan-step0` 블록 parse → mode (exploratory/manuscript), claims count per tag, CLAIMS source 획득.
- Exploratory draft (`claims_source: narrative-draft`)인 FIGURE_PLAN은 review 대상이 아님. "Manuscript mode로 재생성 후 review하라"고 지시 후 STOP.

### 0-2. `docs/CLAIMS.md`
- FIGURE_PLAN에 참조된 `C{N}` ID가 모두 resolve되는지 확인.
- Tag 재확인 — FIGURE_PLAN의 panel 배치와 CLAIMS의 현재 Tag가 mismatch면 Layer 1 FAIL 후보.
- `Last recomputed` 체크: `main` tag claim이 90일 초과 → Layer 1 WARN (stale anchor 위험).
- `deprecated` tag claim이 FIGURE_PLAN에 남아있으면 즉시 Layer 0 FAIL.

### 0-3. `docs/STORY.md`
- `Hypothesis Evolution` current framing + `Pivots` 읽음.
- Story arc가 FIGURE_PLAN의 paper-level message와 consistent한지 Layer 0에서 검증.

### 0-4. `outputs/figures/hook.log` (존재 시)
- **직전 subagent 실행 timestamp 이후**의 엔트리만 훑는다. 첫 실행이면 전체.
- 반복 발생 패턴 식별 (같은 panel, 같은 rule violation 3회 이상) → Layer 3 aggregate 엔트리 후보.
- FAIL-level 엔트리가 REVIEW_LOG에 이미 escalate 됐는지 교차 확인 — 안 됐으면 이번 review에서 승격.

### 0-5. `outputs/figures/REVIEW_LOG.md` (존재 시)
- 최신 N개 엔트리 읽어 "이번 review가 이전 review의 action item을 resolve하는지" 추적.
- Append-only 원칙 준수 — 이전 엔트리 수정 절대 금지. 취소/번복은 새 엔트리에서 이전 timestamp 참조.

### Step 0 output (화면)

```
Mode: <from figure-plan-step0>
CLAIMS state: N main / M supp / K discussion / D deprecated  (stale_main: X)
Hook log since last review: L entries (F FAIL / W WARN / I INFO)
Previous REVIEW_LOG: T entries, last at <timestamp>
```

Machine-readable marker (REVIEW_LOG의 이번 엔트리 헤더에 삽입):
```html
<!-- figure-review-run
timestamp: <ISO8601>
mode_inherited: <from figure-plan>
hook_log_range: <from_ts>..<to_ts>
review_scope: <$ARGUMENTS>
-->
```

---

## Layer 0: Story Arc (MOST CRITICAL)

**Question**: Paper 전체 서사가 FIGURE_PLAN의 figure 순서로 성립하는가? CLAIMS.md의 `main` tag claim들이 figure에 실제로 등장하는가?

### Checks

| Check | Manuscript mode | Exploratory mode |
|-------|-----------------|------------------|
| 모든 `main` tag claim이 FIGURE_PLAN에 1회 이상 등장 | FAIL if 부재 | WARN if 부재 |
| `deprecated` tag claim이 FIGURE_PLAN에 참조됨 | FAIL | FAIL |
| Fig 순서의 message가 STORY current framing과 정렬 | FAIL if 역행 | WARN if 역행 |
| Paper story arc가 3줄로 요약 가능 (Fig1→FigN) | FAIL if 불가 | Skip |

Layer 0 FAIL → 즉시 REVIEW_LOG에 `[L0-FAIL]` prefix로 기록, Layer 1-3 skip. Action: "Story 재설계 또는 CLAIMS Tag 재검토."

---

## Layer 1: Figure Role

**Question**: 각 figure가 고유 역할을 가지는가? Panel 필수성이 확보되는가? Claim-figure 매핑이 CLAIMS와 일치하는가?

### Per-figure checks
1. **Role statement**: "이 figure가 paper에서 담당하는 논증 역할"을 한 문장으로 쓸 수 있는가.
2. **Panel necessity**: 각 panel 제거 시 figure message가 약해지는가. 제거해도 무방한 panel 존재 시 WARN.
3. **Claim-panel 매핑 일치**: FIGURE_PLAN의 `Claim ID` 필드가 CLAIMS의 현재 Tag와 정합 (예: `supp` tag claim이 main figure focal로 배치 → FAIL).
4. **Expression fit**: 선택된 chart type이 데이터 패턴에 적합한가 (figure-plan Technique Matching Reference 재검증).

Layer 1 FAIL → `[L1-FAIL]` prefix로 REVIEW_LOG. Action item 포함. Layer 2-3 skip for that figure.

---

## Layer 2: Content/Logic (P14-P16, panel-level)

Subagent가 수행하는 판단성 review. Hook으로 자동화 불가.

| Rule | Check |
|------|-------|
| P14 CLAIM-MATCH | 시각 패턴이 claim statement를 실제로 지지하는가 (단순히 C{N} ID만 적혀있는 게 아니라). |
| P15 LOGIC-FLOW | 이전 panel 결론이 이 panel 전제인가. Transition sentence가 실질적 logic bridge인가. |
| P16 RESTRAINT | Subtitle의 Limitation이 CLAIMS verbatim인가. Overclaim 표현이 슬쩍 들어갔는가. |

Layer 2 FAIL → `[L2-FAIL]` prefix로 기록. 해당 panel만 해당, 다른 panel Layer 3은 계속 진행.

---

## Layer 3: Visual/Structural (P1-P13, panel-level) [hook-owned in Phase 6]

**현재 (Phase 1-5)**: subagent가 mechanical하게 체크. 주로 grep-level.
**Phase 6 이후**: PostToolUse hook이 매 figure-implement 실행 후 자동 수행. 이 SKILL.md의 Layer 3 섹션은 hook 코드로 이전되고 subagent는 hook.log aggregate만 수행.

### Mechanical checks (currently here, moving to hook in Phase 6)

| Rule | Grep target |
|------|-------------|
| P1 FUNNEL | FIGURE_PLAN panel 순서의 scope monotone 확인 |
| P2 EVIDENCE | Dependency DAG vs reading order |
| P3 DATA-ONLY | Panel 기술에 schematic/diagram keyword 없는지 |
| P5 VARIANTS | 각 panel에 variant ≥2 명시됐는지 |
| P6 SSOT | 모든 path가 DATA_MAP 참조인지 (hardcoded path FAIL) |
| P9 INK | gridlines/borders/shadows 명시 여부 |
| P12 TYPE | font size hierarchy 명시 |
| P13 BREATHE | 축 항목 수 |

Layer 3 WARN은 hook.log에만, FAIL은 REVIEW_LOG에 escalation.

---

## Output protocol: log dual-write

### REVIEW_LOG.md (narrative, paper audit trail)

Append-only. 이번 review의 단일 엔트리는 다음 구조:

```markdown
## Review {{ISO8601}}

<!-- figure-review-run
timestamp: ...
mode_inherited: ...
hook_log_range: ...
review_scope: ...
-->

### Summary
- Mode: <...>
- Overall: <PASS | L0-FAIL | L1-FAIL | L2-FAIL | L3-issues-only>
- Claims audited: <list of C{N}>
- Hook.log aggregate: <N FAIL escalated, M recurring patterns promoted>

### Findings
- [L0-FAIL] ... (if any)
- [L1-FAIL] ... (if any)
- [L2-FAIL] ... (if any)
- [L3-FAIL-from-hook] ... (escalated from hook.log)
- [OK] <brief per-layer pass note>

### Action items
- [ ] <sorted by severity, each with owner & target date>

### Reference
- Previous review: <timestamp of prior REVIEW_LOG entry>
- hook.log range covered: <from>..<to>
```

### hook.log (mechanical, dev artifact)

Hook이 PostToolUse에서 직접 append. 각 줄 format:
```
{{ISO8601}} | {{level}} | {{rule}} | {{panel}} | {{message}}
```
- level ∈ {FAIL, WARN, INFO}
- rule ∈ P1..P16
- panel 예: Fig1A, Fig3B

Hook FAIL 감지 시 **추가로** REVIEW_LOG에 즉시 `[hook-fail]` prefix append:
```markdown
## Hook FAIL {{ISO8601}}
- Rule: P6 SSOT
- Panel: Fig3B
- Detail: hardcoded path `/data/x.csv` outside DATA_MAP
- Auto-logged from hook.log
- Subagent review pending
```

이 escalation 엔트리는 다음 subagent review에서 action 정해진 후 정식 findings 블록으로 이어서 기록. 삭제 금지.

---

## Supersede pattern (append-only preservation)

이전 review의 action item이 resolve되었을 때:
```markdown
### Action items
- [x] ~~Fig3B에 CI 표시 추가~~ → resolved 2026-04-30 (supersedes action from 2026-04-15)
```
기존 엔트리를 고치지 않고 새 엔트리에서 참조.

Claim Tag 변경으로 이전 review의 finding이 무효화되었을 때:
```markdown
### Note
- [L1-FAIL from 2026-04-10 review] was based on C7 tagged as `main`.
  C7 is now `supp` (CLAIMS updated 2026-04-12). Finding superseded.
```

---

## Subagent 호출 (Phase 6 이후)

Phase 6에서 figure-review는 **독립 subagent**로 분리. 호출 규약:
- Main agent → subagent: prompt 문자열 + FIGURE_PLAN.md/CLAIMS.md/hook.log 파일 참조
- Subagent → main agent: REVIEW_LOG.md에 append (persistent) + 30줄 이하 summary (transient, stdout)

현재 (Phase 1-5)는 main agent 내에서 수행. 동일 skill 스펙.

---

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Layer 0 skip하고 Layer 3 먼저 | 항상 top-down. Layer 0 FAIL이면 Layer 3 의미 없음. |
| Exploratory draft를 review 대상으로 | Step 0-1에서 STOP. Manuscript mode 재생성 요구. |
| Hook.log 안 읽고 review | 직전 hook FAIL을 놓침. Step 0-4 필수. |
| REVIEW_LOG 기존 엔트리 수정 | Append-only 위반. Supersede pattern 사용. |
| CLAIMS와 FIGURE_PLAN의 Tag mismatch를 "minor"로 분류 | Layer 1 FAIL. Paper 제출 직전 큰 리스크. |

---

## Handoff
- Input: `outputs/figures/FIGURE_PLAN.md`, `docs/CLAIMS.md`, `docs/STORY.md`, `outputs/figures/hook.log` (있으면)
- Output: `outputs/figures/REVIEW_LOG.md` (append-only)
- Next: user가 action item resolve 후 figure-implement 재실행 또는 CLAIMS 수정 후 figure-plan 재실행

**Schemas** (Phase 5):
- `~/.claude/blueprints/schemas/REVIEW_LOG.schema.md` — 출력 엔트리 포맷 정식 스펙. 이 SKILL의 "Output protocol" 섹션과 동일 내용, schema가 canonical.
- `~/.claude/blueprints/schemas/FIGURE_PLAN.schema.md` — 입력 파일 포맷 참조.
- `~/.claude/blueprints/schemas/PANEL_REGISTRY.schema.md` — variant 참조 시 사용.
