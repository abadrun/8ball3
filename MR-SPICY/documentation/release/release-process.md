# Release Process, Versioning and Rollback

## 1. Versioning (§53)

`MAJOR.MINOR.PATCH` for the MR. SPICY UI layer.

| Bump | When |
|---|---|
| MAJOR | a public API changes incompatibly, a component is removed/renamed, a token's meaning changes, or the integration protocols change |
| MINOR | new components, new tokens, new languages, new states — all backwards compatible |
| PATCH | fixes, copy changes, documentation, non-breaking adjustments |

The version lives in three places and must agree: `MR-SPICY/VERSION`,
`SpicyBrand.uiLayerVersion`, and the header comment block of each source file.

## 2. Release checklist

1. `bash validation/tools/verify_original.sh` → baseline unchanged.
2. `python3 validation/tools/validate_localization.py` → PASS.
3. `python3 validation/tools/validate_design_tokens.py` → PASS.
4. `python3 validation/tools/export_tokens.py` → refresh the preview exports.
5. On a Mac: build + run the XCTest suites; record real results.
6. Run the device/simulator matrix in `documentation/testing/test-plan.md`; record real results.
7. Update `CHANGELOG.md`, `VERSION`, `SpicyBrand.uiLayerVersion`,
   `versions/mr-spicy/<version>.md`, `compatibility/compatibility-matrix.md`.
8. If an authorised app is being shipped: archive, export, then
   `python3 validation/tools/verify_release_ipa.py "Mr Spicy.ipa" output/`.
9. Fill `output/` with: `Mr Spicy.ipa`, `Mr Spicy.sha256`, `release-manifest.json`,
   `validation-report.md`, `build-report.md`, `compatibility-report.md`,
   `changed-files-report.md`.
10. Tag the commit `mr-spicy-ui/<version>`.

A release is **not** declared complete while any item in
`validation/quality-gate-checklist.md` is unevaluated. Blocked items must be stated as blocked,
not quietly dropped.

## 3. Release manifest contents (§55)

`verify_release_ipa.py` emits all of it from the real artifact: UI-layer version, host version,
build identifier, IPA filename, SHA-256, generation time, minimum iOS, device family,
architectures, framework and extension inventory, localisations, unsigned-binary list, signing
status, installation status, validation status and the full per-check table.
Any field it cannot prove is reported as `NOT VERIFIED`, never guessed.

## 4. History and rollback (§61/§62)

* Never delete a previous release, artifact, manifest or compatibility record.
* Every release keeps: the host record, the UI-layer version record, the release manifest, the
  validation report and the changelog entry.
* Rollback = check out the previous tag and ship the previous artifact; the previous compatibility
  data is already next to it.
* The baseline artifact is recoverable from Git at commit `9695a47` and verified by
  `original/checksums/original-ipa.sha256`.

## 5. Change-management record (§41)

Every change in this release:

| File | Component | Change | Reason | Ownership | Confidence | Expected effect | Validation | Rollback |
|---|---|---|---|---|---|---|---|---|
| `SpicyTheme.swift` | MR. SPICY UI | centralised design tokens | one visual source of truth | MR. SPICY | HIGH | consistent styling | `validate_design_tokens.py` PASS | git revert |
| `SpicyLocalization.swift` + `*.lproj` | MR. SPICY UI | EN/AR tables, typed keys, fallback | no hard-coded copy, detectable gaps | MR. SPICY | HIGH | full bilingual UI | `validate_localization.py` PASS | git revert |
| `SpicyLayout.swift` | MR. SPICY UI | RTL + safe area + responsive metrics | genuine mirroring, no fixed sizes | MR. SPICY | HIGH | correct layout in both directions | anchor-discipline gate PASS | git revert |
| `SpicyState.swift` | MR. SPICY UI | explicit state machine | removes scattered booleans | MR. SPICY | HIGH | unreachable invalid states | unit tests (written, not run) | git revert |
| `Components/*.swift` | MR. SPICY UI | reusable component set | no duplicated UI code | MR. SPICY | HIGH | consistent, accessible controls | static gates PASS | git revert |
| `assets/**` | MR. SPICY brand | generated logo/icon variants | required asset slots | MR. SPICY | HIGH | correct rendering at all scales | `assets/SHA256SUMS` | delete + regenerate |
| `validation/tools/*` | tooling | audit + QA gates | reproducibility | MR. SPICY | HIGH | verifiable claims | self-verifying runs | git revert |
| `original/**`, `documentation/**` | audit | manifests + reports | preservation and traceability | MR. SPICY | HIGH | auditable baseline | `verify_original.sh` PASS | regenerate from the IPA |
| `8-ball-pool-i3rby-IPAOMTK.COM.ipa` | baseline | **none** | immutable | third party | HIGH | unchanged | SHA-256 verified | n/a |
| `logo.png` | brand | **none** | immutable source asset | MR. SPICY | HIGH | unchanged | SHA-256 verified | n/a |
