#!/usr/bin/env python3
"""
Validate Engine Version
Ensures Godot 4.6.stable.official.89cea1439 is being used
"""

import subprocess
import sys
from pathlib import Path

REQUIRED_VERSION = "4.6.stable.official.89cea1439"


def check_godot_version():
    """Check if Godot is installed and has correct version"""
    print("[Validate Engine] Checking Godot version...")

    try:
        # Try to run godot --version
        result = subprocess.run(
            ["godot", "--version"],
            capture_output=True,
            text=True,
            timeout=5
        )

        if result.returncode != 0:
            print(f"[X] Failed to run godot command")
            print(f"    Make sure Godot is in PATH")
            return False

        version = result.stdout.strip()
        print(f"    Found: {version}")
        print(f"    Required: {REQUIRED_VERSION}")

        if version == REQUIRED_VERSION:
            print("[OK] Godot version matches!")
            return True
        else:
            print("[X] Godot version mismatch!")
            print(f"    Please install exact version: {REQUIRED_VERSION}")
            return False

    except FileNotFoundError:
        print("[X] Godot not found in PATH")
        print("    Please install Godot 4.6 and add to PATH")
        return False
    except subprocess.TimeoutExpired:
        print("[X] Godot command timed out")
        return False
    except Exception as e:
        print(f"[X] Error checking Godot: {e}")
        return False


def check_project_file():
    """Check if project.godot exists and is valid"""
    print("\n[Validate Engine] Checking project file...")

    project_file = Path(__file__).parent.parent / "project.godot"

    if not project_file.exists():
        print(f"[X] project.godot not found at {project_file}")
        return False

    # Read and check config_version
    with open(project_file, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'config_version=5' not in content:
        print("[X] project.godot has wrong config_version (should be 5 for Godot 4.x)")
        return False

    if '"4.6"' not in content and '"4.6", "Forward Plus"' not in content:
        print("[!] Warning: project.godot may not specify Godot 4.6")

    print("[OK] project.godot is valid")
    return True


def main():
    print("="*60)
    print("GODOT ENGINE VALIDATION")
    print("="*60)

    results = []

    # Check Godot version
    results.append(("Godot Version", check_godot_version()))

    # Check project file
    results.append(("Project File", check_project_file()))

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
        print("\n[OK] All engine validations passed!")
        sys.exit(0)
    else:
        print("\n[X] Some validations failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
