# Changelog

All notable changes to the MR-SPICY project. Semantic versioning (§53) applies to the
MR. SPICY UI layer; repository documentation follows the same release tags.

## [1.0.0] — initial release

### Added — audit & preservation
* Read-only inspection of the supplied baseline artifact `8-ball-pool-i3rby-IPAOMTK.COM.ipa`
  (3,505 entries, 31 Mach-O images, 26 frameworks, 4 app extensions, 17 localisations).
* Reproducible inspection tooling: `inspect_ipa.py`, `machoinfo.py` (fat/thin Mach-O, load commands,
  code-signature SuperBlob/CodeDirectory, entitlements), `verify_release_ipa.py`,
  `verify_original.sh`.
* Full manifests with per-entry SHA-256, ownership class and confidence level.
* Baseline preservation policy + integrity verification (`BASELINE INTEGRITY: PASS`).
* Component classification and the evidence behind it, including identification of
  `libloader.framework` as an unsigned, post-signing injected overlay.

### Added — MR. SPICY UI layer (v1.0.0)
* `SpicyTheme` — centralised tokens: 24 colours (dark + light), 8 spacing steps, 8 radii,
  12 size tokens, 4 stroke, 4 opacity, 5 motion values, Dynamic-Type-backed typography.
* `SpicyL10n` + `SpicyStringKey` — 58 type-safe keys, English + Arabic, fallback with
  missing-key reporting, locale-aware formatting, runtime language switching.
* `SpicyLayoutDirection` / `SpicyLayoutMetrics` — true RTL mirroring, safe-area-aware insets,
  width-class sizing, column computation, stacked-row threshold for accessibility text sizes.
* `SpicyStateMachine` — pure reducer over closed / minimised / expanded / settingsPresented /
  modalPresented, plus `SpicyContentState` and `SpicyControlState`.
* Components: `SpicyButton`, `SpicyCard`, `SpicySectionHeader`, `SpicyHeaderView`,
  `SpicyStatusBadge`, `SpicyFeatureTile`, `SpicyFeatureTileGrid`, `SpicyModalView` (single modal
  system), `SpicySettingRow`, `SpicySettingGroup`.
* Containers: `SpicyOverlayViewController`, `SpicySettingsViewController`.
* `SpicyBrand` — cached brand asset access, purge on memory warning.
* Brand assets generated from `logo.png`: branding 1024/512/256/128/64, icon slots
  180/167/152/120/87/80/76/60/58/40, package imageset @1x/@2x/@3x.
* XCTest suites (28 cases) for the state machine, localisation and theme/layout.

### Added — validation
* `validate_localization.py` — key parity, orphans, empties, duplicates, format-specifier parity,
  Arabic-script detection, hard-coded display strings. **PASS**.
* `validate_design_tokens.py` — token discipline, WCAG 2.1 contrast on 13 pairs, 44 pt touch target,
  Reduce Motion, RTL anchor discipline. **PASS**.
* `export_tokens.py` — exports tokens and strings from the Swift source of truth.
* Browser design-system preview rendered from those exports (EN/AR, dark/light, text-size toggle).

### Added — documentation
* Repository inventory, IPA inspection report, architecture, UI system, localisation & RTL,
  test plan, build report, packaging & signing procedure, release process, future-host-update
  workflow, compatibility matrix, validation report, quality-gate checklist, change log,
  scope & boundaries.

### Fixed (found by the validation gates during development)
* Hard-coded corner radius in `SpicyStatusBadge` → `SpicyTheme.Radius.dot`.
* `textOnPrimary` declared as `UIColor.white` → tokenised `0xFFFFFF`, making it contrast-checkable
  (measured 5.56:1 on brand red).

### Not done — blocked (reasons in `SCOPE-AND-BOUNDARIES.md`)
* Redesign of the injected overlay's UI, and its PRO / licence / account / ad-countdown surfaces —
  **AUTHORISATION BOUNDARY**.
* Integration into `pool.app` — **AUTHORISATION + SOURCE LIMITATION**.
* `output/Mr Spicy.ipa` — **CANNOT BE PRODUCED LEGITIMATELY**.
* Signing — **SIGNING NOT PERFORMED**. Installation — **INSTALLATION TEST NOT PERFORMED**.
* Swift compilation and XCTest execution — **NOT AVAILABLE** (no macOS/Xcode toolchain).

### Unchanged
* `8-ball-pool-i3rby-IPAOMTK.COM.ipa` — byte-for-byte identical to the supplied artifact.
* `logo.png` — unmodified; all variants are separate generated files.
