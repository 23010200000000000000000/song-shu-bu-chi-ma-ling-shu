extends Control
## EvidenceComparison - Side-by-side document comparison with diff highlighting

@onready var title_label := $Title
@onready var left_title := $SplitContainer/LeftPanel/MarginContainer/VBoxContainer/LeftTitle
@onready var left_source := $SplitContainer/LeftPanel/MarginContainer/VBoxContainer/LeftSource
@onready var left_scroll := $SplitContainer/LeftPanel/MarginContainer/VBoxContainer/LeftScroll
@onready var left_text := $SplitContainer/LeftPanel/MarginContainer/VBoxContainer/LeftScroll/LeftText
@onready var right_title := $SplitContainer/RightPanel/MarginContainer/VBoxContainer/RightTitle
@onready var right_source := $SplitContainer/RightPanel/MarginContainer/VBoxContainer/RightSource
@onready var right_scroll := $SplitContainer/RightPanel/MarginContainer/VBoxContainer/RightScroll
@onready var right_text := $SplitContainer/RightPanel/MarginContainer/VBoxContainer/RightScroll/RightText
@onready var highlight_button := $ControlPanel/HBoxContainer/HighlightButton
@onready var sync_scroll_button := $ControlPanel/HBoxContainer/SyncScrollButton
@onready var mark_contradiction_button := $ControlPanel/HBoxContainer/MarkContradictionButton
@onready var back_button := $ControlPanel/HBoxContainer/BackButton

var left_document := {}
var right_document := {}
var sync_scrolling := true
var differences_highlighted := false
var contradictions_found := []


func _ready() -> void:
	_update_ui_text()
	_load_comparison_data()

	# Connect scroll signals
	left_scroll.get_v_scroll_bar().value_changed.connect(_on_left_scroll_changed)
	right_scroll.get_v_scroll_bar().value_changed.connect(_on_right_scroll_changed)

	if LanguageManager:
		LanguageManager.language_changed.connect(_on_language_changed)


func _update_ui_text() -> void:
	if not LanguageManager:
		return

	title_label.text = LanguageManager.tr("ui.investigation.compare")
	highlight_button.text = "Highlight Differences"
	sync_scroll_button.text = "Sync Scroll"
	mark_contradiction_button.text = LanguageManager.tr("ui.investigation.mark_contradiction")
	back_button.text = LanguageManager.tr("ui.confirm.cancel")


func _load_comparison_data() -> void:
	"""Load documents to compare from GameState"""
	if not GameState:
		_load_placeholder_data()
		return

	# Get documents from evidence system
	var compare_history: Array = GameState.get_value("evidence", "compare_history", [])

	if compare_history.is_empty():
		_load_placeholder_data()
		return

	# Load most recent comparison
	var comparison := compare_history[-1]
	left_document = comparison.get("left", {})
	right_document = comparison.get("right", {})

	_display_documents()


func _load_placeholder_data() -> void:
	"""Load placeholder comparison data"""
	left_document = {
		"id": "DOC_001",
		"title": "Imperial Edict",
		"source": "Emperor's Archive",
		"pov": "emperor",
		"text": {
			"english": "On the 15th day of the 3rd month, the Emperor issued a decree regarding the appointment of officials. The Minister was instructed to review all candidates carefully. Three officials were recommended for promotion.",
			"schinese": "三月十五日，皇帝颁布关于官员任命的诏书。命申时行仔细审查所有候选人。推荐三名官员晋升。"
		},
		"date": "1586-03-15",
		"keywords": ["appointment", "officials", "three"]
	}

	right_document = {
		"id": "DOC_002",
		"title": "Minister's Report",
		"source": "Minister's Archive",
		"pov": "minister",
		"text": {
			"english": "On the 16th day of the 3rd month, I received the Emperor's decree. After careful review, I found four qualified candidates for promotion. The list was submitted to the palace on the same day.",
			"schinese": "三月十六日，我收到皇帝的诏书。经过仔细审查，我发现四名合格的晋升候选人。名单于当日提交宫中。"
		},
		"date": "1586-03-16",
		"keywords": ["decree", "four", "candidates"]
	}

	_display_documents()


func _display_documents() -> void:
	"""Display the documents in the comparison view"""
	var lang := LanguageManager.current_language if LanguageManager else "english"

	# Left document
	left_title.text = left_document.get("title", "Document A")
	left_source.text = "Source: %s" % left_document.get("source", "Unknown")

	var left_text_data := left_document.get("text", {})
	var left_content := left_text_data.get(lang, left_text_data.get("english", "No content"))
	left_text.text = left_content

	# Right document
	right_title.text = right_document.get("title", "Document B")
	right_source.text = "Source: %s" % right_document.get("source", "Unknown")

	var right_text_data := right_document.get("text", {})
	var right_content := right_text_data.get(lang, right_text_data.get("english", "No content"))
	right_text.text = right_content


