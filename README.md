# UICrit

Debug tool for UIKit apps. Tap or drag-to-select elements in a running app, annotate them with intent, and export structured context for AI coding agents.

## Requirements

- iOS 16+ deployment target (activates only on iOS 26+)
- UIKit
- Zero dependencies

## Installation

Add via Swift Package Manager:

1. **File → Add Package Dependencies**
2. Paste the repo URL
3. Add `UICrit` to your target

## Setup

In your `AppDelegate` (or wherever you bootstrap):

```swift
#if DEBUG
import UICrit

if #available(iOS 26, *) {
    UICrit.install(activationNotification: .deviceDidShake)
}
#endif
```

The package does not own any gesture — your host app posts the notification. A common pattern using shake:

```swift
extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}
```

You can also skip the notification and control activation directly:

```swift
UICrit.activate()
UICrit.deactivate()
UICrit.toggle()
```

## Usage

When activated:

1. A glass toolbar appears at the bottom with two buttons — **Annotate** and **Done**
2. **Tap** any element to select it and see its metadata (class name, property name, view controller, accessibility ID, frame)
3. **Drag** to draw a selection rectangle and capture multiple elements at once — reposition by dragging, resize with corner handles
4. **Annotate** with a note describing what you want changed — saving exports metadata, screenshots, and a markdown summary
5. The export directory path prints to the Xcode console
6. **Done** dismisses the overlay

## Export Output

Exports write to `/tmp/UICrit/<timestamp>/` with a symlink at `/tmp/UICrit/latest/`.

**Single-element export** (tap + annotate):

| File | Contents |
|---|---|
| `export.json` | Structured metadata — class names, property names, frames, view controllers, visual properties, annotations |
| `export.md` | Human-readable markdown summary |
| `{id}.jpg` | Per-element JPEG screenshot, cropped to element bounds + 20pt padding |

**Area export** (drag-select + annotate):

| File | Contents |
|---|---|
| `export.json` | Structured metadata for all views in the selected area, plus your note and area bounds |
| `export.md` | Human-readable markdown summary |
| `fullscreen.jpg` | Full-screen screenshot for context |
| `area.jpg` | Cropped screenshot of the selected area |

## Auto-Instrumentation

Opt-in flag that swizzles `UIView.didMoveToSuperview` to track view hierarchy changes at runtime:

```swift
UICrit.install(activationNotification: .deviceDidShake, autoInstrument: true)
```

Default is `false`. Enabling this can interfere with custom navigation or modal transitions — use with caution.

## Using with Claude Code

### Workflow

1. Activate UICrit in the simulator (shake or call `UICrit.activate()`)
2. Select the UI you want to change — tap a single element or drag-select an area
3. Annotate with your intent (e.g. "make this button blue", "move this 8pt down", "hide when logged out")
4. Save — the export path prints to the Xcode console
5. In Claude Code, type `/check-uicrit` to read the latest export

### Installing the Skill

Copy the skill file from this repo into your project's `.claude/commands/` directory:

```bash
mkdir -p .claude/commands
cp <path-to-uicrit-repo>/skill/check-uicrit.md .claude/commands/check-uicrit.md
```

This registers `/check-uicrit` as a slash command in Claude Code. When invoked, Claude reads the latest export (JSON, screenshots, source files) and is ready to make targeted code changes.

**Tip:** Annotate with *intent* rather than describing what's there — the metadata already captures the current state.

## Testing / Verification

Build the package:

```bash
xcodebuild build -scheme "UICrit" -destination "platform=iOS Simulator,name=iPhone 16"
```

To verify end-to-end, integrate into a host app and run in the Simulator:

1. Shake (or call `UICrit.activate()`) to trigger the overlay
2. Tap an element → confirm highlight and metadata label appear
3. Drag to multi-select → confirm marquee rectangle and multiple highlights
4. Annotate → confirm input bar appears, annotation saves, and console prints the markdown content + export directory path
5. Verify `export.json`, `export.md`, and screenshots in the temp directory
6. Done → overlay dismisses cleanly
