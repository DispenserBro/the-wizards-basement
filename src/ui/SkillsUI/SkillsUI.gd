class_name SkillsUI
extends PanelContainer

signal skill_purchased(skill_id: String)

var _spLabel: Label
var _treeScroll: ScrollContainer
var _treeViewport: SkillTreeViewport
var _canvas: SkillTreeCanvas
var _player: Player

# Custom styled tooltip elements
var _tooltipPanel: PanelContainer
var _tooltipTitle: Label
var _tooltipLevel: Label
var _tooltipCost: Label
var _tooltipDesc: Label
var _tooltipReqs: Label
var _tooltipSeparator: HSeparator
var _tooltipOwnerButton: Button
var _tooltipHideCountdown: float = 0.0
const TooltipHideGraceSeconds = 0.18
var _closeBtn: TextureButton
var _tutorialRestrictionActive: bool = false
var _tutorialAllowedSkills: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grow_horizontal = GrowDirection.GROW_DIRECTION_BOTH
	grow_vertical = GrowDirection.GROW_DIRECTION_BOTH

	_spLabel = %SPLabel
	_tooltipPanel = %TooltipPanel
	_tooltipTitle = %TooltipTitle
	_tooltipLevel = %TooltipLevel
	_tooltipCost = %TooltipCost
	_tooltipDesc = %TooltipDesc
	_tooltipReqs = %TooltipReqs
	_tooltipSeparator = %TooltipSeparator
	_tooltipPanel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tooltipPanel.mouse_force_pass_scroll_events = true
	MakeTooltipChildrenIgnoreMouse(_tooltipPanel)

	_closeBtn = %CloseButton
	_closeBtn.pressed.connect(func():
		if _tutorialRestrictionActive:
			return
		visible = false
		HideCustomTooltip()
	)

	_treeScroll = %Scroll
	StyleScrollbar(_treeScroll.get_v_scroll_bar(), false)
	StyleScrollbar(_treeScroll.get_h_scroll_bar(), true)

	var margin = _treeScroll.get_node("Margin")

	_treeViewport = SkillTreeViewport.new()
	_treeViewport.Init(self, _treeScroll)
	margin.add_child(_treeViewport)
	_canvas = _treeViewport.TreeCanvas

	_tooltipPanel.get_parent().remove_child(_tooltipPanel)
	_treeViewport.add_child(_tooltipPanel)

func _process(delta: float) -> void:
	if _tooltipPanel == null or not _tooltipPanel.visible:
		return

	var mousePosition = get_viewport().get_mouse_position()
	var isOverTooltip = ContainsGlobalPoint(_tooltipPanel, mousePosition)
	var isOverOwner = _tooltipOwnerButton != null and is_instance_valid(_tooltipOwnerButton) and ContainsGlobalPoint(_tooltipOwnerButton, mousePosition)

	if isOverTooltip or isOverOwner:
		_tooltipHideCountdown = TooltipHideGraceSeconds
		return

	_tooltipHideCountdown -= delta
	if _tooltipHideCountdown <= 0.0:
		HideCustomTooltip()

func ContainsGlobalPoint(control: Control, globalPoint: Vector2) -> bool:
	var localPoint = control.get_global_transform_with_canvas().affine_inverse() * globalPoint
	return Rect2(Vector2.ZERO, control.size).has_point(localPoint)

func MakeTooltipChildrenIgnoreMouse(parent: Control) -> void:
	for child in parent.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			MakeTooltipChildrenIgnoreMouse(child)

func Init(player: Player) -> void:
	_player = player
	Refresh()

func SetCompactMode(enabled: bool) -> void:
	custom_minimum_size = Vector2(352, 352) if enabled else Vector2(660, 500)
	if enabled:
		HideCustomTooltip()

func SetTutorialRestriction(active: bool, allowedSkillIds: Array = []) -> void:
	_tutorialRestrictionActive = active
	_tutorialAllowedSkills.clear()
	if active and allowedSkillIds != null:
		for skillId in allowedSkillIds:
			_tutorialAllowedSkills[skillId] = true

	if _closeBtn != null:
		_closeBtn.disabled = active
	if active:
		HideCustomTooltip()
	Refresh()

