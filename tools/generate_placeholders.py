#!/usr/bin/env python3
"""
Placeholder Asset Generator
Creates simple placeholder images for development
Uses PIL/Pillow to generate images with paper texture aesthetic
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("[X] PIL/Pillow not installed")
    print("    Install with: pip install Pillow")
    sys.exit(1)

PROJECT_ROOT = Path(__file__).parent.parent
ASSETS_DIR = PROJECT_ROOT / "assets"
IMAGES_DIR = ASSETS_DIR / "images"


class PlaceholderGenerator:
    def __init__(self):
        self.paper_color = (232, 224, 216)  # Warm paper color
        self.ink_color = (45, 37, 32)  # Dark ink color
        self.accent_color = (180, 150, 120)  # Muted gold

    def create_background(self, width, height, name, text="Background"):
        """Create a placeholder background"""
        img = Image.new('RGB', (width, height), self.paper_color)
        draw = ImageDraw.Draw(img)

        # Add subtle texture lines
        for i in range(0, height, 40):
            draw.line([(0, i), (width, i)], fill=(220, 212, 204), width=1)

        # Add border
        border_width = 20
        draw.rectangle(
            [border_width, border_width, width - border_width, height - border_width],
            outline=self.ink_color,
            width=3
        )

        # Add text label
        try:
            font = ImageFont.truetype("arial.ttf", 48)
        except:
            font = ImageFont.load_default()

        text_bbox = draw.textbbox((0, 0), text, font=font)
        text_width = text_bbox[2] - text_bbox[0]
        text_height = text_bbox[3] - text_bbox[1]

        text_x = (width - text_width) // 2
        text_y = (height - text_height) // 2

        draw.text((text_x, text_y), text, fill=self.ink_color, font=font)

        # Add size label
        size_text = f"{width}x{height}"
        try:
            small_font = ImageFont.truetype("arial.ttf", 24)
        except:
            small_font = ImageFont.load_default()

        draw.text((width - 150, height - 40), size_text, fill=self.accent_color, font=small_font)

        return img

    def create_character_sprite(self, width, height, name, character_name):
        """Create a placeholder character sprite"""
        img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Draw simple character silhouette
        center_x = width // 2
        center_y = height // 2

        # Head
        head_radius = width // 8
        draw.ellipse(
            [center_x - head_radius, center_y - height // 3 - head_radius,
             center_x + head_radius, center_y - height // 3 + head_radius],
            fill=self.ink_color + (200,),
            outline=self.ink_color + (255,)
        )

        # Body
        body_width = width // 3
        body_height = height // 2
        draw.rectangle(
            [center_x - body_width // 2, center_y - height // 6,
             center_x + body_width // 2, center_y + body_height // 2],
            fill=self.ink_color + (200,),
            outline=self.ink_color + (255,)
        )

        # Add character name
        try:
            font = ImageFont.truetype("arial.ttf", 36)
        except:
            font = ImageFont.load_default()

        text_bbox = draw.textbbox((0, 0), character_name, font=font)
        text_width = text_bbox[2] - text_bbox[0]

        draw.text(
            ((width - text_width) // 2, height - 80),
            character_name,
            fill=self.ink_color + (255,),
            font=font
        )

        return img

    def create_ui_element(self, width, height, name, label):
        """Create a placeholder UI element"""
        img = Image.new('RGBA', (width, height), self.paper_color + (255,))
        draw = ImageDraw.Draw(img)

        # Border
        draw.rectangle([0, 0, width - 1, height - 1], outline=self.ink_color, width=2)

        # Label
        try:
            font = ImageFont.truetype("arial.ttf", 24)
        except:
            font = ImageFont.load_default()

        text_bbox = draw.textbbox((0, 0), label, font=font)
        text_width = text_bbox[2] - text_bbox[0]
        text_height = text_bbox[3] - text_bbox[1]

        draw.text(
            ((width - text_width) // 2, (height - text_height) // 2),
            label,
            fill=self.ink_color,
            font=font
        )

        return img

    def generate_all(self):
        """Generate all placeholder assets"""
        print("[PlaceholderGenerator] Starting generation...")

        # Ensure directories exist
        (IMAGES_DIR / "backgrounds").mkdir(parents=True, exist_ok=True)
        (IMAGES_DIR / "characters").mkdir(parents=True, exist_ok=True)
        (IMAGES_DIR / "ui").mkdir(parents=True, exist_ok=True)

        assets_created = []

        # Backgrounds (4K, 16:9)
        backgrounds = [
            ("home_bg.png", "Main Menu"),
            ("chapter_1_bg.png", "Chapter 1"),
            ("chapter_2_bg.png", "Chapter 2"),
            ("chapter_3_bg.png", "Chapter 3"),
            ("chapter_4_bg.png", "Chapter 4"),
            ("chapter_5_bg.png", "Chapter 5"),
            ("chapter_6_bg.png", "Chapter 6"),
            ("chapter_7_bg.png", "Chapter 7"),
            ("investigation_bg.png", "Investigation"),
            ("archive_bg.png", "Archive Hall"),
        ]

        print("\n[Backgrounds] Generating 4K backgrounds...")
        for filename, label in backgrounds:
            img = self.create_background(3840, 2160, filename, label)
            path = IMAGES_DIR / "backgrounds" / filename
            img.save(path)
            assets_created.append(str(path))
            print(f"  [OK] {filename}")

        # Character sprites (3000px height, transparent)
        characters = [
            ("emperor_full.png", "Emperor", 2000, 3000),
            ("emperor_half.png", "Emperor", 1500, 2200),
            ("consort_full.png", "Consort", 2000, 3000),
            ("consort_half.png", "Consort", 1500, 2200),
            ("minister_full.png", "Minister", 2000, 3000),
            ("minister_half.png", "Minister", 1500, 2200),
        ]

        print("\n[Characters] Generating character sprites...")
        for filename, name, width, height in characters:
            img = self.create_character_sprite(width, height, filename, name)
            path = IMAGES_DIR / "characters" / filename
            img.save(path)
            assets_created.append(str(path))
            print(f"  [OK] {filename}")

        # UI elements
        ui_elements = [
            ("button_normal.png", "Button", 200, 60),
            ("button_hover.png", "Hover", 200, 60),
            ("button_pressed.png", "Pressed", 200, 60),
            ("panel_bg.png", "Panel", 800, 600),
            ("dialogue_box.png", "Dialogue", 1800, 300),
            ("evidence_card.png", "Evidence", 400, 600),
        ]

        print("\n[UI Elements] Generating UI elements...")
        for filename, label, width, height in ui_elements:
            img = self.create_ui_element(width, height, filename, label)
            path = IMAGES_DIR / "ui" / filename
            img.save(path)
            assets_created.append(str(path))
            print(f"  [OK] {filename}")

        # Generate asset list
        self.generate_asset_list(assets_created)

        print(f"\n[OK] Generated {len(assets_created)} placeholder assets")
        print(f"     Output: {IMAGES_DIR}")

    def generate_asset_list(self, assets):
        """Generate a list of all created assets"""
        list_path = IMAGES_DIR / "ASSET_LIST.txt"

        with open(list_path, 'w', encoding='utf-8') as f:
            f.write("# Placeholder Assets List\n")
            f.write(f"# Generated: {Path(__file__).name}\n")
            f.write(f"# Total: {len(assets)} files\n\n")

            f.write("## Backgrounds (4K, 16:9)\n")
            for asset in assets:
                if "backgrounds" in asset:
                    f.write(f"- {Path(asset).name}\n")

            f.write("\n## Characters (Transparent PNG)\n")
            for asset in assets:
                if "characters" in asset:
                    f.write(f"- {Path(asset).name}\n")

            f.write("\n## UI Elements\n")
            for asset in assets:
                if "ui" in asset:
                    f.write(f"- {Path(asset).name}\n")

        print(f"\n[OK] Asset list: {list_path}")


def main():
    print("="*60)
    print("PLACEHOLDER ASSET GENERATOR")
    print("="*60)

    generator = PlaceholderGenerator()
    generator.generate_all()

    print("\n" + "="*60)
    print("[OK] Asset generation complete!")
    print("="*60)
    print("\nNote: These are placeholder assets for development.")
    print("Replace with final art assets before release.")


if __name__ == "__main__":
    main()
