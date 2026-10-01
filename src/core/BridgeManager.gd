extends Node

signal ad_opened
signal ad_closed

var _is_ad_active := false
var _was_paused_before_ad := false
var _is_muted_before_ad := false

var _is_focus_lost := false
var _was_paused_before_focus := false
var _is_muted_before_focus := false

func is_active() -> bool:
	return OS.has_feature("web") or OS.has_feature("editor")

func EnsureDefaultSettingsFile() -> void:
	var path = "user://settings.cfg"
	if FileAccess.file_exists(path):
		return
		
	print("BridgeManager: Settings file not found. Creating settings.cfg with default values.")
	var config = ConfigFile.new()
	
	# Audio Defaults
	config.set_value("Audio", "MusicVolume", 20.0)
	config.set_value("Audio", "SfxVolume", 50.0)
	
	# Video Defaults
	config.set_value("Video", "ResolutionIndex", 3)
	config.set_value("Video", "Fullscreen", false)
	config.set_value("Video", "ScaleIndex", 0)
	
	# Gameplay Defaults
	config.set_value("Gameplay", "ShowTutorial", true)
	
	# Detect initial default language
	var detected_lang = "en"
	if is_active() and Bridge != null and Bridge.platform != null:
		var platform_lang = Bridge.platform.language
		var resolved = _resolve_locale_code(platform_lang)
		if not resolved.is_empty():
			detected_lang = resolved
	else:
		var system_locale = TranslationServer.get_locale()
		var resolved = _resolve_locale_code(system_locale)
		if not resolved.is_empty():
			detected_lang = resolved
			
	config.set_value("Gameplay", "Language", detected_lang)
	
	# Input Defaults
	config.set_value("Input", "SummonKeycode", KEY_SPACE)
	config.set_value("Input", "ShopKeycode", KEY_T)
	config.set_value("Input", "SkillsKeycode", KEY_K)
	config.set_value("Input", "InventoryKeycode", KEY_I)
	config.set_value("Input", "UpgradesKeycode", KEY_U)
	config.set_value("Input", "SettingsKeycode", KEY_O)
	
	var err = config.save(path)
	if err != OK:
		push_error("BridgeManager: Failed to save default settings: " + str(err))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create default settings.cfg if it does not exist
	EnsureDefaultSettingsFile()
	
	# Initialize localization on all platforms
	InitializeLocalization()
	
	if not is_active():
		print("BridgeManager: Non-web standalone build detected. Playgama Bridge is disabled.")
		return
	
	if Bridge != null:
		Bridge.advertisement.interstitial_state_changed.connect(OnInterstitialStateChanged)
		Bridge.advertisement.rewarded_state_changed.connect(OnRewardedStateChanged)
		
		# Connect platform audio and pause state changes (Yandex Games focus loss / tab switch compliance)
		if Bridge.platform != null:
			if not Bridge.platform.audio_state_changed.is_connected(OnPlatformAudioStateChanged):
				Bridge.platform.audio_state_changed.connect(OnPlatformAudioStateChanged)
			if not Bridge.platform.pause_state_changed.is_connected(OnPlatformPauseStateChanged):
				Bridge.platform.pause_state_changed.connect(OnPlatformPauseStateChanged)
			if not Bridge.platform.is_audio_enabled:
				_apply_focus_mute(true)
		
		# Send game_ready to platform (required for publishing)
		Bridge.platform.send_message(Bridge.PlatformMessage.GAME_READY)
		print("BridgeManager: Connected to Playgama Bridge. Platform: ", Bridge.platform.id)
	else:
		push_warning("BridgeManager: Playgama Bridge autoload not found.")

func OnPlatformAudioStateChanged(is_enabled: bool) -> void:
	print("BridgeManager: Platform audio_state_changed: is_enabled=", is_enabled)
	_apply_focus_mute(not is_enabled)

func OnPlatformPauseStateChanged(is_paused: bool) -> void:
	print("BridgeManager: Platform pause_state_changed: is_paused=", is_paused)
	_apply_focus_pause(is_paused)

func _apply_focus_mute(mute: bool) -> void:
	var master_bus_idx = AudioServer.get_bus_index("Master")
	if master_bus_idx == -1:
		return
	if mute:
		if not _is_focus_lost:
			_is_muted_before_focus = AudioServer.is_bus_mute(master_bus_idx)
		AudioServer.set_bus_mute(master_bus_idx, true)
	else:
		if not _is_ad_active:
			AudioServer.set_bus_mute(master_bus_idx, _is_muted_before_focus)

func _apply_focus_pause(pause: bool) -> void:
	if pause:
		if not _is_focus_lost:
			_was_paused_before_focus = get_tree().paused
			_is_focus_lost = true
		get_tree().paused = true
	else:
		_is_focus_lost = false
		if not _is_ad_active:
			get_tree().paused = _was_paused_before_focus

func _notification(what: int) -> void:
	if not is_active():
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_apply_focus_mute(true)
			_apply_focus_pause(true)
		NOTIFICATION_APPLICATION_FOCUS_IN:
			if Bridge != null and Bridge.platform != null and not Bridge.platform.is_audio_enabled:
				return
			_apply_focus_mute(false)
			_apply_focus_pause(false)

func _resolve_locale_code(raw_code: String) -> String:
	if raw_code == null or raw_code.is_empty():
		return ""
	var code = raw_code.left(2).to_lower()
	if code in ["ru", "be", "uk", "kk", "uz", "ky", "tg", "az", "hy", "ka"]:
		return "ru"
	elif code == "tr":
		return "tr"
	elif code == "en":
		return "en"
	return "en"