func Refresh() -> void:
	if _player == null or _canvas == null:
		return

	_spLabel.text = GameLocalization.Format("SKILL_POINTS_AVAILABLE", {"count": _player.SkillPoints})

	for child in _canvas.get_children():
		child.queue_free()

	_canvas.queue_redraw()

	var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")

	# Center node (decorative anchor)
	var centerBtn = Button.new()
	centerBtn.custom_minimum_size = Vector2(24, 24)
	centerBtn.position = Vector2(300 - 12, 200 - 12)
	centerBtn.disabled = true
	centerBtn.focus_mode = Control.FOCUS_NONE
	centerBtn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var centerStyle = StyleBoxFlat.new()
	centerStyle.set_corner_radius_all(12)
	centerStyle.bg_color = Color(0.8, 0.6, 0.2)
	centerStyle.border_color = Color.GOLD
	centerStyle.set_border_width_all(2)
	centerBtn.add_theme_stylebox_override("disabled", centerStyle)
	_canvas.add_child(centerBtn)

	var centerLabel = Label.new()
	centerLabel.text = tr("НАЧАЛО")
	centerLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centerLabel.custom_minimum_size = Vector2(80, 20)
	centerLabel.position = Vector2(300 - 40, 200 - 32)
	centerLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font != null:
		centerLabel.add_theme_font_override("font", font)
	centerLabel.add_theme_font_size_override("font_size", 12)
	centerLabel.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.04))
	centerLabel.add_theme_constant_override("outline_size", 1)
	centerLabel.add_theme_color_override("font_color", Color.KHAKI)
	_canvas.add_child(centerLabel)

	# Branch 1: БОЙ (Top-Left)
	var spellPowerSmallPos = GetNodePos("spell_power_small")
	AddSkillNode(_canvas, "spell_power_small", tr("Малая сила чар"), tr("СЧм"),
		GameLocalization.Format("SKILL_SPELL_POWER_SMALL_DESCRIPTION", {"bonus": _player.SpellPowerSmallSkillLevel}),
		int(spellPowerSmallPos.x), int(spellPowerSmallPos.y),
		_player.SpellPowerSmallSkillLevel, 3, _player.SpellPowerSmallSkillLevel + 1, font)

	var spellPowerMediumPos = GetNodePos("spell_power_medium")
	AddSkillNode(_canvas, "spell_power_medium", tr("Средняя сила чар"), tr("СЧс"),
		GameLocalization.Format("SKILL_SPELL_POWER_MEDIUM_DESCRIPTION", {"bonus": _player.SpellPowerMediumSkillLevel * 2}),
		int(spellPowerMediumPos.x), int(spellPowerMediumPos.y),
		_player.SpellPowerMediumSkillLevel, 3, _player.SpellPowerMediumSkillLevel + 2, font)

	var spellPowerLargePos = GetNodePos("spell_power_large")
	AddSkillNode(_canvas, "spell_power_large", tr("Большая сила чар"), tr("СЧб"),
		GameLocalization.Format("SKILL_SPELL_POWER_LARGE_DESCRIPTION", {"bonus": _player.SpellPowerLargeSkillLevel * 5}),
		int(spellPowerLargePos.x), int(spellPowerLargePos.y),
		_player.SpellPowerLargeSkillLevel, 3, _player.SpellPowerLargeSkillLevel + 3, font)

	var critMagicPos = GetNodePos("crit_magic")
	AddSkillNode(_canvas, "crit_magic", tr("Критическая магия"), tr("КМ"),
		GameLocalization.Format("SKILL_CRIT_MAGIC_DESCRIPTION", {"crit": _player.CritMagicSkillLevel * 5, "power": _player.CritMagicSkillLevel * 15}),
		int(critMagicPos.x), int(critMagicPos.y),
		_player.CritMagicSkillLevel, 3, _player.CritMagicSkillLevel + 4, font)

	var astralBlastPos = GetNodePos("astral_blast")
	AddSkillNode(_canvas, "astral_blast", tr("Астральный взрыв"), tr("АВ"),
		GameLocalization.Format("SKILL_ASTRAL_BLAST_DESCRIPTION", {"bonus": _player.AstralBlastSkillLevel * 25}),
		int(astralBlastPos.x), int(astralBlastPos.y),
		_player.AstralBlastSkillLevel, 3, _player.AstralBlastSkillLevel + 5, font)

	# Branch 2: ПРИЗЫВ (Top-Right)
	var summonMasterSmallPos = GetNodePos("summon_master_small")
	AddSkillNode(_canvas, "summon_master_small", tr("Малый призыв"), tr("МПм"),
		GameLocalization.Format("SKILL_SUMMON_SMALL_DESCRIPTION", {"bonus": _player.SummonMasterSmallSkillLevel}),
		int(summonMasterSmallPos.x), int(summonMasterSmallPos.y),
		_player.SummonMasterSmallSkillLevel, 3, _player.SummonMasterSmallSkillLevel + 1, font)

	var summonMasterMediumPos = GetNodePos("summon_master_medium")
	AddSkillNode(_canvas, "summon_master_medium", tr("Средний призыв"), tr("МПс"),
		GameLocalization.Format("SKILL_SUMMON_MEDIUM_DESCRIPTION", {"bonus": _player.SummonMasterMediumSkillLevel * 2}),
		int(summonMasterMediumPos.x), int(summonMasterMediumPos.y),
		_player.SummonMasterMediumSkillLevel, 3, _player.SummonMasterMediumSkillLevel + 2, font)

	var summonMasterLargePos = GetNodePos("summon_master_large")
	AddSkillNode(_canvas, "summon_master_large", tr("Большой призыв"), tr("МПб"),
		GameLocalization.Format("SKILL_SUMMON_LARGE_DESCRIPTION", {"bonus": _player.SummonMasterLargeSkillLevel * 5}),
		int(summonMasterLargePos.x), int(summonMasterLargePos.y),
		_player.SummonMasterLargeSkillLevel, 3, _player.SummonMasterLargeSkillLevel + 3, font)

	var autoSummonPos = GetNodePos("auto_summon")
	AddSkillNode(_canvas, "auto_summon", tr("Автопризыв"), tr("АП"),
		GameLocalization.Format("SKILL_AUTO_SUMMON_DESCRIPTION", {"level": _player.AutoSummonSkillLevel}),
		int(autoSummonPos.x), int(autoSummonPos.y),
		_player.AutoSummonSkillLevel, 1, 4, font)

	var magicResonancePos = GetNodePos("magic_resonance")
	AddSkillNode(_canvas, "magic_resonance", tr("Резонанс чар"), tr("РЧ"),
		GameLocalization.Format("SKILL_MAGIC_RESONANCE_DESCRIPTION", {"bonus": _player.MagicResonanceSkillLevel * 15}),
		int(magicResonancePos.x), int(magicResonancePos.y),
		_player.MagicResonanceSkillLevel, 3, _player.MagicResonanceSkillLevel + 5, font)

	# Branch 3: БОГАТСТВО (Bottom-Left)
	var goldRushPos = GetNodePos("gold_rush")
	AddSkillNode(_canvas, "gold_rush", tr("Золотая лихорадка"), tr("ЗЛ"),
		GameLocalization.Format("SKILL_GOLD_RUSH_DESCRIPTION", {"bonus": _player.GoldRushSkillLevel * 15}),
		int(goldRushPos.x), int(goldRushPos.y),
		_player.GoldRushSkillLevel, 3, _player.GoldRushSkillLevel + 1, font)

	var astralLinkPos = GetNodePos("astral_link")
	AddSkillNode(_canvas, "astral_link", tr("Астральная связь"), tr("АС"),
		GameLocalization.Format("SKILL_ASTRAL_LINK_DESCRIPTION", {"bonus": _player.AstralLinkSkillLevel}),
		int(astralLinkPos.x), int(astralLinkPos.y),
		_player.AstralLinkSkillLevel, 3, _player.AstralLinkSkillLevel + 2, font)

	var treasureHunterPos = GetNodePos("treasure_hunter")
	AddSkillNode(_canvas, "treasure_hunter", tr("Охотник за сокровищами"), tr("ОС"),
		GameLocalization.Format("SKILL_TREASURE_HUNTER_DESCRIPTION", {"level": _player.TreasureHunterSkillLevel}),
		int(treasureHunterPos.x), int(treasureHunterPos.y),
		_player.TreasureHunterSkillLevel, 4, _player.TreasureHunterSkillLevel + 3, font)

	# Branch 4: МУДРОСТЬ (Bottom-Right)
	var ancientWisdomPos = GetNodePos("ancient_wisdom")
	AddSkillNode(_canvas, "ancient_wisdom", tr("Мудрость древних"), tr("МД"),
		GameLocalization.Format("SKILL_ANCIENT_WISDOM_DESCRIPTION", {"xp": _player.AncientWisdomSkillLevel * 10, "cost": _player.AncientWisdomSkillLevel * 5}),
		int(ancientWisdomPos.x), int(ancientWisdomPos.y),
		_player.AncientWisdomSkillLevel, 3, _player.AncientWisdomSkillLevel + 1, font)

	var manaOverloadPos = GetNodePos("mana_overload")
	AddSkillNode(_canvas, "mana_overload", tr("Перегрузка маны"), tr("ПМ"),
		GameLocalization.Format("SKILL_MANA_OVERLOAD_DESCRIPTION", {"bonus": _player.ManaOverloadSkillLevel * 25}),
		int(manaOverloadPos.x), int(manaOverloadPos.y),
		_player.ManaOverloadSkillLevel, 3, _player.ManaOverloadSkillLevel + 2, font)

	var crystalSynergyPos = GetNodePos("crystal_synergy")
	AddSkillNode(_canvas, "crystal_synergy", tr("Синергия кристалла"), tr("СК"),
		tr("Повышает эффективность улучшения \"Настройка кристалла\" (бонус за уровень становится +6% вместо +5%)."),
		int(crystalSynergyPos.x), int(crystalSynergyPos.y),
		_player.CrystalSynergySkillLevel, 1, 2, font)

	var ultimateFocusPos = GetNodePos("ultimate_focus")
	AddSkillNode(_canvas, "ultimate_focus", tr("Абсолютный разум"), tr("АР"),
		GameLocalization.Format("SKILL_ULTIMATE_FOCUS_DESCRIPTION", {"stone": _player.UltimateFocusSkillLevel * 30, "cooldown": _player.UltimateFocusSkillLevel * 10}),
		int(ultimateFocusPos.x), int(ultimateFocusPos.y),
		_player.UltimateFocusSkillLevel, 2, _player.UltimateFocusSkillLevel + 3, font)

	_treeViewport.move_child(_tooltipPanel, -1)

