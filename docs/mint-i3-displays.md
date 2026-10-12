# Mint/i3 multi-monitor workspaces

The Mint Xfce/i3 profile follows the Arch/Hyprland workspace convention:

- Workspace `0` is the laptop desktop (`Laptop` in Hyprland).
- Workspaces `1`–`5` reside on the first active external output.
- When an external output disconnects, `1`–`5` move to the internal display; when reconnected, they move back.
- Windows are preserved because i3 moves the workspace, not its individual containers.

`~/.local/scripts/i3-display-workspaces` uses i3's `get_outputs` and `get_workspaces` IPC endpoints. It is started once by the Mint i3 config and reconciles output placement every second. The script does not enforce a screen resolution or physical monitor arrangement. It recognizes laptop connectors beginning with `eDP` or `LVDS`, and does not change anything if no active internal connector is reported. If multiple external displays are connected, the first active output reported by i3 is selected.

The workspace button overlay uses the focused workspace's output rectangle to position itself on that output instead of assuming the root screen begins at `(0, 0)`.

After applying the dotfiles, restart the i3 session to start the new daemon (an `i3-msg reload` alone does not rerun `exec`). Test with `xrandr --listmonitors` and `i3-msg -t get_workspaces`. To run unit tests: `python3 -m unittest discover -s tests -p 'test_mint_i3_displays.py'`.
