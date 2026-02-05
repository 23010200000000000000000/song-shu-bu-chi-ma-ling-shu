# API Reference

## Overview

This document provides a complete API reference for "万历十四年·朱笔未落" (The Wanli Year 14: The Vermillion Brush Unfallen). All autoloaded singletons and their public APIs are documented here.

---

## GameState

**File**: `src/core/GameState.gd`
**Type**: Autoload Singleton
**Purpose**: Global game state management across 13 domains

### Constants

```gdscript
const BUILD_VERSION := "0.1.0"
const BUILD_FLAVOR := "demo"  # or "full"
const SCHEMA_VERSION := 1
```

### Signals

```gdscript
signal state_changed(domain: String, key: String, value: Variant)
signal save_requested()
signal load_requested(slot: int)
```

### State Structure

```gdscript
var state := {
    "meta": {...},      # Save metadata
    "nav": {...},       # Navigation state
    "main": {...},      # Main story state
    "stance": {...},    # Investigation stance
    "archive": {...},   # Archive entries
    "evidence": {...},  # Evidence tracking
    "ending": {...},    # Ending calculation
    "ui": {...},        # UI state
    "settings": {...},  # Player settings
    "learning": {...},  # Vocabulary learning
    "side": {...},      # Side stories
    "flags": {...},     # Global flags
    "version": {...}    # Version tracking
}
```

### Methods

#### get_value
```gdscript
func get_value(domain: String, key: String, default: Variant = null) -> Variant
```
Get a value from the state.

**Parameters**:
- `domain`: State domain name
- `key`: Key within domain
- `default`: Default value if key not found

**Returns**: Value from state or default

**Example**:
```gdscript
var chapter = GameState.get_value("main", "chapter", 1)
```

#### set_value
```gdscript
func set_value(domain: String, key: String, value: Variant) -> void
```
Set a value in the state. Emits `state_changed` signal.

**Parameters**:
- `domain`: State domain name
- `key`: Key within domain
- `value`: Value to set

**Example**:
```gdscript
GameState.set_value("main", "chapter", 2)
```

#### get_domain
```gdscript
func get_domain(domain: String) -> Dictionary
```
Get an entire domain dictionary.

**Parameters**:
- `domain`: Domain name

**Returns**: Domain dictionary or empty dict

**Example**:
```gdscript
var main_state = GameState.get_domain("main")
```

#### reset_state
```gdscript
func reset_state() -> void
```
Reset all state to initial values. Used for new game.

---

## LanguageManager

**File**: `src/core/LanguageManager.gd`
**Type**: Autoload Singleton
**Purpose**: 29-language localization system

### Signals

```gdscript
signal language_changed(lang_code: String)
```

### Methods

#### set_language
```gdscript
func set_language(lang_code: String) -> bool
```
Set the current language.

**Parameters**:
- `lang_code`: Language code (e.g., "english", "schinese")

**Returns**: `true` if successful

**Example**:
```gdscript
LanguageManager.set_language("schinese")
```

#### get_text
```gdscript
func get_text(key: String, args: Array = []) -> String
```
Get translated text for a key.

**Parameters**:
- `key`: Translation key (e.g., "ui.menu.title")
- `args`: Optional format arguments

**Returns**: Translated text or key if not found

**Example**:
```gdscript
var text = LanguageManager.get_text("ui.menu.title")
var formatted = LanguageManager.get_text("side.status_turn", [5])
```

#### tr
```gdscript
func tr(key: String) -> String
```
Alias for `get_text()` without arguments.

#### get_current_language
```gdscript
func get_current_language() -> String
```
Get current language code.

**Returns**: Current language code

#### get_display_name
```gdscript
func get_display_name(lang_code: String) -> String
```
Get display name for a language.

**Parameters**:
- `lang_code`: Language code

**Returns**: Display name (e.g., "简体中文")

#### get_modern_languages
```gdscript
func get_modern_languages() -> Array
```
Get list of modern language codes.

