# FIGURE_PLAN.md Schema v1.0

> **Primary consumer**: `figure-implement` (reads), `figure-review` (audits), `figure-assemble` (layout).
> **Producer**: `figure-plan`.
> **Format**: Markdown, LLM-read.
> **Location**: `<project>/outputs/figures/FIGURE_PLAN.md`.

---

## Machine-readable enum lines

```
enum.FigureRole   : main | ED | supplementary
enum.PanelRole    : focal | supporting | mention
enum.Mode         : exploratory | manuscript
```

---

## Required Sections (in order)

1. Header (title + Last updated + Mode + CLAIMS source)
2. `<!-- figure-plan-step0 -->` machine marker block (inherited from figure-plan Step 0)
3. `## Paper-Level Story Arc` (fig-by-fig one-line message)
4. `## Figure-by-Figure` containing `### Fig{N} — <ROLE>` blocks
5. Within each Fig block: `#### Panel <X>` blocks

---

## Header

```markdown
# Figure Plan
Last updated: YYYY-MM-DD
Mode: exploratory | manuscript
CLAIMS source: docs/CLAIMS.md parsed YYYY-MM-DD | narrative-draft
```

Exploratory mode는 반드시 최상단에 draft 경고 배너 추가 (figure-plan Step 0-5 참조).

---

## Figure block

```markdown
### Fig{N} — <role from enum.FigureRole>
**Message**: <one sentence>
**Claims supported**: C{a} (<tag>), C{b} (<tag>)

#### Panel A
- **Claim**: C{N}
- **Statement**: <verbatim from CLAIMS.md>
- **Numerical anchor**: <verbatim from CLAIMS.md>
- **Source script**: <from CLAIMS.md — path or path:line>
- **Data source**: SSOT$<key>; SSOT$<key>
- **Statistical method**: <derived>
- **Visual encoding**: <x/y/color/shape/size/alpha mapping>
- **Focal point (P8)**: <what the eye lands on>
- **Grey-out strategy**: <how non-focal is de-emphasized>
- **Variant 1**: <name + description>
- **Variant 2**: <name + description>
- **Message (P10)**: <testable in <5s without caption>
- **Visual-claim match (P14)**: <how the visual supports the claim>
- **Prior panel dependency (P15)**: <Panel ID or "first panel">
- **Transition sentence (P15)**: <one sentence from prior panel>
- **Limitation (P16)**: <verbatim from CLAIMS.md>
- **Subtitle template**: <scope | method | sample>
- **Role**: <from enum.PanelRole>
```

All fields required in manuscript mode. Exploratory mode allows `Claim: C?-draft` placeholder.

---

## Validation Rules

Well-formed FIGURE_PLAN.md:
1. Required sections present in order.
2. `<!-- figure-plan-step0 -->` marker block present and parseable.
3. Every `#### Panel` block contains all 16 fields.
4. `Claim` field resolves to a CLAIMS.md `C{N}` (exploratory: `C?-draft` allowed).
5. `Statement`, `Numerical anchor`, `Source script`, `Limitation` match CLAIMS.md verbatim.
6. `Role` values from `enum.PanelRole`.
7. Figure `ROLE` from `enum.FigureRole`.

Stale:
- CLAIMS source date older than 30 days → WARN (claim drift 가능).
- Any Panel의 `Source script`가 파일 시스템에 존재 안 하면 FAIL.

---

## Cross-references
- Upstream: `docs/CLAIMS.md` (source of claim content), `docs/STORY.md` (paper-level arc).
- Downstream consumers: `figure-implement` (code generation), `figure-review` (audit), `figure-assemble` (layout).

---

## Deliberate non-features
- Figure dimension specs (Nature 89mm / 183mm 등) → `figure-assemble` SKILL에 유지. FIGURE_PLAN은 role/message만.
- Color palette 상세 → `00_common.R`에 정의. 여기서는 참조만.
