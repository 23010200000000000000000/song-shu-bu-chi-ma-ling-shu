# 万历十四年·朱笔未落
## The Wanli Year 14: The Vermillion Brush Unfallen

A narrative investigation game set in Ming Dynasty China, featuring archive-based detective work, three-protagonist perspective switching, and immersive language learning across 29 modern and 4 ancient languages.

---

## 🎮 Game Overview

**Genre**: Narrative Investigation / Visual Novel / Educational
**Platform**: Windows (Steam), with Steam Deck support
**Engine**: Godot 4.6
**Languages**: 29 modern languages + 4 ancient languages
**Estimated Playtime**: 30+ hours (main story + side content)

### Core Features

- **Three-Protagonist Perspective System**: Experience the same events from three different viewpoints (Emperor, Consort, Minister)
- **Archive Investigation Gameplay**: Read, compare, interrogate, and archive evidence to uncover the truth
- **29-Language Support**: Full localization with three display modes (monolingual, bilingual, immersion learning)
- **Multiple Endings**: Your investigation choices determine which version of history gets recorded
- **Turtle Soup Side Stories**: Lateral thinking puzzles with replay sharing
- **Steam Integration**: Achievements, Cloud Saves, Steam Input support

---

## 📁 Project Structure

```
C:\Users\steam\game\
├── project.godot          # Godot 4.6 project file
├── src/                   # Source code
│   ├── core/             # Core systems
│   │   ├── GameState.gd  # Global state management (13 domains)
│   │   ├── LanguageManager.gd  # 29-language system
│   │   ├── SaveManager.gd      # Save/load with Steam Cloud
│   │   └── SteamManager.gd     # Steamworks integration
│   ├── ui/               # UI scripts
│   │   ├── MainMenu.gd
│   │   └── Settings.gd
│   └── story/            # Story systems
│       └── StoryPlayer.gd
├── scenes/               # Scene files
│   ├── Main.tscn        # Main menu
│   ├── ui/              # UI scenes
│   └── story/           # Story scenes
├── content/             # Runtime content (compiled)
├── locales/             # Localization files
│   ├── _meta/
│   │   ├── language_registry.json  # Language definitions
│   │   └── fallback_rules.json     # Fallback chains
│   ├── english/
│   ├── schinese/
│   └── [27 more languages]/
├── assets/              # Art, audio, fonts
└── tools/               # Build and validation scripts
```

---

## 🚀 Quick Start

### Prerequisites

1. **Godot 4.6.stable.official.89cea1439** (exact version required)
2. **Git** (for version control)
3. **Python 3.8+** (for build scripts)

### Running the Game

```bash
# Open in Godot Editor
cd C:\Users\steam\game
godot project.godot

# Or run directly
godot --path C:\Users\steam\game
```

### Controls

- **Space / Left Click**: Advance dialogue
- **A**: Toggle auto-play
- **Ctrl**: Skip (hold)
- **Mouse Wheel Up / Page Up**: Open backlog
- **Esc**: Menu
- **Tab**: Cycle perspectives

---

## 🌍 Language System

### Supported Languages (29 Modern + 4 Ancient)

**Modern Languages**:
- CJK: Simplified Chinese, Traditional Chinese, Japanese, Korean
- European: English, French, German, Spanish (Spain), Spanish (Latin America), Portuguese (Brazil), Portuguese (Portugal), Italian, Dutch, Polish, Russian, Ukrainian, Czech, Hungarian, Romanian, Bulgarian, Greek, Danish, Finnish, Norwegian, Swedish
- Asian: Thai, Vietnamese, Indonesian
- Middle Eastern: Turkish, Arabic

**Ancient Languages** (learning mode only):
- Ancient Hebrew, Latin, Ancient Greek, Classical Chinese (文言文)

### Display Modes

1. **Monolingual**: Single language display
2. **Bilingual**: Two languages side-by-side
3. **Immersion Learning**: Target language words highlighted with primary language hints

---

## 💾 Save System

- **100 Manual Save Slots**: Named and timestamped
- **10 Auto-Save Slots**: Rolling automatic saves
- **Quick Save/Load**: Slot 0 for rapid saving
- **Steam Cloud Sync**: Automatic synchronization across devices
- **Save Migration**: Forward-compatible schema versioning
- **Demo → Full**: Save files transfer from Demo to Full version

---

## 🎯 Gameplay Systems

### Investigation Actions

1. **Read**: Examine documents and testimonies
2. **Compare**: Side-by-side evidence comparison with diff highlighting
3. **Interrogate**: Structured questioning to reveal contradictions
4. **Archive**: Seal your conclusions and determine the official record

### Perspective Switching

- **Emperor's View**: Access to imperial decisions and court politics
- **Consort's View**: Insight into personal motivations and palace intrigue
- **Minister's View**: Understanding of bureaucratic processes and institutional constraints

Each perspective reveals unique evidence. All three must be explored to complete the investigation.

### Multiple Endings

Your choices determine:
- Which evidence enters the historical record
- Who bears responsibility
- The "official" narrative vs. the hidden truth

