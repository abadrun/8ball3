# `original/` — baseline artifact preservation

## Policy

The supplied artifact is **immutable**. It is never overwritten, renamed, moved, re-zipped or
modified in place by anything in this repository.

| Property | Value |
|---|---|
| Filename | `8-ball-pool-i3rby-IPAOMTK.COM.ipa` |
| Location | repository root (`../../8-ball-pool-i3rby-IPAOMTK.COM.ipa`) |
| Size | 98,576,945 bytes |
| **SHA-256** | `59607b4177f8ffdf36649d9bb3b0c5900d39f5b6b3eaa0c6e351ba353a58c2f8` |
| Recorded in | `checksums/original-ipa.sha256` |

### Why it is referenced instead of copied

Duplicating a 98 MB binary inside `original/source/` would add ~100 MB to the repository, double the
storage of every clone, and create a second copy that can silently diverge from the first. The file
is already tracked in Git at the repository root, which is itself a byte-for-byte, version-controlled,
recoverable copy.

Preservation is therefore enforced by **policy + verification**, not by duplication:

* the original is never a target of any write operation in this project;
* `verify_original.sh` re-verifies the checksum on demand and in CI;
* the full archive manifest (per-entry SHA-256) lets any future copy be diffed entry-by-entry.

If you *do* want a second physical copy (e.g. for offline archival), place it in
`original/source/` — that directory is reserved for it and is excluded from nothing. It is simply
not populated by default.

### Byte-for-byte recovery

```bash
# verify the artifact is untouched
cd <repo root>
sha256sum -c MR-SPICY/original/checksums/original-ipa.sha256

# recover it from Git history if it is ever damaged
git checkout 9695a47 -- "8-ball-pool-i3rby-IPAOMTK.COM.ipa"
```

## Contents

| Path | What it is |
|---|---|
| `checksums/original-ipa.sha256` | SHA-256 of the baseline IPA |
| `checksums/logo.sha256` | SHA-256 of the supplied brand asset |
| `checksums/manifests.sha256` | SHA-256 of every generated manifest (so the audit itself is verifiable) |
| `manifests/archive-manifest.json` | Every one of the 3,505 archive entries: size, compressed size, CRC-32, SHA-256, ownership class, component, confidence |
| `manifests/archive-manifest.csv` | Same data, spreadsheet-friendly |
| `manifests/bundle-manifest.json` | App bundle summary: identity, versions, min OS, device family, orientations, framework/extension lists, type histogram, ownership counts |
| `manifests/frameworks.json` | Every Mach-O image: arch, subtype, filetype, UUID, min OS, SDK, segments, linked dylibs, rpaths, `cryptid`, full code-signature parse (identifier, team, flags, ad-hoc, entitlements) |
| `manifests/plugins.json` | `Info.plist` of all four app extensions |
| `manifests/localization.json` | Every `.lproj` in the bundle and in nested bundles |
| `manifests/info-plist-snapshot.json` | Every `Info.plist` in the archive, fully parsed |
| `manifests/signing.json` | Signature / entitlement / provisioning state per binary |
| `manifests/original-ipa-structural-manifest.json` | Output of the release validator run against the original (baseline record) |
| `reference/baseline.json` | Machine-readable pointer to the baseline artifact |
| `source/` | Reserved for an optional physical archival copy (empty by design) |

## Regenerating the manifests

```bash
python3 MR-SPICY/validation/tools/inspect_ipa.py \
        8-ball-pool-i3rby-IPAOMTK.COM.ipa \
        MR-SPICY/original/manifests
```

Deterministic: the same input reproduces the same manifests (the only varying field is the tool's
own run timestamp in the console summary).
