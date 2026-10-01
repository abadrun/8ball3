#!/usr/bin/env python3
"""
validate_localization.py — localisation QA gate for the MR. SPICY UI layer.

Checks performed:
  1. Every key declared in SpicyStringKey (SpicyLocalization.swift) exists in
     every .strings table.
  2. Every key in every table is declared in SpicyStringKey (no orphans).
  3. No empty values.
  4. No duplicate keys within a table.
  5. Format specifiers match across languages (e.g. "%@" count per key).
  6. Arabic values are actually Arabic script (catches untranslated copy),
     with an explicit allow-list for brand names / shared Latin terms.
  7. No hard-coded user-facing string literals in component sources.

Exit code 0 = PASS, 1 = FAIL. Designed to run in CI.
"""
from __future__ import annotations
import json, os, re, sys, unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UI = os.path.join(ROOT, "mr-spicy-ui", "Sources", "MrSpicyUI")
RESOURCES = os.path.join(UI, "Resources")
ENUM_FILE = os.path.join(UI, "Core", "SpicyLocalization.swift")

# Values that may legitimately stay in Latin script in the Arabic table.
ARABIC_LATIN_ALLOWLIST = {
    "spicy.header.title",        # brand name
    "spicy.language.english",    # endonym
    "spicy.a11y.logo",           # contains the brand name
    "spicy.a11y.panel",          # contains the brand name
}

STRINGS_LINE = re.compile(r'^\s*"(?P<key>[^"]+)"\s*=\s*"(?P<value>.*)"\s*;\s*$')
ENUM_LINE = re.compile(r'case\s+\w+\s*=\s*"(?P<key>[^"]+)"')
FORMAT_SPEC = re.compile(r"%(?:\d+\$)?[@dfsu]")


def parse_strings(path: str) -> tuple[dict[str, str], list[str]]:
    values: dict[str, str] = {}
    problems: list[str] = []
    in_block_comment = False
    with open(path, encoding="utf-8") as handle:
        for number, raw in enumerate(handle, 1):
            line = raw.strip()
            if in_block_comment:
                if "*/" in line:
                    in_block_comment = False
                continue
            if line.startswith("/*"):
                if "*/" not in line:
                    in_block_comment = True
                continue
            if not line or line.startswith("//"):
                continue
            match = STRINGS_LINE.match(raw)
            if not match:
                problems.append(f"{os.path.basename(path)}:{number}: unparsable line: {line[:60]}")
                continue
            key, value = match.group("key"), match.group("value")
            if key in values:
                problems.append(f"{os.path.basename(path)}:{number}: duplicate key '{key}'")
            if not value.strip():
                problems.append(f"{os.path.basename(path)}:{number}: empty value for '{key}'")
            values[key] = value
    return values, problems


def has_arabic(text: str) -> bool:
    return any("ARABIC" in unicodedata.name(ch, "") for ch in text)


def main() -> int:
    failures: list[str] = []
    warnings: list[str] = []

    source = open(ENUM_FILE, encoding="utf-8").read()
    block = re.search(r"public enum SpicyStringKey[^{]*\{(?P<body>.*?)\n\}", source, re.S)
    if block is None:
        print("FAIL: SpicyStringKey enum not found in SpicyLocalization.swift")
        return 1
    declared = set(ENUM_LINE.findall(block.group("body")))
    if not declared:
        print("FAIL: no keys parsed from SpicyStringKey")
        return 1

    tables: dict[str, dict[str, str]] = {}
    for entry in sorted(os.listdir(RESOURCES)):
        if not entry.endswith(".lproj"):
            continue
        path = os.path.join(RESOURCES, entry, "MrSpicy.strings")
        if not os.path.exists(path):
            failures.append(f"{entry}: MrSpicy.strings is missing")
            continue
        values, problems = parse_strings(path)
        failures.extend(problems)
        tables[entry.replace(".lproj", "")] = values

    for language, values in sorted(tables.items()):
        missing = sorted(declared - set(values))
        orphan = sorted(set(values) - declared)
        for key in missing:
            failures.append(f"{language}: missing translation for '{key}'")
        for key in orphan:
            failures.append(f"{language}: '{key}' is not declared in SpicyStringKey")

    # format specifier parity
    base = tables.get("en", {})
    for language, values in sorted(tables.items()):
        if language == "en":
            continue
        for key, value in values.items():
            if key not in base:
                continue
            if sorted(FORMAT_SPEC.findall(value)) != sorted(FORMAT_SPEC.findall(base[key])):
                failures.append(
                    f"{language}: format specifiers differ from en for '{key}'")

    # Arabic script check
    for key, value in sorted(tables.get("ar", {}).items()):
        if key in ARABIC_LATIN_ALLOWLIST:
            continue
        if not has_arabic(value):
            failures.append(f"ar: value for '{key}' contains no Arabic script "
                            f"(looks untranslated): {value!r}")

    # hard-coded display strings in components
    literal = re.compile(r'(?:\.text|\.accessibilityLabel|setTitle\()\s*=?\s*"([^"]{2,})"')
    for folder, _dirs, files in os.walk(UI):
        for name in files:
            if not name.endswith(".swift"):
                continue
            path = os.path.join(folder, name)
            for number, line in enumerate(open(path, encoding="utf-8"), 1):
                if "SpicyL10n" in line or "localized" in line or "\\(" in line:
                    continue
                found = literal.search(line)
                if found:
                    warnings.append(
                        f"{name}:{number}: possible hard-coded display string "
                        f"{found.group(1)!r}")

    report = {
        "tables": {k: len(v) for k, v in sorted(tables.items())},
        "declared_keys": len(declared),
        "failures": failures,
        "warnings": warnings,
        "result": "PASS" if not failures else "FAIL",
    }
    print(json.dumps(report, indent=1, ensure_ascii=False))
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
