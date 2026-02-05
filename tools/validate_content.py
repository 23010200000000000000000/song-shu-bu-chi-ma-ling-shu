#!/usr/bin/env python3
"""
Validate Content
Checks compiled story content for completeness and consistency
"""

import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
CONTENT_DIR = PROJECT_ROOT / "content"


def check_manifest():
    """Check content manifest"""
    print("[Validate Content] Checking manifest...")

    manifest_path = CONTENT_DIR / "manifest.json"

    if not manifest_path.exists():
        print(f"[X] Manifest not found: {manifest_path}")
        print("    Run compile_content.py first")
        return False

    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    expected_chapters = 7
    actual_chapters = manifest.get("content", {}).get("main_chapters", 0)

    if actual_chapters != expected_chapters:
        print(f"[X] Expected {expected_chapters} chapters, found {actual_chapters}")
        return False

    total_nodes = manifest.get("content", {}).get("total_nodes", 0)
    print(f"[OK] Manifest valid: {actual_chapters} chapters, {total_nodes} nodes")
    return True


def check_chapters():
    """Check all chapter files"""
    print("\n[Validate Content] Checking chapters...")

    errors = []

    for chapter in range(1, 8):
        chapter_file = CONTENT_DIR / "main" / f"chapter_{chapter}.json"

        if not chapter_file.exists():
            errors.append(f"Chapter {chapter} file missing")
            continue

        try:
            with open(chapter_file, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # Validate structure
            if "nodes" not in data:
                errors.append(f"Chapter {chapter}: missing 'nodes' key")
                continue

            nodes = data["nodes"]
            if not nodes:
                errors.append(f"Chapter {chapter}: no nodes defined")
                continue

            # Check start node exists
            start_node = f"CH{chapter}_START"
            if start_node not in nodes:
                errors.append(f"Chapter {chapter}: missing start node {start_node}")

            # Check node structure
            for node_id, node_data in nodes.items():
                if "type" not in node_data:
                    errors.append(f"Chapter {chapter}, node {node_id}: missing 'type'")

                if "text" not in node_data and node_data.get("type") != "choice":
                    errors.append(f"Chapter {chapter}, node {node_id}: missing 'text'")

            print(f"    Chapter {chapter}: {len(nodes)} nodes")

        except json.JSONDecodeError as e:
            errors.append(f"Chapter {chapter}: invalid JSON - {e}")
        except Exception as e:
            errors.append(f"Chapter {chapter}: error - {e}")

    if errors:
        print(f"\n[X] Found {len(errors)} errors:")
        for error in errors:
            print(f"    - {error}")
        return False

    print("[OK] All chapters valid")
    return True


def check_side_stories():
    """Check side story files"""
    print("\n[Validate Content] Checking side stories...")

    side_dir = CONTENT_DIR / "side"

    if not side_dir.exists():
        print("[X] Side stories directory not found")
        return False

    case_files = list(side_dir.glob("case_*.json"))

    if not case_files:
        print("[!] No side story cases found")
        return False

    errors = []

    for case_file in case_files:
        try:
            with open(case_file, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # Validate structure
            required_keys = ["case_id", "title", "scenario", "questions", "solution"]
            for key in required_keys:
                if key not in data:
                    errors.append(f"{case_file.name}: missing '{key}'")

            print(f"    {case_file.name}: {data.get('case_id', 'unknown')}")

        except json.JSONDecodeError as e:
            errors.append(f"{case_file.name}: invalid JSON - {e}")
        except Exception as e:
            errors.append(f"{case_file.name}: error - {e}")

    if errors:
        print(f"\n[X] Found {len(errors)} errors:")
        for error in errors:
            print(f"    - {error}")
        return False

    print(f"[OK] {len(case_files)} side stories valid")
    return True


def check_node_links():
    """Check that node links are valid"""
    print("\n[Validate Content] Checking node links...")

    broken_links = []

    for chapter in range(1, 8):
        chapter_file = CONTENT_DIR / "main" / f"chapter_{chapter}.json"

        if not chapter_file.exists():
            continue

        with open(chapter_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        nodes = data.get("nodes", {})

        for node_id, node_data in nodes.items():
            next_node = node_data.get("next", "")

            if next_node and next_node != "ENDING":
                # Check if next node exists (in this chapter or next)
                if not next_node.startswith(f"CH{chapter+1}"):
                    if next_node not in nodes:
                        broken_links.append(f"Chapter {chapter}, {node_id} -> {next_node}")

    if broken_links:
        print(f"[!] Found {len(broken_links)} broken links:")
        for link in broken_links[:10]:  # Show first 10
            print(f"    - {link}")
        if len(broken_links) > 10:
            print(f"    ... and {len(broken_links) - 10} more")
        return False

    print("[OK] All node links valid")
    return True


def main():
    print("="*60)
    print("CONTENT VALIDATION")
    print("="*60)

    results = []

    # Check manifest
    results.append(("Manifest", check_manifest()))

    # Check chapters
    results.append(("Chapters", check_chapters()))

    # Check side stories
    results.append(("Side Stories", check_side_stories()))

    # Check node links
    results.append(("Node Links", check_node_links()))

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
        print("\n[OK] All content validations passed!")
        sys.exit(0)
    else:
        print("\n[X] Some validations failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
