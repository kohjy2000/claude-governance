# {{PROJECT_NAME}} — Claim Registry
Last updated: {{DATE}}
Schema: v1.1

> **Purpose**: "이 프로젝트에서 우리가 아는 사실"의 구조화된 기록.
> **Pair with**: `STORY.md` (내러티브 — *왜* 했는가).
> **Schema**: `~/.claude/blueprints/schemas/CLAIMS.schema.md`
> **작성 시간 목표**: 한 claim 2분 이내. 항목 채우기 부담되면 exploratory tag로 먼저 올리고 나중에 보강.
> **Hierarchical IDs** (v1.1): `C{group}-{N}` 형식. Group은 논문 역할 (C0=method, C1=core, C2=mechanism, C3=extension, C4=validation).

---

## Claim Group (hierarchical, 논문 역할 기반)

각 claim은 Group으로 분류. Group이 **기본 figure 매핑**을 결정 (figure-init이 읽음).

| Group | 의미 | Default figure |
|-------|-----|-----|
| `C0` | Method validity / method introduction | Fig 1 |
| `C1` | Core observation / discovery | Fig 2 |
| `C2` | Mechanism / association / structure | Fig 3 |
| `C3` | Extension / drug / clinical translation | Fig 4 |
| `C4` | Validation / synthesis / cross-cohort | Fig 5 |

프로젝트의 figure 개수가 5개와 다르면 `/figure-init figure_count=N`로 조정.

## Tag Policy (4-tier, manual)

Group과 별개. 통계 rigor 아니라 **해당 figure 내 prominence**가 기준.

| Tag | 의미 |
|-----|-----|
| `main` | Main figure에 등장해야 하는 발견. 빠지면 논문 성립 안 함 또는 main story 약화. |
| `supp` | Supplementary/ED figure로 간다. Main text 문장에는 언급. |
| `discussion` | Discussion 문단 언급만. 단독 panel 없음. |
| `deprecated` | Paper에서 제외. 기록은 보존. |

탈락(Future work, 외부 발표)은 CLAIMS가 아니라 `STORY.md §Open Questions`로 간다.

### Group × Tag 예시

- `C1-3, Group=C1, Tag=main` → Fig 2의 focal main panel
- `C1-4, Group=C1, Tag=supp` → Fig 2의 Supplementary panel
- `C2-1, Group=C2, Tag=discussion` → Fig 3이 아니라 Discussion 본문에만 인용
- `C0-2, Group=C0, Tag=deprecated` → 한때 Fig 1 후보였지만 폐기

---

## Target Paper

- Primary: {{TARGET_PAPER}}  (예: "Genome Medicine 2026Q3")
- Secondary: {{SECONDARY_PAPER}}  (선택. 쉼표 구분 가능. 없으면 `none`)

---

## Active Claims

> Tag가 `deprecated`인 엔트리도 이 섹션에 남긴다. 별도 Deprecated 섹션 없음.
> ID는 영구. C3이 한 번 지정되면 재사용 금지, 삭제 시에도 ID는 유지.

<!-- 엔트리 템플릿 — 복사해서 붙이고 채운다

### C{group}-{N}
- **Group**: C0 | C1 | C2 | C3 | C4
- **Tag**: main | supp | discussion | deprecated
- **Statement**: <한 문장 사실 진술. 인과동사 금지 (demonstrates/proves/causes/drives/induces/leads to/shows/indicates/establishes/confirms).>
- **Numerical anchor**: <논문에 그대로 인용될 값. 예: OR=4.04, p=8.4e-8, n=253>
- **Source script**: <path:line 권장. 최소 파일 경로. 예: scripts/05_survival.R:142>
- **Data source**: SSOT$<key1>; SSOT$<key2>   (`;` 구분. DATA_MAP.md 키와 일치)
- **Evidence type** *(advisory)*: enrichment | survival | correlation | clustering | replication | natural-experiment | other
- **Target paper**: primary | secondary | none
- **Target figures**: Fig{N}{panel} (focal | supporting | mention)    — 없으면 `none` (figure-init이 Group 기준 default 제안)
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

### C0-1
- **Group**: C0
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
### C1-2
- **Group**: C1
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
1. 새 claim → 해당 Group의 다음 ID (`C{group}-{N+1}`) 부여. **절대 재사용 금지.** (예: C1 group에 C1-1, C1-2가 있으면 다음은 C1-3)
2. Claim 폐기 → 같은 엔트리에서 `Tag: deprecated`, `Status: superseded` (또는 적절한 값)로 바꾼다. 삭제 금지.
3. 대체 claim 생김 → 새 ID로 추가하고 구 claim Statement 끝에 `[superseded by C{group}-{M}]` 추가.
4. Group 이동 (예: C1-3 → C2-new) → 새 ID로 추가, 구 ID는 `Tag: deprecated` + Statement에 `[moved to C2-{M}]`.
5. Numerical anchor 재계산 → `Last recomputed` 갱신. 이전 값이 이미 figure/draft에 인용되었다면 `Revision history`에 append.
6. 내용 재검토만 (값 불변) → `Last reviewed`만 갱신.
