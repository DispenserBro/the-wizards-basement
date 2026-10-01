class_name Player
extends CharacterBody2D

signal inventory_updated
signal ad_boosts_updated

const Speed = 150.0
const AttackRange = 22.0
const AttackCooldown = 0.8
const BaseDamageVal = 5

var _sprite: AnimatedSprite2D
var _collisionShape: CollisionShape2D

# Pathfinding variables
var _astar: AStarGrid2D
var _wallsLayer: TileMapLayer
var _pathfindTimer: float = 0.0
const PathfindInterval = 0.2
var _currentPath: Array[Vector2] = []
var _currentPathIndex: int = 0

# Target and combat variables
var _target: CharacterBody2D
var _attackCooldownTimer: float = 0.0

# Health variables
@export var MaxHealth: int = 100
@export var Health: int = 100
@export var UpgradesDamage: int = 1
@export var TreeSkillsDamage: int = 2
@export var CritMultiplier: float = 2.0

# Inventory and equipment containers
var Inventory: Array[ItemData] = []
var EquippedItems: Array[ItemData] = []

# Dynamic stats calculated from equipped items
var StaffDamage: int:
    get:
        return EquippedItems[1].BaseDamage if EquippedItems[1] != null else 0

var MagicStoneDamage: int:
    get:
        return EquippedItems[0].BaseDamage if EquippedItems[0] != null else 0

var MagicStoneMana: int:
    get:
        return EquippedItems[0].ManaBonus if EquippedItems[0] != null else 0

var AmuletRegen: float:
    get:
        return 0.0

var AmuletCritChance: float:
    get:
        var chance: float = 0.0
        if EquippedItems[2] != null:
            chance += EquippedItems[2].CritChanceBonus
        if EquippedItems[3] != null:
            chance += EquippedItems[3].CritChanceBonus
        return chance

var AmuletAttackSpeedBonus: float:
    get:
        var bonus: float = 0.0
        if EquippedItems[1] != null:
            bonus += EquippedItems[1].AttackSpeedBonus
        if EquippedItems[2] != null:
            bonus += EquippedItems[2].AttackSpeedBonus
        if EquippedItems[3] != null:
            bonus += EquippedItems[3].AttackSpeedBonus
        return bonus

# Camera shake & regen timers
var _camera: Camera2D
var _shakeTimer: float = 0.0
var _shakeIntensity: float = 0.0


@export var Level: int = 1
@export var Experience: int = 0

var _gold: int = 0

@export var Gold: int:
    get:
        return _gold
    set(value):
        _gold = value
        inventory_updated.emit()

@export var KillsCount: int = 0
@export var WaveCount: int = 1
@export var KillsOnCurrentWave: int = 0
@export var IsBossActive: bool = false
@export var BossTimer: float = 0.0
@export var facing_right: bool = true
@export var is_attacking: bool = false
@export var is_talking: bool = false
@export var HasSeekerLuckSkill: bool = false

@export var CauldronLevel: int = 0
@export var CrystalLevel: int = 0
@export var EnchantLevel: int = 0

@export var WrathPotionTimer: float = 0.0
@export var LuckyElixirEnemiesCount: int = 0
@export var HasteScrollTimer: float = 0.0
@export var SpeedPotionTimer: float = 0.0
@export var CritPotionTimer: float = 0.0
@export var CritDamageScrollTimer: float = 0.0

# --- LEVELING & SKILL POINTS ---
@export var SkillPoints: int = 0

# --- WIZARD UPGRADES (0-10 levels) ---
@export var StaffUpgradeLevel: int = 0
@export var CrystalUpgradeLevel: int = 0
@export var WardsUpgradeLevel: int = 0
@export var GoldUpgradeLevel: int = 0
@export var InsightUpgradeLevel: int = 0
@export var CritUpgradeLevel: int = 0
@export var ManaUpgradeLevel: int = 0

# Locked Upgrades (opened by skills)
@export var ElementalPortalLevel: int = 0
@export var LegendaryFocusLevel: int = 0

@export var TutorialCompleted: bool = false
@export var HasRequestedReview: bool = false
@export var LastRewardedAdTime: int = 0
@export var LastAdBoostTimes: Dictionary = {}

# --- REWARDED AD BOOST TIMERS & CONSTANTS ---
const MAX_BOOST_DURATION: float = 300.0 # 5 minutes
const BOOST_BASE_DURATION: float = 300.0 # 5 minutes

@export var AdGoldBoostTimer: float = 0.0
@export var AdDamageBoostTimer: float = 0.0
@export var AdSwiftnessBoostTimer: float = 0.0
@export var AdLuckBoostTimer: float = 0.0

# --- SKILL TREE LEVELS (0-3 levels) ---
@export var SpellPowerSmallSkillLevel: int = 0
@export var SpellPowerMediumSkillLevel: int = 0
@export var SpellPowerLargeSkillLevel: int = 0

@export var SummonMasterSmallSkillLevel: int = 0
@export var SummonMasterMediumSkillLevel: int = 0
@export var SummonMasterLargeSkillLevel: int = 0

@export var TreasureHunterSkillLevel: int = 0
@export var GoldRushSkillLevel: int = 0
@export var CritMagicSkillLevel: int = 0
@export var AncientWisdomSkillLevel: int = 0
@export var AstralLinkSkillLevel: int = 0
@export var AutoSummonSkillLevel: int = 0
@export var ManaOverloadSkillLevel: int = 0
@export var CrystalSynergySkillLevel: int = 0
@export var MagicResonanceSkillLevel: int = 0
@export var AstralBlastSkillLevel: int = 0
@export var UltimateFocusSkillLevel: int = 0

var HasLuckyElixirActive: bool:
    get:
        return LuckyElixirEnemiesCount > 0

var EquipmentDropLuckMultiplier: float:
    get:
        var mult: float = 1.0
        if HasSeekerLuckSkill:
            mult += 0.25
        if HasLuckyElixirActive:
            mult += 0.25
        if AdLuckBoostTimer > 0.0:
            mult += 0.50
        return mult

