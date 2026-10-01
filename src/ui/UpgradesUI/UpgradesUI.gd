class_name UpgradesUI
extends PanelContainer

var _upgradesContainer: VBoxContainer
var _scroll: ScrollContainer
var _contentMargin: MarginContainer
var _headerLayout: HBoxContainer
var _titleLabel: Label
var _leftSpacer: Control
var _closeButton: TextureButton
var _player: Player
var _isCompactModeActive: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grow_horizontal = GrowDirection.GROW_DIRECTION_BOTH
	grow_vertical = GrowDirection.GROW_DIRECTION_BOTH

	_upgradesContainer = %UpgradesContainer
	_headerLayout = get_node("MainLayout/HeaderLayout")
	_titleLabel = get_node("MainLayout/HeaderLayout/TitleLabel")
	_leftSpacer = get_node("MainLayout/HeaderLayout/LeftSpacer")
	_closeButton = %CloseButton
	_closeButton.pressed.connect(func(): visible = false)

	_scroll = %Scroll
	_contentMargin = get_node("MainLayout/ContentVBox/InnerPanel/Scroll/Margin")
	StyleScrollbar(_scroll.get_v_scroll_bar())

func Init(player: Player) -> void:
	_player = player
	Refresh()

func SetCompactMode(enabled: bool) -> void:
	_isCompactModeActive = enabled
	custom_minimum_size = Vector2(352, 352) if enabled else Vector2(660, 500)
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS if enabled else ScrollContainer.SCROLL_MODE_AUTO
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_upgradesContainer.add_theme_constant_override("separation", 6 if enabled else 10)
	SetMargins(_contentMargin, 4 if enabled else 12)
	_headerLayout.add_theme_constant_override("separation", 2 if enabled else 4)
	_titleLabel.add_theme_font_size_override("font_size", 21 if enabled else 26)
	_leftSpacer.custom_minimum_size = Vector2(28, 28) if enabled else Vector2(32, 32)
	_closeButton.custom_minimum_size = Vector2(28, 28) if enabled else Vector2(32, 32)
	Refresh()

func SetMargins(container: MarginContainer, margin: int) -> void:
	container.add_theme_constant_override("margin_left", margin)
	container.add_theme_constant_override("margin_top", margin)
	container.add_theme_constant_override("margin_right", margin)
	container.add_theme_constant_override("margin_bottom", margin)

func Refresh() -> void:
	if _player == null or _upgradesContainer == null:
		return
		
	for child in _upgradesContainer.get_children():
		child.queue_free()

	var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")

	# Discount calculation
	var discount = _player.UpgradesGoldDiscountMultiplier

	# 1. Staff
	RenderUpgradeRow("staff", tr("Усиление посоха"),
		GameLocalization.Format("UPGRADE_STAFF_DESCRIPTION", {"bonus": _player.StaffUpgradeLevel * 10}),
		150, _player.StaffUpgradeLevel, 10, discount, font)

	# 2. Crystal
	var hasSynergy = _player.GetSkillLevel("crystal_synergy") > 0
	var pct = 6 if hasSynergy else 5
	RenderUpgradeRow("crystal", tr("Настройка кристалла"),
		GameLocalization.Format("UPGRADE_CRYSTAL_DESCRIPTION", {"per_level": pct, "bonus": _player.CrystalUpgradeLevel * pct}),
		200, _player.CrystalUpgradeLevel, 10, discount, font)

	# 3. Wards
	RenderUpgradeRow("wards", tr("Астральный магнит"),
		GameLocalization.Format("UPGRADE_WARDS_DESCRIPTION", {"bonus": _player.WardsUpgradeLevel * 5}),
		100, _player.WardsUpgradeLevel, 10, discount, font)

	# 4. Gold
	RenderUpgradeRow("gold", tr("Золотое проклятие"),
		GameLocalization.Format("UPGRADE_GOLD_DESCRIPTION", {"bonus": _player.GoldUpgradeLevel * 10}),
		250, _player.GoldUpgradeLevel, 10, discount, font)

	# 5. Insight
	RenderUpgradeRow("insight", tr("Прозрение"),
		GameLocalization.Format("UPGRADE_INSIGHT_DESCRIPTION", {"bonus": _player.InsightUpgradeLevel * 10}),
		200, _player.InsightUpgradeLevel, 10, discount, font)

	# 6. Crit
	RenderUpgradeRow("crit", tr("Критическая концентрация"),
		GameLocalization.Format("UPGRADE_CRIT_DESCRIPTION", {"crit": _player.CritUpgradeLevel * 3, "damage": _player.CritUpgradeLevel * 15}),
		300, _player.CritUpgradeLevel, 10, discount, font)

	# 7. Mana
	RenderUpgradeRow("mana", tr("Поток маны"),
		GameLocalization.Format("UPGRADE_MANA_DESCRIPTION", {"bonus": _player.ManaUpgradeLevel * 10}),
		180, _player.ManaUpgradeLevel, 10, discount, font)

	# --- Locked Upgrades ---
	# 8. Portal (requires Astral Link >= 1)
	var portalUnlocked = _player.GetSkillLevel("astral_link") >= 1
	var portalDesc = ""
	if portalUnlocked:
		portalDesc = GameLocalization.Format("UPGRADE_PORTAL_DESCRIPTION", {"bonus": _player.ElementalPortalLevel * 15})
	else:
		portalDesc = tr("Заблокировано!") + " " + tr("Требования: %s") % (tr("Астральная связь") + " I")
	RenderUpgradeRow("portal", tr("Портал стихий"),
		portalDesc,
		400, _player.ElementalPortalLevel, 5, discount, font, not portalUnlocked)

	# 9. Focus (requires Critical Magic >= 3)
	var focusUnlocked = _player.GetSkillLevel("crit_magic") >= 3
	var focusDesc = ""
	if focusUnlocked:
		focusDesc = GameLocalization.Format("UPGRADE_FOCUS_DESCRIPTION", {"bonus": _player.LegendaryFocusLevel * 10})
	else:
		focusDesc = tr("Заблокировано!") + " " + tr("Требования: %s") % (tr("Критическая магия") + " III")
	RenderUpgradeRow("focus", tr("Легендарный фокус"),
		focusDesc,
		500, _player.LegendaryFocusLevel, 5, discount, font, not focusUnlocked)

