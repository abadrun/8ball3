# Validation Report — MR. SPICY 1.0.0

Every result below is the real output of a command that was executed in this environment.
Nothing is projected, assumed or copied from a plan.

Environment: Linux x86-64 · Python 3 · ImageMagick · **no Swift toolchain, no Xcode, no simulator,
no iOS device, no signing identity**.

---

## 1. Baseline preservation

```
$ bash MR-SPICY/validation/tools/verify_original.sh
8-ball-pool-i3rby-IPAOMTK.COM.ipa: OK
logo.png: OK
archive-manifest.csv: OK          archive-manifest.json: OK
bundle-manifest.json: OK          frameworks.json: OK
info-plist-snapshot.json: OK      localization.json: OK
original-ipa-structural-manifest.json: OK
plugins.json: OK                  signing.json: OK
BASELINE INTEGRITY: PASS
```

| Check | Result |
|---|---|
| Original IPA byte-for-byte unchanged (`59607b41…c2f8`) | **PASS** |
| Brand asset unchanged (`2056971c…4dc9`) | **PASS** |
| All generated manifests match their recorded digests | **PASS** |
| Original IPA modified by this project | **NO** |

## 2. Artifact inspection

```
$ python3 MR-SPICY/validation/tools/inspect_ipa.py 8-ball-pool-i3rby-IPAOMTK.COM.ipa \
          MR-SPICY/original/manifests
{ "ipa_sha256": "59607b4177f8ffdf36649d9bb3b0c5900d39f5b6b3eaa0c6e351ba353a58c2f8",
  "ipa_size": 98576945, "entries": 3505, "mach_o_binaries": 31,
  "frameworks": 26, "plugins": 4 }
```

Status: **DONE**. Findings: `../documentation/audit/ipa-inspection-report.md`.

## 3. Structural validation of the baseline artifact

```
$ python3 MR-SPICY/validation/tools/verify_release_ipa.py 8-ball-pool-i3rby-IPAOMTK.COM.ipa …
{ "result": "FAIL",
  "failed": ["all Mach-O images signed", "embedded.mobileprovision"] }
```

**FAIL is the correct and expected outcome** for this input, and it is reported as evidence, not as a
defect to be "fixed": the bundle contains an unsigned injected framework
(`Frameworks/libloader.framework/libloader`) and has no provisioning profile. Ten other structural
checks PASS. Full table: `original-ipa-structural-validation.md`.

## 4. Localisation gate

```
$ python3 MR-SPICY/validation/tools/validate_localization.py
{ "tables": { "ar": 58, "en": 58 }, "declared_keys": 58,
  "failures": [], "warnings": [], "result": "PASS" }
```

| Check | Result |
|---|---|
| Every `SpicyStringKey` present in `en` | **PASS** |
| Every `SpicyStringKey` present in `ar` | **PASS** |
| No orphan keys in either table | **PASS** |
| No empty values, no duplicate keys | **PASS** |
| Format-specifier parity `en` ↔ `ar` | **PASS** |
| Arabic values actually in Arabic script (brand allow-list aside) | **PASS** |
| No hard-coded display strings in sources | **PASS** |

## 5. Design-system gate

```
$ python3 MR-SPICY/validation/tools/validate_design_tokens.py
{ "parsed_colour_tokens": 20, "token_discipline": "PASS",
  "minimum_touch_target": 44, "reduce_motion_honoured": true,
  "directional_anchors": "PASS", "failures": [], "result": "PASS" }
```

| Contrast pair | Ratio | Required | Result |
|---|---:|---:|---|
| textPrimary / background | 19.79 | 4.5 | PASS |
| textPrimary / surface | 18.40 | 4.5 | PASS |
| textPrimary / surfaceElevated | 17.00 | 4.5 | PASS |
| textSecondary / surface | 7.26 | 4.5 | PASS |
| textSecondary / surfaceElevated | 6.71 | 4.5 | PASS |
| textTertiary / surface | 3.97 | 3.0 | PASS |
| primaryTint / surface | 5.64 | 4.5 | PASS |
| primaryTint / surfaceElevated | 5.21 | 4.5 | PASS |
| success / surface | 7.72 | 3.0 | PASS |
| warning / surface | 9.02 | 3.0 | PASS |
| danger / surface | 5.64 | 3.0 | PASS |
| info / surface | 5.00 | 3.0 | PASS |
| textOnPrimary / primary | 5.56 | 4.0 | PASS |

Two real defects were found by this gate during development and fixed:
a hard-coded corner radius in `SpicyStatusBadge` (now `SpicyTheme.Radius.dot`) and a non-tokenised
`UIColor.white` for `textOnPrimary` (now `0xFFFFFF`, which also made it contrast-checkable).

## 6. Source-of-truth export

```
$ python3 MR-SPICY/validation/tools/export_tokens.py
{ "colors": 24,
  "scale_groups": {"Spacing":8,"Radius":8,"Size":12,"Opacity":4,"Motion":5,"Stroke":4},
  "languages": {"ar":58,"en":58} }
```

Status: **DONE**. The browser preview renders from these exports, so it cannot drift from
`SpicyTheme.swift` or the `.strings` tables.

## 7. Not validated

| Item | Status |
|---|---|
| Swift compilation | **NOT AVAILABLE** — no toolchain; UIKit cannot build on Linux |
| XCTest execution (28 cases written) | **NOT ATTEMPTED** |
| Simulator / device rendering, EN + AR | **NOT PERFORMED** |
| Rotation, safe-area and Dynamic Type behaviour on real hardware | **NOT PERFORMED** |
| VoiceOver and Accessibility Inspector audit | **NOT PERFORMED** |
| Memory / leak / performance measurement | **NOT PERFORMED** |
| IPA build, signing, provisioning, installation | **BLOCKED** — see `../SCOPE-AND-BOUNDARIES.md` |

## 8. Overall

| Dimension | Status |
|---|---|
| Original preservation | **PASS** |
| Inspection & classification | **DONE** |
| Repository structure & documentation | **DONE** |
| Design system & component source | **DONE (authored, uncompiled)** |
| English | **PASS** (static) |
| Arabic | **PASS** (static) |
| RTL | **PARTIAL** — implemented and statically enforced; not verified on device |
| Responsive layout | **PARTIAL** — same reason |
| Accessibility | **PARTIAL** — contrast and targets verified statically; VoiceOver untested |
| Build / signing / installation | **NOT PERFORMED / BLOCKED** |
| Release artifact `Mr Spicy.ipa` | **NOT PRODUCED — BLOCKED** |
