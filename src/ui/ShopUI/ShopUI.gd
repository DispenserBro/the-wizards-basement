class_name ShopUI
extends PanelContainer

signal workshop_upgrade_purchased(property_index: int)

enum TutorialMode {
    None,
    WorkshopUpgrade,
    CloseOnly
}

var _tutorialMode: TutorialMode = TutorialMode.None
var _player: Player
var _goldLabel: Label

# Tabs
var _sellTab: VBoxContainer
var _equipTab: VBoxContainer
var _boostsTab: VBoxContainer
var _workshopTab: VBoxContainer
var _mainLayout: VBoxContainer
var _timerRow: HBoxContainer
var _sellScroll: ScrollContainer
var _equipScroll: ScrollContainer
var _boostsScroll: ScrollContainer
var _workshopScroll: ScrollContainer
var _boostsContainer: VBoxContainer
var _boostsMargin: MarginContainer
var _workshopMargin: MarginContainer

# Sell tab controls
var _sellGrid: GridContainer
var _sellAllBtn: Button
var _sellSlots: Array[InventorySlotUI] = []

# Equip tab controls
var _equipContainer: GridContainer
var _rotationTimerLabel: Label
var _refreshEquipBtn: Button
var _tabsGrid: GridContainer
var _rotatedItems: Array[ItemData] = []
var _refreshTimer: float = 300.0
var _activeEquipmentTooltip: ItemTooltipUI

# Workshop upgrade controls
var _workshopUpgradesContainer: VBoxContainer

# Confirmation overlay for equipment sale
var _confirmOverlay: PanelContainer
var _confirmLabel: Label
var _confirmYesBtn: Button
var _confirmNoBtn: Button
var _confirmSellSlotIndex: int = -1
var _tabButtons: Array[Button] = []
var _isCompactModeActive: bool = false
var _closeBtn: TextureButton
const REWARD_AD_COOLDOWN_SECONDS: int = 600
var _rewardedAdBtn: Button
var _adBoostButtons: Dictionary = {}

func Init(player: Player) -> void:
    _player = player
    if _player != null:
        _player.inventory_updated.connect(UpdateUI)
        if not _player.ad_boosts_updated.is_connected(UpdateAdBoostButtonsState):
            _player.ad_boosts_updated.connect(UpdateAdBoostButtonsState)

func IsWebPlatform() -> bool:
    var bridge = get_node_or_null("/root/BridgeManager")
    if bridge != null and bridge.has_method("is_active"):
        return bridge.is_active()
    return OS.has_feature("web") or OS.has_feature("editor")

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

    _goldLabel = %GoldLabel
    _mainLayout = get_node("MainLayout")
    _sellTab = %SellTab
    _equipTab = %EquipTab
    _boostsTab = %BoostsTab
    _workshopTab = %WorkshopTab
    _sellGrid = %SellGrid
    _sellAllBtn = %SellAllBtn
    _equipContainer = %EquipContainer
    _timerRow = get_node("MainLayout/BodyPanel/EquipTab/TimerRow")
    _rotationTimerLabel = %RotationTimerLabel
    _refreshEquipBtn = %RefreshEquipBtn
    _workshopUpgradesContainer = %WorkshopUpgradesContainer
    _confirmOverlay = %ConfirmOverlay
    _confirmLabel = %ConfirmLabel
    _confirmYesBtn = %ConfirmYesBtn
    _confirmNoBtn = %ConfirmNoBtn

    _closeBtn = %CloseButton
    _closeBtn.pressed.connect(func():
        if _tutorialMode != TutorialMode.WorkshopUpgrade:
            visible = false
    )

    _sellScroll = %SellScroll
    StyleScrollbar(_sellScroll.get_v_scroll_bar())

    _equipScroll = %EquipScroll
    StyleScrollbar(_equipScroll.get_v_scroll_bar())

    _boostsScroll = %BoostsScroll
    _boostsContainer = %BoostsContainer
    _boostsMargin = get_node("MainLayout/BodyPanel/BoostsTab/BoostsScroll/Margin")
    StyleScrollbar(_boostsScroll.get_v_scroll_bar())

    _workshopScroll = %WorkshopScroll
    _workshopMargin = get_node("MainLayout/BodyPanel/WorkshopTab/WorkshopScroll/Margin")
    StyleScrollbar(_workshopScroll.get_v_scroll_bar())

    var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")

    # Tab switcher row setup
    _tabsGrid = %TabsRow
    var tabSellBtn = CreateTabButton(tr("Продать"), font)
    var tabEquipBtn = CreateTabButton(tr("Снаряжение"), font)
    var tabBoostsBtn = CreateTabButton(tr("Бусты"), font)
    var tabWorkshopBtn = CreateTabButton(tr("Мастерская"), font)

    _tabButtons.append(tabSellBtn)
    _tabButtons.append(tabEquipBtn)
    _tabButtons.append(tabBoostsBtn)
    _tabButtons.append(tabWorkshopBtn)

    _tabsGrid.add_child(tabSellBtn)
    _tabsGrid.add_child(tabEquipBtn)
    _tabsGrid.add_child(tabBoostsBtn)
    _tabsGrid.add_child(tabWorkshopBtn)

    tabSellBtn.pressed.connect(func(): SwitchTab(0))
    tabEquipBtn.pressed.connect(func(): SwitchTab(1))
    tabBoostsBtn.pressed.connect(func(): SwitchTab(2))
    tabWorkshopBtn.pressed.connect(func(): SwitchTab(3))

    # Build sell grid slots
    for i in range(36):
        var slot = InventorySlotUI.new(i, false)
        slot.gui_input.connect(func(ev): OnSellSlotClicked(slot, ev))
        _sellGrid.add_child(slot)
        _sellSlots.append(slot)

    StyleGameButton(_sellAllBtn)
    _sellAllBtn.pressed.connect(OnSellAllPressed)

    StyleGameButton(_refreshEquipBtn)
    _refreshEquipBtn.pressed.connect(RefreshRotatedItemsForGold)

    StyleGameButton(_confirmYesBtn, "gold")
    _confirmYesBtn.pressed.connect(ConfirmSellEquipment)

    StyleGameButton(_confirmNoBtn)
    _confirmNoBtn.pressed.connect(func(): _confirmOverlay.visible = false)

    RotateEquipment()
    UpdateUI()

