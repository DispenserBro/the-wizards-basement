class_name SettingsUI
extends PanelContainer

signal compact_mode_toggled(enabled: bool)


var _musicSlider: HSlider
var _sfxSlider: HSlider
var _resolutionDropdown: OptionButton
var _scaleDropdown: OptionButton
var _fullscreenCheckbox: CheckBox
var _tutorialCheckbox: CheckBox
var _compactCheckbox: CheckBox
var _languageDropdown: OptionButton
var _rebindBtn: Button
var _rebindShopBtn: Button
var _rebindSkillsBtn: Button
var _rebindInventoryBtn: Button
var _rebindUpgradesBtn: Button
var _rebindSettingsBtn: Button
var _saveBtn: Button
var _resetConfirmPanel: PanelContainer

var _player: Player
var _isWaitingForKey: bool = false
var _activeRebindAction: String = ""

var _resolutions: Array[Vector2i] = [
    Vector2i(640, 360),
    Vector2i(960, 540),
    Vector2i(1152, 648),
    Vector2i(1280, 720),
    Vector2i(1600, 900),
    Vector2i(1920, 1080)
]

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    grow_horizontal = GrowDirection.GROW_DIRECTION_BOTH
    grow_vertical = GrowDirection.GROW_DIRECTION_BOTH

    var window = get_window()
    if window != null:
        window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
        window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
        window.content_scale_size = Vector2i(1152, 648)

    var closeBtn = %CloseButton
    closeBtn.pressed.connect(func(): visible = false)

    var grid = %Grid
    var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")

    var scroll = %Scroll
    StyleScrollbar(scroll.get_v_scroll_bar())

    EnsureAudioBusesExist()

    # --- Audio Settings ---
    AddCategoryHeader(grid, tr("ЗВУК"), font)

    AddLabel(grid, tr("Музыка:"), font)
    _musicSlider = HSlider.new()
    _musicSlider.min_value = 0
    _musicSlider.max_value = 100
    _musicSlider.value = 80
    _musicSlider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _musicSlider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    StyleSlider(_musicSlider)
    _musicSlider.value_changed.connect(func(val): ApplyVolume("Music", val))
    grid.add_child(_musicSlider)

    AddLabel(grid, tr("Звуковые эффекты:"), font)
    _sfxSlider = HSlider.new()
    _sfxSlider.min_value = 0
    _sfxSlider.max_value = 100
    _sfxSlider.value = 80
    _sfxSlider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _sfxSlider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    StyleSlider(_sfxSlider)
    _sfxSlider.value_changed.connect(func(val): ApplyVolume("SFX", val))
    grid.add_child(_sfxSlider)

    # --- Graphics Settings ---
    AddCategoryHeader(grid, tr("ГРАФИКА"), font)

    AddLabel(grid, tr("Разрешение:"), font)
    _resolutionDropdown = OptionButton.new()
    _resolutionDropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    StyleButton(_resolutionDropdown, font)
    for res in _resolutions:
        _resolutionDropdown.add_item(str(res.x) + "x" + str(res.y))
    
    var popup = _resolutionDropdown.get_popup()
    if popup != null and font != null:
        popup.add_theme_font_override("font", font)
        popup.add_theme_font_size_override("font_size", 18)
    
    _resolutionDropdown.item_selected.connect(OnResolutionSelected)
    grid.add_child(_resolutionDropdown)

    AddLabel(grid, tr("Полноэкранный режим:"), font)
    _fullscreenCheckbox = CheckBox.new()
    _fullscreenCheckbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    StyleCheckbox(_fullscreenCheckbox)
    _fullscreenCheckbox.toggled.connect(ApplyFullscreen)
    grid.add_child(_fullscreenCheckbox)

    AddLabel(grid, tr("Масштаб интерфейса:"), font)
    _scaleDropdown = OptionButton.new()
    _scaleDropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    StyleButton(_scaleDropdown, font)
    _scaleDropdown.add_item("100%")
    _scaleDropdown.add_item("125%")
    _scaleDropdown.add_item("150%")
    _scaleDropdown.add_item("175%")
    _scaleDropdown.add_item("200%")
    
    var scalePopup = _scaleDropdown.get_popup()
    if scalePopup != null and font != null:
        scalePopup.add_theme_font_override("font", font)
        scalePopup.add_theme_font_size_override("font_size", 18)
    
    _scaleDropdown.item_selected.connect(OnScaleSelected)
    grid.add_child(_scaleDropdown)

    # --- Gameplay Settings ---
    AddCategoryHeader(grid, tr("ГЕЙМПЛЕЙ"), font)

    _tutorialCheckbox = CheckBox.new()
    _tutorialCheckbox.button_pressed = true
    _tutorialCheckbox.focus_mode = Control.FOCUS_NONE
    _tutorialCheckbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    StyleCheckbox(_tutorialCheckbox)
    _tutorialCheckbox.toggled.connect(OnTutorialToggled)

    _compactCheckbox = CheckBox.new()
    _compactCheckbox.name = "CompactModeCheckbox"
    _compactCheckbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    StyleCheckbox(_compactCheckbox)
    _compactCheckbox.toggled.connect(OnCompactToggled)

    if not OS.has_feature("web"):
        AddLabel(grid, tr("Компактный режим:"), font)
        grid.add_child(_compactCheckbox)

    _languageDropdown = OptionButton.new()
    _languageDropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    StyleButton(_languageDropdown, font)
    _languageDropdown.add_item(tr("Русский"))
    _languageDropdown.add_item(tr("English"))
    _languageDropdown.add_item(tr("Türkçe"))
    
    var langPopup = _languageDropdown.get_popup()
    if langPopup != null and font != null:
        langPopup.add_theme_font_override("font", font)
        langPopup.add_theme_font_size_override("font_size", 18)
        
    _languageDropdown.item_selected.connect(OnLanguageSelected)
    
    # Pre-select current language in dropdown
    var current_lang = TranslationServer.get_locale().left(2).to_lower()
    match current_lang:
        "ru": _languageDropdown.selected = 0
        "en": _languageDropdown.selected = 1
        "tr": _languageDropdown.selected = 2
        _: _languageDropdown.selected = 1
        
    AddLabel(grid, tr("Язык:"), font)
    grid.add_child(_languageDropdown)

    var bridge = get_node_or_null("/root/BridgeManager")
    if bridge != null and bridge.has_method("IsAddToHomeScreenSupported") and bridge.IsAddToHomeScreenSupported():
        AddLabel(grid, tr("SETTINGS_SHORTCUT_LABEL"), font)
        var shortcutBtn = Button.new()
        shortcutBtn.text = tr("SETTINGS_ADD_SHORTCUT")
        shortcutBtn.custom_minimum_size = Vector2(0, 44)
        StyleButton(shortcutBtn, font)
        shortcutBtn.pressed.connect(func():
            bridge.AddToHomeScreen(func(success: bool):
                if success:
                    shortcutBtn.text = tr("SHORTCUT_ADDED")
                    shortcutBtn.disabled = true
            )
        )
        grid.add_child(shortcutBtn)

    # --- Controls Rebind ---
    AddCategoryHeader(grid, tr("УПРАВЛЕНИЕ"), font)

    AddLabel(grid, tr("Призыв противников:"), font)
    _rebindBtn = Button.new()
    _rebindBtn.text = tr("Пробел")
    _rebindBtn.custom_minimum_size = Vector2(0, 44)
    StyleButton(_rebindBtn, font)
    _rebindBtn.pressed.connect(func(): StartRebinding("summon_enemy"))
    _rebindBtn.focus_mode = Control.FOCUS_NONE
    grid.add_child(_rebindBtn)

    AddLabel(grid, tr("Открыть магазин:"), font)
    _rebindShopBtn = Button.new()
    _rebindShopBtn.text = "T"
    _rebindShopBtn.custom_minimum_size = Vector2(0, 44)
    StyleButton(_rebindShopBtn, font)
    _rebindShopBtn.pressed.connect(func(): StartRebinding("open_shop"))
    _rebindShopBtn.focus_mode = Control.FOCUS_NONE
    grid.add_child(_rebindShopBtn)

    AddLabel(grid, tr("Открыть навыки:"), font)
    _rebindSkillsBtn = Button.new()
    _rebindSkillsBtn.text = "K"
    _rebindSkillsBtn.custom_minimum_size = Vector2(0, 44)
    StyleButton(_rebindSkillsBtn, font)
    _rebindSkillsBtn.pressed.connect(func(): StartRebinding("open_skills"))
    _rebindSkillsBtn.focus_mode = Control.FOCUS_NONE
    grid.add_child(_rebindSkillsBtn)

    AddLabel(grid, tr("Открыть инвентарь:"), font)
    _rebindInventoryBtn = Button.new()
    _rebindInventoryBtn.text = "I"
    _rebindInventoryBtn.custom_minimum_size = Vector2(0, 44)
    StyleButton(_rebindInventoryBtn, font)
    _rebindInventoryBtn.pressed.connect(func(): StartRebinding("open_inventory"))
    _rebindInventoryBtn.focus_mode = Control.FOCUS_NONE
    grid.add_child(_rebindInventoryBtn)

    AddLabel(grid, tr("Открыть мастерскую:"), font)
    _rebindUpgradesBtn = Button.new()
    _rebindUpgradesBtn.text = "U"
    _rebindUpgradesBtn.custom_minimum_size = Vector2(0, 44)
    StyleButton(_rebindUpgradesBtn, font)
    _rebindUpgradesBtn.pressed.connect(func(): StartRebinding("open_upgrades"))
    _rebindUpgradesBtn.focus_mode = Control.FOCUS_NONE
    grid.add_child(_rebindUpgradesBtn)

    AddLabel(grid, tr("Открыть настройки:"), font)
    _rebindSettingsBtn = Button.new()
    _rebindSettingsBtn.text = "O"
    _rebindSettingsBtn.custom_minimum_size = Vector2(0, 44)
    StyleButton(_rebindSettingsBtn, font)
    _rebindSettingsBtn.pressed.connect(func(): StartRebinding("open_settings"))
    _rebindSettingsBtn.focus_mode = Control.FOCUS_NONE
    grid.add_child(_rebindSettingsBtn)

    # Save Button
    _saveBtn = %SaveBtn
    if _saveBtn != null:
        _saveBtn.hide()

    # Reset progress setup
    var resetBtn = %ResetBtn
    _resetConfirmPanel = %ResetConfirmPanel
    resetBtn.pressed.connect(func(): _resetConfirmPanel.visible = true)

    var yesBtn = %YesBtn
    yesBtn.pressed.connect(ResetProgress)

    var noBtn = %NoBtn
    noBtn.pressed.connect(func(): _resetConfirmPanel.visible = false)

    # Load configurations
    LoadSettings()

