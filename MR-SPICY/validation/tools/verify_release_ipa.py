#!/usr/bin/env python3
"""
verify_release_ipa.py — post-build IPA validator and release-manifest generator.

Given an IPA that you are authorised to ship, this tool performs the §34
packaging validation checklist and emits:

    <outdir>/release-manifest.json
    <outdir>/<ipa stem>.sha256
    <outdir>/validation-report.md

Checks:
  1. Single `Payload/<name>.app` root, no stray top-level entries
  2. Info.plist completeness (identifier, version, executable, min OS,
     device family, orientations, icons)
  3. Main executable exists, is Mach-O, and matches CFBundleExecutable
  4. Architecture inventory for every Mach-O image
  5. `cryptid` state (0 = decrypted/never-encrypted; non-zero = FairPlay)
  6. Nested components: frameworks, app extensions, resource bundles
  7. Framework linkage: every @rpath/@executable_path dependency resolves
     inside the bundle
  8. Code-signature presence per binary + embedded.mobileprovision presence
  9. Localisation inventory
 10. Unsigned-binary detection (an unsigned image inside a signed bundle is a
     tampering indicator and fails validation)

It never modifies the IPA.

Usage: verify_release_ipa.py <path.ipa> [output-dir]
"""
from __future__ import annotations
import datetime, hashlib, json, os, plistlib, sys, zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import machoinfo  # noqa: E402

PASS, FAIL, WARN = "PASS", "FAIL", "REQUIRES REVIEW"