func _process(delta: float) -> void:
    _refreshTimer -= delta
    if _refreshTimer <= 0:
        _refreshTimer = 300.0
        RotateEquipment()

    if visible:
        var minutes = int(_refreshTimer / 60.0)
        var seconds = int(_refreshTimer) % 60
        _rotationTimerLabel.text = GameLocalization.Format("SHOP_REFRESH_TIMER", {"minutes": "%02d" % minutes, "seconds": "%02d" % seconds})
        if IsWebPlatform():
            UpdateRewardedAdButtonState()
            if _boostsTab != null and _boostsTab.visible:
                UpdateAdBoostButtonsState()

    if _confirmOverlay.visible:
        _confirmOverlay.position = (size - _confirmOverlay.size) / 2.0

func CreateTabButton(text: String, font: Font) -> Button:
    var btn = Button.new()
    btn.text = text
    if font != null:
        btn.add_theme_font_override("font", font)
    btn.add_theme_font_size_override("font_size", 14)
    btn.custom_minimum_size = Vector2(110, 32)
    StyleGameButton(btn)
    return btn

func StyleGameButton(button: Button, styleType: String = "wood") -> void:
    button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var normalTex = load("res://external/fantasy_pixelart_ui/buttons/" + styleType + "_button_normal.png")
    var pressedTex = load("res://external/fantasy_pixelart_ui/buttons/" + styleType + "_button_pressed.png")

    if normalTex != null:
        var normalStyle = StyleBoxTexture.new()
        normalStyle.texture = normalTex
        normalStyle.texture_margin_left = 4
        normalStyle.texture_margin_top = 4
        normalStyle.texture_margin_right = 4
        normalStyle.texture_margin_bottom = 4
        button.add_theme_stylebox_override("normal", normalStyle)

        var hoverStyle = normalStyle.duplicate() as StyleBoxTexture
        if hoverStyle != null:
            hoverStyle.modulate_color = Color(1.2, 1.2, 1.2, 1.0)
            button.add_theme_stylebox_override("hover", hoverStyle)

    if pressedTex != null:
        var pressedStyle = StyleBoxTexture.new()
        pressedStyle.texture = pressedTex
        pressedStyle.texture_margin_left = 4
        pressedStyle.texture_margin_top = 4
        pressedStyle.texture_margin_right = 4
        pressedStyle.texture_margin_bottom = 4
        button.add_theme_stylebox_override("pressed", pressedStyle)

        var disabledStyle = pressedStyle.duplicate() as StyleBoxTexture
        if disabledStyle != null:
            disabledStyle.modulate_color = Color(0.5, 0.5, 0.5, 0.7)
            button.add_theme_stylebox_override("disabled", disabledStyle)

    button.add_theme_color_override("font_color", Color.WHEAT)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_color_override("font_pressed_color", Color.KHAKI)
    button.add_theme_color_override("font_disabled_color", Color.DIM_GRAY)
    button.add_theme_color_override("font_focus_color", Color.WHEAT)

func SwitchTab(index: int) -> void:
    if _tutorialMode == TutorialMode.CloseOnly or (_tutorialMode == TutorialMode.WorkshopUpgrade and index != 3):
        return
    HideEquipmentTooltip()

    _sellTab.visible = (index == 0)
    _equipTab.visible = (index == 1)
    _boostsTab.visible = (index == 2)
    _workshopTab.visible = (index == 3)

    UpdateUI()

func UpdateHeader() -> void:
    if _player != null and _goldLabel != null:
        _goldLabel.text = GameLocalization.Format("GOLD_LONG", {"amount": _player.Gold})

func UpdateUI() -> void:
    if _player == null:
        return

    UpdateHeader()

    for i in range(36):
        if i < _sellSlots.size():
            _sellSlots[i].SetPlayer(_player)
            _sellSlots[i].SetItem(_player.Inventory[i])

    UpdateEquipmentTab()
    UpdateBoostsTab()
    UpdateWorkshopTab()

func UpdateEquipmentTab() -> void:
    HideEquipmentTooltip()
    for child in _equipContainer.get_children():
        child.queue_free()

    var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")

    for i in range(_rotatedItems.size()):
        var item = _rotatedItems[i]
        var card = VBoxContainer.new()
        card.alignment = BoxContainer.ALIGNMENT_CENTER
        card.custom_minimum_size = Vector2(0, 150) if _isCompactModeActive else Vector2(110, 180)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.add_theme_constant_override("separation", 2 if _isCompactModeActive else 4)
        card.mouse_filter = Control.MOUSE_FILTER_STOP
        _equipContainer.add_child(card)

        if item == null:
            var soldLabel = Label.new()
            soldLabel.text = tr("КУПЛЕНО")
            soldLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            if font != null:
                soldLabel.add_theme_font_override("font", font)
            soldLabel.add_theme_font_size_override("font_size", 16)
            soldLabel.add_theme_color_override("font_color", Color.GRAY)
            card.add_child(soldLabel)
            continue

        var slotFrame = PanelContainer.new()
        slotFrame.custom_minimum_size = Vector2(44, 44) if _isCompactModeActive else Vector2(64, 64)
        slotFrame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        slotFrame.mouse_filter = Control.MOUSE_FILTER_IGNORE
        
        var rarityColor = Color.TRANSPARENT
        match item.Rarity:
            ItemData.ItemRarity.Uncommon: rarityColor = Color.GREEN
            ItemData.ItemRarity.Rare: rarityColor = Color.DEEP_SKY_BLUE
            ItemData.ItemRarity.Epic: rarityColor = Color.MEDIUM_PURPLE
            ItemData.ItemRarity.Legendary: rarityColor = Color.GOLD

        var frameStyle = StyleBoxFlat.new()
        if rarityColor != Color.TRANSPARENT:
            var bg = rarityColor
            bg.a = 0.35
            frameStyle.bg_color = bg
        else:
            frameStyle.bg_color = Color(0.2, 0.15, 0.1, 0.6)

        frameStyle.set_border_width_all(2)
        frameStyle.border_color = Color(0.35, 0.25, 0.15)
        frameStyle.set_corner_radius_all(4)
        slotFrame.add_theme_stylebox_override("panel", frameStyle)
        card.add_child(slotFrame)

        var icon = TextureRect.new()
        if not item.IconTexturePath.is_empty():
            icon.texture = load(item.IconTexturePath)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        icon.anchor_left = 0.0
        icon.anchor_right = 1.0
        icon.anchor_top = 0.0
        icon.anchor_bottom = 1.0
        icon.offset_left = 10
        icon.offset_right = -10
        icon.offset_top = 10
        icon.offset_bottom = -10
        slotFrame.add_child(icon)

        var nameLabel = Label.new()
        nameLabel.text = GameLocalization.ItemName(item)
        nameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        nameLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        nameLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
        if font != null:
            nameLabel.add_theme_font_override("font", font)
        nameLabel.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 16)
        nameLabel.add_theme_color_override("font_color", rarityColor if rarityColor != Color.TRANSPARENT else Color.WHITE)
        card.add_child(nameLabel)

        var price = ItemDatabase.get_buy_price(item)
        var priceLabel = Label.new()
        priceLabel.text = GameLocalization.Format("GOLD_SHORT", {"amount": price})
        priceLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        priceLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
        if font != null:
            priceLabel.add_theme_font_override("font", font)
        priceLabel.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 15)
        priceLabel.add_theme_color_override("font_color", Color.GOLD)
        card.add_child(priceLabel)

        var buyBtn = Button.new()
        buyBtn.text = tr("Купить")
        if font != null:
            buyBtn.add_theme_font_override("font", font)
        buyBtn.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 14)
        if _isCompactModeActive:
            buyBtn.custom_minimum_size = Vector2(0, 36)
        StyleGameButton(buyBtn)
        buyBtn.disabled = _tutorialMode != TutorialMode.None or _player.Gold < price
        
        var indexCopy = i
        buyBtn.pressed.connect(func(): BuyEquipment(indexCopy))
        card.add_child(buyBtn)

        var tooltipItem = item
        var tooltipPrice = price
        card.mouse_entered.connect(func(): ShowEquipmentTooltip(tooltipItem, tooltipPrice))
        card.mouse_exited.connect(HideEquipmentTooltip)
        buyBtn.mouse_entered.connect(func(): ShowEquipmentTooltip(tooltipItem, tooltipPrice))