func InitializeLocalization() -> void:
	# 0. Load translations programmatically to ensure they are registered on all platforms
	var locales = ["ru", "en", "tr"]
	for loc in locales:
		var path = "res://src/core/localization." + loc + ".translation"
		if ResourceLoader.exists(path):
			var trans = load(path)
			if trans != null:
				TranslationServer.add_translation(trans)
	
	var lang = ""
	
	# 1. Сохранённый выбор игрока всегда важнее языка платформы.
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var savedLang = str(config.get_value("Gameplay", "Language", "")).left(2).to_lower()
		if savedLang in locales:
			lang = savedLang

	# 2. Язык платформы используется только при первом запуске без сохранённого выбора.
	if lang == "" and is_active() and Bridge != null and Bridge.platform != null:
		var platform_lang = Bridge.platform.language
		var resolved = _resolve_locale_code(platform_lang)
		if not resolved.is_empty():
			lang = resolved
			print("BridgeManager: Detected platform language: ", lang)
			
	# 3. Если язык всё ещё не определён, используем системную локаль.
	if lang == "":
		var system_locale = TranslationServer.get_locale()
		var resolved = _resolve_locale_code(system_locale)
		lang = resolved if not resolved.is_empty() else "ru"
			
	TranslationServer.set_locale(lang)
	print("BridgeManager: Settled locale to: ", lang)
	print("BridgeManager: Loaded locales: ", TranslationServer.get_loaded_locales())

func OnInterstitialStateChanged(state: String) -> void:
	print("BridgeManager: Interstitial ad state changed to: ", state)
	match state:
		"opened":
			_handle_ad_opened()
		"closed", "failed":
			_handle_ad_closed()

func OnRewardedStateChanged(state: String) -> void:
	print("BridgeManager: Rewarded ad state changed to: ", state)
	match state:
		"opened":
			_handle_ad_opened()
		"closed", "failed":
			_handle_ad_closed()

func _handle_ad_opened() -> void:
	ad_opened.emit()
	_is_ad_active = true
	_was_paused_before_ad = get_tree().paused
	get_tree().paused = true
	
	# Mute master audio bus
	var master_bus_idx = AudioServer.get_bus_index("Master")
	if master_bus_idx != -1:
		_is_muted_before_ad = AudioServer.is_bus_mute(master_bus_idx)
		AudioServer.set_bus_mute(master_bus_idx, true)

func _handle_ad_closed() -> void:
	ad_closed.emit()
	_is_ad_active = false
	if not _is_focus_lost:
		get_tree().paused = _was_paused_before_ad
		
		# Restore audio mute state
		var master_bus_idx = AudioServer.get_bus_index("Master")
		if master_bus_idx != -1:
			AudioServer.set_bus_mute(master_bus_idx, _is_muted_before_ad)

# Public Helpers

func ShowInterstitial() -> void:
	if Bridge != null and Bridge.advertisement != null:
		if Bridge.advertisement.is_interstitial_supported:
			Bridge.advertisement.show_interstitial()
		else:
			print("BridgeManager: Interstitial ads not supported on this platform.")
	else:
		print("BridgeManager: Bridge not available.")

func ShowRewarded(callback: Callable) -> void:
	if Bridge == null or Bridge.advertisement == null or not Bridge.advertisement.is_rewarded_supported:
		print("BridgeManager: Rewarded ads not supported or available.")
		callback.call(false)
		return

	var connection = [null]
	connection[0] = func(state: String):
		if state == "rewarded":
			callback.call(true)
		elif state == "closed" or state == "failed":
			if Bridge.advertisement.rewarded_state_changed.is_connected(connection[0]):
				Bridge.advertisement.rewarded_state_changed.disconnect(connection[0])
	
	Bridge.advertisement.rewarded_state_changed.connect(connection[0])
	Bridge.advertisement.show_rewarded()

func RequestReview() -> void:
	if not is_active() or Bridge == null or Bridge.social == null:
		return
	if Bridge.social.is_rate_supported:
		print("BridgeManager: Requesting platform review/rating prompt...")
		Bridge.social.rate(func(success: bool):
			print("BridgeManager: Rate prompt result: ", success)
		)
	else:
		print("BridgeManager: Rate prompt not supported on this platform.")

func AddToHomeScreen(callback: Callable = Callable()) -> void:
	if not is_active() or Bridge == null or Bridge.social == null:
		if callback.is_valid():
			callback.call(false)
		return
	if Bridge.social.is_add_to_home_screen_supported:
		print("BridgeManager: Requesting add to home screen...")
		Bridge.social.add_to_home_screen(func(success: bool):
			print("BridgeManager: Add to home screen result: ", success)
			if callback.is_valid():
				callback.call(success)
		)
	else:
		print("BridgeManager: Add to home screen not supported on this platform.")
		if callback.is_valid():
			callback.call(false)

func IsAddToHomeScreenSupported() -> bool:
	if not is_active() or Bridge == null or Bridge.social == null:
		return false
	return Bridge.social.is_add_to_home_screen_supported

func SetLeaderboardScore(leaderboard_id: String, score: int) -> void:
	if not is_active() or Bridge == null or Bridge.leaderboards == null:
		return
	Bridge.leaderboards.set_score(leaderboard_id, score, func(success: bool):
		print("BridgeManager: Leaderboard score (", leaderboard_id, "=", score, ") updated: ", success)
	)