var GoldMultiplier: float:
    get:
        var mult: float = 1.0 + CauldronLevel * 0.10 + GoldUpgradeLevel * 0.10 + GoldRushSkillLevel * 0.15 + WardsUpgradeLevel * 0.05
        var hasRatLuck: bool = (EquippedItems[2] != null and EquippedItems[2].Id == "equip_rat_luck") or (EquippedItems[3] != null and EquippedItems[3].Id == "equip_rat_luck")
        if hasRatLuck:
            mult += 0.25
        if AdGoldBoostTimer > 0.0:
            mult *= 2.0
        return mult

var ExperienceMultiplier: float:
    get:
        var mult: float = 1.0 + CrystalLevel * 0.05 + InsightUpgradeLevel * 0.10 + AncientWisdomSkillLevel * 0.10 + WardsUpgradeLevel * 0.05
        var hasElfWisdom: bool = EquippedItems[0] != null and EquippedItems[0].Id == "equip_elf_wisdom"
        if hasElfWisdom:
            mult += 0.30
        return mult

var SummonCooldownReductionFactor: float:
    get:
        var hasSynergy = CrystalSynergySkillLevel > 0
        var crystalEffect = CrystalUpgradeLevel * (0.06 if hasSynergy else 0.05)
        var masterEffect = SummonMasterSmallSkillLevel * 0.01 + SummonMasterMediumSkillLevel * 0.02 + SummonMasterLargeSkillLevel * 0.05
        var portalEffect = ElementalPortalLevel * 0.15
        var ultimateEffect = UltimateFocusSkillLevel * 0.10
        var adBonus = 0.30 if AdLuckBoostTimer > 0.0 else 0.0
        var totalReduction = crystalEffect + masterEffect + portalEffect + ultimateEffect + adBonus
        return maxf(0.10, 1.0 - totalReduction)

var UpgradesGoldDiscountMultiplier: float:
    get:
        return 1.0 - AncientWisdomSkillLevel * 0.05

func ActivateAdBoost(boostType: String) -> void:
    match boostType:
        "gold":
            AdGoldBoostTimer = minf(MAX_BOOST_DURATION, AdGoldBoostTimer + BOOST_BASE_DURATION)
        "damage":
            AdDamageBoostTimer = minf(MAX_BOOST_DURATION, AdDamageBoostTimer + BOOST_BASE_DURATION)
        "swiftness":
            AdSwiftnessBoostTimer = minf(MAX_BOOST_DURATION, AdSwiftnessBoostTimer + BOOST_BASE_DURATION)
        "luck":
            AdLuckBoostTimer = minf(MAX_BOOST_DURATION, AdLuckBoostTimer + BOOST_BASE_DURATION)
    ad_boosts_updated.emit()
    SaveSettings()

func _init() -> void:
    Inventory.resize(36)
    EquippedItems.resize(4)

func GetXPNeeded(lvl: int) -> int:
    return roundi(150.0 * pow(1.25, lvl - 1))

func GainExperience(amount: int) -> void:
    Experience += amount
    var leveledUp = false
    while Experience >= GetXPNeeded(Level):
        Experience -= GetXPNeeded(Level)
        Level += 1
        SkillPoints += 1
        MaxHealth += 10
        Health = MaxHealth
        leveledUp = true

    if leveledUp:
        GameAudio.Play(GameAudio.LEVEL_UP)
        FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -30), tr("НОВЫЙ УРОВЕНЬ!"), Color.GOLD, 12, 1.5)
    SaveSettings()

func GetSkillLevel(skillId: String) -> int:
    match skillId:
        "spell_power_small": return SpellPowerSmallSkillLevel
        "spell_power_medium": return SpellPowerMediumSkillLevel
        "spell_power_large": return SpellPowerLargeSkillLevel
        "summon_master_small": return SummonMasterSmallSkillLevel
        "summon_master_medium": return SummonMasterMediumSkillLevel
        "summon_master_large": return SummonMasterLargeSkillLevel
        "treasure_hunter": return TreasureHunterSkillLevel
        "gold_rush": return GoldRushSkillLevel
        "crit_magic": return CritMagicSkillLevel
        "ancient_wisdom": return AncientWisdomSkillLevel
        "astral_link": return AstralLinkSkillLevel
        "auto_summon": return AutoSummonSkillLevel
        "mana_overload": return ManaOverloadSkillLevel
        "crystal_synergy": return CrystalSynergySkillLevel
        "magic_resonance": return MagicResonanceSkillLevel
        "astral_blast": return AstralBlastSkillLevel
        "ultimate_focus": return UltimateFocusSkillLevel
        _: return 0

func SetSkillLevel(skillId: String, level: int) -> void:
    match skillId:
        "spell_power_small": SpellPowerSmallSkillLevel = level
        "spell_power_medium": SpellPowerMediumSkillLevel = level
        "spell_power_large": SpellPowerLargeSkillLevel = level
        "summon_master_small": SummonMasterSmallSkillLevel = level
        "summon_master_medium": SummonMasterMediumSkillLevel = level
        "summon_master_large": SummonMasterLargeSkillLevel = level
        "treasure_hunter": TreasureHunterSkillLevel = level
        "gold_rush": GoldRushSkillLevel = level
        "crit_magic": CritMagicSkillLevel = level
        "ancient_wisdom": AncientWisdomSkillLevel = level
        "astral_link": AstralLinkSkillLevel = level
        "auto_summon": AutoSummonSkillLevel = level
        "mana_overload": ManaOverloadSkillLevel = level
        "crystal_synergy": CrystalSynergySkillLevel = level
        "magic_resonance": MagicResonanceSkillLevel = level
        "astral_blast": AstralBlastSkillLevel = level
        "ultimate_focus": UltimateFocusSkillLevel = level
    SaveSettings()

