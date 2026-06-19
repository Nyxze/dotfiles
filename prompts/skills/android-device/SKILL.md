---
name: android-device
description: >
  Drive a connected Android device for this React Native / Expo project (Lootopia).
  Use this skill whenever you need to interact with or observe the running mobile app:
  verifying a UI change landed correctly, navigating between screens, tapping buttons,
  filling forms, scrolling lists, taking screenshots, or confirming a feature works
  end-to-end on a real device. Trigger on any request involving "check on device",
  "verify the UI", "navigate to X", "tap X", "test the app", "what does the screen
  look like", or "does it work on mobile". Requires ADB + Metro dev server running.
---

# Android Device — Observe & Interact

Drive a connected Android device via ADB for the Lootopia Expo app. The workflow
combines a React Native Fiber tree inspector (`rn-inspector`) with ADB screenshots
and input commands to achieve reliable, zero-miss-tap automation.

## Prerequisites

- Android device connected via USB with USB debugging enabled
- `adb` available on PATH
- App running on device + Metro dev server active (`bunx expo start --android`)

Quick check:
```bash
adb devices
```

---

## Core loop

Repeat this for every action:

1. **Inspect + screenshot in one step:**
   ```bash
   bun run scripts/rn-inspector.ts --screenshot
   ```
   This gives you element positions AND saves a screenshot to `/tmp/rni-screen.png`.

2. **Read the screenshot** — call the Read tool on `/tmp/rni-screen.png` to see the
   current screen visually. Do not describe what you expect or remember from a prior
   step — actually read the file so you see the current state.

3. **Cross-reference** — match elements from rn-inspector with what you see in the
   screenshot. Ignore anything that doesn't appear on the visible screen (see ghost
   elements below).

4. **Act** — tap the correct coordinates from rn-inspector.

5. **Repeat** from step 1 to confirm the result.

> **Never estimate coordinates from a screenshot.** The Read tool rescales images at
> an arbitrary display size — visual pixel estimation will miss. rn-inspector returns
> exact physical device pixels via `measureInWindow`.

---

## rn-inspector — element positions via React Fiber tree

Connects to Metro's CDP endpoint, walks the React Fiber tree, calls `measureInWindow`
on every `Pressable`/`Touchable`, and returns exact device pixel coordinates.

```bash
# Inspect + screenshot (recommended default)
bun run scripts/rn-inspector.ts --screenshot

# Inspect only
bun run scripts/rn-inspector.ts

# Machine-readable JSON
bun run scripts/rn-inspector.ts --json

# Full component tree (to understand screen structure or debug)
bun run scripts/rn-inspector.ts --tree
```

**Output format:**
```
tap(378,554)  255×89  fy=0.068  ScrollView  "À proximité"
tap(541,874)  995×407 fy=0.119  HuntCard    "Hello 0.0 km · Facile"
tap(181,2252) 360×113 fy=0.338  View        "  Home"
```

Columns: `tap(x,y)` center in physical pixels · `w×h` size · `fy` vertical fraction
(0=top, 1=bottom) · parent component · extracted text.

### Ghost elements (known limitation)

React Navigation 7 keeps adjacent tabs mounted in the Fiber tree. rn-inspector may
return a few elements from background tabs — e.g. filter chips from the Home tab
while you're on Profil. They measure at real-looking coordinates but correspond to
content that's behind the active screen.

**How to spot them:** cross-reference with the screenshot. If an element's text or
position doesn't match anything visible, it's a ghost — skip it.

### Elements off-screen

rn-inspector only sees elements currently mounted in the viewport. If you expect a
button but it's not in the list, scroll first, then re-inspect:

```bash
# Scroll down
adb shell input swipe 540 1600 540 400 300
bun run scripts/rn-inspector.ts --screenshot
```

---

## Screenshot

```bash
adb exec-out screencap -p > /tmp/screen.png
```

Use a unique filename per reference point (`home_ref.png`, `after_tap.png`) so
screenshots don't overwrite each other while you're still comparing them.

The device is **1080×2400 px**. The `fy` field in rn-inspector maps directly:
`fy=0.338` means the element's center is at 33.8% from the top.

---

## Tapping

```bash
# rn-inspector output: tap(375,770) → use x=375, y=770
adb shell input tap 375 770
```

**Gesture bar:** `y > 2256` (fy > 0.94) is intercepted by Android's gesture navigation.
For elements near the bottom, verify `fy < 0.94` before tapping.

---

## Other input

### Scroll
```bash
adb shell input swipe 540 1600 540 400 300   # scroll down
adb shell input swipe 540 400 540 1600 300   # scroll up
```

### Type text
```bash
# Tap the field first, then:
adb shell input text "hello%sworld"   # spaces → %s
```

### System keys
```bash
adb shell input keyevent KEYCODE_BACK
adb shell input keyevent KEYCODE_HOME
adb shell input keyevent KEYCODE_ENTER
adb shell input keyevent KEYCODE_DEL
```

### Long press
```bash
adb shell input swipe <x> <y> <x> <y> 600
```

---

## Navigation rules

**Never use the Expo dev menu to reload.** If something is broken, ask the user to
restart Metro: `cd apps/mobile && bunx expo start --android`

**Never press KEYCODE_BACK on the root screen.** It exits to the Android launcher.
To relaunch the app: `adb shell am start -n com.lootopia.app/.MainActivity`

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `rn-inspector` returns 0 elements | Metro not connected to device — ask user to restart `bunx expo start --android` |
| `Metro not reachable` error | Dev server not running — same fix |
| Element not in rn-inspector output | It's off-screen — scroll then re-inspect |
| Tap hits wrong element | Check for ghost elements; cross-reference with screenshot |
| App exited to launcher | `adb shell am start -n com.lootopia.app/.MainActivity` |

---

## Reporting

After completing a verification task, report:
- What the final screenshot showed
- Which screens were visited and what actions were taken
- Any unexpected behavior found
