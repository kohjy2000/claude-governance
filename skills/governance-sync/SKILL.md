---
name: governance-sync
description: Git pull/push wrapper for claude-governance. Syncs ~/claude-governance ↔ GitHub, then re-installs to ~/.claude/. Thin layer — conflict resolution is user's job.
allowed-tools: Bash, Read, AskUserQuestion
---

# /governance-sync — Git sync for claude-governance

`$ARGUMENTS`:
- `pull` — GitHub → local 작업본 → 설치본
- `push` — local 작업본 → GitHub
- `status` — 세 지점 (작업본/설치본/원격) 상태 체크
- 생략 시 `status`.

예: `/governance-sync pull`

## Role
3개 지점 동기화기. 각 지점:

| 지점 | 경로 | 역할 |
|-----|------|------|
| Remote | `github.com/kohjy2000/claude-governance` | Source of truth (cross-phase constraint #7) |
| Local working copy | `~/claude-governance/` | 편집 지점. 모든 수정은 여기서 시작. |
| Install target | `~/.claude/` | Claude가 실제 참조하는 위치. 작업본 sync 결과를 받음. |

**원칙**: 수정은 항상 작업본(`~/claude-governance/`)에서. 설치본(`~/.claude/`) 직접 편집 금지. 이 skill은 그 흐름을 강제.

---

## Subcommand: status

```bash
cd ~/claude-governance && git status --short && git log -1 --format='%h %s (%ar)'
cd ~/claude-governance && git fetch --quiet 2>/dev/null && git status -sb
# install target 편집 감지 (v1.2: #M5 강화)
DIFF=$(diff -rq ~/claude-governance/skills     ~/.claude/skills     --exclude='.git' 2>/dev/null; \
       diff -rq ~/claude-governance/blueprints ~/.claude/blueprints --exclude='.git' 2>/dev/null; \
       diff -rq ~/claude-governance/agents     ~/.claude/agents     --exclude='.git' 2>/dev/null)
if [ -n "$DIFF" ]; then
  echo "⚠ install target 편집 감지:"
  echo "$DIFF" | head -20
  echo ""
  echo "원칙: ~/.claude는 작업본의 mirror. 직접 편집은 다음 pull에서 유실됨."
  echo "의도한 편집이라면 작업본(~/claude-governance)에도 반영 후 commit 필요."
fi
```

출력 (3블록):
```
--- Working copy ---
<git status --short 결과>
HEAD: <short hash> <subject> (<relative time>)

--- Remote sync state ---
<git status -sb output>  (ahead/behind 표기, remote 없으면 local-only)

--- Install target diff ---
<있으면 경고, 없으면 "clean">
```

Clean/ahead/behind/dirty/install-drift 5가지 케이스를 user에게 명시.

---

## Subcommand: pull

1. **작업본 상태 체크**:
   ```bash
   cd ~/claude-governance && git status --porcelain
   ```
   출력 비어있지 않으면 STOP. "Uncommitted 변경 있음. stash하거나 commit 후 재시도."

2. **Pull**:
   ```bash
   cd ~/claude-governance && git pull --ff-only origin main
   ```
   Non-fast-forward → STOP. "Divergent history. 수동 merge 필요."
   Conflict → STOP. "Conflict 발생. 수동 해결 후 `/governance-sync status`로 확인."

3. **설치본 sync** (작업본 → `~/.claude/`):
   이 skill은 **install 로직을 재구현하지 않는다.** `bootstrap-system` skill의 install step을 참조하여 동일 로직 실행. 구체적으로:
   ```bash
   rsync -av --delete \
     --exclude='.git' \
     --exclude='.DS_Store' \
     ~/claude-governance/skills/ ~/.claude/skills/
   rsync -av --delete \
     --exclude='.git' \
     ~/claude-governance/blueprints/ ~/.claude/blueprints/
   # v1.2 Phase 6: agents sync
   if [ -d ~/claude-governance/agents ]; then
     rsync -av --delete \
       --exclude='.git' \
       --exclude='.DS_Store' \
       ~/claude-governance/agents/ ~/.claude/agents/
   fi
   # CLAUDE.md는 per-machine customize 가능하므로 덮어쓰지 않음. 
   # bootstrap-system이 관리.
   ```

4. **완료 보고**: 변경된 파일 수, 설치된 skill/template 수.

---

## Subcommand: push

1. **작업본 상태 체크**: uncommitted 있으면 AskUserQuestion으로 diff 요약 보여준 후 커밋 메시지 확정. Blind commit 금지.

2. **커밋**:
   ```bash
   cd ~/claude-governance && git add -A && git commit -m "<user-provided message>"
   ```

3. **Push**:
   ```bash
   cd ~/claude-governance && git push origin main
   ```
   Rejected (non-fast-forward) → STOP. "Remote가 앞서 있음. 먼저 `/governance-sync pull`."

4. **설치본 동기화 여부 질문**: push 후 설치본을 같은 내용으로 맞출지 user 확인. 보통 "예" — push한 사람이 현재 machine에서 일하고 있으므로 즉시 install target도 맞춰야 모순 없음.

---

## Conflict 처리 원칙

이 skill은 **자동 conflict resolution 하지 않는다.** Git이 conflict marker 박으면:
1. STOP.
2. User에게 파일 목록과 간단한 지시 출력:
   ```
   Conflict detected in:
   - skills/figure-plan/SKILL.md
   - blueprints/templates/CLAIMS_template.md
   
   수동 해결:
   1. 해당 파일을 편집기로 열어 <<<<<<< / ======= / >>>>>>> 마커 제거
   2. git add <file>
   3. git commit
   4. /governance-sync status 로 재확인
   ```
3. CLAIMS.md/STORY.md처럼 구조화된 파일의 경우 "append-only 원칙 위반 없는지 신중히 확인" 경고 추가.

자동 merge 로직은 Phase 6 이후 conflict 빈도가 실제 문제로 드러나면 재평가 (deferred).

---

## Safety rules

- `git reset --hard`, `git push --force` 절대 사용 금지.
- `--no-verify` 금지.
- `~/.claude/`에 직접 `git init` 하지 말 것. 설치본은 rsync mirror일 뿐.
- `main` 브랜치만 다룸. Feature branch 워크플로는 현재 scope 밖.

---

## Handoff
- `bootstrap-system` skill이 최초 설치 시 `git clone`으로 작업본 생성.
- 이후 3개 환경에서 이 skill로 pull/push 반복.
- Phase 6에서 CLAIMS.md multi-machine conflict 빈도 데이터 쌓이면 자동 resolution 로직 추가 여부 재평가 (PHASE_6_TODO.md 참조).