func GetNodePos(skillId: String) -> Vector2:
	var center = Vector2(300, 200)
	match skillId:
		"spell_power_small": return center + Vector2(-0.707, -0.707) * 55
		"spell_power_medium": return center + Vector2(-0.94, -0.34) * 115
		"spell_power_large": return center + Vector2(-0.94, -0.34) * 185
		"crit_magic": return center + Vector2(-0.34, -0.94) * 115
		"astral_blast": return center + Vector2(-0.34, -0.94) * 185
		"summon_master_small": return center + Vector2(0.707, -0.707) * 55
		"summon_master_medium": return center + Vector2(0.94, -0.34) * 115
		"summon_master_large": return center + Vector2(0.94, -0.34) * 185
		"auto_summon": return center + Vector2(0.34, -0.94) * 115
		"magic_resonance": return center + Vector2(0.34, -0.94) * 185
		"gold_rush": return center + Vector2(-0.707, 0.707) * 55
		"astral_link": return center + Vector2(-0.94, 0.34) * 125
		"treasure_hunter": return center + Vector2(-0.34, 0.94) * 125
		"ancient_wisdom": return center + Vector2(0.707, 0.707) * 55
		"mana_overload": return center + Vector2(0.94, 0.34) * 115
		"ultimate_focus": return center + Vector2(0.94, 0.34) * 185
		"crystal_synergy": return center + Vector2(0.34, 0.94) * 115
		_: return center

