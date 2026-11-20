# 03 — Ghostty and shell surface

## Existing ownership

- home/common/.config/ghostty/config — spacing, cell height, native chrome
- home/common/.config/ghostty/themes/endfield — palette and ANSI colors
- home/common/.config/zsh/endfield.zsh-theme — prompt
- home/common/.config/tmux/endfield.conf — tmux chrome
- home/common/.config/yazi/theme.toml — TUI file manager

## Target

Match the desktop through the background, typography, padding and restrained yellow hierarchy. **No bitmap background, grid texture, audio widget or terminal visualizer.** The design record already rejects these for readability. Keep the prompt two-line and stable for long paths and remote SSH sessions. Avoid noisy powerline segments unless tested against the original quiet prompt.

## Iterations

1. Baseline single Ghostty window with controlled fixture cwd, known locale, font and shell.
2. Inspect and align horizontal/vertical padding, line spacing and native tab chrome.
3. Verify ANSI colors on code, diff, errors, selections and search matches.
4. Test prompt on empty repo, dirty repo, SSH shell, command errors and long paths.
5. Verify tmux status and Yazi if their colors/spacing have changed.
6. Measure native terminal readability rather than forcing screenshot similarity to illustrated fake Git output.

## Functional acceptance

No clipped glyphs, readable ANSI output, correct Unicode/emoji/nerd font fallback, copy/paste, selectable text, prompt under deep paths, no regressions in tmux or SSH display. Pixel comparison is secondary to legibility.

## Later experiment

A small transparency variant may be A/B tested separately against the solid base, but it should not become the default without evidence it improves the result.
