---
name: bootstrap-system
description: Bootstrap Claude governance system on a new machine — installs skills, templates, and configures HPC settings. v1.2 adds automatic git clone (new Step 2); user no longer pre-clones.
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# /bootstrap-system — 새 시스템에 거버넌스 체계 설치

## Prerequisites (v1.2)
- Claude Code가 설치되어 있어야 함
- `git` 설치 + GitHub SSH 키 설정 완료
- ~~claude-governance repo가 clone 되어 있어야 함~~ **→ v1.2부터는 Step 2에서 자동 수행**

`$ARGUMENTS`: 사용하지 않음. 작업본 경로는 `~/claude-governance`로 고정.

---

## Step 1: 시스템 정보 수집

유저에게 아래 질문:

1. **HPC 시스템 이름** (예: TSCC, Expanse, AWS Batch, 또는 "no HPC")
2. **Account/Allocation** (예: ddp302)
3. **GPU QOS / CPU QOS** (예: hca-ddp302 / hcp-ddp302, 또는 N/A)
4. **GPU partitions** (예: rtx3090, a100)
5. **CPU partition** (예: platinum)
6. **기본 작업 디렉토리** (예: /tscc/lustre/restricted/alexandrov-ddn/users/kohjy2000)

"no HPC"인 경우 SLURM 관련 섹션 생략.

---

## Step 2: Git install (v1.2 신규)

### 2-1. 사전 체크
```bash
command -v git || { echo "git 필요. 설치 후 재시도."; exit 1; }
```

**SSH 인증 체크** (3가지 fallback):
```bash
# Try 1: SSH
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  PROTO="ssh"
  REMOTE_URL="git@github.com:kohjy2000/claude-governance.git"
# Try 2: HTTPS (public repo면 anonymous clone 가능)
elif git ls-remote https://github.com/kohjy2000/claude-governance.git HEAD >/dev/null 2>&1; then
  PROTO="https"
  REMOTE_URL="https://github.com/kohjy2000/claude-governance.git"
# Try 3: local-only (remote 없이 진행)
else
  PROTO="local"
  REMOTE_URL=""
  echo "⚠ GitHub remote 접근 불가. --local-only 모드로 진행."
  echo "  향후 SSH 키 등록 후 'git remote add origin ...'로 연결 가능."
fi
echo "Protocol: $PROTO"
```

### 2-2. 작업본 경로
```bash
REPO_DIR="$HOME/claude-governance"
```
고정. 변경 필요 시 이 skill을 수정해야 함 (의도적 — 3개 머신 경로 통일).

### 2-3. Clone 또는 pull

```bash
mkdir -p "$(dirname "$REPO_DIR")"
if [ -d "$REPO_DIR/.git" ]; then
  echo "작업본 존재."
  if [ "$PROTO" != "local" ]; then
    cd "$REPO_DIR" && git pull --ff-only origin main
  else
    echo "local 모드 — pull 생략."
  fi
elif [ "$PROTO" != "local" ]; then
  git clone "$REMOTE_URL" "$REPO_DIR"
else
  # local-only: 빈 repo 생성
  mkdir -p "$REPO_DIR"
  cd "$REPO_DIR" && git init -b main
  echo "local repo 생성. 향후 GitHub 연결 시: git remote add origin <URL> && git push -u origin main"
fi
```

Non-fast-forward 또는 clone 실패 시 STOP. 원인 출력 후 수동 해결 요구.
Local 모드로 진행하면 Phase 0 상태와 유사 — user가 나중에 remote 연결 필요.

### 2-4. 경로 검증
```bash
test -d "$REPO_DIR/skills" || { echo "Invalid repo structure"; exit 1; }
test -d "$REPO_DIR/blueprints" || { echo "Invalid repo structure"; exit 1; }
```

이 이후 Step 3-8은 `$REPO_DIR`을 source로 사용.

---

## Step 3: 디렉토리 생성

```bash
mkdir -p ~/.claude/skills
mkdir -p ~/.claude/blueprints/templates
mkdir -p ~/.claude/blueprints/schemas  # v1.2 신규
```

---

## Step 4: Skills 설치

```bash
rsync -av --delete \
  --exclude='.git' \
  --exclude='.DS_Store' \
  "$REPO_DIR/skills/" ~/.claude/skills/
```

v1.2 변경: `cp -r` 대신 `rsync --delete` — `governance-sync pull`과 동일 로직. 설치본이 작업본 mirror가 되도록 보장.

