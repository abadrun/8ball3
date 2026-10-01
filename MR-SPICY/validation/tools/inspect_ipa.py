#!/usr/bin/env python3
"""
inspect_ipa.py - read-only IPA inspector for the MR-SPICY audit.

Produces, from an untouched IPA:
  * archive-manifest.json / .csv   (every zip entry: size, crc32, sha256)
  * bundle-manifest.json           (app bundle structure summary)
  * frameworks.json                (every Mach-O: arch, min OS, deps, signature)
  * plugins.json                   (app extensions)
  * localization.json              (lproj inventory)
  * info-plist-snapshot.json       (main + nested Info.plist)
  * signing.json                   (signature / entitlement state)

The source IPA is opened read-only and never written to.

Usage: inspect_ipa.py <path-to.ipa> <output-dir>
"""
from __future__ import annotations
import csv, hashlib, io, json, os, plistlib, sys, zipfile, collections, datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import machoinfo  # noqa: E402

CHUNK = 1 << 20


def sha256_entry(z: zipfile.ZipFile, name: str) -> tuple[str, int]:
    h = hashlib.sha256()
    n = 0
    with z.open(name) as f:
        while True:
            b = f.read(CHUNK)
            if not b:
                break
            h.update(b)
            n += len(b)
    return h.hexdigest(), n


def classify(path: str) -> tuple[str, str, str]:
    """(ownership, component, confidence) - evidence-based, conservative."""
    p = path
    if "/Frameworks/libloader.framework" in p:
        return ("CUSTOM_OVERLAY", "injected loader bundle", "HIGH")
    if "/j1O1pP4cpnaLPxs2xoSf/" in p:
        return ("UNKNOWN", "opaque obfuscated resource directory", "LOW")
    if "/PlugIns/" in p:
        return ("ORIGINAL_APPLICATION", "app extension", "HIGH")
    if "/Frameworks/" in p:
        return ("THIRD_PARTY", "embedded SDK framework", "HIGH")
    if "/_CodeSignature/" in p:
        return ("SHARED", "code signature resource map", "HIGH")
    if p.endswith("/Info.plist") or p.endswith(".lproj") or ".lproj/" in p:
        return ("ORIGINAL_APPLICATION", "bundle metadata / localization", "HIGH")
    if "/checksums/" in p:
        return ("ORIGINAL_APPLICATION", "game asset checksum table", "MEDIUM")
    return ("ORIGINAL_APPLICATION", "game resource", "MEDIUM")


