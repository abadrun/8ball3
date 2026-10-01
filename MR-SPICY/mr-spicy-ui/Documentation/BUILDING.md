# Building MR. SPICY UI

## Requirements

| Requirement | Version |
|---|---|
| macOS with Xcode | 15+ (Swift 5.9 toolchain) |
| iOS deployment target | 13.0 |
| Dependencies | none |

**This package cannot be built on Linux.** It links UIKit, which exists only in Apple SDKs.
The authoring environment for v1.0.0 had no Swift toolchain, so the package has
**never been compiled** — see `../../validation/validation-report.md` §7.

## Build

```bash
cd MR-SPICY/mr-spicy-ui
xcodebuild -scheme MrSpicyUI -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Test

```bash
xcodebuild test -scheme MrSpicyUI -destination 'platform=iOS Simulator,name=iPhone 15'
```

28 cases: `SpicyStateMachineTests` (10, pure Swift), `SpicyLocalizationTests` (7, UIKit),
`SpicyThemeAndLayoutTests` (11, UIKit).

## Static gates (run anywhere, no toolchain needed)

```bash
python3 ../validation/tools/validate_localization.py    # key parity, format specifiers, Arabic script
python3 ../validation/tools/validate_design_tokens.py   # tokens, contrast, touch targets, RTL anchors
python3 ../validation/tools/export_tokens.py            # refresh the documentation preview
```

Wire all three into CI; they are fast and have no dependencies beyond Python 3.

## Resources

`Package.swift` uses `.process("Resources")`, so SwiftPM compiles `Assets.xcassets` and copies
`en.lproj` / `ar.lproj`. Strings resolve through `Bundle.module` under SwiftPM; the
`SpicyL10n.resourceBundle` fallback handles a manually embedded `MrSpicyUI.bundle` in a non-SwiftPM
host.

## Predicted first-compile notes (unverified)

* `ExistentialAny` upcoming-feature flag requires Swift 5.9+; remove it for older toolchains.
* `UIButton.contentEdgeInsets` in `SpicyHeaderView` is deprecated on iOS 15+ (warning only).
* Three SF Symbols used by the settings surface (`figure.walk.motion`,
  `circle.lefthalf.filled`, `textformat.size`) do not exist on iOS 13; supply custom images if you
  must support 13.0 exactly.