func DrawConnections(canvas: Control) -> void:
	var center = Vector2(300, 200)

	var spellPowerSmallPos = GetNodePos("spell_power_small")
	var spellPowerMediumPos = GetNodePos("spell_power_medium")
	var spellPowerLargePos = GetNodePos("spell_power_large")
	var critMagicPos = GetNodePos("crit_magic")
	var astralBlastPos = GetNodePos("astral_blast")

	var summonMasterSmallPos = GetNodePos("summon_master_small")
	var summonMasterMediumPos = GetNodePos("summon_master_medium")
	var summonMasterLargePos = GetNodePos("summon_master_large")
	var autoSummonPos = GetNodePos("auto_summon")
	var magicResonancePos = GetNodePos("magic_resonance")

	var goldRushPos = GetNodePos("gold_rush")
	var astralLinkPos = GetNodePos("astral_link")
	var treasureHunterPos = GetNodePos("treasure_hunter")

	var ancientWisdomPos = GetNodePos("ancient_wisdom")
	var manaOverloadPos = GetNodePos("mana_overload")
	var crystalSynergyPos = GetNodePos("crystal_synergy")
	var ultimateFocusPos = GetNodePos("ultimate_focus")

	DrawLineBetween(canvas, center, spellPowerSmallPos, _player.SpellPowerSmallSkillLevel > 0)
	DrawLineBetween(canvas, center, summonMasterSmallPos, _player.SummonMasterSmallSkillLevel > 0)
	DrawLineBetween(canvas, center, goldRushPos, _player.GoldRushSkillLevel > 0)
	DrawLineBetween(canvas, center, ancientWisdomPos, _player.AncientWisdomSkillLevel > 0)

	DrawLineBetween(canvas, spellPowerSmallPos, spellPowerMediumPos, _player.SpellPowerMediumSkillLevel > 0)
	DrawLineBetween(canvas, spellPowerMediumPos, spellPowerLargePos, _player.SpellPowerLargeSkillLevel > 0)
	DrawLineBetween(canvas, spellPowerSmallPos, critMagicPos, _player.CritMagicSkillLevel > 0)

	DrawLineBetween(canvas, summonMasterSmallPos, summonMasterMediumPos, _player.SummonMasterMediumSkillLevel > 0)
	DrawLineBetween(canvas, summonMasterMediumPos, summonMasterLargePos, _player.SummonMasterLargeSkillLevel > 0)
	DrawLineBetween(canvas, summonMasterSmallPos, autoSummonPos, _player.AutoSummonSkillLevel > 0)

	DrawLineBetween(canvas, goldRushPos, astralLinkPos, _player.AstralLinkSkillLevel > 0)
	DrawLineBetween(canvas, goldRushPos, treasureHunterPos, _player.TreasureHunterSkillLevel > 0)

	DrawLineBetween(canvas, ancientWisdomPos, manaOverloadPos, _player.ManaOverloadSkillLevel > 0)
	DrawLineBetween(canvas, manaOverloadPos, ultimateFocusPos, _player.UltimateFocusSkillLevel > 0)
	DrawLineBetween(canvas, ancientWisdomPos, crystalSynergyPos, _player.CrystalSynergySkillLevel > 0)

	var resonanceUnlocked = _player.MagicResonanceSkillLevel > 0
	DrawLineBetween(canvas, autoSummonPos, magicResonancePos, resonanceUnlocked)
	DrawLineBetween(canvas, spellPowerLargePos, magicResonancePos, resonanceUnlocked, true)

	var astralBlastUnlocked = _player.AstralBlastSkillLevel > 0
	DrawLineBetween(canvas, critMagicPos, astralBlastPos, astralBlastUnlocked)
	DrawLineBetween(canvas, astralLinkPos, astralBlastPos, astralBlastUnlocked, true)

	var ultimateFocusUnlocked = _player.UltimateFocusSkillLevel > 0
	DrawLineBetween(canvas, manaOverloadPos, ultimateFocusPos, ultimateFocusUnlocked)
	DrawLineBetween(canvas, crystalSynergyPos, ultimateFocusPos, ultimateFocusUnlocked, true)