func ShowEquipmentTooltip(item: ItemData, buyPrice: int) -> void:
    HideEquipmentTooltip()
    if item == null or not visible or not _equipTab.visible:
        return

    _activeEquipmentTooltip = ItemTooltipUI.new(item, ItemTooltipUI.PriceMode.Buy, buyPrice)

    var tooltipHost: Node = get_parent()
    while tooltipHost != null and not (tooltipHost is CanvasLayer):
        tooltipHost = tooltipHost.get_parent()

    if tooltipHost != null:
        tooltipHost.add_child(_activeEquipmentTooltip)
    else:
        get_tree().root.add_child(_activeEquipmentTooltip)

func HideEquipmentTooltip() -> void:
    if _activeEquipmentTooltip != null and is_instance_valid(_activeEquipmentTooltip):
        _activeEquipmentTooltip.queue_free()
    _activeEquipmentTooltip = null

func UpdateBoostsTab() -> void:
    for child in _boostsContainer.get_children():
        child.queue_free()
    _adBoostButtons.clear()

    var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")

    if IsWebPlatform():
        # 1. Section: Timed Ad Boosts
        RenderSectionHeader(tr("BOOST_SECTION_AD"), font)

        RenderAdBoostCard(font, "gold", tr("BOOST_RUSH_TITLE"), tr("BOOST_RUSH_DESC"),
            "res://external/fantasy_pixelart_ui/icons/gold_star.png", Color.GOLD)

        RenderAdBoostCard(font, "damage", tr("BOOST_FURY_TITLE"), tr("BOOST_FURY_DESC"),
            "res://external/fantasy_pixelart_ui/icons/gold_sword.png", Color(1.0, 0.4, 0.2))

        RenderAdBoostCard(font, "swiftness", tr("BOOST_SWIFT_TITLE"), tr("BOOST_SWIFT_DESC"),
            "res://external/fantasy_pixelart_ui/icons/gold_feather.png", Color(0.3, 0.9, 0.4))

        RenderAdBoostCard(font, "luck", tr("BOOST_LUCK_TITLE"), tr("BOOST_LUCK_DESC"),
            "res://external/fantasy_pixelart_ui/icons/gold_castle.png", Color(0.3, 0.8, 1.0))

        # 2. Section: Free Gold Ad
        RenderRewardedAdCard(font)

        # 3. Section: Elixirs & Scrolls for Gold
        RenderSectionHeader(tr("BOOST_SECTION_GOLD"), font)
    else:
        RenderSectionHeader(tr("Усиления"), font)

    var boostIds = [ "cons_wrath_elixir", "cons_lucky_elixir", "cons_haste_scroll" ]
    for bid in boostIds:
        var item = ItemDatabase.get_item(bid)
        if item == null:
            continue

        var card = HBoxContainer.new()
        card.custom_minimum_size = Vector2(0, 112 if _isCompactModeActive else 96)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _boostsContainer.add_child(card)

        var panel = PanelContainer.new()
        panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        
        var panelStyle = StyleBoxFlat.new()
        panelStyle.bg_color = Color(0.18, 0.12, 0.08, 0.85)
        panelStyle.set_border_width_all(2)
        panelStyle.border_color = Color(0.35, 0.25, 0.15)
        panelStyle.set_corner_radius_all(4)
        panel.add_theme_stylebox_override("panel", panelStyle)
        card.add_child(panel)

        var innerHBox = HBoxContainer.new()
        innerHBox.add_theme_constant_override("separation", 5 if _isCompactModeActive else 12)
        panel.add_child(innerHBox)

        var iconFrame = PanelContainer.new()
        iconFrame.custom_minimum_size = Vector2(40, 40) if _isCompactModeActive else Vector2(48, 48)
        iconFrame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        
        var iconStyle = StyleBoxFlat.new()
        iconStyle.bg_color = Color(0.15, 0.1, 0.08, 0.7)
        iconStyle.set_corner_radius_all(3)
        iconFrame.add_theme_stylebox_override("panel", iconStyle)
        innerHBox.add_child(iconFrame)

        var iconTex = TextureRect.new()
        if not item.IconTexturePath.is_empty():
            iconTex.texture = load(item.IconTexturePath)
        iconTex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        iconTex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        iconTex.anchor_left = 0.0
        iconTex.anchor_right = 1.0
        iconTex.anchor_top = 0.0
        iconTex.anchor_bottom = 1.0
        iconTex.offset_left = 5 if _isCompactModeActive else 6
        iconTex.offset_right = -5 if _isCompactModeActive else -6
        iconTex.offset_top = 5 if _isCompactModeActive else 6
        iconTex.offset_bottom = -5 if _isCompactModeActive else -6
        iconFrame.add_child(iconTex)

        var textVBox = VBoxContainer.new()
        textVBox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        textVBox.alignment = BoxContainer.ALIGNMENT_CENTER
        innerHBox.add_child(textVBox)

        var titleLabel = Label.new()
        titleLabel.text = GameLocalization.ItemName(item)
        if font != null:
            titleLabel.add_theme_font_override("font", font)
        titleLabel.add_theme_font_size_override("font_size", 20 if _isCompactModeActive else 16)
        titleLabel.add_theme_color_override("font_color", Color.KHAKI)
        textVBox.add_child(titleLabel)

        var descLabel = Label.new()
        descLabel.text = GameLocalization.ItemDescription(item)
        descLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        if font != null:
            descLabel.add_theme_font_override("font", font)
        descLabel.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 15)
        descLabel.add_theme_color_override("font_color", Color.LIGHT_GRAY)
        textVBox.add_child(descLabel)

        var actionVBox = VBoxContainer.new()
        actionVBox.alignment = BoxContainer.ALIGNMENT_CENTER
        actionVBox.custom_minimum_size = Vector2(76, 0) if _isCompactModeActive else Vector2(120, 0)
        innerHBox.add_child(actionVBox)

        var price = ItemDatabase.get_buy_price(item)
        var costLabel = Label.new()
        costLabel.text = GameLocalization.Format("GOLD_SHORT", {"amount": price})
        costLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        if font != null:
            costLabel.add_theme_font_override("font", font)
        costLabel.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 15)
        costLabel.add_theme_color_override("font_color", Color.GOLD)
        actionVBox.add_child(costLabel)

        var buyBtn = Button.new()
        buyBtn.text = tr("Купить")
        if font != null:
            buyBtn.add_theme_font_override("font", font)
        buyBtn.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 14)
        if _isCompactModeActive:
            buyBtn.custom_minimum_size = Vector2(0, 36)
        StyleGameButton(buyBtn)
        buyBtn.disabled = _tutorialMode != TutorialMode.None or _player.Gold < price
        buyBtn.pressed.connect(func(): BuyBoost(item, price))
        actionVBox.add_child(buyBtn)

    if IsWebPlatform():
        UpdateAdBoostButtonsState()
        UpdateRewardedAdButtonState()

