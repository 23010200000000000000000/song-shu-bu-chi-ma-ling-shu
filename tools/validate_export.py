#!/usr/bin/env python3
"""
Validate export builds
Checks that Demo and Full versions are correctly configured
"""

import os
import sys
import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
EXPORT_DIR = PROJECT_ROOT / "export"


def print_header(text):
    """Print formatted header"""
    print("\n" + "=" * 60)
    print(text)
    print("=" * 60)


def validate_build(build_dir, expected_config):
    """Validate a build directory"""
    print(f"\n[Validate] Checking {build_dir.name} build...")

    errors = []
    warnings = []

    # Check build_config.json exists
    config_path = build_dir / "build_config.json"
    if not config_path.exists():
        errors.append("build_config.json not found")
        return errors, warnings

    # Load config
    with open(config_path, 'r', encoding='utf-8') as f:
        config = json.load(f)

    # Validate build flavor
    if config.get("build_flavor") != expected_config["build_flavor"]:
        errors.append(f"Wrong build flavor: {config.get('build_flavor')}")

    # Validate chapters
    expected_chapters = set(expected_config["chapters"])
    actual_chapters = set(config.get("chapters_available", []))

    if expected_chapters != actual_chapters:
        errors.append(f"Chapter mismatch: expected {expected_chapters}, got {actual_chapters}")

    # Check chapter files exist
    content_dir = build_dir / "content" / "main"
    if content_dir.exists():
        for chapter in expected_config["chapters"]:
            chapter_file = content_dir / f"chapter_{chapter}.json"
            if not chapter_file.exists():
                errors.append(f"Missing chapter file: chapter_{chapter}.json")
    else:
        warnings.append("Content directory not found (may not be exported yet)")

    # Validate side stories
    expected_stories = set(expected_config["side_stories"])
    actual_stories = set(config.get("side_stories_available", []))

    if expected_stories != actual_stories:
        errors.append(f"Side story mismatch: expected {expected_stories}, got {actual_stories}")

    # Check side story files exist
    side_dir = build_dir / "content" / "side"
    if side_dir.exists():
        for case_num in expected_config["side_stories"]:
            case_file = side_dir / f"case_{case_num}.json"
            if not case_file.exists():
                errors.append(f"Missing side story file: case_{case_num}.json")

    # Validate save slots
    if config.get("max_save_slots") != expected_config["save_slots"]:
        errors.append(f"Save slot mismatch: expected {expected_config['save_slots']}, got {config.get('max_save_slots')}")

    # Validate achievements
    if config.get("max_achievements") != expected_config["achievements"]:
        errors.append(f"Achievement mismatch: expected {expected_config['achievements']}, got {config.get('max_achievements')}")

    # Check README exists
    readme_path = build_dir / "README.txt"
    if not readme_path.exists():
        warnings.append("README.txt not found")

    # Check executable exists
    exe_path = build_dir / f"{expected_config['build_flavor']}.exe"
    if not exe_path.exists():
        warnings.append(f"Executable not found: {exe_path.name}")

    # Print results
    if not errors and not warnings:
        print("[OK] All checks passed")
    else:
        if errors:
            print(f"[X] {len(errors)} error(s):")
            for error in errors:
                print(f"    - {error}")
        if warnings:
            print(f"[!] {len(warnings)} warning(s):")
            for warning in warnings:
                print(f"    - {warning}")

    return errors, warnings


def main():
    """Main validation function"""
    print_header("EXPORT VALIDATION")

    # Demo config
    demo_config = {
        "build_flavor": "demo",
        "chapters": [1, 2, 3],
        "side_stories": [1],
        "achievements": 20,
        "save_slots": 10
    }

    # Full config
    full_config = {
        "build_flavor": "full",
        "chapters": [1, 2, 3, 4, 5, 6, 7],
        "side_stories": [1, 2, 3],
        "achievements": 60,
        "save_slots": 100
    }

    total_errors = 0
    total_warnings = 0

    # Validate demo
    demo_dir = EXPORT_DIR / "demo"
    if demo_dir.exists():
        errors, warnings = validate_build(demo_dir, demo_config)
        total_errors += len(errors)
        total_warnings += len(warnings)
    else:
        print("\n[!] Demo build directory not found")
        total_warnings += 1

    # Validate full
    full_dir = EXPORT_DIR / "full"
    if full_dir.exists():
        errors, warnings = validate_build(full_dir, full_config)
        total_errors += len(errors)
        total_warnings += len(warnings)
    else:
        print("\n[!] Full build directory not found")
        total_warnings += 1

    # Summary
    print_header("VALIDATION SUMMARY")
    print(f"Errors: {total_errors}")
    print(f"Warnings: {total_warnings}")

    if total_errors > 0:
        print("\n[X] Validation failed!")
        sys.exit(1)
    elif total_warnings > 0:
        print("\n[!] Validation passed with warnings")
        sys.exit(0)
    else:
        print("\n[OK] All validations passed!")
        sys.exit(0)


if __name__ == "__main__":
    main()
