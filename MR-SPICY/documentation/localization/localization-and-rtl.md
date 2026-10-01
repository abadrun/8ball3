# Localisation & RTL

Languages: **English** (`en`, base + fallback) and **Arabic** (`ar`).
Automated gate: `validation/tools/validate_localization.py` → **PASS** (58 keys × 2 languages, 0 failures, 0 warnings).

## 1. Architecture

```
SpicyStringKey (enum, 58 cases)      ← type-safe key list, the contract
        │
SpicyL10n.string(_:)                 ← single entry point for all UI text
        │
Resources/en.lproj/MrSpicy.strings   ← base table (fallback)
Resources/ar.lproj/MrSpicy.strings   ← Arabic table
```

Rules the code obeys:

* **No literal display text in components.** Every label, button title, accessibility label and hint
  resolves through `SpicyL10n`. The validator greps for violations.
* **Fallback is explicit.** A key missing from Arabic falls back to English *and* calls
  `missingKeyHandler` (assertion in DEBUG, injectable in release/CI). In DEBUG a truly missing key
  renders as `⟦key⟧` so it is impossible to miss during QA.
* **Runtime language switching, no restart.** `SpicyL10n.setLanguage(_:)` persists the choice and
  posts `SpicyL10n.languageDidChangeNotification`; every component observes it, re-resolves its text
  and re-applies alignment, and the container re-applies layout direction.
* **Locale-aware formatting.** `number(_:)` and `string(_:_:)` format with the active language's
  `Locale`, so digits and formats follow the language, not the device region.
* **Pluralisation** goes through `plural(_:count:)`, which expects a `.stringsdict` entry. None is
  needed by the v1.0.0 string set; the hook exists so plurals never get hand-rolled later.

## 2. Arabic is a real RTL layout

Translation alone is explicitly *not* the deliverable. Mirroring is structural:

| Mechanism | Where |
|---|---|
| `SpicyLayoutDirection.apply(_:to:)` sets `semanticContentAttribute = .forceRightToLeft` recursively over the whole subtree | container, settings, every modal on present |
| All constraints use **leading/trailing** anchors, never left/right | enforced by `validate_design_tokens.py` (fails the build on `leftAnchor`/`rightAnchor`) |
| `UIStackView` arrangement flips automatically with the semantic attribute | header control cluster, tile rows, action stacks |
| Directional icons use `imageFlippedForRightToLeftLayoutDirection()` | disclosure chevrons; non-directional glyphs (gear, globe, ✕) are deliberately **not** flipped |
| Text alignment resolves from the active language | `SpicyLayoutDirection.textAlignment(for:)` on every label |
| Modal content, actions and close button mirror with the card | `SpicyModalView.apply(_:)` re-applies direction |
| VoiceOver reading order follows the mirrored visual order | `accessibilityElements` set on the header; everything else inherits natural order |

What this produces in Arabic: brand mark on the **trailing** (right) edge, control cluster on the
**leading** (left) edge, tiles filling right-to-left, rows with the icon on the right and the
chevron on the left, pointing left.

## 3. Translation notes

* "MR. SPICY" stays in Latin script — it is a brand name (allow-listed in the validator, which
  otherwise fails any Arabic value containing no Arabic script).
* "English" stays as its endonym in the language picker, likewise allow-listed.
* Accessibility strings are translated too, not just visible labels.
* Arabic copy avoids transliterated English UI jargon: السمة (theme), تسهيلات الاستخدام
  (accessibility), اتجاه التخطيط (layout direction).

## 4. Validation performed

```
$ python3 validation/tools/validate_localization.py
{ "tables": {"ar": 58, "en": 58}, "declared_keys": 58,
  "failures": [], "warnings": [], "result": "PASS" }
```

Checks: key parity in both directions (missing + orphan), empty values, duplicate keys, format
specifier parity, Arabic-script presence per value, and hard-coded display strings in sources.

## 5. What has *not* been verified

| Item | Status |
|---|---|
| Rendering of Arabic text on a device/simulator | **NOT PERFORMED** — no Apple platform available |
| Visual truncation / clipping checks in Arabic at large Dynamic Type | **NOT PERFORMED** on device; mitigated by construction (multi-line labels, stacked rows, no fixed widths) |
| Arabic VoiceOver pronunciation pass | **NOT PERFORMED** |
| Bidi edge cases (Arabic text containing Latin brand names mid-sentence) | reviewed in the string table; **not** visually verified |

These are the first items in `documentation/testing/test-plan.md` for anyone with a Mac.

## 6. Adding a third language

1. Add the case to `SpicyLanguage` (and `SpicyLanguageCode` if the state machine must know about it).
2. Create `Resources/<code>.lproj/MrSpicy.strings` by copying `en.lproj` and translating.
3. Run `validate_localization.py` — it fails until parity is reached.
4. Run `export_tokens.py` to refresh the preview, which then shows the new column automatically.