func RenderRewardedAdCard(font: Font) -> void:
    var card = HBoxContainer.new()
    card.custom_minimum_size = Vector2(0, 112 if _isCompactModeActive else 96)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _boostsContainer.add_child(card)

    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var panelStyle = StyleBoxFlat.new()
    panelStyle.bg_color = Color(0.22, 0.16, 0.06, 0.95)
    panelStyle.set_border_width_all(2)
    panelStyle.border_color = Color(0.85, 0.65, 0.15)
    panelStyle.set_corner_radius_all(4)
    panel.add_theme_stylebox_override("panel", panelStyle)
    card.add_child(panel)

    var innerHBox = HBoxContainer.new()
    innerHBox.add_theme_constant_override("separation", 5 if _isCompactModeActive else 12)
    panel.add_child(innerHBox)

    var iconFrame = PanelContainer.new()
    iconFrame.custom_minimum_size = Vector2(40, 40) if _isCompactModeActive else Vector2(48, 48)
    iconFrame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    
    var iconStyle = StyleBoxFlat.new()
    iconStyle.bg_color = Color(0.35, 0.25, 0.05, 0.8)
    iconStyle.set_corner_radius_all(3)
    iconFrame.add_theme_stylebox_override("panel", iconStyle)
    innerHBox.add_child(iconFrame)

    var iconTex = TextureRect.new()
    if ResourceLoader.exists("res://materials/coins.png"):
        iconTex.texture = load("res://materials/coins.png")
    iconTex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    iconTex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    iconTex.anchor_left = 0.0
    iconTex.anchor_right = 1.0
    iconTex.anchor_top = 0.0
    iconTex.anchor_bottom = 1.0
    iconTex.offset_left = 4
    iconTex.offset_right = -4
    iconTex.offset_top = 4
    iconTex.offset_bottom = -4
    iconFrame.add_child(iconTex)

    var textVBox = VBoxContainer.new()
    textVBox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    textVBox.alignment = BoxContainer.ALIGNMENT_CENTER
    innerHBox.add_child(textVBox)

    var titleLabel = Label.new()
    titleLabel.text = tr("REWARD_GOLD_TITLE")
    if font != null:
        titleLabel.add_theme_font_override("font", font)
    titleLabel.add_theme_font_size_override("font_size", 20 if _isCompactModeActive else 16)
    titleLabel.add_theme_color_override("font_color", Color.GOLD)
    textVBox.add_child(titleLabel)

    var descLabel = Label.new()
    descLabel.text = tr("REWARD_GOLD_DESC")
    descLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    if font != null:
        descLabel.add_theme_font_override("font", font)
    descLabel.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 15)
    descLabel.add_theme_color_override("font_color", Color.LIGHT_GOLDENROD)
    textVBox.add_child(descLabel)

    var actionVBox = VBoxContainer.new()
    actionVBox.alignment = BoxContainer.ALIGNMENT_CENTER
    actionVBox.custom_minimum_size = Vector2(76, 0) if _isCompactModeActive else Vector2(120, 0)
    innerHBox.add_child(actionVBox)

    var watchBtn = Button.new()
    _rewardedAdBtn = watchBtn
    if font != null:
        watchBtn.add_theme_font_override("font", font)
    watchBtn.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 14)
    if _isCompactModeActive:
        watchBtn.custom_minimum_size = Vector2(0, 36)
    StyleGameButton(watchBtn, "gold")
    watchBtn.pressed.connect(OnWatchRewardedAdPressed)
    actionVBox.add_child(watchBtn)
    UpdateRewardedAdButtonState()

func UpdateRewardedAdButtonState() -> void:
    if _rewardedAdBtn == null or not is_instance_valid(_rewardedAdBtn):
        return
    if _player == null:
        return

    var now = int(Time.get_unix_time_from_system())
    var elapsed = now - _player.LastRewardedAdTime
    var remaining = REWARD_AD_COOLDOWN_SECONDS - elapsed

    if _player.LastRewardedAdTime > 0 and remaining > 0:
        _rewardedAdBtn.disabled = true
        var mins = int(remaining / 60.0)
        var secs = remaining % 60
        _rewardedAdBtn.text = "%02d:%02d 🎬" % [mins, secs]
    else:
        _rewardedAdBtn.disabled = false
        _rewardedAdBtn.text = tr("REWARD_WATCH_BTN")

