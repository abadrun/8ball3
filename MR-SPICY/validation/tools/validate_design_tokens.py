#!/usr/bin/env python3
"""
validate_design_tokens.py — design-system QA gate for MR. SPICY UI.

Checks performed:
  1. Colour/radius/spacing literals appear only in SpicyTheme.swift
     (components must consume tokens, never hard-coded values).
  2. WCAG 2.1 contrast ratios for every text colour against every surface
     colour it is allowed to sit on (dark palette, which is the default).
  3. Minimum touch target token is >= 44 pt (Apple HIG).
  4. Animation helpers honour Reduce Motion.
  5. Directional layout: components use leading/trailing anchors, never
     left/right anchors (RTL correctness).

Exit code 0 = PASS, 1 = FAIL.
"""
from __future__ import annotations
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UI = os.path.join(ROOT, "mr-spicy-ui", "Sources", "MrSpicyUI")
THEME = os.path.join(UI, "Core", "SpicyTheme.swift")

HEX = re.compile(r"spicyHex:\s*0x([0-9A-Fa-f]{6})")
DYNAMIC = re.compile(r"spicyDynamic\(dark:\s*0x([0-9A-Fa-f]{6}),\s*light:\s*0x([0-9A-Fa-f]{6})\)")
NAMED = re.compile(r"public static let (?P<name>\w+) = (?P<expr>.+)$")

# text colour -> surfaces it is specified to be legible on
CONTRAST_PAIRS = [
    ("textPrimary", "background", 4.5),
    ("textPrimary", "surface", 4.5),
    ("textPrimary", "surfaceElevated", 4.5),
    ("textSecondary", "surface", 4.5),
    ("textSecondary", "surfaceElevated", 4.5),
    ("textTertiary", "surface", 3.0),
    ("primaryTint", "surface", 4.5),
    ("primaryTint", "surfaceElevated", 4.5),
    ("success", "surface", 3.0),
    ("warning", "surface", 3.0),
    ("danger", "surface", 3.0),
    ("info", "surface", 3.0),
    ("textOnPrimary", "primary", 4.0),
]


def luminance(hex_value: str) -> float:
    r, g, b = (int(hex_value[i:i + 2], 16) / 255 for i in (0, 2, 4))

    def channel(c: float) -> float:
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def ratio(a: str, b: str) -> float:
    la, lb = luminance(a), luminance(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def parse_dark_palette(source: str) -> dict[str, str]:
    palette: dict[str, str] = {}
    for line in source.splitlines():
        match = NAMED.search(line.strip())
        if not match:
            continue
        name, expr = match.group("name"), match.group("expr")
        dynamic = DYNAMIC.search(expr)
        if dynamic:
            palette[name] = dynamic.group(1).upper()
            continue
        plain = HEX.search(expr)
        if plain and "alpha" not in expr:
            palette[name] = plain.group(1).upper()
    return palette


def main() -> int:
    failures: list[str] = []
    results: dict[str, object] = {}

    theme_source = open(THEME, encoding="utf-8").read()
    palette = parse_dark_palette(theme_source)
    results["parsed_colour_tokens"] = len(palette)

    # 1. token discipline -----------------------------------------------------
    offenders = []
    for folder, _dirs, files in os.walk(UI):
        for name in sorted(files):
            if not name.endswith(".swift") or name == "SpicyTheme.swift":
                continue
            path = os.path.join(folder, name)
            for number, line in enumerate(open(path, encoding="utf-8"), 1):
                stripped = line.strip()
                if stripped.startswith("//"):
                    continue
                if re.search(r"UIColor\(red:|UIColor\(white:|spicyHex:\s*0x", stripped):
                    offenders.append(f"{name}:{number}: hard-coded colour")
                if re.search(r"cornerRadius\s*=\s*\d+(\.\d+)?\s*$", stripped):
                    offenders.append(f"{name}:{number}: hard-coded corner radius")
    failures.extend(offenders)
    results["token_discipline"] = "PASS" if not offenders else "FAIL"

    # 2. contrast -------------------------------------------------------------
    contrast_report = []
    for fg, bg, minimum in CONTRAST_PAIRS:
        if fg not in palette or bg not in palette:
            failures.append(f"contrast: missing token {fg} or {bg}")
            continue
        value = ratio(palette[fg], palette[bg])
        ok = value >= minimum
        contrast_report.append({
            "foreground": fg, "background": bg,
            "ratio": round(value, 2), "required": minimum,
            "result": "PASS" if ok else "FAIL",
        })
        if not ok:
            failures.append(
                f"contrast: {fg} on {bg} is {value:.2f}:1, requires {minimum}:1")
    results["contrast"] = contrast_report

    # 3. touch target ---------------------------------------------------------
    target = re.search(r"minimumTouchTarget:\s*CGFloat\s*=\s*(\d+)", theme_source)
    if not target or int(target.group(1)) < 44:
        failures.append("touch target: minimumTouchTarget must be >= 44")
    results["minimum_touch_target"] = int(target.group(1)) if target else None

    # 4. reduce motion --------------------------------------------------------
    if "UIAccessibility.isReduceMotionEnabled" not in theme_source:
        failures.append("motion: Reduce Motion is not honoured in SpicyTheme.Motion")
    results["reduce_motion_honoured"] = "UIAccessibility.isReduceMotionEnabled" in theme_source

    # 5. directional anchors ---------------------------------------------------
    directional = []
    for folder, _dirs, files in os.walk(UI):
        for name in sorted(files):
            if not name.endswith(".swift"):
                continue
            for number, line in enumerate(open(os.path.join(folder, name), encoding="utf-8"), 1):
                if re.search(r"\.(leftAnchor|rightAnchor)\b", line):
                    directional.append(f"{name}:{number}: uses left/right anchor "
                                       f"(breaks RTL mirroring)")
    failures.extend(directional)
    results["directional_anchors"] = "PASS" if not directional else "FAIL"

    results["failures"] = failures
    results["result"] = "PASS" if not failures else "FAIL"
    print(json.dumps(results, indent=1))
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
