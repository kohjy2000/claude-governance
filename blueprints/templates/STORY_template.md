# {{PROJECT_NAME}} — Story

> **Purpose**: 내러티브 기록. *왜* 했는가, *어떻게* 결정이 진화했는가.
> **Pair with**: `CLAIMS.md` (구조화된 사실 — *무엇*을 아는가).
> **Boundary rule**: **"이 문장이 논문에 실릴 의도인가?"**
> - 예 → `CLAIMS.md`에 claim 엔트리로.
> - 아니오 → 여기 STORY에.

---

## Background
{{왜 이 프로젝트가 존재하는가. 어떤 gap, 어떤 동기, 어떤 선행 연구.}}

---

## Hypothesis Evolution

Framing이 시간에 따라 어떻게 바뀌었는지. 폐기된 hypothesis도 기록.

### Initial framing (~{{DATE}})
- H1: {{...}}
- H2: {{...}}

### Current framing (~{{DATE}})
- H1: {{...}}  (initial에서 정제됨)
- H2': {{...}} (H2가 pivot 후 교체됨 — Pivots 참조)

---

## Key Decisions

중요한 선택의 시간순 기록. 숫자가 필요하면 CLAIMS의 `C{N}` ID로 참조만 하고,
값 자체는 여기 쓰지 않는다.

| Date | Decision | Rationale | Alternative considered | Affected claims |
|------|----------|-----------|------------------------|----------------|
| {{YYYY-MM-DD}} | {{예: "Drop methylation panel from main figures"}} | {{왜}} | {{다른 옵션}} | C5 → deprecated; C8 새로 추가 |

---

## Pivots

주요 방향 전환 (>2주 작업 무효화, 또는 paper target 변경).

### Pivot 1: {{date}} — {{title}}
- **From**: {{이전 접근}}
- **To**: {{새 접근}}
- **Trigger**: {{무엇이 변경을 강제했는가}}
- **Sunk cost accepted**: {{버린 작업}}
- **Affected claims**: {{C1, C5 → revised; C7 → deprecated}}

---

## Bugs & Resolutions

>1일 소요한 기술적 문제. 반복 방지를 위해 기록.

| Date | Symptom | Root cause | Fix | Lesson |
|------|---------|-----------|-----|--------|
| {{YYYY-MM-DD}} | {{뭐가 망가졌는가}} | {{실제 원인}} | {{해결 방법}} | {{기억할 것}} |

---

## Open Questions

아직 모르지만 알고 싶은 것. Claims (확정된 사실)와 다름 — 명시적 불확실성.
Future work도 여기에 둔다. 답하면 CLAIMS의 새 claim으로 승격.

- Q: {{질문}}
  - Why it matters: {{...}}
  - How we'd answer: {{실험, 분석, 문헌}}
  - Status: open | answered (→ C{N}으로 이동)

---

## Cross-references
- Established facts: `CLAIMS.md`
- Current pipeline: `PIPELINE.md`
- Job history: `JOB_LOG.md`
- Figure work: `outputs/figures/FIGURE_PLAN.md`

---

## Document Discipline

**Boundary rule 한 줄**: "이 문장이 논문에 실릴 의도인가?" → 예면 CLAIMS, 아니면 STORY.

### 여기(STORY)에 쓰는 것
- 왜 이 접근을 다른 대안 대신 선택했는가
- 어떤 경로로 발견했는가 (결과가 아니라 여정)
- Scope, target paper, audience 결정
- 버그, 좌절, 막다른 길
- 5분 이상 고민한 추론

### CLAIMS로 가야 하는 것 (여기 쓰지 말 것)
- 숫자 (OR, p-value, sample size)
- 논문에 인용될 정확한 문장
- 유의미한 발견의 목록
- Figure에 대응되는 사실

### DATA_MAP로 가야 하는 것
- 파일 경로
- SSOT 키

### 헷갈리는 케이스 — worked examples

**예 1: "Methylation panel을 main에서 supplementary로 옮겼다"**
- 결정의 이유/대안 → Key Decisions (STORY)
- 옮김을 정당화한 숫자 (예: ARI=0.064) → CLAIMS C{N}에 `Tag: supp` 또는 `deprecated`

**예 2: "Feature scaling 버그로 3주 재분석했다"**
- 증상/원인/해결/교훈 → Bugs & Resolutions (STORY)
- 재분석 후 변경된 수치 → 해당 CLAIMS 엔트리의 `Revision history`에 append

**예 3: "Cluster 6이 WNT subtype을 대변한다 (84% CTNNB1 변이)"**
- 이 문장은 논문 본문에 들어간다 → CLAIMS, `Tag: main`
- 이 발견을 얻기까지의 시도/대안 → STORY Key Decisions에서 "Cluster 6 해석을 WNT로 정한 결정"으로 기록

**예 4: "ZFTA 케이스를 분석에서 제외했다"**
- 제외 이유/판단 → Key Decisions (STORY)
- 제외된 케이스의 통계 (있다면) → CLAIMS에 `Tag: deprecated` 엔트리로 보존
