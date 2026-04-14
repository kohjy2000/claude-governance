---
name: figure-build
description: Layer 3a orchestrator. Builds one main figure end-to-end (plan → per-panel build → cross-panel review → assemble). Manages figure-level iteration loop F; delegates panel-level work to /panel-build. Resumable via state file. Use when constructing or rebuilding a Paper figure (e.g., Fig 2).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill
---

# /figure-build — Layer 3a: Per-Figure Orchestrator

$ARGUMENTS:
- `target=Fig{N}` : which figure to build (e.g., `target=Fig2`)
- optional `resume` : resume from last saved state
- optional `force-replan` : ignore existing design doc and regenerate
- optional `panels=a,b,c` : build only specified panels (default: all in TARGET)
- optional `parallel` : run per-panel builds concurrently (default: sequential)

## Role
**Per-figure orchestrator**. Reads Layer 1 (`docs/`) + Layer 2 (`docs_figure/`) and produces:
- Per-panel artifacts via `/panel-build` (Layer 3b sub-orchestrator)
- Cross-panel review and consistency enforcement
- Final composite via `/figure-assemble`

Manages **Loop F** (figure-level iteration): cross-panel inconsistency → re-trigger affected panels.
Escalates Loop S (story arc / role failure) to user — does NOT auto-fix structural issues.

## Inputs (must exist)

```
project_root/
├── docs/                          ← Layer 1 (must exist)
│   ├── STORY.md, CLAIM_STRUCTURE_v*.md
│   ├── DATA_MAP.md
│   └── ...
├── docs_figure/                          ← Layer 2 (must exist; from /figure-init)
│   ├── FIGURE_BASELINE.md
│   ├── FIGURE_PLAN_OVERVIEW.md
│   ├── targets/Fig{N}_TARGET.md          ← required for `target=Fig{N}`
│   ├── STYLE_GUIDE.md
│   └── SCRIPT_CATALOG.yml
└── code/00_common.R                      ← optional, generated if missing
```

If any required input missing → STOP, instruct user to run prerequisite (`/project-init`, `/figure-init`).

## Outputs

```
project_root/
├── docs_figure/figure_pipeline/
│   ├── design_docs/Fig{N}_design.md      ← Phase F1 output
│   ├── review_reports/
│   │   ├── Fig{N}_figure_iter1.md        ← Phase F3 output (one per iter)
│   │   └── Fig{N}_figure_iter{N}.md
│   └── orchestrator_state/
│       └── Fig{N}_state.yml              ← session state for resume
├── code/
│   ├── 00_common.R                       ← if generated/updated
│   └── Fig{N}.R                          ← entry point sourcing per-panel files
└── output/
    ├── panels/
    │   ├── Fig{N}_a.pdf, Fig{N}_b.pdf, ...   ← from /panel-build
    │   └── Fig{N}_a.png, Fig{N}_b.png, ...
    └── composite/
        ├── Fig{N}.pdf                     ← Phase F5 output (Nature spec)
        └── Fig{N}.png
```

## Phases (sequential within figure)

```
F0 INIT     → load Layer 1 + 2, init state
F1 PLAN     → /figure-plan granularity=figure → Fig{N}_design.md
F2 BUILD    → for each panel: /panel-build target=Fig{N} panel=p
F3 REVIEW   → /figure-review granularity=figure → cross-panel + Layer 0/1
F4 GATE     → verdict; possibly Loop F or escalate
F5 ASSEMBLE → /figure-assemble → composite/Fig{N}.pdf
```

## Process

### Phase F0 — INIT
- Validate Layer 1 + 2 inputs (Glob)
- If `Fig{N}_state.yml` exists and arg ≠ `resume` → ASK user (resume / restart / abort)
- Initialize state:
```yaml
target: Fig{N}
session_id: {ISO timestamp}
phase: F0_INIT
iter:
  figure: 0
  total: 0
panels: {from TARGET.md panel list}
panel_status:  # 각 panel 별
  a: pending
  b: pending
  ...
artifacts: {}
unresolved_issues: []
history: []
caps:
  loop_figure: 2     # from BASELINE
  total_max: 5
```
- Save state file

### Phase F1 — FIGURE PLAN (figure-level)
- Sub-call: `/figure-plan granularity=figure target=Fig{N}`
- Inputs to sub-skill:
  - `docs_figure/targets/Fig{N}_TARGET.md` (claims, panels, success criteria)
  - `docs_figure/FIGURE_BASELINE.md` (entity tier, palette)
  - `docs_figure/STYLE_GUIDE.md` (style conventions)
  - `docs_figure/SCRIPT_CATALOG.yml` (catalog lookup)
  - Relevant `docs/` excerpts (CLAIM_STRUCTURE, STORY for Fig{N})
