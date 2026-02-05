# Content Creation Guide

## Overview

This guide explains how to create story content, side stories, and vocabulary for "万历十四年·朱笔未落". All content is stored in JSON format and loaded dynamically by the game engine.

---

## Story Content

### File Structure

```
content/
└── main/
    ├── manifest.json       # Chapter index
    ├── chapter_1.json      # Chapter 1 content
    ├── chapter_2.json      # Chapter 2 content
    └── ...
```

### Manifest Format

**File**: `content/main/manifest.json`

```json
{
  "version": "1.0",
  "total_chapters": 7,
  "total_nodes": 91,
  "chapters": [
    {
      "chapter": 1,
      "title": {
        "english": "Chapter 1: The Beginning",
        "schinese": "第一章：开端"
      },
      "start_node": "CH1_START",
      "node_count": 13
    }
  ]
}
```

### Chapter Format

**File**: `content/main/chapter_X.json`

```json
{
  "chapter": 1,
  "title": {
    "english": "Chapter 1: The Beginning",
    "schinese": "第一章：开端"
  },
  "nodes": {
    "CH1_START": {
      "id": "CH1_START",
      "type": "dialogue",
      "speaker": {
        "english": "Narrator",
        "schinese": "旁白"
      },
      "text": {
        "english": "The year is 1586...",
        "schinese": "万历十四年..."
      },
      "pov": "emperor",
      "next": "CH1_002",
      "choices": [],
      "metadata": {
        "background": "palace_exterior",
        "music": "main_theme"
      }
    },
    "CH1_002": {
      "id": "CH1_002",
      "type": "choice",
      "speaker": {
        "english": "Emperor",
        "schinese": "皇帝"
      },
      "text": {
        "english": "What should I do?",
        "schinese": "朕该如何是好？"
      },
      "pov": "emperor",
      "next": "",
      "choices": [
        {
          "text": {
            "english": "Summon the ministers",
            "schinese": "召见大臣"
          },
          "next": "CH1_003",
          "conditions": [],
          "effects": {
            "stance": {
              "axis_truth": 5
            }
          }
        },
        {
          "text": {
            "english": "Consult the consort",
            "schinese": "询问妃子"
          },
          "next": "CH1_004",
          "conditions": [],
          "effects": {
            "stance": {
              "axis_loyalty": {
                "consort": 10
              }
            }
          }
        }
      ],
      "metadata": {}
    }
  }
}
```

### Node Types

#### 1. Dialogue Node
Simple text display with automatic progression.

```json
{
  "type": "dialogue",
  "speaker": {"english": "...", "schinese": "..."},
  "text": {"english": "...", "schinese": "..."},
  "pov": "emperor",
  "next": "NEXT_NODE_ID"
}
```

#### 2. Choice Node
Player makes a decision.

```json
{
  "type": "choice",
  "text": {"english": "...", "schinese": "..."},
  "choices": [
    {
      "text": {"english": "...", "schinese": "..."},
      "next": "NODE_ID",
      "conditions": ["flag_name"],
      "effects": {
        "stance": {"axis_truth": 5},
        "flags": {"flag_name": true}
      }
    }
  ]
}
```

#### 3. Investigation Node
Triggers investigation mode.

```json
{
  "type": "investigation",
  "text": {"english": "...", "schinese": "..."},
  "investigation_type": "compare",
  "documents": ["doc_a", "doc_b"],
  "next": "NODE_ID"
}
```

### POV (Point of View)

Three perspectives available:
- `"emperor"` - Emperor's perspective
- `"consort"` - Consort's perspective
- `"minister"` - Minister's perspective

### Conditions

Conditions gate content based on state:

```json
"conditions": [
  "visited_all_pov",
  "chapter_1_complete",
  "stance_truth_positive"
]
```

### Effects

Effects modify game state:

```json
"effects": {
  "stance": {
    "axis_truth": 10,
    "axis_loyalty": {
      "emperor": 5
    }
  },
  "flags": {
    "met_minister": true
  },
  "evidence": {
    "add": ["evidence_001"]
  }
}
```

