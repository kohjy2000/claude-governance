# REVIEW_LOG.md Schema v1.0 (shared: figures + grant)

> **Primary consumer**: `figure-review` subagent (figures), future `grant-review` (grant). Phase 6 hook writes FAIL escalation entries.
> **Locations**:
> - `<project>/docs_figure/REVIEW_LOG.md` — figure review trail (Phase 6+). Legacy: `<project>/outputs/figures/REVIEW_LOG.md`.
> - `<project>/outputs/grant/REVIEW_LOG.md` — grant review trail (unchanged)
> **Purpose**: Audit trail. Paper 제출 시 reviewer에게 제공 가능한 수준. Append-only.
> **이 schema는 figures/grant 공용**. Entry type으로 domain 구분.

---

## Machine-readable enum lines

```
enum.EntryType    : subagent-review | hook-fail | note | grant-review
enum.Layer        : L0 | L1 | L2 | L3 | L4
enum.Severity     : FAIL | WARN | INFO | OK
enum.Domain       : figures | grant
```

---

## Principles

1. **Append-only**. 기존 엔트리 수정/삭제 금지. 취소/번복은 supersede pattern으로.
2. **Two writer types**:
   - Subagent: Layer 0-2 narrative review (주 writer).
   - Hook: Layer 3 FAIL escalation (Phase 6+).
3. **Separation from hook.log**: `hook.log`는 별도 파일 (기계적, dev artifact). REVIEW_LOG는 사람이 읽는 audit trail.

---

## Entry types

### Type 1: Subagent review (full scan)

```markdown
## Review YYYY-MM-DDTHH:MM:SS±TZ

<!-- figure-review-run
timestamp: ...
mode_inherited: exploratory | manuscript
hook_log_range: <from_ts>..<to_ts>
review_scope: Fig1-Fig5 | Fig3 | ...
-->

### Summary
- Mode: <...>
- Overall: PASS | L0-FAIL | L1-FAIL | L2-FAIL | L3-issues-only
- Claims audited: C1, C3, C7, ...
- Hook.log aggregate: <N FAIL escalated>, <M recurring patterns promoted>

### Findings
- [L0-FAIL] <description> (if any)
- [L1-FAIL] <description> (if any)
- [L2-FAIL] <description> (if any)
- [L3-FAIL-from-hook] <description> (escalated)
- [OK] <brief per-layer pass notes>

### Action items
- [ ] <severity-sorted, owner, target date>

### Reference
- Previous review: <timestamp>
- hook.log range covered: <from>..<to>
```

### Type 2: Hook FAIL escalation (Phase 6+)

```markdown
## Hook FAIL YYYY-MM-DDTHH:MM:SS±TZ
- Rule: <P{N}>
- Panel: <Fig{N}{X}>
- Detail: <one line description>
- Auto-logged from hook.log
- Subagent review pending
```

다음 subagent review에서 이 엔트리가 정식 Findings로 확장되거나 resolved로 supersede됨.

### Type 3: Action item resolution (supersede pattern)

기존 action item이 해결되었을 때, 새 review 엔트리의 Action items 블록에 체크 + supersede 참조:

```markdown
### Action items
- [x] ~~Fig3B CI 표시 추가~~ → resolved 2026-04-30 (supersedes action from 2026-04-15)
- [ ] <새 action>
```

기존 엔트리는 건들지 않음.

### Type 4: Claim tag change note

CLAIMS Tag 변경으로 이전 finding이 무효화되었을 때:

```markdown
### Note YYYY-MM-DDTHH:MM:SS±TZ
- [L1-FAIL from 2026-04-10 review] was based on C7 tagged as `main`.
  C7 is now `supp` (CLAIMS updated 2026-04-12). Finding superseded.
```

---

## Validation Rules

Well-formed:
1. 각 Review 엔트리가 `## Review` 헤더로 시작 (또는 `## Hook FAIL`, `## Note`).
2. Subagent Review는 machine marker 블록 + Summary + Findings + Action items + Reference 5개 모두 포함.
3. Timestamp는 ISO 8601 with timezone.
4. Action items는 `- [ ]` 또는 `- [x]` 체크박스 형식.
5. Findings의 prefix는 `[L{0-3}-FAIL]`, `[L3-FAIL-from-hook]`, `[OK]`, `[WARN]` 중 하나.

Append-only violation:
- 기존 엔트리 textual edit → validation FAIL. Supersede 엔트리로 대체.
- 엔트리 삭제 → FAIL. Revision history 손실.

---

## Cross-references
- `hook.log`: 기계적 dev log. 여기서 FAIL pattern이 REVIEW_LOG로 승격.
- `FIGURE_PLAN.md`: Findings가 특정 Panel 참조 시 PANEL ID 사용.
- `PANEL_REGISTRY.md`: variant supersede 이벤트는 registry가 primary, REVIEW_LOG는 narrative 보조.
- `docs/CLAIMS.md`: Claim tag 변경이 Findings를 supersede하는 일반 패턴.