func _on_left_scroll_changed(value: float) -> void:
	if sync_scrolling and not right_scroll.get_v_scroll_bar().is_dragging():
		right_scroll.scroll_vertical = int(value)


func _on_right_scroll_changed(value: float) -> void:
	if sync_scrolling and not left_scroll.get_v_scroll_bar().is_dragging():
		left_scroll.scroll_vertical = int(value)


func _on_sync_scroll_toggled(enabled: bool) -> void:
	sync_scrolling = enabled
	print("[EvidenceComparison] Sync scrolling: %s" % enabled)


func _on_highlight_pressed() -> void:
	differences_highlighted = not differences_highlighted

	if differences_highlighted:
		_highlight_differences()
		highlight_button.text = "Clear Highlights"
	else:
		_clear_highlights()
		highlight_button.text = "Highlight Differences"


func _highlight_differences() -> void:
	"""Highlight differences between documents"""
	print("[EvidenceComparison] Highlighting differences...")

	# Simple keyword-based highlighting
	var left_keywords := left_document.get("keywords", [])
	var right_keywords := right_document.get("keywords", [])

	# Find unique keywords
	var left_unique := []
	var right_unique := []

	for keyword in left_keywords:
		if keyword not in right_keywords:
			left_unique.append(keyword)

	for keyword in right_keywords:
		if keyword not in left_keywords:
			right_unique.append(keyword)

	# Highlight in left document
	var left_content := left_text.text
	for keyword in left_unique:
		left_content = left_content.replace(keyword, "[bgcolor=#ffcccc]%s[/bgcolor]" % keyword)
	left_text.text = left_content

	# Highlight in right document
	var right_content := right_text.text
	for keyword in right_unique:
		right_content = right_content.replace(keyword, "[bgcolor=#ffcccc]%s[/bgcolor]" % keyword)
	right_text.text = right_content

	print("  Found differences: Left=%d, Right=%d" % [left_unique.size(), right_unique.size()])


func _clear_highlights() -> void:
	"""Clear all highlights"""
	print("[EvidenceComparison] Clearing highlights...")
	_display_documents()


func _on_mark_contradiction_pressed() -> void:
	"""Mark a contradiction found in the comparison"""
	print("[EvidenceComparison] Marking contradiction...")

	# Create contradiction record
	var contradiction := {
		"id": "CONTRA_%03d" % (contradictions_found.size() + 1),
		"left_doc": left_document.get("id", ""),
		"right_doc": right_document.get("id", ""),
		"type": "discrepancy",
		"description": "Discrepancy found between documents",
		"timestamp": Time.get_datetime_string_from_system()
	}

	contradictions_found.append(contradiction)

	# Update GameState
	if GameState:
		var contradictions: Array = GameState.get_value("evidence", "contradictions_found", [])
		if contradiction["id"] not in contradictions:
			contradictions.append(contradiction["id"])
			GameState.set_value("evidence", "contradictions_found", contradictions)

		# Add to compare history
		var compare_history: Array = GameState.get_value("evidence", "compare_history", [])
		compare_history.append({
			"left": left_document,
			"right": right_document,
			"contradictions": contradictions_found,
			"timestamp": Time.get_datetime_string_from_system()
		})
		GameState.set_value("evidence", "compare_history", compare_history)

		# Set flag
		GameState.set_value("main", "flags", {
			"did_key_compare": true
		})

	# Show feedback
	_show_contradiction_marked()


func _show_contradiction_marked() -> void:
	"""Show visual feedback that contradiction was marked"""
	# TODO: Show proper notification UI
	print("[EvidenceComparison] Contradiction marked! Total: %d" % contradictions_found.size())

	# Flash the mark button
	mark_contradiction_button.text = "Marked! (%d)" % contradictions_found.size()
	await get_tree().create_timer(2.0).timeout
	mark_contradiction_button.text = LanguageManager.tr("ui.investigation.mark_contradiction") if LanguageManager else "Mark Contradiction"


func _on_back_pressed() -> void:
	"""Return to story"""
	print("[EvidenceComparison] Returning to story...")

	# Save state
	if SaveManager:
		SaveManager.auto_save()

	# Return to story player
	get_tree().change_scene_to_file("res://scenes/story/StoryPlayer.tscn")


func _on_language_changed(_lang_code: String) -> void:
	_update_ui_text()
	_display_documents()


## Public API for loading specific documents
func load_documents(left_doc: Dictionary, right_doc: Dictionary) -> void:
	"""Load specific documents for comparison"""
	left_document = left_doc
	right_document = right_doc
	_display_documents()


func get_contradictions() -> Array:
	"""Get list of contradictions found"""
	return contradictions_found
