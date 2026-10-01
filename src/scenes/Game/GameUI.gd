class_name GameUI
extends CanvasLayer

@export var GoldLabel: Label
@export var XpLabel: Label
@export var LevelLabel: Label
@export var WaveLabel: Label
@export var KillsLabel: Label
@export var SummonButton: TextureButton
@export var SummonProgressBar: TextureProgressBar
@export var ActiveEffectsContainer: HBoxContainer
@export var SummonParticles: CPUParticles2D

# Navigation Buttons
@export var SkillsButton: TextureButton
@export var UpgradesButton: TextureButton
@export var EquipmentButton: TextureButton
@export var ShopButton: TextureButton
@export var SettingsButton: TextureButton

@export var BaseSummonCooldown: float = 3.0
@export var AutoSummonUnlocked: bool = false

var _player: Player
var _spawner: EnemySpawner
var _inventoryUI: InventoryUI
var _shopUI: ShopUI
var _settingsUI: SettingsUI
var _skillsUI: SkillsUI
var _upgradesUI: UpgradesUI
var _passiveIncomeTimer: float = 0.0

# Compact mode elements
var _compactUI: CompactUI
var _compactLevelLabel: Label
var _compactGoldLabel: Label
var _compactXpLabel: Label
var _compactStatusLabel: Label
var _compactHpLabel: Label
var _compactHpBar: ProgressBar
var _compactSummonBtn: Button
var _compactSummonProgress: ProgressBar
var _compactBoostsBtn: Button
var _compactUpgradesBtn: Button

# Window drag state
var _isCompactModeActive: bool = false
var _isDraggingWindow: bool = false
var _dragStartMousePos: Vector2

var _customTooltip: CustomTooltip
var _customTooltipLabel: Label
var _customTooltipDesc: Label
var _customTooltipTime: Label
var _hoveredControl: Control = null
var _hoveredName: String = ""
var _hoverTimer: float = 0.0

var _lastGold: int
var _lastXp: int
var _lastLevel: int
var _lastKills: int
var _lastWave: int
var _lastKillsOnWave: int = -1

var _summonCooldownTimer: float = 0.0
var _summonBtnTextUpdateTimer: float = 0.0
var _effectsSeparator: Control

# Pause Menu
var _pauseMenuPanel: PauseMenu
var _pauseInputBlocker: Control
var _isPaused: bool = false
var _pauseSettingsOpen: bool = false

# Simple simulated active effects
class Effect:
    var Name: String
    var Description: String
    var Duration: float
    var MaxDuration: float
    var IsPositive: bool
    var BorderColor: Color
    var IsChargeBased: bool = false

var _activeEffects: Array[Effect] = []
var _uiRoot: Control
var _currentUiScale: float = 1.0
var _panelPreferredSizes: Dictionary = {}
var _compactOriginalFontSizes: Dictionary = {}
const CompactMinimumFontSize = 18
const OversamplingWithScaleEnabled = 2
const TutorialDialogZIndex = 1000

enum TutorialStep {
    None,
    Intro1,
    Intro2,
    SummonPrompt,
    WaitSummon,
    LootPrompt,
    WaitLoot,
    ShopPrompt,
    WaitShopOpen,
    UpgradePrompt,
    WaitUpgrade,
    SkillsPrompt,
    WaitSkillsOpen,
    LearnSkillPrompt,
    WaitSkillLearned,
    Final1,
    Final2,
    Completed
}

var _currentTutorialStep: TutorialStep = TutorialStep.None
var _tutorialDialogPanel: TutorialDialog
var _tutorialDialogName: Label
var _tutorialDialogText: Label
var _tutorialNextBtn: Button
var _tutorialLastMatCount: int = 0
var _tutorialStartKillsCount: int = 0
var _tutorialLootFallbackTimer: float = 0.0
var _hasSummonedEnemy: bool = false
const TutorialLootFallbackDelay = 2.5

var _toastTimer: float = 0.0
var _toastInterval: float = 60.0 # каждые 60 секунд после туториала
var _lastPlayerLevel: int = 1

const ToastTips = [
    "Не забудь проверить магазин — там могут быть новые улучшения!",
    "Новый уровень даёт очки навыков! Открой дерево навыков (K), чтобы стать сильнее.",
    "Каждую 5-ю волну призывается сильный Босс с редкими наградами!",
    "Следи за бустами — они временно дают огромные боевые бонусы.",
    "Редкий лут открывается при изучении навыка 'Охотник за сокровищами'!",
	"Улучшай посох и кристалл в лавке, чтобы быстрее побеждать врагов."
]

func _ready() -> void:
    _uiRoot = get_node("Root")
    _uiRoot.set("oversampling_with_scale", OversamplingWithScaleEnabled)
    
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

    _player = get_parent().get_node_or_null("Player")
    _spawner = get_parent().get_node_or_null("EnemySpawner")

    if SummonButton != null:
        SummonButton.pressed.connect(OnSummonButtonPressed)

    if ShopButton != null:
        ShopButton.pressed.connect(ToggleShop)
    if SkillsButton != null:
        SkillsButton.pressed.connect(ToggleSkillsTree)
    if UpgradesButton != null:
        UpgradesButton.pressed.connect(ToggleUpgrades)
    if EquipmentButton != null:
        EquipmentButton.pressed.connect(ToggleInventory)
    if SettingsButton != null:
        SettingsButton.pressed.connect(ToggleSettings)

    var invScene = load("res://src/ui/InventoryUI/InventoryUI.tscn") as PackedScene
    _inventoryUI = invScene.instantiate() as InventoryUI
    _inventoryUI.visible = false
    _inventoryUI.visibility_changed.connect(OnPanelVisibilityChanged)
    _uiRoot.add_child(_inventoryUI)
    if _player != null:
        _inventoryUI.Init(_player)

    var shopScene = load("res://src/ui/ShopUI/ShopUI.tscn") as PackedScene
    _shopUI = shopScene.instantiate() as ShopUI
    _shopUI.visible = false
    _shopUI.visibility_changed.connect(OnPanelVisibilityChanged)
    _uiRoot.add_child(_shopUI)
    if _player != null:
        _shopUI.Init(_player)
    _shopUI.workshop_upgrade_purchased.connect(OnTutorialWorkshopUpgradePurchased)

    var settingsScene = load("res://src/ui/SettingsUI/SettingsUI.tscn") as PackedScene
    _settingsUI = settingsScene.instantiate() as SettingsUI
    _settingsUI.visible = false
    _settingsUI.visibility_changed.connect(OnPanelVisibilityChanged)
    _uiRoot.add_child(_settingsUI)
    _settingsUI.compact_mode_toggled.connect(OnCompactModeToggled)
    if _player != null:
        _settingsUI.Init(_player)

    var skillsScene = load("res://src/ui/SkillsUI/SkillsUI.tscn") as PackedScene
    _skillsUI = skillsScene.instantiate() as SkillsUI
    _skillsUI.visible = false
    _skillsUI.visibility_changed.connect(OnPanelVisibilityChanged)
    _uiRoot.add_child(_skillsUI)
    if _player != null:
        _skillsUI.Init(_player)
    _skillsUI.skill_purchased.connect(OnTutorialSkillPurchased)

    var upgradesScene = load("res://src/ui/UpgradesUI/UpgradesUI.tscn") as PackedScene
    _upgradesUI = upgradesScene.instantiate() as UpgradesUI
    _upgradesUI.visible = false
    _upgradesUI.visibility_changed.connect(OnPanelVisibilityChanged)
    _uiRoot.add_child(_upgradesUI)
    if _player != null:
        _upgradesUI.Init(_player)

    InitializeCompactUI()

    var tooltipScene = load("res://src/ui/CustomTooltip/CustomTooltip.tscn") as PackedScene
    _customTooltip = tooltipScene.instantiate() as CustomTooltip
    _customTooltip.visible = false
    _uiRoot.add_child(_customTooltip)
    _customTooltipLabel = _customTooltip.TooltipLabel
    _customTooltipDesc = _customTooltip.TooltipDesc
    _customTooltipTime = _customTooltip.TooltipTime

    SetupHover(SkillsButton, "Навыки")
    SetupHover(UpgradesButton, "Улучшения")
    SetupHover(EquipmentButton, "Снаряжение")
    SetupHover(ShopButton, "Магазин")
    SetupHover(SettingsButton, "Настройки")
    SetupHover(SummonButton, "Призвать противника")

    _effectsSeparator = get_node_or_null("Root/TopPanel/HBox/Separator")

    if not InputMap.has_action("summon_enemy"):
        InputMap.add_action("summon_enemy")
        var spaceKey = InputEventKey.new()
        spaceKey.keycode = KEY_SPACE
        InputMap.action_add_event("summon_enemy", spaceKey)

    UpdateActiveEffectsUI()

    var uiActions = [ "ui_accept", "ui_select" ]
    for action in uiActions:
        if InputMap.has_action(action):
            var events = InputMap.action_get_events(action)
            for ev in events:
                if ev is InputEventKey and ev.keycode == KEY_SPACE:
                    InputMap.action_erase_event(action, ev)

    InitializeTutorialUI()
    InitializePauseMenuUI()
    # Игровой интерфейс содержит таймеры перезарядки, дохода и автопризыва,
    # поэтому он должен полностью останавливаться вместе с игровым деревом.
    process_mode = PROCESS_MODE_PAUSABLE
    
    if _player != null and not _player.TutorialCompleted:
        StartTutorial()
    else:
        if _player != null:
            _lastPlayerLevel = _player.Level
            UpdateTutorialRestrictions()

    if CompactWindowSession.IsActive:
        EnterCompactModeFromPreviousScene()

func EnterCompactModeFromPreviousScene() -> void:
    OnCompactModeToggled(true)

