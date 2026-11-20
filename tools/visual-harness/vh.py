#!/usr/bin/env python3
"""VM-only visual iteration runner for the Endfield dotfiles.

Pure-stdlib runner; Pillow is used only for image comparison.
Run inside the guest (directly or through SSH) after registering a Hyprland session.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SCENES = HERE / "scenes"
ARTIFACTS = HERE / "artifacts"
SESSION = Path(f"/run/user/{os.getuid()}/visual-harness-session.json")
SESSION_KEYS = (
    "WAYLAND_DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE", "XDG_RUNTIME_DIR",
    "DBUS_SESSION_BUS_ADDRESS", "XDG_CURRENT_DESKTOP", "XDG_SESSION_TYPE",
    "DISPLAY", "XAUTHORITY",
)


class HarnessError(Exception):
    pass


def emit(data: dict, code: int = 0) -> None:
    print(json.dumps(data, indent=2, sort_keys=True))
    raise SystemExit(code)


def run(argv: list[str], *, env: dict | None = None, timeout: int = 35,
        check: bool = True) -> subprocess.CompletedProcess:
    try:
        result = subprocess.run(
            argv, env=env, text=True, capture_output=True, timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise HarnessError(f"Command unavailable/timed out: {argv[0]}: {exc}") from exc
    if check and result.returncode != 0:
        raise HarnessError(
            f"{argv[0]} failed ({result.returncode}): {result.stderr[-1500:]}"
        )
    return result


def require_vm() -> None:
    check = run(["systemd-detect-virt", "--vm", "--quiet"], check=False)
    if check.returncode != 0:
        raise HarnessError(
            "Refusing to operate outside a detected VM. "
            "Never run captures against the daily-use desktop."
        )


def scene_data(name: str) -> dict:
    if not name.replace("-", "").replace("_", "").isalnum():
        raise HarnessError("Invalid scene name")
    path = SCENES / f"{name}.json"
    if not path.is_file():
        raise HarnessError(f"Unknown scene: {name}")
    data = json.loads(path.read_text())
    if data.get("id") != name or data.get("profile") != "arch-hyprland":
        raise HarnessError("Scene ID/profile does not match filename/guest")
    if not isinstance(data.get("argv"), list) or not data["argv"] or not all(
        isinstance(arg, str) and arg for arg in data["argv"]
    ):
        raise HarnessError("Scene argv must be a non-empty array of strings")
    if data.get("window_class") is not None and not isinstance(data["window_class"], str):
        raise HarnessError("Invalid window_class")
    mode = data.get("mode", "1600x900@60")
    if mode not in ("1600x900@60", "1920x1080@60"):
        raise HarnessError("Unsupported capture mode")
    if not 1 <= int(data.get("wait_seconds", 3)) <= 15:
        raise HarnessError("wait_seconds must be between 1 and 15")
    return data


def session_env() -> dict:
    if not SESSION.is_file() or SESSION.stat().st_uid != os.getuid():
        raise HarnessError(
            f"No registered session. Inside the VM's Hyprland terminal run: "
            f"python3 tools/visual-harness/vh.py register"
        )
    info = json.loads(SESSION.read_text())
    env = os.environ.copy()
    env.update({key: value for key, value in info.items() if key in SESSION_KEYS})
    if not env.get("HYPRLAND_INSTANCE_SIGNATURE") or not env.get("WAYLAND_DISPLAY"):
        raise HarnessError("Incomplete registered Hyprland session")
    return env


def register() -> None:
    require_vm()
    if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") or not os.environ.get("WAYLAND_DISPLAY"):
        raise HarnessError("Register must run from a terminal inside Hyprland in the VM")
    run(["hyprctl", "monitors", "-j"])
    SESSION.parent.mkdir(parents=True, exist_ok=True)
    data = {key: os.environ[key] for key in SESSION_KEYS if key in os.environ}
    fd = os.open(str(SESSION), os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as file:
        json.dump(data, file)
    SESSION.chmod(0o600)
    emit({"status": "registered", "session": str(SESSION)})


def doctor(name: str) -> dict:
    require_vm()
    data = scene_data(name)
    env = session_env()
    required = ["hyprctl", "grim", "python3", data["argv"][0]]
    missing = [command for command in required if not shutil.which(command)]
    preview = Path.home() / ".local/scripts/preview"
    if not preview.is_file() or not os.access(preview, os.X_OK):
        missing.append(str(preview))
    if missing:
        raise HarnessError(f"Missing runtime commands: {', '.join(missing)}")
    raw = run(["hyprctl", "monitors", "-j"], env=env).stdout
    try:
        monitors = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HarnessError("hyprctl returned invalid monitor JSON") from exc
    if not isinstance(monitors, list):
        raise HarnessError("No monitor list returned by Hyprland")
    fonts = {}
    if shutil.which("fc-match"):
        for family in ("HarmonyOS Sans", "NotoMono Nerd Font"):
            match = run(["fc-match", "-f", "%{family}", family], check=False).stdout.strip()
            fonts[family] = {"resolved": match, "matched": family.lower() in match.lower()}
    return {
        "status": "ready", "scene": name, "vm": True,
        "monitors": len(monitors), "preview": str(preview),
        "session": str(SESSION), "font_resolution": fonts,
    }


def git_rev() -> str | None:
    result = run(["git", "-C", str(ROOT), "rev-parse", "--short", "HEAD"], check=False)
    return result.stdout.strip() if result.returncode == 0 else None


def capture(name: str) -> dict:
    readiness = doctor(name)
    scene = scene_data(name)
    env = session_env()
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    directory = ARTIFACTS / name / f"{stamp}-{uuid.uuid4().hex[:6]}"
    directory.mkdir(parents=True, exist_ok=False)
    output = directory / "capture.png"
    preview = str(Path.home() / ".local/scripts/preview")
    cmd = [
        preview, "--out", str(output), "--wait", str(scene.get("wait_seconds", 3)),
        "--mode", scene.get("mode", "1600x900@60"),
    ]
    if scene.get("window_class"):
        cmd += ["--class", scene["window_class"]]
    fixture = str(HERE / "fixtures" / "files")
    expand = lambda argv: [arg.replace("{fixture}", fixture) for arg in argv]
    if scene.get("prepare_argv"):
        run(expand(scene["prepare_argv"]), env=env)
    cmd += ["--"] + expand(scene["argv"])
    try:
        result = run(cmd, env=env, timeout=75, check=False)
    finally:
        if scene.get("cleanup_argv"):
            run(expand(scene["cleanup_argv"]), env=env, check=False)
    (directory / "capture.log").write_text(
        "exit=" + str(result.returncode) + "\n" +
        result.stdout[-4000:] + "\n" + result.stderr[-4000:] + "\n"
    )
    if result.returncode or not output.is_file() or output.stat().st_size < 100:
        raise HarnessError(
            f"Capture failed; inspect {directory / 'capture.log'}"
        )
    metadata = {
        "status": "captured", "scene": name, "timestamp_utc": stamp,
        "capture": str(output), "directory": str(directory),
        "git_rev": git_rev(), "readiness": readiness,
        "evaluation": "pending", "functional": "not-tested",
    }
    (directory / "run.json").write_text(json.dumps(metadata, indent=2) + "\n")
    return metadata


def evaluate(name: str, actual: Path, reference: Path) -> dict:
    scene = scene_data(name)
    try:
        from PIL import Image, ImageChops, ImageDraw, ImageStat
    except ImportError as exc:
        raise HarnessError("Image evaluation requires python-pillow in the guest") from exc
    if not actual.is_file() or not reference.is_file():
        raise HarnessError("Both actual and reference PNG files must exist")
    with Image.open(actual) as actual_img, Image.open(reference) as reference_img:
        a, b = actual_img.convert("RGB"), reference_img.convert("RGB")
        if a.size != b.size:
            return {"status": "size_mismatch", "actual": list(a.size),
                    "reference": list(b.size), "passed": False}
        diff = ImageChops.difference(a, b)
        masks = scene.get("ignore_regions", [])
        for rect in masks:
            if (not isinstance(rect, list) or len(rect) != 4 or
                    not all(isinstance(x, int) and x >= 0 for x in rect) or
                    rect[0] >= rect[2] or rect[1] >= rect[3] or
                    rect[2] > a.width or rect[3] > a.height):
                raise HarnessError("Invalid ignore_regions rectangle")
            ImageDraw.Draw(diff).rectangle(tuple(rect), fill=(0, 0, 0))
        mean_abs = sum(ImageStat.Stat(diff).mean) / 3 / 255
        threshold = int(scene.get("pixel_delta_threshold", 24))
        grey = diff.convert("L")
        changed = grey.point(lambda px: 255 if px > threshold else 0)
        changed_fraction = ImageStat.Stat(changed).mean[0] / 255
        diff_path = actual.parent / "difference.png"
        diff.save(diff_path)
    limits = scene.get("visual_limits", {})
    passed = (mean_abs <= float(limits.get("mean_abs", 1.0))
              and changed_fraction <= float(limits.get("changed_fraction", 1.0)))
    result = {
        "status": "compared", "passed": passed,
        "mean_abs": round(mean_abs, 5),
        "changed_fraction": round(changed_fraction, 5),
        "reference": str(reference), "actual": str(actual),
        "difference": str(diff_path),
        "limits": limits,
        "note": "Pixel metrics are diagnostics, not a semantic or functional test.",
    }
    (actual.parent / "evaluation.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def record(directory: Path, report_path: Path) -> dict:
    """Validate the agent's visual/functional evidence before closing a run."""
    metadata_path = directory / "run.json"
    if not metadata_path.is_file() or not (directory / "capture.png").is_file():
        raise HarnessError("Expected a completed run directory with run.json and capture.png")
    metadata = json.loads(metadata_path.read_text())
    scene = scene_data(metadata["scene"])
    report = json.loads(report_path.read_text())
    if not isinstance(report.get("hypothesis"), str) or not report["hypothesis"].strip():
        raise HarnessError("A nonempty hypothesis is required")
    if not isinstance(report.get("changed_files"), list):
        raise HarnessError("changed_files must be an array (may be empty for a baseline)")
    if report.get("visual_review") not in ("pass", "fail", "not-tested"):
        raise HarnessError("visual_review must be pass, fail or not-tested")
    if report.get("reference_kind") not in ("concept", "golden", "none"):
        raise HarnessError("reference_kind must be concept, golden or none")
    if not isinstance(report.get("visual_findings"), list):
        raise HarnessError("visual_findings must be an array")
    checks = report.get("functional_checks")
    if not isinstance(checks, list) or not all(isinstance(row, dict) for row in checks):
        raise HarnessError("functional_checks must be a checklist with evidence")
    expected = set(scene.get("functional_tests", []))
    actual = [row.get("test") for row in checks]
    if len(actual) != len(set(actual)) or set(actual) != expected:
        raise HarnessError("functional_checks must cover every scene check exactly once")
    for row in checks:
        if row.get("result") not in ("pass", "fail", "not-tested"):
            raise HarnessError("Invalid functional result")
        if not isinstance(row.get("evidence"), str):
            raise HarnessError("Each functional check needs evidence (or a blocker)")
    decision = report.get("decision")
    if decision not in ("iterate", "blocked", "ready-for-review"):
        raise HarnessError("Invalid decision")
    if not isinstance(report.get("next_step"), str) or not report["next_step"].strip():
        raise HarnessError("A concrete next_step is required")
    if decision == "ready-for-review" and (
        report["visual_review"] != "pass"
        or report["reference_kind"] == "none"
        or any(row["result"] != "pass" for row in checks)
    ):
        raise HarnessError("Cannot request review with untested/failed checks or no visual reference")
    destination = directory / "review.json"
    if report_path.resolve() != destination.resolve():
        destination.write_text(json.dumps(report, indent=2) + "\n")
    return {"status": "recorded", "decision": decision, "review": str(destination),
            "capture": metadata["capture"], "scene": metadata["scene"]}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("register", help="Run once inside the guest Hyprland session")
    sub.add_parser("scenes", help="List available visual test scenes")
    for command in ("doctor", "run"):
        command_parser = sub.add_parser(command)
        command_parser.add_argument("scene")
        if command == "run":
            command_parser.add_argument("--reference", type=Path)
    compare = sub.add_parser("evaluate")
    compare.add_argument("scene")
    compare.add_argument("capture", type=Path)
    compare.add_argument("--reference", type=Path, required=True)
    review = sub.add_parser("record", help="Validate an agent iteration report")
    review.add_argument("directory", type=Path)
    review.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == "register":
            register()
        if args.command == "scenes":
            emit({"scenes": sorted(path.stem for path in SCENES.glob("*.json"))})
        if args.command == "doctor":
            emit(doctor(args.scene))
        if args.command == "run":
            result = capture(args.scene)
            if args.reference:
                assessment = evaluate(args.scene, Path(result["capture"]), args.reference)
                result["evaluation"] = assessment
            emit(result, 1 if isinstance(result["evaluation"], dict)
                 and not result["evaluation"]["passed"] else 0)
        if args.command == "evaluate":
            require_vm()
            result = evaluate(args.scene, args.capture, args.reference)
            emit(result, 0 if result["passed"] else 1)
        if args.command == "record":
            require_vm()
            emit(record(args.directory, args.report))
    except (HarnessError, ValueError, json.JSONDecodeError) as exc:
        emit({"status": "error", "message": str(exc)}, 2)


if __name__ == "__main__":
    main()
