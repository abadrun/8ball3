# MR. SPICY — Architecture

## 1. The two systems in this repository

```
┌──────────────────────────────────────────────────────────────────────┐
│  INSPECTED MATERIAL (read-only, never modified, never rebuilt)       │
│                                                                      │
│  8-ball-pool-i3rby-IPAOMTK.COM.ipa                                   │
│   ├── Payload/pool.app              commercial third-party host      │
│   │    ├── pool                     Cocos2d-x game, arm64, iOS 13+   │
│   │    ├── Frameworks/ (25 SDKs)    publisher-embedded ad/analytics  │
│   │    ├── PlugIns/ (4 .appex)      widget, notifications, iMessage  │
│   │    └── Frameworks/libloader…    ✖ injected cheat overlay          │
│   └── (audited → original/manifests/)                                │
└──────────────────────────────────────────────────────────────────────┘
                     no code, no build, no patch crosses this line
┌──────────────────────────────────────────────────────────────────────┐
│  MR. SPICY UI LAYER (authored here, source-controlled, reusable)     │
│                                                                      │
│  mr-spicy-ui/  — standalone SwiftPM package, host-independent        │
└──────────────────────────────────────────────────────────────────────┘
```

The MR. SPICY layer has **no dependency on, reference to, or knowledge of** the inspected
application. That is deliberate: see [`../../SCOPE-AND-BOUNDARIES.md`](../../SCOPE-AND-BOUNDARIES.md).

## 2. MR. SPICY UI layer structure

```
mr-spicy-ui/
├── Package.swift                     SwiftPM, iOS 13+, resources processed
├── Sources/MrSpicyUI/
│   ├── Core/
│   │   ├── SpicyTheme.swift          design tokens: colour, spacing, radius,
│   │   │                             typography, size, elevation, opacity, motion
│   │   ├── SpicyLocalization.swift   SpicyL10n + SpicyStringKey + fallback
│   │   ├── SpicyLayout.swift         RTL, safe area, responsive metrics, AL sugar
│   │   ├── SpicyState.swift          presentation/content/control state + reducer
│   │   └── SpicyBrand.swift          cached brand asset access
│   ├── Components/
│   │   ├── SpicyButton.swift         primary / secondary / ghost / destructive
│   │   ├── SpicyCard.swift           surface container + SpicySectionHeader
│   │   ├── SpicyHeaderView.swift     branded header with control cluster
│   │   ├── SpicyStatusBadge.swift    neutral/success/warning/danger/info pill
│   │   ├── SpicyFeatureTile.swift    tile + responsive mirroring grid
│   │   ├── SpicyModalView.swift      THE modal system (one implementation)
│   │   └── SpicySettingRow.swift     row primitives + grouped card
│   ├── SpicyOverlayViewController.swift   container, owns the state machine
│   ├── SpicySettingsViewController.swift  settings surface
│   └── Resources/
│       ├── Assets.xcassets/MrSpicyLogo.imageset (@1x/@2x/@3x)
│       ├── en.lproj/MrSpicy.strings
│       └── ar.lproj/MrSpicy.strings
├── Tests/MrSpicyUITests/             state machine, localisation, theme/layout
└── Documentation/
    ├── BUILDING.md  COMPONENTS.md  USAGE.md
    └── preview/                      browser preview generated from the source
```

### Dependency direction

```
SpicyOverlayViewController ─┬─> Components ──> Core (Theme, L10n, Layout, State, Brand)
SpicySettingsViewController ┘
Core has no dependency on Components, and nothing depends on a host.
```

Core is pure: `SpicyState.swift` imports only Foundation, so the whole state model compiles and is
testable on any Swift toolchain, including Linux CI.

## 3. Design principles enforced mechanically

| Principle | Enforcement |
|---|---|
| No hard-coded visual values | `validate_design_tokens.py` fails on any colour literal or numeric corner radius outside `SpicyTheme.swift` |
| Real RTL, not translated LTR | the same validator fails on any use of `.leftAnchor` / `.rightAnchor`; mirroring is done by `SpicyLayoutDirection.apply` on the whole subtree |
| No orphan or missing translations | `validate_localization.py` cross-checks `SpicyStringKey` against every `.strings` table in both directions |
| No hard-coded display strings | same validator greps `.text` / `.accessibilityLabel` / `setTitle(` assignments |
| Accessible contrast | the validator computes WCAG 2.1 ratios for 13 foreground/background pairs from the actual token values |
| 44 pt touch targets | token asserted ≥ 44; components apply `spicyEnforceMinimumTouchTarget()` or explicit constraints |
| Reduce Motion | all animation goes through `SpicyTheme.Motion.animate`, which collapses to an immediate apply |
| Preview cannot drift from source | `export_tokens.py` regenerates `tokens.json` / `strings.json` from the Swift + `.strings` files |

## 4. State model

`SpicyStateMachine` is a pure reducer: `(state, event) -> state`. Unlisted transitions are no-ops, so
invalid UI states cannot be reached.

```
                 .open                 .openSettings
   closed ─────────────────> expanded ───────────────> settingsPresented
     ▲                        │   ▲                         │
     │ .close (from any)      │   │ .expand                 │ .closeSettings
     │                 .minimise   │                        ▼
     └──────────────────  minimised ◀───────────────── expanded
                               │
                 .present(kind)│  .dismissModal
                               ▼
                        modalPresented(kind)
```

Content loading uses a separate generic enum so a view never has to combine
`isLoading`/`hasError`/`isEmpty` booleans:

```swift
enum SpicyContentState<Value: Equatable> {
    case idle, loading
    case success(Value)
    case failure(SpicyFailure)
    case unavailable(reason: String)
}
```

## 5. Integration boundary

The only way a host talks to the layer:

```swift
protocol SpicyOverlayDataSource: AnyObject {
    func spicyOverlayTiles(_ c: SpicyOverlayViewController) -> [SpicyFeatureTile.Model]
    func spicyOverlayStatus(_ c: SpicyOverlayViewController) -> (text: String, kind: SpicyStatusBadge.Kind)?
}

protocol SpicyOverlayDelegate: AnyObject {
    func spicyOverlay(_ c: SpicyOverlayViewController, didSelectTile model: SpicyFeatureTile.Model)
    func spicyOverlay(_ c: SpicyOverlayViewController, didChangeState state: SpicyPresentationState)
    func spicyOverlay(_ c: SpicyOverlayViewController, didChangeLanguage language: SpicyLanguage)
}
```

Consequences:

* the UI layer never invents state — if the host does not supply a status, no badge is shown;
* tiles are **navigation controls**, not behaviour; selecting one reports back to the host;
* the layer can be versioned, re-themed and re-localised without touching host code, and a host can
  change without touching the layer (that is the point of §27/§28 of the brief).

## 6. Performance characteristics

| Concern | Measure taken |
|---|---|
| Image decoding | `SpicyBrand.logo()` decodes once into an `NSCache`; purged on memory warning |
| Retain cycles | every closure capturing `self` uses `[weak self]`; every `NotificationCenter` observer token is removed in `deinit` |
| Layout thrash | the tile grid rebuilds only when the computed column count changes, not on every `viewDidLayoutSubviews` |
| Reuse | rows, tiles, badges and buttons are single implementations reused everywhere; `SpicyModalView` is the only dialog class |
| Animation | no repeating/looping animations; all durations collapse to 0 under Reduce Motion |

**Not measured on device.** No Instruments run, allocation trace or frame-time measurement has been
performed — there is no Apple hardware in this environment. The table above lists design measures,
not benchmark results.