func OnWatchRewardedAdPressed() -> void:
    if not IsWebPlatform():
        return

    var now = int(Time.get_unix_time_from_system())
    var elapsed = now - _player.LastRewardedAdTime
    var remaining = REWARD_AD_COOLDOWN_SECONDS - elapsed
    if _player.LastRewardedAdTime > 0 and remaining > 0:
        return

    var reward_gold = 500 + (_player.Level * 50)
    var bridge = get_node_or_null("/root/BridgeManager")
    if bridge != null and bridge.is_active():
        bridge.ShowRewarded(func(success: bool):
            if success:
                _player.LastRewardedAdTime = int(Time.get_unix_time_from_system())
                _player.Gold += reward_gold
                _player.SaveSettings()
                ShowToast(GameLocalization.Format("REWARD_GOLD_RECEIVED", {"amount": reward_gold}))
                UpdateHeader()
                UpdateRewardedAdButtonState()
                UpdateAdBoostButtonsState()
                UpdateBoostsTab()
            else:
                ShowToast(tr("Реклама не была досмотрена"))
        )

func RenderSectionHeader(text: String, font: Font) -> void:
    var headerPanel = PanelContainer.new()
    headerPanel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.14, 0.09, 0.06, 0.7)
    style.set_corner_radius_all(3)
    style.set_content_margin_all(6)
    headerPanel.add_theme_stylebox_override("panel", style)
    
    var headerLabel = Label.new()
    headerLabel.text = text
    headerLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if font != null:
        headerLabel.add_theme_font_override("font", font)
    headerLabel.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 15)
    headerLabel.add_theme_color_override("font_color", Color.GOLD)
    headerPanel.add_child(headerLabel)
    _boostsContainer.add_child(headerPanel)

func RenderAdBoostCard(font: Font, boostType: String, title: String, desc: String, iconPath: String, iconBorderColor: Color) -> void:
    var card = HBoxContainer.new()
    card.custom_minimum_size = Vector2(0, 112 if _isCompactModeActive else 96)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _boostsContainer.add_child(card)

    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var panelStyle = StyleBoxFlat.new()
    panelStyle.bg_color = Color(0.18, 0.12, 0.08, 0.9)
    panelStyle.set_border_width_all(2)
    panelStyle.border_color = iconBorderColor.lerp(Color(0.35, 0.25, 0.15), 0.5)
    panelStyle.set_corner_radius_all(4)
    panel.add_theme_stylebox_override("panel", panelStyle)
    card.add_child(panel)

    var innerHBox = HBoxContainer.new()
    innerHBox.add_theme_constant_override("separation", 5 if _isCompactModeActive else 12)
    panel.add_child(innerHBox)

    var iconFrame = PanelContainer.new()
    iconFrame.custom_minimum_size = Vector2(40, 40) if _isCompactModeActive else Vector2(48, 48)
    iconFrame.size_flags_vertical = Control.SIZE_SHRINK_CENTER

    var iconStyle = StyleBoxFlat.new()
    iconStyle.bg_color = Color(0.15, 0.1, 0.08, 0.7)
    iconStyle.border_color = iconBorderColor
    iconStyle.set_border_width_all(1)
    iconStyle.set_corner_radius_all(3)
    iconFrame.add_theme_stylebox_override("panel", iconStyle)
    innerHBox.add_child(iconFrame)

    var iconTex = TextureRect.new()
    if not iconPath.is_empty() and ResourceLoader.exists(iconPath):
        iconTex.texture = load(iconPath)
    iconTex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    iconTex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    iconTex.anchor_left = 0.0
    iconTex.anchor_right = 1.0
    iconTex.anchor_top = 0.0
    iconTex.anchor_bottom = 1.0
    iconTex.offset_left = 4
    iconTex.offset_right = -4
    iconTex.offset_top = 4
    iconTex.offset_bottom = -4
    iconFrame.add_child(iconTex)

    var textVBox = VBoxContainer.new()
    textVBox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    textVBox.alignment = BoxContainer.ALIGNMENT_CENTER
    innerHBox.add_child(textVBox)

    var titleLabel = Label.new()
    titleLabel.text = title
    if font != null:
        titleLabel.add_theme_font_override("font", font)
    titleLabel.add_theme_font_size_override("font_size", 20 if _isCompactModeActive else 16)
    titleLabel.add_theme_color_override("font_color", iconBorderColor)
    textVBox.add_child(titleLabel)

    var descLabel = Label.new()
    descLabel.text = desc
    descLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    if font != null:
        descLabel.add_theme_font_override("font", font)
    descLabel.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 15)
    descLabel.add_theme_color_override("font_color", Color.LIGHT_GRAY)
    textVBox.add_child(descLabel)

    var actionVBox = VBoxContainer.new()
    actionVBox.alignment = BoxContainer.ALIGNMENT_CENTER
    actionVBox.custom_minimum_size = Vector2(76, 0) if _isCompactModeActive else Vector2(120, 0)
    innerHBox.add_child(actionVBox)

    var watchBtn = Button.new()
    if font != null:
        watchBtn.add_theme_font_override("font", font)
    watchBtn.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 14)
    if _isCompactModeActive:
        watchBtn.custom_minimum_size = Vector2(0, 36)
    StyleGameButton(watchBtn, "gold")
    var boostTypeCopy = boostType
    var titleCopy = title
    watchBtn.pressed.connect(func(): WatchAdForBoost(boostTypeCopy, titleCopy))
    actionVBox.add_child(watchBtn)

    _adBoostButtons[boostType] = watchBtn

func WatchAdForBoost(boostType: String, boostTitle: String) -> void:
    if not IsWebPlatform():
        return

    var now = int(Time.get_unix_time_from_system())
    var elapsed = now - _player.LastRewardedAdTime
    var remaining = REWARD_AD_COOLDOWN_SECONDS - elapsed
    if _player.LastRewardedAdTime > 0 and remaining > 0:
        return

    var bridge = get_node_or_null("/root/BridgeManager")
    if bridge != null and bridge.is_active():
        bridge.ShowRewarded(func(success: bool):
            if success:
                _player.LastRewardedAdTime = int(Time.get_unix_time_from_system())
                _player.ActivateAdBoost(boostType)
                ShowToast(GameLocalization.Format("BOOST_ACTIVATED", {"name": boostTitle}))
                UpdateRewardedAdButtonState()
                UpdateAdBoostButtonsState()
                UpdateBoostsTab()
            else:
                ShowToast(tr("Реклама не была досмотрена"))
        )