func AddCategoryHeader(container: GridContainer, text: String, font: Font) -> void:
    var spacing = Control.new()
    spacing.custom_minimum_size = Vector2(0, 8)
    spacing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var header = Label.new()
    header.text = text
    if font != null:
        header.add_theme_font_override("font", font)
    header.add_theme_font_size_override("font_size", 22)
    header.add_theme_color_override("font_color", Color.KHAKI)

    container.add_child(spacing)
    container.add_child(Control.new())
    container.add_child(header)
    container.add_child(Control.new())

func AddLabel(container: GridContainer, text: String, font: Font) -> void:
    var lbl = Label.new()
    lbl.text = text
    lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    if font != null:
        lbl.add_theme_font_override("font", font)
    lbl.add_theme_font_size_override("font_size", 18)
    container.add_child(lbl)

func StyleButton(button: Button, font: Font) -> void:
    if font != null:
        button.add_theme_font_override("font", font)
    button.add_theme_font_size_override("font_size", 18)

    var normalTex = load("res://external/fantasy_pixelart_ui/buttons/wood_button_normal.png")
    var pressedTex = load("res://external/fantasy_pixelart_ui/buttons/wood_button_pressed.png")

    var btnStyleNormal = StyleBoxTexture.new()
    btnStyleNormal.texture = normalTex
    btnStyleNormal.texture_margin_left = 6
    btnStyleNormal.texture_margin_top = 6
    btnStyleNormal.texture_margin_right = 6
    btnStyleNormal.texture_margin_bottom = 6

    var btnStyleHover = StyleBoxTexture.new()
    btnStyleHover.texture = normalTex
    btnStyleHover.texture_margin_left = 6
    btnStyleHover.texture_margin_top = 6
    btnStyleHover.texture_margin_right = 6
    btnStyleHover.texture_margin_bottom = 6
    btnStyleHover.modulate_color = Color(1.15, 1.15, 1.15, 1.0)

    var btnStylePressed = StyleBoxTexture.new()
    btnStylePressed.texture = pressedTex
    btnStylePressed.texture_margin_left = 6
    btnStylePressed.texture_margin_top = 6
    btnStylePressed.texture_margin_right = 6
    btnStylePressed.texture_margin_bottom = 6

    var btnStyleDisabled = StyleBoxTexture.new()
    btnStyleDisabled.texture = pressedTex
    btnStyleDisabled.texture_margin_left = 6
    btnStyleDisabled.texture_margin_top = 6
    btnStyleDisabled.texture_margin_right = 6
    btnStyleDisabled.texture_margin_bottom = 6
    btnStyleDisabled.modulate_color = Color(0.5, 0.5, 0.5, 0.6)

    button.add_theme_stylebox_override("normal", btnStyleNormal)
    button.add_theme_stylebox_override("hover", btnStyleHover)
    button.add_theme_stylebox_override("pressed", btnStylePressed)
    button.add_theme_stylebox_override("disabled", btnStyleDisabled)
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func StyleCheckbox(checkbox: CheckBox) -> void:
    var checkedTex = load("res://external/fantasy_pixelart_ui/checkboxes/wood_checkbox_checked.png")
    var uncheckedTex = load("res://external/fantasy_pixelart_ui/checkboxes/wood_checkbox_unchecked.png")

    var scaledChecked = ScalePixelArtTexture(checkedTex, 2)
    var scaledUnchecked = ScalePixelArtTexture(uncheckedTex, 2)

    checkbox.add_theme_icon_override("checked", scaledChecked)
    checkbox.add_theme_icon_override("unchecked", scaledUnchecked)
    checkbox.add_theme_icon_override("checked_disabled", scaledChecked)
    checkbox.add_theme_icon_override("unchecked_disabled", scaledUnchecked)

