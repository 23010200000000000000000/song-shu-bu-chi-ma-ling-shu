# Export System Documentation

## Overview

The Export System for "万历十四年·朱笔未落" manages the creation of Demo and Full versions of the game with different content and feature sets. The system handles content filtering, build configuration, and automated export processes.

## Build Configurations

### Demo Version
- **Chapters**: 1-3 (first 3 chapters)
- **Side Stories**: 1 (first case only)
- **Achievements**: 20 (subset)
- **Save Slots**: 10 (limited)
- **Build Flavor**: "demo"
- **Purpose**: Free trial, marketing, player acquisition

### Full Version
- **Chapters**: 1-7 (all chapters)
- **Side Stories**: 1-3 (all cases)
- **Achievements**: 60 (complete set)
- **Save Slots**: 100 (full capacity)
- **Build Flavor**: "full"
- **Purpose**: Complete game experience

## Components

### 1. Export Script
**File**: `tools/export_demo_full.py`

Python script that automates the export process:
- Creates export directories
- Filters content based on build configuration
- Generates build_config.json
- Calls Godot export
- Creates README files

**Usage**:
```bash
# Export demo only
python tools/export_demo_full.py --demo

# Export full only
python tools/export_demo_full.py --full

# Export both
python tools/export_demo_full.py --both
```

### 2. Export Presets
**File**: `export_presets.cfg`

Godot export presets for Windows Desktop:
- **Preset 0**: Windows Desktop (Demo)
  - Excludes chapters 4-7
  - Excludes side stories 2-3
  - Embeds PCK file
  - 64-bit architecture

- **Preset 1**: Windows Desktop (Full)
  - Includes all content
  - Embeds PCK file
  - 64-bit architecture

### 3. BuildConfig Manager
**File**: `src/core/BuildConfig.gd`

Autoload that manages build configuration at runtime:
- Loads build_config.json
- Provides API for feature checks
- Determines Demo vs Full version
- Validates content availability

**API**:
```gdscript
# Check build type
BuildConfig.is_demo_build() -> bool
BuildConfig.is_full_build() -> bool

# Check content availability
BuildConfig.is_chapter_available(chapter: int) -> bool
BuildConfig.is_side_story_available(case_num: int) -> bool

# Get configuration
BuildConfig.get_max_save_slots() -> int
BuildConfig.get_max_achievements() -> int
BuildConfig.get_available_chapters() -> Array
BuildConfig.get_available_side_stories() -> Array
```

### 4. Validation Script
**File**: `tools/validate_export.py`

Validates export builds:
- Checks build_config.json
- Verifies content filtering
- Validates chapter/side story files
- Checks save slot and achievement limits
- Verifies README and executable

**Usage**:
```bash
python tools/validate_export.py
```

## Build Configuration Format

### build_config.json
```json
{
  "build_flavor": "demo",
  "build_date": "2026-02-05T12:34:56",
  "chapters_available": [1, 2, 3],
  "side_stories_available": [1],
  "max_achievements": 20,
  "max_save_slots": 10
}
```

## Export Process

### Automated Export

1. **Run Export Script**:
   ```bash
   python tools/export_demo_full.py --both
   ```

2. **Script Actions**:
   - Creates `export/demo/` and `export/full/` directories
   - Filters content based on configuration
   - Copies allowed chapters and side stories
   - Generates build_config.json
   - Creates README.txt
   - Calls Godot export (if available)

3. **Output Structure**:
   ```
   export/
   ├── demo/
   │   ├── demo.exe
   │   ├── demo.pck (embedded)
   │   ├── build_config.json
   │   ├── README.txt
   │   └── content/
   │       ├── main/
   │       │   ├── chapter_1.json
   │       │   ├── chapter_2.json
   │       │   ├── chapter_3.json
   │       │   └── manifest.json
   │       ├── side/
   │       │   └── case_1.json
   │       └── vocabulary/
   │           └── vocab_database.json
   └── full/
       ├── full.exe
       ├── full.pck (embedded)
       ├── build_config.json
       ├── README.txt
       └── content/
           ├── main/
           │   ├── chapter_1.json
           │   ├── ...
           │   ├── chapter_7.json
           │   └── manifest.json
           ├── side/
           │   ├── case_1.json
           │   ├── case_2.json
           │   └── case_3.json
           └── vocabulary/
               └── vocab_database.json
   ```

### Manual Export

If automated export fails:

1. **Open Godot Editor**
2. **Project → Export**
3. **Select Preset**:
   - "Windows Desktop (Demo)" for demo
   - "Windows Desktop (Full)" for full
4. **Click "Export Project"**
5. **Choose destination** in `export/demo/` or `export/full/`
6. **Run export script** with `--demo` or `--full` to generate config files

## Runtime Integration

### Content Gating

Use BuildConfig to gate content:

```gdscript
# In chapter selection
func _load_chapter(chapter: int) -> void:
    if not BuildConfig.is_chapter_available(chapter):
        _show_demo_upgrade_prompt()
        return

    # Load chapter normally
    ...

# In side story menu
func _load_case(case_num: int) -> void:
    if not BuildConfig.is_side_story_available(case_num):
        _show_demo_upgrade_prompt()
        return

    # Load case normally
    ...
```

### Save Slot Limiting

```gdscript
# In SaveManager
func get_max_slots() -> int:
    return BuildConfig.get_max_save_slots()

func can_create_save(slot: int) -> bool:
    return slot < get_max_slots()
```

