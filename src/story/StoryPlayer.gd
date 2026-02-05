extends Control
## StoryPlayer - Main story playback with dialogue box and perspective switching

@onready var background := $Background
@onready var background_color := $BackgroundColor
@onready var character_sprites := $CharacterSprites
@onready var dialogue_box := $DialogueBox
@onready var speaker_name := $DialogueBox/MarginContainer/VBoxContainer/SpeakerName
@onready var dialogue_text := $DialogueBox/MarginContainer/VBoxContainer/DialogueText
@onready var auto_button := $ControlButtons/AutoButton
@onready var skip_button := $ControlButtons/SkipButton
@onready var backlog_button := $ControlButtons/BacklogButton
@onready var menu_button := $ControlButtons/MenuButton
@onready var emperor_button := $PerspectiveButtons/EmperorButton
@onready var consort_button := $PerspectiveButtons/ConsortButton
@ontml:parameter name="minister_button := $PerspectiveButtons/MinisterButton
@onready var chapter_label := $ChapterLabel

var current_node_id := ""
var current_chapter := 1
var current_pov := "emperor"
var auto_playing := false
var auto_timer := 0.0
var backlog := []
var story_data := {}


func _ready() -> void:
	_load_story_state()
	_update_ui_text()
	_update_perspective_buttons()
	_load_current_node()

	# Connect signals
	if LanguageManager:
		LanguageManager.language_changed.connect(_on_language_changed)


func _process(delta: float) -> void:
	# Update playtime
	if GameState:
		GameState.update_playtime(delta)

	# Auto-play timer
	if auto_playing:
		auto_timer += delta
		var auto_speed := GameState.get_value("ui", "auto_speed", 1.0)
		if auto_timer >= auto_speed:
			auto_timer = 0.0
			_advance_dialogue()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("game_advance"):
		_advance_dialogue()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("game_auto"):
		_toggle_auto()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("game_skip"):
		_toggle_skip()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("game_backlog"):
		_open_backlog()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("game_menu"):
		_open_menu()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("game_perspective_switch"):
		_cycle_perspective()
		get_viewport().set_input_as_handled()


func _load_story_state() -> void:
	if not GameState:
		return

	current_chapter = GameState.get_value("main", "chapter", 1)
	current_node_id = GameState.get_value("main", "node_id", "CH1_START")
	current_pov = GameState.get_value("main", "pov_current", "emperor")

	# Load story data for current chapter
	_load_chapter_data(current_chapter)


func _load_chapter_data(chapter: int) -> void:
	# Load chapter story data from content directory
	var chapter_path := "res://content/main/chapter_%d.json" % chapter

	if not FileAccess.file_exists(chapter_path):
		push_warning("[StoryPlayer] Chapter data not found: %s" % chapter_path)
		# Use placeholder data
		story_data = _get_placeholder_story_data(chapter)
		return

	var file := FileAccess.open(chapter_path, FileAccess.READ)
	if not file:
		push_error("[StoryPlayer] Failed to open chapter data")
		story_data = _get_placeholder_story_data(chapter)
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("[StoryPlayer] Failed to parse chapter data")
		story_data = _get_placeholder_story_data(chapter)
		return

	story_data = json.data
	file.close()


