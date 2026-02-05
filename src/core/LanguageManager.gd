extends Node
## LanguageManager - Handles 29 modern + 4 ancient languages
## Manages language registry, fallback chains, and localization

signal language_changed(lang_code: String)
signal translation_missing(key: String, lang_code: String)

const LANGUAGE_REGISTRY_PATH := "res://locales/_meta/language_registry.json"
const FALLBACK_RULES_PATH := "res://locales/_meta/fallback_rules.json"

var language_registry := {}
var fallback_rules := {}
var current_language := "english"
var translations := {}  # Cache of loaded translations
var missing_keys := {}  # Track missing keys per language


func _ready() -> void:
	_load_language_registry()
	_load_fallback_rules()
	_detect_initial_language()
	print("[LanguageManager] Initialized with language: %s" % current_language)


## Load language registry from JSON
func _load_language_registry() -> void:
	var file := FileAccess.open(LANGUAGE_REGISTRY_PATH, FileAccess.READ)
	if not file:
		push_error("[LanguageManager] Failed to load language registry")
		return

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[LanguageManager] Failed to parse language registry JSON")
		return

	var data := json.data as Dictionary
	if data.has("languages"):
		language_registry = data.languages
		print("[LanguageManager] Loaded %d languages" % language_registry.size())


## Load fallback rules from JSON
func _load_fallback_rules() -> void:
	var file := FileAccess.open(FALLBACK_RULES_PATH, FileAccess.READ)
	if not file:
		push_error("[LanguageManager] Failed to load fallback rules")
		return

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[LanguageManager] Failed to parse fallback rules JSON")
		return

	var data := json.data as Dictionary
	if data.has("rules"):
		fallback_rules = data.rules
		print("[LanguageManager] Loaded fallback rules for %d languages" % fallback_rules.size())


## Detect initial language from Steam, system, or default
func _detect_initial_language() -> void:
	var detected_lang := "english"

	# 1. Check player settings (from GameState)
	if GameState:
		var saved_lang := GameState.get_value("settings", "lang_primary", "")
		if saved_lang != "" and is_language_available(saved_lang):
			detected_lang = saved_lang
			current_language = detected_lang
			return

	# 2. Try Steam language (if SteamManager available)
	if SteamManager and SteamManager.is_steam_available():
		var steam_lang := SteamManager.get_steam_language()
		if steam_lang != "" and is_language_available(steam_lang):
			detected_lang = steam_lang
			current_language = detected_lang
			return

	# 3. Try system locale
	var os_locale := OS.get_locale()
	var lang_from_locale := _map_locale_to_steam_lang(os_locale)
	if lang_from_locale != "" and is_language_available(lang_from_locale):
		detected_lang = lang_from_locale
		current_language = detected_lang
		return

	# 4. Default to English
	current_language = "english"
	print("[LanguageManager] Using default language: english")


## Map OS locale to steam_lang code
func _map_locale_to_steam_lang(locale: String) -> String:
	# OS.get_locale() returns format like "en_US", "zh_CN", "ja_JP"
	var parts := locale.split("_")
	if parts.size() == 0:
		return ""

	var lang := parts[0].to_lower()

	# Map common locale codes to steam_lang
	match lang:
		"zh":
			if parts.size() > 1:
				return "tchinese" if parts[1] == "TW" or parts[1] == "HK" else "schinese"
			return "schinese"
		"en": return "english"
		"ja": return "japanese"
		"ko": return "koreana"
		"fr": return "french"
		"de": return "german"
		"es":
			if parts.size() > 1 and parts[1] in ["MX", "AR", "CL", "CO"]:
				return "latam"
			return "spanish"
		"pt":
			if parts.size() > 1 and parts[1] == "BR":
				return "brazilian"
			return "portuguese"
		"ru": return "russian"
		"it": return "italian"
		"nl": return "dutch"
		"pl": return "polish"
		"tr": return "turkish"
		"th": return "thai"
		"vi": return "vietnamese"
		"id": return "indonesian"
		"uk": return "ukrainian"
		"cs": return "czech"
		"hu": return "hungarian"
		"ro": return "romanian"
		"bg": return "bulgarian"
		"el": return "greek"
		"da": return "danish"
		"fi": return "finnish"
		"no": return "norwegian"
		"sv": return "swedish"
		"ar": return "arabic"

	return ""


## Check if language is available
func is_language_available(lang_code: String) -> bool:
	return language_registry.has(lang_code)


## Get language info from registry
func get_language_info(lang_code: String) -> Dictionary:
	if not language_registry.has(lang_code):
		push_warning("[LanguageManager] Unknown language: %s" % lang_code)
		return {}
	return language_registry[lang_code]


