#!/usr/bin/python3
"""Migrate the earlier two-panel layout back to Mint's single native panel.

The normal dotfile deployment never writes Xfce settings. Fresh Mint panels
already have the layout needed by i3-workspace-panel.
"""

import datetime
import os
import pathlib
import shutil
import subprocess
import sys


MINT_BOTTOM = [1, 2, 14, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
CUSTOM_BOTTOM = [1, 2, 14, 3, 4, 5, 6, 7]
CUSTOM_TOP = [24, 8, 9, 10, 11, 12, 13]
TRAY_ONLY_TOP = [8, 9, 10, 11, 12, 13]
CLASSIC_BOTTOM = [7]
CLASSIC_TOP = [1, 2, 14, 3, 4, 5, 6] + CUSTOM_TOP


def xfconf(*arguments, check=True):
    return subprocess.run(
        ["xfconf-query", "-c", "xfce4-panel", *arguments],
        capture_output=True,
        text=True,
        check=check,
    )


def array(path):
    result = xfconf("-p", path)
    return [int(line) for line in result.stdout.splitlines() if line.isdigit()]


def set_value(path, value, kind):
    rendered = str(value).lower() if isinstance(value, bool) else str(value)
    xfconf("-p", path, "-n", "-t", kind, "-s", rendered)


def set_array(path, values):
    arguments = ["-p", path, "-a"]
    for value in values:
        arguments.extend(["-t", "int", "-s", str(value)])
    xfconf(*arguments)


def main():
    if array("/panels") == [1] and array("/panels/panel-1/plugin-ids") == MINT_BOTTOM:
        print("Le panneau Mint unique est déjà configuré.")
        return 0

    if array("/panels") != [1, 2] or (
        array("/panels/panel-1/plugin-ids"),
        array("/panels/panel-2/plugin-ids"),
    ) not in ((CUSTOM_BOTTOM, CUSTOM_TOP), (CUSTOM_BOTTOM, TRAY_ONLY_TOP),
              (CLASSIC_BOTTOM, CLASSIC_TOP)):
        print("Disposition Xfce personnalisée : aucune modification effectuée.", file=sys.stderr)
        return 1

    expected_plugins = {
        1: "whiskermenu",
        6: "tasklist",
        8: "systray",
        9: "notification-plugin",
        10: "xapp-status-plugin",
        11: "power-manager-plugin",
        12: "pulseaudio",
        13: "clock",
    }
    for number, expected in expected_plugins.items():
        if xfconf("-p", f"/plugins/plugin-{number}").stdout.strip() != expected:
            print(f"Le module {number} ne correspond pas au profil Mint ; aucune modification.", file=sys.stderr)
            return 1

    subprocess.run(["xfce4-panel", "--save"], check=True)
    panel_file = (
        pathlib.Path.home()
        / ".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
    )
    state_home = pathlib.Path(
        os.environ.get("XDG_STATE_HOME", pathlib.Path.home() / ".local/state")
    )
    backup_dir = state_home / "dotfiles/panel-backups"
    backup_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup = backup_dir / f"xfce4-panel-{timestamp}.xml"
    shutil.copy2(panel_file, backup)

    subprocess.run(["xfce4-panel", "--quit"], check=True)
    try:
        set_array("/panels/panel-1/plugin-ids", MINT_BOTTOM)
        set_array("/panels", [1])
        set_value("/panels/panel-1/position", "p=10;x=0;y=0", "string")
        set_value("/panels/panel-1/enable-struts", True, "bool")
    finally:
        subprocess.run(
            ["i3-msg", "exec --no-startup-id xfce4-panel --disable-wm-check"],
            check=True,
        )
    print(f"Panneau Mint restauré. Sauvegarde du profil précédent : {backup}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
