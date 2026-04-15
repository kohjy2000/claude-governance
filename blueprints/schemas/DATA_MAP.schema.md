# DATA_MAP.md Schema v1.0

> **Purpose**: 프로젝트 내 모든 파일 경로와 SSOT key의 중앙 레지스트리. CLAIMS, FIGURE_PLAN, figure-implement가 모두 SSOT$key 형식으로 이 파일을 참조.
> **Location**: `<project>/docs/DATA_MAP.md`.
> **Consumer**: `figure-plan` (validation), `figure-implement` (path resolution), `CLAIMS` 검증.

---

## Machine-readable enum lines

```
enum.DataType   : raw | intermediate | result | metadata | reference
enum.PathStatus : active | archived | missing
ssot.prefix     : SSOT$
ssot.pattern    : ^SSOT\$[a-z][a-z0-9_]*$
```

---

## Required Sections (in order)

1. Header (project name + Last updated)
2. `## Base Paths` — Root-level 디렉토리 약어 → 절대 경로 매핑
3. `## SSOT Registry` — 모든 파일의 key → path 매핑
4. `## Conda Environments` — 환경 이름 + 용도 (optional)
5. `## Notes` — free-form (optional)

---

## Base Paths

Root-level 약어로 base path 정의. 이후 SSOT registry는 이 약어 기반 path 사용 가능.

```markdown
| 약어 | 경로 |
|------|------|
| PROJECT | /Users/june-young/Research_Local/18_claude_governance |
| DATA    | ${PROJECT}/01_data |
| RESULTS | ${PROJECT}/02_results |
| SCRIPTS | ${PROJECT}/03_scripts |
```

Path 내 `${VAR}` 참조 허용 (이전 행에 정의된 base path). `$HOME`도 허용.

---

## SSOT Registry

각 데이터 파일 또는 디렉토리에 unique key 부여. Key는 `[a-z][a-z0-9_]*` (lowercase + underscore).

```markdown
| Key | Path | Type | Status | Notes |
|-----|------|------|--------|-------|
| mutation_matrix | ${DATA}/mutations_253samples.tsv | raw | active | 253 patients, somatic |
| cluster_assignment | ${RESULTS}/nmf_k6_clusters.tsv | result | active | NMF k=6 |
| survival_metadata | ${DATA}/clinical_with_os.tsv | metadata | active | OS + censoring |
| old_k5_clusters | ${RESULTS}/nmf_k5_clusters.tsv | result | archived | superseded by k=6 |
```

### Column spec

| Column | Format | Required |
|--------|--------|----------|
| Key | `ssot.pattern` matching | yes |
| Path | 절대 경로 또는 `${BASE}/relative` | yes |
| Type | `enum.DataType` | yes |
| Status | `enum.PathStatus` | yes |
| Notes | Free text, 짧게 | optional |

### Reference 사용

CLAIMS.md의 `Data source`, figure-implement의 `read_tsv()` 호출, figure-plan Panel spec에서 모두 `SSOT$<key>` 형식 사용.

예:
```
- **Data source**: SSOT$mutation_matrix; SSOT$cluster_assignment
```

---

## Conda Environments (optional)

```markdown
| 환경 | 용도 |
|------|------|
| nmf-env | NMF 분석 (scikit-learn, nimfa) |
| survival-env | Cox regression (lifelines) |
```

---

## Validation Rules

Well-formed DATA_MAP.md:
1. Required sections present in order.
2. Base Paths 각 행이 `| 약어 | 경로 |` 형식.
3. SSOT Registry 각 행이 5개 column.
4. 모든 Key가 `ssot.pattern` 매칭 + unique.
5. `Type`이 `enum.DataType`.
6. `Status`가 `enum.PathStatus`.
7. `Path` 내 `${VAR}` 참조는 이전 행에 정의돼야.

Stale:
- `Status: active`인 엔트리의 파일 실제 존재하지 않으면 WARN (figure-review, hook에서 감지).
- `Status: archived` 엔트리는 파일 존재 여부 체크 안 함.

---

## Append-only exception

DATA_MAP은 **append-only 아님** (CLAIMS/JOB_LOG와 다름).
- Path 정정은 허용 (typo 등).
- Key rename은 **금지** (모든 하류 참조가 깨짐). 새 key 추가 + 기존은 `archived`로.
- Row 삭제는 신중. 삭제 시 Notes에 `removed YYYY-MM-DD, reason: ...` 기록.

---

## Deliberate non-features

- Hash/checksum: 파일 무결성 검증은 별도 도구 (hook or manual). 여기서 tracking 안 함.
- Size metadata: file system이 source of truth.
- Multi-project sharing: 각 프로젝트의 DATA_MAP은 독립. 공통 reference 데이터도 각 프로젝트에 복붙 필요.
