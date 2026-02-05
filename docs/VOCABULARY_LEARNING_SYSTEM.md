# Vocabulary Learning System Documentation

## Overview

The Vocabulary Learning System in "万历十四年·朱笔未落" provides immersive language learning through vocabulary injection and quiz-based assessment. The system supports multiple proficiency level frameworks (CEFR, HSK, JLPT, TOPIK) and adapts to player performance.

## Core Components

### 1. VocabularyManager (Autoload)
**File**: `src/core/VocabularyManager.gd`

Central manager for all vocabulary-related functionality:
- Loads vocabulary database from JSON
- Manages vocabulary injection for immersion mode
- Generates quiz questions with distractors
- Tracks learning statistics and progress
- Adapts difficulty based on performance
- Manages word mastery tracking

### 2. VocabularyQuiz Scene
**Files**:
- `scenes/learning/VocabularyQuiz.tscn` - Quiz UI
- `src/learning/VocabularyQuiz.gd` - Quiz logic

Interactive quiz interface:
- Multiple choice questions (4 options)
- Context sentences for vocabulary
- Immediate feedback (correct/incorrect)
- Statistics display (level, score, accuracy)
- Next question button
- Back to settings navigation

### 3. Vocabulary Database
**File**: `content/vocabulary/vocab_database.json`

Structured vocabulary data:
```json
{
  "schinese": {
    "word_001": {
      "word": "皇帝",
      "translation": "emperor",
      "level": 1,
      "context": "The emperor ruled the Ming Dynasty...",
      "part_of_speech": "noun"
    }
  }
}
```

## Level Systems

### Supported Frameworks

1. **CEFR** (Common European Framework)
   - A1, A2, B1, B2, C1, C2
   - Universal standard for European languages

2. **HSK** (Hanyu Shuiping Kaoshi)
   - HSK1, HSK2, HSK3, HSK4, HSK5, HSK6
   - Chinese proficiency standard

3. **JLPT** (Japanese Language Proficiency Test)
   - N5, N4, N3, N2, N1
   - Japanese proficiency standard

4. **TOPIK** (Test of Proficiency in Korean)
   - TOPIK1-6
   - Korean proficiency standard

### Internal Level Mapping

The system uses an internal 1-12 scale that maps to external frameworks:

| Internal | CEFR | HSK  | JLPT | TOPIK  |
|----------|------|------|------|--------|
| 1-2      | A1   | HSK1 | N5   | TOPIK1 |
| 3-4      | A2   | HSK2 | N4   | TOPIK2 |
| 5-6      | B1   | HSK3 | N3   | TOPIK3 |
| 7-8      | B2   | HSK4 | N2   | TOPIK4 |
| 9-10     | C1   | HSK5 | N1   | TOPIK5 |
| 11-12    | C2   | HSK6 | N1   | TOPIK6 |

## GameState Integration

### Learning Domain
```gdscript
"learning": {
  "immersion_enabled": false,      # Enable vocabulary injection
  "inject_rate": 0.10,             # 10% of sentences get vocab
  "level_setting": 5,              # Manual level setting (1-12)
  "level_system": "CEFR",          # Display system
  "quiz_enabled": true,            # Enable quiz system
  "quiz_correct_rate": 0.75,       # Running average (75%)
  "quiz_total": 20,                # Total questions answered
  "quiz_correct": 15,              # Correct answers
  "level_estimate": 5,             # Dynamic level (1-12)
  "mastered_words": ["word_001"]   # Mastered vocabulary IDs
}
```

## Features

### 1. Immersion Mode Vocabulary Injection

**How It Works**:
1. Player enables immersion mode in settings
2. System injects vocabulary into story sentences
3. Injection rate controlled by `inject_rate` (default 10%)
4. Only injects words at or below player's current level
5. Avoids mastered words
6. Words displayed with BBCode highlighting

**Example**:
```
Original: "The emperor made a decision."
Injected: "The [color=yellow][url=word_001]皇帝[/url][/color] made a decision."
```

**API**:
```gdscript
var result = VocabularyManager.inject_vocabulary(sentence, target_lang)
# Returns: {
#   "text": "injected sentence",
#   "injected": true/false,
#   "word_data": {...},
#   "original_sentence": "..."
# }
```

### 2. Quiz System

**Question Generation**:
- Selects random word at player's level
- Generates 3 distractors from same level
- Shuffles options
- Provides context sentence

**Answer Submission**:
- Tracks correct/incorrect answers
- Updates statistics (total, correct, rate)
- Adjusts level estimate based on performance
- Marks words as mastered after repeated success

**Performance-Based Adaptation**:
- Correct rate > 80% → Increase level
- Correct rate < 50% → Decrease level
- Gradual adjustment (±1 level at a time)

**API**:
```gdscript
# Generate quiz
var quiz = VocabularyManager.generate_quiz(target_lang)

# Submit answer
var correct = VocabularyManager.submit_quiz_answer(selected_index)
```

### 3. Word Mastery Tracking

**Mastery Criteria**:
- Currently: Mark as mastered after 3 correct answers
- Future: Per-word statistics with spaced repetition

**Effects**:
- Mastered words excluded from injection
- Mastered words excluded from quizzes
- Mastered count displayed in stats

### 4. Statistics Tracking

**Tracked Metrics**:
- Total questions answered
- Correct answers
- Correct rate (percentage)
- Current level estimate
- Mastered words count

**Display**:
```
Level: HSK3 | Score: 15/20 (75%)
```

## UI Components

### VocabularyQuiz Scene