---

## 🏆 Achievements

60 achievements covering:
- Story progress (chapter completion)
- Investigation milestones (evidence discovered, contradictions found)
- Perspective mastery (view all three perspectives)
- Endings (unlock different conclusions)
- Side stories (complete turtle soup cases)
- Learning achievements (vocabulary milestones)

---

## 🛠️ Development

### Build Commands

```bash
# Validate all systems
cd tools
./validate_all.sh

# Export Demo
python export_demo_full.py --demo

# Export Full
python export_demo_full.py --full
```

### Validation Scripts

- `validate_engine.sh` - Check Godot version
- `validate_locales.sh` - Verify all 29 languages
- `validate_fonts.sh` - Test font coverage
- `validate_content.sh` - Check story data
- `validate_saves.sh` - Test save/load
- `validate_steam_offline.sh` - Verify graceful degradation
- `validate_input.sh` - Check input mappings
- `validate_export.sh` - Validate builds

---

## 📚 Documentation

- **[PROJECT_SUMMARY.md](docs/PROJECT_SUMMARY.md)** - Complete project summary
- **[API_REFERENCE.md](docs/API_REFERENCE.md)** - Complete API documentation
- **[CONTENT_CREATION_GUIDE.md](docs/CONTENT_CREATION_GUIDE.md)** - Content authoring guide
- **[BUILD.md](docs/BUILD.md)** - Complete build instructions
- **[DECISIONS.md](docs/DECISIONS.md)** - Technical decisions log
- **[INVESTIGATION_SYSTEM.md](docs/INVESTIGATION_SYSTEM.md)** - Investigation gameplay documentation
- **[TURTLE_SOUP_SYSTEM.md](docs/TURTLE_SOUP_SYSTEM.md)** - Turtle soup side story documentation
- **[VOCABULARY_LEARNING_SYSTEM.md](docs/VOCABULARY_LEARNING_SYSTEM.md)** - Vocabulary learning documentation
- **[EXPORT_SYSTEM.md](docs/EXPORT_SYSTEM.md)** - Demo/Full export system documentation

---

## 🎨 Art Style

- **Visual Style**: Watercolor + ink fusion, paper texture
- **Color Palette**: Low saturation, cool tones with warm accents
- **UI Design**: Archive/document aesthetic with traditional Chinese elements
- **No Text in Images**: All text programmatically rendered for localization

---

## ⚙️ Technical Specifications

### Minimum Requirements

- **OS**: Windows 10/11 (64-bit)
- **GPU**: Intel Arc iGPU or equivalent
- **RAM**: 32GB (shared VRAM ≤8GB for game)
- **Storage**: 5GB available space
- **Additional**: Steam account (for Steam features)

### Performance Targets

- **2D Scenes**: 60fps on minimum spec
- **2.5D Scenes**: 30fps minimum (toggleable)
- **Load Times**: <1 second for saves
- **Memory**: <8GB shared VRAM usage

---

## 🔧 Troubleshooting

### Common Issues

**"Godot version mismatch"**
- Download exact version: v4.6.stable.official.89cea1439

**"Missing translation keys"**
- Run `validate_locales.sh` to generate report

**"Font rendering issues"**
- Verify Noto fonts in `assets/fonts/`
- Check `language_registry.json` font paths

**"Steam not available"**
- Game runs offline with degraded features
- Check logs for graceful degradation messages

---

## 📝 License

[License information to be added]

---

## 🤝 Contributing

[Contribution guidelines to be added]

---

## 📧 Contact

- **GitHub**: [Repository URL]
- **Steam Community**: [Community URL]
- **Discord**: [Discord invite]

---

## 🙏 Credits

### Development Team
- [Team credits to be added]

### Special Thanks
- Godot Engine community
- GodotSteam contributors
- Noto Fonts (Google)
- All playtesters and translators

---

**Version**: 0.1.0 Demo
**Last Updated**: 2026-02-05
**Status**: Foundation Complete, Implementation In Progress

---

## 📊 Project Status

### Completed ✓
- [x] Godot 4.6 project structure
- [x] 29-language system with RTL support
- [x] Global state management (13 domains)
- [x] Save/load system with Steam Cloud
- [x] Main menu and settings UI
- [x] Story player with dialogue box
- [x] Three-protagonist perspective switching
- [x] Graceful Steam degradation
- [x] Archive investigation gameplay (Read/Compare/Interrogate/Archive)
- [x] Story content integration (7 chapters, 91 nodes)
- [x] Placeholder art assets (22 assets)
- [x] Validation scripts (engine, locales, content)
- [x] Turtle soup side story system (lateral thinking puzzles)
- [x] Vocabulary learning and quiz system (adaptive, multi-framework)
- [x] Demo/Full export system (automated build pipeline)

### Planned 📋
- [ ] Full Steamworks integration (GodotSteam)
- [ ] Achievement system (60 achievements)
- [ ] Complete localization (all 29 languages)
- [ ] Final art assets
- [ ] Audio implementation

---

**Overall Progress**: ~85% Complete
