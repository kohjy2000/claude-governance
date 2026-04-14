---
name: panel-build
description: Layer 3b sub-orchestrator. Builds and polishes a single panel within a figure (plan → implement → review with Loop V/C iteration). Invoked by /figure-build for each panel, or directly by user for fine-grained polish on one panel. Owns visual (Loop V) and content (Loop C) iteration; escalates structural issues (Loop S) to caller.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill
---

# /panel-build — Layer 3b: Per-Panel Orchestrator

$ARGUMENTS:
- `target=Fig{N}` : parent figure (e.g., `target=Fig2`)
- `panel={letter}` : panel within the figure (e.g., `panel=c`)
- optional `resume` : resume from saved panel state
- optional `force` : ignore existing panel artifact and rebuild (used by figure-build Loop F)
- optional `design_doc=<path>` : panel section path (default: derived from Fig{N}_design.md)

## Role
**Per-panel orchestrator**. Iterates on ONE panel until quality threshold met or escalation needed.
Owns Loops V (visual polish, max 3) and C (content fix, max 2). Returns panel artifact + status to caller.

Does NOT manage cross-panel concerns (that's `/figure-build`).
Does NOT auto-fix story arc / panel role issues (escalates to figure-build).

## Inputs (must exist)

```
project_root/
├── docs_figure/
│   ├── FIGURE_BASELINE.md
│   ├── STYLE_GUIDE.md
│   ├── SCRIPT_CATALOG.yml
│   └── figure_pipeline/
│       └── design_docs/Fig{N}_design.md   ← panel section parsed
├── docs/                            ← narrative + data
└── code/00_common.R                        ← may be created/updated
```

If parent `Fig{N}_design.md` missing → STOP, instruct caller to run `/figure-build` Phase F1 first.

## Outputs

```
project_root/
├── docs_figure/figure_pipeline/
│   ├── design_docs/Fig{N}_{p}_design.md   ← panel-detailed design (Phase P1)
│   ├── review_reports/
│   │   └── Fig{N}_{p}_iter{N}.md          ← per iteration
│   └── orchestrator_state/
│       └── Fig{N}_{p}_state.yml
├── code/
│   └── Fig{N}_{p}.R                       ← per-panel R code
└── output/
    ├── panels/
    │   ├── Fig{N}_{p}.pdf, Fig{N}_{p}.png  ← final variant
    │   └── variants/Fig{N}_{p}_v{X}.pdf    ← all variants explored
    └── comparison/
        └── Fig{N}_{p}_comparison.pdf       ← side-by-side variants (if ≥2)
```

## Phases (per panel)

```
P0 INIT      → load design section, init state
P1 PLAN      → /figure-plan granularity=panel → Fig{N}_{p}_design.md (detailed)
P2 IMPLEMENT → /figure-implement granularity=panel → code + render
P3 REVIEW    → /figure-review granularity=panel → review report
P4 GATE      → verdict; Loop V / Loop C / done / escalate
```

## Process

### Phase P0 — INIT
- Validate parent design doc exists (`Fig{N}_design.md`)
- Extract panel section from parent design doc
- If `Fig{N}_{p}_state.yml` exists and ≠ `resume` and ≠ `force` → ASK (resume / restart / abort)
- If `force` → delete previous artifacts, restart
- Init state:
```yaml
target: Fig{N}
panel: {letter}
session_id: {ISO}
phase: P0_INIT
iter:
  visual: 0
  content: 0
  total: 0
artifacts: {}
unresolved_issues: []
caps:
  loop_visual: 3      # from BASELINE
  loop_content: 2
  total_max: 5
status: pending
```

### Phase P1 — PANEL PLAN (panel-level detail)
Sub-call: `/figure-plan granularity=panel target=Fig{N} panel={p}`

Inputs to sub-skill:
- Parent `Fig{N}_design.md` (panel section as anchor)
- `STYLE_GUIDE.md` + `SCRIPT_CATALOG.yml` (catalog lookup for visual primitive)
- `FIGURE_BASELINE.md` (entity tier, palette)
- Relevant `docs/` excerpts (narrative claim text, expected numbers)

Output: `design_docs/Fig{N}_{p}_design.md` (detailed):
- Visual primitive selection (from CATALOG)
- Data spec: source, transformation, subset
- Aesthetic spec: x/y/color/size/shape encoding
- Focal element + grey-out strategy (P8)
- Annotation: title, subtitle (with N + method), in-plot text
- Variant ≥2 (P5)
- Expected output: panel size, format
- Catalog reference: `path: ..., lines: [X, Y]` for clone-modify

### Phase P2 — IMPLEMENT (with catalog clone-modify)
Sub-call: `/figure-implement granularity=panel target=Fig{N} panel={p}`

Sub-skill behavior:
1. Read panel design doc
2. Open referenced catalog script at specified line range
3. Clone code skeleton (preserve structure)
4. Adapt:
   - Variable names (catalog's `df_apobec` → our `mb_df`)
   - Column references (catalog's `gdel` → our `subgroup`)
   - Palette (catalog's `pal_nejm()` → BASELINE `MB_SUBTYPE_COLORS`)
   - Annotations (catalog's title → narrative claim)
5. Inject `# MESSAGE:` + `# EXPECTED:` comments at top of panel block
6. Inject `stopifnot()` assertions for narrative numbers (if applicable)
7. Render panel with `save_panel()` from `00_common.R`

Output:
- `code/Fig{N}_{p}.R`
- `output/panels/Fig{N}_{p}.pdf` + `.png`
- `output/panels/variants/Fig{N}_{p}_v{X}.pdf` (if multi-variant)

### Phase P3 — REVIEW (panel-level)
Sub-call: `/figure-review granularity=panel target=Fig{N} panel={p}`

Focuses on **panel-level checks**:
- **Layer 2 (P14-P16)**: claim-visual match, restraint, NS/limitation labeling
- **Layer 3 (P8-P13)**: focal/context, ink reduction, glance test, encoding, typography, breathing room
- **Catalog cross-ref**: visual diff vs `paper_panel` (if cataloged)
- **Multi-modal review** (if Vision LM available): inspect rendered PNG for label overlap, color contrast, axis density

Output: `review_reports/Fig{N}_{p}_iter{N}.md`

Verdict per layer + overall.

### Phase P4 — GATE
| Verdict | Action |
|---------|--------|
| **PASS all** | DONE. Update state.status = `done`. Return artifact path to caller. |
| **L3 visual FAIL** | Loop V: `iter_visual++`, re-run P2 (same design) |
| **L2 content FAIL** | Loop C: `iter_content++`, re-run P1 (partial) → P2 → P3 |
| **L0/L1 FAIL** | ESCALATE Loop S to caller (figure-build); panel-build STOPS |
| **`iter_total > 5`** | ESCALATE: panel stuck, user diagnosis needed |

#### Loop V (visual polish, max 3 iterations)
Triggered by: P8-P13 violations.
Action: Re-run `/figure-implement` with same design. Sub-skill applies fix hints from review:
- "label overlap" → adjust `hjust`/`vjust`/`position_dodge`
- "focal/context insufficient" → tighten `alpha` or `size` per `add_emphasis()`
- "axis density >20" → top-K + "N others" or facet split
- "color literal" → swap to `BASELINE` palette reference

After 3 iterations without PASS → escalate (likely design-level issue).

#### Loop C (content fix, max 2 iterations)
Triggered by: P14-P16 violations (claim mismatch, NS unlabeled, causal verb, etc.).
Action: Re-run `/figure-plan` partial — adjust ONLY the failing claim/data spec/annotation.
- Update panel design section
- Re-implement → re-render → re-review

After 2 iterations without PASS → escalate.

#### Loop S (structural) — NOT auto-fixed
Triggered by: Layer 0/1 (story arc, role).
- panel-build does not have authority to fix story arc
- ESCALATE to /figure-build (which may itself escalate to user)

## State + Resume

`Fig{N}_{p}_state.yml`:
```yaml
target: Fig2
panel: c
session_id: 20260414T1545
last_updated: 2026-04-14T15:52:11Z
phase: P3_REVIEW
status: in_progress
iter:
  visual: 1
  content: 0
  total: 1
artifacts:
  design_doc: docs_figure/figure_pipeline/design_docs/Fig2_c_design.md
  code: code/Fig2_c.R
  panel_pdf: output/panels/Fig2_c.pdf
  variants: [output/panels/variants/Fig2_c_v1.pdf]
  review_reports: [docs_figure/figure_pipeline/review_reports/Fig2_c_iter1.md]
unresolved_issues:
  - {layer: L3, principle: P13, issue: "x-axis label overlap (15 items)",
     proposed_fix: "rotate 45° + truncate to 12 chars"}
history:
  - {phase: P0, verdict: PASS, ts: 15:45:01}
  - {phase: P1, verdict: PASS, ts: 15:46:30}
  - {phase: P2, verdict: PASS, ts: 15:48:00}
  - {phase: P3, verdict: L3_FAIL, ts: 15:52:11}
caps:
  loop_visual: 3
  loop_content: 2
  total_max: 5
next_action: PHASE_P2_IMPLEMENT  # Loop V re-entry
```

## Catalog Lookup Workflow (used in P1 + P2)

`SCRIPT_CATALOG.yml` is the source of templates. Workflow:

1. **P1 (plan)**:
   - Read panel claim type (e.g., "distribution comparison")
   - Lookup `SCRIPT_CATALOG.yml` → primitive "violin_signif"
   - Pick top entry (highest `cross_ref_strength`)
   - Record in panel design as `catalog_ref: {path: ..., lines: [X, Y]}`

2. **P2 (implement)**:
   - Read `catalog_ref` from panel design
   - `Read` catalog script at specified line range
   - Clone code → adapt variables/palette/labels
   - Output: ours panel R code (not raw catalog code)

This avoids "from-scratch" reinvention. Each panel is descended from a catalog template.

## Variant Generation (P5 enforcement)

`/figure-plan` (panel) is required to specify ≥2 variants. `/figure-implement` renders all.
Variants are auto-compared via `/figure-assemble`-style comparison sheet:

```
output/comparison/Fig{N}_{p}_comparison.pdf
  ┌──────────────┬──────────────┐
  │ v1 (default) │ v2 (alt)     │
  └──────────────┴──────────────┘
```

User reviews comparison; selects preferred variant for composite (default: v1).
Selection recorded in panel state: `selected_variant: v1`.

## Loops Summary

| Loop | Trigger | Re-run scope | Max | Fail → |
|------|---------|--------------|-----|--------|
| **V (visual)** | L3 fail (P8-P13) | implement only (same design) | 3 | escalate to figure-build |
| **C (content)** | L2 fail (P14-P16) | plan partial → implement → review | 2 | escalate to figure-build |
| **S (structural)** | L0/L1 fail | — (no auto) | 0 | escalate immediately |

## Sub-skill calls

```
P1: /figure-plan      granularity=panel target=Fig{N} panel={p}
P2: /figure-implement granularity=panel target=Fig{N} panel={p}
P3: /figure-review    granularity=panel target=Fig{N} panel={p}
```

These sub-skills MUST support `granularity=panel` arg (extension to existing skills).

## Escalation Triggers

| Trigger | Phase | Action |
|---------|-------|--------|
| Parent `Fig{N}_design.md` missing | P0 | STOP, instruct caller to run `/figure-build` Phase F1 |
| `Fig{N}_{p}_state.yml` exists, no resume/force | P0 | ASK |
| Catalog lookup returns no match | P1 | Continue with `cross_ref_strength: none`, log warning |
| `iter_visual > 3` | P4 | ESCALATE Loop V exhausted |
| `iter_content > 2` | P4 | ESCALATE Loop C exhausted |
| Layer 0/1 FAIL | P4 | ESCALATE Loop S immediately |
| `iter_total > 5` | P4 | ESCALATE stuck |
| Sub-skill error (e.g., R syntax error) | P2 | ESCALATE with stderr logged |

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Loop V chasing tail (alpha 0.3 → 0.4 → 0.3 → ...) | After iter 2 with no progress, escalate to Loop C (design issue, not visual) |
| Catalog template doesn't match our data shape | P1 chooses different catalog entry; if all fail, fall back to /figure-implement from-scratch (logged as warning) |
| Variant comparison sheet too wide | If >3 variants, sample top-2 by review score |
| Panel rendered but assertions fail (data ≠ narrative) | P3 catches; Loop C re-plans claim or data spec |
| force flag wipes good intermediate state | force only when caller (figure-build Loop F) explicitly requests; else use resume |
| Sub-skill granularity arg missing | Extend `/figure-plan/implement/review` to support `granularity=panel`; backfill if not |

## CLI Examples

```bash
# Build single panel from scratch
$ claude > /panel-build target=Fig2 panel=c

# Resume after interruption
$ claude > /panel-build target=Fig2 panel=c resume

# Force rebuild (called by figure-build Loop F)
$ claude > /panel-build target=Fig2 panel=c force

# Override design doc (for experimental variant)
$ claude > /panel-build target=Fig2 panel=c design_doc=experiments/Fig2_c_alt.md
```

## Output Manifest

After successful run:
```
output/panels/
├── Fig2_c.pdf, Fig2_c.png        ← final selected variant
└── variants/
    ├── Fig2_c_v1.pdf, Fig2_c_v1.png
    └── Fig2_c_v2.pdf, Fig2_c_v2.png

output/comparison/
└── Fig2_c_comparison.pdf          ← side-by-side variants

docs_figure/figure_pipeline/
├── design_docs/Fig2_c_design.md   ← detailed panel design
├── review_reports/Fig2_c_iter1.md, Fig2_c_iter2.md, ...
└── orchestrator_state/Fig2_c_state.yml

code/Fig2_c.R                       ← panel R code (catalog-derived)
```

Returns to caller (`/figure-build`):
- `status`: done / failed / escalated
- `selected_variant`: v1 / v2 / ...
- `panel_pdf` path
- `iters_used`: {visual: N, content: N}
- `unresolved_issues`: [] (empty if PASS)

## Notes for Implementers

- panel-build is INTRA-panel only; cross-panel concerns belong to figure-build
- State file is per-panel; one panel can be resumed independently
- Loop V vs C decision: review report's failing principle determines (P8-P13 = V, P14-P16 = C)
- Catalog lookup is in P1; P2 just executes the lookup result
- Variant comparison sheet generation is part of P2 (not a separate phase)
- If `/figure-plan/implement/review` lack `granularity=panel` arg → fall back to figure-level invocation, then post-process to extract panel (degraded mode, log warning)
- Multi-modal review (Vision LM): if available, use to catch label overlap / color contrast issues that code review misses
- Concurrency safety: writes to per-panel state file only; no shared mutation

## Versioning
State file `_meta`:
```yaml
_meta:
  panel-build_version: "0.1.0"
  generated_at: 2026-04-14T15:30:00Z
  parent_design_mtime: 2026-04-14T15:01:30Z
  catalog_mtime: 2026-04-14T13:00:00Z
```

If parent design changes → recommend `force` rebuild.
