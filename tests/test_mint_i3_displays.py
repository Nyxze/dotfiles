"""Unit tests for the Mint i3 display reconciler (no X server required)."""
import importlib.machinery
import importlib.util
import pathlib
import unittest
from unittest.mock import patch

SOURCE = pathlib.Path(__file__).resolve().parents[1] / "home/mint-xfce/.local/scripts/i3-display-workspaces"
loader = importlib.machinery.SourceFileLoader("i3_display_workspaces", str(SOURCE))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class DisplayWorkspacesTests(unittest.TestCase):
    def test_external_display_is_preferred(self):
        outputs = [{"name": "eDP-1", "active": True}, {"name": "DP-2", "active": True}]
        self.assertEqual(module.destinations(outputs), ("eDP-1", "DP-2"))

    def test_laptop_fallback(self):
        self.assertEqual(module.destinations([{"name": "eDP-1", "active": True}]),
                         ("eDP-1", "eDP-1"))

    def test_no_internal_display_does_not_move(self):
        self.assertIsNone(module.destinations([{"name": "DP-2", "active": True}]))

    @patch.object(module, "i3")
    def test_moves_only_misplaced_workspaces_and_restores_focus(self, command):
        outputs = [{"name": "eDP-1", "active": True}, {"name": "HDMI-1", "active": True}]
        workspaces = [
            {"num": 0, "name": "0", "output": "eDP-1", "focused": False},
            {"num": 1, "name": "1", "output": "eDP-1", "focused": True},
            {"num": 2, "name": "2", "output": "HDMI-1", "focused": False},
            {"num": 9, "name": "9", "output": "eDP-1", "focused": False},
        ]
        self.assertTrue(module.reconcile(outputs, workspaces))
        self.assertEqual([call.args[0] for call in command.call_args_list],
                         ['workspace "1"; move workspace to output "HDMI-1"',
                          'workspace "1"'])

    @patch.object(module, "i3")
    def test_disconnect_moves_back(self, command):
        outputs = [{"name": "eDP-1", "active": True}]
        workspaces = [{"num": 3, "name": "3", "output": "HDMI-1", "focused": True}]
        self.assertTrue(module.reconcile(outputs, workspaces))
        self.assertEqual(command.call_args.args[0], 'workspace "3"')

    @patch.object(module, "i3")
    def test_already_correct_is_noop(self, command):
        self.assertFalse(module.reconcile(
            [{"name": "eDP-1", "active": True}],
            [{"num": 0, "name": "0", "output": "eDP-1", "focused": True}],
        ))
        command.assert_not_called()


if __name__ == "__main__":
    unittest.main()