func StyleSlider(slider: HSlider) -> void:
    var grabberNormal = load("res://external/fantasy_pixelart_ui/sliders/wood_grabber_normal.png")
    var grabberHighlight = load("res://external/fantasy_pixelart_ui/sliders/wood_grabber_pressed.png")

    var scaledGrabberNormal = ScalePixelArtTexture(grabberNormal, 2)
    var scaledGrabberHighlight = ScalePixelArtTexture(grabberHighlight, 2)

    slider.add_theme_icon_override("grabber", scaledGrabberNormal)
    slider.add_theme_icon_override("grabber_highlight", scaledGrabberHighlight)

    var sliderStyle = StyleBoxTexture.new()
    sliderStyle.texture = load("res://external/fantasy_pixelart_ui/sliders/wood_slider_empty.png")
    sliderStyle.texture_margin_left = 2
    sliderStyle.texture_margin_top = 2
    sliderStyle.texture_margin_right = 2
    sliderStyle.texture_margin_bottom = 2
    sliderStyle.content_margin_top = 10
    sliderStyle.content_margin_bottom = 10

    var fillStyle = StyleBoxTexture.new()
    fillStyle.texture = load("res://external/fantasy_pixelart_ui/sliders/wood_slider_filled.png")
    fillStyle.texture_margin_left = 2
    fillStyle.texture_margin_top = 2
    fillStyle.texture_margin_right = 2
    fillStyle.texture_margin_bottom = 2

    slider.add_theme_stylebox_override("slider", sliderStyle)
    slider.add_theme_stylebox_override("grabber_area", fillStyle)
    slider.add_theme_stylebox_override("grabber_area_highlight", fillStyle)

