# IPA Packaging, Signing and Installation — Procedure and Current Status

## 0. Current status (do not skim past this)

| Item | Status |
|---|---|
| IPA produced by this project | **NONE** |
| Signing | **SIGNING NOT PERFORMED** |
| Provisioning | **NOT AVAILABLE** |
| Installation test | **INSTALLATION TEST NOT PERFORMED** |
| Supported iOS versions (claimed) | none claimed — nothing was built or run |
| Tested devices | none |

The procedure below is the correct process for an application **you are authorised to build, sign
and distribute**. It is documentation, not a record of work performed.

## 1. Packaging checklist (§34)

1. Build the authorised app with the `MrSpicyUI` package linked.
2. Validate the app bundle: `Info.plist` present and complete, executable name matches
   `CFBundleExecutable`, no stray files.
3. Validate resources: `Assets.xcassets` compiled into `Assets.car`, `en.lproj` + `ar.lproj` present,
   `CFBundleLocalizations` consistent.
4. Validate framework relationships: every `@rpath` dependency resolves inside
   `Frameworks/`; no absolute developer paths.
5. Validate architecture: `arm64` for device; confirm with `lipo -info`.
6. Validate `Info.plist`: identifier, versions, `MinimumOSVersion`, `UIDeviceFamily`, orientations,
   icon declarations, privacy usage strings for anything the app actually uses.
7. Validate nested components: each `.appex`/`.framework` has its own valid `Info.plist` and
   signature.
8. Validate signing state: every Mach-O signed with the same team; no unsigned images.
9. Validate entitlements: match the provisioning profile exactly.
10. Package `Payload/<App>.app` at the archive root — nothing else at the top level.
11. Generate the IPA (`xcodebuild -exportArchive`, not a hand-made zip, so the signature survives).
12. Calculate SHA-256.
13. Post-build inspection: run the verifier.
14. Compare against expected structure (before/after table).
15. Record the result in `validation/`.

Steps 2–9, 12, 13 are automated:

```bash
python3 MR-SPICY/validation/tools/verify_release_ipa.py "Mr Spicy.ipa" MR-SPICY/output
```

It writes `release-manifest.json`, `Mr Spicy.sha256` and `validation-report.md`, and fails on an
unsigned image, a missing provisioning profile, a broken `@rpath`, or a malformed payload root.

## 2. Correct build/export commands

```bash
xcodebuild -workspace App.xcworkspace -scheme App \
           -configuration Release -destination 'generic/platform=iOS' \
           -archivePath build/App.xcarchive archive

xcodebuild -exportArchive -archivePath build/App.xcarchive \
           -exportOptionsPlist ExportOptions.plist \
           -exportPath build/export
```

`ExportOptions.plist` must name a real team and a real method
(`development` / `ad-hoc` / `app-store-connect` / `enterprise`).

Then rename the exported artifact **exactly**:

```
Mr Spicy.ipa        (note: space, capital M, capital S)
Mr Spicy.sha256
```

## 3. Signing — what is and is not acceptable

**Acceptable:** your own Apple Developer identity and profile; a client's identity with written
authorisation; an enterprise profile for internal distribution you administer.

**Not acceptable, and not done here:** forging signatures, ad-hoc "fake signing" to defeat
validation, bypassing provisioning, re-signing someone else's application, patching code-signing
checks, or any workflow whose purpose is to install software the user is not entitled to run.

If no identity is available, report `SIGNING REQUIRES AUTHORIZED ENVIRONMENT` — never a success.

## 4. Installation reporting template (§58)

Fill in only from an actual run:

```
Device model:        …
iOS version:         …
Architecture:        arm64
Installation method: Xcode / TestFlight / MDM / Apple Configurator
Signing method:      development / ad-hoc / enterprise / App Store
Install result:      SUCCESS | FAILURE (reason)
Launch result:       …
UI result:           EN …, AR …, RTL …, rotation …
Known issues:        …
```

If it was not run: `INSTALLATION TEST NOT PERFORMED`.

## 5. The one thing this project will not do

Repackage `8-ball-pool-i3rby-IPAOMTK.COM.ipa` — a DRM-stripped build of a third-party commercial
game with an unsigned cheat framework injected after signing — under any filename, including
`Mr Spicy.ipa`. Reasons and evidence: `../../output/README.md`,
`../audit/ipa-inspection-report.md`.
