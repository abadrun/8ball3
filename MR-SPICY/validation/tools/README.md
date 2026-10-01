# Validation & audit tooling

Pure Python 3 (stdlib only) + one shell script. No dependencies, runs anywhere, safe to put in CI.
None of these tools writes to the artifacts it inspects.

| Tool | Purpose | Exit code |
|---|---|---|
| `machoinfo.py` | fat/thin Mach-O parser: arch, filetype, UUID, min OS/SDK, segments, dylib graph, rpaths, `cryptid`, code-signature SuperBlob, CodeDirectory (identifier, team, flags, ad-hoc, hash type), entitlements XML | 0 |
| `inspect_ipa.py` | full read-only IPA audit → `archive-manifest.{json,csv}`, `bundle-manifest.json`, `frameworks.json`, `plugins.json`, `localization.json`, `info-plist-snapshot.json`, `signing.json` | 0 |
| `verify_release_ipa.py` | §34 packaging validation of a *finished* IPA → `release-manifest.json`, `<name>.sha256`, `validation-report.md` | 0 pass/review · 1 fail |
| `verify_original.sh` | baseline byte-for-byte integrity (IPA + logo + all manifests) | 0 ok · non-zero on mismatch |
| `validate_localization.py` | key parity vs `SpicyStringKey`, orphans, empties, duplicates, format-specifier parity, Arabic-script detection, hard-coded display strings | 0 pass · 1 fail |
| `validate_design_tokens.py` | token discipline, WCAG 2.1 contrast on 13 pairs, 44 pt touch target, Reduce Motion, RTL anchor discipline | 0 pass · 1 fail |
| `export_tokens.py` | exports `tokens.json` + `strings.json` for the documentation preview from the Swift source of truth | 0 |

## Suggested CI job

```yaml
- run: bash MR-SPICY/validation/tools/verify_original.sh
- run: python3 MR-SPICY/validation/tools/validate_localization.py
- run: python3 MR-SPICY/validation/tools/validate_design_tokens.py
- run: python3 MR-SPICY/validation/tools/export_tokens.py && git diff --exit-code MR-SPICY/mr-spicy-ui/Documentation/preview
```

The last line fails the build if the preview exports are stale relative to `SpicyTheme.swift` or the
`.strings` tables.