func DrawLineBetween(canvas: Control, start: Vector2, end: Vector2, isActive: bool, isHybrid: bool = false) -> void:
	var color: Color
	var width: float
	if isActive:
		color = Color(0.72, 0.36, 0.95, 0.9) if isHybrid else Color(1.0, 0.85, 0.3, 0.8)
		width = 4.0
	else:
		color = Color(0.35, 0.22, 0.45, 0.5) if isHybrid else Color(0.4, 0.3, 0.2, 0.5)
		width = 2.0
	canvas.draw_line(start, end, color, width, true)

func AddSkillNode(canvas: Control, skillId: String, nameStr: String, shortName: String, description: String, x: int, y: int, currentLevel: int, maxLevel: int, cost: int, font: Font) -> void:
	var reqWarning = GetSkillRequirementsMessage(skillId)
	var reqsMet = reqWarning.is_empty()
	var tutorialBlocked = _tutorialRestrictionActive and not _tutorialAllowedSkills.has(skillId)
	var isMaxed = currentLevel >= maxLevel
	var nodeFont = load("res://fonts/tiny5-font/Tiny5-Regular.ttf")

	var nameLabel = Label.new()
	nameLabel.text = nameStr
	nameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameLabel.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	nameLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nameLabel.max_lines_visible = 2
	nameLabel.custom_minimum_size = Vector2(100, 30)
	nameLabel.position = Vector2(x - 50, y - 52)
	nameLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font != null:
		nameLabel.add_theme_font_override("font", font)
	nameLabel.add_theme_font_size_override("font_size", 11)
	nameLabel.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.04))
	nameLabel.add_theme_constant_override("outline_size", 1)
	
	if isMaxed:
		nameLabel.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	elif not reqsMet or tutorialBlocked:
		nameLabel.add_theme_color_override("font_color", Color.DIM_GRAY)
	else:
		nameLabel.add_theme_color_override("font_color", Color.WHEAT)
	
	canvas.add_child(nameLabel)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(40, 40)
	btn.position = Vector2(x - 20, y - 20)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.mouse_force_pass_scroll_events = true

	var isHybrid = skillId == "magic_resonance" or skillId == "astral_blast" or skillId == "ultimate_focus"

	var style = StyleBoxTexture.new()
	style.texture_margin_left = 4
	style.texture_margin_top = 4
	style.texture_margin_right = 4
	style.texture_margin_bottom = 4

	if isMaxed:
		style.texture = load("res://external/fantasy_pixelart_ui/buttons/gold_button_normal.png")
		if isHybrid:
			style.modulate_color = Color(0.85, 0.6, 1.0)
	elif not reqsMet or tutorialBlocked:
		style.texture = load("res://external/fantasy_pixelart_ui/buttons/wood_button_normal.png")
		style.modulate_color = Color(0.25, 0.25, 0.25, 0.8)
	else:
		style.texture = load("res://external/fantasy_pixelart_ui/buttons/wood_button_normal.png")
		if isHybrid:
			style.modulate_color = Color(0.7, 0.4, 0.9)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 0)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(vbox)

	var abLabel = Label.new()
	abLabel.text = shortName
	abLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	abLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if nodeFont != null:
		abLabel.add_theme_font_override("font", nodeFont)
	abLabel.add_theme_font_size_override("font_size", 15)
	abLabel.add_theme_color_override("font_color", Color.GOLD if isMaxed else Color.WHITE)
	vbox.add_child(abLabel)

	var lvlLabel = Label.new()
	lvlLabel.text = "✔" if isMaxed else str(currentLevel) + "/" + str(maxLevel)
	lvlLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvlLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font != null:
		lvlLabel.add_theme_font_override("font", font)
	lvlLabel.add_theme_font_size_override("font_size", 11)
	lvlLabel.add_theme_color_override("font_color", Color.LIGHT_GREEN if isMaxed else Color.LIGHT_GRAY)
	vbox.add_child(lvlLabel)

	btn.tooltip_text = ""
	btn.mouse_entered.connect(func(): ShowCustomTooltip(btn, nameStr, currentLevel, maxLevel, cost, description, reqWarning))
	btn.mouse_exited.connect(BeginTooltipHideGrace)

	if currentLevel < maxLevel:
		btn.disabled = _player.SkillPoints < cost or not reqsMet or tutorialBlocked
		btn.pressed.connect(func():
			if _player.SkillPoints >= cost and reqsMet and (not _tutorialRestrictionActive or _tutorialAllowedSkills.has(skillId)):
				_player.SkillPoints -= cost
				_player.SetSkillLevel(skillId, currentLevel + 1)
				GameAudio.Play(GameAudio.POWER_UP)
				FloatingTextHelper.spawn(get_parent(), get_global_mouse_position(), GameLocalization.Format("SKILL_POINTS_SPENT", {"count": cost}), Color.ORANGE, 8, 1.0)
				Refresh()
				skill_purchased.emit(skillId)
		)
	else:
		btn.disabled = true

	canvas.add_child(btn)