func GetUpgradeLevel(upgradeId: String) -> int:
    match upgradeId:
        "staff": return StaffUpgradeLevel
        "crystal": return CrystalUpgradeLevel
        "wards": return WardsUpgradeLevel
        "gold": return GoldUpgradeLevel
        "insight": return InsightUpgradeLevel
        "crit": return CritUpgradeLevel
        "mana": return ManaUpgradeLevel
        "portal": return ElementalPortalLevel
        "focus": return LegendaryFocusLevel
        _: return 0

func SetUpgradeLevel(upgradeId: String, level: int) -> void:
    match upgradeId:
        "staff": StaffUpgradeLevel = level
        "crystal": CrystalUpgradeLevel = level
        "wards": WardsUpgradeLevel = level
        "gold": GoldUpgradeLevel = level
        "insight": InsightUpgradeLevel = level
        "crit": CritUpgradeLevel = level
        "mana": ManaUpgradeLevel = level
        "portal": ElementalPortalLevel = level
        "focus": LegendaryFocusLevel = level
    SaveSettings()

func SaveSettings() -> void:
    var config = ConfigFile.new()
    config.load("user://settings.cfg")

    config.set_value("Progression", "Level", Level)
    config.set_value("Progression", "Experience", Experience)
    config.set_value("Progression", "Gold", Gold)
    config.set_value("Progression", "KillsCount", KillsCount)
    config.set_value("Progression", "WaveCount", WaveCount)
    config.set_value("Progression", "KillsOnCurrentWave", KillsOnCurrentWave)
    config.set_value("Progression", "SkillPoints", SkillPoints)

    # Upgrades
    config.set_value("Progression", "StaffUpgradeLevel", StaffUpgradeLevel)
    config.set_value("Progression", "CrystalUpgradeLevel", CrystalUpgradeLevel)
    config.set_value("Progression", "WardsUpgradeLevel", WardsUpgradeLevel)
    config.set_value("Progression", "GoldUpgradeLevel", GoldUpgradeLevel)
    config.set_value("Progression", "InsightUpgradeLevel", InsightUpgradeLevel)
    config.set_value("Progression", "CritUpgradeLevel", CritUpgradeLevel)
    config.set_value("Progression", "ManaUpgradeLevel", ManaUpgradeLevel)
    config.set_value("Progression", "ElementalPortalLevel", ElementalPortalLevel)
    config.set_value("Progression", "LegendaryFocusLevel", LegendaryFocusLevel)
    config.set_value("Progression", "TutorialCompleted", TutorialCompleted)
    config.set_value("Progression", "HasRequestedReview", HasRequestedReview)
    config.set_value("Progression", "AdGoldBoostTimer", AdGoldBoostTimer)
    config.set_value("Progression", "AdDamageBoostTimer", AdDamageBoostTimer)
    config.set_value("Progression", "AdSwiftnessBoostTimer", AdSwiftnessBoostTimer)
    config.set_value("Progression", "AdLuckBoostTimer", AdLuckBoostTimer)

    # Skills
    config.set_value("Progression", "SpellPowerSmallSkillLevel", SpellPowerSmallSkillLevel)
    config.set_value("Progression", "SpellPowerMediumSkillLevel", SpellPowerMediumSkillLevel)
    config.set_value("Progression", "SpellPowerLargeSkillLevel", SpellPowerLargeSkillLevel)
    config.set_value("Progression", "SummonMasterSmallSkillLevel", SummonMasterSmallSkillLevel)
    config.set_value("Progression", "SummonMasterMediumSkillLevel", SummonMasterMediumSkillLevel)
    config.set_value("Progression", "SummonMasterLargeSkillLevel", SummonMasterLargeSkillLevel)
    config.set_value("Progression", "TreasureHunterSkillLevel", TreasureHunterSkillLevel)
    config.set_value("Progression", "GoldRushSkillLevel", GoldRushSkillLevel)
    config.set_value("Progression", "CritMagicSkillLevel", CritMagicSkillLevel)
    config.set_value("Progression", "AncientWisdomSkillLevel", AncientWisdomSkillLevel)
    config.set_value("Progression", "AstralLinkSkillLevel", AstralLinkSkillLevel)
    config.set_value("Progression", "AutoSummonSkillLevel", AutoSummonSkillLevel)
    config.set_value("Progression", "ManaOverloadSkillLevel", ManaOverloadSkillLevel)
    config.set_value("Progression", "CrystalSynergySkillLevel", CrystalSynergySkillLevel)
    config.set_value("Progression", "MagicResonanceSkillLevel", MagicResonanceSkillLevel)
    config.set_value("Progression", "AstralBlastSkillLevel", AstralBlastSkillLevel)
    config.set_value("Progression", "UltimateFocusSkillLevel", UltimateFocusSkillLevel)

    config.save("user://settings.cfg")

    # Serialize Inventory & Equipment
    var serialized_inv: Array = []
    for item in Inventory:
        if item != null:
            serialized_inv.append(item.to_dict())
        else:
            serialized_inv.append(null)

    var serialized_equip: Array = []
    for item in EquippedItems:
        if item != null:
            serialized_equip.append(item.to_dict())
        else:
            serialized_equip.append(null)

    # Cloud & Local save data package
    var data = {
        "Level": Level,
        "Experience": Experience,
        "Gold": Gold,
        "KillsCount": KillsCount,
        "WaveCount": WaveCount,
        "KillsOnCurrentWave": KillsOnCurrentWave,
        "SkillPoints": SkillPoints,
        
        "StaffUpgradeLevel": StaffUpgradeLevel,
        "CrystalUpgradeLevel": CrystalUpgradeLevel,
        "WardsUpgradeLevel": WardsUpgradeLevel,
        "GoldUpgradeLevel": GoldUpgradeLevel,
        "InsightUpgradeLevel": InsightUpgradeLevel,
        "CritUpgradeLevel": CritUpgradeLevel,
        "ManaUpgradeLevel": ManaUpgradeLevel,
        "ElementalPortalLevel": ElementalPortalLevel,
        "LegendaryFocusLevel": LegendaryFocusLevel,
        "TutorialCompleted": TutorialCompleted,
        "HasRequestedReview": HasRequestedReview,
        "LastRewardedAdTime": LastRewardedAdTime,
        "LastAdBoostTimes": LastAdBoostTimes,
        "AdGoldBoostTimer": AdGoldBoostTimer,
        "AdDamageBoostTimer": AdDamageBoostTimer,
        "AdSwiftnessBoostTimer": AdSwiftnessBoostTimer,
        "AdLuckBoostTimer": AdLuckBoostTimer,
        
        "SpellPowerSmallSkillLevel": SpellPowerSmallSkillLevel,
        "SpellPowerMediumSkillLevel": SpellPowerMediumSkillLevel,
        "SpellPowerLargeSkillLevel": SpellPowerLargeSkillLevel,
        "SummonMasterSmallSkillLevel": SummonMasterSmallSkillLevel,
        "SummonMasterMediumSkillLevel": SummonMasterMediumSkillLevel,
        "SummonMasterLargeSkillLevel": SummonMasterLargeSkillLevel,
        "TreasureHunterSkillLevel": TreasureHunterSkillLevel,
        "GoldRushSkillLevel": GoldRushSkillLevel,
        "CritMagicSkillLevel": CritMagicSkillLevel,
        "AncientWisdomSkillLevel": AncientWisdomSkillLevel,
        "AstralLinkSkillLevel": AstralLinkSkillLevel,
        "AutoSummonSkillLevel": AutoSummonSkillLevel,
        "ManaOverloadSkillLevel": ManaOverloadSkillLevel,
        "CrystalSynergySkillLevel": CrystalSynergySkillLevel,
        "MagicResonanceSkillLevel": MagicResonanceSkillLevel,
        "AstralBlastSkillLevel": AstralBlastSkillLevel,
        "UltimateFocusSkillLevel": UltimateFocusSkillLevel,

        "Inventory": serialized_inv,
        "Equipment": serialized_equip
    }

    # 1. Desktop & Local fallback save to user://savegame.dat
    var save_file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
    if save_file != null:
        save_file.store_string(JSON.stringify(data))
        save_file.close()

    # 2. Cloud save using Playgama Bridge for Web builds
    if get_node_or_null("/root/BridgeManager") != null and get_node("/root/BridgeManager").is_active() and Bridge != null and Bridge.storage != null:
        Bridge.storage.set("player_progress", JSON.stringify(data))