**Returns**: Array of language codes

#### is_rtl_language
```gdscript
func is_rtl_language(lang_code: String) -> bool
```
Check if language is right-to-left.

**Parameters**:
- `lang_code`: Language code

**Returns**: `true` if RTL

---

## SaveManager

**File**: `src/core/SaveManager.gd`
**Type**: Autoload Singleton
**Purpose**: Save/load system with Steam Cloud support

### Constants

```gdscript
const MAX_MANUAL_SAVES := 100
const MAX_AUTO_SAVES := 10
const SAVE_DIR := "user://saves/"
```

### Methods

#### save_game
```gdscript
func save_game(slot: int, is_auto: bool = false) -> bool
```
Save game to a slot.

**Parameters**:
- `slot`: Save slot number (0-99 for manual, 0-9 for auto)
- `is_auto`: Whether this is an auto-save

**Returns**: `true` if successful

**Example**:
```gdscript
SaveManager.save_game(0)  # Quick save
SaveManager.save_game(5, false)  # Manual save to slot 5
```

#### load_game
```gdscript
func load_game(slot: int) -> bool
```
Load game from a slot.

**Parameters**:
- `slot`: Save slot number

**Returns**: `true` if successful

**Example**:
```gdscript
SaveManager.load_game(0)  # Quick load
```

#### auto_save
```gdscript
func auto_save() -> bool
```
Create an auto-save in the next available auto-save slot.

**Returns**: `true` if successful

#### get_save_list
```gdscript
func get_save_list() -> Array
```
Get list of all saves sorted by date (newest first).

**Returns**: Array of save info dictionaries

**Example**:
```gdscript
var saves = SaveManager.get_save_list()
for save in saves:
    print("%s - Chapter %d" % [save.timestamp, save.chapter])
```

#### delete_save
```gdscript
func delete_save(slot: int) -> bool
```
Delete a save file.

**Parameters**:
- `slot`: Save slot number

**Returns**: `true` if successful

---

## SteamManager

**File**: `src/core/SteamManager.gd`
**Type**: Autoload Singleton
**Purpose**: Steamworks integration (stub with graceful degradation)

### Methods

#### is_steam_available
```gdscript
func is_steam_available() -> bool
```
Check if Steam is available.

**Returns**: `true` if Steam is initialized

#### get_steam_id
```gdscript
func get_steam_id() -> int
```
Get Steam user ID.

**Returns**: Steam ID or 0 if unavailable

#### get_username
```gdscript
func get_username() -> String
```
Get Steam username.

**Returns**: Username or "Player" if unavailable

#### unlock_achievement
```gdscript
func unlock_achievement(achievement_id: String) -> bool
```
Unlock a Steam achievement.

**Parameters**:
- `achievement_id`: Achievement identifier

**Returns**: `true` if successful

**Example**:
```gdscript
SteamManager.unlock_achievement("CHAPTER_1_COMPLETE")
```

---

## VocabularyManager

**File**: `src/core/VocabularyManager.gd`
**Type**: Autoload Singleton
**Purpose**: Vocabulary learning and quiz system

### Constants

```gdscript
const LEVEL_SYSTEMS := {
    "CEFR": ["A1", "A2", "B1", "B2", "C1", "C2"],
    "HSK": ["HSK1", "HSK2", "HSK3", "HSK4", "HSK5", "HSK6"],
    "JLPT": ["N5", "N4", "N3", "N2", "N1"],
    "TOPIK": ["TOPIK1", "TOPIK2", "TOPIK3", "TOPIK4", "TOPIK5", "TOPIK6"]
}
```

### Signals

```gdscript
signal vocabulary_injected(word_data: Dictionary)
signal quiz_completed(correct: bool, word_data: Dictionary)
```

### Methods

#### get_vocabulary_for_level
```gdscript
func get_vocabulary_for_level(target_lang: String, level: int) -> Array
```
Get vocabulary at or below a level.

**Parameters**:
- `target_lang`: Target language code
- `level`: Internal level (1-12)