func _get_placeholder_story_data(chapter: int) -> Dictionary:
	# Placeholder story data for testing
	return {
		"chapter": chapter,
		"title": "Chapter %d: Placeholder" % chapter,
		"nodes": {
			"CH%d_START" % chapter: {
				"id": "CH%d_START" % chapter,
				"type": "dialogue",
				"speaker": "narrator",
				"text": {
					"english": "This is placeholder text for Chapter %d. The actual story content will be loaded from the content files." % chapter,
					"schinese": "这是第%d章的占位文本。实际故事内容将从内容文件加载。" % chapter
				},
				"next": "CH%d_002" % chapter,
				"pov": "emperor"
			},
			"CH%d_002" % chapter: {
				"id": "CH%d_002" % chapter,
				"type": "dialogue",
				"speaker": "emperor",
				"text": {
					"english": "The Emperor speaks. This is a test of the dialogue system with perspective switching.",
					"schinese": "万历皇帝说话。这是对话系统和视角切换的测试。"
				},
				"next": "CH%d_003" % chapter,
				"pov": "emperor"
			},
			"CH%d_003" % chapter: {
				"id": "CH%d_003" % chapter,
				"type": "dialogue",
				"speaker": "consort",
				"text": {
					"english": "The Consort speaks. Switch perspectives to see different viewpoints.",
					"schinese": "郑贵妃说话。切换视角以查看不同观点。"
				},
				"next": "CH%d_004" % chapter,
				"pov": "consort"
			},
			"CH%d_004" % chapter: {
				"id": "CH%d_004" % chapter,
				"type": "dialogue",
				"speaker": "minister",
				"text": {
					"english": "The Minister speaks. Each perspective reveals different evidence.",
					"schinese": "申时行说话。每个视角揭示不同的证据。"
				},
				"next": "CH%d_END" % chapter,
				"pov": "minister"
			},
			"CH%d_END" % chapter: {
				"id": "CH%d_END" % chapter,
				"type": "chapter_end",
				"text": {
					"english": "End of Chapter %d (Placeholder)" % chapter,
					"schinese": "第%d章结束（占位）" % chapter
				}
			}
		}
	}


func _load_current_node() -> void:
	if current_node_id == "":
		current_node_id = "CH%d_START" % current_chapter

	var node_data := _get_node_data(current_node_id)

	if node_data.is_empty():
		push_error("[StoryPlayer] Node not found: %s" % current_node_id)
		return

	# Check if node is available for current POV
	var node_pov := node_data.get("pov", "all")
	if node_pov != "all" and node_pov != current_pov:
		# Node not available in current perspective
		_show_pov_locked_message(node_pov)
		return

	# Display node content
	_display_node(node_data)

	# Mark as seen
	if GameState:
		var seen_nodes: Array = GameState.get_value("main", "seen_nodes", [])
		if current_node_id not in seen_nodes:
			seen_nodes.append(current_node_id)
			GameState.set_value("main", "seen_nodes", seen_nodes)

	# Add to backlog
	_add_to_backlog(node_data)


func _get_node_data(node_id: String) -> Dictionary:
	if not story_data.has("nodes"):
		return {}

	return story_data.nodes.get(node_id, {})


func _display_node(node_data: Dictionary) -> void:
	var node_type := node_data.get("type", "dialogue")

	match node_type:
		"dialogue":
			_display_dialogue(node_data)
		"choice":
			_display_choice(node_data)
		"chapter_end":
			_display_chapter_end(node_data)
		_:
			push_warning("[StoryPlayer] Unknown node type: %s" % node_type)


func _display_dialogue(node_data: Dictionary) -> void:
	# Get speaker name
	var speaker := node_data.get("speaker", "")
	speaker_name.text = _get_speaker_name(speaker)

	# Get dialogue text in current language
	var text_data := node_data.get("text", {})
	var lang := LanguageManager.current_language if LanguageManager else "english"
	var text := text_data.get(lang, text_data.get("english", "[Missing text]"))

	dialogue_text.text = text

	# Update chapter label
	chapter_label.text = "Chapter %d" % current_chapter


func _get_speaker_name(speaker_id: String) -> String:
	match speaker_id:
		"narrator":
			return ""
		"emperor":
			return LanguageManager.tr("ui.perspective.emperor") if LanguageManager else "Emperor"
		"consort":
			return LanguageManager.tr("ui.perspective.consort") if LanguageManager else "Consort"
		"minister":
			return LanguageManager.tr("ui.perspective.minister") if LanguageManager else "Minister"
		_:
			return speaker_id.capitalize()


func _display_choice(node_data: Dictionary) -> void:
	# TODO: Implement choice display
	push_warning("[StoryPlayer] Choice nodes not yet implemented")


func _display_chapter_end(node_data: Dictionary) -> void:
	var text_data := node_data.get("text", {})
	var lang := LanguageManager.current_language if LanguageManager else "english"
	var text := text_data.get(lang, "Chapter End")

	speaker_name.text = ""
	dialogue_text.text = "[center]%s[/center]" % text