func LoadSettings() -> void:
    # 1. First, load settings.cfg for settings fallback
    var config = ConfigFile.new()
    if config.load("user://settings.cfg") == OK:
        ApplyLoadedSettings(config)

    # 2. Load local savegame.dat if available
    if FileAccess.file_exists("user://savegame.dat"):
        var save_file = FileAccess.open("user://savegame.dat", FileAccess.READ)
        if save_file != null:
            var text = save_file.get_as_text()
            save_file.close()
            var parsed = JSON.parse_string(text)
            if parsed is Dictionary and not parsed.is_empty():
                ApplyBridgeData(parsed)

    # 3. Load from cloud storage asynchronously for Web builds
    if get_node_or_null("/root/BridgeManager") != null and get_node("/root/BridgeManager").is_active() and Bridge != null and Bridge.storage != null:
        Bridge.storage.get("player_progress", OnBridgeProgressLoaded)

func ApplyLoadedSettings(config: ConfigFile) -> void:
    Level = config.get_value("Progression", "Level", 1)
    Experience = config.get_value("Progression", "Experience", 0)
    Gold = config.get_value("Progression", "Gold", 0)
    KillsCount = config.get_value("Progression", "KillsCount", 0)
    WaveCount = config.get_value("Progression", "WaveCount", 1)
    KillsOnCurrentWave = config.get_value("Progression", "KillsOnCurrentWave", 0)
    SkillPoints = config.get_value("Progression", "SkillPoints", 0)

    # Upgrades
    StaffUpgradeLevel = config.get_value("Progression", "StaffUpgradeLevel", 0)
    CrystalUpgradeLevel = config.get_value("Progression", "CrystalUpgradeLevel", 0)
    WardsUpgradeLevel = config.get_value("Progression", "WardsUpgradeLevel", 0)
    GoldUpgradeLevel = config.get_value("Progression", "GoldUpgradeLevel", 0)
    InsightUpgradeLevel = config.get_value("Progression", "InsightUpgradeLevel", 0)
    CritUpgradeLevel = config.get_value("Progression", "CritUpgradeLevel", 0)
    ManaUpgradeLevel = config.get_value("Progression", "ManaUpgradeLevel", 0)
    ElementalPortalLevel = config.get_value("Progression", "ElementalPortalLevel", 0)
    LegendaryFocusLevel = config.get_value("Progression", "LegendaryFocusLevel", 0)
    var showTutorial = config.get_value("Gameplay", "ShowTutorial", true)
    TutorialCompleted = not showTutorial or config.get_value("Progression", "TutorialCompleted", false)
    HasRequestedReview = config.get_value("Progression", "HasRequestedReview", false)
    AdGoldBoostTimer = config.get_value("Progression", "AdGoldBoostTimer", 0.0)
    AdDamageBoostTimer = config.get_value("Progression", "AdDamageBoostTimer", 0.0)
    AdSwiftnessBoostTimer = config.get_value("Progression", "AdSwiftnessBoostTimer", 0.0)
    AdLuckBoostTimer = config.get_value("Progression", "AdLuckBoostTimer", 0.0)

    # Skills
    SpellPowerSmallSkillLevel = config.get_value("Progression", "SpellPowerSmallSkillLevel", 0)
    SpellPowerMediumSkillLevel = config.get_value("Progression", "SpellPowerMediumSkillLevel", 0)
    SpellPowerLargeSkillLevel = config.get_value("Progression", "SpellPowerLargeSkillLevel", 0)
    SummonMasterSmallSkillLevel = config.get_value("Progression", "SummonMasterSmallSkillLevel", 0)
    SummonMasterMediumSkillLevel = config.get_value("Progression", "SummonMasterMediumSkillLevel", 0)
    SummonMasterLargeSkillLevel = config.get_value("Progression", "SummonMasterLargeSkillLevel", 0)
    TreasureHunterSkillLevel = config.get_value("Progression", "TreasureHunterSkillLevel", 0)
    GoldRushSkillLevel = config.get_value("Progression", "GoldRushSkillLevel", 0)
    CritMagicSkillLevel = config.get_value("Progression", "CritMagicSkillLevel", 0)
    AncientWisdomSkillLevel = config.get_value("Progression", "AncientWisdomSkillLevel", 0)
    AstralLinkSkillLevel = config.get_value("Progression", "AstralLinkSkillLevel", 0)
    AutoSummonSkillLevel = config.get_value("Progression", "AutoSummonSkillLevel", 0)
    ManaOverloadSkillLevel = config.get_value("Progression", "ManaOverloadSkillLevel", 0)
    CrystalSynergySkillLevel = config.get_value("Progression", "CrystalSynergySkillLevel", 0)
    MagicResonanceSkillLevel = config.get_value("Progression", "MagicResonanceSkillLevel", 0)
    AstralBlastSkillLevel = config.get_value("Progression", "AstralBlastSkillLevel", 0)
    UltimateFocusSkillLevel = config.get_value("Progression", "UltimateFocusSkillLevel", 0)

