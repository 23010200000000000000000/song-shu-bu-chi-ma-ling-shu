#!/usr/bin/env python3
"""
Export Demo and Full versions of the game
Handles content filtering and build configuration
"""

import os
import sys
import json
import shutil
import subprocess
from pathlib import Path
from datetime import datetime

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent
EXPORT_DIR = PROJECT_ROOT / "export"
CONTENT_DIR = PROJECT_ROOT / "content"

# Build configurations
DEMO_CONFIG = {
    "name": "万历十四年·朱笔未落 (Demo)",
    "chapters": [1, 2, 3],  # Only first 3 chapters
    "side_stories": [1],     # Only first side story
    "achievements": 20,      # Subset of achievements
    "save_slots": 10,        # Limited save slots
    "build_flavor": "demo"
}

FULL_CONFIG = {
    "name": "万历十四年·朱笔未落",
    "chapters": [1, 2, 3, 4, 5, 6, 7],  # All chapters
    "side_stories": [1, 2, 3],           # All side stories
    "achievements": 60,                  # All achievements
    "save_slots": 100,                   # Full save slots
    "build_flavor": "full"
}


def print_header(text):
    """Print formatted header"""
    print("\n" + "=" * 60)
    print(text)
    print("=" * 60)


def create_export_dirs():
    """Create export directories"""
    print("[Export] Creating export directories...")

    demo_dir = EXPORT_DIR / "demo"
    full_dir = EXPORT_DIR / "full"

    demo_dir.mkdir(parents=True, exist_ok=True)
    full_dir.mkdir(parents=True, exist_ok=True)

    print(f"[OK] Created: {demo_dir}")
    print(f"[OK] Created: {full_dir}")

    return demo_dir, full_dir


def filter_content(config, output_dir):
    """Filter content based on build configuration"""
    print(f"[Export] Filtering content for {config['build_flavor']}...")

    content_output = output_dir / "content"
    content_output.mkdir(parents=True, exist_ok=True)

    # Copy main story chapters
    main_dir = content_output / "main"
    main_dir.mkdir(exist_ok=True)

    for chapter in config["chapters"]:
        src = CONTENT_DIR / "main" / f"chapter_{chapter}.json"
        if src.exists():
            dst = main_dir / f"chapter_{chapter}.json"
            shutil.copy2(src, dst)
            print(f"[OK] Copied chapter {chapter}")

    # Copy manifest (filtered)
    manifest_src = CONTENT_DIR / "main" / "manifest.json"
    if manifest_src.exists():
        with open(manifest_src, 'r', encoding='utf-8') as f:
            manifest = json.load(f)

        # Filter chapters
        manifest["chapters"] = [
            ch for ch in manifest["chapters"]
            if ch["chapter"] in config["chapters"]
        ]

        manifest_dst = main_dir / "manifest.json"
        with open(manifest_dst, 'w', encoding='utf-8') as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)
        print("[OK] Filtered manifest")

    # Copy side stories
    side_dir = content_output / "side"
    side_dir.mkdir(exist_ok=True)

    for case_num in config["side_stories"]:
        src = CONTENT_DIR / "side" / f"case_{case_num}.json"
        if src.exists():
            dst = side_dir / f"case_{case_num}.json"
            shutil.copy2(src, dst)
            print(f"[OK] Copied side story {case_num}")

    # Copy vocabulary (full for both versions)
    vocab_dir = content_output / "vocabulary"
    vocab_dir.mkdir(exist_ok=True)

    vocab_src = CONTENT_DIR / "vocabulary" / "vocab_database.json"
    if vocab_src.exists():
        shutil.copy2(vocab_src, vocab_dir / "vocab_database.json")
        print("[OK] Copied vocabulary database")

    print(f"[OK] Content filtered for {config['build_flavor']}")


def update_build_config(config, output_dir):
    """Update GameState.gd with build configuration"""
    print(f"[Export] Updating build configuration...")

    # This would modify GameState.gd BUILD_FLAVOR constant
    # For now, we'll create a build_config.json that the game reads

    build_config = {
        "build_flavor": config["build_flavor"],
        "build_date": datetime.now().isoformat(),
        "chapters_available": config["chapters"],
        "side_stories_available": config["side_stories"],
        "max_achievements": config["achievements"],
        "max_save_slots": config["save_slots"]
    }

    config_path = output_dir / "build_config.json"
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(build_config, f, indent=2)

    print(f"[OK] Build config written to {config_path}")


