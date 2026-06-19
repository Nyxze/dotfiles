# OpenCode Installation

> If Claude Code is already set up, step 1 is already done.

## 1. Copy to ~/.config/coding-agents

```bash
rsync -av --delete <dotfiles>/prompts/ ~/.config/coding-agents/
```

## 2. Symlink into OpenCode

```bash
rm -rf ~/.opencode/skills && ln -sf ~/.config/coding-agents/skills ~/.opencode/skills
```

## Updating

Re-run the rsync after modifying sources — symlinks do not need to be recreated.

```bash
rsync -av --delete <dotfiles>/prompts/ ~/.config/coding-agents/
```

## Verify

```bash
ls -la ~/.opencode/skills/
```