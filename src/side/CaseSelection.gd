extends Control
## CaseSelection - Select turtle soup cases to play

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var case_list: ItemList = $Panel/MarginContainer/VBoxContainer/CaseList
@onready var description_text: RichTextLabel = $Panel/MarginContainer/VBoxContainer/DescriptionPanel/DescriptionText
@onready var play_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonPanel/PlayButton
@onready var back_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonPanel/BackButton

var cases: Array = []
var selected_case_index: int = -1


func _ready() -> void:
	_connect_signals()
	_load_cases()
	_load_translations()
	_refresh_case_list()


func _connect_signals() -> void:
	case_list.item_selected.connect(_on_case_selected)
	play_button.pressed.connect(_on_play_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _load_cases() -> void:
	# Load all case files
	for i in range(1, 4):  # 3 cases
		var case_path := "res://content/side/case_%d.json" % i
		if not FileAccess.file_exists(case_path):
			continue

		var file := FileAccess.open(case_path, FileAccess.READ)
		if file == null:
			continue

		var json_text := file.get_as_text()
		file.close()

		var json := JSON.new()
		if json.parse(json_text) == OK:
			cases.append(json.data)


func _load_translations() -> void:
	title_label.text = LanguageManager.get_text("side.case_selection_title")
	play_button.text = LanguageManager.get_text("side.play_case")
	back_button.text = LanguageManager.get_text("ui.back")


func _refresh_case_list() -> void:
	case_list.clear()

	var lang := GameState.get_value("settings", "lang_primary", "english")

	for case_data in cases:
		var title: String = case_data.title.get(lang, case_data.title.english)
		var difficulty: String = case_data.difficulty
		var difficulty_text := LanguageManager.get_text("side.difficulty." + difficulty)

		var display := "%s [%s]" % [title, difficulty_text]
		case_list.add_item(display)


func _on_case_selected(index: int) -> void:
	if index < 0 or index >= cases.size():
		return

	selected_case_index = index
	var case_data: Dictionary = cases[index]

	var lang := GameState.get_value("settings", "lang_primary", "english")
	var scenario: String = case_data.scenario.get(lang, case_data.scenario.english)

	description_text.clear()
	description_text.append_text(scenario)

	play_button.disabled = false


func _on_play_pressed() -> void:
	if selected_case_index < 0 or selected_case_index >= cases.size():
		return

	var case_data: Dictionary = cases[selected_case_index]

	# Initialize case in GameState
	GameState.set_value("side", "case_id", case_data.case_id)
	GameState.set_value("side", "state", "playing")
	GameState.set_value("side", "turn", 0)
	GameState.set_value("side", "asked_questions", [])
	GameState.set_value("side", "hints_used", 0)
	GameState.set_value("side", "result", "")
	GameState.set_value("side", "replay", {"events": [], "share_code": ""})

	# Load turtle soup scene
	get_tree().change_scene_to_file("res://scenes/side/TurtleSoup.tscn")


func _on_back_pressed() -> void:
	GameState.set_value("nav", "screen", "home")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