func OnBridgeProgressLoaded(success: bool, raw_data: Variant) -> void:
    if not success or raw_data == null:
        return

    var data: Dictionary
    if raw_data is String:
        var parsed = JSON.parse_string(raw_data)
        if parsed is Dictionary:
            data = parsed
        else:
            return
    elif raw_data is Dictionary:
        data = raw_data
    else:
        return

    if data.is_empty():
        return

    ApplyBridgeData(data)

func ApplyBridgeData(data: Dictionary) -> void:
    Level = data.get("Level", Level)
    Experience = data.get("Experience", Experience)
    Gold = data.get("Gold", Gold)
    KillsCount = data.get("KillsCount", KillsCount)
    WaveCount = data.get("WaveCount", WaveCount)
    KillsOnCurrentWave = data.get("KillsOnCurrentWave", KillsOnCurrentWave)
    SkillPoints = data.get("SkillPoints", SkillPoints)

    # Upgrades
    StaffUpgradeLevel = data.get("StaffUpgradeLevel", StaffUpgradeLevel)
    CrystalUpgradeLevel = data.get("CrystalUpgradeLevel", CrystalUpgradeLevel)
    WardsUpgradeLevel = data.get("WardsUpgradeLevel", WardsUpgradeLevel)
    GoldUpgradeLevel = data.get("GoldUpgradeLevel", GoldUpgradeLevel)
    InsightUpgradeLevel = data.get("InsightUpgradeLevel", InsightUpgradeLevel)
    CritUpgradeLevel = data.get("CritUpgradeLevel", CritUpgradeLevel)
    ManaUpgradeLevel = data.get("ManaUpgradeLevel", ManaUpgradeLevel)
    ElementalPortalLevel = data.get("ElementalPortalLevel", ElementalPortalLevel)
    LegendaryFocusLevel = data.get("LegendaryFocusLevel", LegendaryFocusLevel)
    TutorialCompleted = data.get("TutorialCompleted", TutorialCompleted)
    HasRequestedReview = data.get("HasRequestedReview", HasRequestedReview)
    LastRewardedAdTime = data.get("LastRewardedAdTime", LastRewardedAdTime)
    AdGoldBoostTimer = float(data.get("AdGoldBoostTimer", AdGoldBoostTimer))
    AdDamageBoostTimer = float(data.get("AdDamageBoostTimer", AdDamageBoostTimer))
    AdSwiftnessBoostTimer = float(data.get("AdSwiftnessBoostTimer", AdSwiftnessBoostTimer))
    AdLuckBoostTimer = float(data.get("AdLuckBoostTimer", AdLuckBoostTimer))

    # Skills
    SpellPowerSmallSkillLevel = data.get("SpellPowerSmallSkillLevel", SpellPowerSmallSkillLevel)
    SpellPowerMediumSkillLevel = data.get("SpellPowerMediumSkillLevel", SpellPowerMediumSkillLevel)
    SpellPowerLargeSkillLevel = data.get("SpellPowerLargeSkillLevel", SpellPowerLargeSkillLevel)
    SummonMasterSmallSkillLevel = data.get("SummonMasterSmallSkillLevel", SummonMasterSmallSkillLevel)
    SummonMasterMediumSkillLevel = data.get("SummonMasterMediumSkillLevel", SummonMasterMediumSkillLevel)
    SummonMasterLargeSkillLevel = data.get("SummonMasterLargeSkillLevel", SummonMasterLargeSkillLevel)
    TreasureHunterSkillLevel = data.get("TreasureHunterSkillLevel", TreasureHunterSkillLevel)
    GoldRushSkillLevel = data.get("GoldRushSkillLevel", GoldRushSkillLevel)
    CritMagicSkillLevel = data.get("CritMagicSkillLevel", CritMagicSkillLevel)
    AncientWisdomSkillLevel = data.get("AncientWisdomSkillLevel", AncientWisdomSkillLevel)
    AstralLinkSkillLevel = data.get("AstralLinkSkillLevel", AstralLinkSkillLevel)
    AutoSummonSkillLevel = data.get("AutoSummonSkillLevel", AutoSummonSkillLevel)
    ManaOverloadSkillLevel = data.get("ManaOverloadSkillLevel", ManaOverloadSkillLevel)
    CrystalSynergySkillLevel = data.get("CrystalSynergySkillLevel", CrystalSynergySkillLevel)
    MagicResonanceSkillLevel = data.get("MagicResonanceSkillLevel", MagicResonanceSkillLevel)
    AstralBlastSkillLevel = data.get("AstralBlastSkillLevel", AstralBlastSkillLevel)
    UltimateFocusSkillLevel = data.get("UltimateFocusSkillLevel", UltimateFocusSkillLevel)

    # Restore Inventory
    var raw_inv = data.get("Inventory", null)
    if raw_inv is Array:
        Inventory.clear()
        Inventory.resize(36)
        for i in range(min(raw_inv.size(), 36)):
            if raw_inv[i] is Dictionary:
                Inventory[i] = ItemData.from_dict(raw_inv[i])
            else:
                Inventory[i] = null

    # Restore Equipment
    var raw_equip = data.get("Equipment", null)
    if raw_equip is Array:
        EquippedItems.clear()
        EquippedItems.resize(4)
        for i in range(min(raw_equip.size(), 4)):
            if raw_equip[i] is Dictionary:
                EquippedItems[i] = ItemData.from_dict(raw_equip[i])
            else:
                EquippedItems[i] = null

    # Emit signal to update UI
    inventory_updated.emit()

