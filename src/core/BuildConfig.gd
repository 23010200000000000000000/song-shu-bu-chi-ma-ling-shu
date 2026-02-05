extends Node
## BuildConfig - Loads and manages build configuration
## Determines Demo vs Full version features

signal build_config_loaded()

var config: Dictionary = {}
var is_demo: bool = false
var is_full: bool = false


func _ready() -> void:
	_load_build_config()


func _load_build_config() -> void:
	# Try to load build_config.json
	var config_path := "res://build_config.json"

	if FileAccess.file_exists(config_path):
		var file := FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json_text := file.get_as_text()
			file.close()

			var json := JSON.new()
			if json.parse(json_text) == OK:
				config = json.data
				_apply_config()
				print("[BuildConfig] Loaded: %s" % config.get("build_flavor", "unknown"))
				build_config_loaded.emit()
				return

	# Fallback to default (full version)
	_load_default_config()


func _load_default_config() -> void:
	config = {
		"build_flavor": "full",
		"build_date": Time.get_datetime_string_from_system(),
		"chapters_available": [1, 2, 3, 4, 5, 6, 7],
		"side_stories_available": [1, 2, 3],
		"max_achievements": 60,
		"max_save_slots": 100
	}
	_apply_config()
	print("[BuildConfig] Using default (full) configuration")
	build_config_loaded.emit()


func _apply_config() -> void:
	var flavor := config.get("build_flavor", "full")
	is_demo = (flavor == "demo")
	is_full = (flavor == "full")

	# Update GameState if available
	if GameState:
		GameState.BUILD_FLAVOR = flavor


## Check if a chapter is available
func is_chapter_available(chapter: int) -> bool:
	var chapters: Array = config.get("chapters_available", [])
	return chapter in chapters


## Check if a side story is available
func is_side_story_available(case_num: int) -> bool:
	var stories: Array = config.get("side_stories_available", [])
	return case_num in stories


## Get maximum save slots
func get_max_save_slots() -> int:
	return config.get("max_save_slots", 100)


## Get maximum achievements
func get_max_achievements() -> int:
	return config.get("max_achievements", 60)


## Get build flavor string
func get_build_flavor() -> String:
	return config.get("build_flavor", "full")


## Get build date
func get_build_date() -> String:
	return config.get("build_date", "")


## Get available chapters
func get_available_chapters() -> Array:
	return config.get("chapters_available", [])


## Get available side stories
func get_available_side_stories() -> Array:
	return config.get("side_stories_available", [])


## Check if this is a demo build
func is_demo_build() -> bool:
	return is_demo


## Check if this is a full build
func is_full_build() -> bool:
	return is_full