---

## Side Stories (Turtle Soup)

### File Structure

```
content/
└── side/
    ├── case_1.json
    ├── case_2.json
    └── case_3.json
```

### Case Format

**File**: `content/side/case_X.json`

```json
{
  "case_id": "CASE_001",
  "title": {
    "english": "The Mystery of the Missing Memorial",
    "schinese": "失踪的奏折之谜"
  },
  "difficulty": "medium",
  "scenario": {
    "english": "A memorial disappeared from the emperor's desk. What happened?",
    "schinese": "一份奏折从皇帝的案头消失了。发生了什么？"
  },
  "questions": [
    {
      "id": "Q001",
      "text": {
        "english": "Was the memorial stolen?",
        "schinese": "奏折是被偷走的吗？"
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
      "id": "SOLUTION",
      "text": {
        "english": "Was it hidden by a eunuch?",
        "schinese": "是被太监藏起来的吗？"
      },
      "answer": "yes",
      "unlocks": []
    }
  ],
  "solution": {
    "english": "The memorial was hidden by a eunuch who feared its contents would anger the emperor.",
    "schinese": "奏折被一名太监藏了起来，因为他担心其内容会激怒皇帝。"
  },
  "hints": [
    {
      "english": "Think about who has access to the emperor's desk.",
      "schinese": "想想谁能接近皇帝的案头。"
    },
    {
      "english": "Consider the timing of the disappearance.",
      "schinese": "考虑失踪的时间。"
    }
  ],
  "metadata": {
    "estimated_time": "10-15 minutes",
    "historical_context": "Based on real Ming Dynasty palace intrigue"
  }
}
```

### Question Structure

- **id**: Unique question identifier
- **text**: Question text (localized)
- **answer**: "yes", "no", or "irrelevant"
- **unlocks**: Array of question IDs unlocked by this answer

### Special Question ID

- **"SOLUTION"**: Unlocking this enables the solve button

---

## Vocabulary Database

### File Structure

```
content/
└── vocabulary/
    └── vocab_database.json
```

### Database Format

```json
{
  "schinese": {
    "word_001": {
      "word": "皇帝",
      "translation": "emperor",
      "level": 1,
      "context": "The emperor ruled the Ming Dynasty with absolute authority.",
      "part_of_speech": "noun",
      "frequency": "high",
      "tags": ["politics", "history"]
    },
    "word_002": {
      "word": "大臣",
      "translation": "minister",
      "level": 1,
      "context": "The minister advised the emperor on state affairs.",
      "part_of_speech": "noun",
      "frequency": "high",
      "tags": ["politics", "government"]
    }
  },
  "japanese": {
    "word_001": {
      "word": "皇帝",
      "translation": "emperor",
      "level": 2,
      "context": "皇帝は国を統治した。",
      "part_of_speech": "noun",
      "reading": "こうてい",
      "kanji": "皇帝"
    }
  }
}
```

### Vocabulary Fields

- **word**: Target language word
- **translation**: Primary language translation
- **level**: Difficulty level (1-12)
- **context**: Example sentence
- **part_of_speech**: noun, verb, adjective, etc.
- **frequency**: high, medium, low (optional)
- **tags**: Thematic tags (optional)
- **reading**: Pronunciation (for CJK languages)
- **kanji**: Kanji form (for Japanese)

### Level Guidelines

| Level | CEFR | HSK | JLPT | Description |
|-------|------|-----|------|-------------|
| 1-2   | A1   | 1   | N5   | Beginner - Basic words |
| 3-4   | A2   | 2   | N4   | Elementary - Common words |
| 5-6   | B1   | 3   | N3   | Intermediate - Everyday words |
| 7-8   | B2   | 4   | N2   | Upper Intermediate |
| 9-10  | C1   | 5   | N1   | Advanced |
| 11-12 | C2   | 6   | N1   | Mastery - Rare/Literary |

---

## Localization

### Translation Keys

All UI text uses translation keys stored in `locales/{lang}/ui.json`.

### Adding New Keys

