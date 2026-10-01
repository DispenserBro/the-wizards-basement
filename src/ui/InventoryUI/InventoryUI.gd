class_name InventoryUI
extends PanelContainer

var _player: Player
var _inventoryGrid: GridContainer
var _panelsLayout: BoxContainer
var _equipmentContainer: BoxContainer
var _equipmentSection: VBoxContainer
var _inventorySection: VBoxContainer
var _equipmentScroll: ScrollContainer
var _inventoryScroll: ScrollContainer
var _invSlots: Array[InventorySlotUI] = []
var _equipSlots: Array[InventorySlotUI] = []
var _equipLabels: Array[Label] = []

func _ready() -> void:
	# Set texture filter to Nearest for crisp borders/text
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_panelsLayout = %PanelsLayout
	_equipmentContainer = %EquipmentContainer
	_inventoryGrid = %InventoryGrid
	_equipmentSection = get_node("MainLayout/PanelsLayout/EquipVBox")
	_inventorySection = get_node("MainLayout/PanelsLayout/InvVBox")
	
	var closeBtn = %CloseButton
	closeBtn.pressed.connect(func(): visible = false)

	_equipmentScroll = %EquipScroll
	StyleScrollbar(_equipmentScroll.get_v_scroll_bar())

	_inventoryScroll = %InvScroll
	StyleScrollbar(_inventoryScroll.get_v_scroll_bar())

	# Create slots UI
	CreateSlots()

func CreateSlots() -> void:
	# 4 Equipment Slots: 0 - Stone, 1 - Staff, 2 - Amulet I, 3 - Amulet II
	var slotNames = [tr("Камень"), tr("Посох"), tr("Амулет I"), tr("Амулет II")]
	for i in range(4):
		var row = HBoxContainer.new()
		_equipmentContainer.add_child(row)

		var lbl = Label.new()
		lbl.text = slotNames[i]
		var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")
		if font != null:
			lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.custom_minimum_size = Vector2(82, 0)
		row.add_child(lbl)
		_equipLabels.append(lbl)

		var slot = InventorySlotUI.new(i, true)
		row.add_child(slot)
		_equipSlots.append(slot)

	# 36 Inventory Slots
	for i in range(36):
		var slot = InventorySlotUI.new(i, false)
		_inventoryGrid.add_child(slot)
		_invSlots.append(slot)

func Init(player: Player) -> void:
	_player = player
	if _player != null:
		_player.inventory_updated.connect(Refresh)

	# Connect player reference to slots
	for slot in _invSlots:
		slot.SetPlayer(_player)
	for slot in _equipSlots:
		slot.SetPlayer(_player)

	Refresh()

func Refresh() -> void:
	if _player == null:
		return

	# Refresh equipment
	for i in range(4):
		_equipSlots[i].SetItem(_player.EquippedItems[i])

	# Refresh inventory
	for i in range(36):
		_invSlots[i].SetItem(_player.Inventory[i])

func SetCompactMode(enabled: bool) -> void:
	custom_minimum_size = Vector2(352, 352) if enabled else Vector2(660, 500)

	if _panelsLayout != null:
		_panelsLayout.vertical = enabled

	if _equipmentContainer != null:
		_equipmentContainer.vertical = not enabled

	if _equipmentSection != null:
		_equipmentSection.custom_minimum_size = Vector2(0, 92) if enabled else Vector2(170, 0)
		_equipmentSection.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if enabled else Control.SIZE_FILL

	if _inventorySection != null:
		_inventorySection.custom_minimum_size = Vector2.ZERO
		_inventorySection.size_flags_vertical = Control.SIZE_EXPAND_FILL if enabled else Control.SIZE_FILL

	if _equipmentScroll != null:
		_equipmentScroll.custom_minimum_size = Vector2(0, 72) if enabled else Vector2.ZERO

	if _inventoryScroll != null:
		_inventoryScroll.custom_minimum_size = Vector2(0, 190) if enabled else Vector2.ZERO

	for lbl in _equipLabels:
		lbl.visible = not enabled

	if _inventoryGrid != null:
		_inventoryGrid.columns = 4 if enabled else 6

	var slotSize = Vector2(64, 64)
	for slot in _invSlots:
		slot.custom_minimum_size = slotSize
		slot.SetCompactMode(enabled)
	for slot in _equipSlots:
		slot.custom_minimum_size = slotSize
		slot.SetCompactMode(enabled)

func SetResponsiveWidth(panelWidth: float) -> void:
	if _inventoryGrid != null:
		_inventoryGrid.columns = 5 if panelWidth < 590.0 else 6

func StyleScrollbar(vsb: VScrollBar) -> void:
	if vsb == null:
		return
	vsb.custom_minimum_size = Vector2(14, 0)
	var grabber = load("res://external/fantasy_pixelart_ui/sliders/wood_grabber_normal.png")
	if grabber != null:
		var grabStyle = StyleBoxTexture.new()
		grabStyle.texture = grabber
		grabStyle.texture_margin_left = 2
		grabStyle.texture_margin_top = 2
		grabStyle.texture_margin_right = 2
		grabStyle.texture_margin_bottom = 2
		vsb.add_theme_stylebox_override("grabber", grabStyle)
		vsb.add_theme_stylebox_override("grabber_highlight", grabStyle)
		vsb.add_theme_stylebox_override("grabber_pressed", grabStyle)

	var scrollBgStyle = StyleBoxFlat.new()
	scrollBgStyle.bg_color = Color(0.08, 0.05, 0.04, 0.9)
	scrollBgStyle.border_color = Color(0.48, 0.28, 0.18, 1.0)
	scrollBgStyle.set_border_width_all(1)
	vsb.add_theme_stylebox_override("scroll", scrollBgStyle)
