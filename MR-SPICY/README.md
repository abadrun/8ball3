<div align="center">

<img src="assets/branding/mr-spicy-logo-256.png" width="110" alt="MR. SPICY">

# MR-SPICY

**An iOS design system and component library · plus a full forensic audit of the supplied artifact.**

`UI layer 1.0.0` · `English + العربية` · `true RTL` · `iOS 13+` · `WCAG AA verified`

</div>

---

## Read this first

The supplied IPA was inspected before anything was built. It is a **DRM-stripped copy of
Miniclip's 8 Ball Pool (56.30.0)** with an **unsigned cheat/mod-menu framework injected after
signing** — aim assistance, shot prediction, auto-play, auto-queue, a device-bound subscription-key
scheme and a "stream proof" mode, all inside `Frameworks/libloader.framework`.

So this project did the work that is legitimate, and refused the work that is not:

| | |
|---|---|
| ✅ **Built** | complete audit, preservation, reproducible tooling, documentation — and a real, reusable MR. SPICY design system + component library that is **independent of any host** |
| ⛔ **Blocked** | re-skinning that overlay, building its PRO/licence/unlock UI, integrating into `pool.app`, and producing `output/Mr Spicy.ipa` |

Evidence: [`documentation/audit/ipa-inspection-report.md`](documentation/audit/ipa-inspection-report.md).
Reasoning: [`SCOPE-AND-BOUNDARIES.md`](SCOPE-AND-BOUNDARIES.md).
Nothing here fabricates a build, a hash, a signature, an installation or a compatibility claim.

---

## What you actually get

### 1. A reusable iOS UI layer — `mr-spicy-ui/`

A standalone SwiftPM package (iOS 13+, UIKit, zero dependencies) that you can drop into **any app
you are authorised to build**:

* **`SpicyTheme`** — 24 colour tokens (dark + light), spacing, radii, sizes, strokes, opacity,
  motion, Dynamic-Type typography. No visual value is hard-coded anywhere else; a validator enforces it.
* **`SpicyL10n`** — 58 typed string keys, English + Arabic, fallback with missing-key reporting,
  runtime language switching with no restart.
* **True RTL** — recursive semantic-attribute mirroring, leading/trailing anchors everywhere
  (validator fails on `leftAnchor`/`rightAnchor`), mirrored directional icons only.
* **`SpicyStateMachine`** — a pure reducer; invalid UI states are unreachable, and it is testable
  without UIKit.
* **Components** — header, panel container, feature tiles + responsive grid, **one** modal system,
  settings rows/groups, buttons, cards, badges, section headers.
* **Accessibility built in** — VoiceOver labels/hints/traits, 44 pt targets, Reduce Motion,
  stacked-row fallback at accessibility text sizes, measured contrast.

### 2. A complete audit — `original/`, `documentation/audit/`

3,505 archive entries with per-entry SHA-256 and ownership classification · 31 Mach-O images parsed
(arch, UUID, min OS, load commands, `cryptid`, code-signature SuperBlob, entitlements) · 26
frameworks · 4 app extensions · 17 localisations · signing and tampering state, with evidence and
confidence levels.

### 3. Tooling that proves the claims — `validation/tools/`

| Tool | What it does | Last run |
|---|---|---|
| `inspect_ipa.py` | full read-only IPA audit → manifests | DONE |
| `machoinfo.py` | fat/thin Mach-O + code-signature parser | DONE |
| `verify_original.sh` | baseline byte-for-byte integrity | **PASS** |
| `validate_localization.py` | key parity, orphans, format specifiers, Arabic script, hard-coded strings | **PASS** |
| `validate_design_tokens.py` | token discipline, WCAG contrast ×13, 44 pt targets, Reduce Motion, RTL anchors | **PASS** |
| `export_tokens.py` | exports tokens/strings from the Swift source of truth | DONE |
| `verify_release_ipa.py` | §34 packaging validation + release manifest + SHA-256 | DONE (proven against the baseline) |