func ScalePixelArtTexture(original: Texture2D, scaleFactor: int) -> Texture2D:
    if original == null:
        return null
    var img = original.get_image()
    if img == null:
        return original
    img.resize(img.get_width() * scaleFactor, img.get_height() * scaleFactor, Image.INTERPOLATE_NEAREST)
    return ImageTexture.create_from_image(img)

func StyleScrollbar(vsb: VScrollBar) -> void:
    vsb.custom_minimum_size = Vector2(12, 0)

    var trackTex = load("res://external/fantasy_pixelart_ui/scroll/wood_scrollbar.png")
    var grabberTex = load("res://external/fantasy_pixelart_ui/scroll/wood_scrollbar_grabber.png")

    var trackStyle = StyleBoxTexture.new()
    trackStyle.texture = trackTex
    trackStyle.texture_margin_left = 2
    trackStyle.texture_margin_top = 2
    trackStyle.texture_margin_right = 2
    trackStyle.texture_margin_bottom = 2

    var grabberStyle = StyleBoxTexture.new()
    grabberStyle.texture = grabberTex
    grabberStyle.texture_margin_left = 2
    grabberStyle.texture_margin_top = 2
    grabberStyle.texture_margin_right = 2
    grabberStyle.texture_margin_bottom = 2

    var grabberHover = StyleBoxTexture.new()
    grabberHover.texture = grabberTex
    grabberHover.texture_margin_left = 2
    grabberHover.texture_margin_top = 2
    grabberHover.texture_margin_right = 2
    grabberHover.texture_margin_bottom = 2
    grabberHover.modulate_color = Color(1.2, 1.2, 1.2, 1.0)

    vsb.add_theme_stylebox_override("scroll", trackStyle)
    vsb.add_theme_stylebox_override("grabber", grabberStyle)
    vsb.add_theme_stylebox_override("grabber_hover", grabberHover)
    vsb.add_theme_stylebox_override("grabber_highlight", grabberHover)
    vsb.add_theme_stylebox_override("grabber_pressed", grabberStyle)