func _advance_dialogue() -> void:
	var node_data := _get_node_data(current_node_id)

	if node_data.is_empty():
		return

	var next_node := node_data.get("next", "")

	if next_node == "":
		# End of content
		push_warning("[StoryPlayer] No next node")
		return

	# Update current node
	current_node_id = next_node
	GameState.set_value("main", "node_id", current_node_id)

	# Load next node
	_load_current_node()

	# Auto-save periodically
	if GameState.get_value("main", "seen_nodes", []).size() % 10 == 0:
		if SaveManager:
			SaveManager.auto_save()


func _add_to_backlog(node_data: Dictionary) -> void:
	var capacity := GameState.get_value("ui", "backlog_capacity", 100)

	backlog.append({
		"node_id": current_node_id,
		"speaker": node_data.get("speaker", ""),
		"text": node_data.get("text", {}),
		"timestamp": Time.get_ticks_msec()
	})

	# Trim backlog if too large
	while backlog.size() > capacity:
		backlog.pop_front()


func _show_pov_locked_message(required_pov: String) -> void:
	speaker_name.text = "System"
	dialogue_text.text = "This content is only available from the %s perspective. Please switch perspectives to continue." % required_pov.capitalize()


func _update_ui_text() -> void:
	if not LanguageManager:
		return

	auto_button.text = LanguageManager.tr("ui.story.auto")
	skip_button.text = LanguageManager.tr("ui.story.skip")
	backlog_button.text = LanguageManager.tr("ui.story.backlog")
	menu_button.text = LanguageManager.tr("ui.story.menu")

	emperor_button.text = LanguageManager.tr("ui.perspective.emperor")
	consort_button.text = LanguageManager.tr("ui.perspective.consort")
	minister_button.text = LanguageManager.tr("ui.perspective.minister")


func _update_perspective_buttons() -> void:
	# Highlight current perspective
	emperor_button.disabled = (current_pov == "emperor")
	consort_button.disabled = (current_pov == "consort")
	minister_button.disabled = (current_pov == "minister")

	# Update POV visited flags
	if GameState:
		var pov_visited := GameState.get_value("main", "pov_visited", {})
		pov_visited[current_pov] = true
		GameState.set_value("main", "pov_visited", pov_visited)


func _switch_perspective(new_pov: String) -> void:
	if new_pov == current_pov:
		return

	print("[StoryPlayer] Switching perspective: %s -> %s" % [current_pov, new_pov])

	current_pov = new_pov
	GameState.set_value("main", "pov_current", new_pov)

	_update_perspective_buttons()
	_load_current_node()


func _cycle_perspective() -> void:
	match current_pov:
		"emperor":
			_switch_perspective("consort")
		"consort":
			_switch_perspective("minister")
		"minister":
			_switch_perspective("emperor")


func _toggle_auto() -> void:
	auto_playing = not auto_playing
	auto_timer = 0.0

	GameState.set_value("ui", "auto_enabled", auto_playing)

	auto_button.text = "Auto [ON]" if auto_playing else "Auto"
	print("[StoryPlayer] Auto-play: %s" % auto_playing)


func _toggle_skip() -> void:
	var skip_enabled := GameState.get_value("ui", "skip_enabled", false)
	skip_enabled = not skip_enabled
	GameState.set_value("ui", "skip_enabled", skip_enabled)

	skip_button.text = "Skip [ON]" if skip_enabled else "Skip"
	print("[StoryPlayer] Skip: %s" % skip_enabled)


func _open_backlog() -> void:
	print("[StoryPlayer] Opening backlog")
	# TODO: Implement backlog UI


func _open_menu() -> void:
	print("[StoryPlayer] Opening menu")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_language_changed(_lang_code: String) -> void:
	_update_ui_text()
	_load_current_node()  # Reload to show new language


func _on_auto_pressed() -> void:
	_toggle_auto()


func _on_skip_pressed() -> void:
	_toggle_skip()


func _on_backlog_pressed() -> void:
	_open_backlog()


func _on_menu_pressed() -> void:
	_open_menu()


func _on_emperor_pressed() -> void:
	_switch_perspective("emperor")


func _on_consort_pressed() -> void:
	_switch_perspective("consort")


func _on_minister_pressed() -> void:
	_switch_perspective("minister")
