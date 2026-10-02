# Local GPU dictation roadmap

## Intended behavior

A Hyprland shortcut starts microphone recording and captures the active window.
The user can switch windows while speaking. The same shortcut stops recording.
Whisper transcribes locally, then the result is copied to the Wayland clipboard
and a paste shortcut is sent to the original window. Enter is never sent.

The custom clipboard manager owns history exclusion. Dictation does not pause
history collection globally or delete entries after capture.

Initial scope: Codex on Hyprland, completed utterances rather than streaming,
one active dictation at a time. Other applications get explicit paste profiles;
there is no automatic terminal classification in the first version.

## Technical direction

- Use `faster-whisper` with the multilingual `turbo` model on NVIDIA CUDA.
  Compare `large-v3` only if real French samples reveal a quality problem.
- Isolate Python and GPU dependencies from Arch's system Python. Select a Python
  version with supported CTranslate2 wheels; do not assume Python 3.14 works.
- Capture the default PipeWire microphone into bounded, temporary audio storage.
- Keep the transcription worker running as a systemd user service. Load the
  model on first use, then release it after a configurable idle timeout.
- Use Hyprland bindings for activation, without global keyboard monitoring.
- Publish text through `wl-copy` stdin and send the paste shortcut through
  `hyprctl dispatch sendshortcut`, addressed to the captured window.
- Keep audio processing, session state, Hyprland delivery, and visual feedback
  separate. Quickshell displays state; it does not own the model or recording.

The installed packages inspected during planning include Hyprland 0.56.2,
wl-clipboard 2.3.0, and Python 3.14. NVIDIA hardware is visible, but `nvidia-smi`
cannot communicate with the driver from the current execution environment.
Hyprland socket access also fails here. These are checks to repeat inside the
actual desktop session, not evidence that the desktop itself is broken.

## 1. Prove targeted paste before building transcription

Build a disposable demo with a fixed English test sentence:

1. Capture `hyprctl activewindow -j` before displaying any recording indicator.
   Retain address, PID, initial class, and a descriptive title.
2. Let the user move to another window, including another workspace.
3. Publish the test sentence as UTF-8 plain text and wait for clipboard readiness.
4. Send `CTRL,V,address:<captured address>` to the original Codex window.
5. Verify the text appears once in the original input, the current window receives
   no input, the workspace remains unchanged, and modifiers are released.

Hyprland's dispatcher supports a window selector, but background paste must be
verified on the installed version. Earlier implementations temporarily redirect
keyboard focus and restore it; application processing and clipboard selection
can still introduce timing issues. A successful dispatcher response is not an
acknowledgement that text was inserted.

Test native Wayland and XWayland separately where relevant. Include a closed
target, two Codex windows, a changed input selection, and held shortcut modifiers.
If background delivery fails, stop this milestone and choose the focus behavior
with the user before implementing a workaround.

Exit criterion: targeted paste works reliably in the actual Codex input while
the user remains in another window. Offer the demo before integrating it.

## 2. Establish local GPU transcription

- Check GPU access from a tmux terminal in the desktop session; resolve driver
  access before installing inference dependencies.
- Create a reproducible isolated runtime with pinned compatible dependencies.
  Download the model to the user's cache, outside the repository.
- Verify inference explicitly uses CUDA; report failure instead of silently
  falling back to CPU.
- Test French, English, mixed technical vocabulary, silence, and a noisy sample.
  Use transcription mode, a speech activity filter, and a configurable language.
- Measure model load time, warm inference latency, VRAM use, and idle GPU impact.
  Use those measurements to select precision and model retention timeout.

Exit criterion: acceptable transcript quality and measured latency on this GPU,
with inference working offline after dependency and model downloads.

## 3. Implement the dictation session

State flow: idle -> recording -> transcribing -> delivering -> idle.
Failures retain the latest transcript in memory for explicit retry or discard.

- A toggle captures the target and starts recording; the next toggle stops it.
- Cancellation releases the microphone and removes temporary audio.
- Serialize sessions and delivery. Reject extra starts while transcribing or
  delivering instead of maintaining a hidden queue.
- Set a maximum recording duration and handle microphone disconnection, worker
  failure, and service restart without leaving recording active.
- Revalidate the captured target against live clients before delivery. Address,
  PID, and class provide checks against a closed or replaced window; they do not
  identify a conversation or field within that window.
- If the session is locked or the target is missing, retain the result without
  injecting keys. Never redirect automatically to the current window.
- Keep audio and transcript content out of logs and persistent history. Store
  necessary temporary files privately under the runtime directory and clean up.
- Do not automatically retry an uncertain paste: it could duplicate the text.

Exit criterion: complete microphone-to-Codex dictation, cancellation, and
recoverable delivery failure, without sending Enter.

## 4. Integrate clipboard policy and delivery

History filtering belongs to the custom manager. Confirm its exclusion contract
with its implementation rather than adding a second history policy here.

Distinguish the copy producer from the destination: `wl-copy` owns the clipboard
offer, while Codex is the paste target. An application blacklist must specify
which identity it filters. If required, supply dictation origin and target
metadata through an agreed manager interface; do not infer the origin from the
window active when transcription finishes.

Use an explicit Codex paste profile (`Ctrl+V`). Additional profiles can name a
different shortcut without inspecting whether an embedded field is a terminal.

Decide separately whether to leave the transcript on the clipboard or restore
the previous offer. If restoration is wanted, preserve MIME data where supported,
wait for consumption using the chosen backend's capabilities, and avoid replacing
a newer user copy. A fixed delay alone cannot guarantee safe restoration, and
`wl-copy --paste-once` is not a universal application-consumption acknowledgement.

Exit criterion: dictations paste successfully but never enter the custom history;
normal copies made in the other window remain eligible for capture.

## 5. Integrate and deploy the desktop controls

- Add an unused Hyprland binding for toggle and another for cancellation.
  Select the actual keys with the user before editing bindings.
- Start with status notifications containing state and errors, not transcript
  content. Add a non-focusable Quickshell indicator if desired.
- Expose ready, recording, transcribing, delivering, pending, and error states.
  Keep feedback readable when the target window is on another workspace.
- Add package prerequisites to `platform/arch/packages/desktop.sh`, user service configuration, and
  a repeatable setup step for the isolated runtime and model cache.
- Keep implementation in the repository and deploy through its existing workflow.
  Validate against live copies, reload Hyprland, and inspect live bindings.
- Provide a rollback that removes activation and stops the user service.

Exit criterion: works after login, reports missing dependencies clearly, and can
be disabled without affecting clipboard history or ordinary keyboard input.

## Decisions before implementation

1. Shortcut keys for toggle and cancellation.
2. Clipboard lifetime: leave the transcript or restore the previous content.
3. Status notifications only, or a persistent recording indicator.

Dependency order: targeted paste demo -> GPU validation -> dictation service ->
clipboard integration -> desktop deployment. History policy can be developed
independently; its contract must be validated before automatic delivery ships.

## References

- [Hyprland dispatchers](https://wiki.hypr.land/0.54.0/Configuring/Dispatchers/)
  describe `sendshortcut` and window selectors. Validate installed-version behavior.
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper) documents CTranslate2,
  GPU libraries, quantization, and the speech activity filter.
- [wl-clipboard manual](https://github.com/bugaevc/wl-clipboard/blob/master/data/wl-clipboard.1)
  documents clipboard ownership, MIME types, and paste request behavior.
