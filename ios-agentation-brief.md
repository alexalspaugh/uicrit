# iOS Agentation — Product Specification

## Overview

Agentation is a debug-only Swift Package that lets a developer tap elements in a running UIKit app, annotate them with notes, and export structured context for AI coding agents. It ships as an SPM package with zero external dependencies. The host app controls when the tool is active — Agentation never activates itself.

## Requirements

- iOS 17+ deployment target
- UIKit-only (see CLAUDE.md)
- SPM package, zero external dependencies
- Debug-only tool — host app gates activation, not the package
- Code style: see CLAUDE.md

## Public API

### Entry Point

```swift
Agentation.install(activationNotification: .deviceDidShake, autoInstrument: false)
```

`install()` is the single entry point. Both parameters are optional.

### Activation Control

```swift
Agentation.activate()
Agentation.deactivate()
Agentation.toggle()
```

The package exposes its API unconditionally — no `#if` guards inside the package. SPM packages do not inherit the host app's custom compilation conditions (Xcode only passes `DEBUG` to SPM deps for debug builds). The host app gates activation:

```swift
// In host app's AppDelegate:
#if DEBUG || DEVELOPMENT
import Agentation
Agentation.install(activationNotification: .deviceDidShake)
#endif
```

Since `install()` is never called in Production/Staging, the code is dead and gets stripped by the linker.

## Core Features

### 1. Tap-to-Select

hitTest-based element identification. Tapping a view in the running app highlights it and shows its metadata.

### 2. Annotation

Add notes and context to selected elements. Annotations are included in the export output.

### 3. Auto-Instrumentation

Opt-in (`autoInstrument` parameter, default: `false`). Uses swizzling (`didMoveToSuperview`) to track view hierarchy changes. Off by default because swizzling can interfere with custom navigation controllers and modal transition types.

### 4. Metadata Capture

Mirror-based stored property name detection. Finds which stored property on a parent references the tapped view. This is not IBOutlet detection — it uses `Mirror` to inspect stored properties at runtime.

### 5. Export

Produces three output formats:
- **Structured JSON** — includes a `schema_version` field for forward compatibility
- **Markdown** — human-readable summary with embedded screenshots
- **Screenshots** — per-element captures

## Technical Constraints

### Shake Gesture

The package must not own the shake gesture. The host app owns `UIWindow.motionEnded` and posts `.deviceDidShake`. Agentation listens for the notification passed to `install(activationNotification:)`, or the host app calls `toggle()` directly.

### Concurrency

`@MainActor` for the Agentation class, overlay, and all UI types. View hierarchy serialization dispatches to a background context to avoid blocking the UI during export.

### Overlay Window

Window level: `.alert + 2`. This coexists with existing debug tools (DebugView at shake-activated panel, PerformanceHUDWindow at `.alert + 1`).

### Screenshots

- JPEG at ~0.6 quality (not PNG)
- Cropped to element bounds + 20pt padding (not full screen by default)
- Capped at 2x scale
- Full-screen available as an option, not default

### JSON Output

Includes a `schema_version` field:

```json
{ "schema_version": "1.0.0", "timestamp": "...", ... }
```

## Verification

1. Add the SPM package to the host workspace
2. Build with `xcodebuild build -scheme "Doji - Playground" -destination "generic/platform=iOS Simulator"` — must compile clean
3. Run in Simulator, shake to activate, tap elements, verify metadata capture
4. Export markdown to clipboard, paste somewhere, confirm it reads correctly
5. Verify JSON written to tmp directory is parseable
6. Confirm no conflicts with DebugView or PerformanceHUD overlays
7. Confirm no swizzling side effects on navigation or modal transitions (if auto-instrument enabled)
