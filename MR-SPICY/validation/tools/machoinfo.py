#!/usr/bin/env python3
"""
machoinfo.py - read-only Mach-O inspector used by the MR-SPICY audit.

Parses fat/thin Mach-O headers, load commands, linked dylibs, build versions,
encryption info and the embedded code-signature SuperBlob / CodeDirectory.

No binary is ever written or modified by this tool.
"""
from __future__ import annotations
import struct, uuid, json, sys, hashlib

MH_MAGIC_64 = 0xfeedfacf
MH_CIGAM_64 = 0xcffaedfe
FAT_MAGIC   = 0xcafebabe
FAT_MAGIC_64= 0xcafebabf

CPU_TYPES = {0x0100000c: "arm64", 0x0200000c: "arm64_32", 12: "armv7", 0x01000007: "x86_64", 7: "i386"}
CPU_SUBS  = {0: "all", 1: "v8", 2: "arm64e", 9: "armv7s", 11: "armv7k"}
FILETYPES = {1: "MH_OBJECT", 2: "MH_EXECUTE", 6: "MH_DYLIB", 8: "MH_BUNDLE", 10: "MH_DSYM"}
PLATFORMS = {1: "macOS", 2: "iOS", 3: "tvOS", 4: "watchOS", 5: "bridgeOS", 6: "MacCatalyst",
             7: "iOSSimulator", 8: "tvOSSimulator", 9: "watchOSSimulator"}

LC_SEGMENT_64 = 0x19
LC_LOAD_DYLIB = 0xc
LC_LOAD_WEAK_DYLIB = 0x18000000 | 0x18
LC_ID_DYLIB = 0xd
LC_CODE_SIGNATURE = 0x1d
LC_ENCRYPTION_INFO_64 = 0x2C
LC_ENCRYPTION_INFO = 0x21
LC_BUILD_VERSION = 0x32
LC_VERSION_MIN_IPHONEOS = 0x25
LC_UUID = 0x1b
LC_RPATH = 0x8000001f

CSMAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0
CSMAGIC_CODEDIRECTORY      = 0xfade0c02
CSMAGIC_ENTITLEMENTS       = 0xfade7171
CSMAGIC_DER_ENTITLEMENTS   = 0xfade7172
CSMAGIC_BLOBWRAPPER        = 0xfade0b01
CS_ADHOC                   = 0x0000002
HASH_TYPES = {0: "no-hash", 1: "sha1", 2: "sha256", 3: "sha256-truncated", 4: "sha384"}


def _ver(v: int) -> str:
    return f"{v >> 16}.{(v >> 8) & 0xff}.{v & 0xff}"


def _parse_codedir(data: bytes, off: int) -> dict:
    magic, length, version, flags, hashOffset, identOffset, nSpecialSlots, nCodeSlots, \
        codeLimit, hashSize, hashType, platform, pageSize, spare2 = struct.unpack(
            ">IIIIIIIIIBBBBI", data[off:off + 44])
    ident = data[off + identOffset:data.index(b"\0", off + identOffset)].decode("utf8", "replace")
    team = None
    if version >= 0x20200:
        (teamOffset,) = struct.unpack(">I", data[off + 48:off + 52])
        if teamOffset:
            team = data[off + teamOffset:data.index(b"\0", off + teamOffset)].decode("utf8", "replace")
    return {
        "identifier": ident,
        "team_id": team,
        "cd_version": hex(version),
        "flags": hex(flags),
        "ad_hoc": bool(flags & CS_ADHOC),
        "hash_type": HASH_TYPES.get(hashType, hashType),
        "code_slots": nCodeSlots,
        "special_slots": nSpecialSlots,
        "page_size": 1 << pageSize if pageSize else 0,
        "code_limit": codeLimit,
        "platform_binary": platform,
    }


def _parse_signature(data: bytes, off: int, size: int) -> dict:
    out = {"present": True, "size": size, "code_directories": [], "has_cms_blob": False,
           "has_entitlements": False, "entitlements_xml": None}
    try:
        magic, length, count = struct.unpack(">III", data[off:off + 12])
    except struct.error:
        out["error"] = "truncated signature"
        return out
    if magic != CSMAGIC_EMBEDDED_SIGNATURE:
        out["error"] = f"unexpected magic {hex(magic)}"
        return out
    out["blob_count"] = count
    for i in range(count):
        t, o = struct.unpack(">II", data[off + 12 + i * 8: off + 20 + i * 8])
        bo = off + o
        (bmagic,) = struct.unpack(">I", data[bo:bo + 4])
        if bmagic == CSMAGIC_CODEDIRECTORY:
            out["code_directories"].append(_parse_codedir(data, bo))
        elif bmagic in (CSMAGIC_ENTITLEMENTS, CSMAGIC_DER_ENTITLEMENTS):
            out["has_entitlements"] = True
            if bmagic == CSMAGIC_ENTITLEMENTS:
                (_, blen) = struct.unpack(">II", data[bo:bo + 8])
                out["entitlements_xml"] = data[bo + 8:bo + blen].decode("utf8", "replace")
        elif bmagic == CSMAGIC_BLOBWRAPPER:
            (_, blen) = struct.unpack(">II", data[bo:bo + 8])
            out["has_cms_blob"] = blen > 8
            out["cms_blob_size"] = blen - 8
    return out


