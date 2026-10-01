class_name MainMenu
extends Node2D

var _startButton: Button
var _settingsButton: Button
var _exitButton: Button
var _settingsUI: SettingsUI
var _uiRoot: Control
var _menuVBox: VBoxContainer
var _titleBackground: NinePatchRect
var _compactRestoreButton: Button
var _currentUiScale: float = 1.0
var _settingsPreferredSize: Vector2 = Vector2.ZERO
var _isCompactModeActive: bool = false
const MenuSafeMargins = Vector2(32.0, 32.0)
const OversamplingWithScaleEnabled = 2

func _ready() -> void:
	_startButton = get_node("UI/ButtonsContainer/StartButton")
	_settingsButton = get_node("UI/ButtonsContainer/SettingsButton")
	_exitButton = get_node("UI/ButtonsContainer/ExitButton")

	_startButton.pressed.connect(OnStartButtonPressed)
	_settingsButton.pressed.connect(OnSettingsButtonPressed)
	_exitButton.pressed.connect(OnExitButtonPressed)

	var ui = get_node("UI")
	var root = Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	ResetRootLayout(root)

	_titleBackground = ui.get_node("TitleBackground")
	var buttonsContainer = ui.get_node("ButtonsContainer")

	ui.remove_child(_titleBackground)
	ui.remove_child(buttonsContainer)

	_titleBackground.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_titleBackground.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_titleBackground.grow_vertical = Control.GROW_DIRECTION_BOTH
	_titleBackground.custom_minimum_size = Vector2(560, 100)
	_titleBackground.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	buttonsContainer.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	buttonsContainer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	buttonsContainer.grow_vertical = Control.GROW_DIRECTION_BOTH
	buttonsContainer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var menuCenter = CenterContainer.new()
	menuCenter.name = "MenuCenter"
	menuCenter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(menuCenter)
	menuCenter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_menuVBox = VBoxContainer.new()
	_menuVBox.name = "MenuVBox"
	_menuVBox.add_theme_constant_override("separation", 24)
	menuCenter.add_child(_menuVBox)
	_menuVBox.add_child(_titleBackground)
	_menuVBox.add_child(buttonsContainer)

	_uiRoot = root
	_uiRoot.set("oversampling_with_scale", OversamplingWithScaleEnabled)
	CreateCompactRestoreButton()

	get_viewport().size_changed.connect(OnViewportSizeChanged)

	var config = ConfigFile.new()
	var scaleVal = 1.0
	if config.load("user://settings.cfg") == OK:
		var scaleIdx = config.get_value("Video", "ScaleIndex", 0)
		match scaleIdx:
			0: scaleVal = 1.0
			1: scaleVal = 1.25
			2: scaleVal = 1.5
			3: scaleVal = 1.75
			4: scaleVal = 2.0
	_currentUiScale = scaleVal
	SetUIScale(scaleVal)

	var settingsScene = load("res://src/ui/SettingsUI/SettingsUI.tscn") as PackedScene
	_settingsUI = settingsScene.instantiate() as SettingsUI
	_settingsUI.visible = false
	root.add_child(_settingsUI)
	_settingsUI.compact_mode_toggled.connect(OnCompactModeToggled)

	if CompactWindowSession.IsActive:
		EnterCompactModeFromPreviousScene()

func EnterCompactModeFromPreviousScene() -> void:
	OnCompactModeToggled(true)

func CreateCompactRestoreButton() -> void:
	_compactRestoreButton = Button.new()
	_compactRestoreButton.name = "CompactRestoreButton"
	_compactRestoreButton.text = tr("Развернуть")
	_compactRestoreButton.visible = false
	_compactRestoreButton.custom_minimum_size = Vector2(140.0, 44.0)
	_compactRestoreButton.focus_mode = Control.FOCUS_NONE
	_compactRestoreButton.z_index = 100

	_compactRestoreButton.add_theme_font_override("font", load("res://fonts/ithaca-font/Ithaca-LVB75.ttf"))
	_compactRestoreButton.add_theme_font_size_override("font_size", 20)
	_compactRestoreButton.add_theme_color_override("font_color", Color("e6d9bf"))
	_compactRestoreButton.add_theme_color_override("font_hover_color", Color("fff2d9"))
	
	for styleName in [ "normal", "hover", "pressed", "focus" ]:
		_compactRestoreButton.add_theme_stylebox_override(styleName, _settingsButton.get_theme_stylebox(styleName))

	_uiRoot.add_child(_compactRestoreButton)
	_compactRestoreButton.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_compactRestoreButton.offset_left = -148.0
	_compactRestoreButton.offset_top = 8.0
	_compactRestoreButton.offset_right = -8.0
	_compactRestoreButton.offset_bottom = 52.0
	_compactRestoreButton.pressed.connect(func(): OnCompactModeToggled(false))

