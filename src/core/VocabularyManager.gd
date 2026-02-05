extends Node
## VocabularyManager - Manages vocabulary learning and injection
## Handles immersion mode word injection and quiz generation

signal vocabulary_injected(word_data: Dictionary)
signal quiz_completed(correct: bool, word_data: Dictionary)

## Level systems mapping
const LEVEL_SYSTEMS := {
	"CEFR": ["A1", "A2", "B1", "B2", "C1", "C2"],
	"HSK": ["HSK1", "HSK2", "HSK3", "HSK4", "HSK5", "HSK6"],
	"JLPT": ["N5", "N4", "N3", "N2", "N1"],
	"TOPIK": ["TOPIK1", "TOPIK2", "TOPIK3", "TOPIK4", "TOPIK5", "TOPIK6"]
}

## Internal level to external level mapping (1-12 scale)
const INTERNAL_TO_EXTERNAL := {
	1: {"CEFR": "A1", "HSK": "HSK1", "JLPT": "N5", "TOPIK": "TOPIK1"},
	2: {"CEFR": "A1", "HSK": "HSK1", "JLPT": "N5", "TOPIK": "TOPIK1"},
	3: {"CEFR": "A2", "HSK": "HSK2", "JLPT": "N4", "TOPIK": "TOPIK2"},
	4: {"CEFR": "A2", "HSK": "HSK2", "JLPT": "N4", "TOPIK": "TOPIK2"},
	5: {"CEFR": "B1", "HSK": "HSK3", "JLPT": "N3", "TOPIK": "TOPIK3"},
	6: {"CEFR": "B1", "HSK": "HSK3", "JLPT": "N3", "TOPIK": "TOPIK3"},
	7: {"CEFR": "B2", "HSK": "HSK4", "JLPT": "N2", "TOPIK": "TOPIK4"},
	8: {"CEFR": "B2", "HSK": "HSK4", "JLPT": "N2", "TOPIK": "TOPIK4"},
	9: {"CEFR": "C1", "HSK": "HSK5", "JLPT": "N1", "TOPIK": "TOPIK5"},
	10: {"CEFR": "C1", "HSK": "HSK5", "JLPT": "N1", "TOPIK": "TOPIK5"},
	11: {"CEFR": "C2", "HSK": "HSK6", "JLPT": "N1", "TOPIK": "TOPIK6"},
	12: {"CEFR": "C2", "HSK": "HSK6", "JLPT": "N1", "TOPIK": "TOPIK6"}
}

var vocabulary_database: Dictionary = {}
var current_quiz: Dictionary = {}


func _ready() -> void:
	_load_vocabulary_database()


func _load_vocabulary_database() -> void:
	# Load vocabulary database from JSON
	var db_path := "res://content/vocabulary/vocab_database.json"

	if not FileAccess.file_exists(db_path):
		push_warning("[VocabularyManager] Vocabulary database not found, creating placeholder")
		_create_placeholder_database()
		return

	var file := FileAccess.open(db_path, FileAccess.READ)
	if file == null:
		push_error("[VocabularyManager] Failed to open vocabulary database")
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_text) == OK:
		vocabulary_database = json.data
		print("[VocabularyManager] Loaded %d vocabulary entries" % vocabulary_database.size())
	else:
		push_error("[VocabularyManager] Failed to parse vocabulary database: %s" % json.get_error_message())


func _create_placeholder_database() -> void:
	# Create minimal placeholder database
	vocabulary_database = {
		"schinese": {
			"word_001": {
				"word": "皇帝",
				"translation": "emperor",
				"level": 1,
				"context": "The emperor ruled the Ming Dynasty.",
				"part_of_speech": "noun"
			},
			"word_002": {
				"word": "大臣",
				"translation": "minister",
				"level": 2,
				"context": "The minister advised the emperor.",
				"part_of_speech": "noun"
			}
		}
	}


## Get vocabulary for current target language and level
func get_vocabulary_for_level(target_lang: String, level: int) -> Array:
	if not vocabulary_database.has(target_lang):
		return []

	var words: Array = []
	var lang_vocab: Dictionary = vocabulary_database[target_lang]

	for word_id in lang_vocab:
		var word_data: Dictionary = lang_vocab[word_id]
		if word_data.get("level", 1) <= level:
			words.append({
				"id": word_id,
				"word": word_data.word,
				"translation": word_data.translation,
				"level": word_data.level,
				"context": word_data.get("context", ""),
				"part_of_speech": word_data.get("part_of_speech", "")
			})

	return words


