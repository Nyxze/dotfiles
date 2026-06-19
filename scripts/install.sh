#!/usr/bin/env bash
# install.sh — Deploy skills and agents from the dotfiles repo to local providers.
# Destinations: ~/.claude/skills, ~/.claude/agents, ~/.opencode/skills

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$(dirname "$SCRIPT_DIR")/prompts"

echo "Creating directories..."
mkdir -p ~/.claude/skills ~/.claude/agents ~/.opencode/skills

echo "Installing Claude Code skills..."
rsync -a --delete "$PROMPTS_DIR/skills/" ~/.claude/skills/

echo "Installing Claude Code agents..."
rsync -a --delete "$PROMPTS_DIR/agents/" ~/.claude/agents/

echo "Installing OpenCode skills..."
rsync -a --delete "$PROMPTS_DIR/skills/" ~/.opencode/skills/

echo ""
echo "=== Claude Code Skills ==="
ls ~/.claude/skills/

echo ""
echo "=== Claude Code Agents ==="
ls ~/.claude/agents/

echo ""
echo "=== OpenCode Skills ==="
ls ~/.opencode/skills/

echo ""
echo "Installation complete!"