1. Add to English locale:
```json
{
  "ui.new_feature.title": "New Feature",
  "ui.new_feature.description": "This is a new feature"
}
```

2. Add to all other locales with translations

3. Use in code:
```gdscript
label.text = LanguageManager.get_text("ui.new_feature.title")
```

### Key Naming Convention

- `ui.*` - UI elements
- `story.*` - Story-related text
- `investigation.*` - Investigation system
- `side.*` - Side stories
- `learning.*` - Vocabulary learning
- `error.*` - Error messages

---

## Best Practices

### Story Content

1. **Keep nodes focused**: One idea per node
2. **Use meaningful IDs**: `CH1_EMPEROR_DECISION` not `NODE_042`
3. **Balance POVs**: Ensure all three perspectives are represented
4. **Test choices**: Verify all choice paths work
5. **Add metadata**: Background, music, character sprites

### Side Stories

1. **Clear scenarios**: Mystery should be intriguing but solvable
2. **Logical questions**: Questions should lead toward solution
3. **Good hints**: Hints should guide without giving away answer
4. **Test thoroughly**: Ensure question tree works correctly

### Vocabulary

1. **Authentic context**: Use real sentences, not isolated words
2. **Appropriate level**: Match difficulty to target audience
3. **Thematic consistency**: Group related words
4. **Cultural notes**: Add context for cultural concepts

### Localization

1. **Natural language**: Translate meaning, not words
2. **Cultural adaptation**: Adjust idioms and references
3. **Consistent terminology**: Use same terms throughout
4. **Test in-game**: Verify text fits UI elements

---

## Tools and Workflow

### Content Compilation

Generate content from templates:
```bash
python tools/compile_content.py
```

### Content Validation

Validate all content:
```bash
python tools/validate_content.py
```

### Locale Validation

Check translations:
```bash
python tools/validate_locales.py
```

---

## Common Issues

### Node Not Found

**Problem**: Game can't find next node

**Solution**: Check node ID spelling, ensure node exists

### Missing Translation

**Problem**: Text shows as key instead of translation

**Solution**: Add translation to all locale files

### Choice Not Working

**Problem**: Choice doesn't trigger

**Solution**: Check conditions, verify next node ID

### Vocabulary Not Loading

**Problem**: Quiz shows no words

**Solution**: Check JSON format, verify language code

---

## Examples

### Complete Chapter Node Sequence

```json
{
  "nodes": {
    "CH1_START": {
      "type": "dialogue",
      "speaker": {"english": "Narrator", "schinese": "旁白"},
      "text": {"english": "The story begins...", "schinese": "故事开始..."},
      "pov": "emperor",
      "next": "CH1_002"
    },
    "CH1_002": {
      "type": "choice",
      "speaker": {"english": "Emperor", "schinese": "皇帝"},
      "text": {"english": "What to do?", "schinese": "如何是好？"},
      "pov": "emperor",
      "choices": [
        {
          "text": {"english": "Option A", "schinese": "选项A"},
          "next": "CH1_003"
        },
        {
          "text": {"english": "Option B", "schinese": "选项B"},
          "next": "CH1_004"
        }
      ]
    },
    "CH1_003": {
      "type": "dialogue",
      "text": {"english": "You chose A", "schinese": "你选择了A"},
      "pov": "emperor",
      "next": "CH1_END"
    },
    "CH1_004": {
      "type": "dialogue",
      "text": {"english": "You chose B", "schinese": "你选择了B"},
      "pov": "emperor",
      "next": "CH1_END"
    },
    "CH1_END": {
      "type": "dialogue",
      "text": {"english": "Chapter complete", "schinese": "章节完成"},
      "pov": "emperor",
      "next": ""
    }
  }
}
```

### Complete Turtle Soup Case

See example in Side Stories section above.

### Complete Vocabulary Entry

See example in Vocabulary Database section above.

---

## See Also

- [API Reference](API_REFERENCE.md)
- [Translation Keys](TRANSLATION_KEYS.md)
- [Content Format Specification](CONTENT_FORMAT.md)