## Check if language is RTL
func is_rtl(lang_code: String) -> bool:
	var info := get_language_info(lang_code)
	return info.get("direction", "ltr") == "rtl"


## Check if language is ancient (not modern)
func is_ancient_language(lang_code: String) -> bool:
	var info := get_language_info(lang_code)
	return info.get("is_ancient", false)


## Get display name for language
func get_display_name(lang_code: String) -> String:
	var info := get_language_info(lang_code)
	return info.get("display_name", lang_code)


## Get list of all modern languages
func get_modern_languages() -> Array:
	var modern := []
	for lang_code in language_registry.keys():
		var info := language_registry[lang_code]
		if info.get("is_modern", false):
			modern.append(lang_code)
	return modern


## Get list of all ancient languages
func get_ancient_languages() -> Array:
	var ancient := []
	for lang_code in language_registry.keys():
		var info := language_registry[lang_code]
		if info.get("is_ancient", false):
			ancient.append(lang_code)
	return ancient


## Set current language
func set_language(lang_code: String) -> bool:
	if not is_language_available(lang_code):
		push_error("[LanguageManager] Cannot set unavailable language: %s" % lang_code)
		return false

	if lang_code == current_language:
		return true

	current_language = lang_code
	_load_translations(lang_code)
	language_changed.emit(lang_code)

	# Update GameState
	if GameState:
		GameState.set_value("settings", "lang_primary", lang_code)

	print("[LanguageManager] Language changed to: %s" % lang_code)
	return true


## Load translations for a language
func _load_translations(lang_code: String) -> void:
	if translations.has(lang_code):
		return  # Already loaded

	var locale_path := "res://locales/%s/ui.json" % lang_code
	var file := FileAccess.open(locale_path, FileAccess.READ)

	if not file:
		push_warning("[LanguageManager] Translation file not found: %s" % locale_path)
		translations[lang_code] = {}
		return

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[LanguageManager] Failed to parse translations for %s" % lang_code)
		translations[lang_code] = {}
		return

	translations[lang_code] = json.data as Dictionary
	print("[LanguageManager] Loaded %d translation keys for %s" % [translations[lang_code].size(), lang_code])


## Translate a key
func tr(key: String, lang_code: String = "") -> String:
	if lang_code == "":
		lang_code = current_language

	# Ensure translations are loaded
	if not translations.has(lang_code):
		_load_translations(lang_code)

	# Try to find translation
	if translations[lang_code].has(key):
		return translations[lang_code][key]

	# Try fallback chain
	if fallback_rules.has(lang_code):
		var fallback_chain: Array = fallback_rules[lang_code]
		for fallback_lang in fallback_chain:
			if not translations.has(fallback_lang):
				_load_translations(fallback_lang)

			if translations[fallback_lang].has(key):
				return translations[fallback_lang][key]

	# No translation found
	_log_missing_key(key, lang_code)
	return "[%s]" % key  # Return key in brackets to indicate missing translation


## Log missing translation key
func _log_missing_key(key: String, lang_code: String) -> void:
	if not missing_keys.has(lang_code):
		missing_keys[lang_code] = []

	if key not in missing_keys[lang_code]:
		missing_keys[lang_code].append(key)
		translation_missing.emit(key, lang_code)
		push_warning("[LanguageManager] Missing translation: %s for %s" % [key, lang_code])


## Get missing keys report
func get_missing_keys_report() -> Dictionary:
	return missing_keys.duplicate(true)


## Export missing keys to file (for QA)
func export_missing_keys(output_path: String) -> void:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		push_error("[LanguageManager] Failed to open file for writing: %s" % output_path)
		return

	file.store_line("# Missing Translation Keys Report")
	file.store_line("# Generated: %s" % Time.get_datetime_string_from_system())
	file.store_line("")

	for lang_code in missing_keys.keys():
		file.store_line("## Language: %s (%s)" % [lang_code, get_display_name(lang_code)])
		file.store_line("Missing keys: %d" % missing_keys[lang_code].size())
		file.store_line("")

		for key in missing_keys[lang_code]:
			file.store_line("- %s" % key)

		file.store_line("")

	file.close()
	print("[LanguageManager] Missing keys report exported to: %s" % output_path)


## Validate all languages have required keys
func validate_all_languages(required_keys: Array) -> Dictionary:
	var report := {}

	for lang_code in get_modern_languages():
		if not translations.has(lang_code):
			_load_translations(lang_code)

		var missing := []
		for key in required_keys:
			if not translations[lang_code].has(key):
				missing.append(key)

		if missing.size() > 0:
			report[lang_code] = missing

	return report
