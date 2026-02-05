extends Node
## SaveManager - Handles save/load operations with Steam Cloud support
## Manages 100 manual slots + 10 auto-save slots

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal save_list_updated()

const SAVE_DIR := "user://saves/"
const SETTINGS_DIR := "user://settings/"
const MAX_MANUAL_SLOTS := 100
const MAX_AUTO_SLOTS := 10
const SAVE_EXTENSION := ".json"

var save_slots := {}  # Cache of save metadata
var current_slot := -1  # Currently loaded slot (-1 = none)


func _ready() -> void:
	_ensure_directories()
	_scan_save_slots()
	print("[SaveManager] Initialized with %d saves found" % save_slots.size())


## Ensure save directories exist
func _ensure_directories() -> void:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	if not dir.dir_exists("settings"):
		dir.make_dir("settings")
	if not dir.dir_exists("logs"):
		dir.make_dir("logs")


## Scan all save slots and build metadata cache
func _scan_save_slots() -> void:
	save_slots.clear()

	var dir := DirAccess.open(SAVE_DIR)
	if not dir:
		push_warning("[SaveManager] Could not open save directory")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(SAVE_EXTENSION):
			var slot_num := _extract_slot_number(file_name)
			if slot_num >= 0:
				var metadata := _load_save_metadata(slot_num)
				if metadata:
					save_slots[slot_num] = metadata

		file_name = dir.get_next()

	dir.list_dir_end()
	save_list_updated.emit()


## Extract slot number from filename
func _extract_slot_number(filename: String) -> int:
	# Format: save_001.json or auto_001.json
	var parts := filename.replace(SAVE_EXTENSION, "").split("_")
	if parts.size() >= 2:
		return parts[1].to_int()
	return -1


## Get save file path for slot
func _get_save_path(slot: int, is_auto: bool = false) -> String:
	var prefix := "auto" if is_auto else "save"
	return SAVE_DIR + "%s_%03d%s" % [prefix, slot, SAVE_EXTENSION]


## Load save metadata without loading full state
func _load_save_metadata(slot: int) -> Dictionary:
	var is_auto := slot >= 1000  # Auto-saves use slots 1000-1009
	var path := _get_save_path(slot if not is_auto else slot - 1000, is_auto)

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[SaveManager] Failed to parse save file: %s" % path)
		return {}

	var data := json.data as Dictionary

	# Extract metadata
	return {
		"slot": slot,
		"is_auto": is_auto,
		"created_at": data.get("meta", {}).get("created_at", ""),
		"updated_at": data.get("meta", {}).get("updated_at", ""),
		"playtime_seconds": data.get("meta", {}).get("playtime_seconds", 0),
		"chapter": data.get("main", {}).get("chapter", 1),
		"build_flavor": data.get("version", {}).get("build_flavor", ""),
		"schema_version": data.get("version", {}).get("schema_version", 0),
		"file_size": FileAccess.get_file_as_bytes(path).size()
	}


## Save game to slot
func save_game(slot: int, is_auto: bool = false) -> bool:
	if not is_auto and (slot < 1 or slot > MAX_MANUAL_SLOTS):
		push_error("[SaveManager] Invalid manual save slot: %d" % slot)
		return false

	if is_auto and (slot < 0 or slot >= MAX_AUTO_SLOTS):
		push_error("[SaveManager] Invalid auto-save slot: %d" % slot)
		return false

	# Get state from GameState
	var state_data := GameState.to_dict()

	# Update timestamps
	state_data.meta.updated_at = Time.get_datetime_string_from_system()

	# Serialize to JSON
	var json_string := JSON.stringify(state_data, "\t")

	# Write to file
	var path := _get_save_path(slot, is_auto)
	var file := FileAccess.open(path, FileAccess.WRITE)

	if not file:
		push_error("[SaveManager] Failed to open save file for writing: %s" % path)
		save_completed.emit(slot, false)
		return false

	file.store_string(json_string)
	file.close()

	# Update cache
	var actual_slot := slot if not is_auto else slot + 1000
	save_slots[actual_slot] = _load_save_metadata(actual_slot)

	current_slot = actual_slot
	save_list_updated.emit()
	save_completed.emit(slot, true)

	print("[SaveManager] Game saved to slot %d (auto: %s)" % [slot, is_auto])

	# Trigger Steam Cloud sync if available
	if SteamManager and SteamManager.is_steam_available():
		SteamManager.sync_cloud_files()

	return true


## Load game from slot
func load_game(slot: int) -> bool:
	var is_auto := slot >= 1000
	var actual_slot := slot if not is_auto else slot - 1000

	var path := _get_save_path(actual_slot, is_auto)

	if not FileAccess.file_exists(path):
		push_error("[SaveManager] Save file not found: %s" % path)
		load_completed.emit(slot, false)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Failed to open save file: %s" % path)
		load_completed.emit(slot, false)
		return false

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[SaveManager] Failed to parse save file: %s" % path)
		load_completed.emit(slot, false)
		return false

	var data := json.data as Dictionary

	# Validate save data
	if not _validate_save_data(data):
		push_error("[SaveManager] Save data validation failed")
		load_completed.emit(slot, false)
		return false

	# Load into GameState
	if not GameState.from_dict(data):
		push_error("[SaveManager] Failed to load state from save data")
		load_completed.emit(slot, false)
		return false

	current_slot = slot
	load_completed.emit(slot, true)

	print("[SaveManager] Game loaded from slot %d" % slot)
	return true


