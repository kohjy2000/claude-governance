# PANEL_REGISTRY.md Schema v1.0

> **Primary consumer**: `figure-implement` (writes), `figure-assemble` (reads to pick variants).
> **Location**: `<project>/outputs/figures/PANEL_REGISTRY.md`.
> **Purpose**: 각 panel의 variant 중 무엇을 선택했는지, 어느 이미지 파일이 canonical인지 기록. Reproducibility + review trail.

---

## Machine-readable enum lines

```
enum.VariantStatus : draft | selected | superseded | rejected
enum.OutputFormat  : pdf | svg | png
```

---

## Structure

```markdown
# Panel Registry
Last updated: YYYY-MM-DD

| Panel | Variant | File | Format | Status | Selected at | Notes |
|-------|---------|------|--------|--------|-------------|-------|
| Fig1A | v1-volcano | panels/Fig1A_volcano.pdf | pdf | superseded | 2026-04-10 | initial |
| Fig1A | v2-forest  | panels/Fig1A_forest.pdf  | pdf | selected   | 2026-04-15 | C1 effect size 강조 |
| Fig1B | v1-violin  | panels/Fig1B_violin.pdf  | pdf | selected   | 2026-04-15 |  |
```

---

## Column spec

| Column | Format | Owner |
|--------|--------|-------|
| Panel | `Fig{N}{letter}` (matches FIGURE_PLAN panel ID) | figure-implement |
| Variant | `v{K}-<descriptor>`, e.g. `v1-volcano`, `v2-forest` | figure-implement |
| File | project-relative path, usually `panels/<name>.<ext>` | figure-implement |
| Format | `enum.OutputFormat` | figure-implement |
| Status | `enum.VariantStatus`. One `selected` per panel at any time. | figure-implement (initial), figure-review/user (transition) |
| Selected at | ISO date — Status가 `selected`로 최초 전환된 날 | whoever transitions |
| Notes | 짧게. 왜 이 variant 선택했는지 (한 줄) | producer |

---

## Transition rules

- `draft` → `selected`: 사용자 확인 후 `figure-implement` 또는 user가 전환. `Selected at` 기록.
- `selected` → `superseded`: 새 variant가 `selected`로 올라올 때 이전 것 자동 `superseded`. `Notes`에 `→ superseded by <variant>` append.
- `draft` → `rejected`: user가 명시적으로 거부. 삭제 금지.
- 한 Panel에 `selected` 2개 이상 금지. Validation에서 FAIL.

---

## Append-only principle

- 행 삭제 금지. Status 변경만 허용.
- File 컬럼 수정 시 `Notes`에 `corrected file path` append.

---

## Validation Rules

Well-formed:
1. Header + table present.
2. Each `Panel` has exactly one row with Status=`selected` (복수 FAIL).
3. `File` path가 파일 시스템에 존재.
4. `Variant` 이름이 같은 Panel 내에서 unique.
5. `Status` 값이 enum 내.

Stale:
- `selected` variant의 File 삭제됨 → FAIL.
- 30일 이상 `draft`로 방치된 variant → WARN.

---

## Cross-references
- Panel ID: `FIGURE_PLAN.md`와 일치.
- `File`: `figure-assemble`이 읽어 multi-panel figure 조립.
- Supersede 이력은 `REVIEW_LOG.md`에도 narrative로 남길 수 있음 (중복 허용 — registry는 기계, review_log는 사람용).
