import runpy
import subprocess
import unittest
from pathlib import Path
from types import SimpleNamespace


SCRIPT = Path(__file__).resolve().parents[1] / "home/arch-hyprland/.config/hypr/scripts/displays.py"


class DisplayIPCExpressions(unittest.TestCase):
    def setUp(self):
        self.module = runpy.run_path(str(SCRIPT))
        self.calls = []

        def hyprctl(*args, **kwargs):
            self.calls.append((args, kwargs))
            return SimpleNamespace(stdout="ok\n", stderr="")

        self.module["set_monitor"].__globals__["hyprctl"] = hyprctl

    def test_lua_quote_keeps_dynamic_text_as_data(self):
        value = 'DP-1"}); error("injected") --\n\t\0☃'
        quoted = self.module["lua_quote"](value)
        result = subprocess.run(
            ["lua", "-e", 'local f = assert(load("return " .. io.read("*a"))); io.write(f())'],
            input=quoted.encode(),
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stdout, value.encode())

    def test_enabling_monitor_explicitly_clears_disabled_and_mirror(self):
        self.module["set_monitor"]("eDP-1", "preferred", "auto-right", 1)
        expression = self.calls[-1][0][1]
        self.assertIn("disabled = false", expression)
        self.assertIn('mirror = ""', expression)

    def test_mirror_target_is_quoted(self):
        self.module["set_monitor"]("eDP-1", "preferred", "0x0", 1, mirror='DP-1"')
        expression = self.calls[-1][0][1]
        self.assertIn('mirror = "\\068\\080\\045\\049\\034"', expression)

    def test_switching_mirror_target_unmirrors_first(self):
        apply_mirror = self.module["apply_mirror"]
        globals_ = apply_mirror.__globals__
        actions = []
        globals_["enable_internal"] = lambda *args: actions.append("unmirror")
        globals_["outputs"] = lambda: [{"name": "eDP-1", "mirrorOf": "none"}]
        globals_["enable_external"] = lambda *args: actions.append("enable_external")
        globals_["set_monitor"] = lambda *args, **kwargs: actions.append("mirror")
        globals_["assign_main_workspaces"] = lambda *args: None
        globals_["assign_laptop_workspace"] = lambda *args: None

        apply_mirror({"name": "eDP-1", "mirrorOf": "1"}, {"name": "DP-2", "id": 2})
        self.assertEqual(actions, ["unmirror", "enable_external", "mirror"])

    def test_external_output_uses_preferred_when_current_mode_is_not_advertised(self):
        enable_external = self.module["enable_external"]
        calls = []
        enable_external.__globals__["set_monitor"] = lambda *args: calls.append(args)
        enable_external({
            "name": "HDMI-A-1",
            "width": 1920,
            "height": 1080,
            "refreshRate": 119.98,
            "availableModes": ["1280x800@59.81Hz", "1920x1080@60.00Hz"],
        })
        self.assertEqual(calls, [("HDMI-A-1", "preferred", "auto-left", 1)])

    def test_external_output_keeps_advertised_current_mode(self):
        enable_external = self.module["enable_external"]
        calls = []
        enable_external.__globals__["set_monitor"] = lambda *args: calls.append(args)
        enable_external({
            "name": "HDMI-A-1",
            "width": 1920,
            "height": 1080,
            "refreshRate": 119.98,
            "availableModes": ["1920x1080@119.98Hz"],
        })
        self.assertEqual(calls, [("HDMI-A-1", "1920x1080@119.98", "auto-left", 1)])

    def test_external_mode_is_bound_to_display_description(self):
        enable_external = self.module["enable_external"]
        calls = []
        enable_external.__globals__["set_monitor"] = lambda *args: calls.append(args)
        enable_external({
            "name": "HDMI-A-1",
            "description": "Seiko Epson Corporation EPSON PJ 0x01010101",
            "width": 1920,
            "height": 1080,
            "refreshRate": 119.98,
            "availableModes": ["1280x800@59.81Hz", "1920x1080@60.00Hz"],
        })
        self.assertEqual(calls, [("desc:Seiko Epson Corporation EPSON PJ 0x01010101", "preferred", "auto-left", 1)])

    def test_mode_selected_before_connection_is_used_on_next_hotplug(self):
        apply = self.module["apply"]
        globals_ = apply.__globals__
        remembered = []
        globals_["split_outputs"] = lambda: ({"name": "eDP-1"}, None)
        globals_["remember_mode"] = remembered.append
        globals_["apply_internal"] = lambda *args: None

        self.assertFalse(apply("mirror", remember=True, quiet=True))
        self.assertEqual(remembered, ["mirror"])


if __name__ == "__main__":
    unittest.main()
