# hook.log Schema v1.0

> **Purpose**: PostToolUse hook이 매 figure-implement 실행 후 mechanical check 결과를 append하는 로그 파일. Phase 6 이후 hook 구현체가 생성 주체.
> **Location**: `<project>/outputs/figures/hook.log`.
> **Consumer**: `figure-review` subagent가 invoke 시 직전 엔트리 이후 범위를 aggregate하여 REVIEW_LOG로 승격.
> **Separation from REVIEW_LOG.md**: hook.log는 기계적, dev artifact. REVIEW_LOG는 사람 읽는 audit trail.

---

## Machine-readable enum lines

```
enum.Severity : FAIL | WARN | INFO
enum.Rule     : P1 | P2 | P3 | P4 | P5 | P6 | P7 | P8 | P9 | P10 | P11 | P12 | P13 | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | V1 | V2 | V3 | V4 | V5 | V6 | V7 | V8 | V9
field.separator : ` | ` (pipe + single spaces)
```

---

## Line format

각 줄은 **정확히 5 fields**, `field.separator`로 구분:

```
{ISO8601 timestamp} | {severity} | {rule} | {panel} | {message}
```

예시:
```
2026-04-15T14:32:00-07:00 | FAIL | P6  | Fig3B   | hardcoded path `/data/x.csv` outside DATA_MAP
2026-04-15T14:32:00-07:00 | WARN | P13 | Fig3B   | 23 axis items (>20)
2026-04-15T14:32:01-07:00 | INFO | V2  | Fig1A   | theme_nature() applied
2026-04-15T14:35:12-07:00 | FAIL | V7  | Fig2C   | subtitle contains banned verb "demonstrates"
```

### Field spec

| Field | Format | Notes |
|-------|--------|-------|
| Timestamp | ISO 8601 with timezone offset | Minute 또는 second precision. Hook 실행 시각. |
| Severity | `enum.Severity` | FAIL → REVIEW_LOG escalation. WARN/INFO → hook.log only. |
| Rule | `enum.Rule` | 위반된 rule 한 개. Multi-rule 위반 시 한 줄에 하나씩 여러 entry. |
| Panel | `Fig{N}{X}` 또는 `common` | `common`은 00_common.R 레벨 이슈. |
| Message | Free text, **no pipe character** | 한 줄, 200자 이내 권장. |

---

## Append-only

- 기존 줄 **절대 수정 금지**.
- Log rotation 원칙: Phase 6 hook은 파일 크기 100MB 넘으면 `hook.log.YYYYMMDD`로 archive 후 새 hook.log 시작 (optional, Phase 6 구현 시 결정).

---

## Escalation to REVIEW_LOG

Hook이 Severity=FAIL entry를 hook.log에 write할 때 **동시에** REVIEW_LOG.md에 escalation 엔트리 append. REVIEW_LOG.schema의 `subagent-review` entry type이 아닌 `hook-fail` type으로:

```markdown
## Hook FAIL 2026-04-15T14:32:00-07:00
- Rule: P6
- Panel: Fig3B
- Detail: hardcoded path `/data/x.csv` outside DATA_MAP
- Auto-logged from hook.log
- Subagent review pending
```

---

## Subagent aggregate protocol

`figure-review` subagent invoke 시:

1. 직전 subagent run의 timestamp 확인 (REVIEW_LOG의 `hook_log_range.to_ts`).
2. hook.log에서 그 timestamp 이후 entries를 읽음.
3. 반복 패턴 (같은 Panel + 같은 Rule이 3회 이상) 식별.
4. Aggregate entry를 REVIEW_LOG의 현재 review entry Findings로 승격.
5. 현재 review entry 헤더에 `hook_log_range: {from_ts}..{to_ts}` 기록.

---

## Validation

Well-formed hook.log:
1. 각 줄이 정확히 5 fields (pipe로 split).
2. Timestamp는 ISO 8601.
3. Severity ∈ enum.Severity.
4. Rule ∈ enum.Rule.
5. Panel은 `Fig{N}{X}` 또는 `common`.
6. Message에 pipe 문자 없음.

Malformed 줄 발견 시 subagent가 WARN으로 REVIEW_LOG에 보고하고 해당 줄 무시.

---

## Deliberate non-features

- 구조화 형식 (JSON Lines 등) 대신 pipe-delimited 선택 — grep/awk 친화, hook 코드 경량.
- Thread/process ID 없음 — single-host single-process 가정.
- Cost tracking (CPU-hr 등) 없음. 현재 scope 밖.
