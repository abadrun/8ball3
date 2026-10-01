# Test Plan & Current Test Status

Vocabulary per §56: `DONE`, `NOT DONE`, `NOT AVAILABLE`, `NOT ATTEMPTED`,
`BLOCKED BY SOURCE LIMITATION`, `REQUIRES REVIEW`, `PASS`, `FAIL`, `PARTIAL`.

## 1. What was actually executed in this environment

| Test | Tool | Result |
|---|---|---|
| Baseline artifact integrity (IPA + logo + manifests) | `verify_original.sh` | **PASS** |
| IPA archive/bundle/Mach-O/signing inspection | `inspect_ipa.py` | **DONE** — 3,505 entries, 31 Mach-O images |
| Structural IPA validation (baseline record) | `verify_release_ipa.py` | **FAIL — expected**: unsigned injected binary, no provisioning profile |
| Localisation parity, orphans, empties, duplicates, format specifiers, Arabic-script, hard-coded strings | `validate_localization.py` | **PASS** (0 failures, 0 warnings) |
| Design-token discipline (no literals outside the theme) | `validate_design_tokens.py` | **PASS** |
| WCAG 2.1 contrast on 13 colour pairs | `validate_design_tokens.py` | **PASS** |
| 44 pt minimum touch-target token | `validate_design_tokens.py` | **PASS** |
| Reduce Motion honoured in the motion layer | `validate_design_tokens.py` | **PASS** |
| RTL anchor discipline (no left/right anchors) | `validate_design_tokens.py` | **PASS** |
| Token/string export determinism for the preview | `export_tokens.py` | **DONE** |

Environment: Linux x86-64, Python 3, no Swift toolchain, no Xcode, no simulator, no iOS device.

## 2. What could not be executed here

| Test | Status | Blocker |
|---|---|---|
| `swift build` / Xcode compile of `MrSpicyUI` | **NOT AVAILABLE** | UIKit target cannot build on Linux; no macOS/Xcode |
| XCTest suites (`SpicyStateMachineTests`, `SpicyLocalizationTests`, `SpicyThemeAndLayoutTests`) | **NOT ATTEMPTED** | no toolchain |
| Simulator screenshots / snapshot tests | **NOT AVAILABLE** | no simulator |
| On-device run, launch, memory, Instruments | **NOT AVAILABLE** | no device |
| IPA build, signing, provisioning, installation | **BLOCKED** | see `SCOPE-AND-BOUNDARIES.md` and `output/README.md` |

**No result in this repository is extrapolated from these untested items.**

## 3. Test plan for an engineer with a Mac

### 3.1 Build & unit tests

```bash
cd MR-SPICY/mr-spicy-ui
xcodebuild -scheme MrSpicyUI -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild test -scheme MrSpicyUI -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected: `SpicyStateMachineTests` (10 cases) pass on any toolchain;
`SpicyLocalizationTests` (7) and `SpicyThemeAndLayoutTests` (11) require a simulator.

### 3.2 Localisation QA matrix

| Check | English | Arabic |
|---|---|---|
| All labels resolve (no `⟦key⟧`) | ☐ | ☐ |
| No truncation at default text size | ☐ | ☐ |
| No truncation at `.accessibilityExtraExtraExtraLarge` | ☐ | ☐ |
| Text alignment natural (leading) | ☐ | ☐ |
| Header brand/control sides correct | ☐ left/right | ☐ right/left |
| Tile grid fill order | ☐ L→R | ☐ R→L |
| Chevrons point in the reading direction | ☐ | ☐ |
| Non-directional icons **not** mirrored | ☐ | ☐ |
| Modal layout mirrored, actions in order | ☐ | ☐ |
| Language switch applies with no restart | ☐ | ☐ |

### 3.3 Responsive / safe-area matrix

| Device class | Portrait | Landscape | Checks |
|---|---|---|---|
| iPhone SE (375×667, no notch) | ☐ | ☐ | panel fits, 2–3 tile columns, no clipping |
| iPhone 15 (393×852, Dynamic Island) | ☐ | ☐ | header clear of the island, home-indicator inset respected |
| iPhone 15 Pro Max (430×932) | ☐ | ☐ | panel capped at 520 pt, centred |
| iPad (1024×768+) | ☐ | ☐ | up to 6 tile columns, modal capped at 420 pt |
| Split view / Slide Over | ☐ | ☐ | width class recalculation, no overflow |

### 3.4 Accessibility matrix

| Check | Status |
|---|---|
| VoiceOver: every control has a label; traits correct (button/selected/notEnabled/header) | ☐ |
| VoiceOver: modal traps focus (`accessibilityViewIsModal`) and announces on present | ☐ |
| VoiceOver: reading order follows the mirrored layout in Arabic | ☐ |
| Dynamic Type: all sizes from xSmall to AX5 without clipping | ☐ |
| Dynamic Type: rows switch to stacked layout at AX sizes | ☐ |
| Reduce Motion: no animation, no visual jump, final state correct | ☐ |
| Touch targets ≥ 44×44 (Accessibility Inspector audit) | ☐ |
| Contrast audit in Accessibility Inspector matches the computed table | ☐ |

### 3.5 Regression matrix (per release)

Launch · overlay open/close · minimise/expand · modal present/dismiss ×10 (leak check) ·
settings open/close · language switch EN→AR→EN ×5 · rotate in every state ·
background/foreground · memory-warning handling (brand cache purge) · repeated grid rebuilds.

Run the last three under Instruments (Allocations + Leaks). Record real numbers in
`validation/validation-report.md`; do not copy expectations from this plan into results.