func RenderUpgradeRow(upgradeId: String, title: String, description: String, baseCost: int, currentLevel: int, maxLevel: int, discount: float, font: Font, isLocked: bool = false) -> void:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 124 if _isCompactModeActive else 96)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgradesContainer.add_child(row)

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var panelStyle = StyleBoxFlat.new()
	panelStyle.bg_color = Color(0.15, 0.15, 0.15, 0.3) if isLocked else Color(0.25, 0.18, 0.12, 0.4)
	panelStyle.set_border_width_all(1)
	panelStyle.border_color = Color(0.4, 0.3, 0.2)
	panelStyle.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panelStyle)
	row.add_child(panel)

	var contentMargin = MarginContainer.new()
	var compactMargin = 5 if _isCompactModeActive else 8
	contentMargin.add_theme_constant_override("margin_left", compactMargin)
	contentMargin.add_theme_constant_override("margin_top", compactMargin)
	contentMargin.add_theme_constant_override("margin_right", compactMargin)
	contentMargin.add_theme_constant_override("margin_bottom", compactMargin)
	panel.add_child(contentMargin)

	var contentLayout = BoxContainer.new()
	contentLayout.vertical = _isCompactModeActive
	contentLayout.add_theme_constant_override("separation", 4 if _isCompactModeActive else 12)
	contentMargin.add_child(contentLayout)

	var textVBox = VBoxContainer.new()
	textVBox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textVBox.alignment = BoxContainer.ALIGNMENT_CENTER
	contentLayout.add_child(textVBox)

	var titleLabel = Label.new()
	titleLabel.text = title + " " + (tr("Макс. уровень") if currentLevel >= maxLevel else tr("Уровень %d") % currentLevel)
	if font != null:
		titleLabel.add_theme_font_override("font", font)
	titleLabel.add_theme_font_size_override("font_size", 20 if _isCompactModeActive else 16)
	titleLabel.add_theme_color_override("font_color", Color.GRAY if isLocked else Color.WHEAT)
	textVBox.add_child(titleLabel)

	var descLabel = Label.new()
	descLabel.text = description
	descLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font != null:
		descLabel.add_theme_font_override("font", font)
	descLabel.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 16)
	descLabel.add_theme_color_override("font_color", Color.GRAY if isLocked else Color.LIGHT_GRAY)
	textVBox.add_child(descLabel)

	# Button section
	if not isLocked and currentLevel < maxLevel:
		var cost = roundi((baseCost * discount) * pow(1.15, currentLevel))
		
		var buyBtn = Button.new()
		buyBtn.text = tr("%d Зол.") % cost
		StyleButton(buyBtn, font)
		buyBtn.custom_minimum_size = Vector2(0, 38) if _isCompactModeActive else Vector2(100, 36)
		buyBtn.add_theme_font_size_override("font_size", 18)
		buyBtn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buyBtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if _isCompactModeActive else Control.SIZE_SHRINK_BEGIN
		buyBtn.disabled = _player.Gold < cost
		buyBtn.focus_mode = Control.FOCUS_NONE

		buyBtn.pressed.connect(func():
			if _player.Gold >= cost:
				_player.Gold -= cost
				_player.SetUpgradeLevel(upgradeId, currentLevel + 1)
				GameAudio.Play(GameAudio.POWER_UP)
				FloatingTextHelper.spawn(get_parent(), get_global_mouse_position(), "-" + tr("%d Зол.") % cost, Color.RED, 8, 1.0)
				Refresh()
		)
		contentLayout.add_child(buyBtn)
	elif isLocked:
		var lockLabel = Label.new()
		lockLabel.text = tr("Закрыто")
		if font != null:
			lockLabel.add_theme_font_override("font", font)
		lockLabel.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 14)
		lockLabel.add_theme_color_override("font_color", Color.RED)
		lockLabel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lockLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if _isCompactModeActive else HORIZONTAL_ALIGNMENT_LEFT
		contentLayout.add_child(lockLabel)

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

func StyleScrollbar(vsb: VScrollBar) -> void:
	vsb.custom_minimum_size = Vector2(14, 0)

	var trackTex = load("res://external/fantasy_pixelart_ui/scroll/wood_scrollbar.png")
	var grabberTex = load("res://external/fantasy_pixelart_ui/scroll/wood_scrollbar_grabber.png")

	var trackStyle = StyleBoxTexture.new()
	trackStyle.texture = trackTex
	trackStyle.texture_margin_left = 2
	trackStyle.texture_margin_top = 2
	trackStyle.texture_margin_right = 2
	trackStyle.texture_margin_bottom = 2
	trackStyle.modulate_color = Color(1.2, 1.2, 1.2, 1.0)

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
