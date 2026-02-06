# iOS Agentation Brief — Evaluation & Recommended Changes

## Context

The brief describes a debug-only Swift Package that lets a developer tap elements in a running UIKit app, annotate them with notes, and export structured context for AI coding agents. This evaluation identifies what needs to change so the brief aligns with Doji's codebase practices before implementation begins.

---

## What the Brief Gets Right

- **UIKit-only** — matches Doji's "Default to UIKit for everything" rule
- **SPM distribution** — Doji manages all dependencies via SPM
- **Zero external dependencies** — Doji already has significant dep weight; a debug tool shouldn't add more
- **Single `install()` entry point** — matches Doji patterns like `AppStyle.apply()`, `Analytics.start()`, `FirebaseApp.configure()` in AppDelegate
- **hitTest-based identification** — Doji already uses custom hitTest in `ToastManager` (`PassthroughWindow`), `PassthroughOverlay`, etc.
- **Overlay window approach** — proven pattern in Doji's `ToastManager` (`.alert` level) and `PerformanceHUDWindow` (`.alert + 1` level)

---

## Critical Changes Required

### 1. Deployment Target: iOS 15+ → iOS 17+

The brief says iOS 15+. Doji's base project target is **iOS 17.5**, main app target is **iOS 18.0**. The package's `Package.swift` should specify `.iOS(.v17)` minimum. Targeting iOS 15 would mean designing against APIs three major versions behind what Doji actually runs.

### 2. Conditional Compilation: Package Must Not Use `#if DEVELOPMENT`

The brief proposes `#if DEBUG || DEVELOPMENT` inside the package. **SPM packages do not inherit the host app's custom compilation conditions.** Xcode only passes `DEBUG` to SPM deps for debug builds — `DEVELOPMENT` is never set from the package's perspective.

**Fix:** The package should expose its API unconditionally (no `#if` guards inside the package). The host app gates it:

```swift
// In Doji's AppDelegate:
#if DEBUG || DEVELOPMENT
import Agentation
Agentation.install(...)
#endif
```

Since `install()` is never called in Production/Staging, the code is dead and gets stripped by the linker.

### 3. Shake Gesture: Package Must Not Own It

Doji already has a global `UIWindow.motionEnded` override in `Doji/Legacy/Extensions/UIKit/UIWindow.swift` that posts `.deviceDidShake`. If the package adds its own UIWindow extension, it will **cause a compile error** (duplicate override).

**Fix:** The package should expose `Agentation.activate()` / `Agentation.deactivate()` / `Agentation.toggle()`. The host app wires up activation:

```swift
Agentation.install(activationNotification: .deviceDidShake)
// — or —
NotificationCenter.default.addObserver(forName: .deviceDidShake, ...) {
    Agentation.toggle()
}
```

This also allows future integration with Doji's existing DebugView as a toggle option.

---

## High-Priority Changes

### 4. Formatting Rules (not mentioned in brief)

Doji uses tabs and 200-char line length (`.swift-format` config). The package should include a `.swift-format` matching:
```json
{ "indentation": { "tabs": 1 }, "lineLength": 200 }
```

### 5. Closure Conventions (not mentioned in brief)

Per CLAUDE.md, all closures must use `[weak self]` and avoid blanket `guard let self`. The brief's code examples should follow this. No direct method references (e.g., `button.onTap = self.doThing` is forbidden).

### 6. No `convenience init` / No `typealiases`

CLAUDE.md explicitly prohibits both. The brief should note these as constraints for any public API or model types.

### 7. Auto-Instrumentation Should Be Optional

Doji has **zero existing swizzling** in the codebase. Introducing `didMoveToSuperview` swizzling is a new pattern that could interfere with Doji's custom navigation (1200+ line `DojiNavigationController`) and 14 custom modal transition types.

**Fix:** Make auto-instrumentation opt-in:
```swift
Agentation.install(autoInstrument: true) // default: false
```

---

## Medium-Priority Changes

### 8. Screenshot Optimization (brief underspecified)

A full-screen PNG on a modern iPhone can be 5-15MB; base64 inflates it by 33%. Multiple annotations would produce massive markdown.

**Add to brief:**
- Use JPEG at ~0.6 quality instead of PNG
- Crop to annotated element bounds + 20pt padding (not full screen)
- Cap resolution at 2x scale
- Keep full-screen as an option, not default

### 9. Mirror-Based IBOutlet Detection → Property Name Detection

Doji does **not use Interface Builder or Storyboards** for modern code (all programmatic layout). There are no `@IBOutlet`s to detect. `Mirror` is still useful for finding stored property names that reference the tapped view, but the brief should reframe this as "property name detection via Mirror" rather than "IBOutlet detection."

### 10. Output Schema Versioning

The JSON output should include a `schema_version` field so consuming AI agents can handle format changes:
```json
{ "schema_version": "1.0.0", "timestamp": "...", ... }
```

### 11. Concurrency Model (not mentioned)

Doji is heavily `@MainActor`-annotated (`ToastManager`, `UserStore`, etc.). The Agentation class and overlay should be `@MainActor`. View hierarchy serialization should dispatch to a background context to avoid blocking the UI during export.

### 12. Coexistence with Existing Debug Tools

The brief doesn't mention that Doji already has:
- **DebugView** — SwiftUI debug panel activated via shake
- **PerformanceHUDWindow** — overlay at `.alert + 1`

The brief should explicitly state the Agentation overlay window level (e.g., `.alert + 2`) and that it coexists with both.

---

## Summary Table

| Priority | Issue | Brief Says | Should Say |
|----------|-------|-----------|------------|
| CRITICAL | Deploy target | iOS 15+ | iOS 17+ |
| CRITICAL | Compilation flags | `#if DEBUG \|\| DEVELOPMENT` in package | No `#if` in package; host app gates `install()` |
| CRITICAL | Shake gesture | Package owns shake | Package exposes `toggle()`; host app owns shake |
| HIGH | Formatting | Not specified | Tabs, 200 char lines, swift-format |
| HIGH | Closures | Not specified | `[weak self]`, no method refs |
| HIGH | Swizzling | Mandatory | Optional, opt-in |
| HIGH | No convenience init | Not mentioned | Must be a constraint |
| MEDIUM | Screenshots | PNG, base64, implied full-screen | JPEG, cropped, size-capped |
| MEDIUM | IBOutlet detection | Mirror for IBOutlets | Mirror for stored properties (no IBOutlets in Doji) |
| MEDIUM | Schema version | Not specified | Add `schema_version` to JSON |
| MEDIUM | Concurrency | Not specified | `@MainActor` for UI; background for serialization |
| MEDIUM | Debug tool coexistence | Not mentioned | Specify window level, no conflicts |

---

## Verification

After updating the brief and implementing:
1. Add the SPM package to the Doji workspace
2. Build with `xcodebuild build -scheme "Doji - Playground" -destination "generic/platform=iOS Simulator"` — must compile clean
3. Run in Simulator, shake to activate, tap elements, verify metadata capture
4. Export markdown to clipboard, paste somewhere, confirm it reads correctly
5. Verify JSON written to tmp directory is parseable
6. Confirm no conflicts with DebugView or PerformanceHUD overlays
7. Confirm no swizzling side effects on navigation or modal transitions (if auto-instrument enabled)