func _process(delta: float) -> void:
    if _hoveredControl != null and not is_instance_valid(_hoveredControl):
        _hoveredControl = null
        _hoveredName = ""
        _hoverTimer = 0.0
        if _customTooltip != null:
            _customTooltip.visible = false

    if _hoveredControl != null:
        _hoverTimer += delta
        if _hoverTimer >= 0.15:
            var isEffect = _hoveredControl.has_meta("is_effect") and _hoveredControl.get_meta("is_effect")
            
            if isEffect:
                var hover_name = _hoveredControl.get_meta("hover_name", "")
                var effect = null
                for e in _activeEffects:
                    if e.Name == hover_name:
                        effect = e
                        break
                if effect != null:
                    _customTooltipLabel.text = tr(effect.Name)
                    _customTooltipLabel.add_theme_color_override("font_color", effect.BorderColor)
                    _customTooltipDesc.text = tr(effect.Description)
                    _customTooltipDesc.show()
                    if effect.IsChargeBased:
                        _customTooltipTime.text = GameLocalization.Format("EFFECT_CHARGES", {"count": int(effect.Duration)})
                    else:
                        _customTooltipTime.text = GameLocalization.Format("EFFECT_TIME_LEFT", {"seconds": maxi(0, int(ceil(effect.Duration)))})
                    _customTooltipTime.show()

                    var style = _customTooltip.get_theme_stylebox("panel").duplicate() as StyleBoxTexture
                    if style != null:
                        style.modulate_color = effect.BorderColor.lerp(Color.WHITE, 0.4)
                        _customTooltip.add_theme_stylebox_override("panel", style)
                else:
                    _customTooltip.visible = false
                    return
            else:
                _customTooltipLabel.text = tr(_hoveredName)
                _customTooltipLabel.add_theme_color_override("font_color", Color.WHITE)
                _customTooltipDesc.hide()
                _customTooltipTime.hide()

                var style = _customTooltip.get_theme_stylebox("panel").duplicate() as StyleBoxTexture
                if style != null and style.modulate_color != Color.WHITE:
                    style.modulate_color = Color.WHITE
                    _customTooltip.add_theme_stylebox_override("panel", style)

            if _customTooltip != null:
                _customTooltip.visible = true
                _customTooltip.scale = Vector2.ONE

                var controlPos = _hoveredControl.global_position
                var controlSize = _hoveredControl.size
                
                _customTooltip.reset_size()
                var tooltipSize = _customTooltip.get_combined_minimum_size()
                var scaledTooltipSize = tooltipSize * _customTooltip.scale

                var viewportSize = get_viewport().get_visible_rect().size

                var targetX = controlPos.x + (controlSize.x - scaledTooltipSize.x) / 2.0
                targetX = clampf(targetX, 10.0, viewportSize.x - scaledTooltipSize.x - 10.0)

                var targetY = controlPos.y - scaledTooltipSize.y - 5.0
                if targetY < 10.0:
                    targetY = controlPos.y + controlSize.y + 5.0
                targetY = clampf(targetY, 10.0, viewportSize.y - scaledTooltipSize.y - 10.0)

                _customTooltip.position = Vector2(targetX, targetY)
        else:
            if _customTooltip != null and _customTooltip.visible:
                _customTooltip.visible = false
    else:
        if _customTooltip != null and _customTooltip.visible:
            _customTooltip.visible = false

    if _player == null or not is_instance_valid(_player):
        return

    # Process Tutorial and Toasts
    if not _player.TutorialCompleted:
        if _currentTutorialStep == TutorialStep.Completed or _currentTutorialStep == TutorialStep.None:
            StartTutorial()

        if _tutorialDialogPanel != null and not _tutorialDialogPanel.visible:
            ShowTutorialDialogOnTop()
            _player.is_talking = true
            UpdateTutorialRestrictions()
        else:
            BringTutorialDialogToFront()
        UpdateTutorialDialogPosition()
        ProcessTutorialLogic(delta)
    else:
        if _currentTutorialStep != TutorialStep.Completed and _currentTutorialStep != TutorialStep.None:
            _currentTutorialStep = TutorialStep.Completed
            _player.is_talking = false
            if _tutorialDialogPanel != null:
                _tutorialDialogPanel.hide()
            UpdateTutorialRestrictions()

        ProcessToastLogic(delta)

    if _isCompactModeActive:
        UpdateCompactModeUI()

        _summonBtnTextUpdateTimer += delta
        if _summonBtnTextUpdateTimer >= 0.5:
            _summonBtnTextUpdateTimer = 0.0
            UpdateSummonButtonText()

    # Passive income from Astral Link skill (+1 gold per second per level)
    if _player.GetSkillLevel("astral_link") > 0:
        _passiveIncomeTimer += delta
        if _passiveIncomeTimer >= 1.0:
            _passiveIncomeTimer = 0.0
            var amount = _player.GetSkillLevel("astral_link")
            _player.Gold += amount
            _player.SaveSettings()

    # 1. Process Summon Cooldown
    if _summonCooldownTimer > 0.0:
        _summonCooldownTimer -= delta
        if SummonProgressBar != null:
            var maxCooldown = BaseSummonCooldown
            maxCooldown *= _player.SummonCooldownReductionFactor
            if _player.HasteScrollTimer > 0.0:
                maxCooldown *= 0.50
            SummonProgressBar.value = (_summonCooldownTimer / maxCooldown) * 100.0
        if SummonButton != null:
            SummonButton.disabled = true
    else:
        if SummonProgressBar != null:
            SummonProgressBar.value = 0.0
        if SummonButton != null:
            SummonButton.disabled = false

        AutoSummonUnlocked = _player.GetSkillLevel("auto_summon") > 0

        if AutoSummonUnlocked:
            OnSummonButtonPressed()

    # 2. Track resource changes and animate labels
    if _player.Gold != _lastGold:
        AnimateResourceLabel(GoldLabel, str(_player.Gold), Color.YELLOW if _player.Gold > _lastGold else Color.WHITE)
        _lastGold = _player.Gold

    if _player.Experience != _lastXp:
        AnimateResourceLabel(XpLabel, str(_player.Experience) + "/" + str(_player.GetXPNeeded(_player.Level)), Color.LIGHT_GREEN)
        _lastXp = _player.Experience

    if _player.Level != _lastLevel:
        AnimateResourceLabel(LevelLabel, tr("Ур. %d") % _player.Level, Color.GOLD)
        _lastLevel = _player.Level

    if _player.KillsOnCurrentWave != _lastKillsOnWave or _player.WaveCount != _lastWave or _player.IsBossActive:
        _lastKillsOnWave = _player.KillsOnCurrentWave
        _lastWave = _player.WaveCount
        _lastKills = _player.KillsCount

        if _player.IsBossActive:
            KillsLabel.text = tr("УБЕЙТЕ БОССА!")
            WaveLabel.text = tr("БОСС! (%0.1fs)") % _player.BossTimer
        elif _player.WaveCount % 5 == 0:
            KillsLabel.text = tr("Босс готов!")
            WaveLabel.text = tr("Волна: %d (БОСС)") % _player.WaveCount
        else:
            KillsLabel.text = tr("Убито: %d/20") % _player.KillsOnCurrentWave
            WaveLabel.text = tr("Волна: %d") % _player.WaveCount

    # 3. Process Active Effects from Player
    SyncActiveEffectsFromPlayer()
    UpdateActiveEffectsUI()

func OnSummonButtonPressed() -> void:
    if _summonCooldownTimer > 0.0:
        return

    var maxCooldown = BaseSummonCooldown
    if _player != null and is_instance_valid(_player) and _player.HasteScrollTimer > 0.0:
        maxCooldown *= 0.50
    _summonCooldownTimer = maxCooldown

    if _spawner != null and is_instance_valid(_spawner):
        _spawner.SpawnEnemyManually()
        _hasSummonedEnemy = true

    if SummonButton != null:
        var tween = create_tween()
        tween.tween_property(SummonButton, "scale", Vector2(1.15, 1.15), 0.08)
        tween.tween_property(SummonButton, "scale", Vector2(1.0, 1.0), 0.08)

    if SummonParticles != null:
        SummonParticles.restart()
        SummonParticles.emitting = true

func AnimateResourceLabel(label: Label, textVal: String, color: Color) -> void:
    if label == null:
        return

    label.text = textVal

    var tween = create_tween()
    tween.set_parallel(true)
    
    tween.tween_property(label, "scale", Vector2(1.25, 1.25), 0.1)
    tween.tween_method(func(c): label.add_theme_color_override("font_color", c), Color.WHITE, color, 0.1)
    
    tween.chain()
    tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15)
    tween.tween_method(func(c): label.add_theme_color_override("font_color", c), color, Color.WHITE, 0.15)

