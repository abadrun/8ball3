# Component Reference — MR. SPICY UI 1.0.0

Every component: dark-first, token-driven, Dynamic-Type-ready, RTL-mirroring, VoiceOver-labelled.

## Core

| Type | Purpose |
|---|---|
| `SpicyTheme` | all design tokens: `Color`, `Spacing`, `Radius`, `Stroke`, `Typography`, `Size`, `Shadow`, `Opacity`, `Motion` |
| `SpicyL10n` / `SpicyStringKey` | centralised localisation, 58 typed keys, fallback + missing-key reporting |
| `SpicyLanguage` | `.english` / `.arabic`, endonym, layout direction, locale, system resolution |
| `SpicyLayoutDirection` | recursive RTL mirroring, directional images, natural alignment |
| `SpicyLayoutMetrics` | width class, landscape, iPad, safe-area-aware insets, tile columns, modal width, stacked-row threshold |
| `SpicyStateMachine` | pure reducer over the presentation states |
| `SpicyContentState<Value>` | idle / loading / success / failure / unavailable |
| `SpicyControlState` | isEnabled · isSelected · isBusy |
| `SpicyBrand` | cached logo access, `purgeCaches()` |

## Views

### `SpicyHeaderView`
Brand mark · title · optional subtitle · optional status badge · settings / minimise / close.
Configurable per instance; delegate callbacks for each control. Mirrors fully in RTL. VoiceOver
reads the title block as one `.header` element, then the controls.

### `SpicyOverlayViewController`
Floating panel: header + scrollable content + responsive tile grid, capped at 520 pt, pinned inside
the safe area, centred. Owns the state machine, the single modal presenter and the settings child
controller. Purges brand caches on memory warning.

### `SpicyFeatureTile` / `SpicyFeatureTileGrid`
Circular icon tile with title. States: default, selected, disabled, busy. Traits `.button`,
`.selected`, `.notEnabled`; value announces "Selected"/"Loading…". The grid computes 2–6 columns
from the available width and rebuilds only when that count changes.

### `SpicyModalView`
The only dialog implementation. Title, message, icon, custom content, primary/secondary actions,
close button, configurable scrim dismissal. Tones: neutral, success, error, loading.
Presets: `.info`, `.confirmation`, `.loading`, `.success`, `.error`.
`accessibilityViewIsModal = true`; posts `.screenChanged` on present.

### `SpicySettingRow` / `SpicySettingGroup`
Accessories: `.toggle`, `.value`, `.disclosure`, `.informational`, `.none`.
Rows become vertical stacks at accessibility text sizes. Groups draw hairline separators inside one
card. Toggles announce their new value.

### `SpicyButton`
Styles: primary, secondary, ghost, destructive. Sizes: regular (44 pt), compact (36 pt).
Busy state swaps the label for a spinner and disables interaction. Press feedback is a 0.98 scale.

### `SpicyStatusBadge`
Pill with a dot: neutral, success, warning, danger, info. Height follows its own bounds, so it
scales with Dynamic Type.

### `SpicyCard` / `SpicySectionHeader`
Surface container with flat / raised / floating elevation and configurable padding; uppercase
section caption with the `.header` trait.

## Not included (deliberately)

No account, PRO, licence, subscription, entitlement, payment, ad-countdown or unlock component.
See `../../SCOPE-AND-BOUNDARIES.md` §3.
