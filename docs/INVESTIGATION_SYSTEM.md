# Investigation System Documentation

## Overview

The investigation system is a core gameplay mechanic in "万历十四年·朱笔未落" that allows players to examine historical documents, compare evidence, interrogate characters, and archive their conclusions. This system directly affects the game's ending through the stance/口径 system.

## Four Investigation Actions

### 1. Read (阅读)
- **Scene**: `StoryPlayer.tscn`
- **Purpose**: Read story nodes and documents from different perspectives
- **Features**:
  - Three-protagonist perspective switching (Emperor/Consort/Minister)
  - Dialogue box with auto-play and skip functionality
  - Backlog system for reviewing previous text
  - Tracks visited nodes in GameState

### 2. Compare (对比)
- **Scene**: `EvidenceComparison.tscn`
- **Script**: `src/investigation/EvidenceComparison.gd`
- **Purpose**: Side-by-side comparison of two documents to find contradictions
- **Features**:
  - Split-screen document display
  - Automatic difference highlighting
  - Mark contradictions button
  - Saves comparison history to GameState.evidence.compare_history
  - Sets did_key_compare flag when used

### 3. Interrogate (问询)
- **Scene**: `Interrogation.tscn`
- **Script**: `src/investigation/Interrogation.gd`
- **Purpose**: Question characters about events and documents
- **Features**:
  - Character portrait display
  - Structured question selection
  - Response display with stance changes
  - Saves interrogation log to GameState.evidence.interrogate_log
  - Applies stance changes to GameState.stance axes
  - Sets did_key_interrogate flag when used

### 4. Archive (归档)
- **Scene**: `ArchiveSealing.tscn`
- **Script**: `src/investigation/ArchiveSealing.gd`
- **Purpose**: Review evidence and seal conclusions
- **Features**:
  - Evidence list showing all collected comparisons, interrogations, and contradictions
  - Conclusion text editor
  - Four seal types with different stance effects
  - Saves archive entries to GameState.archive.entries
  - Sets did_archive_confirm flag when used
  - Auto-saves after sealing

## Seal Types and Effects

The archive system offers four seal types, each with different narrative and mechanical implications:

### 1. Routine Filing (例行归档)
- **Effect**: Neutral - no major stance changes
- **Use case**: Standard bureaucratic processing
- **Narrative**: Treat the case as routine administrative matter

### 2. Confidential Sealing (机密封存)
- **Effect**: axis_truth -5 (slightly suppress truth)
- **Use case**: Sensitive information that should be kept internal
- **Narrative**: Protect certain parties or maintain stability

### 3. Imperial Review (御览呈报)
- **Effect**: axis_truth +10 (favor allowing truth to reach emperor)
- **Use case**: Important matters requiring imperial attention
- **Narrative**: Ensure the emperor knows the full truth

### 4. Suppress/Conceal (压制不报)
- **Effect**: axis_truth -15 (strongly suppress truth)
- **Use case**: Dangerous information that must be buried
- **Narrative**: Actively prevent truth from emerging

## GameState Integration

### Evidence Domain
```gdscript
"evidence": {
  "compare_history": [],      # Array of comparison records
  "interrogate_log": [],       # Array of interrogation records
  "contradictions_found": []   # Array of contradiction IDs
}
```

### Archive Domain
```gdscript
"archive": {
  "entries": [],      # Array of ArchiveEntry dicts
  "seal_counts": {}   # Count of each seal type used
}
```

### Archive Entry Structure
```gdscript
{
  "chapter": 1,
  "timestamp": "2026-02-05T12:34:56",
  "conclusion": "Player's written conclusion",
  "seal_type": "imperial",
  "evidence_count": 5,
  "evidence_snapshot": [...]  # Full copy of collected evidence
}
```

### Main Flags
```gdscript
"main": {
  "flags": {
    "visited_all_pov_in_chapter": false,
    "did_key_compare": false,
    "did_key_interrogate": false,
    "did_archive_confirm": false
  }
}
```

## Stance System Integration

The investigation system directly affects the stance/口径 system, which determines the game's ending:

### Truth Axis (axis_truth)
- Range: -100 to +100
- Negative: Favor usable narrative over truth
- Positive: Allow truth to emerge
- Modified by: Seal types, interrogation responses

### Loyalty Axes (axis_loyalty)
- Three axes: emperor, consort, minister
- Range: -100 to +100
- Modified by: Interrogation responses, perspective choices

### Blame Axes (axis_blame)
- Three axes: emperor, consort, minister
- Range: -100 to +100
- Modified by: Interrogation responses, conclusion content

## Workflow Example

1. **Read Phase**: Player reads story nodes from all three perspectives
   - Sets pov_visited flags
   - Unlocks investigation options

2. **Compare Phase**: Player compares conflicting documents
   - Highlights differences
   - Marks contradictions
   - Saves to compare_history

3. **Interrogate Phase**: Player questions characters
   - Selects questions based on evidence
   - Receives responses
   - Stance changes applied
   - Saves to interrogate_log

4. **Archive Phase**: Player reviews and seals
   - Reviews all collected evidence
   - Writes conclusion
   - Selects seal type
   - Stance changes applied
   - Archive entry saved
   - Auto-save triggered

5. **Ending Calculation**: At chapter end
   - Reads stance axes
   - Reads archive entries
   - Reads flags
   - Calculates appropriate ending

## Translation Keys

All investigation UI elements are fully localized. Key translation namespaces:

- `investigation.comparison.*` - Evidence comparison UI
- `investigation.interrogation.*` - Interrogation UI
- `investigation.archive.*` - Archive/sealing UI
- `investigation.seal_type.*` - Seal type names
- `investigation.evidence_type.*` - Evidence type labels

## Future Enhancements

Potential improvements for the investigation system:

1. **Evidence Timeline**: Visual timeline of events based on collected evidence
2. **Relationship Graph**: Network diagram showing character connections
3. **Document Annotations**: Allow players to highlight and annotate documents
4. **Evidence Filtering**: Filter evidence by type, chapter, or character
5. **Archive Review**: Gallery to review past archive entries
6. **Achievement Integration**: Achievements for specific investigation patterns
7. **Replay System**: Replay investigation sequences with different choices

