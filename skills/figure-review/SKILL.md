---
name: figure-review
description: Phase 3 — Review rendered figure panels against 7 principles (P1-P7) and generate fix report
allowed-tools: Read, Bash, Glob, Grep
---

# /figure-review — Phase 3: Rendered Panels → Review

$ARGUMENTS: figure 디렉토리 경로 또는 특정 figure 번호

## Role
Scientific figure reviewer. 렌더링된 panel을 design spec과 7원칙에 대해 평가.

## Review Protocol (7 Checks)

### Check 1: Funnel Monotonicity (P1)
- 각 panel subtitle에서 scope 추출
- 단조감소 확인
- Zoom level 전환은 bridging panel이 있으면 OK

### Check 2: Evidence Before Conclusion (P2)
- 각 panel에 대해 "독자가 이미 알아야 할 것" 식별
- 선행 panel보다 뒤에 오는지 확인
- 위반 시: "Panel X를 Panel Y 뒤로 이동" 형태로 fix 제안

### Check 3: Data-Only (P3)
- 모든 visual element가 data에서 traceable한지 확인
- 화살표 다이어그램, 개념도, subjective grade 금지
- 대체안 제시:

| Non-data | Data-driven 대체 |
|----------|------------------|
| Arrow diagram | Mediation coefficient heatmap |
| Evidence grade matrix | Effect size forest plot + CI |
| Conceptual pathway | Pathway enrichment dot plot |

### Check 4: Exhaustive Before Selective (P4)
- Subset panel (top N, selected, significant only) 탐지
- 선행 universe panel 존재 확인
- Selection criterion이 정량적인지 (FDR < 0.10 등) 확인
- "key", "important" 같은 주관적 기준 플래그

### Check 5: Multi-Variant (P5)
```bash
for panel in A B C D E F G H I; do
  n=$(ls panels/Fig*_${panel}_*.png 2>/dev/null | wc -l)
  echo "Panel $panel: $n variants $([ $n -ge 2 ] && echo OK || echo FAIL)"
done
```

### Check 6: SSOT Provenance (P6)
```bash
grep -n 'read_tsv\|read_csv\|fread' Fig*.R | grep -v 'SSOT\$'
# 매치 = FAIL
```

### Check 7: Cross-Figure Consistency (P7)
- Hex color literals 검색 (00_common 외 정의 금지)
- 같은 entity의 라벨 일관성 확인 ("NonProg" vs "Non-Progressor")

## Output: Review Report

```markdown
# Figure Review Report
Date: <DATE>

## Summary
| Figure | Panels | P1 | P2 | P3 | P4 | P5 | P6 | P7 | Status |
|--------|--------|----|----|----|----|----|----|----| -------|

## Failures
### FigX Panel Y — PZ Violation
- Issue: <description>
- Fix: <specific instruction>
- Priority: HIGH / MEDIUM / LOW

## Cross-Figure Issues
<color/label inconsistencies>

## Overall: [ ] Ready / [x] Requires fixes / [ ] Major restructuring
```

## Common Failure Modes
| Symptom | Root cause | Fix |
|---------|-----------|-----|
| ggrepel N unlabeled | Overlapping labels | `max.overlaps` 증가 또는 top-K만 |
| Nested patchwork crash | patchwork in patchwork | `wrap_elements()` 사용 |
| Log scale with 0 | log10(0) = -Inf | `pmax(y, 0.5)` |
| Mixed scales shared axis | 다른 단위 | Sub-panel 분리 |
