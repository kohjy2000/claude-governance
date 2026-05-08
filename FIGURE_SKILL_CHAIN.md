# Figure Skill Chain — General Operating Principles

> Role: defines the contract between figure skills, the required document flow,
> and the enforcement points that prevent skill bypass.
> This is a general governance document, not project-specific.
> Project-specific panel contracts, aesthetic specs, and reference plans
> are created per-project by the skills themselves.

## Principle 1: Linear Dependency Chain

Skills form a strict linear chain. Each skill MUST NOT execute
unless the previous skill's output file exists.

```
/figure-style-extract
    output: STYLE_GUIDE.md, SCRIPT_CATALOG.yml
        ↓
/figure-init
    input:  STYLE_GUIDE.md, SCRIPT_CATALOG.yml, docs/
    output: FIGURE_BASELINE.md, FIGURE_PLAN_OVERVIEW.md,
            Fig*_TARGET.md, (optional) Fig*_PANEL_CONTRACTS.md
        ↓
/figure-plan
    input:  CLAIMS.md, Fig*_TARGET.md, STYLE_GUIDE.md,
            SCRIPT_CATALOG.yml, (optional) PANEL_CONTRACTS
    output: FIGURE_WORK_PLAN.md (session scope, Status: ACTIVE)
        ↓
/figure-build  (or /panel-build for single panel)
    input:  FIGURE_WORK_PLAN.md, Fig*_TARGET.md
    output: per-panel code + candidate renders
        ↓
/figure-review
    input:  candidate renders, Fig*_TARGET.md, CLAIMS.md
    output: review report, REVIEW_LOG entry
        ↓
/figure-assemble
    input:  promoted panels only
    output: assembled figure PDF/PNG
```

If a required input is missing, the skill MUST STOP and name
the prerequisite skill and missing file. It must not improvise
a substitute or proceed without it.

## Principle 2: Plans Are Files, Not Conversations

Every planning decision must be persisted as a file under `docs_figure/`.
A plan that exists only in conversation text is not a plan.

| Decision type | Must be recorded in | NOT acceptable |
|---|---|---|
| Which panels to build this session | `FIGURE_WORK_PLAN.md` | Conversation-only list |
| What plot type each panel uses | `Fig*_TARGET.md` panel plan table | Verbal description |
| Which reference script to use | `FIGURE_WORK_PLAN.md` or `PANEL_CONTRACTS` | "I'll use the ver4 style" |
| What numbers are allowed | `CLAIMS.md` numerical anchors | Hardcoded from memory |
| What is forbidden | `Fig*_TARGET.md` forbidden section | Implicit assumption |

## Principle 3: Reference Selection Happens at Plan Time

The plan phase (/figure-plan) must select and record reference
scripts and rendered examples BEFORE implementation begins.

/figure-plan output must include for each panel:
1. Panel ID and plot type
2. Claim reference (C-ID)
3. Source data path
4. **Reference script** (path + tier A/B/C)
5. **Reference render** (path to PNG/PDF if available)
6. Forbidden styles for this panel

/figure-implement then reads these references as mandatory input.
It must not independently choose a different visual grammar
without updating the plan first.

## Principle 4: One Panel At A Time, In Order

When /figure-build or /panel-build executes:
- Work on exactly one panel at a time.
- Follow the execution order in FIGURE_WORK_PLAN.md.
- Complete the full cycle (implement → render → review) before
  moving to the next panel.
- Do not touch panels outside the current session scope.

"Scope" is defined by FIGURE_WORK_PLAN.md. If the plan says
"Fig3 panels only," touching Fig1/Fig2/Fig4/Fig5 code is forbidden.

## Principle 5: Render Goes To Candidates, Not Active Output

All renders must produce output in a candidate directory first.
Active output directories (output/panels/, output/assembled/)
are populated only through an explicit promotion step that
requires human visual review.

```
render → output/candidates/{panel}/{run_id}/
validate → assertion check
review → visual review template
promote → (human approval) → output/panels/
```

Direct writes to active output are forbidden and should be
blocked by a PreToolUse hook.

## Principle 6: Skill Outputs Are Checkpointed

Each skill must leave a machine-readable marker in its output
so that downstream skills can verify the chain was followed.

| Skill | Checkpoint marker |
|---|---|
| figure-style-extract | `<!-- figure-style-extract v{X} -->` in STYLE_GUIDE.md |
| figure-init | `<!-- figure-init v{X} -->` in FIGURE_BASELINE.md |
| figure-plan | `Status: ACTIVE` in FIGURE_WORK_PLAN.md |
| figure-implement | `CONTRACT_REF:` + `CLAIM_REF:` in script header |
| figure-review | Review entry appended to REVIEW_LOG.md |
| figure-assemble | Composite file in output/composite/ |

## Principle 7: Human Gates

Two mandatory human gates exist in the chain:

1. **Plan approval**: After /figure-plan produces FIGURE_WORK_PLAN.md,
   the user must approve before implementation starts.
   Enforcement: Plan Mode (EnterPlanMode/ExitPlanMode) +
   guard-plan-lock hook.

2. **Visual review**: After /figure-review produces a review template,
   the user must visually inspect the rendered candidate and approve
   promotion. Enforcement: figure_gate.py promote requires
   VISUAL_REVIEW.json with all booleans true.

## Principle 8: Document Authority Order

When conflicts exist between documents, the higher authority wins:

```
1. docs/CLAIMS.md                    ← canonical facts and limits
2. docs_figure/targets/Fig*_TARGET.md ← figure-level scope and forbidden items
3. docs_figure/panel_contracts/       ← panel-level grammar and gate markers
4. docs_figure/FIGURE_AESTHETIC_SPEC.md ← visual system
5. docs_figure/FIGURE_WORK_PLAN.md   ← session execution plan
6. docs_figure/SCRIPT_CATALOG.yml    ← reference script index
7. Existing code and rendered output  ← implementation reference only, never claim authority
```

A script must never override a TARGET restriction even if the
reference script it was cloned from uses a different approach.

## Enforcement Summary

| Principle | Enforcement mechanism | Hook/Gate |
|---|---|---|
| P1 Linear chain | Skill checks for prerequisite files at Step 0 | Built into SKILL.md |
| P2 Files not conversations | WORK_PLAN.md required for implementation | guard-plan-lock.sh |
| P3 Reference at plan time | Plan must include reference columns | SKILL.md mandatory output |
| P4 One panel at a time | WORK_PLAN.md scope check | guard-plan-lock.sh |
| P5 Candidates only | Active output write blocked | guard-panel-output.sh |
| P6 Checkpointed outputs | Markers checked by downstream skills | Built into SKILL.md |
| P7 Human gates | Plan Mode + visual review | guard-figure-skill.sh + figure_gate.py |
| P8 Authority order | Higher doc overrides lower | Built into SKILL.md + PANEL_CONTRACTS |

## Applying To A New Project

When starting figure work on a new project:

1. Run `/figure-style-extract` with a reference paper → produces STYLE_GUIDE + CATALOG
2. Run `/figure-init` → produces BASELINE, OVERVIEW, per-figure TARGETs
3. Write CLAIMS.md (human) → canonical facts
4. Write/refine Fig*_TARGET.md (human + /figure-plan) → per-figure scope
5. Optionally write PANEL_CONTRACTS (human or /figure-plan) → per-panel gates
6. Run `/figure-plan` per session → produces WORK_PLAN with reference selections
7. Run `/figure-build` or `/panel-build` → implements within plan scope
8. Human reviews and promotes

Steps 1-5 are setup (done once or updated rarely).
Steps 6-8 are the repeating work cycle.