**Returns**: Array of word dictionaries

#### inject_vocabulary
```gdscript
func inject_vocabulary(sentence: String, target_lang: String) -> Dictionary
```
Inject vocabulary into a sentence (immersion mode).

**Parameters**:
- `sentence`: Original sentence
- `target_lang`: Target language code

**Returns**: Dictionary with injected text and metadata

**Example**:
```gdscript
var result = VocabularyManager.inject_vocabulary("The emperor ruled.", "schinese")
if result.injected:
    label.text = result.text  # Contains BBCode
```

#### generate_quiz
```gdscript
func generate_quiz(target_lang: String) -> Dictionary
```
Generate a quiz question.

**Parameters**:
- `target_lang`: Target language code

**Returns**: Quiz dictionary with word, options, correct_index

**Example**:
```gdscript
var quiz = VocabularyManager.generate_quiz("schinese")
word_label.text = quiz.word
for i in quiz.options.size():
    option_buttons[i].text = quiz.options[i]
```

#### submit_quiz_answer
```gdscript
func submit_quiz_answer(selected_index: int) -> bool
```
Submit quiz answer and update statistics.

**Parameters**:
- `selected_index`: Index of selected option

**Returns**: `true` if correct

#### get_display_level
```gdscript
func get_display_level() -> String
```
Get current level in display format.

**Returns**: Level string (e.g., "HSK3", "B1")

#### reset_statistics
```gdscript
func reset_statistics() -> void
```
Reset all learning statistics.

---

## BuildConfig

**File**: `src/core/BuildConfig.gd`
**Type**: Autoload Singleton
**Purpose**: Build configuration management (Demo vs Full)

### Signals

```gdscript
signal build_config_loaded()
```

### Properties

```gdscript
var config: Dictionary
var is_demo: bool
var is_full: bool
```

### Methods

#### is_chapter_available
```gdscript
func is_chapter_available(chapter: int) -> bool
```
Check if a chapter is available in this build.

**Parameters**:
- `chapter`: Chapter number

**Returns**: `true` if available

**Example**:
```gdscript
if BuildConfig.is_chapter_available(4):
    load_chapter(4)
else:
    show_upgrade_prompt()
```

#### is_side_story_available
```gdscript
func is_side_story_available(case_num: int) -> bool
```
Check if a side story is available.

**Parameters**:
- `case_num`: Case number

**Returns**: `true` if available

#### get_max_save_slots
```gdscript
func get_max_save_slots() -> int
```
Get maximum save slots for this build.

**Returns**: 10 for demo, 100 for full

#### get_max_achievements
```gdscript
func get_max_achievements() -> int
```
Get maximum achievements for this build.

**Returns**: 20 for demo, 60 for full

#### get_build_flavor
```gdscript
func get_build_flavor() -> String
```
Get build flavor string.

**Returns**: "demo" or "full"

#### is_demo_build
```gdscript
func is_demo_build() -> bool
```
Check if this is a demo build.

**Returns**: `true` if demo

#### is_full_build
```gdscript
func is_full_build() -> bool
```
Check if this is a full build.

**Returns**: `true` if full

---

## Common Patterns

### Checking and Setting State

```gdscript
# Get current chapter
var chapter = GameState.get_value("main", "chapter", 1)

# Advance to next chapter
GameState.set_value("main", "chapter", chapter + 1)

# Check if player visited all POVs
var flags = GameState.get_value("main", "flags", {})
if flags.get("visited_all_pov_in_chapter", false):
    unlock_investigation()
```

### Localization

```gdscript
# Simple translation
title_label.text = LanguageManager.get_text("ui.menu.title")

# With formatting
status_label.text = LanguageManager.get_text("side.status_turn", [turn_count])

# Change language
LanguageManager.set_language("schinese")
```

### Saving and Loading

