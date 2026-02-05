extends Node
## SteamManager - Steamworks integration with graceful degradation
## Handles achievements, cloud saves, Steam Input, and language detection

signal steam_initialized(success: bool)
signal achievement_unlocked(achievement_id: String)
signal cloud_sync_completed(success: bool)

const STEAM_APP_ID := 480  # TEST ONLY - Must change for release
const STEAM_APP_ID_FILE := "steam_appid.txt"

var steam_available := false
var steam_id := 0
var steam_username := ""
var achievements_cache := {}


func _ready() -> void:
	_initialize_steam()


## Initialize Steamworks
func _initialize_steam() -> void:
	# Check if running from Steam or has steam_appid.txt
	if not _check_steam_environment():
		print("[SteamManager] Steam not available - running in offline mode")
		steam_available = false
		steam_initialized.emit(false)
		return

	# Try to initialize Steam API
	# NOTE: This requires GodotSteam GDExtension to be installed
	# For now, we'll simulate the check
	if not _try_initialize_steam_api():
		print("[SteamManager] Failed to initialize Steam API - graceful degradation")
		steam_available = false
		steam_initialized.emit(false)
		return

	steam_available = true
	print("[SteamManager] Steam initialized successfully")
	steam_initialized.emit(true)

	# Load user info
	_load_steam_user_info()

	# Load achievements
	_load_achievements()


## Check if Steam environment is available
func _check_steam_environment() -> bool:
	# Check for steam_appid.txt (development)
	if FileAccess.file_exists(STEAM_APP_ID_FILE):
		print("[SteamManager] Found steam_appid.txt - development mode")
		return true

	# Check if launched from Steam (production)
	# In real implementation, check for Steam client process
	# For now, return false to simulate offline mode
	return false


## Try to initialize Steam API
func _try_initialize_steam_api() -> bool:
	# NOTE: This is a stub implementation
	# Real implementation would use GodotSteam:
	#
	# if not Engine.has_singleton("Steam"):
	#     return false
	#
	# var init_result = Steam.steamInit()
	# if init_result.status != 1:
	#     push_error("[SteamManager] Steam init failed: %s" % init_result.verbal)
	#     return false
	#
	# return true

	# For now, return false to simulate Steam not available
	return false


## Load Steam user information
func _load_steam_user_info() -> void:
	if not steam_available:
		return

	# Real implementation:
	# steam_id = Steam.getSteamID()
	# steam_username = Steam.getPersonaName()

	steam_id = 0
	steam_username = "Player"

	print("[SteamManager] User: %s (ID: %d)" % [steam_username, steam_id])


## Check if Steam is available
func is_steam_available() -> bool:
	return steam_available


## Get Steam language code
func get_steam_language() -> String:
	if not steam_available:
		return ""

	# Real implementation:
	# var steam_lang = Steam.getCurrentGameLanguage()
	# return _map_steam_language(steam_lang)

	return ""


## Map Steam language to our steam_lang codes
func _map_steam_language(steam_lang: String) -> String:
	# Steam uses different codes, map to our system
	match steam_lang:
		"schinese": return "schinese"
		"tchinese": return "tchinese"
		"english": return "english"
		"japanese": return "japanese"
		"koreana": return "koreana"
		"french": return "french"
		"german": return "german"
		"spanish": return "spanish"
		"latam": return "latam"
		"brazilian": return "brazilian"
		"portuguese": return "portuguese"
		"russian": return "russian"
		"italian": return "italian"
		"dutch": return "dutch"
		"polish": return "polish"
		"turkish": return "turkish"
		"thai": return "thai"
		"vietnamese": return "vietnamese"
		"indonesian": return "indonesian"
		"ukrainian": return "ukrainian"
		"czech": return "czech"
		"hungarian": return "hungarian"
		"romanian": return "romanian"
		"bulgarian": return "bulgarian"
		"greek": return "greek"
		"danish": return "danish"
		"finnish": return "finnish"
		"norwegian": return "norwegian"
		"swedish": return "swedish"
		"arabic": return "arabic"

	return "english"  # Default fallback


## Load achievements from Steam
func _load_achievements() -> void:
	if not steam_available:
		return

	# Real implementation:
	# var num_achievements = Steam.getNumAchievements()
	# for i in range(num_achievements):
	#     var ach_name = Steam.getAchievementName(i)
	#     var achieved = Steam.getAchievement(ach_name)
	#     achievements_cache[ach_name] = achieved

	print("[SteamManager] Loaded %d achievements" % achievements_cache.size())


