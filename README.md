# 8ball3 — MR. SPICY workspace

| Path | What it is |
|---|---|
| [`MR-SPICY/`](MR-SPICY/) | **the project** — design system, audit, tooling, documentation |
| `8-ball-pool-i3rby-IPAOMTK.COM.ipa` | supplied baseline artifact · **immutable, never modified** · SHA-256 `59607b4177f8ffdf36649d9bb3b0c5900d39f5b6b3eaa0c6e351ba353a58c2f8` |
| `logo.png` | supplied MR. SPICY brand mark · unmodified |

Start here: [`MR-SPICY/README.md`](MR-SPICY/README.md) and
[`MR-SPICY/SCOPE-AND-BOUNDARIES.md`](MR-SPICY/SCOPE-AND-BOUNDARIES.md).

## Summary

The supplied IPA was audited read-only before anything was created. It is a DRM-stripped copy of a
commercial third-party game (8 Ball Pool 56.30.0, `com.miniclip.8ballpoolmult`) with an unsigned
cheat/mod-menu framework injected after signing.

Delivered: a complete forensic audit with reproducible tooling, strict preservation of the baseline,
and a genuinely reusable, host-independent **MR. SPICY iOS design system** (tokens, components,
EN + AR with real RTL, accessibility, responsive layout) with passing validation gates.

Not delivered, and why: re-skinning that injected overlay, building its PRO/licence/unlock UI,
integrating into the third-party app, and producing a repackaged `Mr Spicy.ipa` — all blocked on
authorisation grounds. Build, signing and installation were **not performed**, and nothing has been
fabricated to look otherwise. See
[`MR-SPICY/validation/validation-report.md`](MR-SPICY/validation/validation-report.md).

## Verify everything yourself

```bash
bash MR-SPICY/validation/tools/verify_original.sh          # baseline unchanged
python3 MR-SPICY/validation/tools/validate_localization.py  # EN/AR parity
python3 MR-SPICY/validation/tools/validate_design_tokens.py # tokens, contrast, RTL discipline
cd MR-SPICY/mr-spicy-ui/Documentation/preview && python3 -m http.server 3000
```
