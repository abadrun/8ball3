# IPA Inspection Report

Artifact: `8-ball-pool-i3rby-IPAOMTK.COM.ipa`
SHA-256: `59607b4177f8ffdf36649d9bb3b0c5900d39f5b6b3eaa0c6e351ba353a58c2f8`
Size: 98,576,945 bytes · 3,505 archive entries (3,344 files) · 205,308,617 bytes uncompressed

Method: read-only. The archive was opened with Python's `zipfile`, entries were hashed by streaming,
and Mach-O images were parsed in memory. The IPA was never rewritten. Tooling:
`validation/tools/inspect_ipa.py` + `validation/tools/machoinfo.py`.
Raw output: `original/manifests/`.

---

## 1. Archive layout

```
Payload/
└── pool.app/                         ← single app bundle
    ├── pool                          ← main executable, Mach-O arm64, 81,963,248 B
    ├── Info.plist                    ← 66 keys
    ├── Frameworks/                   ← 25 .framework + 1 .dylib
    ├── PlugIns/                      ← 4 app extensions (.appex)
    ├── _CodeSignature/CodeResources  ← 1,089,386 B
    ├── SC_Info/.keep                 ← empty placeholder (see §6)
    ├── checksums/                    ← 30 per-device asset checksum plists (game-owned)
    ├── *.lproj/                      ← 17 host localisations
    ├── j1O1pP4cpnaLPxs2xoSf/         ← 20 opaque files, name is random (see §5)
    └── ~3,100 loose game resources   ← .png .plist .ccbi .mp3 .atlas .skel .ttf .car
```

No `iTunesMetadata.plist`, no `iTunesArtwork`, no `embedded.mobileprovision`.

### File-type distribution

| Type | Files | Bytes |
|---|---:|---:|
| `.png` | 1,326 | 21.9 MB |
| `.plist` | 819 | 26.6 MB |
| `.ccbi` (Cocos2d-x binary CCB scenes) | 688 | 1.7 MB |
| no extension (executables, dylibs, data) | 261 | 140.6 MB |
| `.mp3` | 142 | 5.0 MB |
| `.strings` | 83 | 0.03 MB |
| `.json` / `.atlas` / `.skel` (Spine animation) | 110 | 2.9 MB |
| `.car` (asset catalogues) | 6 | 4.6 MB |
| `.ttf` | 5 | 0.7 MB |

The `.ccbi` + `.atlas` + `.skel` mix identifies the host's UI as a **Cocos2d-x / CocosBuilder + Spine**
engine UI, i.e. the game's own interface is compiled scene data, not UIKit nibs/storyboards
(the only storyboard in the bundle is `Splash.storyboardc`).

---

## 2. Host application identity

| Key | Value |
|---|---|
| `CFBundleIdentifier` | `com.miniclip.8ballpoolmult` |
| `CFBundleDisplayName` / `CFBundleName` | 8 Ball Pool |
| `CFBundleExecutable` | `pool` |
| `CFBundleShortVersionString` | **56.30.0** |
| `CFBundleVersion` | **5328** |
| `MinimumOSVersion` | **13.0** |
| `DTSDKName` / `DTPlatformVersion` | `iphoneos26.2` / 26.2 |
| `DTXcode` / `DTXcodeBuild` | 2620 / 17C52 |
| `UIDeviceFamily` | `[1, 2]` → iPhone **and** iPad |
| Orientations (both idioms) | Landscape Left + Landscape Right **only** |
| `UIRequiresFullScreen` | `true` |
| `UIStatusBarHidden` | `true` |
| `CFBundleSupportedPlatforms` | `iPhoneOS` |
| `NSAppTransportSecurity` | `NSAllowsArbitraryLoads = true` |
| App Store `AppID` | 543186831 |

Publisher-identifying metadata (Apple Developer Team `HLSX4DMBX6`, `applinks:8bp.co`,
`applinks:poolbyminiclip.com`, application group `group.com.miniclip.8ballpoolmult`) is embedded in
the main executable's entitlements. **The host application is a commercial third-party product; this
repository holds no rights to it.**

### Two Info.plist keys that are *not* original

