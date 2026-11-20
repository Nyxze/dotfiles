"""Dependency-light checks that do not launch a compositor or require a VM."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


HARNESS = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("vh", HARNESS / "vh.py")
vh = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vh)


class SceneTests(unittest.TestCase):
    def test_all_scenes_have_valid_contract(self):
        names = sorted(path.stem for path in (HARNESS / "scenes").glob("*.json"))
        self.assertEqual(names, ["files", "launcher", "sidebar", "terminal"])
        for name in names:
            data = vh.scene_data(name)
            self.assertTrue(data["argv"])
            self.assertTrue(data["functional_tests"])

    def test_unknown_scene_fails(self):
        with self.assertRaises(vh.HarnessError):
            vh.scene_data("../etc/passwd")

    def test_eval_identity(self):
        try:
            from PIL import Image
        except ImportError:
            self.skipTest("Pillow is only needed for image comparison")
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            actual = directory / "capture.png"
            reference = directory / "golden.png"
            Image.new("RGB", (64, 64), "#111A23").save(actual)
            Image.new("RGB", (64, 64), "#111A23").save(reference)
            # The scene masks are for 1600x900; test the unmasked helper via
            # a temporary scene contract instead of silently resizing.
            original = vh.scene_data
            try:
                vh.scene_data = lambda name: {"id": name, "ignore_regions": [],
                                            "visual_limits": {"mean_abs": 0.0,
                                                              "changed_fraction": 0.0}}
                result = vh.evaluate("launcher", actual, reference)
            finally:
                vh.scene_data = original
            self.assertTrue(result["passed"])
            self.assertEqual(result["mean_abs"], 0.0)
            self.assertTrue((directory / "difference.png").exists())

    def test_record_requires_real_functional_evidence(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            (directory / "capture.png").write_bytes(b"mock png")
            (directory / "run.json").write_text(json.dumps({
                "scene": "launcher", "capture": str(directory / "capture.png")
            }))
            scene = vh.scene_data("launcher")
            review = {
                "hypothesis": "Check geometry",
                "changed_files": [],
                "visual_review": "pass",
                "reference_kind": "concept",
                "visual_findings": [],
                "functional_checks": [
                    {"test": test, "result": "not-tested", "evidence": "Not tested"}
                    for test in scene["functional_tests"]
                ],
                "decision": "ready-for-review",
                "next_step": "Request review"
            }
            report = directory / "report.json"
            report.write_text(json.dumps(review))
            with self.assertRaises(vh.HarnessError):
                vh.record(directory, report)
            review["decision"] = "iterate"
            report.write_text(json.dumps(review))
            self.assertEqual(vh.record(directory, report)["status"], "recorded")
            self.assertTrue((directory / "review.json").is_file())

    def test_eval_size_mismatch_is_not_resized(self):
        try:
            from PIL import Image
        except ImportError:
            self.skipTest("Pillow is only needed for image comparison")
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp)
            a, b = path / "capture.png", path / "golden.png"
            Image.new("RGB", (64, 64)).save(a)
            Image.new("RGB", (96, 96)).save(b)
            self.assertEqual(vh.evaluate("launcher", a, b)["status"], "size_mismatch")


if __name__ == "__main__":
    unittest.main()