func UpdateActiveEffectsUI() -> void:
    if ActiveEffectsContainer == null:
        return

    var effectCount = _activeEffects.size()
    if _effectsSeparator != null:
        _effectsSeparator.visible = effectCount > 0

    while ActiveEffectsContainer.get_child_count() > effectCount:
        var child = ActiveEffectsContainer.get_child(ActiveEffectsContainer.get_child_count() - 1)
        if _hoveredControl == child:
            _hoveredControl = null
            _hoveredName = ""
            _hoverTimer = 0.0
            if _customTooltip != null:
                _customTooltip.visible = false
        child.queue_free()
        ActiveEffectsContainer.remove_child(child)

    while ActiveEffectsContainer.get_child_count() < effectCount:
        var frame = PanelContainer.new()
        frame.custom_minimum_size = Vector2(36, 36)

        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.1, 0.1, 0.1, 0.6)
        style.set_border_width_all(2)
        style.set_corner_radius_all(4)
        frame.add_theme_stylebox_override("panel", style)

        var rect = TextureRect.new()
        rect.texture = load("res://external/icodot-png-v1.0/icodot-png/ui/animals_people/icon-bug-ui.png")
        rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
        frame.add_child(rect)

        var label = Label.new()
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        
        var font = load("res://fonts/tiny5-font/Tiny5-Regular.ttf")
        if font != null:
            label.add_theme_font_override("font", font)
        label.add_theme_font_size_override("font_size", 16)
        label.add_theme_color_override("font_color", Color.WHITE)
        label.add_theme_color_override("font_outline_color", Color.BLACK)
        label.add_theme_constant_override("outline_size", 3)
        frame.add_child(label)

        frame.mouse_entered.connect(func():
            _hoveredControl = frame
            _hoveredName = frame.get_meta("hover_name", "")
            _hoverTimer = 0.0
        )
        frame.mouse_exited.connect(func():
            if _hoveredControl == frame:
                _hoveredControl = null
                _hoveredName = ""
                _hoverTimer = 0.0
                if _customTooltip != null:
                    _customTooltip.visible = false
        )

        ActiveEffectsContainer.add_child(frame)

    for i in range(effectCount):
        var effect = _activeEffects[i]
        var frame = ActiveEffectsContainer.get_child(i) as PanelContainer
        
        frame.set_meta("hover_name", effect.Name)
        frame.set_meta("is_effect", true)
        frame.tooltip_text = ""

        var style = frame.get_theme_stylebox("panel") as StyleBoxFlat
        if style != null:
            if effect.Duration < 5.0:
                var showBorder = (Time.get_ticks_msec() % 400) < 200
                style.border_color = effect.BorderColor if showBorder else Color.TRANSPARENT
            else:
                style.border_color = effect.BorderColor

        var label = frame.get_child(1) as Label
        if label != null:
            label.text = str(maxi(0, int(ceil(effect.Duration))))

func ShowToast(message: String) -> void:
    if _isCompactModeActive:
        return
    var toast = get_node_or_null("/root/GodotxToast")
    if toast != null and toast.has_method("show"):
        toast.call("show", message)

func ClearToasts() -> void:
    var toast = get_node_or_null("/root/GodotxToast")
    if toast != null and toast.has_method("clear_all"):
        toast.call("clear_all")

func SetupHover(control: Control, nameVal: String) -> void:
    if control == null:
        return
    control.mouse_entered.connect(func(): OnControlMouseEntered(control, nameVal))
    control.mouse_exited.connect(func(): OnControlMouseExited(control))

func _unhandled_input(event: InputEvent) -> void:
    if IsTutorialActive():
        HandleTutorialInput(event)
        return

    if event.is_action_pressed("ui_cancel"):
        if _isPaused:
            ResumePause()
            get_viewport().set_input_as_handled()
            return

        if IsAnyPanelVisible():
            HideAllPanels()
            if _isCompactModeActive:
                _compactUI.visible = true
            get_viewport().set_input_as_handled()
            return

        TogglePauseMenu()
        get_viewport().set_input_as_handled()
        return

    if _isPaused:
        return

    if event.is_action_pressed("summon_enemy"):
        if _player != null and not _player.TutorialCompleted:
            if _currentTutorialStep == TutorialStep.SummonPrompt:
                OnSummonButtonPressed()
        else:
            OnSummonButtonPressed()

    if event.is_action_pressed("open_shop"):
        ToggleShop()

    if event.is_action_pressed("open_skills"):
        if _player != null and not _player.TutorialCompleted:
            if _currentTutorialStep == TutorialStep.SkillsPrompt:
                ToggleSkillsTree()
        else:
            ToggleSkillsTree()

    if event.is_action_pressed("open_inventory"):
        if _player == null or _player.TutorialCompleted:
            ToggleInventory()

    if event.is_action_pressed("open_upgrades"):
        if _player == null or _player.TutorialCompleted:
            ToggleUpgrades()

    if event.is_action_pressed("open_settings"):
        if _player == null or _player.TutorialCompleted:
            ToggleSettings()

func IsTutorialActive() -> bool:
    return _player != null and not _player.TutorialCompleted and _currentTutorialStep != TutorialStep.Completed

func HandleTutorialInput(event: InputEvent) -> void:
    var handled = false

    if event.is_action_pressed("ui_cancel"):
        handled = true
        if _currentTutorialStep == TutorialStep.SkillsPrompt and _shopUI != null and _shopUI.visible:
            ToggleShop()
    elif event.is_action_pressed("summon_enemy"):
        handled = true
        if _currentTutorialStep == TutorialStep.SummonPrompt:
            OnSummonButtonPressed()
    elif event.is_action_pressed("open_shop"):
        handled = true
        var mayOpen = _currentTutorialStep == TutorialStep.ShopPrompt and _shopUI != null and not _shopUI.visible
        var mayClose = _currentTutorialStep == TutorialStep.SkillsPrompt and _shopUI != null and _shopUI.visible
        if mayOpen or mayClose:
            ToggleShop()
    elif event.is_action_pressed("open_skills"):
        handled = true
        var mayOpenSkills = _currentTutorialStep == TutorialStep.SkillsPrompt or _currentTutorialStep == TutorialStep.LearnSkillPrompt
        if mayOpenSkills and _skillsUI != null and not _skillsUI.visible:
            ToggleSkillsTree()
    elif event.is_action_pressed("open_inventory") or event.is_action_pressed("open_upgrades") or event.is_action_pressed("open_settings"):
        handled = true

    if handled:
        get_viewport().set_input_as_handled()

func OnControlMouseEntered(control: Control, nameVal: String) -> void:
    _hoveredControl = control
    _hoveredName = nameVal
    _hoverTimer = 0.0

func OnControlMouseExited(control: Control) -> void:
    if _hoveredControl == control:
        _hoveredControl = null
        _hoveredName = ""
        _hoverTimer = 0.0
        if _customTooltip != null:
            _customTooltip.visible = false

func ToggleInventory() -> void:
    if IsTutorialActive():
        return
    if _inventoryUI == null:
        return
    if _inventoryUI.visible:
        _inventoryUI.visible = false
        if _isCompactModeActive and not IsAnyPanelVisible():
            _compactUI.visible = true
        return
    _inventoryUI.Refresh()
    HideAllPanels()
    ShowPanel(_inventoryUI)