func SetUIScale(scaleVal: float) -> void:
	_currentUiScale = clampf(scaleVal, 0.5, 2.0)
	if _uiRoot != null and is_instance_valid(_uiRoot):
		var screenSize = get_viewport().get_visible_rect().size
		var effectiveScale = GetEffectiveUiScale(_currentUiScale, screenSize)

		ResetRootLayout(_uiRoot)
		_uiRoot.size = screenSize / effectiveScale
		_uiRoot.scale = Vector2.ONE * effectiveScale

	if _settingsUI != null and _settingsUI.visible:
		CenterSettingsPanel()

func GetEffectiveUiScale(requestedScale: float, screenSize: Vector2) -> float:
	if _menuVBox == null or not is_instance_valid(_menuVBox):
		return requestedScale

	var requiredSize = _menuVBox.get_combined_minimum_size() + MenuSafeMargins
	if requiredSize.x <= 0.0 or requiredSize.y <= 0.0:
		return requestedScale

	var fitScale = minf(screenSize.x / requiredSize.x, screenSize.y / requiredSize.y)
	return clampf(minf(requestedScale, fitScale), 0.5, requestedScale)

func ResetRootLayout(root: Control) -> void:
	root.anchor_left = 0.0
	root.anchor_top = 0.0
	root.anchor_right = 0.0
	root.anchor_bottom = 0.0
	root.position = Vector2.ZERO
	root.pivot_offset = Vector2.ZERO

func OnViewportSizeChanged() -> void:
	SetUIScale(_currentUiScale)

func _exit_tree() -> void:
	get_viewport().size_changed.disconnect(OnViewportSizeChanged)

func OnStartButtonPressed() -> void:
	print("Start Game pressed")
	var gameScenePath = "res://src/scenes/Game/Game.tscn"
	if ResourceLoader.exists(gameScenePath):
		get_tree().change_scene_to_file(gameScenePath)
	else:
		var toast = get_node_or_null("/root/GodotxToast")
		if toast != null and toast.has_method("show"):
			toast.call("show", tr("Игра запускается!"))

func OnSettingsButtonPressed() -> void:
	if _settingsUI != null:
		_settingsUI.visible = not _settingsUI.visible
		if _settingsUI.visible:
			_settingsUI.SetCompactMode(_isCompactModeActive)
			CenterSettingsPanel()

func OnCompactModeToggled(enabled: bool) -> void:
	if OS.has_feature("web"):
		return
	if _isCompactModeActive == enabled:
		return

	var window = get_window()
	if window == null:
		return

	_isCompactModeActive = enabled
	if enabled:
		_settingsUI.visible = false
		_titleBackground.visible = false
		_compactRestoreButton.visible = true
		_settingsUI.SetCompactModeCheckboxSilent(true)

		CompactWindowSession.enter(window)
		SetUIScale(_currentUiScale)
	else:
		_settingsUI.visible = false
		_titleBackground.visible = true
		_compactRestoreButton.visible = false
		_settingsUI.SetCompactModeCheckboxSilent(false)
		CompactWindowSession.exit(window)
		SetUIScale(_currentUiScale)

func CenterSettingsPanel() -> void:
	if _settingsUI == null or not is_instance_valid(_settingsUI):
		return

	if _settingsPreferredSize == Vector2.ZERO:
		_settingsPreferredSize = _settingsUI.custom_minimum_size
		if _settingsPreferredSize == Vector2.ZERO:
			_settingsPreferredSize = _settingsUI.size
		if _settingsPreferredSize.x <= 0 or _settingsPreferredSize.y <= 0:
			_settingsPreferredSize = Vector2(660.0, 500.0)

	var sizeVal = _uiRoot.size if (_uiRoot != null and is_instance_valid(_uiRoot)) else get_viewport().get_visible_rect().size

	_settingsUI.custom_minimum_size = Vector2.ZERO
	_settingsUI.anchors_preset = Control.PRESET_TOP_LEFT

	var targetW = minf(_settingsPreferredSize.x, sizeVal.x * 0.95)
	var targetH = minf(_settingsPreferredSize.y, sizeVal.y * 0.95)
	_settingsUI.size = Vector2(targetW, targetH)

	var pos = ((sizeVal - _settingsUI.size) * 0.5).floor()
	_settingsUI.position = Vector2(maxf(0.0, pos.x), maxf(0.0, pos.y))

func OnExitButtonPressed() -> void:
	print("Exit pressed")
	get_tree().quit()