def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def main(ipa_path: str, outdir: str) -> int:
    os.makedirs(outdir, exist_ok=True)
    checks: list[dict] = []

    def check(name: str, status: str, detail: str = "") -> None:
        checks.append({"check": name, "status": status, "detail": detail})

    digest = sha256_file(ipa_path)
    size = os.path.getsize(ipa_path)
    z = zipfile.ZipFile(ipa_path)
    names = z.namelist()

    # 1 - payload layout
    roots = {n.split("/")[0] for n in names if n.strip("/")}
    apps = sorted({n.split("/")[1] for n in names
                   if n.startswith("Payload/") and n.count("/") >= 2
                   and n.split("/")[1].endswith(".app")})
    if roots - {"Payload"}:
        check("payload layout", WARN, f"extra top-level entries: {sorted(roots - {'Payload'})}")
    elif len(apps) != 1:
        check("payload layout", FAIL, f"expected exactly one .app, found {apps}")
    else:
        check("payload layout", PASS, f"Payload/{apps[0]}")
    if not apps:
        print(json.dumps({"result": FAIL, "reason": "no .app bundle"}, indent=1))
        return 1
    app = apps[0]
    prefix = f"Payload/{app}/"

    # 2 - Info.plist
    try:
        info = plistlib.loads(z.read(prefix + "Info.plist"))
    except KeyError:
        check("Info.plist", FAIL, "missing")
        info = {}
    required = ["CFBundleIdentifier", "CFBundleExecutable", "CFBundleShortVersionString",
                "CFBundleVersion", "MinimumOSVersion", "UIDeviceFamily",
                "CFBundleSupportedPlatforms"]
    missing = [k for k in required if k not in info]
    check("Info.plist required keys", PASS if not missing else FAIL,
          "all present" if not missing else f"missing {missing}")
    orientations = info.get("UISupportedInterfaceOrientations", [])
    check("orientations declared", PASS if orientations else WARN, ", ".join(orientations))
    icons = info.get("CFBundleIcons", {}).get("CFBundlePrimaryIcon", {})
    check("app icon declared", PASS if icons else WARN, json.dumps(icons))

    # 3/4/5 - Mach-O inventory
    executable = info.get("CFBundleExecutable", "")
    machos, unsigned, encrypted, arches = [], [], [], set()
    for name in names:
        if name.endswith("/"):
            continue
        with z.open(name) as f:
            head = f.read(4)
        if not machoinfo.is_macho(head):
            continue
        parsed = machoinfo.analyze_bytes(z.read(name), name)
        machos.append(parsed)
        for s in parsed["slices"]:
            arches.add(f"{s['arch']}/{s['subtype']}")
            if not s.get("code_signature", {}).get("present"):
                unsigned.append(name)
            if s.get("cryptid"):
                encrypted.append(name)

    check("main executable present", PASS if prefix + executable in names else FAIL,
          prefix + executable)
    check("architectures", PASS if arches else FAIL, ", ".join(sorted(arches)))
    check("FairPlay encryption state",
          PASS if not encrypted else WARN,
          "all cryptid=0" if not encrypted else f"cryptid!=0 in {encrypted}")
    check("all Mach-O images signed", PASS if not unsigned else FAIL,
          "yes" if not unsigned else f"UNSIGNED: {unsigned}")

    # 6 - nested components
    frameworks = sorted({n.split("Frameworks/")[1].split("/")[0]
                         for n in names if "/Frameworks/" in n and n.split("Frameworks/")[1]})
    plugins = sorted({n.split("PlugIns/")[1].split("/")[0]
                      for n in names if "/PlugIns/" in n and n.split("PlugIns/")[1]})
    bundles = sorted({n.split("/")[-2] for n in names if "/" in n and n.split("/")[-2].endswith(".bundle")})
    check("nested components inventoried", PASS,
          f"{len(frameworks)} frameworks, {len(plugins)} extensions, {len(bundles)} resource bundles")

    # 7 - linkage
    present = set(names)
    unresolved = []
    for parsed in machos:
        for s in parsed["slices"]:
            for dep in s["dylibs"] + s["weak_dylibs"]:
                if dep.startswith("@rpath/") or dep.startswith("@executable_path/"):
                    rel = dep.split("/", 1)[1]
                    if rel.startswith("Frameworks/"):
                        candidate = prefix + rel
                    else:
                        candidate = prefix + "Frameworks/" + rel
                    if candidate not in present and not rel.startswith("libswift"):
                        unresolved.append(f"{os.path.basename(parsed['name'])} -> {dep}")
    check("framework linkage resolves inside bundle",
          PASS if not unresolved else WARN,
          "all resolved" if not unresolved else "; ".join(sorted(set(unresolved))[:10]))

    # 8 - provisioning
    provisioned = prefix + "embedded.mobileprovision" in names
    check("embedded.mobileprovision", PASS if provisioned else FAIL,
          "present" if provisioned else "absent — IPA is not provisioned for installation")

    # 9 - localisation
    lprojs = sorted({n.split("/")[2].replace(".lproj", "")
                     for n in names if n.startswith(prefix) and n.count("/") > 2
                     and n.split("/")[2].endswith(".lproj")})
    check("localisations", PASS if lprojs else WARN, ", ".join(lprojs) or "none")

    failed = [c for c in checks if c["status"] == FAIL]
    review = [c for c in checks if c["status"] == WARN]
    overall = FAIL if failed else (WARN if review else PASS)

    manifest = {
        "ipa_filename": os.path.basename(ipa_path),
        "ipa_size_bytes": size,
        "sha256": digest,
        "generated_utc": datetime.datetime.now(datetime.timezone.utc)
                                 .strftime("%Y-%m-%dT%H:%M:%SZ"),
        "app_bundle": app,
        "bundle_identifier": info.get("CFBundleIdentifier"),
        "short_version": info.get("CFBundleShortVersionString"),
        "build_version": info.get("CFBundleVersion"),
        "minimum_os_version": info.get("MinimumOSVersion"),
        "device_family": info.get("UIDeviceFamily"),
        "architectures": sorted(arches),
        "frameworks": frameworks,
        "app_extensions": plugins,
        "localizations": lprojs,
        "mach_o_count": len(machos),
        "unsigned_binaries": sorted(set(unsigned)),
        "signing_status": "SIGNED + PROVISIONED" if provisioned and not unsigned
                          else "SIGNING NOT VERIFIED — see validation report",
        "installation_test": "INSTALLATION TEST NOT PERFORMED",
        "validation_status": overall,
        "checks": checks,
    }

    stem = os.path.splitext(os.path.basename(ipa_path))[0]
    with open(os.path.join(outdir, "release-manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1)
    with open(os.path.join(outdir, f"{stem}.sha256"), "w") as f:
        f.write(f"{digest}  {os.path.basename(ipa_path)}\n")
    with open(os.path.join(outdir, "validation-report.md"), "w") as f:
        f.write(f"# IPA validation report — `{os.path.basename(ipa_path)}`\n\n")
        f.write(f"SHA-256: `{digest}`  \nSize: {size:,} bytes  \n")
        f.write(f"Overall: **{overall}**\n\n| Check | Status | Detail |\n|---|---|---|\n")
        for c in checks:
            f.write(f"| {c['check']} | {c['status']} | {c['detail']} |\n")
        f.write("\nSigning: not performed by this tool. "
                "Installation: INSTALLATION TEST NOT PERFORMED.\n")

    print(json.dumps({"result": overall, "sha256": digest,
                      "failed": [c["check"] for c in failed],
                      "review": [c["check"] for c in review],
                      "outdir": outdir}, indent=1))
    return 0 if overall != FAIL else 1


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else ".")
