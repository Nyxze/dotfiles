---
name: android-record
description: >
  Record a replayable action sequence on the connected Android device (Lootopia).
  Use this skill when the user explicitly asks to "record", "create a test session",
  "enregistre ce flow", "crée une session de test", or wants a script they can replay
  later without an AI agent. This skill produces a .ndjson file that can be run with
  `bun run scripts/replay.ts <file>` — no LLM needed for replay.
  Do NOT use this skill for one-off interactions; use android-device instead.
---

# Android Record — Create Replayable Sessions

Records a sequence of interactions on the Android device as a `.ndjson` file.
Each action is streamed to disk immediately after execution — partial recordings
survive crashes. Replay runs deterministically with `scripts/replay.ts`.

## Prerequisites

Same as android-device: ADB connected, Metro running, app on device.

```bash
adb devices
```

---

## Output file

Save recordings to `scripts/recordings/<name>.ndjson` (create the directory if needed).
Ask the user for a name if not specified, or derive one from their description.

```bash
mkdir -p scripts/recordings
```

Each line is one JSON action, appended immediately after execution:

```ndjson
{"label":"Navigate to Home","text":"Home","nodeId":"NavigationProvider/BottomTabItem/View/RCTView/Animated(Pressable)/Pressable","action":"tap","waitMs":600}
{"label":"Scroll down","action":"swipe-down","waitMs":400}
{"label":"Tap Déconnexion","text":"Déconnexion","nodeId":"RCTView/SettingsCard[1]/View/RCTView/SettingsItem/Pressable","action":"tap","waitMs":500}
```

---

## Core loop

For every **tap** action:

1. **Inspect:**
   ```bash
   bun run scripts/rn-inspector.ts --json 2>/dev/null
   ```
   This returns `{ elements: [...] }`. Each element has `text`, `nodeId`, `px`, `py`.

2. **Identify** the target element. Store both `text` and `nodeId` — replay uses
   text first, nodeId as fallback.

3. **Execute:**
   ```bash
   adb shell input tap <px> <py>
   ```

4. **Stream the action** — append one JSON line to the recording file immediately:
   ```bash
   echo '{"label":"...","text":"...","nodeId":"...","action":"tap","waitMs":500}' >> scripts/recordings/<name>.ndjson
   ```

5. **Wait** for the screen to settle (use the `waitMs` value from the echo, default 500ms):
   ```bash
   sleep 0.5
   ```

6. **Screenshot** to confirm:
   ```bash
   adb exec-out screencap -p > /tmp/rni-screen.png
   ```
   Read `/tmp/rni-screen.png` with the Read tool to verify the navigation succeeded.

For **scroll** actions (no element resolution needed):

```bash
# Swipe down
adb shell input swipe 540 1600 540 400 300
echo '{"label":"Scroll down","action":"swipe-down","waitMs":300}' >> scripts/recordings/<name>.ndjson
sleep 0.3
```

---

## Action JSON fields

| Field | Required | Description |
|---|---|---|
| `label` | yes | Human-readable description of the step |
| `action` | yes | `"tap"` \| `"swipe-down"` \| `"swipe-up"` \| `"back"` |
| `text` | for tap | Extracted text of the element (used first in replay) |
| `nodeId` | for tap | Structural path from rn-inspector JSON (fallback) |
| `waitMs` | no | Milliseconds to wait after action (default: 500 for tap, 300 for swipe) |

**Always record both `text` and `nodeId` for tap actions.** If text is empty or
only icons (unicode chars), still record it — the nodeId alone will handle replay.

---

## waitMs guidelines

| Scenario | waitMs |
|---|---|
| Tab navigation | 600 |
| In-screen tap (button, settings item) | 500 |
| Scroll | 300 |
| Back button | 400 |

---

## Reporting

When done, report:
- The recording file path
- Number of actions recorded
- How to replay: `bun run scripts/replay.ts scripts/recordings/<name>.ndjson`
- Any steps that required scrolling (so the user knows the replay will scroll too)
