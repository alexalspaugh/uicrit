# Agentation

Debug tool for UIKit apps. Tap or drag-to-select elements in a running app, annotate them with intent, and export structured context for AI coding agents.

## Requirements

- iOS 16+ deployment target (activates only on iOS 26+)
- UIKit
- Zero dependencies

## Installation

Add via Swift Package Manager:

1. **File → Add Package Dependencies**
2. Paste the repo URL
3. Add `Agentation` to your target

## Setup

In your `AppDelegate` (or wherever you bootstrap):

```swift
#if DEBUG
import Agentation

if #available(iOS 26, *) {
    Agentation.install(activationNotification: .deviceDidShake)
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
Agentation.activate()
Agentation.deactivate()
Agentation.toggle()
```

## Usage

When activated:

1. A glass toolbar appears at the bottom with two buttons — **Annotate** and **Done**
2. **Tap** any element to select it and see its metadata (class name, property name, view controller, accessibility ID, frame)
3. **Drag** to draw a selection rectangle and select multiple elements at once
4. **Annotate** selected elements with notes describing what you want changed — saving an annotation automatically exports metadata, screenshots, and a markdown summary to the Xcode console
5. **Done** dismisses the overlay

## Export Output

Export writes to a temp directory (`FileManager.temporaryDirectory/Agentation/`):

| File | Contents |
|---|---|
| `export.json` | Structured metadata — element class names, property names, frames, view controllers, accessibility IDs, annotations, screenshot filenames |
| `export.md` | Human-readable markdown summary (printed to Xcode console on each export) |
| `{id}.jpg` | Per-element JPEG screenshot, cropped to element bounds + 20pt padding |

## Auto-Instrumentation

Opt-in flag that swizzles `UIView.didMoveToSuperview` to track view hierarchy changes at runtime:

```swift
Agentation.install(activationNotification: .deviceDidShake, autoInstrument: true)
```

Default is `false`. Enabling this can interfere with custom navigation or modal transitions — use with caution.

## Using with Claude Code

Agentation is designed to feed context directly into AI coding agents like Claude Code:

1. Activate Agentation in your running app
2. Select the elements you want changed
3. Annotate each element with your intent — e.g. "make this button blue", "this label should show the username"
4. Saving the annotation auto-exports — the markdown summary and export directory path are printed to the Xcode console
5. Point Claude Code at the export directory path shown in the console (e.g. read the `export.md` file directly)

Claude Code receives structured metadata (class names, property names, view controller, accessibility IDs, frames) plus your annotations — enough to locate and modify the right code.

**Tip:** Annotate with *intent* ("move this 8pt down", "hide when logged out") rather than just describing what's there. The metadata already captures the current state.

## Testing / Verification

Build the package:

```bash
xcodebuild build -scheme "Agentation" -destination "platform=iOS Simulator,name=iPhone 16"
```

To verify end-to-end, integrate into a host app and run in the Simulator:

1. Shake (or call `Agentation.activate()`) to trigger the overlay
2. Tap an element → confirm highlight and metadata label appear
3. Drag to multi-select → confirm marquee rectangle and multiple highlights
4. Annotate → confirm input bar appears, annotation saves, and console prints the markdown content + export directory path
5. Verify `export.json`, `export.md`, and screenshots in the temp directory
6. Done → overlay dismisses cleanly
