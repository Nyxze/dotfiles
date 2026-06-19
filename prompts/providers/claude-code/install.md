# Claude Code Installation

## 1. Copy to ~/.config/coding-agents

```bash
rsync -av --delete <dotfiles>/prompts/ ~/.config/coding-agents/
```

## 2. Symlink into Claude Code

```bash
rm -rf ~/.claude/skills && ln -sf ~/.config/coding-agents/skills ~/.claude/skills
rm -rf ~/.claude/agents && ln -sf ~/.config/coding-agents/agents ~/.claude/agents
```

## Updating

Re-run the rsync after modifying sources — symlinks do not need to be recreated.

```bash
rsync -av --delete <dotfiles>/prompts/ ~/.config/coding-agents/
```

## Verify

```bash
ls -la ~/.claude/skills/
ls -la ~/.claude/agents/
```