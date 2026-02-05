extends Node
## GameState - Global game state management
## Manages all game variables across 13 domains as per specification

signal state_changed(domain: String, key: String, value: Variant)
signal save_requested()
signal load_requested(slot: int)

## Build information
const BUILD_VERSION := "0.1.0"
const BUILD_FLAVOR := "demo"  # "demo" or "full"
const SCHEMA_VERSION := 1

## Game state structure (13 domains as per specification)
var state := {
	# 1. meta - Save metadata
	"meta": {
		"save_version": SCHEMA_VERSION,
		"build_flavor": BUILD_FLAVOR,
		"created_at": "",
		"updated_at": "",
		"playtime_seconds": 0
	},

	# 2. nav - Navigation/screen state
	"nav": {
		"screen": "home",  # home|main|side|settings|gallery
		"stack": [],  # Navigation history for back button
		"last_safe_screen": "home"  # Fallback for crashes
	},

	# 3. main - Main story state
	"main": {
		"chapter": 1,  # 1-7
		"node_id": "",  # Current story node ID
		"pov_current": "emperor",  # emperor|consort|minister
		"pov_visited": {
			"emperor": false,
			"consort": false,
			"minister": false
		},
		"seen_nodes": [],  # For skip-read functionality
		"flags": {
			"visited_all_pov_in_chapter": false,
			"did_key_compare": false,
			"did_key_interrogate": false,
			"did_archive_confirm": false
		}
	},

	# 4. stance - Investigation stance/口径 system
	"stance": {
		"axis_truth": 0,  # -100 to +100 (negative=usable narrative, positive=allow truth)
		"axis_loyalty": {  # Trust in each perspective
			"emperor": 0,
			"consort": 0,
			"minister": 0
		},
		"axis_blame": {  # Blame attribution tendency
			"emperor": 0,
			"consort": 0,
			"minister": 0
		},
		"key_choices": []  # Record of critical choices
	},

	# 5. archive - Archiving/sealing/finalization
	"archive": {
		"entries": [],  # List of ArchiveEntry dicts
		"seal_counts": {}  # Count of each seal type used
	},

	# 6. evidence - Evidence comparison/contradiction tracking
	"evidence": {
		"compare_history": [],  # History of comparisons made
		"interrogate_log": [],  # History of interrogations
		"contradictions_found": []  # IDs of discovered contradictions
	},

	# 7. ending - Ending calculation and unlocks
	"ending": {
		"ending_id": "",  # Final ending achieved
		"calculated_from": {},  # Snapshot of state used for calculation
		"unlocked_endings": []  # All endings player has seen
	},

	# 8. ui - UI state (dialogue box, auto-play, etc.)
	"ui": {
		"auto_enabled": false,
		"auto_speed": 1.0,  # Seconds per dialogue line
		"skip_enabled": false,
		"backlog_open": false,
		"backlog_capacity": 100,  # Max lines in backlog
		"text_speed": 1.0,
		"volume_bgm": 0.8,
		"volume_sfx": 0.8,
		"volume_voice": 0.8
	},

	# 9. settings - Player settings
	"settings": {
		"lang_mode": "monolingual",  # monolingual|bilingual|immersion_bilingual
		"lang_primary": "english",  # Primary language (steam_lang code)
		"lang_target": "",  # Target language for learning (empty if monolingual)
		"font_size": 1.0,  # Font size multiplier
		"no_text_in_images": true,  # Always true per spec
		"enable_2_5d": true,  # Enable 2.5D scenes
		"fullscreen": true,
		"vsync": true
	},

	# 10. learning - Vocabulary learning system
	"learning": {
		"immersion_enabled": false,  # Only works in bilingual mode
		"inject_rate": 0.10,  # Percentage of sentences with vocab
		"level_setting": 5,  # Internal level index (1-12)
		"level_system": "CEFR",  # Display system (HSK/JLPT/TOPIK/CEFR/etc.)
		"quiz_enabled": true,  # Enable quiz system
		"quiz_correct_rate": 0.0,  # Running average
		"quiz_total": 0,
		"quiz_correct": 0,
		"level_estimate": 5,  # Dynamic level based on performance
		"mastered_words": []  # IDs of mastered vocabulary
	},

	# 11. side - Side story (turtle soup) state
	"side": {
		"case_id": "",  # Current case ID
		"state": "init",  # init|playing|solved|failed
		"turn": 0,  # Question turn counter
		"asked_questions": [],  # Questions already asked
		"hints_used": 0,
		"result": "",  # Final result
		"replay": {
			"events": [],  # Full event log for replay
			"share_code": ""  # Base64 encoded replay data
		}
	},

	# 12. flags - Global flags for gates and achievements
	"flags": {
		"first_launch": true,
		"tutorial_completed": false,
		"chapters_completed": [],  # List of completed chapter numbers
		"achievements_unlocked": []  # List of achievement IDs
	},

	# 13. version - Version tracking for migration
	"version": {
		"game_version": BUILD_VERSION,
		"schema_version": SCHEMA_VERSION,
		"build_flavor": BUILD_FLAVOR,
		"last_migration": 0
	}
}


