#!/bin/bash
# Claude Governance System — Quick Setup
# Usage: bash setup.sh [--no-hpc]
#
# This script copies skills, templates, and the portable CLAUDE.md
# to ~/.claude/. For HPC configuration, use /bootstrap-system skill
# after installation.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Governance System Setup ==="
echo "Source: $SCRIPT_DIR"
echo "Target: $CLAUDE_DIR"
echo ""

# Skills
echo "Installing skills..."
mkdir -p "$CLAUDE_DIR/skills"
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p "$CLAUDE_DIR/skills/$skill_name"
    cp "$skill_dir/SKILL.md" "$CLAUDE_DIR/skills/$skill_name/"
    echo "  + $skill_name"
done

# Templates
echo "Installing templates..."
mkdir -p "$CLAUDE_DIR/blueprints/templates"
cp "$SCRIPT_DIR"/blueprints/templates/*.md "$CLAUDE_DIR/blueprints/templates/"
echo "  + $(ls "$SCRIPT_DIR"/blueprints/templates/*.md | wc -l) templates"

# Global CLAUDE.md
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo ""
    echo "WARNING: ~/.claude/CLAUDE.md already exists."
    echo "  Existing: $(wc -l < "$CLAUDE_DIR/CLAUDE.md") lines"
    echo "  Backing up to ~/.claude/CLAUDE.md.bak"
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
fi

if [ "$1" = "--no-hpc" ]; then
    # Remove HPC section from portable template
    sed '/^## HPC 리소스/,/^## 상태 점검/{/^## 상태 점검/!d}' \
        "$SCRIPT_DIR/global/CLAUDE_portable.md" > "$CLAUDE_DIR/CLAUDE.md"
    echo "Installed CLAUDE.md (no HPC)"
else
    cp "$SCRIPT_DIR/global/CLAUDE_portable.md" "$CLAUDE_DIR/CLAUDE.md"
    echo "Installed CLAUDE.md (with HPC placeholders)"
    echo "  -> Run /bootstrap-system to fill in HPC details"
fi

echo ""
echo "=== Setup Complete ==="
echo "Skills:    $(ls "$CLAUDE_DIR"/skills/*/SKILL.md 2>/dev/null | wc -l)"
echo "Templates: $(ls "$CLAUDE_DIR"/blueprints/templates/*.md 2>/dev/null | wc -l)"
echo "CLAUDE.md: $(wc -l < "$CLAUDE_DIR/CLAUDE.md") lines"
echo ""
echo "Next steps:"
echo "  1. cd <project_dir> && claude"
echo "  2. /bootstrap-system $SCRIPT_DIR    (to configure HPC)"
echo "  3. /init-project                    (to set up a new project)"
