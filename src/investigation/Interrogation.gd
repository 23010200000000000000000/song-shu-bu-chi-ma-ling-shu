extends Control
## Interrogation - Structured questioning system for investigation

@onready var title_label := $Title
@onready var subject_label := $SubjectPanel/MarginContainer/VBoxContainer/SubjectLabel
@onready var context_label := $SubjectPanel/MarginContainer/VBoxContainer/ContextLabel
@onready var question_label := $QuestionPanel/MarginContainer/VBoxContainer/QuestionLabel
@onready var question_list := $QuestionPanel/MarginContainer/VBoxContainer/QuestionList
@onready var response_label := $ResponsePanel/MarginContainer/VBoxContainer/ResponseLabel
@onready var response_text := $ResponsePanel/MarginContainer/VBoxContainer/ResponseText
@onready var continue_button := $ControlPanel/ContinueButton
@onready var back_button := $ControlPanel/BackButton

var current_subject := ""
var current_context := ""
var available_questions := []
var asked_questions := []
var current_response := ""


func _ready() -> void:
	_update_ui_text()
	_load_interrogation_data()

	if LanguageManager:
		LanguageManager.language_changed.connect(_on_language_changed)


func _update_ui_text() -> void:
	if not LanguageManager:
		return

	title_label.text = LanguageManager.tr("ui.investigation.interrogate")
	question_label.text = "Select your line of questioning:"
	response_label.text = "Response:"
	continue_button.text = LanguageManager.tr("ui.story.continue")
	back_button.text = LanguageManager.tr("ui.confirm.cancel")


func _load_interrogation_data() -> void:
	"""Load interrogation scenario"""
	if not GameState:
		_load_placeholder_data()
		return

	# Get interrogation log from GameState
	var interrogate_log: Array = GameState.get_value("evidence", "interrogate_log", [])

	if interrogate_log.is_empty():
		_load_placeholder_data()
		return

	# Load most recent interrogation
	var interrogation := interrogate_log[-1]
	current_subject = interrogation.get("subject", "Unknown")
	current_context = interrogation.get("context", "")
	available_questions = interrogation.get("questions", [])

	_display_interrogation()


func _load_placeholder_data() -> void:
	"""Load placeholder interrogation data"""
	current_subject = "Minister"
	current_context = "Discrepancy found in official records regarding number of candidates"

	var lang := LanguageManager.current_language if LanguageManager else "english"

	available_questions = [
		{
			"id": "Q001",
			"text": {
				"english": "How many candidates did you review?",
				"schinese": "你审查了多少候选人？"
			},
			"response": {
				"english": "I reviewed four candidates in total, as stated in my report.",
				"schinese": "我总共审查了四名候选人，正如我报告中所述。"
			},
			"unlocks": ["Q002"],
			"stance_change": {"axis_truth": 5, "axis_loyalty": {"minister": 2}}
		},
		{
			"id": "Q002",
			"text": {
				"english": "The Emperor's edict mentions only three. Can you explain this discrepancy?",
				"schinese": "皇帝的诏书只提到三人。你能解释这个差异吗？"
			},
			"response": {
				"english": "Perhaps there was a misunderstanding. I found one additional qualified candidate after the initial review.",
				"schinese": "也许有误解。我在初步审查后发现了一名额外的合格候选人。"
			},
			"unlocks": ["Q003"],
			"stance_change": {"axis_truth": 10, "axis_loyalty": {"minister": -3}},
			"locked": true
		},
		{
			"id": "Q003",
			"text": {
				"english": "Was this additional candidate approved by the Emperor?",
				"schinese": "这名额外的候选人得到皇帝批准了吗？"
			},
			"response": {
				"english": "I... I submitted the list for approval, but I have not yet received confirmation.",
				"schinese": "我...我提交了名单等待批准，但尚未收到确认。"
			},
			"unlocks": [],
			"stance_change": {"axis_truth": 15, "axis_loyalty": {"minister": -5}},
			"locked": true
		}
	]

	_display_interrogation()


func _display_interrogation() -> void:
	"""Display the interrogation interface"""
	subject_label.text = "Subject: %s" % current_subject
	context_label.text = "Context: %s" % current_context

	_populate_questions()