func ShowCustomTooltip(button: Button, nameStr: String, level: int, maxLevel: int, cost: int, description: String, reqWarning: String) -> void:
	if _tooltipPanel == null:
		return
	_tooltipOwnerButton = button
	_tooltipHideCountdown = TooltipHideGraceSeconds

	_tooltipTitle.text = nameStr
	_tooltipLevel.text = tr("Изучено (Макс. ур.)") if level >= maxLevel else GameLocalization.Format("SKILL_LEVEL", {"level": level, "max": maxLevel})
	_tooltipCost.text = "" if level >= maxLevel else GameLocalization.Format("SKILL_COST", {"count": cost})
	_tooltipCost.visible = level < maxLevel

	_tooltipDesc.text = description

	if not reqWarning.is_empty():
		_tooltipReqs.text = reqWarning
		_tooltipReqs.show()
		_tooltipSeparator.show()
	else:
		_tooltipReqs.hide()
		_tooltipSeparator.hide()

	_tooltipPanel.show()
	
	_tooltipPanel.reset_size()
	var tooltipSize = _tooltipPanel.get_combined_minimum_size()
	_tooltipPanel.size = tooltipSize
	var zoom = _treeViewport.ZoomLevel if _treeViewport != null else 1.0
	var btnPos = button.position * zoom
	var btnSize = button.size * zoom

	var visibleLeft = _treeScroll.scroll_horizontal
	var visibleTop = _treeScroll.scroll_vertical
	var visibleRight = visibleLeft + _treeScroll.size.x
	var visibleBottom = visibleTop + _treeScroll.size.y

	var targetX = btnPos.x + (btnSize.x - tooltipSize.x) / 2.0
	var aboveY = btnPos.y - tooltipSize.y - 8.0
	var belowY = btnPos.y + btnSize.y + 8.0
	var targetY = aboveY if aboveY >= visibleTop + 10.0 else belowY

	var maxX = maxf(visibleLeft + 10.0, visibleRight - tooltipSize.x - 10.0)
	var maxY = maxf(visibleTop + 10.0, visibleBottom - tooltipSize.y - 10.0)
	targetX = clampf(targetX, visibleLeft + 10.0, maxX)
	targetY = clampf(targetY, visibleTop + 10.0, maxY)

	_tooltipPanel.position = Vector2(targetX, targetY)