func _ready() -> void:
	print("[GameState] Initialized with schema version %d" % SCHEMA_VERSION)
	_initialize_timestamps()


func _initialize_timestamps() -> void:
	var now := Time.get_datetime_string_from_system()
	if state.meta.created_at == "":
		state.meta.created_at = now
	state.meta.updated_at = now


## Get value from state
func get_value(domain: String, key: String, default: Variant = null) -> Variant:
	if not state.has(domain):
		push_warning("[GameState] Unknown domain: %s" % domain)
		return default

	if not state[domain].has(key):
		push_warning("[GameState] Unknown key '%s' in domain '%s'" % [key, domain])
		return default

	return state[domain][key]


## Set value in state
func set_value(domain: String, key: String, value: Variant) -> void:
	if not state.has(domain):
		push_error("[GameState] Cannot set value in unknown domain: %s" % domain)
		return

	state[domain][key] = value
	state_changed.emit(domain, key, value)
	_mark_updated()


## Get entire domain
func get_domain(domain: String) -> Dictionary:
	if not state.has(domain):
		push_warning("[GameState] Unknown domain: %s" % domain)
		return {}
	return state[domain]


## Set entire domain (use with caution)
func set_domain(domain: String, data: Dictionary) -> void:
	if not state.has(domain):
		push_error("[GameState] Cannot set unknown domain: %s" % domain)
		return

	state[domain] = data
	state_changed.emit(domain, "", data)
	_mark_updated()


## Mark state as updated
func _mark_updated() -> void:
	state.meta.updated_at = Time.get_datetime_string_from_system()


## Reset state to initial values
func reset_state() -> void:
	# Preserve meta information
	var old_created_at := state.meta.created_at
	var old_playtime := state.meta.playtime_seconds

	# Reset all domains
	for domain in state.keys():
		if domain == "meta":
			continue
		if domain == "version":
			continue

		# Reset to initial structure
		match domain:
			"nav":
				state.nav = {
					"screen": "home",
					"stack": [],
					"last_safe_screen": "home"
				}
			"main":
				state.main = {
					"chapter": 1,
					"node_id": "",
					"pov_current": "emperor",
					"pov_visited": {
						"emperor": false,
						"consort": false,
						"minister": false
					},
					"seen_nodes": [],
					"flags": {
						"visited_all_pov_in_chapter": false,
						"did_key_compare": false,
						"did_key_interrogate": false,
						"did_archive_confirm": false
					}
				}
			# Add other domains as needed

	# Restore preserved meta
	state.meta.created_at = old_created_at
	state.meta.playtime_seconds = old_playtime
	_mark_updated()

	print("[GameState] State reset to initial values")


## Serialize state to dictionary (for saving)
func to_dict() -> Dictionary:
	return state.duplicate(true)


## Load state from dictionary (from save file)
func from_dict(data: Dictionary) -> bool:
	# Validate schema version
	if not data.has("version") or not data.version.has("schema_version"):
		push_error("[GameState] Invalid save data: missing schema version")
		return false

	var save_schema := data.version.schema_version as int
	if save_schema > SCHEMA_VERSION:
		push_error("[GameState] Save file is from newer version (schema %d > %d)" % [save_schema, SCHEMA_VERSION])
		return false

	# Migrate if needed
	if save_schema < SCHEMA_VERSION:
		data = _migrate_save_data(data, save_schema)

	# Load state
	state = data.duplicate(true)
	_mark_updated()

	print("[GameState] State loaded from save (schema %d)" % save_schema)
	return true


## Migrate save data from old schema to current
func _migrate_save_data(data: Dictionary, from_schema: int) -> Dictionary:
	print("[GameState] Migrating save data from schema %d to %d" % [from_schema, SCHEMA_VERSION])

	# Add migration logic here as schema evolves
	# For now, just update version info
	data.version.schema_version = SCHEMA_VERSION
	data.version.last_migration = from_schema

	return data


## Check if Demo content gate should block
func is_demo_content_locked(chapter: int) -> bool:
	if BUILD_FLAVOR == "full":
		return false

	# Demo allows Chapter 1 only
	return chapter > 1


## Update playtime (call from _process in main scene)
func update_playtime(delta: float) -> void:
	state.meta.playtime_seconds += int(delta)
