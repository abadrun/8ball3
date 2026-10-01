# Repeatable Workflow for a New Host Version

Applies to any **legitimate** host application you are authorised to build and ship. It is the
§28/§59 workflow, written so a new engineer can follow it without rediscovering anything.

```
NEW HOST VERSION
      ↓  1. preserve the new artifact (never overwrite the previous one)
      ↓  2. SHA-256 + manifests
      ↓  3. inspect
      ↓  4. diff against the previous host version
      ↓  5. classify what changed
      ↓  6. check MR. SPICY compatibility
      ↓  7. reuse the MR. SPICY source (do NOT re-create it)
      ↓  8. update only the version-specific adapter
      ↓  9. integrate through the supported boundary
      ↓ 10. build → validate → test → document → version → release
      ↓ 11. keep the previous release intact
```

## Step by step

**1 — Preserve.** Add the new artifact alongside the old ones. Never replace, never rename an old
one to "old", never delete. `versions/host/` gets a new record file.

**2 — Checksum and manifest.**
```bash
sha256sum "<new>.ipa" > MR-SPICY/original/checksums/<new>.sha256
python3 MR-SPICY/validation/tools/inspect_ipa.py "<new>.ipa" MR-SPICY/versions/host/<version>/manifests
```

**3 — Inspect.** Read `bundle-manifest.json`, `frameworks.json`, `signing.json`.

**4 — Diff.** The manifests are plain JSON/CSV with a SHA-256 per entry, so a release diff is:
```bash
python3 - <<'PY'
import json
a = {e["path"]: e["sha256"] for e in json.load(open("old/archive-manifest.json"))["entries"]}
b = {e["path"]: e["sha256"] for e in json.load(open("new/archive-manifest.json"))["entries"]}
print("added:   ", sorted(set(b) - set(a))[:50])
print("removed: ", sorted(set(a) - set(b))[:50])
print("changed: ", sorted(p for p in set(a) & set(b) if a[p] != b[p])[:50])
PY
```
Record the result as `changed-files-report.md` for that release.

**5 — Classify the changes.** For each changed component: original / third-party / shared / yours.
Attach a confidence level. Anything you cannot evidence stays `UNKNOWN / LOW`.

**6 — Compatibility check.** Compare against `compatibility/compatibility-matrix.md`:
minimum iOS, architectures, device families, orientations, UI technology, and the integration
points your adapter relies on. If a relied-upon API changed, the adapter changes — never the
component library's internals.

**7 — Reuse, do not rebuild.** The MR. SPICY source layer is the asset. A new host version almost
never requires theme, component, localisation or accessibility changes. If it does, bump the UI
layer version properly (§53) and write the migration note.

**8 — Update the adapter.** `integration/adapters/<host>-<version>/` holds a thin object that
conforms to `SpicyOverlayDataSource` / `SpicyOverlayDelegate`. That file — and only that file — is
host-version specific.

**9 — Integrate through supported mechanisms only.** Link the package, present the controller, feed
it tiles and status. If the only available route would be binary patching an application you do not
own, stop and report `BLOCKED BY SOURCE LIMITATION`.

**10 — Build, validate, test, document, version, release.**
```bash
xcodebuild … archive && xcodebuild -exportArchive …
python3 MR-SPICY/validation/tools/verify_release_ipa.py "Mr Spicy.ipa" MR-SPICY/output
python3 MR-SPICY/validation/tools/validate_localization.py
python3 MR-SPICY/validation/tools/validate_design_tokens.py
```
Update `CHANGELOG.md`, the compatibility matrix, and the version records.

**11 — Preserve the previous release.** Previous artifacts, manifests, compatibility records and
changelogs stay in the repository. Rollback = checking out the previous release record and its
artifact.

## Hard rules

| Rule | Why |
|---|---|
| A previous release is **never** a binary patch recipe for a new host | offsets, symbols and resource layouts change; §60 |
| Never blindly re-apply old changes | the diff decides what is needed |
| Never bypass signing, licensing, DRM, anti-cheat or payment to make an integration "work" | §48; if that is the only route, the integration is not authorised |
| Never claim compatibility you have not measured | §36/§66 |
| Never delete history to make the newest release look clean | §61/§62 |
