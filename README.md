# UICrit

A design tool for UIKit apps. Select an area of your running app, annotate what you want changed, and export structured context for AI coding agents.

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

1. Drag to select an area of the UI
2. Adjust the selection if needed, then confirm
3. Add an annotation describing what you want changed
4. Export writes structured metadata, screenshots, and a markdown summary to `/tmp/UICrit/latest/` and prints the path to the Xcode console

## Export Output

Exports write to `/tmp/UICrit/<timestamp>/` with a symlink at `/tmp/UICrit/latest/`.

| File | Contents |
|---|---|
| `export.json` | Structured metadata for all views in the selected area, plus your annotation and area bounds |
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
2. Drag to select the area you want to change
3. Annotate with your intent (e.g. "make this button blue", "move this 8pt down", "hide when logged out")
4. Export — the path prints to the Xcode console
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
2. Drag to select an area → confirm selection rectangle appears
3. Annotate → confirm input appears, annotation saves, and console prints the export directory path
4. Verify `export.json`, `export.md`, and screenshots in the temp directory