func OnWaveAdvanced() -> void:
    var bridge = get_node_or_null("/root/BridgeManager")
    if bridge != null:
        bridge.SetLeaderboardScore("waves", WaveCount)
        if not HasRequestedReview and WaveCount > 5:
            HasRequestedReview = true
            SaveSettings()
            bridge.RequestReview()


func GetTotalDamage() -> Dictionary:
    var baseDmg = BaseDamageVal + (Level - 1)

    var staffMult = 1.0 + StaffUpgradeLevel * 0.10 + SpellPowerSmallSkillLevel * 0.01 + SpellPowerMediumSkillLevel * 0.02 + SpellPowerLargeSkillLevel * 0.05
    if MagicResonanceSkillLevel > 0:
        var spawner = get_parent().get_node_or_null("EnemySpawner")
        if spawner != null and spawner.get_child_count() > 0:
            staffMult += MagicResonanceSkillLevel * 0.15
    var staffDmg = roundi(StaffDamage * staffMult)

    var stoneMult = 1.0 + ManaUpgradeLevel * 0.10 + ManaOverloadSkillLevel * 0.25
    if UltimateFocusSkillLevel > 0:
        stoneMult += UltimateFocusSkillLevel * 0.30
    var stoneDmg = roundi(MagicStoneDamage * stoneMult)

    var total = baseDmg + staffDmg + stoneDmg + UpgradesDamage + TreeSkillsDamage

    if WrathPotionTimer > 0.0:
        total = roundi(total * 1.50)
    if AdDamageBoostTimer > 0.0:
        total = roundi(total * 1.50)

    var totalCritChance = AmuletCritChance + CritUpgradeLevel * 0.03 + CritMagicSkillLevel * 0.05 + LegendaryFocusLevel * 0.10
    if CritPotionTimer > 0.0:
        totalCritChance += 0.15
    var isCrit = randf() < totalCritChance

    if isCrit:
        var totalCritMultiplier = CritMultiplier + EnchantLevel * 0.15 + CritUpgradeLevel * 0.15 + CritMagicSkillLevel * 0.15
        if AstralBlastSkillLevel > 0:
            totalCritMultiplier += AstralBlastSkillLevel * 0.25
        if CritDamageScrollTimer > 0.0:
            totalCritMultiplier += 0.50
        total = roundi(total * totalCritMultiplier)

    return {
        "damage": total,
        "is_crit": isCrit
    }

func GetCurrentTarget() -> CharacterBody2D:
    return _target

func _ready() -> void:
    _sprite = get_node("sprite")
    _collisionShape = get_node("CollisionShape2D")
    _camera = get_node_or_null("Camera2D")

    LoadSettings()
    Health = MaxHealth

    if _sprite != null:
        _sprite.animation_finished.connect(OnAnimationFinished)

    call_deferred("InitializePathfinding")

func InitializePathfinding() -> void:
    _wallsLayer = get_parent().get_node_or_null("Tilemaps/SurgroundWalls")
    if _wallsLayer == null:
        printerr("Player: SurgroundWalls layer not found! Pathfinding disabled.")
        return

    _astar = AStarGrid2D.new()
    var usedRect = _wallsLayer.get_used_rect()

    usedRect.position -= Vector2i(2, 2)
    usedRect.size += Vector2i(4, 4)

    _astar.region = usedRect
    _astar.cell_size = _wallsLayer.tile_set.tile_size
    _astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
    _astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
    _astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER

    _astar.update()

    for cell in _wallsLayer.get_used_cells():
        _astar.set_point_solid(cell, true)