---

## Step 5: Templates & Schemas 설치

```bash
rsync -av --delete \
  --exclude='.git' \
  "$REPO_DIR/blueprints/" ~/.claude/blueprints/
```

Templates + Schemas가 한 번에 sync됨.

---

## Step 6: Global CLAUDE.md 설치

v1.2 단순화: `$REPO_DIR/global/CLAUDE_portable.md`를 `~/.claude/CLAUDE.md`로 **단순 복사**. Placeholder 치환 로직 없음.

```bash
if [ ! -f ~/.claude/CLAUDE.md ]; then
  cp "$REPO_DIR/global/CLAUDE_portable.md" ~/.claude/CLAUDE.md
  echo "Global CLAUDE.md installed from portable source."
else
  echo "~/.claude/CLAUDE.md already exists — NOT overwritten. Diff:"
  diff "$REPO_DIR/global/CLAUDE_portable.md" ~/.claude/CLAUDE.md || true
  echo "수동 확인 후 필요 시 cp로 덮어쓰기."
fi
```

**이유**: Global CLAUDE.md에는 HPC 정보가 없음 (v1.2 design). HPC 정보는 project-level CLAUDE.md에서 `/init-project` skill이 수집/기록. Global은 범용 행동 규칙만.

Step 1에서 수집한 HPC 정보는 이 Step에서 사용하지 않고 **Step 9 요약에 출력만** 하여 user에게 "/init-project 시 이 값 입력하면 됨" 안내.

> `~/.claude/CLAUDE.md`는 **`governance-sync pull`이 덮어쓰지 않음** (per-machine customize 가능 파일로 취급). 재생성 원하면 이 Step을 명시적으로 재실행.

---

## Step 7: Memory 초기화

유저에게 안내:
- "Memory는 프로젝트 디렉토리에서 Claude Code를 처음 실행하면 자동 생성됩니다."
- "MEMORY.md를 인덱스로, 주제별 .md 파일로 관리하세요."

---

## Step 8: 검증

```bash
echo "=== Working copy ==="
cd "$REPO_DIR" && git log -1 --format='%h %s (%ar)'
echo "=== Installed Skills ==="
ls ~/.claude/skills/*/SKILL.md
echo "=== Global CLAUDE.md ==="
wc -l ~/.claude/CLAUDE.md
echo "=== Templates ==="
ls ~/.claude/blueprints/templates/
echo "=== Schemas ==="
ls ~/.claude/blueprints/schemas/   # v1.2 추가
```

---

## Step 9: 요약 출력

```
--- Bootstrap Complete ---
System: <HPC_NAME>
Working copy: <REPO_DIR> (HEAD: <short hash>)
Skills installed: 9 (/bootstrap-system, /init-project, /session-resume, /submit-job, /check-status, /figure-plan, /figure-implement, /figure-review, /governance-sync)
Templates: 6 (CLAUDE, README, STORY, CLAIMS, DATA_MAP, PIPELINE, JOB_LOG)
Schemas: N (CLAIMS.schema + future)
Global CLAUDE.md: ~/.claude/CLAUDE.md (<N> lines)

Step 1에서 수집한 HPC 정보 (다음 /init-project에 사용):
- HPC: <HPC_NAME>
- Account: <HPC_ACCOUNT>
- GPU QOS: <GPU_QOS> / CPU QOS: <CPU_QOS>
- Partitions: <GPU_PARTITIONS> / <CPU_PARTITION>
- Work dir: <WORK_DIR>

다음 단계:
1. 프로젝트 디렉토리로 이동
2. /init-project 로 새 프로젝트 세팅 (위 HPC 정보 재사용)
3. /session-resume 으로 기존 프로젝트 context 로드
4. 수정은 작업본(<REPO_DIR>)에서. /governance-sync push 로 GitHub 반영.
5. 다른 머신 동기화: /governance-sync pull.
---
```

---

## Idempotency

`/bootstrap-system` 재실행 시:
- Step 1: 재질문 또는 기존 CLAUDE.md 참조해서 skip 선택지 제공
- Step 2: clone 대신 pull
- Step 3-5: rsync가 --delete로 항상 작업본 상태로 수렴
- Step 6: CLAUDE.md는 **보존**. 덮어쓰기 원하면 명시 확인 필요
- Step 8-9: 항상 실행