## Validate save data structure
func _validate_save_data(data: Dictionary) -> bool:
	# Check required top-level keys
	if not data.has("version"):
		push_error("[SaveManager] Save data missing 'version' key")
		return false

	if not data.version.has("schema_version"):
		push_error("[SaveManager] Save data missing schema_version")
		return false

	# Check schema version compatibility
	var save_schema := data.version.schema_version as int
	if save_schema > GameState.SCHEMA_VERSION:
		push_error("[SaveManager] Save is from newer version (schema %d > %d)" % [save_schema, GameState.SCHEMA_VERSION])
		return false

	return true


## Delete save slot
func delete_save(slot: int) -> bool:
	var is_auto := slot >= 1000
	var actual_slot := slot if not is_auto else slot - 1000

	var path := _get_save_path(actual_slot, is_auto)

	if not FileAccess.file_exists(path):
		push_warning("[SaveManager] Save file not found for deletion: %s" % path)
		return false

	var dir := DirAccess.open(SAVE_DIR)
	var err := dir.remove(path)

	if err != OK:
		push_error("[SaveManager] Failed to delete save file: %s" % path)
		return false

	save_slots.erase(slot)
	save_list_updated.emit()

	print("[SaveManager] Deleted save slot %d" % slot)
	return true


## Get list of all save slots with metadata
func get_save_list() -> Array:
	var list := []

	for slot in save_slots.keys():
		list.append(save_slots[slot])

	# Sort by updated_at (most recent first)
	list.sort_custom(func(a, b): return a.updated_at > b.updated_at)

	return list


## Get metadata for specific slot
func get_save_metadata(slot: int) -> Dictionary:
	return save_slots.get(slot, {})


## Check if slot has save
func has_save(slot: int) -> bool:
	return save_slots.has(slot)


## Get next available manual slot
func get_next_available_slot() -> int:
	for i in range(1, MAX_MANUAL_SLOTS + 1):
		if not has_save(i):
			return i
	return -1  # All slots full


## Auto-save (uses rolling slots 0-9)
func auto_save() -> bool:
	# Find oldest auto-save slot or first empty
	var oldest_slot := 0
	var oldest_time := ""

	for i in range(MAX_AUTO_SLOTS):
		var slot := i + 1000
		if not has_save(slot):
			return save_game(i, true)

		var metadata := get_save_metadata(slot)
		if oldest_time == "" or metadata.updated_at < oldest_time:
			oldest_time = metadata.updated_at
			oldest_slot = i

	# Overwrite oldest
	return save_game(oldest_slot, true)


## Quick save (slot 0, special quick save slot)
func quick_save() -> bool:
	return save_game(0, false)


## Quick load (slot 0)
func quick_load() -> bool:
	if not has_save(0):
		push_warning("[SaveManager] No quick save found")
		return false
	return load_game(0)


## Export save to file (for backup/sharing)
func export_save(slot: int, export_path: String) -> bool:
	var is_auto := slot >= 1000
	var actual_slot := slot if not is_auto else slot - 1000

	var source_path := _get_save_path(actual_slot, is_auto)

	if not FileAccess.file_exists(source_path):
		push_error("[SaveManager] Source save not found: %s" % source_path)
		return false

	var source := FileAccess.open(source_path, FileAccess.READ)
	if not source:
		return false

	var content := source.get_as_text()
	source.close()

	var dest := FileAccess.open(export_path, FileAccess.WRITE)
	if not dest:
		push_error("[SaveManager] Failed to create export file: %s" % export_path)
		return false

	dest.store_string(content)
	dest.close()

	print("[SaveManager] Save exported to: %s" % export_path)
	return true


## Import save from file
func import_save(import_path: String, target_slot: int) -> bool:
	if not FileAccess.file_exists(import_path):
		push_error("[SaveManager] Import file not found: %s" % import_path)
		return false

	var source := FileAccess.open(import_path, FileAccess.READ)
	if not source:
		return false

	var content := source.get_as_text()
	source.close()

	# Validate before importing
	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("[SaveManager] Invalid save file format")
		return false

	var data := json.data as Dictionary
	if not _validate_save_data(data):
		push_error("[SaveManager] Save data validation failed")
		return false

	# Write to target slot
	var dest_path := _get_save_path(target_slot, false)
	var dest := FileAccess.open(dest_path, FileAccess.WRITE)
	if not dest:
		push_error("[SaveManager] Failed to write imported save")
		return false

	dest.store_string(content)
	dest.close()

	# Update cache
	save_slots[target_slot] = _load_save_metadata(target_slot)
	save_list_updated.emit()

	print("[SaveManager] Save imported to slot %d" % target_slot)
	return true


## Get total save file size (for cloud quota check)
func get_total_save_size() -> int:
	var total := 0
	for slot in save_slots.keys():
		var metadata := save_slots[slot]
		total += metadata.get("file_size", 0)
	return total


## Backup all saves to directory
func backup_all_saves(backup_dir: String) -> bool:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists(backup_dir):
		dir.make_dir_recursive(backup_dir)

	var success_count := 0

	for slot in save_slots.keys():
		var is_auto := slot >= 1000
		var actual_slot := slot if not is_auto else slot - 1000
		var source_path := _get_save_path(actual_slot, is_auto)
		var backup_path := backup_dir + "/" + source_path.get_file()

		if export_save(slot, backup_path):
			success_count += 1

	print("[SaveManager] Backed up %d saves to %s" % [success_count, backup_dir])
	return success_count > 0


## Format playtime for display
static func format_playtime(seconds: int) -> String:
	var hours := seconds / 3600
	var minutes := (seconds % 3600) / 60

	if hours > 0:
		return "%d:%02d" % [hours, minutes]
	else:
		return "%d min" % minutes
