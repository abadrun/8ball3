# Compatibility Matrix

Statuses: `PASS` / `FAIL` / `PARTIAL` / `NOT TESTED` / `NOT AVAILABLE` / `BLOCKED`.
Nothing in this file is inferred — an untested item says NOT TESTED.

## 1. MR. SPICY UI layer

| Field | Value |
|---|---|
| MR. SPICY UI version | 1.0.0 |
| Declared minimum iOS | 13.0 |
| Maximum iOS tested | **NOT TESTED** |
| Architectures (declared) | arm64 device; simulator per toolchain |
| Architectures tested | **NOT TESTED** |
| Device families (designed for) | iPhone + iPad |
| Device families tested | **NOT TESTED** |
| Orientations supported | portrait + landscape (layout is orientation-agnostic) |
| Orientations tested | **NOT TESTED** |
| Dynamic Type | designed xSmall → AX5 (stacked-row fallback at AX sizes) · **NOT TESTED on device** |
| Dark mode | canonical palette |
| Light mode | token variants present · **NOT TESTED on device** |
| English | strings complete, validator **PASS** · on-device **NOT TESTED** |
| Arabic | strings complete, validator **PASS** · on-device **NOT TESTED** |
| RTL | implemented structurally, anchor discipline validator **PASS** · on-device **NOT TESTED** |
| Accessibility labels/traits/hints | implemented · Accessibility Inspector audit **NOT PERFORMED** |
| Contrast (WCAG 2.1 AA) | **PASS** — computed from real token values, 13 pairs |
| Compile status | **NOT AVAILABLE** (no Swift/iOS toolchain in the authoring environment) |
| Unit tests | **NOT ATTEMPTED** |
| Host integration status | **NOT INTEGRATED** — host-independent by design |

## 2. Inspected host application (reference only — not a supported target)

| Field | Value |
|---|---|
| Host | 8 Ball Pool · `com.miniclip.8ballpoolmult` |
| Host version | 56.30.0 (5328) |
| Host architecture | arm64 only (single slice, no arm64e, no armv7) |
| Host minimum iOS | 13.0 |
| Host SDK | iphoneos26.2 (Xcode 17C52) |
| Host device families | iPhone + iPad (`UIDeviceFamily [1,2]`) |
| Host orientations | landscape only, `UIRequiresFullScreen = true` |
| Host UI technology | Cocos2d-x / CocosBuilder (`.ccbi`) + Spine, **not** UIKit |
| Host localisations | 17 (`ar` included) |
| Artifact integrity | DRM-stripped; unsigned framework injected post-signing; no provisioning profile |
| MR. SPICY integration status | **BLOCKED — authorisation + source limitation** |
| Build status with MR. SPICY | **NOT ATTEMPTED** |
| Installation test | **INSTALLATION TEST NOT PERFORMED** |

Technical note, independent of the authorisation block: the host's interface is a Cocos2d-x scene
graph rendered through OpenGL ES/Metal, not a UIKit view hierarchy. A UIKit layer could only ever
sit in a separate window/overlay above it; it could not restyle the game's own UI. Any claim that
this design system "redesigns the app's interface" would be false.

## 3. Compatibility matrix template for a real integration

Copy this into `compatibility/` per release and fill in only measured values.

| Field | Value |
|---|---|
| MR. SPICY version | |
| Host application + version | |
| Host architecture | |
| Minimum iOS | |
| Maximum iOS tested | |
| Device families tested (iPhone / iPad) | TESTED / NOT TESTED |
| Orientation support tested | |
| English | PASS / FAIL |
| Arabic | PASS / FAIL |
| RTL | PASS / FAIL |
| Accessibility audit | PASS / FAIL / PARTIAL |
| Integration status | |
| Build status | |
| Signing status | |
| Installation test status | |
| Known limitations | |

## 4. Known limitations of v1.0.0

1. Not compiled, not run, not screenshot-tested anywhere — all runtime behaviour is
   design-verified only.
2. No entitlement/account/licence components exist (deliberate scope exclusion).
3. `UIButton.contentEdgeInsets` is deprecated on iOS 15+ (warning expected, behaviour intact).
4. The `ExistentialAny` upcoming-feature flag requires Swift 5.9+.
5. SF Symbols are used for component icons; on iOS 13 a handful of newer symbol names
   (`figure.walk.motion`, `circle.lefthalf.filled`, `textformat.size`) resolve to nil and render as
   an empty icon slot. Supply your own images via the model if you must support iOS 13 exactly.
6. The light palette is provided but was never reviewed on a device.
