class_name ItemTooltipUI
extends PanelContainer

enum PriceMode {
	Sell,
	Buy,
	Hidden
}

var _item: ItemData
var _priceMode: int
var _priceOverride: int

func _init(item: ItemData, priceMode: int = PriceMode.Sell, priceOverride: int = -1) -> void:
	_item = item
	_priceMode = priceMode
	_priceOverride = priceOverride
	z_index = 200 # Render on top of GUI
	z_as_relative = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Setup StyleBox with wood_button_normal texture
	var bgTex = load("res://external/fantasy_pixelart_ui/buttons/wood_button_normal.png")
	if bgTex != null:
		var styleBox = StyleBoxTexture.new()
		styleBox.texture = bgTex
		styleBox.texture_margin_left = 5
		styleBox.texture_margin_top = 5
		styleBox.texture_margin_right = 5
		styleBox.texture_margin_bottom = 5
		add_theme_stylebox_override("panel", styleBox)

	# Tooltip layout
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	add_child(layout)

	var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")

	# Item Name
	var nameLabel = Label.new()
	nameLabel.text = GameLocalization.ItemName(_item)
	if font != null:
		nameLabel.add_theme_font_override("font", font)
	nameLabel.add_theme_font_size_override("font_size", 24)

	var rarityColor = Color.WHITE
	match _item.Rarity:
		ItemData.ItemRarity.Uncommon:
			rarityColor = Color.GREEN
		ItemData.ItemRarity.Rare:
			rarityColor = Color.DEEP_SKY_BLUE
		ItemData.ItemRarity.Epic:
			rarityColor = Color.MEDIUM_PURPLE
		ItemData.ItemRarity.Legendary:
			rarityColor = Color.GOLD
	nameLabel.add_theme_color_override("font_color", rarityColor)
	layout.add_child(nameLabel)

	# Item Rarity & Type
	var rarityName = tr("Обычный")
	match _item.Rarity:
		ItemData.ItemRarity.Uncommon: rarityName = tr("Необычный")
		ItemData.ItemRarity.Rare: rarityName = tr("Редкий")
		ItemData.ItemRarity.Epic: rarityName = tr("Эпический")
		ItemData.ItemRarity.Legendary: rarityName = tr("Легендарный")

	var typeName = tr("Материал")
	match _item.Type:
		ItemData.ItemType.Staff: typeName = tr("Посох")
		ItemData.ItemType.Stone: typeName = tr("Магический камень")
		ItemData.ItemType.Amulet: typeName = tr("Амулет")
		ItemData.ItemType.Consumable: typeName = tr("Расходник")
	var metaLabel = Label.new()
	metaLabel.text = rarityName + " | " + typeName
	if font != null:
		metaLabel.add_theme_font_override("font", font)
	metaLabel.add_theme_font_size_override("font_size", 18)
	metaLabel.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	layout.add_child(metaLabel)

	# Stats List
	var statsLayout = VBoxContainer.new()
	statsLayout.add_theme_constant_override("separation", 4)
	layout.add_child(statsLayout)

	if _item.BaseDamage != 0:
		AddStatRow(statsLayout, font, GameLocalization.Format("ITEM_STAT_DAMAGE", {"value": FormatSignedNumber(_item.BaseDamage)}), _item.BaseDamage > 0)
	if not is_zero_approx(_item.AttackSpeedBonus):
		AddStatRow(statsLayout, font, GameLocalization.Format("ITEM_STAT_ATTACK_SPEED", {"value": FormatSignedPercent(_item.AttackSpeedBonus)}), _item.AttackSpeedBonus > 0.0)
	if _item.ManaBonus != 0:
		AddStatRow(statsLayout, font, GameLocalization.Format("ITEM_STAT_MANA", {"value": FormatSignedNumber(_item.ManaBonus)}), _item.ManaBonus > 0)
	if not is_zero_approx(_item.RegenBonus):
		AddStatRow(statsLayout, font, GameLocalization.Format("ITEM_STAT_REGEN", {"value": FormatSignedFloat(_item.RegenBonus)}), _item.RegenBonus > 0.0)
	if not is_zero_approx(_item.CritChanceBonus):
		AddStatRow(statsLayout, font, GameLocalization.Format("ITEM_STAT_CRIT_CHANCE", {"value": FormatSignedPercent(_item.CritChanceBonus)}), _item.CritChanceBonus > 0.0)

	# Description
	if not _item.Description.is_empty():
		var descLabel = Label.new()
		descLabel.text = GameLocalization.ItemDescription(_item)
		descLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		descLabel.custom_minimum_size = Vector2(300, 0)
		if font != null:
			descLabel.add_theme_font_override("font", font)
		descLabel.add_theme_font_size_override("font_size", 18)
		descLabel.add_theme_color_override("font_color", Color.KHAKI)
		layout.add_child(descLabel)

	# Цена зависит от места, где показана подсказка: инвентарь или магазин.
	if _priceMode != PriceMode.Hidden:
		var priceLabel = Label.new()
		if _priceMode == PriceMode.Buy:
			var buyPrice = _priceOverride if _priceOverride >= 0 else ItemDatabase.get_buy_price(_item)
			priceLabel.text = GameLocalization.Format("ITEM_BUY_PRICE", {"amount": buyPrice})
		else:
			priceLabel.text = GameLocalization.Format("ITEM_SELL_PRICE", {"amount": _item.SellValue * _item.StackCount})
		if font != null:
			priceLabel.add_theme_font_override("font", font)
		priceLabel.add_theme_font_size_override("font_size", 18)
		priceLabel.add_theme_color_override("font_color", Color.YELLOW)
		layout.add_child(priceLabel)

func AddStatRow(parent: VBoxContainer, font: Font, text: String, isPositive: bool = true) -> void:
	var lbl = Label.new()
	lbl.text = text
	if font != null:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color.PALE_GREEN if isPositive else Color.LIGHT_CORAL)
	parent.add_child(lbl)

func FormatSignedNumber(value: int) -> String:
	return ("+" if value > 0 else "") + str(value)

func FormatSignedPercent(value: float) -> String:
	var percent = roundi(value * 100.0)
	return ("+" if percent > 0 else "") + str(percent) + "%"

func FormatSignedFloat(value: float) -> String:
	var rounded = snappedf(value, 0.1)
	return ("+" if rounded > 0.0 else "") + str(rounded)

func _process(_delta: float) -> void:
	var mousePos = get_global_mouse_position()
	var tooltipSize = get_combined_minimum_size()
	var limit = get_viewport_rect().size

	var targetX = mousePos.x + 10
	var targetY = mousePos.y + 10

	if targetX + tooltipSize.x > limit.x:
		targetX = mousePos.x - tooltipSize.x - 10
	if targetY + tooltipSize.y > limit.y:
		targetY = limit.y - tooltipSize.y - 5

	var maxX = maxf(5.0, limit.x - tooltipSize.x - 5.0)
	var maxY = maxf(5.0, limit.y - tooltipSize.y - 5.0)
	global_position = Vector2(
		clampf(targetX, 5.0, maxX),
		clampf(targetY, 5.0, maxY))
