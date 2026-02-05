extends Control
## ArchiveSealing - Archive and seal investigation conclusions
## Part of the investigation gameplay loop (Read/Compare/Interrogate/Archive)

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var instruction_label: Label = $Panel/MarginContainer/VBoxContainer/InstructionLabel
@onready var evidence_list: ItemList = $Panel/MarginContainer/VBoxContainer/HSplitContainer/LeftPanel/EvidenceList
@onready var conclusion_text: TextEdit = $Panel/MarginContainer/VBoxContainer/HSplitContainer/RightPanel/ConclusionText
@onready var seal_type_option: OptionButton = $Panel/MarginContainer/VBoxContainer/HSplitContainer/RightPanel/SealTypeOption
@onready var seal_button: Button = $Panel/MarginContainer/VBoxContainer/HSplitContainer/RightPanel/SealButton
@onready var back_button: Button = $Panel/MarginContainer/VBoxContainer/BackButton
@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel

## Seal types available
const SEAL_TYPES := [
	"routine",      # 例行归档 - Routine filing
	"confidential", # 机密封存 - Confidential sealing
	"imperial",     # 御览呈报 - Imperial review
	"suppress"      # 压制不报 - Suppress/conceal
]

var current_chapter: int = 1
var collected_evidence: Array = []


func _ready() -> void:
	_connect_signals()
	_populate_seal_types()
	_load_translations()
	_refresh_evidence_list()

	# Load current chapter from GameState
	current_chapter = GameState.get_value("main", "chapter", 1)


func _connect_signals() -> void:
	seal_button.pressed.connect(_on_seal_pressed)
	back_button.pressed.connect(_on_back_pressed)
	evidence_list.item_selected.connect(_on_evidence_selected)


func _populate_seal_types() -> void:
	seal_type_option.clear()
	for seal_type in SEAL_TYPES:
		var display_name := LanguageManager.get_text("investigation.seal_type." + seal_type)
		seal_type_option.add_item(display_name)


func _load_translations() -> void:
	title_label.text = LanguageManager.get_text("investigation.archive.title")
	instruction_label.text = LanguageManager.get_text("investigation.archive.instruction")
	seal_button.text = LanguageManager.get_text("investigation.archive.seal_button")
	back_button.text = LanguageManager.get_text("ui.back")
	conclusion_text.placeholder_text = LanguageManager.get_text("investigation.archive.conclusion_placeholder")


func _refresh_evidence_list() -> void:
	evidence_list.clear()

	# Get evidence from GameState
	var compare_history: Array = GameState.get_value("evidence", "compare_history", [])
	var interrogate_log: Array = GameState.get_value("evidence", "interrogate_log", [])
	var contradictions: Array = GameState.get_value("evidence", "contradictions_found", [])

	collected_evidence.clear()

	# Add comparisons
	for comparison in compare_history:
		var entry := {
			"type": "comparison",
			"data": comparison
		}
		collected_evidence.append(entry)
		var display := "[%s] %s vs %s" % [
			LanguageManager.get_text("investigation.evidence_type.comparison"),
			comparison.get("doc_a_id", "?"),
			comparison.get("doc_b_id", "?")
		]
		evidence_list.add_item(display)

	# Add interrogations
	for interrogation in interrogate_log:
		var entry := {
			"type": "interrogation",
			"data": interrogation
		}
		collected_evidence.append(entry)
		var display := "[%s] %s" % [
			LanguageManager.get_text("investigation.evidence_type.interrogation"),
			interrogation.get("character_id", "?")
		]
		evidence_list.add_item(display)


	# Add contradictions
	for contradiction_id in contradictions:
		var entry := {
			"type": "contradiction",
			"data": {"id": contradiction_id}
		}
		collected_evidence.append(entry)
		var display := "[%s] %s" % [
			LanguageManager.get_text("investigation.evidence_type.contradiction"),
			contradiction_id
		]
		evidence_list.add_item(display)

	status_label.text = LanguageManager.get_text("investigation.archive.evidence_count") % collected_evidence.size()


