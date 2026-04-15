# {{PROJECT_NAME}} — Claim Registry
Last updated: {{DATE}}

> **Purpose**: "이 프로젝트에서 우리가 아는 사실"의 구조화된 기록.
> **Pair with**: `STORY.md` (내러티브 — *왜* 했는가).
> **Schema**: `~/.claude/blueprints/schemas/CLAIMS.schema.md`
> **작성 시간 목표**: 한 claim 2분 이내. 항목 채우기 부담되면 exploratory tag로 먼저 올리고 나중에 보강.

---

## Tag Policy (4-tier, manual)

통계적 p-value가 아니라 **논문에서의 역할**이 기준.

| Tag | 의미 |
|-----|-----|
| `main` | Main figure에 등장해야 하는 발견. 빠지면 논문 성립 안 함 또는 main story 약화. |
| `supp` | Supplementary/ED figure로 간다. Main text 문장에는 언급. |
| `discussion` | Discussion 문단 언급만. 단독 panel 없음. |
| `deprecated` | Paper에서 제외. 기록은 보존. |

탈락(Future work, 외부 발표)은 CLAIMS가 아니라 `STORY.md §Open Questions`로 간다.

---

## Target Paper

- Primary: {{TARGET_PAPER}}  (예: "Genome Medicine 2026Q3")
- Secondary: {{SECONDARY_PAPER}}  (선택. 쉼표 구분 가능. 없으면 `none`)

---

## Active Claims

> Tag가 `deprecated`인 엔트리도 이 섹션에 남긴다. 별도 Deprecated 섹션 없음.
> ID는 영구. C3이 한 번 지정되면 재사용 금지, 삭제 시에도 ID는 유지.

<!-- 엔트리 템플릿 — 복사해서 붙이고 채운다

### C{N}
- **Tag**: main | supp | discussion | deprecated
- **Statement**: <한 문장 사실 진술. 인과동사 금지 (demonstrates/proves/causes/drives/induces/leads to/shows/indicates/establishes/confirms).>
- **Numerical anchor**: <논문에 그대로 인용될 값. 예: OR=4.04, p=8.4e-8, n=253>
- **Source script**: <path:line 권장. 최소 파일 경로. 예: scripts/05_survival.R:142>
- **Data source**: SSOT$<key1>; SSOT$<key2>   (`;` 구분. DATA_MAP.md 키와 일치)
- **Evidence type** *(advisory)*: enrichment | survival | correlation | clustering | replication | natural-experiment | other
- **Target paper**: primary | secondary | none
- **Target figures**: Fig{N}{panel} (focal | supporting | mention)    — 없으면 `none`
- **Target writing**: <draft filename> §<section>                      — 없으면 `none`
- **Target grant**: <grant filename> §<section>                        — 없으면 `none`
- **Status**: validated | pending replication | exploratory | superseded
- **Limitation**: <한 줄. 하류 figure subtitle에서 verbatim으로 쓰임 (P16).>
- **Story ref**: STORY.md §<section>                                    — 없으면 `none`
- **Last recomputed**: {{DATE}}    (값 재계산한 날)
- **Last reviewed**: {{DATE}}      (내용 재검토한 날)
- **Revision history** *(optional)*:
  - {{DATE}}: <이전 anchor 값> → <현재 값>. 이유: <간단히>

-->

### C1
- **Tag**: 
- **Statement**: 
- **Numerical anchor**: 
- **Source script**: 
- **Data source**: 
- **Evidence type**: 
- **Target paper**: 
- **Target figures**: 
- **Target writing**: 
- **Target grant**: 
- **Status**: 
- **Limitation**: 
- **Story ref**: 
- **Last recomputed**: 
- **Last reviewed**: 

---

## Exploratory Entry Example (초기 단계용)

프로젝트 초반에는 아래처럼 최소 필드만 채워도 된다. Tag가 `supp`/`discussion`이거나 Status가 `exploratory`면 `figure-plan`은 loose mode로 돈다.

```
### C2
- **Tag**: supp
- **Statement**: Cluster 4의 TP53 변이 빈도가 다른 cluster보다 높아 보인다.
- **Numerical anchor**: 관찰 수준 (n~30, 정식 검정 미실시)
- **Source script**: notebooks/exploration/04_tp53_check.ipynb
- **Data source**: SSOT$mutation_matrix
- **Target paper**: primary
- **Target figures**: none
- **Status**: exploratory
- **Limitation**: 정식 검정 전. 빈도 관찰일 뿐.
- **Last recomputed**: 2026-04-15
- **Last reviewed**: 2026-04-15
```

---

## Cross-references
- Narrative: `STORY.md`
- Data paths: `DATA_MAP.md`
- Figure plan: `outputs/figures/FIGURE_PLAN.md`
- Manuscript: `outputs/writing/drafts/`
- Grant: `outputs/grant/AIMS.md`

## Update Protocol
1. 새 claim → 다음 ID (`C{N+1}`) 부여. **절대 재사용 금지.**
2. Claim 폐기 → 같은 엔트리에서 `Tag: deprecated`, `Status: superseded` (또는 적절한 값)로 바꾼다. 삭제 금지.
3. 대체 claim 생김 → 새 ID로 추가하고 구 claim Statement 끝에 `[superseded by C{M}]` 추가.
4. Numerical anchor 재계산 → `Last recomputed` 갱신. 이전 값이 이미 figure/draft에 인용되었다면 `Revision history`에 append.
5. 내용 재검토만 (값 불변) → `Last reviewed`만 갱신.