func BeginTooltipHideGrace() -> void:
	_tooltipHideCountdown = TooltipHideGraceSeconds

func HideCustomTooltip() -> void:
	if _tooltipPanel != null:
		_tooltipPanel.hide()
	_tooltipOwnerButton = null
	_tooltipHideCountdown = 0.0

func GetSkillRequirementsMessage(skillId: String) -> String:
	match skillId:
		"spell_power_medium":
			if _player.GetSkillLevel("spell_power_small") < 1:
				return tr("Требует навык \"Малая сила чар\" I уровня.")
		"spell_power_large":
			if _player.GetSkillLevel("spell_power_medium") < 1:
				return tr("Требует навык \"Средняя сила чар\" I уровня.")
		"crit_magic":
			if _player.GetSkillLevel("spell_power_small") < 1:
				return tr("Требует навык \"Малая сила чар\" I уровня.")
		"summon_master_medium":
			if _player.GetSkillLevel("summon_master_small") < 1:
				return tr("Требует навык \"Малый призыв\" I уровня.")
		"summon_master_large":
			if _player.GetSkillLevel("summon_master_medium") < 1:
				return tr("Требует навык \"Средний призыв\" I уровня.")
		"auto_summon":
			if _player.GetSkillLevel("summon_master_small") < 1:
				return tr("Требует навык \"Малый призыв\" I уровня.")
		"astral_link":
			if _player.GetSkillLevel("gold_rush") < 1:
				return tr("Требует навык \"Золотая лихорадка\" I уровня.")
		"treasure_hunter":
			if _player.GetSkillLevel("gold_rush") < 1:
				return tr("Требует навык \"Золотая лихорадка\" I уровня.")
		"mana_overload":
			if _player.GetSkillLevel("ancient_wisdom") < 1:
				return tr("Требует навык \"Мудрость древних\" I уровня.")
		"crystal_synergy":
			if _player.GetSkillLevel("ancient_wisdom") < 1:
				return tr("Требует навык \"Мудрость древних\" I уровня.")
		"magic_resonance":
			var autoSummonOk = _player.GetSkillLevel("auto_summon") >= 1
			var spellPowerOk = _player.GetSkillLevel("spell_power_large") >= 1
			if not autoSummonOk or not spellPowerOk:
				return GameLocalization.Text("SKILL_REQUIREMENT_MAGIC_RESONANCE")
		"astral_blast":
			var critMagicOk = _player.GetSkillLevel("crit_magic") >= 1
			var astralLinkOk = _player.GetSkillLevel("astral_link") >= 1
			if not critMagicOk or not astralLinkOk:
				return GameLocalization.Text("SKILL_REQUIREMENT_ASTRAL_BLAST")
		"ultimate_focus":
			var manaOverloadOk = _player.GetSkillLevel("mana_overload") >= 1
			var crystalSynergyOk = _player.GetSkillLevel("crystal_synergy") >= 1
			if not manaOverloadOk or not crystalSynergyOk:
				return GameLocalization.Text("SKILL_REQUIREMENT_ULTIMATE_FOCUS")
	return ""

