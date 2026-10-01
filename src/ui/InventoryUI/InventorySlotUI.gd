class_name InventorySlotUI
extends TextureRect

var SlotIndex: int
var IsEquipment: bool
var _player: Player
var _item: ItemData

var _iconRect: TextureRect
var _rarityBg: ColorRect
var _countLabel: Label
var _activeTooltip: ItemTooltipUI

func _init(index: int, isEquipment: bool) -> void:
	SlotIndex = index
	IsEquipment = isEquipment

	custom_minimum_size = Vector2(64, 64)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Default inset background
	texture = load("res://external/fantasy_pixelart_ui/buttons/wood_button_pressed.png")

	# Rarity Background
	_rarityBg = ColorRect.new()
	_rarityBg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rarityBg.anchor_left = 0.0
	_rarityBg.anchor_right = 1.0
	_rarityBg.anchor_top = 0.0
	_rarityBg.anchor_bottom = 1.0
	_rarityBg.offset_left = 6
	_rarityBg.offset_right = -6
	_rarityBg.offset_top = 6
	_rarityBg.offset_bottom = -6
	_rarityBg.visible = false
	add_child(_rarityBg)

	# Icon representation
	_iconRect = TextureRect.new()
	_iconRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_iconRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_iconRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_iconRect.anchor_left = 0.0
	_iconRect.anchor_right = 1.0
	_iconRect.anchor_top = 0.0
	_iconRect.anchor_bottom = 1.0
	_iconRect.offset_left = 12
	_iconRect.offset_right = -12
	_iconRect.offset_top = 12
	_iconRect.offset_bottom = -12
	add_child(_iconRect)

	# Stack count label
	_countLabel = Label.new()
	_countLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_countLabel.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_countLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countLabel.anchor_left = 1.0
	_countLabel.anchor_right = 1.0
	_countLabel.anchor_top = 1.0
	_countLabel.anchor_bottom = 1.0
	_countLabel.offset_left = -40
	_countLabel.offset_right = -8
	_countLabel.offset_top = -24
	_countLabel.offset_bottom = -6
	var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")
	if font != null:
		_countLabel.add_theme_font_override("font", font)
	_countLabel.add_theme_font_size_override("font_size", 13)
	_countLabel.add_theme_color_override("font_color", Color.WHITE)
	add_child(_countLabel)
	_countLabel.hide()

	# Mouse signals
	mouse_entered.connect(OnMouseEntered)
	mouse_exited.connect(OnMouseExited)

func SetPlayer(player: Player) -> void:
	_player = player

func SetItem(item: ItemData) -> void:
	_item = item

	if _item == null:
		_iconRect.texture = null
		_countLabel.hide()
		_rarityBg.visible = false
	else:
		if not _item.IconTexturePath.is_empty():
			_iconRect.texture = load(_item.IconTexturePath)
		else:
			_iconRect.texture = null

		if _item.StackCount > 1:
			_countLabel.text = str(_item.StackCount)
			_countLabel.show()
		else:
			_countLabel.hide()

		if _item.Type != ItemData.ItemType.Material and _item.Type != ItemData.ItemType.Consumable:
			var rarityColor = Color.TRANSPARENT
			match _item.Rarity:
				ItemData.ItemRarity.Uncommon: rarityColor = Color.GREEN
				ItemData.ItemRarity.Rare: rarityColor = Color.DEEP_SKY_BLUE
				ItemData.ItemRarity.Epic: rarityColor = Color.MEDIUM_PURPLE
				ItemData.ItemRarity.Legendary: rarityColor = Color.GOLD

			if rarityColor != Color.TRANSPARENT:
				rarityColor.a = 0.35
				_rarityBg.color = rarityColor
				_rarityBg.visible = true
			else:
				_rarityBg.visible = false
		else:
			_rarityBg.visible = false

func SetCompactMode(enabled: bool) -> void:
	if _countLabel != null:
		_countLabel.add_theme_font_size_override("font_size", 18 if enabled else 13)

func OnMouseEntered() -> void:
	if _item == null:
		return

	_activeTooltip = ItemTooltipUI.new(_item)
	
	var parent = get_parent()
	while parent != null and not (parent is CanvasLayer):
		parent = parent.get_parent()

	if parent != null:
		parent.add_child(_activeTooltip)
	else:
		get_tree().root.add_child(_activeTooltip)

func OnMouseExited() -> void:
	if _activeTooltip != null:
		_activeTooltip.queue_free()
		_activeTooltip = null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			if _player != null and _item != null:
				OnMouseExited()
				if IsEquipment:
					_player.UnequipItem(SlotIndex)
				else:
					_player.EquipItem(SlotIndex)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if _player != null and _item != null:
				ShowContextMenu()