func EnsureAudioBusesExist() -> void:
    var musicIndex = AudioServer.get_bus_index("Music")
    if musicIndex == -1:
        AudioServer.add_bus()
        musicIndex = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(musicIndex, "Music")
        AudioServer.set_bus_send(musicIndex, "Master")

    var sfxIndex = AudioServer.get_bus_index("SFX")
    if sfxIndex == -1:
        AudioServer.add_bus()
        sfxIndex = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(sfxIndex, "SFX")
        AudioServer.set_bus_send(sfxIndex, "Master")

func ApplyVolume(busName: String, sliderVal: float) -> void:
    var index = AudioServer.get_bus_index(busName)
    if index == -1:
        return

    if sliderVal <= 0.0:
        AudioServer.set_bus_mute(index, true)
    else:
        AudioServer.set_bus_mute(index, false)
        var db = error_to_db_val(sliderVal)
        AudioServer.set_bus_volume_db(index, db)

func error_to_db_val(val: float) -> float:
    return db_to_linear_fallback(val / 100.0)

func db_to_linear_fallback(linear: float) -> float:
    if linear <= 0.0:
        return -80.0
    return 20.0 * log(linear) / log(10.0)

func OnResolutionSelected(index: int) -> void:
    if index < 0 or index >= _resolutions.size():
        return
    var res = _resolutions[index]

    var window = get_window()
    if window.mode != Window.MODE_EXCLUSIVE_FULLSCREEN and window.mode != Window.MODE_FULLSCREEN:
        window.size = res
        var screenId = window.current_screen
        var screenRect = DisplayServer.screen_get_usable_rect(screenId)
        window.position = (screenRect.size - window.size) / 2

func ApplyFullscreen(enabled: bool) -> void:
    var window = get_window()
    window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if enabled else Window.MODE_WINDOWED

func OnScaleSelected(index: int) -> void:
    var scaleVal = 1.0
    match index:
        0: scaleVal = 1.0
        1: scaleVal = 1.25
        2: scaleVal = 1.5
        3: scaleVal = 1.75
        4: scaleVal = 2.0

    get_window().content_scale_factor = 1.0

    var currentScene = get_tree().current_scene
    if currentScene != null:
        if currentScene.has_method("SetUIScale"):
            currentScene.SetUIScale(scaleVal)
        else:
            var gameUI = currentScene.get_node_or_null("UI")
            if gameUI != null and is_instance_valid(gameUI) and gameUI.has_method("SetUIScale"):
                gameUI.SetUIScale(scaleVal)

func OnCompactToggled(enabled: bool) -> void:
    compact_mode_toggled.emit(enabled)

func OnLanguageSelected(index: int) -> void:
    var lang = "ru"
    match index:
        0: lang = "ru"
        1: lang = "en"
        2: lang = "tr"
    
    TranslationServer.set_locale(lang)
    
    # Save to config
    var config = ConfigFile.new()
    config.load("user://settings.cfg")
    config.set_value("Gameplay", "Language", lang)
    config.save("user://settings.cfg")
    
    # Reload scene to apply translation
    get_tree().reload_current_scene()