### 4. A design-system preview you can open in a browser

```bash
cd MR-SPICY/mr-spicy-ui/Documentation/preview && python3 -m http.server 3000
```

Rendered from `tokens.json` / `strings.json`, which are **generated from `SpicyTheme.swift` and the
`.strings` tables** — so the documentation cannot drift from the code. Toggle English ⇄ العربية
(the whole page mirrors), dark ⇄ light, and standard ⇄ large text.

---

## Repository layout

```
MR-SPICY/
├── README.md                    ← you are here
├── SCOPE-AND-BOUNDARIES.md      ← what was built, what was refused, why
├── CHANGELOG.md · VERSION
├── original/                    baseline preservation
│   ├── checksums/               SHA-256 of the IPA, logo and every manifest
│   ├── manifests/               archive / bundle / frameworks / plugins / plists / signing / localisation
│   ├── reference/baseline.json  machine-readable pointer to the immutable baseline
│   └── source/                  reserved for an optional physical archival copy
├── assets/                      brand mark + generated branding/icon variants + SHA256SUMS
├── mr-spicy-ui/                 the reusable UI layer
│   ├── Package.swift
│   ├── Sources/MrSpicyUI/{Core,Components,Resources}
│   ├── Tests/MrSpicyUITests/    28 XCTest cases (written, not executed here)
│   └── Documentation/{BUILDING,USAGE,COMPONENTS}.md + preview/
├── integration/                 adapters · configuration · integration notes
├── versions/                    host records · MR. SPICY UI version records
├── compatibility/               compatibility matrix (tested vs NOT TESTED)
├── documentation/               architecture · audit · build · localization · testing · release
├── validation/                  reports, quality gate, tools
└── output/                      release artifacts — see output/README.md (empty, with reasons)
```

---

## Quick start

```bash
# 1. verify the baseline is untouched
bash MR-SPICY/validation/tools/verify_original.sh

# 2. run the QA gates
python3 MR-SPICY/validation/tools/validate_localization.py
python3 MR-SPICY/validation/tools/validate_design_tokens.py

# 3. reproduce the audit from the original IPA
python3 MR-SPICY/validation/tools/inspect_ipa.py \
        8-ball-pool-i3rby-IPAOMTK.COM.ipa MR-SPICY/original/manifests

# 4. browse the design system
cd MR-SPICY/mr-spicy-ui/Documentation/preview && python3 -m http.server 3000
```

Using the UI layer in your own app: [`mr-spicy-ui/Documentation/USAGE.md`](mr-spicy-ui/Documentation/USAGE.md).

---

## Honest status

| | |
|---|---|
| Original IPA preserved, SHA-256 `59607b41…c2f8` | **PASS** |
| Audit, classification, documentation | **DONE** |
| Design system + component source | **DONE** (authored; **not compiled** — no Swift/iOS toolchain here) |
| English / Arabic string coverage | **PASS** (static validation) |
| RTL · responsive · accessibility | **PARTIAL** — implemented and statically enforced, **not verified on a device** |
| Unit tests (28 cases) | **NOT ATTEMPTED** — no toolchain |
| Build · signing · provisioning · installation | **NOT PERFORMED** |
| `output/Mr Spicy.ipa` | **NOT PRODUCED — BLOCKED** |

Full detail: [`validation/validation-report.md`](validation/validation-report.md) ·
[`validation/quality-gate-checklist.md`](validation/quality-gate-checklist.md).

---

## Licensing & ownership

The MR. SPICY UI layer, tooling, assets derived from `logo.png`, and all documentation are the
project owner's work. `8-ball-pool-i3rby-IPAOMTK.COM.ipa` and every component inside it belong to
their respective owners (8 Ball Pool © Miniclip; embedded SDKs © their vendors). It is retained
**only** as an audit subject. No part of it is redistributed, modified, re-signed or reused by this
project.
