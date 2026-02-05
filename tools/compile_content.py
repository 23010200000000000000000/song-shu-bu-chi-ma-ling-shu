#!/usr/bin/env python3
"""
Content Compiler - Converts source content to runtime format
Processes story files from _source and generates JSON for the game
"""

import json
import os
import re
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any

# Paths
PROJECT_ROOT = Path(__file__).parent.parent
SOURCE_DIR = PROJECT_ROOT.parent / "source" / "content" / "_source"
OUTPUT_DIR = PROJECT_ROOT / "content"
MAIN_SOURCE = SOURCE_DIR / "main"
SIDE_SOURCE = SOURCE_DIR / "side"


class ContentCompiler:
    def __init__(self):
        self.node_counter = 0
        self.errors = []
        self.warnings = []

    def compile_all(self):
        """Compile all content"""
        print("[ContentCompiler] Starting compilation...")
        print(f"Source: {SOURCE_DIR}")
        print(f"Output: {OUTPUT_DIR}")

        # Ensure output directories exist
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        (OUTPUT_DIR / "main").mkdir(exist_ok=True)
        (OUTPUT_DIR / "side").mkdir(exist_ok=True)

        # Compile main story
        self.compile_main_story()

        # Compile side stories
        self.compile_side_stories()

        # Generate manifest
        self.generate_manifest()

        # Report
        self.print_report()

    def compile_main_story(self):
        """Compile main story chapters"""
        print("\n[Main Story] Compiling...")

        if not MAIN_SOURCE.exists():
            self.errors.append(f"Main source directory not found: {MAIN_SOURCE}")
            return

        # For now, generate placeholder chapters
        for chapter in range(1, 8):  # 7 chapters
            chapter_data = self.generate_chapter_placeholder(chapter)
            output_path = OUTPUT_DIR / "main" / f"chapter_{chapter}.json"

            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(chapter_data, f, ensure_ascii=False, indent=2)

            print(f"  [OK] Chapter {chapter}: {len(chapter_data['nodes'])} nodes")

    def generate_chapter_placeholder(self, chapter: int) -> Dict[str, Any]:
        """Generate placeholder chapter data with proper structure"""
        nodes = {}

        # Start node
        start_id = f"CH{chapter}_START"
        nodes[start_id] = {
            "id": start_id,
            "type": "dialogue",
            "speaker": "narrator",
            "text": {
                "english": f"Chapter {chapter}: The Investigation Begins\n\nYou are summoned to the palace to investigate a mysterious case.",
                "schinese": f"第{chapter}章：调查开始\n\n你被召入宫中调查一桩神秘案件。"
            },
            "next": f"CH{chapter}_002",
            "pov": "all",
            "tags": ["intro"]
        }

        # Emperor perspective nodes
        for i in range(2, 6):
            node_id = f"CH{chapter}_{i:03d}"
            nodes[node_id] = {
                "id": node_id,
                "type": "dialogue",
                "speaker": "emperor" if i % 3 == 0 else "narrator",
                "text": {
                    "english": f"Emperor's perspective: This is dialogue node {i} of chapter {chapter}. The investigation continues.",
                    "schinese": f"万历视角：这是第{chapter}章的第{i}个对话节点。调查继续进行。"
                },
                "next": f"CH{chapter}_{i+1:03d}" if i < 5 else f"CH{chapter}_CONSORT_001",
                "pov": "emperor",
                "tags": ["emperor_view"]
            }

        # Consort perspective nodes
        for i in range(1, 4):
            node_id = f"CH{chapter}_CONSORT_{i:03d}"
            nodes[node_id] = {
                "id": node_id,
                "type": "dialogue",
                "speaker": "consort" if i % 2 == 0 else "narrator",
                "text": {
                    "english": f"Consort's perspective: Node {i}. Different evidence emerges from this viewpoint.",
                    "schinese": f"郑贵妃视角：节点{i}。从这个视角出现了不同的证据。"
                },
                "next": f"CH{chapter}_CONSORT_{i+1:03d}" if i < 3 else f"CH{chapter}_MINISTER_001",
                "pov": "consort",
                "tags": ["consort_view"]
            }

        # Minister perspective nodes
        for i in range(1, 4):
            node_id = f"CH{chapter}_MINISTER_{i:03d}"
            nodes[node_id] = {
                "id": node_id,
                "type": "dialogue",
                "speaker": "minister" if i % 2 == 1 else "narrator",
                "text": {
                    "english": f"Minister's perspective: Node {i}. Bureaucratic details reveal the truth.",
                    "schinese": f"申时行视角：节点{i}。官僚细节揭示真相。"
                },
                "next": f"CH{chapter}_MINISTER_{i+1:03d}" if i < 3 else f"CH{chapter}_INVESTIGATION",
                "pov": "minister",
                "tags": ["minister_view"]
            }

        # Investigation node
        nodes[f"CH{chapter}_INVESTIGATION"] = {
            "id": f"CH{chapter}_INVESTIGATION",
            "type": "investigation",
            "text": {
                "english": "Time to compare the evidence from all three perspectives.",
                "schinese": "是时候比对三个视角的证据了。"
            },
            "next": f"CH{chapter}_END",
            "pov": "all",
            "tags": ["investigation"]
        }

        # End node
        nodes[f"CH{chapter}_END"] = {
            "id": f"CH{chapter}_END",
            "type": "chapter_end",
            "text": {
                "english": f"End of Chapter {chapter}\n\nYou have completed this chapter. The investigation continues...",
                "schinese": f"第{chapter}章结束\n\n你已完成本章。调查仍在继续..."
            },
            "next": f"CH{chapter+1}_START" if chapter < 7 else "ENDING",
            "pov": "all",
            "tags": ["chapter_end"]
        }

        return {
            "chapter": chapter,
            "title": {
                "english": f"Chapter {chapter}",
                "schinese": f"第{chapter}章"
            },
            "nodes": nodes,
            "metadata": {
                "compiled_at": datetime.now().isoformat(),
                "compiler_version": "1.0.0",
                "node_count": len(nodes),
                "source": "placeholder_generator"
            }
        }

    def compile_side_stories(self):
        """Compile side stories (turtle soup cases)"""
        print("\n[Side Stories] Compiling...")

        # Generate placeholder turtle soup cases
        for case_num in range(1, 4):  # 3 cases for demo
            case_data = self.generate_turtle_soup_case(case_num)
            output_path = OUTPUT_DIR / "side" / f"case_{case_num}.json"

            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(case_data, f, ensure_ascii=False, indent=2)

            print(f"  [OK] Case {case_num}: {case_data['title']['english']}")

    def generate_turtle_soup_case(self, case_num: int) -> Dict[str, Any]:
        """Generate placeholder turtle soup case"""
        return {
            "case_id": f"CASE_{case_num:03d}",
            "title": {
                "english": f"The Mystery of Case {case_num}",
                "schinese": f"案件{case_num}之谜"
            },
            "difficulty": "medium",
            "scenario": {
                "english": f"A mysterious event occurred in the palace. What really happened?",
                "schinese": f"宫中发生了一件神秘事件。究竟发生了什么？"
            },
            "questions": [
                {
                    "id": "Q001",
                    "text": {
                        "english": "Was anyone injured?",
                        "schinese": "有人受伤吗？"
                    },
                    "answer": "yes",
                    "unlocks": ["Q002", "Q003"]
                },
                {
                    "id": "Q002",
                    "text": {
                        "english": "Did it happen at night?",
                        "schinese": "是在夜间发生的吗？"
                    },
                    "answer": "no",
                    "unlocks": ["Q004"]
                },
                {
                    "id": "Q003",
                    "text": {
                        "english": "Was it an accident?",
                        "schinese": "这是意外吗？"
                    },
                    "answer": "irrelevant",
                    "unlocks": []
                },
                {
                    "id": "Q004",
                    "text": {
                        "english": "Were there witnesses?",
                        "schinese": "有目击者吗？"
                    },
                    "answer": "yes",
                    "unlocks": ["SOLUTION"]
                }
            ],
            "solution": {
                "english": "The truth was hidden in plain sight. The evidence reveals what really happened.",
                "schinese": "真相就藏在眼前。证据揭示了真正发生的事情。"
            },
            "hints": [
                {
                    "english": "Think about the timing of events.",
                    "schinese": "思考事件的时间顺序。"
                },
                {
                    "english": "Consider who had access to the location.",
                    "schinese": "考虑谁能进入现场。"
                }
            ],
            "metadata": {
                "compiled_at": datetime.now().isoformat(),
                "estimated_time": "10-15 minutes"
            }
        }

    def generate_manifest(self):
        """Generate content manifest"""
        print("\n[Manifest] Generating...")

        manifest = {
            "version": "1.0.0",
            "compiled_at": datetime.now().isoformat(),
            "content": {
                "main_chapters": 7,
                "side_cases": 3,
                "total_nodes": 0
            },
            "chapters": [],
            "cases": []
        }

        # Count main story nodes
        for chapter in range(1, 8):
            chapter_file = OUTPUT_DIR / "main" / f"chapter_{chapter}.json"
            if chapter_file.exists():
                with open(chapter_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    node_count = len(data.get('nodes', {}))
                    manifest["content"]["total_nodes"] += node_count
                    manifest["chapters"].append({
                        "chapter": chapter,
                        "file": f"main/chapter_{chapter}.json",
                        "nodes": node_count
                    })

        # List side cases
        for case_num in range(1, 4):
            case_file = OUTPUT_DIR / "side" / f"case_{case_num}.json"
            if case_file.exists():
                with open(case_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    manifest["cases"].append({
                        "case_id": data["case_id"],
                        "file": f"side/case_{case_num}.json",
                        "difficulty": data.get("difficulty", "medium")
                    })

        # Write manifest
        manifest_path = OUTPUT_DIR / "manifest.json"
        with open(manifest_path, 'w', encoding='utf-8') as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)

        print(f"  [OK] Manifest: {manifest['content']['total_nodes']} total nodes")

    def print_report(self):
        """Print compilation report"""
        print("\n" + "="*60)
        print("COMPILATION REPORT")
        print("="*60)

        if self.errors:
            print(f"\n[X] ERRORS ({len(self.errors)}):")
            for error in self.errors:
                print(f"  - {error}")

        if self.warnings:
            print(f"\n[!] WARNINGS ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  - {warning}")

        if not self.errors:
            print("\n[OK] Compilation successful!")
            print(f"   Output: {OUTPUT_DIR}")
        else:
            print("\n[X] Compilation failed!")
            sys.exit(1)


def main():
    compiler = ContentCompiler()
    compiler.compile_all()


if __name__ == "__main__":
    main()