func UpdateAdBoostButtonsState() -> void:
    if _player == null:
        return
    var now = int(Time.get_unix_time_from_system())
    var elapsed = now - _player.LastRewardedAdTime
    var cooldown_remaining = REWARD_AD_COOLDOWN_SECONDS - elapsed
    var is_on_ad_cooldown = _player.LastRewardedAdTime > 0 and cooldown_remaining > 0

    for boostType in _adBoostButtons:
        var btn: Button = _adBoostButtons[boostType]
        if btn == null or not is_instance_valid(btn):
            continue
        var timer: float = 0.0
        match boostType:
            "gold": timer = _player.AdGoldBoostTimer
            "damage": timer = _player.AdDamageBoostTimer
            "swiftness": timer = _player.AdSwiftnessBoostTimer
            "luck": timer = _player.AdLuckBoostTimer
        
        if timer > 0.0:
            var mins = int(timer / 60.0)
            var secs = int(timer) % 60
            btn.text = "%02d:%02d 🟢" % [mins, secs]
            btn.disabled = true
        elif is_on_ad_cooldown:
            var mins = int(cooldown_remaining / 60.0)
            var secs = cooldown_remaining % 60
            btn.text = "%02d:%02d 🎬" % [mins, secs]
            btn.disabled = true
        else:
            btn.disabled = false
            btn.text = tr("REWARD_WATCH_BTN")

func UpdateWorkshopTab() -> void:
    if _workshopUpgradesContainer == null:
        return
    for child in _workshopUpgradesContainer.get_children():
        child.queue_free()

    var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")

    # Cauldron upgrade
    var cauldronCost = 100 * (_player.CauldronLevel + 1)
    RenderUpgradeRow(0, tr("Больший котёл"),
        GameLocalization.Format("WORKSHOP_CAULDRON_DESCRIPTION", {"level": _player.CauldronLevel, "bonus": _player.CauldronLevel * 10}),
        cauldronCost, _player.CauldronLevel, func(): UpgradeWorkshopProperty(0, cauldronCost), font)

    # Crystal upgrade
    var crystalCost = 120 * (_player.CrystalLevel + 1)
    RenderUpgradeRow(1, tr("Кристалл прозрения"),
        GameLocalization.Format("WORKSHOP_CRYSTAL_DESCRIPTION", {"level": _player.CrystalLevel, "bonus": _player.CrystalLevel * 5}),
        crystalCost, _player.CrystalLevel, func(): UpgradeWorkshopProperty(1, crystalCost), font)

    # Enchantment upgrade
    var enchantCost = 150 * (_player.EnchantLevel + 1)
    RenderUpgradeRow(2, tr("Усиленные чары"),
        GameLocalization.Format("WORKSHOP_ENCHANT_DESCRIPTION", {"level": _player.EnchantLevel, "bonus": _player.EnchantLevel * 15}),
        enchantCost, _player.EnchantLevel, func(): UpgradeWorkshopProperty(2, enchantCost), font)

func RenderUpgradeRow(propertyIndex: int, title: String, description: String, cost: int, _level: int, upgradeAction: Callable, font: Font) -> void:
    var row = HBoxContainer.new()
    row.custom_minimum_size = Vector2(0, 112 if _isCompactModeActive else 96)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _workshopUpgradesContainer.add_child(row)

    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var panelStyle = StyleBoxFlat.new()
    panelStyle.bg_color = Color(0.18, 0.12, 0.08, 0.85)
    panelStyle.set_border_width_all(2)
    panelStyle.border_color = Color(0.35, 0.25, 0.15)
    panelStyle.set_corner_radius_all(4)
    panel.add_theme_stylebox_override("panel", panelStyle)
    row.add_child(panel)

    var innerHBox = HBoxContainer.new()
    innerHBox.add_theme_constant_override("separation", 5 if _isCompactModeActive else 12)
    panel.add_child(innerHBox)

    var iconFrame = PanelContainer.new()
    iconFrame.custom_minimum_size = Vector2(40, 40) if _isCompactModeActive else Vector2(48, 48)
    iconFrame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    
    var iconStyle = StyleBoxFlat.new()
    iconStyle.bg_color = Color(0.15, 0.1, 0.08, 0.7)
    iconStyle.set_corner_radius_all(3)
    iconFrame.add_theme_stylebox_override("panel", iconStyle)
    innerHBox.add_child(iconFrame)

    var iconTex = TextureRect.new()
    iconTex.texture = load("res://external/fantasy_pixelart_ui/icons/gold_anvil.png")
    iconTex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    iconTex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    iconTex.anchor_left = 0.0
    iconTex.anchor_right = 1.0
    iconTex.anchor_top = 0.0
    iconTex.anchor_bottom = 1.0
    iconTex.offset_left = 5 if _isCompactModeActive else 6
    iconTex.offset_right = -5 if _isCompactModeActive else -6
    iconTex.offset_top = 5 if _isCompactModeActive else 6
    iconTex.offset_bottom = -5 if _isCompactModeActive else -6
    iconFrame.add_child(iconTex)

    var textVBox = VBoxContainer.new()
    textVBox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    textVBox.alignment = BoxContainer.ALIGNMENT_CENTER
    innerHBox.add_child(textVBox)

    var titleLabel = Label.new()
    titleLabel.text = title
    if font != null:
        titleLabel.add_theme_font_override("font", font)
    titleLabel.add_theme_font_size_override("font_size", 20 if _isCompactModeActive else 16)
    titleLabel.add_theme_color_override("font_color", Color.KHAKI)
    textVBox.add_child(titleLabel)

    var descLabel = Label.new()
    descLabel.text = description
    descLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    if font != null:
        descLabel.add_theme_font_override("font", font)
    descLabel.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 15)
    descLabel.add_theme_color_override("font_color", Color.LIGHT_GRAY)
    textVBox.add_child(descLabel)

    var actionVBox = VBoxContainer.new()
    actionVBox.alignment = BoxContainer.ALIGNMENT_CENTER
    actionVBox.custom_minimum_size = Vector2(76, 0) if _isCompactModeActive else Vector2(120, 0)
    innerHBox.add_child(actionVBox)

    var costLabel = Label.new()
    costLabel.text = GameLocalization.Format("GOLD_SHORT", {"amount": cost})
    costLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if font != null:
        costLabel.add_theme_font_override("font", font)
    costLabel.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 15)
    costLabel.add_theme_color_override("font_color", Color.GOLD)
    actionVBox.add_child(costLabel)

    var upgradeBtn = Button.new()
    upgradeBtn.text = tr("Улучшить")
    if font != null:
        upgradeBtn.add_theme_font_override("font", font)
    upgradeBtn.add_theme_font_size_override("font_size", 18 if _isCompactModeActive else 14)
    if _isCompactModeActive:
        upgradeBtn.custom_minimum_size = Vector2(0, 36)
    StyleGameButton(upgradeBtn)
    var blockedByTutorial = _tutorialMode == TutorialMode.CloseOnly or (_tutorialMode == TutorialMode.WorkshopUpgrade and propertyIndex != 0)
    upgradeBtn.disabled = blockedByTutorial or _player.Gold < cost
    upgradeBtn.pressed.connect(upgradeAction)
    actionVBox.add_child(upgradeBtn)

