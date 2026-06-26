# Changelog

All meaningful repository changes should be documented in this file.

## 2026-06-25

- Added `focusMode` support that activates the app owning the top normal window under the new cursor position after display switching.
- Fixed cursor cue placement by converting CoreGraphics cursor/display coordinates into AppKit screen coordinates before showing the overlay.
- Made `install` preserve the existing service app by default so normal reinstalls do not invalidate macOS Accessibility permission; added explicit `upgrade` replacement behavior.
- Added a configurable animated cursor visual cue after successful display switching.
- Created the initial SwiftPM implementation of `oxx`, a macOS user-level cursor display cycle service.
- Added the `oxx` CLI for display listing, cursor jumping, config validation, LaunchAgent install/start/stop/status, and service permission diagnostics.
- Added the `oxx-service` background process that installs a CGEvent tap for middle-click display cycling.
- Added stable service installation as `~/Applications/oxx-service.app` with LaunchAgent wiring.
- Added unit tests for display ordering, display cycling, config defaults, prompt policy, and stable install paths.
