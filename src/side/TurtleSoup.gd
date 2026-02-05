extends Control
## TurtleSoup - Lateral thinking puzzle game (海龟汤)
## Players ask yes/no questions to solve mysteries

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var difficulty_label: Label = $Panel/MarginContainer/VBoxContainer/DifficultyLabel
@onready var scenario_text: RichTextLabel = $Panel/MarginContainer/VBoxContainer/ScenarioPanel/ScenarioText
@onready var question_list: ItemList = $Panel/MarginContainer/VBoxContainer/HSplitContainer/LeftPanel/QuestionList
@onready var history_text: RichTextLabel = $Panel/MarginContainer/VBoxContainer/HSplitContainer/RightPanel/HistoryScroll/HistoryText
@onready var hint_button: Button = $Panel/MarginContainer/VBoxContainer/BottomPanel/HintButton
@onready var solve_button: Button = $Panel/MarginContainer/VBoxContainer/BottomPanel/SolveButton
@onready var back_button: Button = $Panel/MarginContainer/VBoxContainer/BottomPanel/BackButton
@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel

var current_case: Dictionary = {}
var available_questions: Array = []
var asked_questions: Array = []
var unlocked_question_ids: Array = []
var hints_used: int = 0
var turn_count: int = 0
var case_solved: bool = false


func _ready() -> void:
	_connect_signals()
	_load_case()