## Unlock achievement
func unlock_achievement(achievement_id: String) -> bool:
	# Always track locally
	if GameState:
		var unlocked: Array = GameState.get_value("flags", "achievements_unlocked", [])
		if achievement_id not in unlocked:
			unlocked.append(achievement_id)
			GameState.set_value("flags", "achievements_unlocked", unlocked)

	if not steam_available:
		print("[SteamManager] Achievement unlocked (offline): %s" % achievement_id)
		achievement_unlocked.emit(achievement_id)
		return true

	# Real implementation:
	# if achievements_cache.get(achievement_id, false):
	#     return true  # Already unlocked
	#
	# var success = Steam.setAchievement(achievement_id)
	# if success:
	#     Steam.storeStats()
	#     achievements_cache[achievement_id] = true
	#     achievement_unlocked.emit(achievement_id)
	#     print("[SteamManager] Achievement unlocked: %s" % achievement_id)
	#     return true

	achievement_unlocked.emit(achievement_id)
	return true


## Check if achievement is unlocked
func is_achievement_unlocked(achievement_id: String) -> bool:
	if steam_available:
		return achievements_cache.get(achievement_id, false)

	# Check local cache
	if GameState:
		var unlocked: Array = GameState.get_value("flags", "achievements_unlocked", [])
		return achievement_id in unlocked

	return false


## Get achievement progress (for progress-based achievements)
func get_achievement_progress(achievement_id: String) -> float:
	if not steam_available:
		return 0.0

	# Real implementation:
	# var progress = Steam.getAchievementAchievedPercent(achievement_id)
	# return progress

	return 0.0


## Sync cloud files
func sync_cloud_files() -> void:
	if not steam_available:
		return

	# Real implementation:
	# Steam Cloud automatically syncs files in designated directories
	# We just need to ensure files are written to the right location

	print("[SteamManager] Cloud sync requested")
	cloud_sync_completed.emit(true)


## Check if cloud save exists
func has_cloud_save() -> bool:
	if not steam_available:
		return false

	# Real implementation:
	# Check if Steam Cloud has save files
	# var file_count = Steam.getFileCount()
	# return file_count > 0

	return false


## Resolve cloud save conflict
func resolve_cloud_conflict(use_cloud: bool) -> void:
	if not steam_available:
		return

	if use_cloud:
		print("[SteamManager] Using cloud save")
		# Download and load cloud save
	else:
		print("[SteamManager] Using local save")
		# Upload local save to cloud


## Get Steam Input handle
func get_steam_input_handle() -> int:
	if not steam_available:
		return 0

	# Real implementation:
	# return Steam.getInputHandle()

	return 0


## Show Steam overlay
func show_overlay(dialog: String = "") -> void:
	if not steam_available:
		push_warning("[SteamManager] Cannot show overlay - Steam not available")
		return

	# Real implementation:
	# Steam.activateGameOverlay(dialog)
	# dialog can be: "Friends", "Community", "Players", "Settings", "OfficialGameGroup", "Stats", "Achievements"

	print("[SteamManager] Showing overlay: %s" % dialog)


## Open Steam store page
func open_store_page(app_id: int = STEAM_APP_ID) -> void:
	if not steam_available:
		# Fallback to browser
		OS.shell_open("https://store.steampowered.com/app/%d" % app_id)
		return

	# Real implementation:
	# Steam.activateGameOverlayToStore(app_id)

	print("[SteamManager] Opening store page for app %d" % app_id)


## Check if running with test AppID (480)
func is_using_test_app_id() -> bool:
	return STEAM_APP_ID == 480


## Validate release build (must not use AppID 480)
func validate_release_build() -> bool:
	if GameState.BUILD_FLAVOR == "release" and STEAM_APP_ID == 480:
		push_error("[SteamManager] CRITICAL: Cannot release with test AppID 480!")
		return false
	return true


## Get rich presence
func set_rich_presence(key: String, value: String) -> void:
	if not steam_available:
		return

	# Real implementation:
	# Steam.setRichPresence(key, value)

	print("[SteamManager] Rich presence: %s = %s" % [key, value])


## Clear rich presence
func clear_rich_presence() -> void:
	if not steam_available:
		return

	# Real implementation:
	# Steam.clearRichPresence()


## Get leaderboard (for future use)
func get_leaderboard(leaderboard_name: String) -> void:
	if not steam_available:
		return

	# Real implementation:
	# Steam.findLeaderboard(leaderboard_name)


## Upload leaderboard score
func upload_score(leaderboard_name: String, score: int) -> void:
	if not steam_available:
		return

	# Real implementation:
	# Steam.uploadLeaderboardScore(score, true, [], leaderboard_name)

	print("[SteamManager] Score uploaded: %s = %d" % [leaderboard_name, score])


## Process Steam callbacks (call from _process)
func process_callbacks() -> void:
	if not steam_available:
		return

	# Real implementation:
	# Steam.run_callbacks()


## Shutdown Steam
func shutdown() -> void:
	if not steam_available:
		return

	print("[SteamManager] Shutting down Steam")

	# Real implementation:
	# Steam.steamShutdown()


func _exit_tree() -> void:
	shutdown()
