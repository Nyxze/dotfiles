#!/usr/bin/env python3

import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

INTERNAL_MODE = "2560x1440@60"
INTERNAL_SCALE = "1.6"
MAIN_WORKSPACES = range(1, 6)
MODES = {
    "Extend": "extend",
    "Mirror": "mirror",
    "External only": "external",
    "Internal only": "internal",
}


def run(*args, check=True, capture=False, input_text=None):
    return subprocess.run(
        args,
        check=check,
        input=input_text,
        text=True,
        stdout=subprocess.PIPE if capture else subprocess.DEVNULL,
        stderr=subprocess.PIPE if capture else subprocess.DEVNULL,
    )


def hyprctl(*args, check=True, capture=False):
    return run("hyprctl", *args, check=check, capture=capture)


def outputs():
    result = hyprctl("monitors", "all", "-j", capture=True)
    return json.loads(result.stdout)


def split_outputs():
    monitors = outputs()
    internal = next(
        (monitor for monitor in monitors if monitor["name"].startswith(("eDP-", "LVDS-"))),
        None,
    )
    external = next(
        (
            monitor
            for monitor in monitors
            if not monitor["name"].startswith(("eDP-", "LVDS-", "HEADLESS-"))
        ),
        None,
    )
    return internal, external


def lua_quote(value):
    return '"' + "".join(f"\\{byte:03d}" for byte in str(value).encode()) + '"'


def lua_eval(expression):
    result = hyprctl("eval", expression, capture=True)
    if result.stdout.strip() != "ok":
        raise RuntimeError(result.stdout.strip() or result.stderr.strip())


def dispatch(expression, check=True):
    result = hyprctl("dispatch", expression, capture=True, check=check)
    if check and result.stdout.strip() != "ok":
        raise RuntimeError(result.stdout.strip() or result.stderr.strip())


def set_monitor(output, mode=None, position=None, scale=None, disabled=False, mirror=None):
    fields = [f"output = {lua_quote(output)}"]
    if disabled:
        fields.append("disabled = true")
    else:
        fields.extend(
            (
                "disabled = false",
                f"mode = {lua_quote(mode)}",
                f"position = {lua_quote(position)}",
                f"scale = {lua_quote(scale)}",
                f"mirror = {lua_quote(mirror or '')}",
            )
        )
    lua_eval("hl.monitor({ " + ", ".join(fields) + " })")


def assign_main_workspaces(monitor):
    for workspace in MAIN_WORKSPACES:
        dispatch(
            f"hl.dsp.workspace.move({{ workspace = {workspace}, monitor = {lua_quote(monitor)} }})",
            check=False,
        )


def assign_laptop_workspace(monitor):
    dispatch(
        f"hl.dsp.workspace.move({{ workspace = {lua_quote('name:Laptop')}, monitor = {lua_quote(monitor)} }})",
        check=False,
    )


def enable_internal(name, position="auto-right"):
    set_monitor(name, INTERNAL_MODE, position, INTERNAL_SCALE)


def enable_external(monitor, position="auto-left"):
    mode = "preferred"
    if not monitor.get("disabled") and monitor.get("width"):
        mode = f'{monitor["width"]}x{monitor["height"]}@{monitor["refreshRate"]:g}'
    set_monitor(monitor["name"], mode, position, 1)


def apply_extend(internal, external):
    enable_external(external)
    enable_internal(internal["name"])
    assign_main_workspaces(external["name"])
    assign_laptop_workspace(internal["name"])


def apply_mirror(internal, external):
    if internal.get("mirrorOf") not in ("none", str(external["id"])):
        enable_internal(internal["name"], "0x0")
        for _ in range(40):
            current = next((item for item in outputs() if item["name"] == internal["name"]), None)
            if current and current["mirrorOf"] == "none":
                break
            time.sleep(0.05)
        else:
            raise RuntimeError(f'Could not stop mirroring {internal["name"]}')

    enable_external(external, "0x0")
    set_monitor(internal["name"], INTERNAL_MODE, "0x0", INTERNAL_SCALE, mirror=external["name"])
    assign_main_workspaces(external["name"])
    assign_laptop_workspace(external["name"])


def apply_external(internal, external):
    enable_external(external, "0x0")
    set_monitor(internal["name"], disabled=True)
    assign_main_workspaces(external["name"])
    assign_laptop_workspace(external["name"])


def apply_internal(internal):
    enable_internal(internal, "0x0")
    assign_main_workspaces(internal)
    assign_laptop_workspace(internal)


def state_path():
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "default")
    path = runtime / "hypr" / signature / "display-mode"
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def selected_mode():
    try:
        mode = state_path().read_text().strip()
    except FileNotFoundError:
        return "extend"
    return mode if mode in MODES.values() else "extend"


def remember_mode(mode):
    state_path().write_text(f"{mode}\n")


def notify(message):
    run("notify-send", "Displays", message, check=False)


def apply(mode=None, remember=False, quiet=False):
    mode = mode or selected_mode()
    internal, external = split_outputs()

    if not internal:
        if not quiet:
            notify("No internal display detected")
        return False

    if mode != "internal" and not external:
        apply_internal(internal["name"])
        if not quiet:
            notify("No external display detected; using the internal display")
        return False

    if remember:
        remember_mode(mode)

    if mode == "extend":
        apply_extend(internal, external)
    elif mode == "mirror":
        apply_mirror(internal, external)
    elif mode == "external":
        apply_external(internal, external)
    else:
        apply_internal(internal["name"])
        if external:
            set_monitor(external["name"], disabled=True)

    if not quiet:
        label = next(label for label, value in MODES.items() if value == mode)
        notify(f"Display mode: {label}")
    return True


def menu():
    result = run(
        "rofi",
        "-dmenu",
        "-i",
        "-p",
        "Display mode",
        check=False,
        capture=True,
        input_text="\n".join(MODES),
    )
    if result.returncode != 0:
        return
    choice = result.stdout.strip()
    if choice in MODES:
        apply(MODES[choice], remember=True)


def event_socket_path():
    runtime = Path(os.environ["XDG_RUNTIME_DIR"])
    signature = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
    return runtime / "hypr" / signature / ".socket2.sock"


def watch():
    path = event_socket_path()
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.connect(str(path))
        stream = client.makefile()
        for event in stream:
            if not event.startswith(("monitoradded", "monitorremoved")):
                continue
            time.sleep(0.3)
            apply(quiet=True)


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "menu"
    if command == "menu":
        menu()
        return
    if command == "watch":
        watch()
        return
    if command == "apply":
        apply(quiet=True)
        return
    if command == "status":
        print(selected_mode())
        return
    if command in MODES.values():
        apply(command, remember=True)
        return
    raise SystemExit(f"Unknown command: {command}")


if __name__ == "__main__":
    main()
