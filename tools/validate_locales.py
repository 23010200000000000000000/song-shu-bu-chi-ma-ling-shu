#!/usr/bin/env python3
"""
Validate Locales
Checks all 29 languages for missing keys and consistency
"""

import json
import sys
from pathlib import Path
from collections import defaultdict

PROJECT_ROOT = Path(__file__).parent.parent
LOCALES_DIR = PROJECT_ROOT / "locales"
META_DIR = LOCALES_DIR / "_meta"

# Required modern languages (29)
REQUIRED_LANGUAGES = [
    "schinese", "tchinese", "english", "japanese", "koreana",
    "french", "german", "spanish", "latam", "brazilian", "portuguese",
    "russian", "italian", "dutch", "polish", "turkish",
    "thai", "vietnamese", "indonesian", "ukrainian", "czech",
    "hungarian", "romanian", "bulgarian", "greek", "danish",
    "finnish", "norwegian", "swedish", "arabic"
]


def load_language_registry():
    """Load language registry"""
    registry_path = META_DIR / "language_registry.json"

    if not registry_path.exists():
        print(f"[X] Language registry not found: {registry_path}")
        return None

    with open(registry_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    return data.get("languages", {})


def check_registry():
    """Check language registry"""
    print("[Validate Locales] Checking language registry...")

    registry = load_language_registry()
    if not registry:
        return False

    # Check all required languages are defined
    missing = []
    for lang in REQUIRED_LANGUAGES:
        if lang not in registry:
            missing.append(lang)

    if missing:
        print(f"[X] Missing languages in registry: {', '.join(missing)}")
        return False

    print(f"[OK] All {len(REQUIRED_LANGUAGES)} required languages in registry")
    return True


def check_locale_files():
    """Check locale files exist for all languages"""
    print("\n[Validate Locales] Checking locale files...")

    missing_files = []
    existing_files = []

    for lang in REQUIRED_LANGUAGES:
        locale_file = LOCALES_DIR / lang / "ui.json"

        if not locale_file.exists():
            missing_files.append(lang)
        else:
            existing_files.append(lang)

    print(f"    Found: {len(existing_files)}/{len(REQUIRED_LANGUAGES)} languages")

    if missing_files:
        print(f"[!] Missing locale files for: {', '.join(missing_files)}")
        print("    These languages will need translation files")
        return False

    print("[OK] All locale files exist")
    return True


def check_translation_keys():
    """Check for missing translation keys"""
    print("\n[Validate Locales] Checking translation keys...")

    # Load English as reference
    english_file = LOCALES_DIR / "english" / "ui.json"

    if not english_file.exists():
        print("[X] English locale file not found (needed as reference)")
        return False

    with open(english_file, 'r', encoding='utf-8') as f:
        english_keys = set(json.load(f).keys())

    print(f"    Reference keys (English): {len(english_keys)}")

    # Check each language
    missing_keys_report = {}

    for lang in REQUIRED_LANGUAGES:
        locale_file = LOCALES_DIR / lang / "ui.json"

        if not locale_file.exists():
            continue

        with open(locale_file, 'r', encoding='utf-8') as f:
            try:
                lang_data = json.load(f)
                lang_keys = set(lang_data.keys())

                missing = english_keys - lang_keys
                if missing:
                    missing_keys_report[lang] = list(missing)

            except json.JSONDecodeError as e:
                print(f"[X] Invalid JSON in {lang}: {e}")
                return False

    # Report missing keys
    if missing_keys_report:
        print(f"\n[!] Missing keys found in {len(missing_keys_report)} languages:")

        for lang, keys in missing_keys_report.items():
            print(f"    {lang}: {len(keys)} missing keys")

        # Write detailed report
        report_path = PROJECT_ROOT / "tools" / "logs" / "missing_keys_report.json"
        report_path.parent.mkdir(parents=True, exist_ok=True)

        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(missing_keys_report, f, ensure_ascii=False, indent=2)

        print(f"\n    Detailed report: {report_path}")
        return False

    print("[OK] No missing keys")
    return True


def check_rtl_languages():
    """Check RTL language configuration"""
    print("\n[Validate Locales] Checking RTL languages...")

    registry = load_language_registry()
    if not registry:
        return False

    rtl_languages = []
    for lang_code, lang_data in registry.items():
        if lang_data.get("direction") == "rtl":
            rtl_languages.append(lang_code)

    if not rtl_languages:
        print("[!] No RTL languages found (expected Arabic, Ancient Hebrew)")
        return False

    print(f"[OK] RTL languages configured: {', '.join(rtl_languages)}")
    return True


def check_fallback_rules():
    """Check fallback rules"""
    print("\n[Validate Locales] Checking fallback rules...")

    fallback_path = META_DIR / "fallback_rules.json"

    if not fallback_path.exists():
        print(f"[X] Fallback rules not found: {fallback_path}")
        return False

    with open(fallback_path, 'r', encoding='utf-8') as f:
        rules = json.load(f).get("rules", {})

    # Check all languages have fallback rules
    missing_rules = []
    for lang in REQUIRED_LANGUAGES:
        if lang not in rules:
            missing_rules.append(lang)

    if missing_rules:
        print(f"[X] Missing fallback rules for: {', '.join(missing_rules)}")
        return False

    print(f"[OK] Fallback rules defined for all languages")
    return True


def main():
    print("="*60)
    print("LOCALIZATION VALIDATION")
    print("="*60)

    results = []

    # Check registry
    results.append(("Language Registry", check_registry()))

    # Check locale files
    results.append(("Locale Files", check_locale_files()))

    # Check translation keys
    results.append(("Translation Keys", check_translation_keys()))

    # Check RTL
    results.append(("RTL Configuration", check_rtl_languages()))

    # Check fallback rules
    results.append(("Fallback Rules", check_fallback_rules()))

    # Summary
    print("\n" + "="*60)
    print("VALIDATION SUMMARY")
    print("="*60)

    all_passed = True
    for name, passed in results:
        status = "[OK]" if passed else "[X]"
        print(f"{status} {name}")
        if not passed:
            all_passed = False

    if all_passed:
        print("\n[OK] All locale validations passed!")
        sys.exit(0)
    else:
        print("\n[X] Some validations failed!")
        print("    Note: Missing locale files are expected at this stage")
        print("    Run this again after completing all translations")
        sys.exit(1)


if __name__ == "__main__":
    main()