func _physics_process(delta: float) -> void:
    if is_talking:
        velocity = Vector2.ZERO
        PlayIdleAnimation()
        move_and_slide()
        return

    if _attackCooldownTimer > 0.0:
        _attackCooldownTimer -= delta

    if IsBossActive:
        BossTimer -= delta
        if BossTimer <= 0.0:
            BossTimer = 0.0
            IsBossActive = false
            WaveCount = max(1, WaveCount - 1)
            KillsOnCurrentWave = 0
            GameAudio.Play(GameAudio.BOSS_FAILED)
            
            if get_node_or_null("/root/BridgeManager") != null:
                get_node("/root/BridgeManager").ShowInterstitial()

            var escapeMessagePosition = global_position + Vector2(0, -20)
            var escapedBossName = "Босс"
            var activeEnemies = get_tree().get_nodes_in_group("enemies")
            for node in activeEnemies:
                if node is EnemyBase and node.IsBoss and is_instance_valid(node):
                    escapeMessagePosition = node.global_position + Vector2(0, -20)
                    escapedBossName = node.name
                    node.queue_free()
                    break

            print("Boss ", escapedBossName, " escaped. Returning to Wave ", WaveCount, ".")
            FloatingTextHelper.spawn(get_parent(), escapeMessagePosition, GameLocalization.Format("BOSS_ESCAPED_WAVE", {"wave": WaveCount}), Color.RED, 12, 1.5)
            SaveSettings()

    # Decrement boost timers
    if WrathPotionTimer > 0.0:
        WrathPotionTimer = maxf(0.0, WrathPotionTimer - delta)
    if HasteScrollTimer > 0.0:
        HasteScrollTimer = maxf(0.0, HasteScrollTimer - delta)
    if SpeedPotionTimer > 0.0:
        SpeedPotionTimer = maxf(0.0, SpeedPotionTimer - delta)
    if CritPotionTimer > 0.0:
        CritPotionTimer = maxf(0.0, CritPotionTimer - delta)
    if CritDamageScrollTimer > 0.0:
        CritDamageScrollTimer = maxf(0.0, CritDamageScrollTimer - delta)

    # Decrement ad boost timers
    var hadActiveAdBoost = (AdGoldBoostTimer > 0.0 or AdDamageBoostTimer > 0.0 or AdSwiftnessBoostTimer > 0.0 or AdLuckBoostTimer > 0.0)
    if AdGoldBoostTimer > 0.0:
        AdGoldBoostTimer = maxf(0.0, AdGoldBoostTimer - delta)
    if AdDamageBoostTimer > 0.0:
        AdDamageBoostTimer = maxf(0.0, AdDamageBoostTimer - delta)
    if AdSwiftnessBoostTimer > 0.0:
        AdSwiftnessBoostTimer = maxf(0.0, AdSwiftnessBoostTimer - delta)
    if AdLuckBoostTimer > 0.0:
        AdLuckBoostTimer = maxf(0.0, AdLuckBoostTimer - delta)
    var hasActiveAdBoost = (AdGoldBoostTimer > 0.0 or AdDamageBoostTimer > 0.0 or AdSwiftnessBoostTimer > 0.0 or AdLuckBoostTimer > 0.0)
    if hadActiveAdBoost and not hasActiveAdBoost:
        ad_boosts_updated.emit()

    # Camera shake logic
    if _camera != null and _shakeTimer > 0.0:
        _shakeTimer -= delta
        if _shakeTimer <= 0.0:
            _camera.offset = Vector2.ZERO
        else:
            _camera.offset = Vector2(
                randf_range(-_shakeIntensity, _shakeIntensity),
                randf_range(-_shakeIntensity, _shakeIntensity)
            )

    # Target management
    if _target == null or not is_instance_valid(_target) or _target.get("CurrentState") == EnemyBase.EnemyState.Dead or _target.get("CurrentState") == 3:
        _target = FindNearestEnemy()
        _currentPath = []

    # Combat handling
    if _target != null and is_instance_valid(_target):
        var distance = global_position.distance_to(_target.global_position)

        if not is_attacking:
            facing_right = _target.global_position.x > global_position.x

        if distance <= AttackRange:
            velocity = Vector2.ZERO
            if not is_attacking and _attackCooldownTimer <= 0.0:
                StartAttack()
        elif not is_attacking:
            _pathfindTimer += delta
            if _pathfindTimer >= PathfindInterval:
                _pathfindTimer = 0.0
                RecalculatePathToTarget()

            var direction = GetMovementDirection()
            var currentSpeed = Speed
            if SpeedPotionTimer > 0.0:
                currentSpeed *= 1.30
            if AdSwiftnessBoostTimer > 0.0:
                currentSpeed *= 1.35
            velocity = direction * currentSpeed
    else:
        velocity = Vector2.ZERO

    # Animation handling
    if is_attacking:
        pass
    elif velocity != Vector2.ZERO:
        if facing_right:
            _sprite.play("walk_right")
        else:
            _sprite.play("walk_left")
    else:
        PlayIdleAnimation()

    move_and_slide()

func PlayIdleAnimation() -> void:
    if facing_right:
        _sprite.play("idle_right")
    else:
        _sprite.play("idle_left")

func FindNearestEnemy() -> CharacterBody2D:
    var enemies = get_tree().get_nodes_in_group("enemies")
    var nearest: CharacterBody2D = null
    var minDistance = INF

    for node in enemies:
        if node is CharacterBody2D and is_instance_valid(node):
            var state = node.get("CurrentState")
            if state == EnemyBase.EnemyState.Dead or state == 3:
                continue

            var dist = global_position.distance_to(node.global_position)
            if dist < minDistance:
                minDistance = dist
                nearest = node
    return nearest

func RecalculatePathToTarget() -> void:
    if _astar == null or _wallsLayer == null or _target == null:
        return

    var playerCell = _wallsLayer.local_to_map(global_position)
    var targetCell = _wallsLayer.local_to_map(_target.global_position)

    if _astar.is_point_solid(targetCell):
        var neighbors = [
            targetCell + Vector2i.LEFT,
            targetCell + Vector2i.RIGHT,
            targetCell + Vector2i.UP,
            targetCell + Vector2i.DOWN
        ]
        for n in neighbors:
            if _astar.region.has_point(n) and not _astar.is_point_solid(n):
                targetCell = n
                break

    if _astar.region.has_point(playerCell) and _astar.region.has_point(targetCell):
        var idPath = _astar.get_id_path(playerCell, targetCell)
        _currentPath.clear()
        for cell in idPath:
            _currentPath.append(_wallsLayer.map_to_local(cell))
        _currentPathIndex = 0

func GetMovementDirection() -> Vector2:
    if _currentPath.size() > 0 and _currentPathIndex < _currentPath.size():
        var nextPoint = _currentPath[_currentPathIndex]

        var hasReached = false
        if _wallsLayer != null:
            hasReached = _wallsLayer.local_to_map(global_position) == _wallsLayer.local_to_map(nextPoint)
        if not hasReached:
            hasReached = global_position.distance_to(nextPoint) < 4.0

        if hasReached:
            _currentPathIndex += 1
            if _currentPathIndex < _currentPath.size():
                nextPoint = _currentPath[_currentPathIndex]
            else:
                return (_target.global_position - global_position).normalized()

        var direction = (nextPoint - global_position).normalized()

        var alignment = Vector2.ZERO
        if abs(direction.y) > abs(direction.x):
            var diffX = nextPoint.x - global_position.x
            if abs(diffX) > 1.0:
                alignment.x = sign(diffX) * 0.5
        else:
            var diffY = nextPoint.y - global_position.y
            if abs(diffY) > 1.0:
                alignment.y = sign(diffY) * 0.5

        return (direction + alignment).normalized()

    return (_target.global_position - global_position).normalized()