| Key | Value | Interpretation | Confidence |
|---|---|---|---|
| `DecryptedBy` | `@FastDecryptBot - https://t.me/FastDecryptBot` | The App Store FairPlay encryption was removed by a third-party decryption service. Confirmed independently: every Mach-O in the bundle reports `cryptid = 0`. | HIGH |
| `NSUserTrackingUsageDescription` | "Used to bind your subscription key to this device and protect your activation." | This is not Miniclip ATT copy; it describes the **injected** component's own key-activation scheme. | HIGH |

---

## 3. Mach-O inventory

31 Mach-O images, **all single-slice `arm64`** (no armv7, no arm64e, no fat binaries).

| Component | Type | Min OS | Signed | Team | `cryptid` |
|---|---|---|---|---|---|
| `pool` | MH_EXECUTE | 13.0 | yes | HLSX4DMBX6 | 0 |
| `PlugIns/NotificationContent` | MH_EXECUTE | 13.0 | yes | HLSX4DMBX6 | 0 |
| `PlugIns/NotificationService` | MH_EXECUTE | 13.0 | yes | HLSX4DMBX6 | 0 |
| `PlugIns/PooliMessage` | MH_EXECUTE | 13.0 | yes | HLSX4DMBX6 | 0 |
| `PlugIns/PoolWidgetExtension` | MH_EXECUTE | 14.0 | yes | HLSX4DMBX6 | 0 |
| 24 advertising/analytics frameworks | MH_DYLIB | 11.0–13.0 | yes | HLSX4DMBX6 | 0 |
| `libswift_Concurrency.dylib` | MH_DYLIB | — | yes | HLSX4DMBX6 | 0 |
| **`Frameworks/libloader.framework/libloader`** | MH_DYLIB | 9.0 | **NO SIGNATURE** | — | 0 |

Third-party SDKs embedded by the publisher: AppLovinSDK, AdSurgeSDK, BigoADS, DTBiOSSDK (Amazon),
FBAudienceNetwork, InMobiSDK, MolocoSDK, OMSDK_Appodeal, Firebase (Core, Analytics, Crashlytics,
Installations, Sessions, RemoteConfigInterop, CoreInternal, CoreExtension), GoogleAppMeasurement
(+IdentitySupport), GoogleAdsOnDeviceConversion, GoogleDataTransport, GoogleUtilities, nanopb,
Promises, FBLPromises.

### App extensions

| Extension | Bundle ID | Extension point | Min OS |
|---|---|---|---|
| `NotificationContent.appex` | `…notificationContent` | `com.apple.usernotifications.content-extension` | 13.0 |
| `NotificationService.appex` | `…notificationService` | `com.apple.usernotifications.service` | 13.0 |
| `PooliMessage.appex` | `…PooliMessage` | `com.apple.message-payload-provider` | 13.0 |
| `PoolWidgetExtension.appex` | `…poolWidget` | `com.apple.widgetkit-extension` | 14.0 |

All four are intact, publisher-signed and unmodified as far as structure shows.

---

## 4. Host localisation inventory

`pool.app` ships 17 `.lproj` directories: `ar`, `de`, `eng`, `es`, `fr`, `hi`, `id`, `it`, `ja`, `ko`,
`kor`, `pt`, `pt-BR`, `pt-PT`, `ru`, `tr`, `vi`.

Note: the host **already ships Arabic** (`ar.lproj`). Further localisation inventory for nested
bundles is in `original/manifests/localization.json`.

---

## 5. The injected component — `libloader.framework`

| Property | Value |
|---|---|
| Path | `Payload/pool.app/Frameworks/libloader.framework/libloader` |
| Size | 11,493,804 bytes |
| `CFBundleIdentifier` | `com.appdome.libloader` |
| `CFBundleShortVersionString` | 1.0.0 |
| `MinimumOSVersion` (plist) | 11.0 · (Mach-O `LC_VERSION_MIN_IPHONEOS`) 9.0 |
| `LC_UUID` | `1a1bc909-4e7c-31a5-bd59-3ed3b7867064` |
| Code signature | **absent** (`LC_CODE_SIGNATURE` not present) |
| Links | UIKit, WebKit, JavaScriptCore, StoreKit, Security, AdSupport, CoreTelephony, AVFoundation, CFNetwork, libswiftCore/libswiftFoundation |

### Evidence of post-signing injection (HIGH confidence)