func SetCompactModeCheckboxSilent(enabled: bool) -> void:
    _compactCheckbox.set_pressed_no_signal(enabled)

func Init(player: Player) -> void:
    _player = player
    UpdateTutorialCheckbox()

func SetCompactMode(enabled: bool) -> void:
    custom_minimum_size = Vector2(352, 352) if enabled else Vector2(660, 500)

func UpdateTutorialCheckbox() -> void:
    if _player != null and _tutorialCheckbox != null:
        _tutorialCheckbox.set_pressed_no_signal(not _player.TutorialCompleted)

func OnTutorialToggled(buttonPressed: bool) -> void:
    if _player != null:
        _player.TutorialCompleted = not buttonPressed
        _player.SaveSettings()

func StartRebinding(actionName: String) -> void:
    _isWaitingForKey = true
    _activeRebindAction = actionName

    var activeBtn: Button = null
    match actionName:
        "summon_enemy": activeBtn = _rebindBtn
        "open_shop": activeBtn = _rebindShopBtn
        "open_skills": activeBtn = _rebindSkillsBtn
        "open_inventory": activeBtn = _rebindInventoryBtn
        "open_upgrades": activeBtn = _rebindUpgradesBtn
        "open_settings": activeBtn = _rebindSettingsBtn

    if activeBtn != null:
        activeBtn.icon = null
        activeBtn.text = tr("... Нажмите клавишу ...")
        activeBtn.release_focus()

func _input(event: InputEvent) -> void:
    if _isWaitingForKey and not _activeRebindAction.is_empty():
        get_viewport().set_input_as_handled()

        if event is InputEventKey and event.pressed:
            _isWaitingForKey = false

            if event.keycode != KEY_ESCAPE:
                InputMap.action_erase_events(_activeRebindAction)
                var newEvent = event.duplicate() as InputEventKey
                newEvent.pressed = false
                InputMap.action_add_event(_activeRebindAction, newEvent)
                SaveSettings()

            UpdateAllRebindButtonsText()
            _activeRebindAction = ""

func UpdateAllRebindButtonsText() -> void:
    UpdateSingleRebindButtonText("summon_enemy", _rebindBtn)
    UpdateSingleRebindButtonText("open_shop", _rebindShopBtn)
    UpdateSingleRebindButtonText("open_skills", _rebindSkillsBtn)
    UpdateSingleRebindButtonText("open_inventory", _rebindInventoryBtn)
    UpdateSingleRebindButtonText("open_upgrades", _rebindUpgradesBtn)
    UpdateSingleRebindButtonText("open_settings", _rebindSettingsBtn)

func UpdateSingleRebindButtonText(actionName: String, button: Button) -> void:
    if button == null:
        return

    var events = InputMap.action_get_events(actionName)
    if events.size() > 0 and events[0] is InputEventKey:
        var keyEvent = events[0] as InputEventKey
        var code = keyEvent.keycode if keyEvent.keycode != KEY_NONE else keyEvent.physical_keycode
        var iconTex = GetKeyIconTexture(code)
        if iconTex != null:
            button.icon = iconTex
            button.text = ""
            button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        else:
            button.icon = null
            button.text = keyEvent.as_text()
    else:
        button.icon = null
        button.text = tr("[Не назначено]")

func GetKeyIconTexture(keycode: Key) -> Texture2D:
    var keyName = ""
    match keycode:
        KEY_SPACE:
            keyName = "space_md_4x"
        KEY_ENTER:
            keyName = "enter_4x"
        KEY_ESCAPE:
            keyName = "escape_4x"
        KEY_TAB:
            keyName = "tab_4x"
        KEY_CTRL:
            keyName = "ctrl_4x"
        KEY_SHIFT:
            keyName = "shift_4x"
        KEY_ALT:
            keyName = "alt_4x"
        KEY_BACKSPACE:
            keyName = "backspace_4x"
        KEY_UP:
            keyName = "arrow-up_4x"
        KEY_DOWN:
            keyName = "arrow-down_4x"
        KEY_LEFT:
            keyName = "arrow-left_4x"
        KEY_RIGHT:
            keyName = "arrow-right_4x"
        _:
            var nameStr = OS.get_keycode_string(keycode).to_lower()
            if nameStr.length() == 1 and ((nameStr >= "a" and nameStr <= "z") or (nameStr >= "0" and nameStr <= "9")):
                keyName = nameStr + "_4x"

    if not keyName.is_empty():
        var path = "res://external/vector-keyboard-controls/Keyboard Keys/Outline/PNG_4x/" + keyName + ".png"
        if ResourceLoader.exists(path):
            var tex = load(path) as Texture2D
            return ScaleTextureToHeight(tex, 28)
    return null

