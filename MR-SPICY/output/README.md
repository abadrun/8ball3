# `output/` — release artifacts

## Status: `Mr Spicy.ipa` was NOT produced

**BLOCKED — cannot be produced legitimately.**
This is a real status, not a placeholder, and not a failure that can be retried with different
tooling.

### Why

The only IPA that could be produced from the supplied input would be
`8-ball-pool-i3rby-IPAOMTK.COM.ipa` repackaged. That artifact is:

1. **A DRM-stripped copy of a commercial App Store application.**
   `com.miniclip.8ballpoolmult` 56.30.0 (5328), Apple Developer Team `HLSX4DMBX6`.
   `Info.plist` key `DecryptedBy = @FastDecryptBot …`, `SC_Info/` emptied, every Mach-O `cryptid = 0`.
   Repackaging and redistributing it is software piracy.

2. **Carrying an injected cheat payload.**
   `Frameworks/libloader.framework` — unsigned, appended as the last `LC_LOAD_DYLIB` of `pool` after
   signing. Its own strings describe aim/trajectory assistance, shot prediction, automated play,
   automated match queueing, a device-bound subscription-key/PRO scheme, and a "stream proof" mode
   that hides the overlay from spectators. Packaging that for distribution is prohibited by §48 of
   the project brief and is not something this project will do.

3. **Unsignable here in any case.**
   No signing identity, no provisioning profile, no `embedded.mobileprovision`, no Apple toolchain
   and no iOS device are available in this environment. Even a legitimate artifact would be reported
   as `SIGNING NOT PERFORMED` / `INSTALLATION TEST NOT PERFORMED`.

Fabricating an IPA file, a SHA-256 for it, a signing result or an installation result would violate
§46 and §66 ("never fabricate hashes / signing / installation / compatibility"). So this directory
intentionally stays empty of artifacts.

### What exists instead

| File | Content |
|---|---|
| `../validation/validation-report.md` | What was validated, with real tool output |
| `../documentation/build/build-report.md` | Build status, with the blocked steps enumerated |
| `../documentation/build/ipa-packaging-and-signing.md` | The exact, correct packaging/signing procedure for when there **is** a legitimately buildable host |
| `../compatibility/compatibility-matrix.md` | Tested vs untested, honestly separated |

### How this directory gets populated legitimately

When the MR. SPICY UI layer is embedded in an application **you are authorised to build and sign**:

1. Build that app with the `MrSpicyUI` package added (see `../documentation/build/build-report.md`).
2. Archive and export with your own Developer ID / distribution profile in Xcode.
3. Run `../validation/tools/verify_release_ipa.py "<exported>.ipa"` to produce
   `release-manifest.json`, the SHA-256 and a structural validation report.
4. Name the exported artifact exactly `Mr Spicy.ipa` and place it here together with
   `Mr Spicy.sha256`, `release-manifest.json`, `validation-report.md`, `build-report.md`,
   `compatibility-report.md` and `changed-files-report.md`.

The naming/packaging contract is already implemented by the verification tool; only an artifact you
are entitled to ship is missing.
