#!/usr/bin/env python3
"""
Master Validation Script
Runs all validation checks in sequence
"""

import subprocess
import sys
from pathlib import Path

TOOLS_DIR = Path(__file__).parent

VALIDATORS = [
    ("Engine Version", "validate_engine.py"),
    ("Localization", "validate_locales.py"),
    ("Content", "validate_content.py"),
]


def run_validator(name, script):
    """Run a validation script"""
    print(f"\n{'='*60}")
    print(f"Running: {name}")
    print('='*60)

    script_path = TOOLS_DIR / script

    if not script_path.exists():
        print(f"[X] Validator not found: {script_path}")
        return False

    try:
        result = subprocess.run(
            [sys.executable, str(script_path)],
            cwd=TOOLS_DIR,
            capture_output=False,
            text=True
        )

        return result.returncode == 0

    except Exception as e:
        print(f"[X] Error running validator: {e}")
        return False


def main():
    print("="*60)
    print("MASTER VALIDATION - ALL CHECKS")
    print("="*60)
    print(f"Running {len(VALIDATORS)} validation suites...")

    results = []

    for name, script in VALIDATORS:
        passed = run_validator(name, script)
        results.append((name, passed))

    # Final summary
    print("\n" + "="*60)
    print("FINAL VALIDATION SUMMARY")
    print("="*60)

    all_passed = True
    for name, passed in results:
        status = "[OK]" if passed else "[X]"
        print(f"{status} {name}")
        if not passed:
            all_passed = False

    print("\n" + "="*60)

    if all_passed:
        print("[OK] ALL VALIDATIONS PASSED!")
        print("="*60)
        sys.exit(0)
    else:
        print("[X] SOME VALIDATIONS FAILED")
        print("="*60)
        print("\nNote: Some failures are expected during development:")
        print("  - Missing locale files (need translation)")
        print("  - Godot not in PATH (install Godot 4.6)")
        print("\nRun individual validators for details.")
        sys.exit(1)


if __name__ == "__main__":
    main()