## Inject vocabulary into a sentence (immersion mode)
func inject_vocabulary(sentence: String, target_lang: String) -> Dictionary:
	# Check if immersion is enabled
	if not GameState.get_value("learning", "immersion_enabled", false):
		return {"text": sentence, "injected": false}

	# Check if we should inject based on rate
	var inject_rate: float = GameState.get_value("learning", "inject_rate", 0.10)
	if randf() > inject_rate:
		return {"text": sentence, "injected": false}

	# Get current level
	var level: int = GameState.get_value("learning", "level_estimate", 5)

	# Get available vocabulary
	var available_words := get_vocabulary_for_level(target_lang, level)
	if available_words.is_empty():
		return {"text": sentence, "injected": false}

	# Filter out mastered words
	var mastered: Array = GameState.get_value("learning", "mastered_words", [])
	var unmastered_words: Array = []
	for word in available_words:
		if word.id not in mastered:
			unmastered_words.append(word)

	if unmastered_words.is_empty():
		return {"text": sentence, "injected": false}

	# Pick a random word
	var word_data: Dictionary = unmastered_words[randi() % unmastered_words.size()]

	# Create injected sentence with BBCode
	var injected_text := "[color=yellow][url=%s]%s[/url][/color]" % [word_data.id, word_data.word]
	var result := {
		"text": injected_text,
		"injected": true,
		"word_data": word_data,
		"original_sentence": sentence
	}

	vocabulary_injected.emit(word_data)
	return result


## Generate a quiz question
func generate_quiz(target_lang: String) -> Dictionary:
	var level: int = GameState.get_value("learning", "level_estimate", 5)
	var available_words := get_vocabulary_for_level(target_lang, level)

	if available_words.is_empty():
		return {}

	# Pick a random word
	var correct_word: Dictionary = available_words[randi() % available_words.size()]

	# Generate distractors (wrong answers)
	var distractors: Array = []
	var all_words := available_words.duplicate()
	all_words.erase(correct_word)

	for i in range(3):
		if all_words.is_empty():
			break
		var distractor: Dictionary = all_words[randi() % all_words.size()]
		distractors.append(distractor)
		all_words.erase(distractor)

	# Create quiz question
	current_quiz = {
		"word": correct_word.word,
		"correct_translation": correct_word.translation,
		"context": correct_word.get("context", ""),
		"options": [correct_word.translation],
		"correct_index": 0,
		"word_id": correct_word.id
	}

	# Add distractors
	for distractor in distractors:
		current_quiz.options.append(distractor.translation)

	# Shuffle options
	var correct_answer := current_quiz.options[0]
	current_quiz.options.shuffle()
	current_quiz.correct_index = current_quiz.options.find(correct_answer)

	return current_quiz


## Submit quiz answer
func submit_quiz_answer(selected_index: int) -> bool:
	if current_quiz.is_empty():
		return false

	var correct := selected_index == current_quiz.correct_index

	# Update statistics
	var total: int = GameState.get_value("learning", "quiz_total", 0)
	var correct_count: int = GameState.get_value("learning", "quiz_correct", 0)

	total += 1
	if correct:
		correct_count += 1

	GameState.set_value("learning", "quiz_total", total)
	GameState.set_value("learning", "quiz_correct", correct_count)

	# Update correct rate
	var correct_rate := float(correct_count) / float(total)
	GameState.set_value("learning", "quiz_correct_rate", correct_rate)

	# Update level estimate based on performance
	_update_level_estimate(correct)

	# Mark word as mastered if answered correctly multiple times
	if correct:
		_check_word_mastery(current_quiz.word_id)

	quiz_completed.emit(correct, current_quiz)

	return correct


func _update_level_estimate(correct: bool) -> void:
	var current_level: int = GameState.get_value("learning", "level_estimate", 5)
	var correct_rate: float = GameState.get_value("learning", "quiz_correct_rate", 0.0)

	# Adjust level based on performance
	if correct_rate > 0.8 and current_level < 12:
		# Doing well, increase level
		GameState.set_value("learning", "level_estimate", current_level + 1)
	elif correct_rate < 0.5 and current_level > 1:
		# Struggling, decrease level
		GameState.set_value("learning", "level_estimate", current_level - 1)


func _check_word_mastery(word_id: String) -> void:
	# Simple mastery: mark as mastered after 3 correct answers
	# In a full implementation, this would track per-word statistics
	var mastered: Array = GameState.get_value("learning", "mastered_words", [])
	if word_id not in mastered:
		mastered.append(word_id)
		GameState.set_value("learning", "mastered_words", mastered)


## Get display level for current system
func get_display_level() -> String:
	var level: int = GameState.get_value("learning", "level_estimate", 5)
	var system: String = GameState.get_value("learning", "level_system", "CEFR")

	if INTERNAL_TO_EXTERNAL.has(level) and INTERNAL_TO_EXTERNAL[level].has(system):
		return INTERNAL_TO_EXTERNAL[level][system]

	return "Level %d" % level


## Get available level systems for target language
func get_level_systems_for_language(lang_code: String) -> Array:
	# Map languages to their appropriate level systems
	match lang_code:
		"schinese", "tchinese":
			return ["HSK", "CEFR"]
		"japanese":
			return ["JLPT", "CEFR"]
		"koreana":
			return ["TOPIK", "CEFR"]
		_:
			return ["CEFR"]


## Reset learning statistics
func reset_statistics() -> void:
	GameState.set_value("learning", "quiz_total", 0)
	GameState.set_value("learning", "quiz_correct", 0)
	GameState.set_value("learning", "quiz_correct_rate", 0.0)
	GameState.set_value("learning", "level_estimate", 5)
	GameState.set_value("learning", "mastered_words", [])

