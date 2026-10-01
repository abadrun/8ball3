# Build Report

Report format per §57. Statuses per §56.

## 1. Summary

| Field | Value |
|---|---|
| Source revision | branch `arena/01a0f631-8ball3`, base commit `9695a47` |
| MR. SPICY UI version | 1.0.0 |
| Host application version (inspected) | 8 Ball Pool 56.30.0 (5328), `com.miniclip.8ballpoolmult` |
| Build configuration | — (no build performed) |
| Deployment target (declared) | iOS 13.0 (`Package.swift`, matches the inspected host's `MinimumOSVersion`) |
| Architectures (declared) | arm64 (device), arm64/x86_64 (simulator, toolchain-dependent) |
| Swift compile of `MrSpicyUI` | **NOT AVAILABLE — requires macOS + Xcode** |
| Unit tests | **NOT ATTEMPTED** |
| IPA produced | **NO — BLOCKED** (see `../../output/README.md`) |
| Signing | **SIGNING NOT PERFORMED** |
| Provisioning | **NOT AVAILABLE** (no profile, no identity) |
| Installation test | **INSTALLATION TEST NOT PERFORMED** |
| Static validation gates | **PASS** (see §4) |

## 2. Why no binary was produced

Two independent reasons, either of which is sufficient:

1. **Environment.** This is a Linux container with Python and ImageMagick. There is no Swift
   compiler, no iOS SDK, no `xcodebuild`, no simulator and no signing identity. A UIKit library
   cannot be compiled here at all.
2. **Authorisation.** The only app that could be packaged from this repository's input is a
   DRM-stripped copy of a commercial game carrying an injected cheat payload. That artifact is out of
   scope on authorisation grounds, independent of tooling. See
   [`../../SCOPE-AND-BOUNDARIES.md`](../../SCOPE-AND-BOUNDARIES.md).

Neither a build log, a binary, a checksum nor an installation result has been invented to fill the gap.

## 3. What *is* buildable, and how

The MR. SPICY UI layer is a self-contained SwiftPM package that any authorised iOS app can consume.

### As a local package dependency

```swift
// Package.swift of your app
dependencies: [ .package(path: "../MR-SPICY/mr-spicy-ui") ],
targets: [ .target(name: "App", dependencies: [ .product(name: "MrSpicyUI", package: "MrSpicyUI") ]) ]
```

### In Xcode

`File ▸ Add Package Dependencies… ▸ Add Local…` → select `MR-SPICY/mr-spicy-ui`.

### Verify the package alone

```bash
cd MR-SPICY/mr-spicy-ui
xcodebuild -scheme MrSpicyUI -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild test -scheme MrSpicyUI -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Expected build settings

| Setting | Value |
|---|---|
| `IPHONEOS_DEPLOYMENT_TARGET` | 13.0 |
| `SWIFT_VERSION` | 5.9 |
| `ENABLE_BITCODE` | NO (Xcode 14+ default) |
| Resources | `Assets.xcassets`, `en.lproj`, `ar.lproj` processed by SwiftPM (`.process("Resources")`) |
| Linked frameworks | UIKit, Foundation only |

### Known build-time caveats to expect on first compile

Honest disclosure — these are *unverified* because nothing was compiled:

* `Package.swift` enables the upcoming feature `ExistentialAny`; on toolchains older than Swift 5.9
  this flag must be removed.
* `UIButton.contentEdgeInsets` (used in `SpicyHeaderView`) is deprecated from iOS 15 and will emit a
  deprecation warning; it still functions. Migrating to `UIButton.Configuration` is deferred because
  the declared deployment target is iOS 13.
* `UIColor.spicyContrastRatio(against:)` is used only by tests; if you strip tests, it is dead code.

## 4. Static validation actually executed

```
validate_localization.py   → PASS   (58 keys × 2 languages, 0 failures, 0 warnings)
validate_design_tokens.py  → PASS   (token discipline, 13 contrast pairs, 44 pt target,
                                     Reduce Motion, RTL anchor discipline)
export_tokens.py           → DONE   (24 colour tokens, 6 scale groups, 2 languages exported)
inspect_ipa.py             → DONE   (baseline audit)
verify_original.sh         → PASS   (baseline byte-for-byte unchanged)
```

Full output: `../../validation/validation-report.md`.

## 5. Warnings / errors

| Class | Count | Notes |
|---|---:|---|
| Compiler errors | unknown | not compiled — see §2 |
| Compiler warnings | unknown | not compiled; two deprecations predicted above |
| Validation failures | 0 | all gates PASS |
| Blocked tasks | 6 | enumerated in `SCOPE-AND-BOUNDARIES.md` §3 |