func StartAttack() -> void:
    is_attacking = true
    GameAudio.Play(GameAudio.ATTACK, 0.06)
    var speedBonus = AmuletAttackSpeedBonus + CrystalUpgradeLevel * (0.06 if CrystalSynergySkillLevel > 0 else 0.05)
    if AdSwiftnessBoostTimer > 0.0:
        speedBonus += 0.35
    _attackCooldownTimer = AttackCooldown / (1.0 + speedBonus)

    if facing_right:
        _sprite.play("attack_right")
    else:
        _sprite.play("attack_left")

func OnAnimationFinished() -> void:
    if _sprite.animation == "attack_right" or _sprite.animation == "attack_left":
        is_attacking = false

        if _target != null and is_instance_valid(_target):
            var distance = global_position.distance_to(_target.global_position)
            if distance <= AttackRange + 8.0:
                var res = GetTotalDamage()
                var damageDealt = res.get("damage", 0)
                var isCrit = res.get("is_crit", false)

                if isCrit:
                    ShakeCamera(0.2, 4.0)

                if _target.has_method("TakeDamage"):
                    _target.TakeDamage(damageDealt, isCrit)
                else:
                    _target.call("TakeDamage", damageDealt, isCrit)

func TakeDamage(_amount: int) -> void:
    # Player is invulnerable and takes no damage
    pass

func ShakeCamera(duration: float, intensity: float) -> void:
    _shakeTimer = duration
    _shakeIntensity = intensity

func AddToInventory(item: ItemData) -> bool:
    if item == null:
        return false

    if item.Type == ItemData.ItemType.Material:
        for i in range(Inventory.size()):
            var invItem = Inventory[i]
            if invItem != null and invItem.Id == item.Id and invItem.StackCount < invItem.MaxStack:
                var spaceLeft = invItem.MaxStack - invItem.StackCount
                var amountToAdd = min(spaceLeft, item.StackCount)
                invItem.StackCount += amountToAdd
                item.StackCount -= amountToAdd

                if item.StackCount <= 0:
                    inventory_updated.emit()
                    return true

    for i in range(Inventory.size()):
        if Inventory[i] == null:
            Inventory[i] = item
            inventory_updated.emit()
            return true

    return false

func EquipItem(invIndex: int) -> void:
    if invIndex < 0 or invIndex >= Inventory.size():
        return

    var item = Inventory[invIndex]
    if item == null:
        return

    var targetSlot = -1

    if item.Type == ItemData.ItemType.Stone:
        targetSlot = 0
    elif item.Type == ItemData.ItemType.Staff:
        targetSlot = 1
    elif item.Type == ItemData.ItemType.Amulet:
        if EquippedItems[2] == null:
            targetSlot = 2
        elif EquippedItems[3] == null:
            targetSlot = 3
        else:
            targetSlot = 2

    if targetSlot != -1:
        var previouslyEquipped = EquippedItems[targetSlot]
        EquippedItems[targetSlot] = item
        Inventory[invIndex] = previouslyEquipped
        inventory_updated.emit()

func UnequipItem(slotIndex: int) -> void:
    if slotIndex < 0 or slotIndex >= 4:
        return

    var item = EquippedItems[slotIndex]
    if item == null:
        return

    for i in range(Inventory.size()):
        if Inventory[i] == null:
            EquippedItems[slotIndex] = null
            Inventory[i] = item
            inventory_updated.emit()
            return

func SellItem(invIndex: int) -> void:
    if invIndex < 0 or invIndex >= Inventory.size():
        return

    var item = Inventory[invIndex]
    if item == null:
        return

    var payout = item.SellValue * item.StackCount

    Gold += payout
    Inventory[invIndex] = null
    inventory_updated.emit()

func DestroyItem(invIndex: int) -> void:
    if invIndex < 0 or invIndex >= Inventory.size():
        return
    Inventory[invIndex] = null
    inventory_updated.emit()

func SwapInventoryItems(indexA: int, indexB: int) -> void:
    if indexA < 0 or indexA >= Inventory.size() or indexB < 0 or indexB >= Inventory.size():
        return
    var temp = Inventory[indexA]
    Inventory[indexA] = Inventory[indexB]
    Inventory[indexB] = temp
    inventory_updated.emit()

func UseConsumable(index: int) -> void:
    if index < 0 or index >= Inventory.size():
        return
    var item = Inventory[index]
    if item == null or item.Type != ItemData.ItemType.Consumable:
        return

    var success = false
    if item.Id == "cons_minor_heal":
        CritPotionTimer = 30.0
        FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -20), tr("+15% крита!"), Color.ORANGE, 8, 1.0)
        success = true
    elif item.Id == "cons_speed_potion":
        SpeedPotionTimer = 30.0
        FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -20), tr("Ускорение!"), Color.LIGHT_GREEN, 8, 1.0)
        success = true
    elif item.Id == "cons_wrath_elixir":
        WrathPotionTimer = 60.0
        FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -20), tr("Ярость!"), Color.RED, 8, 1.0)
        success = true
    elif item.Id == "cons_lucky_elixir":
        LuckyElixirEnemiesCount = 10
        FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -20), tr("Удача!"), Color.GOLD, 8, 1.0)
        success = true
    elif item.Id == "cons_haste_scroll":
        HasteScrollTimer = 300.0
        FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -20), tr("Ускорение призыва!"), Color.CYAN, 8, 1.0)
        success = true
    elif item.Id == "cons_protection_scroll":
        CritDamageScrollTimer = 60.0
        FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -20), tr("+50% силы крита!"), Color.PURPLE, 8, 1.0)
        success = true
    elif item.Id == "cons_teleport_scroll":
        FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -20), tr("Телепортация!"), Color.MEDIUM_PURPLE, 8, 1.0)
        success = true

    if success:
        item.StackCount -= 1
        if item.StackCount <= 0:
            Inventory[index] = null
        inventory_updated.emit()