func StyleScrollbar(sb: ScrollBar, horizontal: bool = false) -> void:
	if horizontal:
		sb.custom_minimum_size = Vector2(0, 12)
	else:
		sb.custom_minimum_size = Vector2(12, 0)

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

	sb.add_theme_stylebox_override("scroll", trackStyle)
	sb.add_theme_stylebox_override("grabber", grabberStyle)
	sb.add_theme_stylebox_override("grabber_hover", grabberHover)
	sb.add_theme_stylebox_override("grabber_highlight", grabberHover)
	sb.add_theme_stylebox_override("grabber_pressed", grabberStyle)

# ==========================================
# INNER CLASSES FOR TREE VIEWPORT/CANVAS
# ==========================================
class SkillTreeCanvas:
	extends Control

	var _ui: SkillsUI

	func Init(ui: SkillsUI) -> void:
		_ui = ui
		size = Vector2(660.0, 500.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set("oversampling_with_scale", 2)

	func _draw() -> void:
		if _ui != null:
			_ui.DrawConnections(self)

class SkillTreeViewport:
	extends Control

	var BaseCanvasSize: Vector2 = Vector2(660.0, 500.0)
	const MinZoom = 0.5
	const MaxZoom = 2.0
	const ZoomStep = 0.1

	var _scroll: ScrollContainer
	var _treeCanvas: SkillTreeCanvas
	var _isDragging: bool = false
	var _dragStartMousePosition: Vector2 = Vector2.ZERO
	var _dragStartScroll: Vector2 = Vector2.ZERO
	var _zoomLevel: float = 1.0
	
	var TreeCanvas: SkillTreeCanvas:
		get:
			return _treeCanvas
	var ZoomLevel: float:
		get:
			return _zoomLevel

	func Init(ui: SkillsUI, scroll: ScrollContainer) -> void:
		_scroll = scroll
		custom_minimum_size = BaseCanvasSize
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_ALL

		_treeCanvas = SkillTreeCanvas.new()
		_treeCanvas.Init(ui)
		add_child(_treeCanvas)

	func _gui_input(event: InputEvent) -> void:
		if _scroll == null or not is_instance_valid(_scroll):
			return

		if event is InputEventKey and event.pressed and not event.echo:
			var zoomIn = event.keycode == KEY_PLUS or event.keycode == KEY_KP_ADD or event.unicode == 43 # '+'
			var zoomOut = event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT or event.unicode == 45 # '-'
			if zoomIn or zoomOut:
				AdjustZoom(ZoomStep if zoomIn else -ZoomStep, get_local_mouse_position())
				accept_event()
			return

		if event is not InputEventMouseButton:
			return
		var mouseButton = event as InputEventMouseButton

		if mouseButton.pressed and mouseButton.button_index == MOUSE_BUTTON_WHEEL_UP:
			AdjustZoom(ZoomStep, mouseButton.position)
			accept_event()
		elif mouseButton.pressed and mouseButton.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			AdjustZoom(-ZoomStep, mouseButton.position)
			accept_event()
		elif mouseButton.pressed and mouseButton.button_index == MOUSE_BUTTON_LEFT:
			grab_focus()
			_isDragging = true
			_dragStartMousePosition = mouseButton.global_position
			_dragStartScroll = Vector2(_scroll.scroll_horizontal, _scroll.scroll_vertical)
			mouse_default_cursor_shape = Control.CURSOR_DRAG
			accept_event()

	func _input(event: InputEvent) -> void:
		if not _isDragging or _scroll == null or not is_instance_valid(_scroll):
			return

		if event is InputEventMouseMotion:
			var delta = event.global_position - _dragStartMousePosition
			_scroll.scroll_horizontal = roundi(_dragStartScroll.x - delta.x)
			_scroll.scroll_vertical = roundi(_dragStartScroll.y - delta.y)
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_isDragging = false
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			get_viewport().set_input_as_handled()

	func AdjustZoom(step: float, localMousePosition: Vector2) -> void:
		var oldZoom = _zoomLevel
		_zoomLevel = clampf(_zoomLevel + step, MinZoom, MaxZoom)
		if is_equal_approx(oldZoom, _zoomLevel):
			return

		_treeCanvas.scale = Vector2.ONE * _zoomLevel
		custom_minimum_size = BaseCanvasSize * _zoomLevel

		var treePointUnderCursor = localMousePosition / oldZoom
		var scrollDelta = treePointUnderCursor * _zoomLevel - localMousePosition
		_scroll.set_deferred("scroll_horizontal", _scroll.scroll_horizontal + roundi(scrollDelta.x))
		_scroll.set_deferred("scroll_vertical", _scroll.scroll_vertical + roundi(scrollDelta.y))

		_treeCanvas.queue_redraw()
