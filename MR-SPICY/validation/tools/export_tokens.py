#!/usr/bin/env python3
"""
export_tokens.py — single source of truth exporter.

Reads SpicyTheme.swift and the .strings tables and emits machine-readable
copies used by the documentation preview, so the preview can never drift from
the Swift source:

  mr-spicy-ui/Documentation/preview/tokens.json
  mr-spicy-ui/Documentation/preview/strings.json

Run after any change to SpicyTheme.swift or the localisation tables.
"""
from __future__ import annotations
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UI = os.path.join(ROOT, "mr-spicy-ui", "Sources", "MrSpicyUI")
THEME = os.path.join(UI, "Core", "SpicyTheme.swift")
RESOURCES = os.path.join(UI, "Resources")
OUT = os.path.join(ROOT, "mr-spicy-ui", "Documentation", "preview")

HEX_ALPHA = re.compile(r"UIColor\(spicyHex:\s*0x([0-9A-Fa-f]{6})(?:,\s*alpha:\s*([0-9.]+))?\)")
DYNAMIC = re.compile(r"spicyDynamic\(dark:\s*0x([0-9A-Fa-f]{6}),\s*light:\s*0x([0-9A-Fa-f]{6})\)")
NUMBER = re.compile(r"public static let (\w+):\s*(?:CGFloat|TimeInterval)\s*=\s*(-?[0-9.]+)")
REF = re.compile(r"public static let (\w+) = (\w+)\s*$")
STRINGS_LINE = re.compile(r'^\s*"([^"]+)"\s*=\s*"(.*)"\s*;\s*$')


def rgba(hex_value: str, alpha: str | None) -> str:
    r, g, b = (int(hex_value[i:i + 2], 16) for i in (0, 2, 4))
    return f"rgba({r},{g},{b},{alpha})" if alpha else f"#{hex_value.upper()}"


def section(source: str, name: str) -> str:
    """Returns the body of `public enum <name> { ... }`."""
    match = re.search(rf"public enum {name} \{{(.*?)\n    \}}", source, re.S)
    return match.group(1) if match else ""


def main() -> int:
    source = open(THEME, encoding="utf-8").read()

    colours: dict[str, dict[str, str]] = {}
    colour_body = section(source, "Color")
    for line in colour_body.splitlines():
        line = line.strip()
        if not line.startswith("public static let"):
            continue
        name = line.split()[3]
        dynamic = DYNAMIC.search(line)
        if dynamic:
            colours[name] = {"dark": f"#{dynamic.group(1).upper()}",
                             "light": f"#{dynamic.group(2).upper()}"}
            continue
        plain = HEX_ALPHA.search(line)
        if plain:
            value = rgba(plain.group(1), plain.group(2))
            colours[name] = {"dark": value, "light": value}
            continue
        ref = REF.search(line)
        if ref and ref.group(2) in colours:
            colours[name] = colours[ref.group(2)]

    numeric: dict[str, dict[str, float]] = {}
    for group in ("Spacing", "Radius", "Size", "Opacity", "Motion", "Stroke"):
        body = section(source, group)
        numeric[group] = {name: float(value) for name, value in NUMBER.findall(body)}

    tokens = {
        "generated_by": "validation/tools/export_tokens.py",
        "source": "mr-spicy-ui/Sources/MrSpicyUI/Core/SpicyTheme.swift",
        "ui_layer_version": "1.0.0",
        "colors": colours,
        "scales": numeric,
    }

    strings: dict[str, dict[str, str]] = {}
    for entry in sorted(os.listdir(RESOURCES)):
        if not entry.endswith(".lproj"):
            continue
        language = entry.replace(".lproj", "")
        table: dict[str, str] = {}
        in_comment = False
        for raw in open(os.path.join(RESOURCES, entry, "MrSpicy.strings"), encoding="utf-8"):
            line = raw.strip()
            if in_comment:
                if "*/" in line:
                    in_comment = False
                continue
            if line.startswith("/*"):
                if "*/" not in line:
                    in_comment = True
                continue
            match = STRINGS_LINE.match(raw)
            if match:
                table[match.group(1)] = match.group(2)
        strings[language] = table

    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "tokens.json"), "w", encoding="utf-8") as handle:
        json.dump(tokens, handle, indent=1, ensure_ascii=False)
    with open(os.path.join(OUT, "strings.json"), "w", encoding="utf-8") as handle:
        json.dump(strings, handle, indent=1, ensure_ascii=False)

    print(json.dumps({
        "colors": len(colours),
        "scale_groups": {k: len(v) for k, v in numeric.items()},
        "languages": {k: len(v) for k, v in strings.items()},
        "written": [os.path.relpath(os.path.join(OUT, f), ROOT)
                    for f in ("tokens.json", "strings.json")],
    }, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
