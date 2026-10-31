# Interactive operations and UI checks

## Commands requiring input or live feedback

- Keep tmux session `Main` alive. Use a named window there for package installations, `sudo` prompts, SSH sessions, manual input, and commands the user needs to watch.
- Check for a suitable existing `Main` window before creating one. Tell the user the exact `Main:window` and bring the active tmux client there when useful.
- Run the command in that window. Let the user type secrets or other input directly in tmux; never request secrets in chat or pass them through a tool call.
- Read the result with `tmux capture-pane` and report the outcome. Keep the window available while the user needs its output.
- Short non-interactive inspections may use ordinary command tools.

## Visual tests

- Run visual UI checks in a headless compositor, virtual display, or separate inactive screen. Do not open, move, reload, or capture the user's active desktop for testing without their explicit request.
- If a test cannot run off the active desktop, validate the nonvisual behavior and explain the remaining visual check. Do not switch the user's workspace or focus to perform it.
