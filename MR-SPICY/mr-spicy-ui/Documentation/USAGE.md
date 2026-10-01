# Using MR. SPICY UI

Requirements: iOS 13+, Swift 5.9+, UIKit. No third-party dependencies.

## 1. Add the package

Xcode: `File ▸ Add Package Dependencies… ▸ Add Local…` → select `MR-SPICY/mr-spicy-ui`.

SwiftPM:

```swift
dependencies: [ .package(path: "../MR-SPICY/mr-spicy-ui") ],
targets: [ .target(name: "App", dependencies: [ .product(name: "MrSpicyUI", package: "MrSpicyUI") ]) ]
```

## 2. Present the overlay

```swift
import MrSpicyUI

let overlay = SpicyOverlayViewController()
overlay.dataSource = adapter      // what to show
overlay.delegate   = adapter      // what the user did
present(overlay, animated: true) { overlay.send(.open) }
```

`SpicyOverlayViewController` is a normal `UIViewController` with
`modalPresentationStyle = .overFullScreen`, so it can also be added as a child view controller or
hosted in its own `UIWindow`.

## 3. Drive it with a data source

```swift
func spicyOverlayTiles(_ c: SpicyOverlayViewController) -> [SpicyFeatureTile.Model] {
    [
        .init(id: "settings", titleKey: .settingsTitle,   systemImageName: "gearshape"),
        .init(id: "language", titleKey: .settingsLanguage, systemImageName: "globe"),
        .init(id: "help",     titleKey: .settingsHelp,     systemImageName: "questionmark.circle",
              state: helpAvailable ? .default : .disabled),
    ]
}

func spicyOverlayStatus(_ c: SpicyOverlayViewController) -> (text: String, kind: SpicyStatusBadge.Kind)? {
    guard let s = session.status else { return nil }   // nil → no badge at all
    return (s.text, s.ok ? .success : .warning)
}
```

Rule: return `nil` rather than a placeholder. The UI layer never invents state.

## 4. State

```swift
overlay.send(.open)                  // closed    → expanded
overlay.send(.minimise)              // expanded  → minimised
overlay.send(.present(.help))        // expanded  → modalPresented(.help)
overlay.send(.dismissModal)          // back to expanded
overlay.send(.close)                 // → closed, from anywhere
overlay.machine.presentation         // current state
```

Illegal transitions are no-ops, so you can send events without guarding.

## 5. Modals — one system, five presets

```swift
overlay.presentModal(.info(titleKey: .aboutTitle, messageKey: .aboutCredits))
overlay.presentModal(.loading())
overlay.presentModal(.success(messageKey: .settingsReset…))
overlay.presentModal(.error(retry: { reload() }))
overlay.presentModal(.confirmation(titleKey: .settingsResetTitle,
                                   messageKey: .settingsResetMessage,
                                   confirmKey: .settingsResetConfirm,
                                   onConfirm: { reset() }))
```

Custom content: pass any `UIView` as `customContent` — it is inserted above the action buttons and
inherits layout direction, padding and accessibility behaviour.

## 6. Language and direction

```swift
SpicyL10n.shared.setLanguage(.arabic)   // persists; posts languageDidChangeNotification
SpicyL10n.shared.current                // .english | .arabic
SpicyL10n.shared.string(.settingsTitle)
SpicyL10n.shared.number(1234)           // locale-formatted
```

Every component observes the notification, re-resolves its text and re-applies alignment; the
container re-applies the semantic content attribute across its subtree. No restart, no reload call.

To surface translation gaps in CI:

```swift
SpicyL10n.shared.missingKeyHandler = { key, language in
    Analytics.log("missing_string", ["key": key, "lang": language.rawValue])
}
```

## 7. Theming

Consume tokens; never literals.

```swift
view.backgroundColor = SpicyTheme.Color.surface
view.spicyApply(radius: SpicyTheme.Radius.l)
view.spicyApply(shadow: .level2)
label.font = SpicyTheme.Typography.body()
stack.spacing = SpicyTheme.Spacing.m
SpicyTheme.Motion.animate { view.alpha = 1 }       // respects Reduce Motion
```

To rebrand, edit `SpicyTheme.swift` only, then run
`python3 validation/tools/export_tokens.py` to refresh the preview.

## 8. Layout helpers

```swift
child.spicyPin(to: parent, insets: .init(top: 16, left: 16, bottom: 16, right: 16))
child.spicyPinToSafeArea(of: view)
button.spicyEnforceMinimumTouchTarget()

let m = SpicyLayoutMetrics(traitCollection: traitCollection,
                           size: view.bounds.size,
                           safeArea: view.safeAreaInsets)
m.tileColumns(availableWidth: view.bounds.width)   // 2…6
m.prefersStackedRows                                // true at AX text sizes
```

`spicyPin` uses leading/trailing anchors, so everything mirrors automatically in Arabic.

## 9. Accessibility expectations

Components already set labels, hints, traits, `accessibilityViewIsModal`, focus announcements and
44 pt targets. When you add your own views:

* give every interactive view a localised `accessibilityLabel`;
* add `.selected` / `.notEnabled` traits rather than relying on colour;
* post `.screenChanged` / `.announcement` on significant transitions;
* never place text below 11 pt or on an untested colour pair — add the pair to
  `validate_design_tokens.py` instead.
