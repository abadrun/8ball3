# MR. SPICY — UI System & Design Language

Version 1.0.0 · dark-first, compact, iOS-native.
Live preview: `mr-spicy-ui/Documentation/preview/index.html` (open with a static file server).

## 1. Brand

`logo.png` is a 1254×1254 opaque tile: near-black canvas (`rgb(5,3,5)`), glossy red "S"
(`rgb(211,1,2)`), white "made by Spicy Lamar" signature bottom-right.

Because the mark is a **pre-composed tile**, the rules are:

| Rule | Reason |
|---|---|
| Always square, always `.scaleAspectFit`, never stretched | the mark has baked-in geometry and a signature |
| Always inside a rounded container (radius token `xs`–`m`) | matches the mark's own rounded canvas |
| Never recoloured, never used as a template/tint image | the gloss and signature would be destroyed |
| Minimum rendered size 28 pt | below that the signature becomes unreadable mush |
| Dark surfaces preferred; on light surfaces the tile keeps its dark canvas | it is self-contained, so it stays legible either way |

Generated variants (`assets/`): branding 1024/512/256/128/64, icon slots 180/167/152/120/87/80/76/60/58/40,
and the package imageset at @1x/@2x/@3x. All are proportional resamples of the original — no crops,
no re-compositions, no background removal.

## 2. Palette

Derived from the mark, not invented. Dark values are canonical; light values exist so the layer can
be embedded in a light-mode host.

| Token | Dark | Light | Use |
|---|---|---|---|
| `primary` | `#D30102` | `#D30102` | brand fills, selected borders |
| `primaryPressed` | `#A60103` | — | pressed state |
| `primaryTint` | `#FF4D52` | — | brand text/icons on dark (5.6:1) |
| `primaryWash` | `rgba(211,1,2,.14)` | — | selected tile/row fill |
| `background` | `#0A0A0B` | `#F4F4F6` | behind everything |
| `surface` | `#141416` | `#FFFFFF` | cards, groups |
| `surfaceElevated` | `#1C1C1F` | `#FFFFFF` | header, modal, floating panel |
| `surfaceSunken` | `#0F0F11` | `#EDEDF1` | flat/recessed areas |
| `separator` / `border` | `#2A2A2E` / `#303036` | `#DEDEE3` / `#D2D2D9` | hairlines, outlines |
| `textPrimary` | `#FFFFFF` | `#101014` | titles, body |
| `textSecondary` | `#A2A2AA` | `#5B5B66` | supporting copy |
| `textTertiary` | `#74747C` | `#8A8A95` | section captions |
| `textDisabled` | `#55555C` | `#AAAAB3` | disabled copy |
| `success` / `warning` / `danger` / `info` | `#2FBF71` / `#F5A524` / `#FF4D52` / `#3B82F6` | semantic states |

### Measured contrast (WCAG 2.1, dark palette)

Computed from the real token values by `validation/tools/validate_design_tokens.py` — all PASS:

| Foreground | Background | Ratio | Required |
|---|---|---:|---:|
| textPrimary | background | 19.79 | 4.5 |
| textPrimary | surface | 18.40 | 4.5 |
| textPrimary | surfaceElevated | 17.00 | 4.5 |
| textSecondary | surface | 7.26 | 4.5 |
| textSecondary | surfaceElevated | 6.71 | 4.5 |
| textTertiary | surface | 3.97 | 3.0 |
| primaryTint | surface | 5.64 | 4.5 |
| primaryTint | surfaceElevated | 5.21 | 4.5 |
| success / warning / danger / info | surface | 7.72 / 9.02 / 5.64 / 5.00 | 3.0 |
| textOnPrimary | primary | 5.56 | 4.0 |

Note the brand red `#D30102` is used as a **fill**, never as text on dark — `primaryTint #FF4D52`
exists precisely so brand-coloured text stays readable.

## 3. Scales

| Scale | Values |
|---|---|
| Spacing (4-pt grid) | xxs 2, xs 4, s 8, m 12, l 16, xl 24, xxl 32, xxxl 40 |
| Radius | dot 3, xs 6, s 10, m 14, l 20, xl 28 (+ `pill` sentinel) |
| Icon sizes | xs 14, s 18, m 22, l 28 |
| Control sizes | touch target 44, control 44, compact control 36, header 56, tile 76, badge 22 |
| Width caps | modal 420, overlay panel 520 |
| Stroke | hairline `1/scale`, thin 1, medium 1.5, focus 2 |
| Opacity | disabled .38, pressed .72, scrim .55, subtle .6 |
| Motion | fast .16s, standard .24s, slow .36s, spring damping .86 |

Typography is built on `UIFontMetrics` for every style (title 20/bold, headline 17/semibold,
body 15, callout 14, caption 12, button 16/semibold), so Dynamic Type works without per-component work.

## 4. Components

| Component | States | Notes |
|---|---|---|
| `SpicyHeaderView` | title, optional subtitle, optional status badge, settings/minimise/close | mirrors in RTL; VoiceOver reads brand+title as one header element then the controls |
| `SpicyOverlayViewController` | closed, minimised, expanded, settingsPresented, modalPresented | owns the state machine; panel capped at 520 pt and pinned inside the safe area |
| `SpicyFeatureTile` | default, selected, disabled, busy | 44 pt minimum target; `.selected` / `.notEnabled` traits; hint string |
| `SpicyFeatureTileGrid` | 2–4 columns (phone), up to 6 (iPad) | columns computed from available width; rebuilds only on column change |
| `SpicyModalView` | info, confirmation, loading, success, error, custom content | **the only dialog implementation**; `accessibilityViewIsModal`; scrim dismiss configurable |
| `SpicySettingRow` | toggle, value, disclosure, informational | switches to a vertical stack at accessibility text sizes |
| `SpicySettingGroup` | grouped card with hairline separators | |
| `SpicyButton` | primary, secondary, ghost, destructive × enabled/disabled/busy | spinner replaces label while busy, control becomes non-interactive |
| `SpicyStatusBadge` | neutral, success, warning, danger, info | pill height tracks its own bounds |
| `SpicyCard` / `SpicySectionHeader` | flat, raised, floating | elevation tokens only |

### Deliberately absent

No account, PRO, licence, subscription, entitlement, payment, ad-countdown or unlock component
exists in this library. That is a scope decision, not an omission — see
[`../../SCOPE-AND-BOUNDARIES.md`](../../SCOPE-AND-BOUNDARIES.md) §3.

## 5. Layout rules

* Every root surface pins to `safeAreaLayoutGuide` — status bar, notch, Dynamic Island and home
  indicator are respected by construction.
* `SpicyLayoutMetrics` classifies width as compact (≤375), regular (376–413) or wide (≥414), detects
  landscape and iPad, and folds `safeAreaInsets` into `contentInset`, so landscape side insets are
  handled without special-casing.
* No absolute positioning anywhere; no fixed frames; all constraints are directional
  (leading/trailing), which is what makes the Arabic mirror free.
* `prefersStackedRows` flips horizontal rows to vertical at `.accessibilityMedium` and above.

## 6. Motion

Modal in: 0.24 s spring, scale 0.96→1 + 12 pt rise, scrim fade. Modal out: 0.16 s.
Tile press: scale 0.94. Button press: scale 0.98 + 0.72 opacity. Minimise/expand: 0.24 s crossfade.
No looping animation exists in the library. With Reduce Motion enabled every duration resolves to 0
and the final state is applied immediately — same code path, no branching in components.
