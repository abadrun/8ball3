# Scope, Boundaries and Blocked Work

This document states precisely what was built, what was **not** built, and why. It is the honest
answer required by §46 (failure-safe behaviour), §48 (security/authorisation boundary) and §66
(absolute honesty) of the engineering brief.

---

## 1. The finding that determines the scope

The supplied artifact was inspected before anything was created or changed. Full evidence:
[`documentation/audit/ipa-inspection-report.md`](documentation/audit/ipa-inspection-report.md).

Three facts decide the scope of this project:

1. **The host application is a commercial third-party product.**
   `com.miniclip.8ballpoolmult` — 8 Ball Pool 56.30.0 (5328), Apple Developer Team `HLSX4DMBX6`.
   This repository holds no rights, source, signing identity or provisioning profile for it.

2. **The copy supplied is DRM-stripped.**
   `Info.plist` contains `DecryptedBy = @FastDecryptBot …`, `SC_Info/` has been emptied, and every
   Mach-O reports `cryptid = 0`. This is a decrypted App Store binary.

3. **The "custom overlay" that the brief asks to redesign is a cheat/mod menu with its own paid
   licensing layer.** `Frameworks/libloader.framework` is an unsigned binary appended to the host's
   load commands after signing. Its own strings identify aim/trajectory assistance, shot prediction,
   automated play, automated match queueing, a device-bound subscription-key/PRO activation scheme
   with ad-gated free hours, and a "stream proof" mode that hides the overlay from viewers while the
   local player keeps using it.

The brief itself forbids exactly this material:

> §13 — "Do NOT invent or implement unauthorized gameplay manipulation, aim assistance, auto-play,
> server manipulation, anti-cheat evasion, or similar functionality."
> §48 — "…do not bypass DRM … evade anti-cheat systems … implement unauthorized gameplay automation
> … package cheating functionality for redistribution. If existing inspected material contains such
> functionality, document it neutrally and keep the MR. SPICY work focused on legitimate UI/design/
> source architecture."
> §48 — "Do not use a UI redesign as a mechanism for concealing or improving unauthorized
> functionality."

So the instruction set and the artifact conflict. Following §47 ("do not get stuck") and §67
(priority order: security → authorisation → preservation → correctness), the project proceeds with
every legitimate task and marks the rest **BLOCKED**, with reasons.

---

## 2. Delivered (legitimate work)

| Area | Status |
|---|---|
| Repository inventory with checksums, roles, ownership, confidence | DONE |
| Original artifact preservation + SHA-256 + immutability policy | DONE |
| Full read-only IPA inspection (archive, bundle, Mach-O, signing, localisation, nested components) | DONE |
| Reproducible inspection tooling (`validation/tools/`) | DONE |
| Architecture documentation and component classification | DONE |
| MR. SPICY brand analysis and asset variants from `logo.png` | DONE |
| MR. SPICY design system — centralised tokens, no hard-coded values | DONE |
| Reusable UIKit source layer (header, container, tiles, modal system, settings, buttons, cards, badges, rows) | DONE (written; **not compiled** — see §4) |
| Explicit, unit-testable state model | DONE |
| English + Arabic localisation with fallback and missing-key detection | DONE |
| True RTL (semantic content attribute mirroring, directional anchors, mirrored iconography) | DONE |
| Responsive + safe-area + Dynamic Type layout system | DONE |
| Accessibility (VoiceOver labels/hints/traits, 44 pt targets, Reduce Motion, contrast-verified palette) | DONE |
| Browser-renderable design-system preview generated from the Swift source of truth | DONE |
| Automated validation gates that actually run (localisation parity, token discipline, WCAG contrast, RTL anchor rules) | DONE — PASS |
| Versioning, changelog, compatibility matrix, future-host-update workflow | DONE |
| Build / validation / compatibility / installation reports | DONE (with honest NOT-PERFORMED statuses) |

## 3. Blocked (and why)

