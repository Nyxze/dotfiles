# Visual agent harness — VM-first proof of concept

This harness makes each visual change to the Endfield dotfiles reproducible and reviewable. It runs **inside an isolated Arch/Hyprland VM**, never against the host laptop session. It consumes the existing `~/.local/scripts/preview` (headless output + cleanup) instead of replacing it. No KDE desktop is installed.

Status: **first executable iteration framework, not a verified pixel-perfect theme**. A working, compatible Hyprland VM is required for real captures. The harness has not been exercised in a graphical VM by the author of this branch.

## One-time setup (inside the VM)

1. Create an Arch VM in virt-manager/QEMU/KVM with **VirtIO GPU and 3D acceleration** (VirGL), at least 4 vCPU, 8 GiB RAM and 30 GiB disk. Select an isolated VM network. Enable SSH only if you want to drive it remotely; do not expose SSH publicly. The guest's GPU rendering may differ from physical hardware.
2. Install Arch, create an unprivileged user, and boot a working Hyprland session. **Important:** this repository uses the Lua-based Hyprland configuration and `hyprctl eval/dispatch` extensions. Stock upstream Hyprland may not execute `hyprland.lua` or the current `preview` unchanged. Match the version/build that runs your existing setup, or adapt preview **in the VM** before attempting captures. Do not copy your host's private files, credentials or personal home directory.
3. In the VM, clone this branch and install only the listed guest dependencies (interactive, explicit):
   
       git clone --branch feature/visual-agent-harness https://github.com/Nyxze/dotfiles.git ~/dotfiles
       cd ~/dotfiles
       bash tools/visual-harness/bootstrap-arch.sh

4. Deploy the **specific** files needed, not the entire workstation image:

       ./apply-config --profile arch-hyprland rofi ghostty gtk-4.0
       ./apply-config --profile arch-hyprland .local/scripts/preview .config/hypr/scripts/lua-ipc.sh

   The existing `preview` requires a running compatible compositor and accessible `hyprctl` Lua IPC. For the sidebar scene, Quickshell/endfield must also be deployed and running in the VM. If your VM uses another Hyprland build, fix the capture backend first, never on the real laptop.

5. Open a terminal **inside the VM Hyprland session** and register its non-secret display variables:

       cd ~/dotfiles
       python3 tools/visual-harness/vh.py register
       python3 tools/visual-harness/vh.py doctor launcher
       python3 tools/visual-harness/vh.py run launcher

   The session registration is a mode-0600 runtime file in /run/user/UID. It must be repeated after graphical login or VM restore. It allows SSH-invoked agents to connect to the right guest compositor without stealing the host display.

6. Result: tools/visual-harness/artifacts/launcher/<run-id>/capture.png, run.json and capture.log (ignored by Git). Each run is independent. Start with launcher; files, terminal and sidebar need additional running application setup.

To drive over SSH from the **host**, use a restricted SSH key and run commands inside the guest, e.g.:

    ssh guest-user@vm-address 'cd ~/dotfiles && python3 tools/visual-harness/vh.py run launcher'

Neither `vh.py` nor its capture subprocess invokes SSH or connects to your host.

## Compare a candidate with a reference

Treat AI-generated desktop mockups as *concept boards*, not exact goldens. Save a reference PNG in the VM (or copy it explicitly) and run:

    python3 tools/visual-harness/vh.py run launcher --reference /path/to/reference.png

A PNG comparison requires matching dimensions and the `python-pillow` package. It produces difference.png and evaluation.json with normalized mean absolute error and changed-pixel fraction. The top bar is masked in the four initial scenes because time/network changes make it unstable. The provided thresholds are **initial heuristics**, not validated acceptance criteria; use human/multimodal judgment for geometry, semantics, readability and interaction. Do not resize images silently. Do not mark a scene approved solely because the comparison passes.

Run `bash tools/visual-harness/check.sh` for non-GUI harness checks (syntax + unit tests). To close an iteration, copy review.example.json, fill in each functional check with actual evidence, and record it:

    cp tools/visual-harness/review.example.json /tmp/launcher-review.json
    # Edit /tmp/launcher-review.json after testing interactions in the VM.
    python3 tools/visual-harness/vh.py record tools/visual-harness/artifacts/launcher/<run-id> --report /tmp/launcher-review.json

The record command refuses a ready-for-review decision when any functional check is failed/untested, visual review is not passed, or no visual reference was used. It does not independently certify the report's truthfulness.

## Determinism and rollback

- Fix resolution, scale=1 (managed by preview), fonts, icon theme, locale, app versions, fixture files and screenshot wait interval before comparing pixels.
- Keep one clean VM snapshot (after installing dependencies) and a separate work snapshot. Restore them through your VM manager when changing the compositor, platform dependencies or after an unrecoverable test. **Restoring a VM snapshot destroys work since the snapshot**; commit/push changes first.
- One scene = one task. One diagnosis = one small patch. Preserve every iteration artifact, evaluate and run again. Set an explicit iteration budget (default: 8) and stop on stagnation, repeated crashes or missing capture.
- Never use `./apply-config --force` to conceal drift. Apply changed paths selectively; inspect any conflicts and rerun.
- Runs must not access real Bluetooth devices, secrets, production networks or private documents. The sidebar uses simulated or disconnected guest resources only.
- Capture scripts must leave no persistent headless outputs or newly opened windows. Inspect `hyprctl monitors all -j` when debugging preview cleanup.

## What is deliberately not automated yet

VM image creation and snapshot management depend on local libvirt storage/GPU/network arrangements. We do **not** issue destructive `virsh` commands or assume that snapshot-revert is portable. Keyboard, focus, launcher search and application opening are **manual/agent-observed functional checks** documented in each scene until an input-injection backend can be tested in the guest. The harness never asserts functional success from a screenshot.

Read [AGENTS.md](AGENTS.md) for the mandatory agent loop and [plans](plans/) for each implementation milestone.

References: https://wiki.hypr.land/getting-started/master-tutorial/ (VM 3D requirement), https://wiki.hypr.land/configuring/core/advanced-configuration/using-hyprctl/ (headless outputs), https://www.libvirt.org/manpages/virsh.html (snapshot semantics).
