# Turtle Soup Side Story System Documentation

## Overview

The Turtle Soup (海龟汤) system implements lateral thinking puzzles as side stories in "万历十四年·朱笔未落". Players ask yes/no questions to uncover the truth behind mysterious scenarios, similar to the classic "situation puzzles" or "lateral thinking puzzles" format.

## Game Mechanics

### Core Gameplay Loop

1. **Case Selection** - Player chooses from available cases
2. **Scenario Presentation** - Initial mysterious scenario is shown
3. **Question Phase** - Player asks yes/no questions to gather information
4. **Progressive Unlocking** - Correct questions unlock new questions
5. **Solution** - Player reveals the solution when ready
6. **Replay Sharing** - Generate shareable replay code

### Question System

Questions follow a tree structure where:
- Initial questions are available from the start
- Answering questions unlocks new questions
- Questions can have three answer types:
  - **Yes** - Affirmative answer
  - **No** - Negative answer
  - **Irrelevant** - Question doesn't help solve the puzzle

### Hint System

- Each case has 2-3 hints available
- Hints are revealed one at a time
- Using hints is tracked in the replay
- Hints guide players toward the solution

### Difficulty Levels

- **Easy**: Straightforward scenarios with clear question paths
- **Medium**: Requires lateral thinking and careful questioning
- **Hard**: Complex scenarios with misleading information

## File Structure

### Scenes
- `scenes/side/CaseSelection.tscn` - Case selection menu
- `scenes/side/TurtleSoup.tscn` - Main game scene

### Scripts
- `src/side/CaseSelection.gd` - Case selection logic
- `src/side/TurtleSoup.gd` - Game logic and state management

### Content
- `content/side/case_1.json` - Case 1 data
- `content/side/case_2.json` - Case 2 data
- `content/side/case_3.json` - Case 3 data

## Case Data Format

```json
{
  "case_id": "CASE_001",
  "title": {
    "english": "The Mystery of Case 1",
    "schinese": "案件1之谜"
  },
  "difficulty": "medium",
  "scenario": {
    "english": "A mysterious event occurred...",
    "schinese": "发生了一件神秘事件..."
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
    }
  ],
  "solution": {
    "english": "The truth was...",
    "schinese": "真相是..."
  },
  "hints": [
    {
      "english": "Think about the timing...",
      "schinese": "思考时间顺序..."
    }
  ],
  "metadata": {
    "compiled_at": "2026-02-05T12:41:31",
    "estimated_time": "10-15 minutes"
  }
}
```

## GameState Integration

### Side Domain
```gdscript
"side": {
  "case_id": "CASE_001",           # Current case ID
  "state": "playing",              # init|playing|solved|failed
  "turn": 5,                       # Question turn counter
  "asked_questions": ["Q001", "Q002"],  # Questions already asked
  "hints_used": 1,                 # Number of hints used
  "result": "success",             # Final result
  "replay": {
    "events": [...],               # Full event log
    "share_code": "base64..."      # Shareable replay code
  }
}
```

### Replay Event Structure
```gdscript
{
  "type": "question",              # question|hint|solve
  "turn": 3,
  "question_id": "Q003",
  "answer": "yes"
}
```

## UI Components

### CaseSelection Scene
- **Case List**: Shows all available cases with difficulty
- **Description Panel**: Displays scenario when case is selected
- **Play Button**: Starts the selected case
- **Back Button**: Returns to main menu

### TurtleSoup Scene
- **Title**: Case title and difficulty
- **Scenario Panel**: Initial mysterious scenario
- **Question List**: Available questions (left panel)
- **History Panel**: Asked questions and answers (right panel)
- **Hint Button**: Request hints (shows count)
- **Solve Button**: Reveal solution (unlocked when ready)
- **Status Label**: Current turn count or solved status

## Features

### Progressive Question Unlocking
Questions unlock based on a tree structure:
- Initial questions have no prerequisites
- Answering questions unlocks new questions via `unlocks` array
- Special "SOLUTION" marker unlocks the solve button

### Replay System
When a case is solved:
1. All events (questions, hints) are recorded
2. A base64-encoded replay code is generated
3. Player can share the code with others
4. Replay includes: case_id, turns, hints_used, full event log

### Achievement Integration
Solving cases unlocks achievements:
- `SIDE_CASE_1` - Solved Case 1
- `SIDE_CASE_2` - Solved Case 2
- `SIDE_CASE_3` - Solved Case 3

## Translation Keys

All UI elements are fully localized:

### Side Story Keys
- `side.difficulty_label` - "Difficulty"
- `side.difficulty.easy` - "Easy"
- `side.difficulty.medium` - "Medium"
- `side.difficulty.hard` - "Hard"
- `side.hint_button` - "Hint"
- `side.solve_button` - "Reveal Solution"
- `side.hint_label` - "Hint"
- `side.solution_label` - "Solution"
- `side.answer_yes` - "Yes"
- `side.answer_no` - "No"
- `side.answer_irrelevant` - "Irrelevant"
- `side.status_turn` - "Turn: {0}"
- `side.status_solved` - "Case Solved!"
- `side.share_title` - "Case Solved!"
- `side.share_message` - Share message text
- `side.share_turns` - "Turns"
- `side.share_hints` - "Hints Used"
- `side.case_selection_title` - "Turtle Soup Cases"
- `side.play_case` - "Play Case"

## Workflow Example

1. **Player selects case** from CaseSelection menu
   - GameState.side initialized with case_id
   - State set to "playing"
   - Turn counter reset to 0

2. **Player sees scenario** in TurtleSoup scene
   - Initial questions are unlocked
   - Question list populated

3. **Player asks questions**
   - Click question in list
   - Answer is revealed in history
   - Turn counter increments
   - New questions unlock based on answer

4. **Player uses hints** (optional)
   - Click hint button
   - Hint appears in history
   - Hint count increments

5. **Player solves case**
   - "SOLUTION" marker unlocked
   - Solve button enabled
   - Click solve button
   - Solution revealed
   - Replay code generated
   - Achievement unlocked

6. **Player shares replay**
   - Copy base64 replay code
   - Share with friends
   - Others can see the solution path

## Future Enhancements

Potential improvements:

1. **Replay Viewer**: Import and view shared replay codes
2. **Leaderboard**: Track fastest solutions (fewest turns)
3. **Custom Cases**: User-generated content support
4. **Multiplayer**: Collaborative case solving
5. **Time Limits**: Optional timed challenges
6. **Branching Solutions**: Multiple valid solution paths
7. **Evidence Integration**: Link to main story evidence
8. **Character Interrogation**: Use main story characters in cases
9. **Historical Cases**: Real historical mysteries from Ming Dynasty
10. **Achievement Tiers**: Bronze/Silver/Gold based on performance

## Design Philosophy

The Turtle Soup system is designed to:
- Encourage lateral thinking and creative problem-solving
- Provide bite-sized gameplay sessions (10-15 minutes)
- Complement the main investigation gameplay
- Offer replayability through sharing and optimization
- Maintain historical authenticity while being accessible
- Support both casual and competitive play styles

## Integration with Main Story

While side stories are standalone, they can:
- Reference events from the main story
- Use similar investigation themes
- Reward players with insights into main characters
- Unlock bonus content in the main story
- Provide practice for investigation mechanics