func _on_evidence_selected(index: int) -> void:
	if index < 0 or index >= collected_evidence.size():
		return

	var entry: Dictionary = collected_evidence[index]
	var details := ""

	match entry.type:
		"comparison":
			var data: Dictionary = entry.data
			details = "%s:\n%s\n\n%s:\n%s" % [
				data.get("doc_a_id", "?"),
				data.get("doc_a_excerpt", ""),
				data.get("doc_b_id", "?"),
				data.get("doc_b_excerpt", "")
			]
		"interrogation":
			var data: Dictionary = entry.data
			details = "%s: %s\n\n%s: %s" % [
				LanguageManager.get_text("investigation.interrogation.question"),
				data.get("question_text", ""),
				LanguageManager.get_text("investigation.interrogation.response"),
				data.get("response_text", "")
			]
		"contradiction":
			var data: Dictionary = entry.data
			details = "%s: %s" % [
				LanguageManager.get_text("investigation.evidence_type.contradiction"),
				data.get("id", "?")
			]

	# Show details in conclusion text (read-only preview)
	conclusion_text.text = details
	conclusion_text.editable = false


func _on_seal_pressed() -> void:
	var conclusion := conclusion_text.text.strip_edges()

	if conclusion.is_empty():
		status_label.text = LanguageManager.get_text("investigation.archive.error_no_conclusion")
		return

	var seal_index := seal_type_option.selected
	if seal_index < 0 or seal_index >= SEAL_TYPES.size():
		status_label.text = LanguageManager.get_text("investigation.archive.error_no_seal_type")
		return

	var seal_type := SEAL_TYPES[seal_index]

	# Create archive entry
	var archive_entry := {
		"chapter": current_chapter,
		"timestamp": Time.get_datetime_string_from_system(),
		"conclusion": conclusion,
		"seal_type": seal_type,
		"evidence_count": collected_evidence.size(),
		"evidence_snapshot": collected_evidence.duplicate(true)
	}

	# Save to GameState
	var entries: Array = GameState.get_value("archive", "entries", [])
	entries.append(archive_entry)
	GameState.set_value("archive", "entries", entries)

	# Update seal counts
	var seal_counts: Dictionary = GameState.get_value("archive", "seal_counts", {})
	seal_counts[seal_type] = seal_counts.get(seal_type, 0) + 1
	GameState.set_value("archive", "seal_counts", seal_counts)

	# Mark archive confirmation flag
	GameState.set_value("main", "flags", {
		"visited_all_pov_in_chapter": GameState.get_value("main", "flags", {}).get("visited_all_pov_in_chapter", false),
		"did_key_compare": GameState.get_value("main", "flags", {}).get("did_key_compare", false),
		"did_key_interrogate": GameState.get_value("main", "flags", {}).get("did_key_interrogate", false),
		"did_archive_confirm": true
	})

	# Apply stance changes based on seal type
	_apply_seal_stance_effects(seal_type)

	status_label.text = LanguageManager.get_text("investigation.archive.sealed_success")

	# Auto-save after sealing
	GameState.save_requested.emit()

	# Return to story after brief delay
	await get_tree().create_timer(2.0).timeout
	_on_back_pressed()


func _apply_seal_stance_effects(seal_type: String) -> void:
	# Different seal types affect stance differently
	match seal_type:
		"routine":
			# Neutral - no major stance changes
			pass
		"confidential":
			# Slightly favor suppressing truth
			var current_truth: int = GameState.get_value("stance", "axis_truth", 0)
			GameState.set_value("stance", "axis_truth", current_truth - 5)
		"imperial":
			# Favor allowing truth to reach emperor
			var current_truth: int = GameState.get_value("stance", "axis_truth", 0)
			GameState.set_value("stance", "axis_truth", current_truth + 10)
		"suppress":
			# Strongly suppress truth
			var current_truth: int = GameState.get_value("stance", "axis_truth", 0)
			GameState.set_value("stance", "axis_truth", current_truth - 15)


func _on_back_pressed() -> void:
	# Return to story
	GameState.set_value("nav", "screen", "main")
	get_tree().change_scene_to_file("res://scenes/story/StoryPlayer.tscn")

