---
name: bootstrap-system
description: Bootstrap Claude governance system on a new machine — installs skills, templates, and configures HPC settings
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# /bootstrap-system — 새 시스템에 거버넌스 체계 설치

## Prerequisites
- Claude Code가 설치되어 있어야 함
- claude-governance repo가 clone 되어 있어야 함

## Step 1: 시스템 정보 수집

유저에게 아래 질문:

1. **HPC 시스템 이름** (예: TSCC, Expanse, AWS Batch, 또는 "no HPC")
2. **Account/Allocation** (예: ddp302)
3. **GPU QOS / CPU QOS** (예: hca-ddp302 / hcp-ddp302, 또는 N/A)
4. **GPU partitions** (예: rtx3090, a100)
5. **CPU partition** (예: platinum)
6. **기본 작업 디렉토리** (예: /tscc/lustre/restricted/alexandrov-ddn/users/kohjy2000)

"no HPC"인 경우 SLURM 관련 섹션 생략.

## Step 2: 디렉토리 생성

```bash
mkdir -p ~/.claude/skills
mkdir -p ~/.claude/blueprints/templates
```

## Step 3: Skills 설치

claude-governance repo에서 모든 skills/ 를 ~/.claude/skills/ 로 복사:

```bash
REPO_DIR="$ARGUMENTS"  # repo 경로
cp -r $REPO_DIR/skills/* ~/.claude/skills/
```

## Step 4: Templates 설치

```bash
cp -r $REPO_DIR/blueprints/* ~/.claude/blueprints/
```

## Step 5: Global CLAUDE.md 생성

$REPO_DIR/global/CLAUDE_portable.md 를 읽어서 placeholder를 유저 답변으로 채운 뒤 ~/.claude/CLAUDE.md 로 저장.

치환 대상:
- `{{HPC_ACCOUNT}}` → 유저 답변
- `{{GPU_QOS}}` → 유저 답변
- `{{CPU_QOS}}` → 유저 답변
- `{{GPU_PARTITIONS}}` → 유저 답변
- `{{CPU_PARTITION}}` → 유저 답변

"no HPC"인 경우 "HPC 리소스" 섹션 전체를 제거하고 대신:
```
## 실행 환경
- Local execution (HPC 없음)
```

## Step 6: Memory 초기화

```bash
# auto-memory 디렉토리는 프로젝트별로 자동 생성되므로
# 여기서는 구조 안내만
```

유저에게 안내:
- "memory는 프로젝트 디렉토리에서 Claude Code를 처음 실행하면 자동 생성됩니다."
- "MEMORY.md를 인덱스로, 주제별 .md 파일로 관리하세요."

## Step 7: 검증

```bash
echo "=== Installed Skills ==="
ls ~/.claude/skills/*/SKILL.md
echo "=== Global CLAUDE.md ==="
wc -l ~/.claude/CLAUDE.md
echo "=== Templates ==="
ls ~/.claude/blueprints/templates/
```

## Step 8: 요약 출력

```
--- Bootstrap Complete ---
System: <HPC_NAME>
Skills installed: 8 (/init-project, /session-resume, /figure-plan, /figure-implement, /figure-review, /submit-job, /check-status, /bootstrap-system)
Templates: 6 (CLAUDE, README, STORY, DATA_MAP, PIPELINE, JOB_LOG)
Global CLAUDE.md: ~/.claude/CLAUDE.md (<N> lines)

다음 단계:
1. 프로젝트 디렉토리로 이동
2. /init-project 로 새 프로젝트 세팅
3. /session-resume 으로 기존 프로젝트 context 로드
---
```