func _connect_signals() -> void:
	question_list.item_activated.connect(_on_question_activated)
	hint_button.pressed.connect(_on_hint_pressed)
	solve_button.pressed.connect(_on_solve_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _load_case() -> void:
	# Get current case from GameState
	var case_id: String = GameState.get_value("side", "case_id", "")

	if case_id.is_empty():
		# Default to first case
		case_id = "CASE_001"
		GameState.set_value("side", "case_id", case_id)

	# Load case data
	var case_path := "res://content/side/case_%s.json" % case_id.substr(5, 1)
	if not FileAccess.file_exists(case_path):
		push_error("[TurtleSoup] Case file not found: %s" % case_path)
		return

	var file := FileAccess.open(case_path, FileAccess.READ)
	if file == null:
		push_error("[TurtleSoup] Failed to open case file: %s" % case_path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)

	if error != OK:
		push_error("[TurtleSoup] JSON parse error: %s" % json.get_error_message())
		return

	current_case = json.data

	# Initialize state
	turn_count = GameState.get_value("side", "turn", 0)
	asked_questions = GameState.get_value("side", "asked_questions", [])
	hints_used = GameState.get_value("side", "hints_used", 0)
	case_solved = GameState.get_value("side", "state", "init") == "solved"

	# Start with first questions unlocked
	if unlocked_question_ids.is_empty():
		_unlock_initial_questions()

	_update_ui()


func _unlock_initial_questions() -> void:
	# Unlock questions that have no prerequisites (first questions)
	for question in current_case.questions:
		var is_initial := true
		# Check if this question is unlocked by any other question
		for other_q in current_case.questions:
			if question.id in other_q.get("unlocks", []):
				is_initial = false
				break
		if is_initial and question.id not in unlocked_question_ids:
			unlocked_question_ids.append(question.id)


func _update_ui() -> void:
	# Load translations
	var lang := GameState.get_value("settings", "lang_primary", "english")

	# Title and difficulty
	title_label.text = current_case.title.get(lang, current_case.title.english)
	var difficulty_text := LanguageManager.get_text("side.difficulty." + current_case.difficulty)
	difficulty_label.text = "%s: %s" % [
		LanguageManager.get_text("side.difficulty_label"),
		difficulty_text
	]

	# Scenario
	scenario_text.clear()
	scenario_text.append_text(current_case.scenario.get(lang, current_case.scenario.english))

	# Update question list
	_refresh_question_list()

	# Update history
	_refresh_history()

	# Update buttons
	hint_button.text = "%s (%d/%d)" % [
		LanguageManager.get_text("side.hint_button"),
		hints_used,
		current_case.hints.size()
	]
	hint_button.disabled = hints_used >= current_case.hints.size()

	solve_button.text = LanguageManager.get_text("side.solve_button")
	solve_button.disabled = not _can_attempt_solution()

	back_button.text = LanguageManager.get_text("ui.back")

	# Status
	if case_solved:
		status_label.text = LanguageManager.get_text("side.status_solved")
	else:
		status_label.text = LanguageManager.get_text("side.status_turn") % turn_count


func _refresh_question_list() -> void:
	question_list.clear()
	available_questions.clear()

	var lang := GameState.get_value("settings", "lang_primary", "english")

	for question in current_case.questions:
		var q_id: String = question.id
		# Skip already asked questions
		if q_id in asked_questions:
			continue
		# Only show unlocked questions
		if q_id not in unlocked_question_ids:
			continue

		available_questions.append(question)
		var q_text: String = question.text.get(lang, question.text.english)
		question_list.add_item(q_text)


func _refresh_history() -> void:
	history_text.clear()

	var lang := GameState.get_value("settings", "lang_primary", "english")

	# Show asked questions and answers
	for q_id in asked_questions:
		var question := _find_question_by_id(q_id)
		if question.is_empty():
			continue

		var q_text: String = question.text.get(lang, question.text.english)
		var answer: String = question.answer

		# Format answer
		var answer_text := ""
		match answer:
			"yes":
				answer_text = LanguageManager.get_text("side.answer_yes")
			"no":
				answer_text = LanguageManager.get_text("side.answer_no")
			"irrelevant":
				answer_text = LanguageManager.get_text("side.answer_irrelevant")
			_:
				answer_text = answer

		history_text.append_text("[b]Q:[/b] %s\n" % q_text)
		history_text.append_text("[b]A:[/b] %s\n\n" % answer_text)

	# Show hints if used
	for i in hints_used:
		if i < current_case.hints.size():
			var hint: String = current_case.hints[i].get(lang, current_case.hints[i].english)
			history_text.append_text("[color=yellow][b]%s:[/b] %s[/color]\n\n" % [
				LanguageManager.get_text("side.hint_label"),
				hint
			])

	# Show solution if solved
	if case_solved:
		var solution: String = current_case.solution.get(lang, current_case.solution.english)
		history_text.append_text("[color=green][b]%s:[/b]\n%s[/color]\n" % [
			LanguageManager.get_text("side.solution_label"),
			solution
		])


func _find_question_by_id(q_id: String) -> Dictionary:
	for question in current_case.questions:
		if question.id == q_id:
			return question
	return {}


func _can_attempt_solution() -> bool:
	# Player can attempt solution if they've unlocked the SOLUTION marker
	return "SOLUTION" in unlocked_question_ids and not case_solved


func _on_question_activated(index: int) -> void:
	if index < 0 or index >= available_questions.size():
		return

	var question: Dictionary = available_questions[index]
	var q_id: String = question.id

	# Mark as asked
	asked_questions.append(q_id)
	turn_count += 1

	# Unlock next questions
	for unlock_id in question.get("unlocks", []):
		if unlock_id not in unlocked_question_ids:
			unlocked_question_ids.append(unlock_id)

	# Save state
	GameState.set_value("side", "asked_questions", asked_questions)
	GameState.set_value("side", "turn", turn_count)

	# Record event for replay
	var replay_events: Array = GameState.get_value("side", "replay", {}).get("events", [])
	replay_events.append({
		"type": "question",
		"turn": turn_count,
		"question_id": q_id,
		"answer": question.answer
	})
	GameState.set_value("side", "replay", {
		"events": replay_events,
		"share_code": ""  # Will be generated on solve
	})

	_update_ui()


func _on_hint_pressed() -> void:
	if hints_used >= current_case.hints.size():
		return

	hints_used += 1
	GameState.set_value("side", "hints_used", hints_used)

	# Record hint usage
	var replay_events: Array = GameState.get_value("side", "replay", {}).get("events", [])
	replay_events.append({
		"type": "hint",
		"turn": turn_count,
		"hint_index": hints_used - 1
	})
	GameState.set_value("side", "replay", {
		"events": replay_events,
		"share_code": ""
	})

	_update_ui()


func _on_solve_pressed() -> void:
	if not _can_attempt_solution():
		return

	# Mark as solved
	case_solved = true
	GameState.set_value("side", "state", "solved")
	GameState.set_value("side", "result", "success")

	# Generate share code
	var share_code := _generate_share_code()
	var replay_data := GameState.get_value("side", "replay", {})
	replay_data["share_code"] = share_code
	GameState.set_value("side", "replay", replay_data)

	# Update flags
	var case_num := int(current_case.case_id.substr(5, 1))
	var flags: Dictionary = GameState.get_value("flags", "achievements_unlocked", [])
	var achievement_id := "SIDE_CASE_%d" % case_num
	if achievement_id not in flags:
		flags.append(achievement_id)
		GameState.set_value("flags", "achievements_unlocked", flags)

	_update_ui()

	# Show share code dialog
	_show_share_code_dialog(share_code)


func _generate_share_code() -> String:
	# Generate base64 encoded replay data
	var replay_data := {
		"case_id": current_case.case_id,
		"turns": turn_count,
		"hints": hints_used,
		"events": GameState.get_value("side", "replay", {}).get("events", [])
	}

	var json_str := JSON.stringify(replay_data)
	var bytes := json_str.to_utf8_buffer()
	return Marshalls.raw_to_base64(bytes)


func _show_share_code_dialog(share_code: String) -> void:
	# Create popup dialog
	var dialog := AcceptDialog.new()
	dialog.title = LanguageManager.get_text("side.share_title")
	dialog.dialog_text = "%s\n\n%s\n\n%s: %d\n%s: %d" % [
		LanguageManager.get_text("side.share_message"),
		share_code,
		LanguageManager.get_text("side.share_turns"),
		turn_count,
		LanguageManager.get_text("side.share_hints"),
		hints_used
	]
	dialog.ok_button_text = LanguageManager.get_text("ui.ok")

	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())


func _on_back_pressed() -> void:
	# Return to main menu or story
	GameState.set_value("nav", "screen", "home")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

