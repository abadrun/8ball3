# Final Engineering Report (§65)

```
PROJECT
-------
MR. SPICY

REPOSITORY
----------
MR-SPICY  (inside abadrun/8ball3, branch arena/01a0f631-8ball3)

ORIGINAL IPA
------------
8-ball-pool-i3rby-IPAOMTK.COM.ipa   (98,576,945 bytes, unmodified)

ORIGINAL SHA-256
----------------
59607b4177f8ffdf36649d9bb3b0c5900d39f5b6b3eaa0c6e351ba353a58c2f8

MR. SPICY VERSION
-----------------
UI layer 1.0.0

HOST VERSION
------------
8 Ball Pool 56.30.0 (5328) · com.miniclip.8ballpoolmult · arm64 · iOS 13.0+
(inspected only — third-party commercial application, NOT an integration target)

FINAL IPA
---------
NOT PRODUCED — BLOCKED.
Any IPA derived from this input would be a repackaged, DRM-stripped copy of a
commercial third-party game carrying an injected cheat framework. See output/README.md.

FINAL SHA-256
-------------
NOT APPLICABLE — no artifact exists. No hash has been fabricated.

SIGNING
-------
SIGNING NOT PERFORMED — no identity, no profile, no Apple toolchain, and no
artifact that should be signed.

PROVISIONING
------------
NOT AVAILABLE — no embedded.mobileprovision, no team.

INSTALLATION TEST
-----------------
INSTALLATION TEST NOT PERFORMED.

TESTED DEVICES
--------------
NONE.

TESTED IOS VERSIONS
-------------------
NONE.

ENGLISH
-------
PASS (static validation: 58/58 keys, no gaps, no orphans, no hard-coded strings)
Runtime rendering: NOT TESTED.

ARABIC
------
PASS (static validation: 58/58 keys, Arabic-script verified, format-specifier parity)
Runtime rendering: NOT TESTED.

RTL
---
PARTIAL — implemented structurally (recursive semantic-attribute mirroring,
leading/trailing anchors enforced by a validator, mirrored directional icons).
NOT verified on a device or simulator.

RESPONSIVE UI
-------------
PARTIAL — size-class metrics, safe-area insets, responsive tile columns and
Dynamic-Type stacked rows implemented; NOT verified on hardware.

ACCESSIBILITY
-------------
PARTIAL — VoiceOver labels/hints/traits, 44 pt targets, Reduce Motion and modal
focus implemented; WCAG 2.1 contrast PASS on 13 measured pairs;
VoiceOver and Accessibility Inspector audits NOT PERFORMED.

VALIDATION
----------
PASS for everything executable in this environment:
  baseline integrity               PASS
  localisation gate                PASS
  design-token gate                PASS
  contrast gate (13 pairs)         PASS
  RTL anchor-discipline gate       PASS
  IPA audit + structural validator DONE (baseline FAIL is the correct finding)
NOT AVAILABLE: Swift compilation, XCTest execution, device testing.

KNOWN LIMITATIONS
-----------------
1. The Swift package has never been compiled; no runtime behaviour is verified.
2. 28 XCTest cases are written but NOT ATTEMPTED (no toolchain).
3. No account/PRO/licence/entitlement/ad-countdown components exist — deliberate
   exclusion, not an oversight.
4. UIButton.contentEdgeInsets is deprecated on iOS 15+ (warning expected).
5. ExistentialAny upcoming-feature flag requires Swift 5.9+.
6. Three SF Symbols used in the settings surface are unavailable on iOS 13.
7. The light palette is implemented but unreviewed on hardware.
8. Ownership of Payload/pool.app/j1O1pP4cpnaLPxs2xoSf/ remains UNKNOWN (LOW confidence).

BLOCKED ITEMS
-------------
1. Redesigning the injected overlay's UI (header/feature circles/PRO/licence/
   ad-countdown/unlock) — AUTHORISATION BOUNDARY. That overlay is unauthorised
   game-manipulation software with a paid-licence layer.
2. Account / PRO / licence / subscription UI — no legitimate authorising service
   exists; fabricating one is forbidden.
3. Integration into pool.app — AUTHORISATION + SOURCE LIMITATION. No source, no
   rights, no supported extension point; the only route would be another unsigned
   dylib injection.
4. Any modification of the host Mach-O, Info.plist or resources — NOT ATTEMPTED.
5. output/Mr Spicy.ipa — CANNOT BE PRODUCED LEGITIMATELY.
6. Signing, provisioning, installation testing — NOT PERFORMED.

NEXT LEGITIMATE ACTIONS
-----------------------
1. On a Mac: build MrSpicyUI and run the 28 XCTest cases; record real results in
   validation/validation-report.md.
2. Run the device matrix in documentation/testing/test-plan.md (iPhone SE, iPhone 15,
   Pro Max, iPad; portrait + landscape; EN + AR; AX text sizes; VoiceOver) and fill
   compatibility/compatibility-matrix.md with measured values only.
3. Embed the UI layer in an application you are authorised to build; write the
   adapter under integration/adapters/<host>-<version>/.
4. Archive and export that app with your own signing identity, then run
   verify_release_ipa.py to produce Mr Spicy.ipa + SHA-256 + release manifest.
5. Wire the three static gates into CI so localisation, token and RTL discipline
   stay enforced.
6. If the goal is a legitimate companion/overlay product for a game, obtain the
   publisher's authorisation or target your own application — the UI layer is
   already host-independent and ready for either.
```
