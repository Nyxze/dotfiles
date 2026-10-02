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
        (self.repo / "profiles").mkdir()
        (self.repo / "home/.config/example").mkdir(parents=True)
        self.home.mkdir()

        shutil.copy(ROOT / "deploy", self.repo / "deploy")
        shutil.copy(ROOT / "sync-files", self.repo / "sync-files")
        shutil.copy(
            ROOT / "scripts/lib/managed-home.sh",
            self.repo / "scripts/lib/managed-home.sh",
        )
        (self.repo / "profiles/personal-arch.manifest").write_text(
            "mirror example home/.config/example .config/example\n"
        )
        self.repository_file = self.repo / "home/.config/example/value"
        self.repository_file.write_text("repository\n")

    def tearDown(self):
        self.temporary.cleanup()

    def run_command(self, command, *arguments):
        environment = os.environ.copy()
        environment["HOME"] = str(self.home)
        return subprocess.run(
            [str(self.repo / command), *arguments],
            env=environment,
            capture_output=True,
            text=True,
        )

    def test_round_trip_preserves_newer_side(self):
        deployed = self.run_command("deploy", "example")
        self.assertEqual(deployed.returncode, 0, deployed.stderr)

        live_file = self.home / ".config/example/value"
        live_file.write_text("application\n")
        future = time.time() + 10
        os.utime(live_file, (future, future))

        blocked = self.run_command("deploy", "example")
        self.assertNotEqual(blocked.returncode, 0)
        self.assertEqual(self.repository_file.read_text(), "repository\n")

        captured = self.run_command("sync-files", "example")
        self.assertEqual(captured.returncode, 0, captured.stderr)
        self.assertEqual(self.repository_file.read_text(), "application\n")

    def test_unknown_component_fails(self):
        result = self.run_command("deploy", "missing")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not managed", result.stdout)


if __name__ == "__main__":
    unittest.main()