- Output: `design_docs/Fig{N}_design.md`
  - Cross-panel arc (a → b → c → ... transitions)
  - Per-panel skeleton (visual primitive, data, catalog ref, expected number)
  - Composite layout sketch (which panels in which row/col)

### Gate A — Design self-check (figure-plan internal)
- P1-P16 checklist on the design doc itself
- Pass → proceed to F2
- Fail (e.g., panels exceed cap, story arc gap) → ESCALATE to user with diagnosis

### Phase F2 — PER-PANEL BUILD (delegate to Layer 3b)
For each panel in TARGET:

```
Skill: panel-build
  args:
    target: Fig{N}
    panel: {panel_letter}
    design_doc: design_docs/Fig{N}_design.md  (panel section only)
```

**Mode**:
- Sequential (default): build panels one by one
- `parallel`: spawn parallel subagent per panel (use Agent tool with subagent_type)

**Per-panel result tracking**:
- Update `state.panel_status[p]` to `done` / `failed` / `escalated`
- Collect per-panel review reports

**Failure handling**:
- If panel-build escalates Loop S → mark figure escalated, STOP F2
- If panel-build returns `failed` after Loop V/C exhausted → mark panel failed, continue with others
- After all panels processed: count successes

If <50% panels succeeded → STOP, ESCALATE to user (likely systemic issue)

### Phase F3 — FIGURE REVIEW (cross-panel)
Sub-call: `/figure-review granularity=figure target=Fig{N}`

Focuses on **figure-level concerns** (panel-level already covered by panel-build):
- **Layer 0 (story arc)**: Fig{N-1} conclusion → Fig{N} premise → Fig{N+1} premise transitions
- **Layer 1 (figure roles)**: each panel's role distinct, no redundancy
- **Cross-panel consistency**: palette, typography, axis conventions match across panels
- **Composite feasibility**: panels fit Nature 183mm × ≤247mm budget

Output: `review_reports/Fig{N}_figure_iter{N}.md`

### Phase F4 — GATE: verdict + iteration decision

| Verdict | Action |
|---------|--------|
| **PASS all layers** | Proceed to F5 ASSEMBLE |
| **Layer 0/1 FAIL** (story arc, panel role) | STOP, ESCALATE Loop S to user (cannot auto-fix) |
| **Cross-panel FAIL** (palette/typography/composite) | Loop F: re-trigger affected panels via /panel-build with `force` flag |
| **`iter_total > 5` or `iter_figure > 2`** | STOP, ESCALATE (stuck) |

#### Loop F semantics (figure-level)
- Identify which panels have cross-panel issue (e.g., "panel b uses different NB color than panels a, c")
- Re-trigger only affected panels: `/panel-build target=Fig{N} panel=b force=true`
- After re-build, re-run Phase F3 review
- `iter_figure++`, max 2 iterations
- If 2nd iter still fails → ESCALATE to user (likely BASELINE or design ambiguity)

### Phase F5 — ASSEMBLE
Sub-call: `/figure-assemble target=Fig{N}`

- Read selected variants from each panel (from Phase F2 results)
- Build composite per `Fig{N}_design.md` layout spec
- Export at Nature dimensions (183mm full-width, ≤247mm height)
- Output: `output/composite/Fig{N}.pdf` + `.png`

If assemble fails (e.g., panel not found, layout overflow) → ESCALATE.

## State Machine + Resume

`Fig{N}_state.yml` updated after each phase:

```yaml
target: Fig2
session_id: 20260414T1500
started: 2026-04-14T15:00:00Z
last_updated: 2026-04-14T15:32:18Z
phase: F2_BUILD
iter:
  figure: 0
  total: 1
panels:
  a: {status: done,    artifact: output/panels/Fig2_a.pdf, iters: 1}
  b: {status: done,    artifact: output/panels/Fig2_b.pdf, iters: 2}
  c: {status: building, artifact: null, iters: 0}
  d: {status: pending, artifact: null, iters: 0}
  e: {status: pending, artifact: null, iters: 0}
artifacts:
  design_doc: docs_figure/figure_pipeline/design_docs/Fig2_design.md
  review_reports: []
unresolved_issues: []
history:
  - {phase: F0, verdict: PASS, ts: 15:00:01}
  - {phase: F1, verdict: PASS, ts: 15:01:30}
  - {phase: F2, verdict: IN_PROGRESS, ts: 15:08:00}
caps:
  loop_figure: 2
  total_max: 5
next_action: PHASE_F2_BUILD_panel_c
```

`/figure-build resume target=Fig2` reads state, jumps to `next_action`.

## Loops Summary

