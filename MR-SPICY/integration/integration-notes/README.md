# Integration Notes

## 1. Current integration status

**No host integration exists in this repository, and none was attempted.**

| Candidate host | Status | Reason |
|---|---|---|
| `pool.app` (8 Ball Pool 56.30.0) from the supplied IPA | **BLOCKED — authorisation + source limitation** | third-party commercial app, no source, no rights, no signing identity, DRM-stripped copy, already tampered with an injected cheat framework. The only technical route would be injecting another unsigned dylib — prohibited. |
| Your own / a client's authorised app | **SUPPORTED** | follow §3 below |

## 2. The integration boundary

```
┌───────────────────────────────┐
│ HOST APPLICATION              │
│  (owns: data, services,       │
│   authorisation, state)       │
└──────────────┬────────────────┘
               │ SpicyOverlayDataSource   (host → UI: what to show)
               │ SpicyOverlayDelegate     (UI → host: what the user did)
┌──────────────▼────────────────┐
│ MR. SPICY UI LAYER            │
│  Theme · Components ·         │
│  Localisation · Assets ·      │
│  State · Accessibility        │
└───────────────────────────────┘
```

Rules that keep the layer reusable:

1. The UI layer **never** reads host globals, singletons or private APIs.
2. The UI layer **never** invents state. No data source entry → nothing rendered.
3. The host **never** imports MR. SPICY internals; it only uses the public protocols, the controller,
   `SpicyL10n` and the theme.
4. Host-version-specific code lives in `integration/adapters/<host>-<version>/`, never in
   `mr-spicy-ui/Sources/`.

## 3. Minimal authorised integration

```swift
import MrSpicyUI

final class SpicyAdapter: NSObject, SpicyOverlayDataSource, SpicyOverlayDelegate {

    // Host → UI. Tiles are navigation only; the host decides what exists.
    func spicyOverlayTiles(_ c: SpicyOverlayViewController) -> [SpicyFeatureTile.Model] {
        [
            .init(id: "settings", titleKey: .settingsTitle,  systemImageName: "gearshape"),
            .init(id: "language", titleKey: .settingsLanguage, systemImageName: "globe"),
            .init(id: "help",     titleKey: .settingsHelp,    systemImageName: "questionmark.circle",
                  state: helpAvailable ? .default : .disabled),
            .init(id: "about",    titleKey: .aboutTitle,      systemImageName: "info.circle"),
        ]
    }

    // Only return a status the host can actually prove.
    func spicyOverlayStatus(_ c: SpicyOverlayViewController) -> (text: String, kind: SpicyStatusBadge.Kind)? {
        guard let status = session.currentStatus else { return nil }
        return (status.displayText, status.isHealthy ? .success : .warning)
    }

    // UI → host.
    func spicyOverlay(_ c: SpicyOverlayViewController, didSelectTile model: SpicyFeatureTile.Model) {
        switch model.id {
        case "settings": c.presentSettings(SpicySettingsViewController())
        case "language": c.presentModal(.info(titleKey: .languageTitle,
                                              messageKey: .settingsLanguageHint), kind: .language)
        case "help":     router.showHelp()
        default:         break
        }
    }
}
```

Presenting it:

```swift
let overlay = SpicyOverlayViewController()
overlay.dataSource = adapter
overlay.delegate   = adapter
present(overlay, animated: true) { overlay.send(.open) }
```

## 4. Integration checklist

- [ ] You are authorised to modify and ship the host application.
- [ ] The package is linked through SwiftPM (no source copied into the host).
- [ ] An adapter exists under `integration/adapters/<host>-<version>/`.
- [ ] The host supplies every state the UI displays; nothing is hard-coded or faked.
- [ ] `SpicyL10n` language selection is wired to the host's own language preference if it has one.
- [ ] The overlay is presented in a window/context that respects the host's own safe areas.
- [ ] `validate_localization.py` and `validate_design_tokens.py` run in the host's CI.
- [ ] The compatibility matrix is updated with **measured** results.

## 5. What integration must never mean

Injecting a dylib into an application you do not own · patching a Mach-O · re-signing someone else's
app · hooking anti-cheat, licensing or payment paths · rendering an entitlement state that no
authorising service produced · hiding functionality from a game's operator. Any of these turns an
integration into an attack; the project stops and reports instead.