def main(ipa_path: str, outdir: str) -> None:
    os.makedirs(outdir, exist_ok=True)
    size = os.path.getsize(ipa_path)
    h = hashlib.sha256()
    with open(ipa_path, "rb") as f:
        while True:
            b = f.read(CHUNK)
            if not b:
                break
            h.update(b)
    ipa_sha = h.hexdigest()

    z = zipfile.ZipFile(ipa_path, "r")
    infos = [i for i in z.infolist()]

    rows = []
    by_ext = collections.Counter()
    by_ext_bytes = collections.Counter()
    ownership = collections.Counter()
    macho_targets = []
    for i in infos:
        name = i.filename
        is_dir = name.endswith("/")
        own, comp, conf = classify(name)
        ownership[own] += 0 if is_dir else 1
        base = name.rstrip("/").split("/")[-1]
        ext = base.rsplit(".", 1)[-1].lower() if "." in base else "(no-ext)"
        sha = ""
        if not is_dir:
            sha, _ = sha256_entry(z, name)
            by_ext[ext] += 1
            by_ext_bytes[ext] += i.file_size
            if ext == "(no-ext)" or ext in ("dylib",):
                with z.open(name) as f:
                    head = f.read(4)
                if machoinfo.is_macho(head):
                    macho_targets.append(name)
        rows.append({
            "path": name, "is_dir": is_dir, "size": i.file_size,
            "compressed_size": i.compress_size, "crc32": f"{i.CRC:08x}",
            "sha256": sha, "ownership": own, "component": comp, "confidence": conf,
        })

    with open(os.path.join(outdir, "archive-manifest.json"), "w") as f:
        json.dump({
            "ipa": os.path.basename(ipa_path), "ipa_size_bytes": size, "ipa_sha256": ipa_sha,
            "entry_count": len(rows),
            "generated_by": "MR-SPICY/validation/tools/inspect_ipa.py",
            "entries": rows,
        }, f, indent=1)
    with open(os.path.join(outdir, "archive-manifest.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    # ---- Mach-O inventory -------------------------------------------------
    machos = []
    for name in macho_targets:
        data = z.read(name)
        info = machoinfo.analyze_bytes(data, name)
        own, comp, conf = classify(name)
        info["ownership"] = own
        info["confidence"] = conf
        machos.append(info)
    with open(os.path.join(outdir, "frameworks.json"), "w") as f:
        json.dump({"count": len(machos), "mach_o": machos}, f, indent=1)

    # ---- Info.plist snapshots --------------------------------------------
    plists = {}
    for i in infos:
        if i.filename.endswith("Info.plist") and i.file_size:
            try:
                plists[i.filename] = plistlib.loads(z.read(i.filename))
            except Exception as e:  # noqa: BLE001
                plists[i.filename] = {"__parse_error__": str(e)}
    with open(os.path.join(outdir, "info-plist-snapshot.json"), "w") as f:
        json.dump(plists, f, indent=1, default=str)

    # ---- app bundle / plugin / localization summaries ---------------------
    app = next(n.filename for n in infos if n.filename.count("/") == 2
               and n.filename.endswith(".app/"))
    app_name = app.split("/")[1]
    main_plist = plists.get(f"Payload/{app_name}/Info.plist", {})
    plugins = sorted({n.filename.split("PlugIns/")[1].split("/")[0]
                      for n in infos if "/PlugIns/" in n.filename
                      and n.filename.split("PlugIns/")[1]})
    frameworks = sorted({n.filename.split("Frameworks/")[1].split("/")[0]
                         for n in infos if "/Frameworks/" in n.filename
                         and n.filename.split("Frameworks/")[1]})
    lprojs = collections.defaultdict(list)
    for n in infos:
        parts = n.filename.split("/")
        for idx, seg in enumerate(parts):
            if seg.endswith(".lproj"):
                lprojs["/".join(parts[:idx])].append(seg)
    bundle = {
        "app_bundle": app_name,
        "bundle_identifier": main_plist.get("CFBundleIdentifier"),
        "display_name": main_plist.get("CFBundleDisplayName"),
        "short_version": main_plist.get("CFBundleShortVersionString"),
        "build_version": main_plist.get("CFBundleVersion"),
        "executable": main_plist.get("CFBundleExecutable"),
        "minimum_os_version": main_plist.get("MinimumOSVersion"),
        "sdk": main_plist.get("DTSDKName"),
        "device_family": main_plist.get("UIDeviceFamily"),
        "orientations_iphone": main_plist.get("UISupportedInterfaceOrientations"),
        "orientations_ipad": main_plist.get("UISupportedInterfaceOrientations~ipad"),
        "requires_fullscreen": main_plist.get("UIRequiresFullScreen"),
        "frameworks": frameworks,
        "plugins": plugins,
        "entry_count": len(rows),
        "uncompressed_bytes": sum(r["size"] for r in rows),
        "ownership_counts": dict(ownership),
        "extension_counts": {k: {"files": v, "bytes": by_ext_bytes[k]}
                             for k, v in by_ext.most_common()},
    }
    with open(os.path.join(outdir, "bundle-manifest.json"), "w") as f:
        json.dump(bundle, f, indent=1, default=str)
    with open(os.path.join(outdir, "plugins.json"), "w") as f:
        json.dump({p: plists.get(f"Payload/{app_name}/PlugIns/{p}/Info.plist", {})
                   for p in plugins}, f, indent=1, default=str)
    with open(os.path.join(outdir, "localization.json"), "w") as f:
        json.dump({k: sorted(set(v)) for k, v in sorted(lprojs.items())}, f, indent=1)

    # ---- signing state ----------------------------------------------------
    signing = {
        "embedded_mobileprovision": any("embedded.mobileprovision" in r["path"] for r in rows),
        "code_signature_dirs": sorted({r["path"] for r in rows if r["path"].endswith("_CodeSignature/")}),
        "sc_info_present": any("/SC_Info/" in r["path"] for r in rows),
        "binaries": [],
    }
    for m in machos:
        for s in m["slices"]:
            cs = s.get("code_signature", {})
            signing["binaries"].append({
                "path": m["name"], "arch": s["arch"],
                "signature_present": cs.get("present", False),
                "ad_hoc": any(cd.get("ad_hoc") for cd in cs.get("code_directories", [])),
                "identifier": (cs.get("code_directories") or [{}])[0].get("identifier"),
                "team_id": (cs.get("code_directories") or [{}])[0].get("team_id"),
                "has_cms_blob": cs.get("has_cms_blob"),
                "has_entitlements": cs.get("has_entitlements"),
                "cryptid": s.get("cryptid"),
            })
    with open(os.path.join(outdir, "signing.json"), "w") as f:
        json.dump(signing, f, indent=1)

    print(json.dumps({
        "ipa_sha256": ipa_sha, "ipa_size": size, "entries": len(rows),
        "mach_o_binaries": len(machos), "frameworks": len(frameworks),
        "plugins": len(plugins), "outdir": outdir,
        "generated_utc": datetime.datetime.now(datetime.timezone.utc)
                                  .strftime("%Y-%m-%dT%H:%M:%SZ"),
    }, indent=1))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