func ShowContextMenu() -> void:
	var menu = PopupMenu.new()
	add_child(menu)
	menu.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST

	var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")
	if font != null:
		menu.add_theme_font_override("font", font)
	menu.add_theme_font_size_override("font_size", 18)
	menu.add_theme_constant_override("v_separation", 12)

	if IsEquipment:
		menu.add_item(tr("Снять снаряжение"), 0)
	else:
		if _item.Type != ItemData.ItemType.Material and _item.Type != ItemData.ItemType.Consumable:
			menu.add_item(tr("Экипировать"), 1)
		if _item.Type == ItemData.ItemType.Consumable:
			menu.add_item(tr("Использовать"), 4)
		menu.add_item(GameLocalization.Format("SELL_CONTEXT_ITEM", {"amount": _item.SellValue * _item.StackCount}), 2)
		menu.add_item(tr("Уничтожить предмет"), 3)

	menu.id_pressed.connect(func(id: int):
		OnMouseExited()
		if id == 0: _player.UnequipItem(SlotIndex)
		elif id == 1: _player.EquipItem(SlotIndex)
		elif id == 2: _player.SellItem(SlotIndex)
		elif id == 3: _player.DestroyItem(SlotIndex)
		elif id == 4: _player.UseConsumable(SlotIndex)
		menu.queue_free()
	)

	menu.position = get_global_mouse_position()
	menu.popup()

# ==========================================
# Godot Built-in Drag and Drop overrides
# ==========================================
func _get_drag_data(_position: Vector2) -> Variant:
	if _item == null:
		return null

	var preview = TextureRect.new()
	preview.texture = _iconRect.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(40, 40)
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	set_drag_preview(preview)

	var dragData = DragData.new()
	dragData.SlotIndex = SlotIndex
	dragData.IsEquipment = IsEquipment

	return dragData

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if data is DragData:
		if data.SlotIndex == SlotIndex and data.IsEquipment == IsEquipment:
			return false

		if IsEquipment:
			var itemToDrop: ItemData
			if data.IsEquipment:
				itemToDrop = _player.EquippedItems[data.SlotIndex]
			else:
				itemToDrop = _player.Inventory[data.SlotIndex]

			if itemToDrop == null:
				return false

			if SlotIndex == 0 and itemToDrop.Type != ItemData.ItemType.Stone: return false
			if SlotIndex == 1 and itemToDrop.Type != ItemData.ItemType.Staff: return false
			if (SlotIndex == 2 or SlotIndex == 3) and itemToDrop.Type != ItemData.ItemType.Amulet: return false

		return true

	return false

func _drop_data(_position: Vector2, data: Variant) -> void:
	if data is DragData:
		OnMouseExited()

		# 1. Inventory to Inventory swap
		if not IsEquipment and not data.IsEquipment:
			_player.SwapInventoryItems(data.SlotIndex, SlotIndex)
		# 2. Inventory to Equipment equip
		elif IsEquipment and not data.IsEquipment:
			_player.EquipItem(data.SlotIndex)

			var item = _player.Inventory[data.SlotIndex]
			var prev = _player.EquippedItems[SlotIndex]
			_player.EquippedItems[SlotIndex] = item
			_player.Inventory[data.SlotIndex] = prev
			_player.inventory_updated.emit()
		# 3. Equipment to Inventory unequip
		elif not IsEquipment and data.IsEquipment:
			var item = _player.EquippedItems[data.SlotIndex]
			var prev = _player.Inventory[SlotIndex]

			var canSwap = true
			if prev != null:
				if data.SlotIndex == 0 and prev.Type != ItemData.ItemType.Stone: canSwap = false
				if data.SlotIndex == 1 and prev.Type != ItemData.ItemType.Staff: canSwap = false
				if (data.SlotIndex == 2 or data.SlotIndex == 3) and prev.Type != ItemData.ItemType.Amulet: canSwap = false

			if canSwap:
				_player.EquippedItems[data.SlotIndex] = prev
				_player.Inventory[SlotIndex] = item
				_player.inventory_updated.emit()
		# 4. Equipment to Equipment swap (amulets)
		elif IsEquipment and data.IsEquipment:
			var item = _player.EquippedItems[data.SlotIndex]
			var prev = _player.EquippedItems[SlotIndex]

			var canSwap = false
			if (SlotIndex == 2 or SlotIndex == 3) and (data.SlotIndex == 2 or data.SlotIndex == 3):
				canSwap = true

			if canSwap:
				_player.EquippedItems[data.SlotIndex] = prev
				_player.EquippedItems[SlotIndex] = item
				_player.inventory_updated.emit()