1. In `pool`, the load command
   `LC_LOAD_DYLIB @executable_path/Frameworks/libloader.framework/libloader` is command
   **#125 of 125 — the very last one**. Linker-emitted dylib commands are grouped with the other
   `@rpath/...` SDK commands (#37–#42); an appended trailing command is the signature of an
   `insert_dylib`-style post-link patch.
2. `libloader` carries **no code signature at all**, while all 30 other Mach-O images carry the
   publisher's Team ID `HLSX4DMBX6`.
3. Its `CFBundleIdentifier` (`com.appdome.libloader`) belongs to a different vendor namespace than
   every other component in the bundle, and its bundle contains no `PrivacyInfo.xcprivacy`, unlike
   every publisher-embedded framework.
4. `pool`'s own signature was generated **before** the injection, so it no longer matches the file
   content (see §6).

### What the component does (neutral classification)

`libloader` is **not** a loader stub and is **not** the Appdome shielding product its identifier
imitates. Clear-text string evidence inside the binary identifies an in-game overlay menu
("`GBModMenu`", `GBMenu*` view classes) that provides, among other things:

* aim/trajectory assistance and shot prediction;
* automated play and automated match queueing;
* a device-bound "subscription key" activation and PRO-entitlement scheme, with ad-watch-for-free-hours
  gating and remote key validation;
* a "stream proof" mode whose own description states that viewers see normal gameplay while the local
  user sees the overlay;
* local trace logs (`gb_autoplay_trace.jsonl`, `gb_breaklog_trace.jsonl`).

Classification: **unauthorised game-manipulation software (a cheat/mod menu) with its own paid
licensing layer**, injected into a DRM-stripped copy of a commercial App Store game.

This report records the finding neutrally and does not document the component's internals, hooks,
offsets or activation mechanism. No part of it has been reverse-engineered beyond the
ownership-classification needed for the audit, and none of it is reimplemented anywhere in this
repository.

---

## 6. Signing state of the supplied artifact

| Check | Result |
|---|---|
| `embedded.mobileprovision` | **absent** → the IPA is not provisioned for any device or team |
| `SC_Info/` | present but contains only an empty `.keep` placeholder → the FairPlay `.sinf`/`.supp` material was stripped |
| `cryptid` on every Mach-O | `0` → all binaries are decrypted |
| `pool` code signature | present, Team `HLSX4DMBX6`, CMS blob 4,384 B, SHA-1 + SHA-256 code directories, 19,920 code slots, entitlements blob present |
| Does that signature still validate? | **NO.** The signature was produced before `libloader` was injected, so the `LC_LOAD_DYLIB` command and the shifted `__LINKEDIT` content no longer match the sealed hashes. |
| `_CodeSignature/CodeResources` | present, but seals the publisher's original resource set |

**Conclusion:** the supplied IPA is an unsigned-in-practice, DRM-stripped, tampered build. It cannot be
installed on a non-jailbroken device without being completely re-signed with a provisioning profile
that the repository does not have, and re-signing it would mean signing someone else's application
plus an injected cheat payload.

---

## 7. Component classification summary

| Class | Files | Bytes | Basis |
|---|---:|---:|---|
| `ORIGINAL_APPLICATION` | 3,171 | 153.9 MB | publisher bundle, resources, extensions, localisations |
| `THIRD_PARTY` | 150 | 33.7 MB | advertising/analytics SDKs embedded by the publisher |
| `CUSTOM_OVERLAY` | 3 | 11.5 MB | `libloader.framework` (binary, Info.plist, CodeResources) |
| `UNKNOWN` | 19 | 5.2 MB | `j1O1pP4cpnaLPxs2xoSf/` — randomly named directory of opaque blobs (LOW confidence on ownership; it was **not** probed further) |
| `SHARED` | 1 | 1.1 MB | `_CodeSignature/CodeResources` |

Per-file classifications with confidence levels: `original/manifests/archive-manifest.csv`.

---

## 8. Reproducing this report

```bash
python3 MR-SPICY/validation/tools/inspect_ipa.py \
        8-ball-pool-i3rby-IPAOMTK.COM.ipa \
        MR-SPICY/original/manifests
```

The tool opens the IPA read-only and writes only into the output directory.