func ScaleTextureToHeight(original: Texture2D, targetHeight: int) -> Texture2D:
    if original == null:
        return null
    var img = original.get_image()
    if img == null:
        return original

    var aspect = float(img.get_width()) / img.get_height()
    var targetWidth = roundi(targetHeight * aspect)

    img.resize(targetWidth, targetHeight, Image.INTERPOLATE_NEAREST)
    return ImageTexture.create_from_image(img)

func SaveSettings() -> void:
    if _musicSlider == null or not is_instance_valid(_musicSlider):
        return
    var config = ConfigFile.new()
    config.load("user://settings.cfg")
    config.set_value("Audio", "MusicVolume", _musicSlider.value)
    config.set_value("Audio", "SfxVolume", _sfxSlider.value)
    config.set_value("Video", "ResolutionIndex", _resolutionDropdown.selected)
    config.set_value("Video", "Fullscreen", _fullscreenCheckbox.button_pressed)
    config.set_value("Video", "ScaleIndex", _scaleDropdown.selected)
    config.set_value("Gameplay", "ShowTutorial", _tutorialCheckbox.button_pressed)

    var events = InputMap.action_get_events("summon_enemy")
    if events.size() > 0 and events[0] is InputEventKey:
        config.set_value("Input", "SummonKeycode", events[0].keycode)

    var shopEvents = InputMap.action_get_events("open_shop")
    if shopEvents.size() > 0 and shopEvents[0] is InputEventKey:
        config.set_value("Input", "ShopKeycode", shopEvents[0].keycode)

    var skillsEvents = InputMap.action_get_events("open_skills")
    if skillsEvents.size() > 0 and skillsEvents[0] is InputEventKey:
        config.set_value("Input", "SkillsKeycode", skillsEvents[0].keycode)

    var invEvents = InputMap.action_get_events("open_inventory")
    if invEvents.size() > 0 and invEvents[0] is InputEventKey:
        config.set_value("Input", "InventoryKeycode", invEvents[0].keycode)

    var upgEvents = InputMap.action_get_events("open_upgrades")
    if upgEvents.size() > 0 and upgEvents[0] is InputEventKey:
        config.set_value("Input", "UpgradesKeycode", upgEvents[0].keycode)

    var setEvents = InputMap.action_get_events("open_settings")
    if setEvents.size() > 0 and setEvents[0] is InputEventKey:
        config.set_value("Input", "SettingsKeycode", setEvents[0].keycode)

    config.save("user://settings.cfg")