def _parse_thin(data: bytes, base: int, size: int) -> dict:
    magic, cputype, cpusub, filetype, ncmds, sizeofcmds, flags = struct.unpack(
        "<7I", data[base:base + 28])
    sub = cpusub & 0x00ffffff
    info = {
        "arch": CPU_TYPES.get(cputype, hex(cputype)),
        "subtype": CPU_SUBS.get(sub, sub),
        "filetype": FILETYPES.get(filetype, filetype),
        "flags": hex(flags),
        "pie": bool(flags & 0x200000),
        "ncmds": ncmds,
        "slice_size": size,
        "uuid": None, "min_os": None, "sdk": None, "platform": None,
        "cryptid": None, "segments": [], "dylibs": [], "weak_dylibs": [], "rpaths": [],
        "install_name": None, "code_signature": {"present": False},
    }
    p = base + 32
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack("<II", data[p:p + 8])
        if cmd in (LC_LOAD_DYLIB, LC_ID_DYLIB, LC_LOAD_WEAK_DYLIB):
            (noff,) = struct.unpack("<I", data[p + 8:p + 12])
            name = data[p + noff:p + cmdsize].split(b"\0")[0].decode("utf8", "replace")
            if cmd == LC_ID_DYLIB:
                info["install_name"] = name
            elif cmd == LC_LOAD_WEAK_DYLIB:
                info["weak_dylibs"].append(name)
            else:
                info["dylibs"].append(name)
        elif cmd == LC_SEGMENT_64:
            info["segments"].append(data[p + 8:p + 24].split(b"\0")[0].decode())
        elif cmd == LC_BUILD_VERSION:
            plat, minos, sdk, _n = struct.unpack("<4I", data[p + 8:p + 24])
            info["platform"] = PLATFORMS.get(plat, plat)
            info["min_os"] = _ver(minos)
            info["sdk"] = _ver(sdk)
        elif cmd == LC_VERSION_MIN_IPHONEOS:
            v, s = struct.unpack("<2I", data[p + 8:p + 16])
            info["platform"] = "iOS"
            info["min_os"] = _ver(v)
            info["sdk"] = _ver(s)
        elif cmd in (LC_ENCRYPTION_INFO, LC_ENCRYPTION_INFO_64):
            co, cs, cid = struct.unpack("<3I", data[p + 8:p + 20])
            info["cryptid"] = cid
            info["crypt_size"] = cs
        elif cmd == LC_UUID:
            info["uuid"] = str(uuid.UUID(bytes=data[p + 8:p + 24]))
        elif cmd == LC_RPATH:
            (noff,) = struct.unpack("<I", data[p + 8:p + 12])
            info["rpaths"].append(data[p + noff:p + cmdsize].split(b"\0")[0].decode("utf8", "replace"))
        elif cmd == LC_CODE_SIGNATURE:
            so, ss = struct.unpack("<2I", data[p + 8:p + 16])
            info["code_signature"] = _parse_signature(data, base + so, ss)
        p += cmdsize
    return info


def is_macho(head: bytes) -> bool:
    if len(head) < 4:
        return False
    (m,) = struct.unpack(">I", head[:4])
    (ml,) = struct.unpack("<I", head[:4])
    return m in (FAT_MAGIC, FAT_MAGIC_64, MH_MAGIC_64) or ml in (MH_MAGIC_64,)


def analyze_bytes(data: bytes, name: str = "") -> dict:
    (be,) = struct.unpack(">I", data[:4])
    out = {"name": name, "size": len(data), "sha256": hashlib.sha256(data).hexdigest(),
           "fat": False, "slices": []}
    if be in (FAT_MAGIC, FAT_MAGIC_64):
        out["fat"] = True
        (n,) = struct.unpack(">I", data[4:8])
        off = 8
        for _ in range(n):
            if be == FAT_MAGIC:
                _c, _s, o, sz, _a = struct.unpack(">5I", data[off:off + 20]); off += 20
            else:
                _c, _s, o, sz, _a, _r = struct.unpack(">2I2Q2I", data[off:off + 32]); off += 32
            out["slices"].append(_parse_thin(data, o, sz))
    else:
        out["slices"].append(_parse_thin(data, 0, len(data)))
    return out


def analyze_file(path: str) -> dict:
    with open(path, "rb") as f:
        data = f.read()
    return analyze_bytes(data, path)


if __name__ == "__main__":
    for a in sys.argv[1:]:
        print(json.dumps(analyze_file(a), indent=2))
