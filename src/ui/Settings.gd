extends Control
## Settings - Game settings UI

@onready var title_label := $Panel/MarginContainer/VBoxContainer/Title
@onready var language_label := $Panel/MarginContainer/VBoxContainer/LanguageLabel
@onready var language_option := $Panel/MarginContainer/VBoxContainer/LanguageOption
@onready var language_mode_label := $Panel/MarginContainer/VBoxContainer/LanguageModeLabel
@onready var language_mode_option := $Panel/MarginContainer/VBoxContainer/LanguageModeOption
@onready var font_size_label := $Panel/MarginContainer/VBoxContainer/FontSizeLabel
@onready var font_size_slider := $Panel/MarginContainer/VBoxContainer/FontSizeSlider
@onready var enable_2_5d_label := $Panel/MarginContainer/VBoxContainer/Enable2_5DLabel
@onready var enable_2_5d_check := $Panel/MarginContainer/VBoxContainer/Enable2_5DCheck
@onready var quiz_button := $Panel/MarginContainer/VBoxContainer/QuizButton
@onready var apply_button := $Panel/MarginContainer/VBoxContainer/ButtonContainer/ApplyButton
@onready var back_button := $Panel/MarginContainer/VBoxContainer/ButtonContainer/BackButton

var pending_changes := false


func _ready() -> void:
	_populate_language_options()
	_populate_language_mode_options()
	_load_current_settings()
	_update_ui_text()

	if LanguageManager:
		LanguageManager.language_changed.connect(_on_language_changed)


func _populate_language_options() -> void:
	language_option.clear()

	if not LanguageManager:
		return

	var modern_languages := LanguageManager.get_modern_languages()

	for lang_code in modern_languages:
		var display_name := LanguageManager.get_display_name(lang_code)
		language_option.add_item(display_name)
		language_option.set_item_metadata(language_option.get_item_count() - 1, lang_code)


func _populate_language_mode_options() -> void:
	language_mode_option.clear()

	language_mode_option.add_item("Single Language")
	language_mode_option.set_item_metadata(0, "monolingual")

	language_mode_option.add_item("Bilingual")
	language_mode_option.set_item_metadata(1, "bilingual")

	language_mode_option.add_item("Immersion Learning")
	language_mode_option.set_item_metadata(2, "immersion_bilingual")


func _load_current_settings() -> void:
	if not GameState:
		return

	# Load language
	var current_lang := GameState.get_value("settings", "lang_primary", "english")
	for i in range(language_option.get_item_count()):
		if language_option.get_item_metadata(i) == current_lang:
			language_option.selected = i
			break

	# Load language mode
	var lang_mode := GameState.get_value("settings", "lang_mode", "monolingual")
	for i in range(language_mode_option.get_item_count()):
		if language_mode_option.get_item_metadata(i) == lang_mode:
			language_mode_option.selected = i
			break

	# Load font size
	var font_size := GameState.get_value("settings", "font_size", 1.0)
	font_size_slider.value = font_size

	# Load 2.5D setting
	var enable_2_5d := GameState.get_value("settings", "enable_2_5d", true)
	enable_2_5d_check.button_pressed = enable_2_5d


func _update_ui_text() -> void:
	if not LanguageManager:
		return

	title_label.text = LanguageManager.tr("ui.settings.language")
	language_label.text = LanguageManager.tr("ui.settings.primary_language")
	language_mode_label.text = LanguageManager.tr("ui.settings.language_mode")
	font_size_label.text = LanguageManager.tr("ui.settings.font_size")
	enable_2_5d_label.text = LanguageManager.tr("ui.settings.enable_2_5d")
	quiz_button.text = LanguageManager.tr("learning.start_quiz")
	apply_button.text = LanguageManager.tr("ui.settings.apply")
	back_button.text = LanguageManager.tr("ui.settings.cancel")


func _on_language_selected(index: int) -> void:
	pending_changes = true
	var lang_code := language_option.get_item_metadata(index)
	print("[Settings] Language selected: %s" % lang_code)


func _on_language_mode_selected(index: int) -> void:
	pending_changes = true
	var mode := language_mode_option.get_item_metadata(index)
	print("[Settings] Language mode selected: %s" % mode)


func _on_font_size_changed(value: float) -> void:
	pending_changes = true
	print("[Settings] Font size: %.1f" % value)


func _on_2_5d_toggled(enabled: bool) -> void:
	pending_changes = true
	print("[Settings] 2.5D enabled: %s" % enabled)


func _on_apply_pressed() -> void:
	_apply_settings()
	_go_back()


func _on_back_pressed() -> void:
	if pending_changes:
		# TODO: Show confirmation dialog
		print("[Settings] Discarding changes")

	_go_back()


func _apply_settings() -> void:
	if not GameState:
		return

	# Apply language
	var lang_index := language_option.selected
	if lang_index >= 0:
		var lang_code := language_option.get_item_metadata(lang_index)
		GameState.set_value("settings", "lang_primary", lang_code)

		if LanguageManager:
			LanguageManager.set_language(lang_code)

	# Apply language mode
	var mode_index := language_mode_option.selected
	if mode_index >= 0:
		var mode := language_mode_option.get_item_metadata(mode_index)
		GameState.set_value("settings", "lang_mode", mode)

	# Apply font size
	GameState.set_value("settings", "font_size", font_size_slider.value)

	# Apply 2.5D setting
	GameState.set_value("settings", "enable_2_5d", enable_2_5d_check.button_pressed)

	# Save settings
	if SaveManager:
		SaveManager.auto_save()

	pending_changes = false
	print("[Settings] Settings applied")


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_language_changed(_lang_code: String) -> void:
	_update_ui_text()


func _on_quiz_pressed() -> void:
	# Check if target language is set
	var lang_mode := GameState.get_value("settings", "lang_mode", "monolingual")
	if lang_mode == "monolingual":
		print("[Settings] Quiz requires bilingual or immersion mode")
		# TODO: Show error dialog
		return

	var target_lang := GameState.get_value("settings", "lang_target", "")
	if target_lang.is_empty():
		print("[Settings] No target language set")
		# TODO: Show error dialog
		return

	# Load quiz scene
	get_tree().change_scene_to_file("res://scenes/learning/VocabularyQuiz.tscn")

