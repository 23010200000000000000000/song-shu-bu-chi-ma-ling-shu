extends Control
## VocabularyQuiz - Quiz interface for vocabulary learning

@onready var question_label: Label = $Panel/MarginContainer/VBoxContainer/QuestionLabel
@onready var word_label: Label = $Panel/MarginContainer/VBoxContainer/WordPanel/WordLabel
@onready var context_label: Label = $Panel/MarginContainer/VBoxContainer/ContextLabel
@onready var option_buttons: Array = [
	$Panel/MarginContainer/VBoxContainer/OptionsContainer/Option1,
	$Panel/MarginContainer/VBoxContainer/OptionsContainer/Option2,
	$Panel/MarginContainer/VBoxContainer/OptionsContainer/Option3,
	$Panel/MarginContainer/VBoxContainer/OptionsContainer/Option4
]
@onready var result_label: Label = $Panel/MarginContainer/VBoxContainer/ResultLabel
@onready var stats_label: Label = $Panel/MarginContainer/VBoxContainer/StatsLabel
@onready var next_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonPanel/NextButton
@onready var back_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonPanel/BackButton

var current_quiz: Dictionary = {}
var quiz_answered: bool = false


func _ready() -> void:
	_connect_signals()
	_load_translations()
	_generate_new_quiz()


func _connect_signals() -> void:
	for i in range(option_buttons.size()):
		if option_buttons[i]:
			option_buttons[i].pressed.connect(_on_option_pressed.bind(i))

	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)

	if VocabularyManager:
		VocabularyManager.quiz_completed.connect(_on_quiz_completed)


func _load_translations() -> void:
	question_label.text = LanguageManager.get_text("learning.quiz_question")
	next_button.text = LanguageManager.get_text("learning.quiz_next")
	back_button.text = LanguageManager.get_text("ui.back")
	_update_stats()


func _generate_new_quiz() -> void:
	quiz_answered = false
	result_label.text = ""
	result_label.hide()

	# Get target language
	var target_lang: String = GameState.get_value("settings", "lang_target", "")
	if target_lang.is_empty():
		_show_error("learning.error_no_target_language")
		return

	# Generate quiz
	current_quiz = VocabularyManager.generate_quiz(target_lang)

	if current_quiz.is_empty():
		_show_error("learning.error_no_vocabulary")
		return

	# Display quiz
	word_label.text = current_quiz.word
	context_label.text = current_quiz.get("context", "")

	# Set option buttons
	for i in range(option_buttons.size()):
		if i < current_quiz.options.size():
			option_buttons[i].text = current_quiz.options[i]
			option_buttons[i].disabled = false
			option_buttons[i].show()
		else:
			option_buttons[i].hide()

	next_button.disabled = true


func _on_option_pressed(index: int) -> void:
	if quiz_answered:
		return

	quiz_answered = true

	# Submit answer
	var correct := VocabularyManager.submit_quiz_answer(index)

	# Disable all buttons
	for button in option_buttons:
		button.disabled = true

	# Show result
	if correct:
		result_label.text = LanguageManager.get_text("learning.quiz_correct")
		result_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		var correct_answer := current_quiz.options[current_quiz.correct_index]
		result_label.text = LanguageManager.get_text("learning.quiz_incorrect") % correct_answer
		result_label.add_theme_color_override("font_color", Color.RED)

	result_label.show()
	next_button.disabled = false

	_update_stats()


func _on_quiz_completed(correct: bool, word_data: Dictionary) -> void:
	# Additional feedback could be added here
	pass


func _on_next_pressed() -> void:
	_generate_new_quiz()


func _on_back_pressed() -> void:
	# Return to settings or main menu
	GameState.set_value("nav", "screen", "settings")
	get_tree().change_scene_to_file("res://scenes/ui/Settings.tscn")


func _update_stats() -> void:
	var total: int = GameState.get_value("learning", "quiz_total", 0)
	var correct: int = GameState.get_value("learning", "quiz_correct", 0)
	var rate: float = GameState.get_value("learning", "quiz_correct_rate", 0.0)
	var level_display := VocabularyManager.get_display_level()

	stats_label.text = "%s: %s | %s: %d/%d (%.1f%%)" % [
		LanguageManager.get_text("learning.current_level"),
		level_display,
		LanguageManager.get_text("learning.quiz_stats"),
		correct,
		total,
		rate * 100.0
	]


func _show_error(error_key: String) -> void:
	result_label.text = LanguageManager.get_text(error_key)
	result_label.add_theme_color_override("font_color", Color.ORANGE)
	result_label.show()

	for button in option_buttons:
		button.disabled = true

	next_button.disabled = true