func SpawnFlyingLoot(item: ItemData, startScreenPos: Vector2, startDelay: float = 0.0) -> void:
    if item == null:
        return

    var container = HBoxContainer.new()
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.position = (startScreenPos / _currentUiScale) - Vector2(50, 10)
    container.z_index = 200
    container.add_theme_constant_override("separation", 6)
    _uiRoot.add_child(container)

    var icon = TextureRect.new()
    icon.texture = load(item.IconTexturePath)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.custom_minimum_size = Vector2(24, 24)
    icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.add_child(icon)

    var labelText = GameLocalization.ItemName(item)
    if item.StackCount > 1:
        labelText += " x" + str(item.StackCount)
    
    var label = Label.new()
    label.text = labelText
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")
    if font != null:
        label.add_theme_font_override("font", font)
    label.add_theme_font_size_override("font_size", 12)
    
    var rarityColor = Color.WHITE
    match item.Rarity:
        ItemData.ItemRarity.Uncommon: rarityColor = Color.GREEN
        ItemData.ItemRarity.Rare: rarityColor = Color.DEEP_SKY_BLUE
        ItemData.ItemRarity.Epic: rarityColor = Color.MEDIUM_PURPLE
        ItemData.ItemRarity.Legendary: rarityColor = Color.GOLD
    label.add_theme_color_override("font_color", rarityColor)
    container.add_child(label)

    var tween = create_tween()
    tween.set_parallel(false)

    var popPos = startScreenPos + Vector2(randf_range(-40.0, 40.0), randf_range(-50.0, -30.0))
    tween.tween_property(container, "position", popPos, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    tween.tween_interval(0.1 + startDelay)

    var targetPos = Vector2.ZERO
    if EquipmentButton != null:
        targetPos = EquipmentButton.global_position + EquipmentButton.size / 2.0 - Vector2(12, 12)
        
    tween.chain().set_parallel(true)
    tween.tween_property(container, "position", targetPos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.tween_property(container, "scale", Vector2(0.4, 0.4), 0.6)
    tween.tween_property(container, "modulate:a", 0.2, 0.6)

    tween.chain().tween_callback(func():
        if _player != null and is_instance_valid(_player):
            _player.AddToInventory(item)
        container.queue_free()
    )

func ToggleShop() -> void:
    if _shopUI == null:
        return
    if IsTutorialActive():
        var mayOpen = _currentTutorialStep == TutorialStep.ShopPrompt and not _shopUI.visible
        var mayClose = _currentTutorialStep == TutorialStep.SkillsPrompt and _shopUI.visible
        if not mayOpen and not mayClose:
            return
    if _shopUI.visible:
        _shopUI.visible = false
        if _isCompactModeActive and not IsAnyPanelVisible():
            _compactUI.visible = true
        return
    HideAllPanels()
    ShowPanel(_shopUI)

    if _player != null and not _player.TutorialCompleted and _tutorialDialogPanel != null:
        ShowTutorialDialogOnTop()
        _player.is_talking = true

    _shopUI.UpdateUI()

func SyncActiveEffectsFromPlayer() -> void:
    _activeEffects.clear()
    if _player == null or not is_instance_valid(_player):
        return

    if _player.WrathPotionTimer > 0.0:
        var eff = Effect.new()
        eff.Name = "Зелье ярости"
        eff.Description = "Увеличивает наносимый урон на 50%"
        eff.Duration = _player.WrathPotionTimer
        eff.MaxDuration = 60.0
        eff.IsPositive = true
        eff.BorderColor = Color.RED
        _activeEffects.append(eff)

    if _player.LuckyElixirEnemiesCount > 0:
        var eff = Effect.new()
        eff.Name = "Эликсир удачи"
        eff.Description = "Повышает шанс редкого лута на 25%"
        eff.Duration = _player.LuckyElixirEnemiesCount
        eff.MaxDuration = 10.0
        eff.IsPositive = true
        eff.BorderColor = Color.GOLD
        eff.IsChargeBased = true
        _activeEffects.append(eff)

    if _player.HasteScrollTimer > 0.0:
        var eff = Effect.new()
        eff.Name = "Свиток ускорения"
        eff.Description = "Сокращает кулдаун призыва на 50%"
        eff.Duration = _player.HasteScrollTimer
        eff.MaxDuration = 300.0
        eff.IsPositive = true
        eff.BorderColor = Color.CYAN
        _activeEffects.append(eff)

    if _player.SpeedPotionTimer > 0.0:
        var eff = Effect.new()
        eff.Name = "Зелье скорости"
        eff.Description = "Увеличивает скорость передвижения на 30%"
        eff.Duration = _player.SpeedPotionTimer
        eff.MaxDuration = 30.0
        eff.IsPositive = true
        eff.BorderColor = Color.LIGHT_GREEN
        _activeEffects.append(eff)

    if _player.CritPotionTimer > 0.0:
        var eff = Effect.new()
        eff.Name = "Эликсир крита"
        eff.Description = "Увеличивает шанс критического удара на 15%"
        eff.Duration = _player.CritPotionTimer
        eff.MaxDuration = 30.0
        eff.IsPositive = true
        eff.BorderColor = Color.ORANGE
        _activeEffects.append(eff)

    if _player.CritDamageScrollTimer > 0.0:
        var eff = Effect.new()
        eff.Name = "Свиток крит. силы"
        eff.Description = "Увеличивает силу критического удара на 50%"
        eff.Duration = _player.CritDamageScrollTimer
        eff.MaxDuration = 60.0
        eff.IsPositive = true
        eff.BorderColor = Color.PURPLE
        _activeEffects.append(eff)

func ToggleSettings() -> void:
    if IsTutorialActive():
        return
    if _settingsUI == null:
        return
    if _settingsUI.visible:
        _settingsUI.visible = false
        if _isCompactModeActive and not IsAnyPanelVisible():
            _compactUI.visible = true
        return
    HideAllPanels()
    ShowPanel(_settingsUI)

func ToggleSkillsTree() -> void:
    if _skillsUI == null:
        return
    if IsTutorialActive():
        var mayOpen = _currentTutorialStep == TutorialStep.SkillsPrompt or _currentTutorialStep == TutorialStep.LearnSkillPrompt
        if not mayOpen or _skillsUI.visible:
            return
    if _skillsUI.visible:
        _skillsUI.visible = false
        if _isCompactModeActive and not IsAnyPanelVisible():
            _compactUI.visible = true
        return
    _skillsUI.Refresh()
    HideAllPanels()
    ShowPanel(_skillsUI)

    if IsTutorialActive() and _tutorialDialogPanel != null:
        ShowTutorialDialogOnTop()
        _player.is_talking = true

func ToggleUpgrades() -> void:
    if IsTutorialActive():
        return
    if _upgradesUI == null:
        return
    if _upgradesUI.visible:
        _upgradesUI.visible = false
        if _isCompactModeActive and not IsAnyPanelVisible():
            _compactUI.visible = true
        return
    _upgradesUI.Refresh()
    HideAllPanels()
    ShowPanel(_upgradesUI)

func HideAllPanels() -> void:
    if _inventoryUI != null: _inventoryUI.visible = false
    if _shopUI != null: _shopUI.visible = false
    if _settingsUI != null: _settingsUI.visible = false
    if _skillsUI != null: _skillsUI.visible = false
    if _upgradesUI != null: _upgradesUI.visible = false

    if _isCompactModeActive:
        _compactUI.visible = true

func ShowPanel(panel: Control) -> void:
    if not _panelPreferredSizes.has(panel):
        var preferredSize = panel.custom_minimum_size
        _panelPreferredSizes[panel] = preferredSize if preferredSize.x > 0.0 and preferredSize.y > 0.0 else Vector2(660.0, 500.0)

    panel.visible = true

    if _isCompactModeActive:
        panel.scale = Vector2.ONE
        SetPanelCompactMode(panel, true)
        _compactUI.visible = false
    else:
        panel.scale = Vector2.ONE
        SetPanelCompactMode(panel, false)

    call_deferred("DoCenterPanel", panel)

func SetPanelCompactMode(panel: Control, enabled: bool) -> void:
    if enabled:
        CapturePanelFontSizes(panel)

    if panel is InventoryUI:
        panel.SetCompactMode(enabled)
    elif panel is ShopUI:
        panel.SetCompactMode(enabled)
    elif panel is SettingsUI:
        panel.SetCompactMode(enabled)
    elif panel is SkillsUI:
        panel.SetCompactMode(enabled)
    elif panel is UpgradesUI:
        panel.SetCompactMode(enabled)
    elif panel is PauseMenu:
        panel.SetCompactMode(enabled)

    if enabled:
        ApplyCompactFontFloor(panel)
    else:
        RestorePanelFontSizes(panel)

func CapturePanelFontSizes(root: Control) -> void:
    var themeName = GetReadableFontSizeThemeName(root)
    if not themeName.is_empty() and not _compactOriginalFontSizes.has(root):
        _compactOriginalFontSizes[root] = root.get_theme_font_size(themeName)

    for child in root.get_children():
        if child is Control:
            CapturePanelFontSizes(child)

func ApplyCompactFontFloor(root: Control) -> void:
    var themeName = GetReadableFontSizeThemeName(root)
    if not themeName.is_empty() and root.get_theme_font_size(themeName) < CompactMinimumFontSize:
        root.add_theme_font_size_override(themeName, CompactMinimumFontSize)

    for child in root.get_children():
        if child is Control:
            ApplyCompactFontFloor(child)

func RestorePanelFontSizes(root: Control) -> void:
    var themeName = GetReadableFontSizeThemeName(root)
    if not themeName.is_empty() and _compactOriginalFontSizes.has(root):
        var originalSize = _compactOriginalFontSizes[root]
        _compactOriginalFontSizes.erase(root)
        root.add_theme_font_size_override(themeName, originalSize)

    for child in root.get_children():
        if child is Control:
            RestorePanelFontSizes(child)

func GetReadableFontSizeThemeName(control: Control) -> String:
    if control is RichTextLabel:
        return "normal_font_size"
    if control is Label or control is Button or control is LineEdit or control is TextEdit:
        return "font_size"
    return ""

func DoCenterPanel(panel: Control) -> void:
    if panel == null or not is_instance_valid(panel):
        return

    var viewport = get_viewport()
    if viewport == null:
        return
    var screenSize = _uiRoot.size if (_uiRoot != null and is_instance_valid(_uiRoot)) else viewport.get_visible_rect().size

    if not _panelPreferredSizes.has(panel):
        var minSize = panel.custom_minimum_size
        if minSize == Vector2.ZERO:
            minSize = panel.size
        if minSize.x <= 0 or minSize.y <= 0:
            minSize = Vector2(660.0, 500.0)
        _panelPreferredSizes[panel] = minSize
    var preferredSize = _panelPreferredSizes[panel]

    panel.anchor_left = 0.0
    panel.anchor_top = 0.0
    panel.anchor_right = 0.0
    panel.anchor_bottom = 0.0
    panel.pivot_offset = Vector2.ZERO

    if _isCompactModeActive:
        var availableSize = Vector2(maxf(1.0, screenSize.x - 8.0), maxf(1.0, screenSize.y - 8.0))
        var targetSize = Vector2(minf(300.0, availableSize.x), minf(240.0, availableSize.y)) if panel is PauseMenu else availableSize
        panel.scale = Vector2.ONE
        panel.size = targetSize
        var pos = ((screenSize - targetSize) * 0.5).floor()
        panel.position = Vector2(maxf(0.0, pos.x), maxf(0.0, pos.y))
    else:
        panel.custom_minimum_size = Vector2.ZERO
        panel.scale = Vector2.ONE

        var targetW = minf(preferredSize.x, screenSize.x * 0.95)
        var targetH = minf(preferredSize.y, screenSize.y * 0.95)
        if panel is InventoryUI:
            panel.SetResponsiveWidth(targetW)
        panel.size = Vector2(targetW, targetH)

        var pos = ((screenSize - panel.size) * 0.5).floor()
        panel.position = Vector2(maxf(0.0, pos.x), maxf(0.0, pos.y))

func OnPanelVisibilityChanged() -> void:
    if _isPaused and _pauseSettingsOpen and _settingsUI != null and not _settingsUI.visible:
        ClosePauseSettings(true)
        return

    if not _isCompactModeActive:
        return
    if not IsAnyPanelVisible():
        _compactUI.visible = true

func IsAnyPanelVisible() -> bool:
    return (_inventoryUI != null and _inventoryUI.visible) or (_shopUI != null and _shopUI.visible) or (_settingsUI != null and _settingsUI.visible) or (_skillsUI != null and _skillsUI.visible) or (_upgradesUI != null and _upgradesUI.visible)

func InitializeCompactUI() -> void:
    var scene = load("res://src/ui/CompactUI/CompactUI.tscn") as PackedScene
    _compactUI = scene.instantiate() as CompactUI
    _compactUI.visible = false
    add_child(_compactUI)
    _compactUI.z_index = 300

    _compactLevelLabel = _compactUI.LevelLabel
    _compactGoldLabel = _compactUI.GoldLabel
    _compactXpLabel = _compactUI.XpLabel
    _compactStatusLabel = _compactUI.StatusLabel
    _compactHpLabel = _compactUI.HpLabel
    _compactHpBar = _compactUI.HpBar
    _compactSummonBtn = _compactUI.SummonButton
    _compactSummonProgress = _compactUI.SummonProgress
    _compactBoostsBtn = _compactUI.ShopBtn
    _compactUpgradesBtn = _compactUI.UpgradesBtn

    _compactUI.Header.gui_input.connect(OnCompactGuiInput)
    _compactUI.RestoreButton.pressed.connect(func(): OnCompactModeToggled(false))
    _compactSummonBtn.pressed.connect(OnSummonButtonPressed)
    _compactBoostsBtn.pressed.connect(ToggleShop)
    _compactUI.InventoryBtn.pressed.connect(ToggleInventory)
    _compactUI.SkillsBtn.pressed.connect(ToggleSkillsTree)
    _compactUpgradesBtn.pressed.connect(ToggleUpgrades)
    _compactUI.SettingsBtn.pressed.connect(ToggleSettings)
    _compactUI.PauseBtn.pressed.connect(TogglePauseMenu)

    UpdateSummonButtonText()

func UpdateCompactModeUI() -> void:
    if _player == null or not is_instance_valid(_player):
        return

    var maxCooldown = BaseSummonCooldown
    if _player.HasteScrollTimer > 0.0:
        maxCooldown *= 0.50
    maxCooldown *= _player.SummonCooldownReductionFactor

    if _summonCooldownTimer > 0.0:
        _compactSummonBtn.disabled = true
        _compactSummonProgress.value = (_summonCooldownTimer / maxCooldown) * 100.0
    else:
        _compactSummonBtn.disabled = false
        _compactSummonProgress.value = 0.0

    _compactLevelLabel.text = tr("Ур. %d") % _player.Level
    _compactGoldLabel.text = tr("%d Зол.") % _player.Gold
    var nextLevelXp = _player.GetXPNeeded(_player.Level)
    var xpPercent = int(_player.Experience * 100.0 / nextLevelXp) if nextLevelXp > 0 else 0
    _compactXpLabel.text = GameLocalization.Format("EXPERIENCE_PERCENT", {"amount": xpPercent})
    if _player.IsBossActive:
        _compactStatusLabel.text = tr("БОСС %dс • Эфф. %d") % [int(_player.BossTimer), _activeEffects.size()]
    else:
        _compactStatusLabel.text = tr("Волна %d • %d/20 • Эфф. %d") % [_player.WaveCount, _player.KillsOnCurrentWave, _activeEffects.size()]

    UpdateSummonButtonText()

    if _player.CurrentTarget != null and is_instance_valid(_player.CurrentTarget):
        var enemy = _player.CurrentTarget
        _compactHpLabel.text = GameLocalization.Format("ENEMY_HEALTH", {"enemy": tr(str(enemy.name)), "health": enemy.Health, "max_health": enemy.MaxHealth})
        _compactHpBar.value = float(enemy.Health) * 100.0 / enemy.MaxHealth
    else:
        _compactHpLabel.text = tr("Нет цели")
        _compactHpBar.value = 0

func OnCompactModeToggled(enabled: bool) -> void:
    if OS.has_feature("web"):
        return
    if _isCompactModeActive == enabled:
        return
    _isCompactModeActive = enabled

    var window = get_window()

    if enabled:
        ClearToasts()
        _toastTimer = 0.0

        if _inventoryUI != null: _inventoryUI.visible = false
        if _shopUI != null: _shopUI.visible = false
        if _settingsUI != null: _settingsUI.visible = false
        if _skillsUI != null: _skillsUI.visible = false
        if _upgradesUI != null: _upgradesUI.visible = false

        SetNormalUIVisible(false)
        _compactUI.visible = true
        _compactUI.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        _compactUI.position = Vector2.ZERO
        _compactUI.scale = Vector2.ONE

        CompactWindowSession.enter(window)
        ApplyUiRootScale(1.0)

        if _settingsUI != null:
            _settingsUI.SetCompactModeCheckboxSilent(true)
    else:
        _compactUI.visible = false
        _compactUI.position = Vector2.ZERO

        CompactWindowSession.exit(window)
        ApplyUiRootScale(_currentUiScale)
        SetNormalUIVisible(true)

        if _inventoryUI != null: _inventoryUI.scale = Vector2.ONE
        if _shopUI != null: _shopUI.scale = Vector2.ONE
        if _settingsUI != null: _settingsUI.scale = Vector2.ONE
        if _skillsUI != null: _skillsUI.scale = Vector2.ONE
        if _upgradesUI != null: _upgradesUI.scale = Vector2.ONE
        if _inventoryUI != null: SetPanelCompactMode(_inventoryUI, false)
        if _shopUI != null: SetPanelCompactMode(_shopUI, false)
        if _settingsUI != null: SetPanelCompactMode(_settingsUI, false)
        if _skillsUI != null: SetPanelCompactMode(_skillsUI, false)
        if _upgradesUI != null: SetPanelCompactMode(_upgradesUI, false)
        if _pauseMenuPanel != null: SetPanelCompactMode(_pauseMenuPanel, false)

        if _inventoryUI != null and _inventoryUI.visible: DoCenterPanel(_inventoryUI)
        if _shopUI != null and _shopUI.visible: DoCenterPanel(_shopUI)
        if _settingsUI != null and _settingsUI.visible: DoCenterPanel(_settingsUI)
        if _skillsUI != null and _skillsUI.visible: DoCenterPanel(_skillsUI)
        if _upgradesUI != null and _upgradesUI.visible: DoCenterPanel(_upgradesUI)

        if _settingsUI != null:
            _settingsUI.SetCompactModeCheckboxSilent(false)

func OnCompactGuiInput(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb = event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT:
            _isDraggingWindow = mb.pressed
            if _isDraggingWindow:
                _dragStartMousePos = DisplayServer.mouse_get_position()
    elif event is InputEventMouseMotion and _isDraggingWindow:
        var mousePos = DisplayServer.mouse_get_position()
        var delta = mousePos - Vector2i(_dragStartMousePos)
        var window = get_window()
        window.position += delta
        _dragStartMousePos = mousePos

func ShowCompactBoostsMenu() -> void:
    var menu = PopupMenu.new()
    AddThemeFontsToPopupMenu(menu)

    var wrathItem = ItemDatabase.get_item("cons_wrath_elixir")
    var wrathPrice = ItemDatabase.get_buy_price(wrathItem)
    menu.add_item(GameLocalization.Format("BUY_MENU_ITEM", {"item": GameLocalization.ItemName(wrathItem), "amount": wrathPrice}), 0)
    menu.set_item_disabled(0, _player.Gold < wrathPrice)

    var luckyItem = ItemDatabase.get_item("cons_lucky_elixir")
    var luckyPrice = ItemDatabase.get_buy_price(luckyItem)
    menu.add_item(GameLocalization.Format("BUY_MENU_ITEM", {"item": GameLocalization.ItemName(luckyItem), "amount": luckyPrice}), 1)
    menu.set_item_disabled(1, _player.Gold < luckyPrice)

    var hasteItem = ItemDatabase.get_item("cons_haste_scroll")
    var hastePrice = ItemDatabase.get_buy_price(hasteItem)
    menu.add_item(GameLocalization.Format("BUY_MENU_ITEM", {"item": GameLocalization.ItemName(hasteItem), "amount": hastePrice}), 2)
    menu.set_item_disabled(2, _player.Gold < hastePrice)

    menu.id_pressed.connect(func(id):
        if id == 0: BuyAndUseBoostDirectly("cons_wrath_elixir", wrathPrice)
        elif id == 1: BuyAndUseBoostDirectly("cons_lucky_elixir", luckyPrice)
        elif id == 2: BuyAndUseBoostDirectly("cons_haste_scroll", hastePrice)
        menu.queue_free()
    )

    add_child(menu)
    menu.position = Vector2i(_compactBoostsBtn.global_position) + Vector2i(0, -int(menu.size.y))
    menu.popup()

func ShowCompactUpgradesMenu() -> void:
    var menu = PopupMenu.new()
    AddThemeFontsToPopupMenu(menu)

    var discount = _player.UpgradesGoldDiscountMultiplier

    var staffCost = roundi((150 * discount) * pow(1.15, _player.StaffUpgradeLevel))
    menu.add_item(FormatCompactUpgradeItem(tr("Усиление посоха"), _player.StaffUpgradeLevel, 10, staffCost), 0)
    menu.set_item_disabled(0, _player.Gold < staffCost or _player.StaffUpgradeLevel >= 10)

    var crystalCost = roundi((200 * discount) * pow(1.15, _player.CrystalUpgradeLevel))
    menu.add_item(FormatCompactUpgradeItem(tr("Настройка кристалла"), _player.CrystalUpgradeLevel, 10, crystalCost), 1)
    menu.set_item_disabled(1, _player.Gold < crystalCost or _player.CrystalUpgradeLevel >= 10)

    var wardsCost = roundi((100 * discount) * pow(1.15, _player.WardsUpgradeLevel))
    menu.add_item(FormatCompactUpgradeItem(tr("Астральный магнит"), _player.WardsUpgradeLevel, 10, wardsCost), 2)
    menu.set_item_disabled(2, _player.Gold < wardsCost or _player.WardsUpgradeLevel >= 10)

    var goldCost = roundi((250 * discount) * pow(1.15, _player.GoldUpgradeLevel))
    menu.add_item(FormatCompactUpgradeItem(tr("Золотое проклятие"), _player.GoldUpgradeLevel, 10, goldCost), 3)
    menu.set_item_disabled(3, _player.Gold < goldCost or _player.GoldUpgradeLevel >= 10)

    var insightCost = roundi((200 * discount) * pow(1.15, _player.InsightUpgradeLevel))
    menu.add_item(FormatCompactUpgradeItem(tr("Прозрение"), _player.InsightUpgradeLevel, 10, insightCost), 4)
    menu.set_item_disabled(4, _player.Gold < insightCost or _player.InsightUpgradeLevel >= 10)

    var critCost = roundi((300 * discount) * pow(1.15, _player.CritUpgradeLevel))
    menu.add_item(FormatCompactUpgradeItem(tr("Критическая концентрация"), _player.CritUpgradeLevel, 10, critCost), 5)
    menu.set_item_disabled(5, _player.Gold < critCost or _player.CritUpgradeLevel >= 10)

    var manaCost = roundi((180 * discount) * pow(1.15, _player.ManaUpgradeLevel))
    menu.add_item(FormatCompactUpgradeItem(tr("Поток маны"), _player.ManaUpgradeLevel, 10, manaCost), 6)
    menu.set_item_disabled(6, _player.Gold < manaCost or _player.ManaUpgradeLevel >= 10)

    var portalUnlocked = _player.GetSkillLevel("astral_link") >= 1
    var portalCost = roundi((400 * discount) * pow(1.15, _player.ElementalPortalLevel))
    if portalUnlocked:
        menu.add_item(FormatCompactUpgradeItem(tr("Портал стихий"), _player.ElementalPortalLevel, 5, portalCost), 7)
        menu.set_item_disabled(7, _player.Gold < portalCost or _player.ElementalPortalLevel >= 5)

    var focusUnlocked = _player.GetSkillLevel("crit_magic") >= 3
    var focusCost = roundi((500 * discount) * pow(1.15, _player.LegendaryFocusLevel))
    if focusUnlocked:
        menu.add_item(FormatCompactUpgradeItem(tr("Легендарный фокус"), _player.LegendaryFocusLevel, 5, focusCost), 8)
        menu.set_item_disabled(8, _player.Gold < focusCost or _player.LegendaryFocusLevel >= 5)

    menu.id_pressed.connect(func(id):
        if id == 0 and _player.Gold >= staffCost and _player.StaffUpgradeLevel < 10:
            _player.Gold -= staffCost
            _player.StaffUpgradeLevel += 1
            FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Улучшено!"), Color.GREEN, 8, 1.0)
        elif id == 1 and _player.Gold >= crystalCost and _player.CrystalUpgradeLevel < 10:
            _player.Gold -= crystalCost
            _player.CrystalUpgradeLevel += 1
            FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Улучшено!"), Color.GREEN, 8, 1.0)
        elif id == 2 and _player.Gold >= wardsCost and _player.WardsUpgradeLevel < 10:
            _player.Gold -= wardsCost
            _player.WardsUpgradeLevel += 1
            FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Улучшено!"), Color.GREEN, 8, 1.0)
        elif id == 3 and _player.Gold >= goldCost and _player.GoldUpgradeLevel < 10:
            _player.Gold -= goldCost
            _player.GoldUpgradeLevel += 1
            FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Улучшено!"), Color.GREEN, 8, 1.0)
        elif id == 4 and _player.Gold >= insightCost and _player.InsightUpgradeLevel < 10:
            _player.Gold -= insightCost
            _player.InsightUpgradeLevel += 1
            FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Улучшено!"), Color.GREEN, 8, 1.0)
        elif id == 5 and _player.Gold >= critCost and _player.CritUpgradeLevel < 10:
            _player.Gold -= critCost
            _player.CritUpgradeLevel += 1
            FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Улучшено!"), Color.GREEN, 8, 1.0)
        elif id == 6 and _player.Gold >= manaCost and _player.ManaUpgradeLevel < 10:
            _player.Gold -= manaCost
            _player.ManaUpgradeLevel += 1
            FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Улучшено!"), Color.GREEN, 8, 1.0)
        elif id == 7 and _player.Gold >= portalCost and _player.ElementalPortalLevel < 5:
            _player.Gold -= portalCost
            _player.ElementalPortalLevel += 1
            FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Улучшено!"), Color.GREEN, 8, 1.0)
        elif id == 8 and _player.Gold >= focusCost and _player.LegendaryFocusLevel < 5:
            _player.Gold -= focusCost
            _player.LegendaryFocusLevel += 1
            FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Улучшено!"), Color.GREEN, 8, 1.0)

        _player.SaveSettings()
        if _upgradesUI != null and _upgradesUI.visible:
            _upgradesUI.Refresh()
        menu.queue_free()
    )

    add_child(menu)
    menu.position = Vector2i(_compactUpgradesBtn.global_position) + Vector2i(0, -int(menu.size.y))
    menu.popup()

func FormatCompactUpgradeItem(title: String, currentLevel: int, maxLevel: int, cost: int) -> String:
    return GameLocalization.Format("UPGRADE_MENU_ITEM", {
        "title": title,
        "level": currentLevel,
        "max_level": maxLevel,
        "amount": cost
    })

func AddThemeFontsToPopupMenu(menu: PopupMenu) -> void:
    var font = load("res://fonts/ithaca-font/Ithaca-LVB75.ttf")
    if font != null:
        menu.add_theme_font_override("font", font)
        menu.add_theme_font_size_override("font_size", 14)

func BuyAndUseBoostDirectly(itemId: String, price: int) -> void:
    if _player == null or _player.Gold < price:
        return

    _player.Gold -= price
    if itemId == "cons_wrath_elixir":
        _player.WrathPotionTimer = 60.0
        FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Ярость!"), Color.RED, 8, 1.0)
    elif itemId == "cons_lucky_elixir":
        _player.LuckyElixirEnemiesCount = 10
        FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Удача!"), Color.GOLD, 8, 1.0)
    elif itemId == "cons_haste_scroll":
        _player.HasteScrollTimer = 300.0
        FloatingTextHelper.spawn(get_parent(), _player.global_position + Vector2(0, -20), tr("Ускорение призыва!"), Color.CYAN, 8, 1.0)

    _player.inventory_updated.emit()
    if _shopUI != null and _shopUI.visible:
        _shopUI.UpdateUI()

func SetNormalUIVisible(visibleVal: bool) -> void:
    if _uiRoot == null or not is_instance_valid(_uiRoot):
        return

    var normalHudNodes = [ "TopPanel", "SummonPanel", "NavPanel" ]
    for nodeName in normalHudNodes:
        var control = _uiRoot.get_node_or_null(nodeName)
        if control != null:
            control.visible = visibleVal

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

func UpdateSummonButtonText() -> void:
    if _compactSummonBtn == null or not is_instance_valid(_compactSummonBtn):
        return

    var keyName = tr("Пробел")
    if InputMap.has_action("summon_enemy"):
        var events = InputMap.action_get_events("summon_enemy")
        if events.size() > 0 and events[0] is InputEventKey:
            var keyEvent = events[0] as InputEventKey
            var keycode = keyEvent.physical_keycode if keyEvent.physical_keycode != KEY_NONE else keyEvent.keycode
            keyName = OS.get_keycode_string(keycode)

            if keyName == "Space": keyName = tr("Пробел")
            elif keyName == "Enter": keyName = tr("Ввод")
            elif keyName == "Kp Enter": keyName = tr("Ввод")

    if _player != null and is_instance_valid(_player):
        if _player.IsBossActive:
            _compactSummonBtn.text = GameLocalization.Format("SUMMON_BOSS_FIGHT", {"seconds": "%.1f" % _player.BossTimer})
        elif _player.WaveCount % 5 == 0:
            _compactSummonBtn.text = GameLocalization.Format("SUMMON_BOSS", {"key": keyName})
        else:
            _compactSummonBtn.text = GameLocalization.Format("SUMMON_WITH_PROGRESS", {"key": keyName, "kills": _player.KillsOnCurrentWave})
    else:
        _compactSummonBtn.text = GameLocalization.Format("SUMMON_WITH_KEY", {"key": keyName})

func InitializePauseMenuUI() -> void:
    _pauseInputBlocker = Control.new()
    _pauseInputBlocker.name = "PauseInputBlocker"
    _pauseInputBlocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _pauseInputBlocker.mouse_filter = Control.MOUSE_FILTER_STOP
    _pauseInputBlocker.process_mode = PROCESS_MODE_ALWAYS
    _pauseInputBlocker.z_index = 2000
    _pauseInputBlocker.visible = false
    _uiRoot.add_child(_pauseInputBlocker)

    var scene = load("res://src/ui/PauseMenu/PauseMenu.tscn") as PackedScene
    _pauseMenuPanel = scene.instantiate() as PauseMenu
    _pauseMenuPanel.visible = false
    _pauseInputBlocker.add_child(_pauseMenuPanel)

    _pauseMenuPanel.ResumeButton.pressed.connect(ResumePause)
    _pauseMenuPanel.SettingsButton.pressed.connect(OpenPauseSettings)
    _pauseMenuPanel.QuitButton.pressed.connect(QuitToMainMenu)
    _pauseMenuPanel.cancel_requested.connect(HandlePauseCancel)

func TogglePauseMenu() -> void:
    if IsTutorialActive():
        return
    if _isPaused:
        ResumePause()
    else:
        HideAllPanels()
        _isPaused = true
        get_tree().paused = true
        _pauseInputBlocker.visible = true
        _pauseMenuPanel.visible = true
        _hoveredControl = null
        _hoverTimer = 0.0
        if _customTooltip != null:
            _customTooltip.visible = false
        if _isCompactModeActive:
            _compactUI.visible = false
            _pauseMenuPanel.scale = Vector2.ONE
            SetPanelCompactMode(_pauseMenuPanel, true)
            call_deferred("DoCenterPanel", _pauseMenuPanel)
        else:
            UpdatePauseMenuPosition()

func ResumePause() -> void:
    ClosePauseSettings(false)
    _isPaused = false
    get_tree().paused = false
    _pauseMenuPanel.visible = false
    _pauseInputBlocker.visible = false
    if _isCompactModeActive and not IsAnyPanelVisible():
        _compactUI.visible = true

func OpenPauseSettings() -> void:
    if not _isPaused or _settingsUI == null:
        return

    HideAllPanels()
    _pauseSettingsOpen = true
    _pauseMenuPanel.visible = false
    if _settingsUI.get_parent() != _pauseInputBlocker:
        _settingsUI.reparent(_pauseInputBlocker, true)
    ShowPanel(_settingsUI)

func ClosePauseSettings(returnToPauseMenu: bool) -> void:
    if not _pauseSettingsOpen:
        return

    _pauseSettingsOpen = false
    if _settingsUI != null:
        _settingsUI.visible = false
        if _settingsUI.get_parent() != _uiRoot:
            _settingsUI.reparent(_uiRoot, true)

    if returnToPauseMenu and _isPaused:
        _pauseMenuPanel.visible = true
        UpdatePauseMenuPosition()

func HandlePauseCancel() -> void:
    if not _isPaused:
        return
    if _pauseSettingsOpen:
        ClosePauseSettings(true)
    else:
        ResumePause()

func UpdatePauseMenuPosition() -> void:
    if _pauseMenuPanel != null and is_instance_valid(_pauseMenuPanel):
        if _isCompactModeActive and _pauseMenuPanel.visible:
            DoCenterPanel(_pauseMenuPanel)
            return
        var sizeVal = _uiRoot.size if (_uiRoot != null and is_instance_valid(_uiRoot)) else get_viewport().get_visible_rect().size
        var x = (sizeVal.x - _pauseMenuPanel.size.x) / 2.0
        var y = (sizeVal.y - _pauseMenuPanel.size.y) / 2.0
        _pauseMenuPanel.position = Vector2(x, y)

func QuitToMainMenu() -> void:
    ResumePause()
    get_tree().change_scene_to_file("res://src/scenes/MainMenu/MainMenu.tscn")

func InitializeTutorialUI() -> void:
    var scene = load("res://src/ui/TutorialDialog/TutorialDialog.tscn") as PackedScene
    _tutorialDialogPanel = scene.instantiate() as TutorialDialog
    _tutorialDialogPanel.visible = false
    _tutorialDialogPanel.z_index = TutorialDialogZIndex
    _tutorialDialogPanel.z_as_relative = false
    _tutorialDialogPanel.anchors_preset = Control.PRESET_TOP_LEFT
    _uiRoot.add_child(_tutorialDialogPanel)

    _tutorialDialogName = _tutorialDialogPanel.DialogName
    _tutorialDialogText = _tutorialDialogPanel.DialogText
    _tutorialNextBtn = _tutorialDialogPanel.NextButton

    _tutorialNextBtn.pressed.connect(OnTutorialNextPressed)

func ShowTutorialDialogOnTop() -> void:
    if _tutorialDialogPanel == null or not is_instance_valid(_tutorialDialogPanel):
        return
    _tutorialDialogPanel.z_index = TutorialDialogZIndex
    _tutorialDialogPanel.z_as_relative = false
    _tutorialDialogPanel.show()
    BringTutorialDialogToFront()

func BringTutorialDialogToFront() -> void:
    if _tutorialDialogPanel == null or not is_instance_valid(_tutorialDialogPanel):
        return
    var parent = _tutorialDialogPanel.get_parent()
    if parent != null and parent.get_child_count() > 0:
        parent.move_child(_tutorialDialogPanel, parent.get_child_count() - 1)

func UpdateTutorialDialogPosition() -> void:
    if _tutorialDialogPanel != null and is_instance_valid(_tutorialDialogPanel):
        var sizeVal = _uiRoot.size if (_uiRoot != null and is_instance_valid(_uiRoot)) else get_viewport().get_visible_rect().size
        if sizeVal.x <= 0 or sizeVal.y <= 0:
            sizeVal = get_viewport().get_visible_rect().size
        var panelSize = _tutorialDialogPanel.size
        if panelSize.x <= 0 or panelSize.y <= 0:
            panelSize = _tutorialDialogPanel.custom_minimum_size
        var x = (sizeVal.x - panelSize.x) / 2.0
        var y = sizeVal.y - panelSize.y - 90.0
        _tutorialDialogPanel.position = Vector2(x, y)

func StartTutorial() -> void:
    HideAllPanels()
    _currentTutorialStep = TutorialStep.Intro1
    UpdateTutorialDialogPosition()
    ShowTutorialDialogOnTop()
    _player.is_talking = true
    
    UpdateTutorialRestrictions()
    ShowTutorialDialogText()

func ShowTutorialDialogText() -> void:
    match _currentTutorialStep:
        TutorialStep.Intro1:
            _tutorialDialogText.text = tr("Приветствую тебя, юный маг. Я — дух Альдебарана, предыдущего владельца этой древней мастерской. Вижу, ты решил восстановить её былое величие...")
            _tutorialNextBtn.text = tr("Далее >>")
            _tutorialNextBtn.show()
            _tutorialNextBtn.grab_focus()
        TutorialStep.Intro2:
            _tutorialDialogText.text = tr("Мастерская долгие годы была заброшена, но её магический кристалл всё ещё помнит основы чародейства. Не бойся, я поведу тебя шаг за шагом. Давай начнем!")
            _tutorialNextBtn.text = tr("Далее >>")
            _tutorialNextBtn.show()
            _tutorialNextBtn.grab_focus()
        TutorialStep.SummonPrompt:
            _tutorialDialogText.text = tr("Для начала нам нужно призвать существо для испытания чар. Нажми кнопку \"ПРИЗВАТЬ\" справа внизу (или клавишу %s), чтобы вызвать первую тварь.") % GetActionKeyName("summon_enemy")
            _tutorialNextBtn.hide()
        TutorialStep.LootPrompt:
            _tutorialDialogText.text = tr("Отлично! Магический кристалл победил врага. Дождись, пока выпавший материал попадёт в инвентарь.")
            _tutorialNextBtn.hide()
        TutorialStep.ShopPrompt:
            _tutorialDialogText.text = tr("Превосходно, золото и материалы у тебя! Давай зайдем в магазин, чтобы улучшить оборудование. Нажми кнопку \"Магазин\" внизу (или клавишу %s).") % GetActionKeyName("open_shop")
            _tutorialNextBtn.hide()
        TutorialStep.UpgradePrompt:
            _tutorialDialogText.text = tr("Перед тобой лавка. Сейчас доступна только вкладка \"Мастерская\" и только улучшение \"Больший котёл\". Остальные покупки и закрытие магазина заблокированы до завершения шага. Я выдал тебе достаточно золота!")
            _tutorialNextBtn.hide()
        TutorialStep.SkillsPrompt:
            _tutorialDialogText.text = tr("Молодец, мастерская становится сильнее! Но истинная мощь мага скрыта в его книге заклинаний. Закрой магазин и открой меню \"Навыки\" на панели внизу (или клавишу %s).") % GetActionKeyName("open_skills")
            _tutorialNextBtn.hide()
        TutorialStep.LearnSkillPrompt:
            var grantedSkillPoints = GetRequiredTutorialSkillPoints()
            _tutorialDialogText.text = GameLocalization.Format("TUTORIAL_SKILL_POINTS", {"count": grantedSkillPoints})
            _tutorialNextBtn.hide()
        TutorialStep.Final1:
            _tutorialDialogText.text = tr("Невероятно! Ты потрясающе быстро осваиваешься. Теперь мастерская полностью в твоих руках.")
            _tutorialNextBtn.text = tr("Далее >>")
            _tutorialNextBtn.show()
            _tutorialNextBtn.grab_focus()
        TutorialStep.Final2:
            _tutorialDialogText.text = tr("Побеждай волны врагов, призывай грозных боссов на каждой 5-й волне, разблокируй редкий лут и изучай легендарные заклинания. Удачи, юный чародей!")
            _tutorialNextBtn.text = tr("Завершить")
            _tutorialNextBtn.show()
            _tutorialNextBtn.grab_focus()

func GetActionKeyName(actionName: String) -> String:
    if InputMap.has_action(actionName):
        var events = InputMap.action_get_events(actionName)
        if events.size() > 0 and events[0] is InputEventKey:
            var keyEvent = events[0] as InputEventKey
            var code = keyEvent.keycode if keyEvent.keycode != KEY_NONE else keyEvent.physical_keycode
            var keyName = OS.get_keycode_string(code)
            if keyName == "Space": return tr("Пробел")
            if keyName == "Enter": return tr("Ввод")
            if keyName == "Kp Enter": return tr("Ввод")
            return keyName
    return tr("[Не назначено]")

func OnTutorialNextPressed() -> void:
    match _currentTutorialStep:
        TutorialStep.Intro1:
            _currentTutorialStep = TutorialStep.Intro2
            ShowTutorialDialogText()
        TutorialStep.Intro2:
            _currentTutorialStep = TutorialStep.SummonPrompt
            _player.is_talking = true
            UpdateTutorialRestrictions()
            ShowTutorialDialogText()
        TutorialStep.Final1:
            _currentTutorialStep = TutorialStep.Final2
            ShowTutorialDialogText()
        TutorialStep.Final2:
            _currentTutorialStep = TutorialStep.Completed
            _player.TutorialCompleted = true
            _player.is_talking = false
            _player.SaveSettings()
            _tutorialDialogPanel.hide()
            UpdateTutorialRestrictions()
            _lastPlayerLevel = _player.Level
            if _settingsUI != null:
                _settingsUI.UpdateTutorialCheckbox()
            ShowToast(tr("Обучение завершено! Добро пожаловать в игру."))

func UpdateTutorialRestrictions() -> void:
    if _player == null or _player.TutorialCompleted:
        if SummonButton != null: SummonButton.disabled = false
        if _compactSummonBtn != null and is_instance_valid(_compactSummonBtn): _compactSummonBtn.disabled = false
        if SkillsButton != null: SkillsButton.disabled = false
        if UpgradesButton != null: UpgradesButton.disabled = false
        if EquipmentButton != null: EquipmentButton.disabled = false
        if ShopButton != null: ShopButton.disabled = false
        if _compactBoostsBtn != null and is_instance_valid(_compactBoostsBtn): _compactBoostsBtn.disabled = false
        if SettingsButton != null: SettingsButton.disabled = false
        if _compactUI != null and is_instance_valid(_compactUI):
            _compactUI.InventoryBtn.disabled = false
            _compactUI.SkillsBtn.disabled = false
            _compactUI.UpgradesBtn.disabled = false
            _compactUI.SettingsBtn.disabled = false
            _compactUI.PauseBtn.disabled = false
            _compactUI.RestoreButton.disabled = false
        _shopUI.SetTutorialMode(ShopUI.TutorialMode.None)
        _skillsUI.SetTutorialRestriction(false)
        return

    if SummonButton != null: SummonButton.disabled = true
    if _compactSummonBtn != null and is_instance_valid(_compactSummonBtn): _compactSummonBtn.disabled = true
    if SkillsButton != null: SkillsButton.disabled = true
    if UpgradesButton != null: UpgradesButton.disabled = true
    if EquipmentButton != null: EquipmentButton.disabled = true
    if ShopButton != null: ShopButton.disabled = true
    if _compactBoostsBtn != null and is_instance_valid(_compactBoostsBtn): _compactBoostsBtn.disabled = true
    if SettingsButton != null: SettingsButton.disabled = true
    if _compactUI != null and is_instance_valid(_compactUI):
        _compactUI.InventoryBtn.disabled = true
        _compactUI.SkillsBtn.disabled = true
        _compactUI.UpgradesBtn.disabled = true
        _compactUI.SettingsBtn.disabled = true
        _compactUI.PauseBtn.disabled = true
        _compactUI.RestoreButton.disabled = true

    var shopMode = ShopUI.TutorialMode.None
    match _currentTutorialStep:
        TutorialStep.ShopPrompt, TutorialStep.UpgradePrompt:
            shopMode = ShopUI.TutorialMode.WorkshopUpgrade
        TutorialStep.SkillsPrompt:
            shopMode = ShopUI.TutorialMode.CloseOnly
    _shopUI.SetTutorialMode(shopMode)

    var restrictSkills = _currentTutorialStep == TutorialStep.SkillsPrompt or _currentTutorialStep == TutorialStep.LearnSkillPrompt
    _skillsUI.SetTutorialRestriction(restrictSkills, [ "spell_power_small", "summon_master_small" ])
    _player.is_talking = _currentTutorialStep != TutorialStep.LootPrompt

    match _currentTutorialStep:
        TutorialStep.SummonPrompt:
            if SummonButton != null: SummonButton.disabled = false
            if _compactSummonBtn != null and is_instance_valid(_compactSummonBtn): _compactSummonBtn.disabled = false
        TutorialStep.ShopPrompt:
            if ShopButton != null: ShopButton.disabled = false
            if _compactBoostsBtn != null and is_instance_valid(_compactBoostsBtn): _compactBoostsBtn.disabled = false
        TutorialStep.SkillsPrompt:
            if SkillsButton != null: SkillsButton.disabled = false
            if _compactUI != null and is_instance_valid(_compactUI): _compactUI.SkillsBtn.disabled = false
        TutorialStep.LearnSkillPrompt:
            if SkillsButton != null: SkillsButton.disabled = false
            if _compactUI != null and is_instance_valid(_compactUI): _compactUI.SkillsBtn.disabled = false

func ProcessTutorialLogic(delta: float) -> void:
    match _currentTutorialStep:
        TutorialStep.SummonPrompt:
            var activeEnemies = get_tree().get_nodes_in_group("enemies")
            if _hasSummonedEnemy and activeEnemies.size() > 0:
                _currentTutorialStep = TutorialStep.LootPrompt
                _player.is_talking = false
                _tutorialLastMatCount = GetTotalMaterialsCount()
                _tutorialStartKillsCount = _player.KillsCount
                _tutorialLootFallbackTimer = 0.0
                UpdateTutorialRestrictions()
                ShowTutorialDialogText()

        TutorialStep.LootPrompt:
            var currentMats = GetTotalMaterialsCount()
            var tutorialEnemyKilled = _player.KillsCount > _tutorialStartKillsCount
            if tutorialEnemyKilled and currentMats > _tutorialLastMatCount:
                AdvanceTutorialToShop()
            elif tutorialEnemyKilled:
                _tutorialLootFallbackTimer += delta
                if _tutorialLootFallbackTimer >= TutorialLootFallbackDelay:
                    var fallbackMaterial = ItemDatabase.get_item("mat_slime", 1)
                    if fallbackMaterial != null:
                        _player.AddToInventory(fallbackMaterial)
                    AdvanceTutorialToShop()

        TutorialStep.ShopPrompt:
            if _shopUI != null and _shopUI.visible:
                _currentTutorialStep = TutorialStep.UpgradePrompt
                var cauldronUpgradeCost = 100 * (_player.CauldronLevel + 1)
                _player.Gold += max(200, cauldronUpgradeCost - _player.Gold)
                _player.is_talking = true
                UpdateTutorialRestrictions()
                ShowTutorialDialogText()

        TutorialStep.SkillsPrompt:
            if (_shopUI == null or not _shopUI.visible) and _skillsUI != null and _skillsUI.visible:
                _currentTutorialStep = TutorialStep.LearnSkillPrompt
                var requiredSkillPoints = GetRequiredTutorialSkillPoints()
                if requiredSkillPoints == 0:
                    CompleteTutorialSkillStep()
                    return
                _player.SkillPoints = max(_player.SkillPoints, requiredSkillPoints)
                _skillsUI.Refresh()
                UpdateTutorialRestrictions()
                ShowTutorialDialogText()

func AdvanceTutorialToShop() -> void:
    _currentTutorialStep = TutorialStep.ShopPrompt
    _player.is_talking = true
    _tutorialLootFallbackTimer = 0.0
    UpdateTutorialRestrictions()
    ShowTutorialDialogText()

func OnTutorialWorkshopUpgradePurchased(_propertyIndex: int) -> void:
    if not IsTutorialActive() or _currentTutorialStep != TutorialStep.UpgradePrompt:
        return

    _currentTutorialStep = TutorialStep.SkillsPrompt
    UpdateTutorialRestrictions()
    ShowTutorialDialogText()

func OnTutorialSkillPurchased(skillId: String) -> void:
    if not IsTutorialActive() or _currentTutorialStep != TutorialStep.LearnSkillPrompt:
        return
    if skillId != "spell_power_small" and skillId != "summon_master_small":
        return

    CompleteTutorialSkillStep()

func GetRequiredTutorialSkillPoints() -> int:
    if _player == null:
        return 1

    var spellCost = _player.SpellPowerSmallSkillLevel + 1 if _player.SpellPowerSmallSkillLevel < 3 else 999999
    var summonCost = _player.SummonMasterSmallSkillLevel + 1 if _player.SummonMasterSmallSkillLevel < 3 else 999999
    var required = min(spellCost, summonCost)
    return 0 if required == 999999 else required

func CompleteTutorialSkillStep() -> void:
    _currentTutorialStep = TutorialStep.Final1
    if _skillsUI != null:
        _skillsUI.visible = false
    _player.is_talking = true
    UpdateTutorialRestrictions()
    ShowTutorialDialogOnTop()
    ShowTutorialDialogText()

func GetTotalMaterialsCount() -> int:
    var count = 0
    if _player != null:
        for item in _player.Inventory:
            if item != null and item.Type == ItemData.ItemType.Material:
                count += item.StackCount
    return count

func ProcessToastLogic(delta: float) -> void:
    if _isCompactModeActive:
        if _player != null:
            _lastPlayerLevel = _player.Level
        _toastTimer = 0.0
        return

    if _player != null and _player.Level != _lastPlayerLevel:
        _lastPlayerLevel = _player.Level
        ShowToast(tr("Новый уровень! Открой дерево навыков (K), чтобы распределить очки навыков."))
        _toastTimer = 0.0
        return

    if Time.get_ticks_msec() < 900000:
        _toastTimer += delta
        if _toastTimer >= _toastInterval:
            _toastTimer = 0.0
            var idx = randi() % ToastTips.size()
            ShowToast(tr(ToastTips[idx]))

func SetUIScale(scaleVal: float) -> void:
    _currentUiScale = clampf(scaleVal, 0.5, 2.0)
    ApplyUiRootScale(1.0 if _isCompactModeActive else _currentUiScale)

    UpdateTutorialDialogPosition()
    UpdatePauseMenuPosition()

    if _inventoryUI != null and _inventoryUI.visible: DoCenterPanel(_inventoryUI)
    if _shopUI != null and _shopUI.visible: DoCenterPanel(_shopUI)
    if _settingsUI != null and _settingsUI.visible: DoCenterPanel(_settingsUI)
    if _skillsUI != null and _skillsUI.visible: DoCenterPanel(_skillsUI)
    if _upgradesUI != null and _upgradesUI.visible: DoCenterPanel(_upgradesUI)

func ApplyUiRootScale(effectiveScale: float) -> void:
    if _uiRoot != null and is_instance_valid(_uiRoot):
        var screenSize = get_viewport().get_visible_rect().size

        _uiRoot.anchor_left = 0.0
        _uiRoot.anchor_top = 0.0
        _uiRoot.anchor_right = 0.0
        _uiRoot.anchor_bottom = 0.0
        _uiRoot.position = Vector2.ZERO
        _uiRoot.pivot_offset = Vector2.ZERO
        _uiRoot.size = screenSize / effectiveScale
        _uiRoot.scale = Vector2.ONE * effectiveScale

func OnViewportSizeChanged() -> void:
    SetUIScale(_currentUiScale)

func _exit_tree() -> void:
    if get_tree() != null:
        get_tree().paused = false
    get_viewport().size_changed.disconnect(OnViewportSizeChanged)