func RotateEquipment() -> void:
    _rotatedItems.clear()
    var pool = ItemDatabase.get_all_predefined_equipment()
    if pool.size() == 0:
        return

    for i in range(4):
        var randomIndex = randi() % pool.size()
        _rotatedItems.append(pool[randomIndex].duplicate_item())

func RefreshRotatedItemsForGold() -> void:
    if _tutorialMode != TutorialMode.None or _player == null or _player.Gold < 50:
        return

    _player.Gold -= 50
    GameAudio.Play(GameAudio.COIN, 0.04)
    RotateEquipment()
    UpdateUI()

    FloatingTextHelper.spawn(get_parent(), get_global_position(), GameLocalization.Format("GOLD_SPENT", {"amount": 50}), Color.RED, 8, 1.0)

func BuyEquipment(index: int) -> void:
    if _tutorialMode != TutorialMode.None:
        return
    if index < 0 or index >= _rotatedItems.size():
        return
    var item = _rotatedItems[index]
    if item == null:
        return

    var price = ItemDatabase.get_buy_price(item)
    if _player.Gold < price:
        return

    if _player.AddToInventory(item):
        _player.Gold -= price
        GameAudio.Play(GameAudio.COIN, 0.04)
        _rotatedItems[index] = null
        UpdateUI()

        FloatingTextHelper.spawn(get_parent(), get_global_position(), GameLocalization.Format("ITEM_RECEIVED", {"item": GameLocalization.ItemName(item)}), Color.GREEN, 8, 1.0)
    else:
        ShowToast(tr("Инвентарь полон!"))

func BuyBoost(item: ItemData, price: int) -> void:
    if _tutorialMode != TutorialMode.None or _player == null or _player.Gold < price:
        return

    if _player.AddToInventory(item):
        _player.Gold -= price
        GameAudio.Play(GameAudio.COIN, 0.04)
        UpdateUI()
        FloatingTextHelper.spawn(get_parent(), get_global_position(), GameLocalization.Format("ITEM_RECEIVED", {"item": GameLocalization.ItemName(item)}), Color.GREEN, 8, 1.0)
    else:
        ShowToast(tr("Инвентарь полон!"))

func UpgradeWorkshopProperty(propertyIndex: int, cost: int) -> void:
    if _tutorialMode == TutorialMode.CloseOnly or _player == null or _player.Gold < cost:
        return
    if _tutorialMode == TutorialMode.WorkshopUpgrade and propertyIndex != 0:
        return

    _player.Gold -= cost
    GameAudio.Play(GameAudio.POWER_UP)
    if propertyIndex == 0:
        _player.CauldronLevel += 1
    elif propertyIndex == 1:
        _player.CrystalLevel += 1
    elif propertyIndex == 2:
        _player.EnchantLevel += 1

    UpdateUI()
    workshop_upgrade_purchased.emit(propertyIndex)

    FloatingTextHelper.spawn(get_parent(), get_global_position(), tr("Улучшено!"), Color.GREEN, 8, 1.0)

func OnSellSlotClicked(slot: InventorySlotUI, event: InputEvent) -> void:
    if _tutorialMode != TutorialMode.None:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var slotIndex = slot.SlotIndex
        var item = _player.Inventory[slotIndex]
        if item == null:
            return

        if item.Type == ItemData.ItemType.Staff or item.Type == ItemData.ItemType.Stone or item.Type == ItemData.ItemType.Amulet:
            _confirmSellSlotIndex = slotIndex
            _confirmLabel.text = GameLocalization.Format("SELL_ITEM_CONFIRM", {"item": GameLocalization.ItemName(item), "amount": item.SellValue})
            _confirmOverlay.visible = true
        else:
            _player.SellItem(slotIndex)
            GameAudio.Play(GameAudio.COIN, 0.04)
            UpdateUI()
            FloatingTextHelper.spawn(get_parent(), get_global_position(), GameLocalization.Format("GOLD_RECEIVED", {"amount": item.SellValue * item.StackCount}), Color.GOLD, 8, 1.0)

func ConfirmSellEquipment() -> void:
    if _tutorialMode != TutorialMode.None:
        return
    if _confirmSellSlotIndex < 0 or _confirmSellSlotIndex >= _player.Inventory.size():
        return
    var item = _player.Inventory[_confirmSellSlotIndex]
    if item != null:
        var payout = item.SellValue
        _player.SellItem(_confirmSellSlotIndex)
        GameAudio.Play(GameAudio.COIN, 0.04)
        FloatingTextHelper.spawn(get_parent(), get_global_position(), GameLocalization.Format("GOLD_RECEIVED", {"amount": payout}), Color.GOLD, 8, 1.0)
    _confirmOverlay.visible = false
    UpdateUI()

func OnSellAllPressed() -> void:
    if _tutorialMode != TutorialMode.None or _player == null:
        return

    var totalPayout = 0
    var itemsSold = 0

    for i in range(_player.Inventory.size()):
        var item = _player.Inventory[i]
        if item != null and item.Type == ItemData.ItemType.Material:
            totalPayout += item.SellValue * item.StackCount
            _player.Inventory[i] = null
            itemsSold += 1

    if itemsSold > 0:
        _player.Gold += totalPayout
        GameAudio.Play(GameAudio.COIN, 0.04)
        _player.inventory_updated.emit()
        UpdateUI()
        FloatingTextHelper.spawn(get_parent(), get_global_position(), GameLocalization.Format("ALL_MATERIALS_SOLD", {"amount": totalPayout}), Color.GOLD, 9, 1.1)
    else:
        ShowToast(tr("В инвентаре нет материалов для продажи"))