func _populate_questions() -> void:
	"""Populate available questions"""
	# Clear existing questions
	for child in question_list.get_children():
		child.queue_free()

	var lang := LanguageManager.current_language if LanguageManager else "english"

	# Add available questions
	for question in available_questions:
		var question_id := question.get("id", "")

		# Skip if already asked
		if question_id in asked_questions:
			continue

		# Skip if locked
		if question.get("locked", false):
			continue

		# Create question button
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 50)

		var text_data := question.get("text", {})
		var question_text := text_data.get(lang, text_data.get("english", "Question"))

		button.text = question_text
		button.pressed.connect(_on_question_selected.bind(question))

		question_list.add_child(button)


func _on_question_selected(question: Dictionary) -> void:
	"""Handle question selection"""
	var question_id := question.get("id", "")

	print("[Interrogation] Question selected: %s" % question_id)

	# Mark as asked
	asked_questions.append(question_id)

	# Display response
	var lang := LanguageManager.current_language if LanguageManager else "english"
	var response_data := question.get("response", {})
	current_response = response_data.get(lang, response_data.get("english", "No response"))

	response_text.text = current_response

	# Apply stance changes
	var stance_change := question.get("stance_change", {})
	_apply_stance_changes(stance_change)

	# Unlock new questions
	var unlocks: Array = question.get("unlocks", [])
	_unlock_questions(unlocks)

	# Update GameState
	if GameState:
		var interrogate_log: Array = GameState.get_value("evidence", "interrogate_log", [])
		interrogate_log.append({
			"subject": current_subject,
			"question_id": question_id,
			"response": current_response,
			"timestamp": Time.get_datetime_string_from_system()
		})
		GameState.set_value("evidence", "interrogate_log", interrogate_log)

		# Set flag
		var flags := GameState.get_value("main", "flags", {})
		flags["did_key_interrogate"] = true
		GameState.set_value("main", "flags", flags)

	# Refresh question list
	_populate_questions()


func _apply_stance_changes(stance_change: Dictionary) -> void:
	"""Apply stance changes from question"""
	if not GameState:
		return

	# Apply truth axis change
	if stance_change.has("axis_truth"):
		var current_truth := GameState.get_value("stance", "axis_truth", 0)
		var new_truth := current_truth + stance_change["axis_truth"]
		GameState.set_value("stance", "axis_truth", clamp(new_truth, -100, 100))

	# Apply loyalty changes
	if stance_change.has("axis_loyalty"):
		var loyalty_changes: Dictionary = stance_change["axis_loyalty"]
		var current_loyalty := GameState.get_value("stance", "axis_loyalty", {})

		for pov in loyalty_changes.keys():
			var current := current_loyalty.get(pov, 0)
			var change := loyalty_changes[pov]
			current_loyalty[pov] = clamp(current + change, -100, 100)

		GameState.set_value("stance", "axis_loyalty", current_loyalty)

	print("[Interrogation] Stance updated: %s" % stance_change)


func _unlock_questions(unlock_ids: Array) -> void:
	"""Unlock new questions"""
	for question in available_questions:
		if question.get("id", "") in unlock_ids:
			question["locked"] = false
			print("[Interrogation] Unlocked question: %s" % question["id"])


func _on_continue_pressed() -> void:
	"""Continue to next phase"""
	print("[Interrogation] Continuing...")

	# Save state
	if SaveManager:
		SaveManager.auto_save()

	# Return to story
	get_tree().change_scene_to_file("res://scenes/story/StoryPlayer.tscn")


func _on_back_pressed() -> void:
	"""Return without completing interrogation"""
	print("[Interrogation] Returning to story...")
	get_tree().change_scene_to_file("res://scenes/story/StoryPlayer.tscn")


func _on_language_changed(_lang_code: String) -> void:
	_update_ui_text()
	_display_interrogation()


## Public API
func load_interrogation(subject: String, context: String, questions: Array) -> void:
	"""Load specific interrogation scenario"""
	current_subject = subject
	current_context = context
	available_questions = questions
	asked_questions.clear()
	_display_interrogation()