**Layout**:
- Question label: "What is the meaning of this word?"
- Word panel: Large display of target word
- Context label: Example sentence
- 4 option buttons: Multiple choice answers
- Result label: Feedback (correct/incorrect)
- Stats label: Level and score display
- Next button: Generate new question
- Back button: Return to settings

**User Flow**:
1. Quiz loads with first question
2. Player selects an answer
3. Immediate feedback shown
4. Statistics updated
5. Player clicks "Next" for new question
6. Repeat or click "Back" to exit

### Settings Integration

**Quiz Button**:
- Located in Settings menu
- Requires bilingual or immersion mode
- Requires target language selection
- Launches VocabularyQuiz scene

## Translation Keys

All UI elements are fully localized:

### Learning Keys
- `learning.quiz_question` - "What is the meaning of this word?"
- `learning.quiz_next` - "Next Question"
- `learning.quiz_correct` - "Correct!"
- `learning.quiz_incorrect` - "Incorrect. The correct answer is: {0}"
- `learning.current_level` - "Current Level"
- `learning.quiz_stats` - "Quiz Score"
- `learning.error_no_target_language` - Error message
- `learning.error_no_vocabulary` - Error message
- `learning.immersion_mode` - "Immersion Mode"
- `learning.inject_rate_label` - "Vocabulary Density"
- `learning.level_system_label` - "Level System"
- `learning.reset_stats` - "Reset Statistics"
- `learning.start_quiz` - "Start Quiz"

## Vocabulary Database Format

### Structure
```json
{
  "language_code": {
    "word_id": {
      "word": "target language word",
      "translation": "primary language translation",
      "level": 1-12,
      "context": "example sentence",
      "part_of_speech": "noun|verb|adjective|..."
    }
  }
}
```

### Example Entry
```json
{
  "schinese": {
    "word_001": {
      "word": "皇帝",
      "translation": "emperor",
      "level": 1,
      "context": "The emperor ruled the Ming Dynasty with absolute authority.",
      "part_of_speech": "noun"
    }
  }
}
```

### Current Database
- **Language**: Simplified Chinese (schinese)
- **Words**: 8 placeholder entries
- **Levels**: 1-4 (beginner to intermediate)
- **Theme**: Ming Dynasty historical vocabulary

## API Reference

### VocabularyManager Methods

```gdscript
# Get vocabulary for level
get_vocabulary_for_level(target_lang: String, level: int) -> Array

# Inject vocabulary into sentence
inject_vocabulary(sentence: String, target_lang: String) -> Dictionary

# Generate quiz question
generate_quiz(target_lang: String) -> Dictionary

# Submit quiz answer
submit_quiz_answer(selected_index: int) -> bool

# Get display level string
get_display_level() -> String

# Get available level systems for language
get_level_systems_for_language(lang_code: String) -> Array

# Reset all statistics
reset_statistics() -> void
```

### Signals

```gdscript
# Emitted when vocabulary is injected
signal vocabulary_injected(word_data: Dictionary)

# Emitted when quiz is completed
signal quiz_completed(correct: bool, word_data: Dictionary)
```

## Integration with Story System

### Immersion Mode in StoryPlayer

To integrate vocabulary injection into the story player:

```gdscript
# In StoryPlayer.gd
func _display_dialogue(text: String) -> void:
    var target_lang = GameState.get_value("settings", "lang_target", "")
    if not target_lang.is_empty():
        var result = VocabularyManager.inject_vocabulary(text, target_lang)
        if result.injected:
            text = result.text
            # Store word_data for click handling

    dialogue_label.text = text
```

### Click Handling for Injected Words

```gdscript
# Handle BBCode URL clicks
func _on_dialogue_meta_clicked(meta: String) -> void:
    # meta contains word_id
    var word_data = _get_word_data(meta)
    _show_word_tooltip(word_data)
```

## Future Enhancements

### Planned Features

1. **Spaced Repetition System (SRS)**
   - Implement Leitner or SM-2 algorithm
   - Track per-word review intervals
   - Optimize review scheduling

2. **Vocabulary Lists**
   - View all learned vocabulary
   - Filter by level, mastery, part of speech
   - Export to flashcard apps

3. **Progress Visualization**
   - Level progression graph
   - Mastery heatmap
   - Learning streak tracking

4. **Custom Vocabulary Sets**
   - User-created word lists
   - Import from external sources
   - Share vocabulary sets

5. **Audio Pronunciation**
   - Native speaker recordings
   - Pronunciation practice
   - Speech recognition

6. **Writing Practice**
   - Character writing for CJK languages
   - Stroke order animation
   - Handwriting recognition

7. **Contextual Learning**
   - Story-specific vocabulary
   - Character-specific vocabulary
   - Historical context notes

8. **Achievement Integration**
   - Vocabulary milestones
   - Perfect quiz streaks
   - Level advancement rewards

9. **Multiplayer Features**
   - Vocabulary challenges
   - Leaderboards
   - Collaborative learning

10. **Advanced Analytics**
    - Learning curve analysis
    - Weak area identification
    - Personalized recommendations

## Design Philosophy

The vocabulary learning system is designed to:
- Integrate seamlessly with story gameplay
- Provide non-intrusive learning opportunities
- Adapt to individual learning pace
- Support multiple language frameworks
- Encourage consistent practice
- Reward progress and mastery
- Maintain historical authenticity
- Balance education with entertainment

## Performance Considerations

- Vocabulary database loaded once at startup
- Quiz generation is lightweight (no heavy computation)
- Statistics updates are incremental
- Injection rate limits performance impact
- BBCode rendering is native to Godot

## Accessibility

- Clear visual feedback for correct/incorrect answers
- Context sentences aid comprehension
- Adjustable injection rate
- Optional system (can be disabled)
- Multiple level frameworks for different backgrounds