func ShowToast(message: String) -> void:
    if _isCompactModeActive:
        return

    var toast = get_node_or_null("/root/GodotxToast")
    if toast != null and toast.has_method("show"):
        toast.call("show", message)

func _notification(what: int) -> void:
    if what == NOTIFICATION_VISIBILITY_CHANGED:
        if not visible:
            if _confirmOverlay != null:
                _confirmOverlay.visible = false
            HideEquipmentTooltip()

func SetCompactMode(enabled: bool) -> void:
    custom_minimum_size = Vector2(352, 352) if enabled else Vector2(660, 500)
    _isCompactModeActive = enabled

    if _mainLayout != null:
        _mainLayout.add_theme_constant_override("separation", 2 if enabled else 4)
    if _sellTab != null:
        _sellTab.add_theme_constant_override("separation", 4 if enabled else 10)
    if _equipTab != null:
        _equipTab.add_theme_constant_override("separation", 4 if enabled else 10)
    if _boostsContainer != null:
        _boostsContainer.add_theme_constant_override("separation", 6 if enabled else 10)
    if _workshopUpgradesContainer != null:
        _workshopUpgradesContainer.add_theme_constant_override("separation", 6 if enabled else 10)

    SetContainerMargins(_boostsMargin, 5 if enabled else 12)
    SetContainerMargins(_workshopMargin, 5 if enabled else 12)

    SetVerticalScrollMode(_sellScroll, enabled)
    SetVerticalScrollMode(_equipScroll, enabled)
    SetVerticalScrollMode(_boostsScroll, enabled)
    SetVerticalScrollMode(_workshopScroll, enabled)

    if _sellGrid != null:
        _sellGrid.columns = 4 if enabled else 6

    var slotSize = Vector2(64, 64)
    for slot in _sellSlots:
        slot.custom_minimum_size = slotSize

    for btn in _tabButtons:
        btn.add_theme_font_size_override("font_size", 17 if enabled else 14)
        btn.custom_minimum_size = Vector2(0, 34) if enabled else Vector2(110, 32)
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if enabled else Control.SIZE_SHRINK_CENTER

    if _tabsGrid != null:
        _tabsGrid.columns = 2 if enabled else 4
        _tabsGrid.add_theme_constant_override("h_separation", 4 if enabled else 8)
        _tabsGrid.add_theme_constant_override("v_separation", 2 if enabled else 4)

    if _equipContainer != null:
        _equipContainer.columns = 2 if enabled else 4
        _equipContainer.add_theme_constant_override("h_separation", 5 if enabled else 8)
        _equipContainer.add_theme_constant_override("v_separation", 5 if enabled else 8)

    if _timerRow != null:
        _timerRow.add_theme_constant_override("separation", 4 if enabled else 8)
        _timerRow.custom_minimum_size = Vector2(0, 34) if enabled else Vector2.ZERO
    if _rotationTimerLabel != null:
        _rotationTimerLabel.add_theme_font_size_override("font_size", 17 if enabled else 14)
        _rotationTimerLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if enabled else Control.SIZE_SHRINK_BEGIN
        _rotationTimerLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if enabled else HORIZONTAL_ALIGNMENT_LEFT

    if _sellAllBtn != null:
        _sellAllBtn.add_theme_font_size_override("font_size", 18 if enabled else 14)
        _sellAllBtn.custom_minimum_size = Vector2(220, 44) if enabled else Vector2.ZERO
        _sellAllBtn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if enabled else Control.SIZE_FILL

    if _refreshEquipBtn != null:
        _refreshEquipBtn.add_theme_font_size_override("font_size", 17 if enabled else 12)
        _refreshEquipBtn.custom_minimum_size = Vector2(132, 34) if enabled else Vector2.ZERO

    UpdateUI()

func SetContainerMargins(container: MarginContainer, margin: int) -> void:
    if container == null:
        return
    container.add_theme_constant_override("margin_left", margin)
    container.add_theme_constant_override("margin_top", margin)
    container.add_theme_constant_override("margin_right", margin)
    container.add_theme_constant_override("margin_bottom", margin)

func SetVerticalScrollMode(scroll: ScrollContainer, compact: bool) -> void:
    if scroll == null:
        return
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS if compact else ScrollContainer.SCROLL_MODE_AUTO

func SetTutorialMode(mode: TutorialMode) -> void:
    _tutorialMode = mode

    if mode != TutorialMode.None:
        _sellTab.visible = false
        _equipTab.visible = false
        _boostsTab.visible = false
        _workshopTab.visible = true

    for i in range(_tabButtons.size()):
        _tabButtons[i].disabled = (mode == TutorialMode.WorkshopUpgrade and i != 3) or (mode == TutorialMode.CloseOnly)

    if _closeBtn != null:
        _closeBtn.disabled = (mode == TutorialMode.WorkshopUpgrade)
    if _sellAllBtn != null:
        _sellAllBtn.disabled = (mode != TutorialMode.None)
    if _refreshEquipBtn != null:
        _refreshEquipBtn.disabled = (mode != TutorialMode.None)
    if _confirmOverlay != null and mode != TutorialMode.None:
        _confirmOverlay.visible = false

    UpdateUI()

func StyleScrollbar(sb: ScrollBar) -> void:
    if sb == null:
        return
    sb.custom_minimum_size = Vector2(14, 0) if sb is VScrollBar else Vector2(0, 14)
    var grabber = load("res://external/fantasy_pixelart_ui/sliders/wood_grabber_normal.png")
    if grabber != null:
        var grabStyle = StyleBoxTexture.new()
        grabStyle.texture = grabber
        grabStyle.texture_margin_left = 2
        grabStyle.texture_margin_top = 2
        grabStyle.texture_margin_right = 2
        grabStyle.texture_margin_bottom = 2
        sb.add_theme_stylebox_override("grabber", grabStyle)
        sb.add_theme_stylebox_override("grabber_highlight", grabStyle)
        sb.add_theme_stylebox_override("grabber_pressed", grabStyle)

    var scrollBgStyle = StyleBoxFlat.new()
    scrollBgStyle.bg_color = Color(0.08, 0.05, 0.04, 0.9)
    scrollBgStyle.border_color = Color(0.48, 0.28, 0.18, 1.0)
    scrollBgStyle.set_border_width_all(1)
    sb.add_theme_stylebox_override("scroll", scrollBgStyle)