```gdscript
# Quick save
SaveManager.save_game(0)

# Manual save with name
SaveManager.save_game(5)

# Auto-save
SaveManager.auto_save()

# Load most recent save
var saves = SaveManager.get_save_list()
if not saves.is_empty():
    SaveManager.load_game(saves[0].slot)
```

### Build Configuration

```gdscript
# Check if content is available
if not BuildConfig.is_chapter_available(chapter):
    show_demo_upgrade_prompt()
    return

# Limit save slots
var max_slots = BuildConfig.get_max_save_slots()
if slot >= max_slots:
    show_error("Save slot not available in demo")
    return
```

### Vocabulary Learning

```gdscript
# Generate and display quiz
var quiz = VocabularyManager.generate_quiz("schinese")
word_label.text = quiz.word
context_label.text = quiz.context

# Submit answer
var correct = VocabularyManager.submit_quiz_answer(selected_index)
if correct:
    show_success_feedback()
else:
    show_correct_answer(quiz.options[quiz.correct_index])
```

---

## Error Handling

All API methods handle errors gracefully:

```gdscript
# Returns default value if key not found
var value = GameState.get_value("invalid_domain", "key", "default")

# Returns false if operation fails
var success = SaveManager.save_game(999)
if not success:
    show_error("Save failed")

# Returns empty array if no vocabulary
var words = VocabularyManager.get_vocabulary_for_level("invalid_lang", 1)
if words.is_empty():
    show_error("No vocabulary available")
```

---

## Best Practices

### State Management

1. **Always use get_value with defaults**:
   ```gdscript
   var chapter = GameState.get_value("main", "chapter", 1)  # Good
   var chapter = GameState.state.main.chapter  # Bad - no error handling
   ```

2. **Use set_value for all state changes**:
   ```gdscript
   GameState.set_value("main", "chapter", 2)  # Good - emits signal
   GameState.state.main.chapter = 2  # Bad - no signal
   ```

3. **Listen to state_changed for reactive updates**:
   ```gdscript
   GameState.state_changed.connect(_on_state_changed)
   ```

### Localization

1. **Use translation keys, not hardcoded text**:
   ```gdscript
   label.text = LanguageManager.get_text("ui.menu.title")  # Good
   label.text = "Main Menu"  # Bad - not localized
   ```

2. **Update UI on language change**:
   ```gdscript
   LanguageManager.language_changed.connect(_update_ui_text)
   ```

### Saving

1. **Auto-save at key moments**:
   ```gdscript
   # After chapter completion
   SaveManager.auto_save()
   ```

2. **Validate before loading**:
   ```gdscript
   var saves = SaveManager.get_save_list()
   if not saves.is_empty():
       SaveManager.load_game(saves[0].slot)
   ```

### Build Configuration

1. **Always check availability before loading content**:
   ```gdscript
   if BuildConfig.is_chapter_available(chapter):
       load_chapter(chapter)
   ```

2. **Use build config for feature gating**:
   ```gdscript
   var max_slots = BuildConfig.get_max_save_slots()
   ```

---

## Thread Safety

All autoloaded singletons are **not thread-safe**. Always call from the main thread.

---

## Performance Considerations

- **GameState**: O(1) access, minimal overhead
- **LanguageManager**: Translations cached, O(1) lookup
- **SaveManager**: File I/O is blocking, use sparingly
- **VocabularyManager**: Database loaded once at startup

---

## Debugging

Enable debug output:

```gdscript
# In GameState
print("[GameState] %s.%s = %s" % [domain, key, value])

# In LanguageManager
print("[LanguageManager] Language changed: %s" % lang_code)

# In SaveManager
print("[SaveManager] Saved to slot %d" % slot)
```

---

## Version Compatibility

- **Schema Version**: 1
- **Save Format**: Forward-compatible
- **API Stability**: Stable for v0.1.0

---

## See Also

- [GameState Domain Reference](GAMESTATE_DOMAINS.md)
- [Translation Key Reference](TRANSLATION_KEYS.md)
- [Content Format Reference](CONTENT_FORMAT.md)
