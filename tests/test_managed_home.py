import os
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ManagedHome(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.base = Path(self.temporary.name)
        self.repo = self.base / "repo"
        self.home = self.base / "home"
        (self.repo / "scripts/lib").mkdir(parents=True)
        (self.repo / "home/common/.config/example").mkdir(parents=True)
        (self.repo / "home/arch-hyprland/.config/example").mkdir(parents=True)
        (self.repo / "home/mint-xfce/.config/example").mkdir(parents=True)
        self.home.mkdir()

        for path in ("apply-config", "capture-config", "scripts/lib/managed-home.sh"):
            destination = self.repo / path
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(ROOT / path, destination)
            destination.chmod(0o755)

        self.common_file = self.repo / "home/common/.config/example/common"
        self.common_file.write_text("common\n")
        self.profile_file = self.repo / "home/arch-hyprland/.config/example/profile"
        self.profile_file.write_text("profile\n")

    def tearDown(self):
        self.temporary.cleanup()

    def run_command(self, command, *arguments):
        environment = os.environ.copy()
        environment["HOME"] = str(self.home)
        return subprocess.run(
            [str(self.repo / command), "--profile", "arch-hyprland", *arguments],
            env=environment,
            capture_output=True,
            text=True,
        )

    def test_round_trip_preserves_newer_side(self):
        deployed = self.run_command("apply-config", "example")
        self.assertEqual(deployed.returncode, 0, deployed.stderr)

        live_file = self.home / ".config/example/common"
        live_file.write_text("application\n")
        future = time.time() + 10
        os.utime(live_file, (future, future))

        blocked = self.run_command("apply-config", "example")
        self.assertNotEqual(blocked.returncode, 0)
        self.assertEqual(self.common_file.read_text(), "common\n")

        captured = self.run_command("capture-config", "example")
        self.assertEqual(captured.returncode, 0, captured.stderr)
        self.assertEqual(self.common_file.read_text(), "application\n")

    def test_deploy_rejects_live_change_even_when_source_is_newer(self):
        self.assertEqual(self.run_command("apply-config", "example").returncode, 0)
        live_file = self.home / ".config/example/common"
        live_file.write_text("personal setting\n")
        self.common_file.write_text("new repository default\n")
        future = time.time() + 10
        os.utime(self.common_file, (future, future))

        result = self.run_command("apply-config", "example")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("last synchronized copy", result.stdout)
        self.assertEqual(live_file.read_text(), "personal setting\n")

    def test_capture_rejects_repository_change_even_when_live_is_newer(self):
        self.assertEqual(self.run_command("apply-config", "example").returncode, 0)
        self.common_file.write_text("repository change\n")
        live_file = self.home / ".config/example/common"
        live_file.write_text("live change\n")
        future = time.time() + 10
        os.utime(live_file, (future, future))

        result = self.run_command("capture-config", "example")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.common_file.read_text(), "repository change\n")

    def test_capture_updates_baseline_for_later_deploy(self):
        self.assertEqual(self.run_command("apply-config", "example").returncode, 0)
        live_file = self.home / ".config/example/common"
        live_file.write_text("captured setting\n")
        self.assertEqual(self.run_command("capture-config", "example").returncode, 0)
        self.common_file.write_text("next repository change\n")

        result = self.run_command("apply-config", "example")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(live_file.read_text(), "next repository change\n")

    def test_exact_path_capture_leaves_other_files_untouched(self):
        self.assertEqual(self.run_command("apply-config", "example").returncode, 0)
        live_common = self.home / ".config/example/common"
        live_profile = self.home / ".config/example/profile"
        live_common.write_text("capture this\n")
        live_profile.write_text("leave this live\n")

        result = self.run_command("capture-config", ".config/example/common")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.common_file.read_text(), "capture this\n")
        self.assertEqual(self.profile_file.read_text(), "profile\n")
        self.assertEqual(live_profile.read_text(), "leave this live\n")

    def test_profile_overlays_common_file(self):
        self.profile_file.unlink()
        profile_override = self.repo / "home/arch-hyprland/.config/example/common"
        profile_override.write_text("profile override\n")

        deployed = self.run_command("apply-config", "example")
        self.assertEqual(deployed.returncode, 0, deployed.stderr)
        self.assertEqual(
            (self.home / ".config/example/common").read_text(), "profile override\n"
        )

    def test_cleanup_removes_only_previously_deployed_files(self):
        deployed = self.run_command("apply-config", "example")
        self.assertEqual(deployed.returncode, 0, deployed.stderr)

        unmanaged = self.home / ".config/example/application-owned"
        unmanaged.write_text("keep\n")
        self.profile_file.unlink()

        deployed = self.run_command("apply-config", "example")
        self.assertEqual(deployed.returncode, 0, deployed.stderr)
        self.assertFalse((self.home / ".config/example/profile").exists())
        self.assertEqual(unmanaged.read_text(), "keep\n")

    def test_unknown_component_fails(self):
        result = self.run_command("apply-config", "missing")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not managed", result.stdout)

    def test_unknown_filter_blocks_valid_files_before_deploy(self):
        result = self.run_command("apply-config", "example", ".config/example/missing")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / ".config/example/common").exists())

    def test_mint_profile_deploy_is_idempotent(self):
        environment = os.environ.copy()
        environment["HOME"] = str(self.home)
        command = [str(self.repo / "apply-config"), "--profile", "mint-xfce", "example"]

        first = subprocess.run(command, env=environment, capture_output=True, text=True)
        second = subprocess.run(command, env=environment, capture_output=True, text=True)

        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)


if __name__ == "__main__":
    unittest.main()
