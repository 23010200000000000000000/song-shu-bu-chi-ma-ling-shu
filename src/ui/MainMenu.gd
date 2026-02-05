extends Control
## MainMenu - Main menu scene with language-aware UI

@onready var title_label := $VBoxContainer/Title
@onready var subtitle_label := $VBoxContainer/Subtitle
@onready var new_game_button := $VBoxContainer/NewGameButton
@onready var continue_button := $VBoxContainer/ContinueButton
@onready var side_stories_button := $VBoxContainer/SideStoriesButton
@onready var settings_button := $VBoxContainer/SettingsButton
@onready var quit_button := $VBoxContainer/QuitButton
@onready var version_label := $VersionLabel


func _ready() -> void:
	_update_ui_text()
	_check_continue_available()

	# Connect to language change signal
	if LanguageManager:
		LanguageManager.language_changed.connect(_on_language_changed)

	# Update version label
	version_label.text = "v%s %s" % [GameState.BUILD_VERSION, GameState.BUILD_FLAVOR.capitalize()]

	# Check Steam status
	if SteamManager and SteamManager.is_steam_available():
		print("[MainMenu] Steam available")
	else:
		print("[MainMenu] Running in offline mode")


func _update_ui_text() -> void:
	if not LanguageManager:
		return

	# Update all UI text from translations
	title_label.text = LanguageManager.tr("ui.menu.title")
	new_game_button.text = LanguageManager.tr("ui.menu.start_game")
	continue_button.text = LanguageManager.tr("ui.menu.continue")
	side_stories_button.text = LanguageManager.tr("ui.menu.side_stories")
	settings_button.text = LanguageManager.tr("ui.menu.settings")
	quit_button.text = LanguageManager.tr("ui.menu.quit")


func _check_continue_available() -> void:
	# Check if there are any saves
	if SaveManager:
		var saves := SaveManager.get_save_list()
		continue_button.disabled = saves.is_empty()


func _on_language_changed(_lang_code: String) -> void:
	_update_ui_text()


func _on_new_game_pressed() -> void:
	print("[MainMenu] New game started")

	# Reset game state
	GameState.reset_state()

	# Set initial values
	GameState.set_value("nav", "screen", "main")
	GameState.set_value("main", "chapter", 1)
	GameState.set_value("main", "node_id", "CH1_START")
	GameState.set_value("main", "pov_current", "emperor")

	# Auto-save at start
	if SaveManager:
		SaveManager.auto_save()

	# Load story scene
	_load_story_scene()


func _on_continue_pressed() -> void:
	print("[MainMenu] Continue game")

	# Load most recent save
	if SaveManager:
		var saves := SaveManager.get_save_list()
		if not saves.is_empty():
			var most_recent := saves[0]
			if SaveManager.load_game(most_recent.slot):
				_load_story_scene()
			else:
				_show_error("ui.error.load_failed")


func _on_side_stories_pressed() -> void:
	print("[MainMenu] Side stories selected")

	GameState.set_value("nav", "screen", "side")

	# Load case selection scene
	get_tree().change_scene_to_file("res://scenes/side/CaseSelection.tscn")


func _on_settings_pressed() -> void:
	print("[MainMenu] Settings opened")

	# Load settings scene
	get_tree().change_scene_to_file("res://scenes/ui/Settings.tscn")


func _on_quit_pressed() -> void:
	print("[MainMenu] Quit game")
	get_tree().quit()


func _load_story_scene() -> void:
	# Load the story player scene
	get_tree().change_scene_to_file("res://scenes/story/StoryPlayer.tscn")


func _show_error(error_key: String) -> void:
	# Show error dialog
	var error_text := LanguageManager.tr(error_key) if LanguageManager else error_key
	push_error("[MainMenu] Error: %s" % error_text)

	# TODO: Show proper error dialog UI
	print("ERROR: %s" % error_text)