def export_godot(config, output_dir, preset_name):
    """Export using Godot"""
    print(f"[Export] Exporting with Godot preset: {preset_name}...")

    # Find Godot executable
    godot_paths = [
        "godot",
        "C:/Program Files/Godot/godot.exe",
        "/usr/bin/godot",
        "/usr/local/bin/godot"
    ]

    godot_exe = None
    for path in godot_paths:
        if shutil.which(path) or Path(path).exists():
            godot_exe = path
            break

    if not godot_exe:
        print("[!] Godot executable not found. Please export manually.")
        print(f"[!] Use preset: {preset_name}")
        return False

    # Export command
    export_path = output_dir / f"{config['build_flavor']}.exe"
    cmd = [
        godot_exe,
        "--headless",
        "--export-release",
        preset_name,
        str(export_path)
    ]

    try:
        result = subprocess.run(
            cmd,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=300
        )

        if result.returncode == 0:
            print(f"[OK] Exported to {export_path}")
            return True
        else:
            print(f"[!] Export failed: {result.stderr}")
            return False

    except subprocess.TimeoutExpired:
        print("[!] Export timed out")
        return False
    except Exception as e:
        print(f"[!] Export error: {e}")
        return False


def create_readme(config, output_dir):
    """Create README for the build"""
    print("[Export] Creating README...")

    readme_content = f"""# {config['name']}

**Build**: {config['build_flavor'].upper()}
**Date**: {datetime.now().strftime('%Y-%m-%d')}

## Contents

- Chapters: {len(config['chapters'])} ({', '.join(map(str, config['chapters']))})
- Side Stories: {len(config['side_stories'])}
- Achievements: {config['achievements']}
- Save Slots: {config['save_slots']}

## Installation

1. Extract all files to a folder
2. Run the executable
3. Enjoy!

## System Requirements

- OS: Windows 10/11 (64-bit)
- GPU: Intel Arc iGPU or equivalent
- RAM: 32GB (shared VRAM ≤8GB for game)
- Storage: 5GB available space

## Support

For issues or feedback, please visit:
[GitHub Repository URL]

---

© 2026 - All Rights Reserved
"""

    readme_path = output_dir / "README.txt"
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(readme_content)

    print(f"[OK] README created at {readme_path}")


def main():
    """Main export function"""
    import argparse

    parser = argparse.ArgumentParser(description="Export game builds")
    parser.add_argument("--demo", action="store_true", help="Export demo version")
    parser.add_argument("--full", action="store_true", help="Export full version")
    parser.add_argument("--both", action="store_true", help="Export both versions")

    args = parser.parse_args()

    if not (args.demo or args.full or args.both):
        print("Usage: python export_demo_full.py [--demo] [--full] [--both]")
        sys.exit(1)

    print_header("GAME EXPORT TOOL")
    print(f"Project: {PROJECT_ROOT}")

    # Create export directories
    demo_dir, full_dir = create_export_dirs()

    # Export demo
    if args.demo or args.both:
        print_header("EXPORTING DEMO VERSION")
        filter_content(DEMO_CONFIG, demo_dir)
        update_build_config(DEMO_CONFIG, demo_dir)
        create_readme(DEMO_CONFIG, demo_dir)
        export_godot(DEMO_CONFIG, demo_dir, "Windows Desktop (Demo)")

    # Export full
    if args.full or args.both:
        print_header("EXPORTING FULL VERSION")
        filter_content(FULL_CONFIG, full_dir)
        update_build_config(FULL_CONFIG, full_dir)
        create_readme(FULL_CONFIG, full_dir)
        export_godot(FULL_CONFIG, full_dir, "Windows Desktop (Full)")

    print_header("EXPORT COMPLETE")
    print(f"Demo: {demo_dir}")
    print(f"Full: {full_dir}")


if __name__ == "__main__":
    main()
