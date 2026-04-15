# CLAIMS.md Schema v1.0

> **Primary consumers**:
> 1. Phase 6 PostToolUse **hook** (grep / regex over this file to extract enums and rules)
> 2. `figure-review` **subagent** (LLM-read for semantic review)
> 3. Users (reference when editing CLAIMS_template.md)
>
> **Format**: Markdown (Option A). If hook↔schema drift becomes a real problem in
> Phase 6, promote to Option B (Markdown + trailing YAML block). See PHASE_6_TODO.md.
>
> **No Python parser is shipped.** Skills that need programmatic access use grep
> against the enum lines below. LLM-read is sufficient for everything else.

---

## Machine-readable enum lines

Hook implementations should grep these lines. **Do not reformat.**

```
enum.Tag          : main | supp | discussion | deprecated
enum.TargetPaper  : primary | secondary | none
enum.Status       : validated | pending replication | exploratory | superseded
enum.EvidenceType : enrichment | survival | correlation | clustering | replication | natural-experiment | other
banned.CausalVerbs: demonstrates | proves | causes | drives | induces | leads to | shows | indicates | establishes | confirms
stale.main_claim_days   : 90
stale.any_claim_days    : 180
```

---

## File Identity
- Path: `<project_root>/docs/CLAIMS.md`
- One file per project. Multi-paper projects use the `Target paper` field per claim.
- Format: Markdown with predictable section order.

---

## Required Sections (in this order)

1. Header (`# {{PROJECT_NAME}} — Claim Registry` + `Last updated:` line)
2. Tag Policy (4-tier table — keep aligned with template)
3. Target Paper (Primary + optional Secondary)
4. Active Claims (includes deprecated entries marked by `Tag: deprecated`)
5. Cross-references and Update Protocol

Deprecated claims remain inside Active Claims with `Tag: deprecated` and appropriate `Status`. The `C{N}` namespace is permanent; there is no separate `D{N}` namespace.

---

## Claim Entry Shape

Each claim is a level-3 heading `### C{N}` where `{N}` is an integer, followed by a bullet list of fields. Fields use `- **FieldName**: value` on a single line (except `Revision history`, which is nested bullets).

### Required fields

| Field | Type | Allowed values / format | Why required |
|-------|------|------------------------|--------------|
| Tag | enum | `main`, `supp`, `discussion`, `deprecated` | Drives figure-plan placement, figure-review Layer 1 |
| Statement | string | One sentence, factual, no causal verbs | Paper-facing text |
| Numerical anchor | string | Key=value list or `observation-level` | Directly cited |
| Source script | string | `path` or `path:line`. Points to script producing the value. **Optional when `Status: exploratory`; becomes required on promotion to non-exploratory status.** | Defends against numerical drift (failure mode #1, #2) |
| Data source | string | `SSOT$<key1>; SSOT$<key2>` (semicolon-delimited, each key must resolve in DATA_MAP.md) | Data provenance |
| Target paper | enum | `primary`, `secondary`, `none` | Multi-paper disambiguation |
| Target figures | string | `Fig{N}{panel} (focal\|supporting\|mention)` or `none` | Figure placement |
| Target writing | string | `<filename> §<section>` or `none` | Paper-section linkage |
| Target grant | string | `<filename> §<section>` or `none` | Grant-section linkage |
| Status | enum | `validated`, `pending replication`, `exploratory`, `superseded` | Loosens figure-plan gating when `exploratory` |
| Limitation | string | One line, used verbatim in figure subtitles (P16) | Prevents overclaim |
| Story ref | string | `STORY.md §<section>` or `none` | Back-link |
| Last recomputed | ISO date | `YYYY-MM-DD` | Stale-number detection |
| Last reviewed | ISO date | `YYYY-MM-DD` | Stale-interpretation detection |

### Optional fields

| Field | Type | Notes |
|-------|------|-------|
| Evidence type | enum | From `enum.EvidenceType`. Advisory. No skill currently branches on this. |
| Revision history | nested list | Append-only. Each entry: `- {{DATE}}: <old> → <new>. Reason: <...>`. Becomes more important after Phase 6 audit-trail work. |

---

## Tag semantics for downstream skills

| Tag | figure-plan (manuscript) | figure-plan (exploratory) | figure-review |
|-----|-------------------------|---------------------------|---------------|
| `main` | MUST appear focal/supporting in a main figure. FAIL if absent. | RECOMMEND main figure, do not fail. | Layer 0/1 FAIL if missing from main figures. |
| `supp` | Place in ED/supplementary. WARN if in main. | OK anywhere. | Layer 1 WARN if in main. |
| `discussion` | No panel. WARN if referenced. | Mention only. | Layer 1 FAIL if used as main panel. |
| `deprecated` | Excluded. FAIL if referenced. | Excluded. | Layer 0 FAIL if any output references. |

Mode is chosen by the user at `figure-plan` invocation.

---

## Validation Rules

A CLAIMS.md file is **well-formed** when:

1. All required sections present in order.
2. All `### C{N}` IDs are integers and unique. IDs are never reused.
3. All required fields present per claim (except `Source script` when `Status: exploratory`).
4. `Tag`, `Target paper`, `Status` values come from their enums (see `enum.*` lines above).
5. All `SSOT$<key>` references (after `;` split) resolve to entries in DATA_MAP.md.
6. `Statement` contains no verbs from `banned.CausalVerbs` (case-insensitive).
7. `Last recomputed` and `Last reviewed` are ≤ current date.

A CLAIMS.md file is **stale** when any of:

- `Last recomputed` older than `stale.main_claim_days` (90d) on a `main` or `supp` claim.
- `Last reviewed` older than `stale.any_claim_days` (180d) on any non-`deprecated` claim.
- `Source script` path does not exist on disk (checked by hook in Phase 6, by figure-review in Phase 1-5).

**Enforcement split** (v1.2):
- **Hook (Phase 6+)**: rules 4, 6, and stale-path check. Fast, mechanical, runs after every figure-implement.
- **figure-plan / figure-review subagent**: rules 1-3, 5, 7 + tag semantics + staleness warnings. Semantic, requires context.

No central linter. Each consumer re-checks the rules it cares about.

---

## Multi-paper handling

A claim belongs to at most one paper at a time. To reuse for a second paper with different tag/placement:

1. Add a new claim (new ID) with `Target paper: secondary` and the desired Tag.
2. Cross-reference in Statement: `[companion to C{M}]`.
3. Keep both entries.

Don't overload one entry with two target papers — tag and placement usually differ.

---

## Migration and versioning

- This is v1.0.
- Future versions add optional fields only. Removing a required field = v2.0 (breaking).
- No migration tooling in Phase 1. Future location: `~/.claude/blueprints/migrations/`.
- Existing pre-v1.2 projects are NOT migrated (global constraint).

---

## Deliberate non-features

- **Python parser** — not shipped. Hook uses markdown grep against `enum.*` lines. Subagent uses LLM-read.
- **`D{N}` namespace** — single `C{N}` namespace with Tag is simpler.
- **Separate narrative_importance + statistical_strength** — 4-tag collapses both.
- **Required Revision history** — optional until Phase 6 audit-trail work.
- **Verbatim Tag Policy enforcement** — drop; template drift acceptable until a sync tool exists.
- **Auto-conflict resolution across machines** — `governance-sync` stays thin; user resolves manually.