### Achievement Limiting

```gdscript
# In achievement system
func get_max_achievements() -> int:
    return BuildConfig.get_max_achievements()

func is_achievement_available(achievement_id: String) -> bool:
    var achievement_num = _get_achievement_number(achievement_id)
    return achievement_num <= BuildConfig.get_max_achievements()
```

## Demo Upgrade Flow

### Upgrade Prompt

When demo players try to access locked content:

```gdscript
func _show_demo_upgrade_prompt() -> void:
    var dialog = AcceptDialog.new()
    dialog.title = "Demo Version"
    dialog.dialog_text = """
    This content is available in the full version.

    The full version includes:
    - All 7 chapters
    - 3 side stories
    - 60 achievements
    - 100 save slots

    Visit our store page to upgrade!
    """
    dialog.ok_button_text = "Visit Store"
    dialog.confirmed.connect(_open_store_page)

    add_child(dialog)
    dialog.popup_centered()

func _open_store_page() -> void:
    OS.shell_open("https://store.steampowered.com/app/YOUR_APP_ID")
```

### Save Transfer

Demo saves are compatible with full version:
- Same save format
- Same schema version
- Automatic migration
- Progress preserved

## Validation

### Pre-Export Validation

Before exporting:
```bash
# Validate content
python tools/validate_content.py

# Validate locales
python tools/validate_locales.py

# Validate engine
bash tools/validate_engine.sh
```

### Post-Export Validation

After exporting:
```bash
# Validate exports
python tools/validate_export.py
```

Expected output:
```
============================================================
EXPORT VALIDATION
============================================================

[Validate] Checking demo build...
[OK] All checks passed

[Validate] Checking full build...
[OK] All checks passed

============================================================
VALIDATION SUMMARY
============================================================
Errors: 0
Warnings: 0

[OK] All validations passed!
```

## Distribution

### Steam Distribution

1. **Upload Builds**:
   - Demo: Upload to "demo" depot
   - Full: Upload to "game" depot

2. **Set Branches**:
   - Demo: Public branch
   - Full: Default branch

3. **Configure Store**:
   - Demo: Free to play
   - Full: Paid product

### File Sizes

Estimated sizes:
- **Demo**: ~500MB (3 chapters, 1 side story)
- **Full**: ~1.5GB (7 chapters, 3 side stories)

### Compression

PCK files are embedded and compressed:
- Godot's built-in compression
- ~30-40% size reduction
- No external dependencies

## Troubleshooting

### Export Script Fails

**Issue**: Godot executable not found

**Solution**:
1. Install Godot 4.6.stable.official.89cea1439
2. Add to PATH or update `godot_paths` in script
3. Or export manually from Godot Editor

### Content Not Filtered

**Issue**: Wrong chapters in demo build

**Solution**:
1. Check `export_presets.cfg` exclude filters
2. Verify `export_demo_full.py` filter logic
3. Run validation script to identify issues

### Build Config Not Loaded

**Issue**: Game doesn't recognize demo/full version

**Solution**:
1. Ensure `build_config.json` is in export directory
2. Check BuildConfig.gd is in autoloads
3. Verify JSON format is valid

### Save Slots Not Limited

**Issue**: Demo allows more than 10 saves

**Solution**:
1. Update SaveManager to use BuildConfig API
2. Check `get_max_save_slots()` implementation
3. Verify build_config.json has correct value

## Future Enhancements

### Planned Features

1. **Platform Support**:
   - Linux export preset
   - macOS export preset
   - Steam Deck optimization

2. **Localization Filtering**:
   - Demo: Limited languages
   - Full: All 29 languages

3. **Asset Quality**:
   - Demo: Compressed assets
   - Full: High-quality assets

4. **DLC Support**:
   - Additional chapters as DLC
   - Expansion packs
   - Bonus content

5. **Automated Testing**:
   - Post-export smoke tests
   - Content verification
   - Performance benchmarks

6. **CI/CD Integration**:
   - GitHub Actions workflow
   - Automated builds on commit
   - Steam upload automation

## Best Practices

### Before Export

1. **Test thoroughly** in editor
2. **Run all validation scripts**
3. **Update version numbers**
4. **Review changelog**
5. **Backup project**

### During Export

1. **Use release mode** (not debug)
2. **Embed PCK** for single-file distribution
3. **Enable compression**
4. **Sign executables** (if available)
5. **Test on clean system**

### After Export

1. **Run validation script**
2. **Test both builds**
3. **Verify content gating**
4. **Check save compatibility**
5. **Test upgrade flow**

## Security Considerations

### Content Protection

- PCK files are embedded (harder to extract)
- No encryption (Godot limitation)
- Content gating enforced at runtime
- Server-side validation for achievements (future)

### Save File Integrity

- Schema versioning prevents tampering
- Demo saves work in full version
- No server-side save validation (offline game)

## Performance

### Build Times

- Demo export: ~2-3 minutes
- Full export: ~5-7 minutes
- Both exports: ~8-10 minutes

### Optimization

- Parallel content copying
- Incremental exports (Godot feature)
- Cached templates

## Conclusion

The Export System provides a robust, automated solution for creating Demo and Full versions of the game with proper content filtering, runtime validation, and upgrade paths. The system is designed to be maintainable, extensible, and compatible with Steam distribution requirements.