func LoadSettings() -> void:
    if not InputMap.has_action("summon_enemy"):
        InputMap.add_action("summon_enemy")
        var spaceKey = InputEventKey.new()
        spaceKey.keycode = KEY_SPACE
        InputMap.action_add_event("summon_enemy", spaceKey)

    if not InputMap.has_action("open_shop"):
        InputMap.add_action("open_shop")
        var tKey = InputEventKey.new()
        tKey.keycode = KEY_T
        InputMap.action_add_event("open_shop", tKey)

    if not InputMap.has_action("open_skills"):
        InputMap.add_action("open_skills")
        var kKey = InputEventKey.new()
        kKey.keycode = KEY_K
        InputMap.action_add_event("open_skills", kKey)

    if not InputMap.has_action("open_inventory"):
        InputMap.add_action("open_inventory")
        var iKey = InputEventKey.new()
        iKey.keycode = KEY_I
        InputMap.action_add_event("open_inventory", iKey)

    if not InputMap.has_action("open_upgrades"):
        InputMap.add_action("open_upgrades")
        var uKey = InputEventKey.new()
        uKey.keycode = KEY_U
        InputMap.action_add_event("open_upgrades", uKey)

    if not InputMap.has_action("open_settings"):
        InputMap.add_action("open_settings")
        var oKey = InputEventKey.new()
        oKey.keycode = KEY_O
        InputMap.action_add_event("open_settings", oKey)

    var config = ConfigFile.new()
    if config.load("user://settings.cfg") == OK:
        var musicVol = config.get_value("Audio", "MusicVolume", 20.0)
        var sfxVol = config.get_value("Audio", "SfxVolume", 50.0)
        _musicSlider.value = musicVol
        _sfxSlider.value = sfxVol

        ApplyVolume("Music", musicVol)
        ApplyVolume("SFX", sfxVol)

        var resIdx = config.get_value("Video", "ResolutionIndex", 3)
        _resolutionDropdown.selected = resIdx
        OnResolutionSelected(resIdx)

        var fullscreen = config.get_value("Video", "Fullscreen", false)
        _fullscreenCheckbox.button_pressed = fullscreen
        ApplyFullscreen(fullscreen)

        var scaleIdx = config.get_value("Video", "ScaleIndex", 0)
        _scaleDropdown.selected = scaleIdx
        OnScaleSelected(scaleIdx)

        _tutorialCheckbox.button_pressed = config.get_value("Gameplay", "ShowTutorial", true)

        var keycode = config.get_value("Input", "SummonKeycode", KEY_SPACE)
        var keyEvent = InputEventKey.new()
        keyEvent.keycode = keycode
        InputMap.action_erase_events("summon_enemy")
        InputMap.action_add_event("summon_enemy", keyEvent)

        var shopKeycode = config.get_value("Input", "ShopKeycode", KEY_T)
        var shopKeyEvent = InputEventKey.new()
        shopKeyEvent.keycode = shopKeycode
        InputMap.action_erase_events("open_shop")
        InputMap.action_add_event("open_shop", shopKeyEvent)

        var skillsKeycode = config.get_value("Input", "SkillsKeycode", KEY_K)
        var skillsKeyEvent = InputEventKey.new()
        skillsKeyEvent.keycode = skillsKeycode
        InputMap.action_erase_events("open_skills")
        InputMap.action_add_event("open_skills", skillsKeyEvent)

        var invKeycode = config.get_value("Input", "InventoryKeycode", KEY_I)
        var invKeyEvent = InputEventKey.new()
        invKeyEvent.keycode = invKeycode
        InputMap.action_erase_events("open_inventory")
        InputMap.action_add_event("open_inventory", invKeyEvent)

        var upgKeycode = config.get_value("Input", "UpgradesKeycode", KEY_U)
        var upgKeyEvent = InputEventKey.new()
        upgKeyEvent.keycode = upgKeycode
        InputMap.action_erase_events("open_upgrades")
        InputMap.action_add_event("open_upgrades", upgKeyEvent)

        var setKeycode = config.get_value("Input", "SettingsKeycode", KEY_O)
        var setKeyEvent = InputEventKey.new()
        setKeyEvent.keycode = setKeycode
        InputMap.action_erase_events("open_settings")
        InputMap.action_add_event("open_settings", setKeyEvent)

    UpdateAllRebindButtonsText()

func _notification(what: int) -> void:
    if what == NOTIFICATION_VISIBILITY_CHANGED:
        if not visible:
            SaveSettings()
            if _resetConfirmPanel != null:
                _resetConfirmPanel.visible = false

func _exit_tree() -> void:
    SaveSettings()

func ResetProgress() -> void:
    _resetConfirmPanel.visible = false

    const settingsPath = "user://settings.cfg"
    if FileAccess.file_exists(settingsPath):
        var config = ConfigFile.new()
        var loadError = config.load(settingsPath)
        if loadError != OK:
            push_error("Не удалось загрузить настройки перед сбросом прогресса: " + str(loadError))
            return

        config.erase_section("Progression")
        var saveError = config.save(settingsPath)
        if saveError != OK:
            push_error("Не удалось сохранить настройки после сброса прогресса: " + str(saveError))
            return

    # Delete cloud save using Playgama Bridge
    if get_node_or_null("/root/BridgeManager") != null and get_node("/root/BridgeManager").is_active() and Bridge != null and Bridge.storage != null:
        Bridge.storage.delete("player_progress")

    get_tree().reload_current_scene()