| Loop | Owned by | Trigger | Action | Max iter | Fail → |
|------|----------|---------|--------|----------|--------|
| **V (visual)** | panel-build | Layer 3 panel FAIL | re-implement panel | 3 | escalate to figure-build (rare) |
| **C (content)** | panel-build | Layer 2 panel FAIL | re-plan partial | 2 | escalate to figure-build |
| **F (figure)** | **figure-build** | cross-panel FAIL | re-trigger affected panels | 2 | ESCALATE to user |
| **S (structural)** | figure-build | Layer 0/1 FAIL | — (no auto-fix) | 0 | ESCALATE immediately |

## Sub-skill calls (ordered)

```
PHASE F1: /figure-plan granularity=figure target=Fig{N}
PHASE F2: for p in panels:
            /panel-build target=Fig{N} panel={p}
PHASE F3: /figure-review granularity=figure target=Fig{N}
PHASE F5: /figure-assemble target=Fig{N}
```

`/figure-plan/implement/review` are invoked at panel level by `/panel-build`. figure-build only invokes them at figure granularity.

## Escalation Triggers (STOP & ask user)

| Trigger | Phase | Action |
|---------|-------|--------|
| `docs/` or `docs_figure/` missing | F0 | STOP, instruct prerequisite |
| `Fig{N}_TARGET.md` missing | F0 | STOP, instruct `/figure-init` |
| `Fig{N}_state.yml` exists, no `resume` arg | F0 | ASK resume / restart / abort |
| Design doc Gate A fail (P1-P16 internal) | F1 | STOP, ESCALATE with diagnosis |
| <50% panels succeeded in F2 | F2 | STOP, likely systemic — user review needed |
| Layer 0/1 (story arc, role) FAIL | F4 | STOP, Loop S — user must approve plan changes |
| `iter_figure > 2` or `iter_total > 5` | F4 | STOP, stuck — user diagnoses |
| Composite assembly fails | F5 | STOP, layout / panel mismatch |

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Re-running with `force-replan` overwrites user-edited design doc | ASK before overwrite if design_doc mtime > generated_at |
| Parallel mode produces inconsistent palette across panels | parallel=false by default; use parallel only after BASELINE locked |
| Loop F re-triggers entire panel (slow) — user wants minimal change | Pass `loop_F_minimal=true` arg → patch instead of full rebuild |
| Composite overflow (panels too large) | F5 detects and ASKs to shrink panels or split figure |
| Panel-build escalates but user fixes manually then re-runs figure-build | Resume mode skips done panels; user can manually mark `status: done` in state.yml |
| Cross-panel review FAIL on minor palette diff | Tolerance threshold in BASELINE; only escalate if hard mismatch |

## CLI Examples

```bash
# Build Fig 2 from scratch
$ claude > /figure-build target=Fig2

# Resume after interrupted session
$ claude > /figure-build target=Fig2 resume

# Force re-plan (e.g., after TARGET.md updated)
$ claude > /figure-build target=Fig2 force-replan

# Build only panels c and d
$ claude > /figure-build target=Fig2 panels=c,d

# Parallel panel build (after design locked)
$ claude > /figure-build target=Fig2 parallel
```

## Output Manifest

After successful run:
```
output/
├── panels/
│   ├── Fig2_a.pdf, Fig2_a.png
│   ├── Fig2_b.pdf, Fig2_b.png
│   └── ...
└── composite/
    ├── Fig2.pdf       ← Nature 183mm × Nmm composite
    └── Fig2.png
docs_figure/figure_pipeline/
├── design_docs/Fig2_design.md
├── review_reports/Fig2_figure_iter*.md
└── orchestrator_state/Fig2_state.yml
code/
├── 00_common.R
└── Fig2.R
```

## Notes for Implementers

- Use `Glob` for file discovery, `Read` for spec parsing
- `/panel-build` is mandatory dependency; if missing, fall back to direct `/figure-implement granularity=panel` per panel (degraded mode, no Loop V/C)
- State file is the source of truth; never trust in-memory state alone (resume safety)
- Sub-skill arg passing: use `Skill` tool with explicit args (do not rely on implicit context)
- Logging: each phase appends `history[]` entry with phase + verdict + timestamp
- Concurrency (parallel mode): use `Agent` tool with `subagent_type: general-purpose`, one per panel
- Idempotency: re-running with same inputs + state should be safe (resume picks up where left off)
- Multi-figure batch (e.g., `target=all` or `target=Fig1,Fig2,Fig3`): future enhancement, not v0.1

## Versioning
State file emits `_meta`:
```yaml
_meta:
  figure-build_version: "0.1.0"
  generated_at: 2026-04-14T15:30:00Z
  inputs_mtime:
    target: 2026-04-14T14:00:00Z
    baseline: 2026-04-14T13:00:00Z
```

Used by `resume` to detect input changes and warn user.