| Requested item | Status | Reason |
|---|---|---|
| Redesign the existing overlay's UI (header / feature circles / PRO / license / ad-countdown / unlock surfaces of `libloader`) | **BLOCKED — AUTHORISATION BOUNDARY** | That overlay is unauthorised game-manipulation software with a paid-licence layer. Re-skinning it would be improving and repackaging a cheat, and would also build the UI for a licensing scheme that only exists to monetise it. Prohibited by §13, §48, §49 of the brief and by basic authorisation rules. |
| Account / PRO / License / subscription-key UI | **BLOCKED — AUTHORISATION BOUNDARY** | The only entitlement backend present is the mod's own key-activation service. There is no legitimate authorising service to represent, and §49 forbids fabricating one. The component library therefore ships **no** entitlement, licence, payment or account surfaces. |
| Ad / countdown / unlock presentation redesign | **BLOCKED — AUTHORISATION BOUNDARY** | Same component, same reason. |
| Integrate the MR. SPICY layer into `pool.app` | **BLOCKED — SOURCE + AUTHORISATION LIMITATION** | There is no source, no SDK, no plug-in point and no permission. The only technical route would be injecting another unsigned dylib into a tampered, DRM-stripped third-party binary — i.e. the same prohibited operation. §38 requires reporting `BLOCKED BY SOURCE LIMITATION` instead of speculative binary surgery. |
| Modify the `pool` Mach-O, its load commands, `Info.plist`, or any bundle resource | **NOT ATTEMPTED** | §7 (no blind replacements) and §38/§39. No modification has a legitimate target, authorisation or rollback story here. |
| Produce `output/Mr Spicy.ipa` | **BLOCKED — CANNOT BE PRODUCED LEGITIMATELY** | Any IPA produced from this input would be a repackaged, DRM-stripped copy of Miniclip's 8 Ball Pool carrying an injected cheat payload. Producing it would be software piracy plus distribution of game-manipulation software. See `output/README.md`. |
| Sign / provision / install-test any IPA | **SIGNING NOT PERFORMED · INSTALLATION TEST NOT PERFORMED** | No signing identity, no provisioning profile, no Apple hardware, no iOS device in this environment — and no artifact that should be signed. §35/§36 require reporting this rather than faking it. |

## 4. Honest limitations of what *was* delivered

| Limitation | Detail |
|---|---|
| The Swift package has **not been compiled** | This environment is Linux with no Swift toolchain and no iOS SDK; a UIKit target cannot be built here at all. Status: `NOT AVAILABLE — REQUIRES macOS + Xcode`. The code has been statically checked (token discipline, RTL anchor rules, localisation parity, no hard-coded display strings) but **"compiles cleanly" is not claimed**. |
| The XCTest suites have **not been executed** | Same reason. The state-machine tests are pure Swift and should run anywhere a toolchain exists; the UIKit tests need a simulator. Status: `NOT ATTEMPTED`. |
| No device, simulator or screenshot testing | No Apple platform available. The browser preview is design documentation, not a simulator result. RTL / responsive / Dynamic Type correctness is therefore **PARTIAL (verified by construction and static analysis, not on-device)**. |
| The `UNKNOWN` directory `j1O1pP4cpnaLPxs2xoSf/` was not analysed | Its ownership could not be established from structure alone, and deeper analysis was unnecessary for legitimate work. Confidence on its classification is deliberately `LOW`. |

## 5. What the MR. SPICY UI layer is, then

A **standalone, host-independent iOS design system and component library**: theme tokens, header,
panel container, tiles, one modal system, settings surface, buttons, cards, rows, badges, a testable
state model, English + Arabic with real RTL, accessibility and responsive layout.

It is attached to no host in this repository. It can be dropped into **any application you are
authorised to build** — your own app, a client's app, or a future legitimate host — through the
documented integration boundary (`SpicyOverlayDataSource` / `SpicyOverlayDelegate`).
See `integration/integration-notes/README.md`.
