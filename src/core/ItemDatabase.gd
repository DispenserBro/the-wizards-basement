class_name ItemDatabase
extends Object

static var PredefinedEpicsAndLegendaries: Array[ItemData] = []
static var PredefinedMaterials: Array[ItemData] = []
static var PredefinedConsumables: Array[ItemData] = []
static var PredefinedEquipment: Array[ItemData] = []

static var _is_initialized: bool = false

static func init_db() -> void:
	if _is_initialized:
		return
	_is_initialized = true

	# --- Epics and Legendaries ---
	var item: ItemData

	item = ItemData.new()
	item.Id = "epic_staff_storm"
	item.Name = "Посох Бури"
	item.Description = "Напитан яростью грозовых туч."
	item.Type = ItemData.ItemType.Staff
	item.Rarity = ItemData.ItemRarity.Epic
	item.BaseDamage = 7
	item.AttackSpeedBonus = 0.15
	item.SellValue = 100
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-magic-staff-2d.png"
	PredefinedEpicsAndLegendaries.append(item)

	item = ItemData.new()
	item.Id = "epic_stone_eye"
	item.Name = "Око Дракона"
	item.Description = "Драконий зрачок, застывший в камне."
	item.Type = ItemData.ItemType.Stone
	item.Rarity = ItemData.ItemRarity.Epic
	item.ManaBonus = 25
	item.BaseDamage = 4
	item.SellValue = 100
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-gem-diamond-2d.png"
	PredefinedEpicsAndLegendaries.append(item)

	item = ItemData.new()
	item.Id = "epic_amulet_phoenix"
	item.Name = "Амулет Феникса"
	item.Description = "Дарует владельцу тепло, ускоряя призыв и атаки (+15% к скорости, +5% к криту)."
	item.Type = ItemData.ItemType.Amulet
	item.Rarity = ItemData.ItemRarity.Epic
	item.AttackSpeedBonus = 0.15
	item.CritChanceBonus = 0.05
	item.SellValue = 100
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-ring-2d.png"
	PredefinedEpicsAndLegendaries.append(item)

	item = ItemData.new()
	item.Id = "legendary_staff_archmage"
	item.Name = "Посох Архимага"
	item.Description = "Легендарное оружие величайших магов древности."
	item.Type = ItemData.ItemType.Staff
	item.Rarity = ItemData.ItemRarity.Legendary
	item.BaseDamage = 15
	item.AttackSpeedBonus = 0.25
	item.SellValue = 300
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-magic-staff-2d.png"
	PredefinedEpicsAndLegendaries.append(item)

	item = ItemData.new()
	item.Id = "legendary_stone_void"
	item.Name = "Сердце Бездны"
	item.Description = "Пульсирующий кристалл из глубин космоса."
	item.Type = ItemData.ItemType.Stone
	item.Rarity = ItemData.ItemRarity.Legendary
	item.ManaBonus = 60
	item.BaseDamage = 9
	item.SellValue = 300
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-gem-diamond-2d.png"
	PredefinedEpicsAndLegendaries.append(item)

	item = ItemData.new()
	item.Id = "legendary_amulet_star"
	item.Name = "Звезда надежды"
	item.Description = "Осколок упавшей звезды. Значительно повышает скорость (+20% к скорости) и критический шанс (+15% к шансу крита)."
	item.Type = ItemData.ItemType.Amulet
	item.Rarity = ItemData.ItemRarity.Legendary
	item.AttackSpeedBonus = 0.20
	item.CritChanceBonus = 0.15
	item.SellValue = 300
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-ring-2d.png"
	PredefinedEpicsAndLegendaries.append(item)

	# --- Materials ---
	item = ItemData.new()
	item.Id = "mat_slime"
	item.Name = "Слизь"
	item.Description = "Вязкая субстанция слизня. Используется в алхимии."
	item.Type = ItemData.ItemType.Material
	item.Rarity = ItemData.ItemRarity.Common
	item.MaxStack = 99
	item.SellValue = 2
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-mushroom-2d.png"
	PredefinedMaterials.append(item)

	item = ItemData.new()
	item.Id = "mat_fur"
	item.Name = "Шкура крысы"
	item.Description = "Грубая шерсть серой крысы."
	item.Type = ItemData.ItemType.Material
	item.Rarity = ItemData.ItemRarity.Common
	item.MaxStack = 99
	item.SellValue = 2
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-backpack-2d.png"
	PredefinedMaterials.append(item)

	item = ItemData.new()
	item.Id = "mat_wing"
	item.Name = "Крыло летучей мыши"
	item.Description = "Тонкое кожаное крыло летучей мыши."
	item.Type = ItemData.ItemType.Material
	item.Rarity = ItemData.ItemRarity.Common
	item.MaxStack = 99
	item.SellValue = 3
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-skull-2d.png"
	PredefinedMaterials.append(item)

	item = ItemData.new()
	item.Id = "mat_pollen"
	item.Name = "Пыльца эльфов"
	item.Description = "Мерцающий порошок с одежды лесного эльфа."
	item.Type = ItemData.ItemType.Material
	item.Rarity = ItemData.ItemRarity.Rare
	item.MaxStack = 99
	item.SellValue = 8
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-potion-2d.png"
	PredefinedMaterials.append(item)

	item = ItemData.new()
	item.Id = "mat_bat_claw"
	item.Name = "Коготь летучей мыши"
	item.Description = "Маленький острый коготь."
	item.Type = ItemData.ItemType.Material
	item.Rarity = ItemData.ItemRarity.Common
	item.MaxStack = 99
	item.SellValue = 3
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-skull-2d.png"
	PredefinedMaterials.append(item)

	item = ItemData.new()
	item.Id = "mat_mana_clump"
	item.Name = "Сгусток маны"
	item.Description = "Концентрированная чистая магическая энергия."
	item.Type = ItemData.ItemType.Material
	item.Rarity = ItemData.ItemRarity.Uncommon
	item.MaxStack = 99
	item.SellValue = 6
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-potion-2d.png"
	PredefinedMaterials.append(item)

	item = ItemData.new()
	item.Id = "mat_rat_tail"
	item.Name = "Хвост крысы"
	item.Description = "Длинный тонкий крысиный хвост."
	item.Type = ItemData.ItemType.Material
	item.Rarity = ItemData.ItemRarity.Common
	item.MaxStack = 99
	item.SellValue = 2
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-backpack-2d.png"
	PredefinedMaterials.append(item)

	item = ItemData.new()
	item.Id = "mat_rat_fang"
	item.Name = "Клык крысы"
	item.Description = "Острый зуб грызуна."
	item.Type = ItemData.ItemType.Material
	item.Rarity = ItemData.ItemRarity.Common
	item.MaxStack = 99
	item.SellValue = 3
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-skull-2d.png"
	PredefinedMaterials.append(item)

	item = ItemData.new()
	item.Id = "mat_elf_dust"
	item.Name = "Эльфийская пыль"
	item.Description = "Волшебный светящийся порошок."
	item.Type = ItemData.ItemType.Material
	item.Rarity = ItemData.ItemRarity.Uncommon
	item.MaxStack = 99
	item.SellValue = 8
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-potion-2d.png"
	PredefinedMaterials.append(item)

	item = ItemData.new()
	item.Id = "mat_ancient_parchment"
	item.Name = "Древний пергамент"
	item.Description = "Ветхий свиток с остатками древних рун."
	item.Type = ItemData.ItemType.Material
	item.Rarity = ItemData.ItemRarity.Rare
	item.MaxStack = 99
	item.SellValue = 15
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-backpack-2d.png"
	PredefinedMaterials.append(item)

	# --- Consumables ---
	item = ItemData.new()
	item.Id = "cons_minor_heal"
	item.Name = "Эликсир крита"
	item.Description = "Дарует +15% к шансу крита на 30 секунд при использовании."
	item.Type = ItemData.ItemType.Consumable
	item.Rarity = ItemData.ItemRarity.Common
	item.MaxStack = 99
	item.SellValue = 5
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-potion-2d.png"
	PredefinedConsumables.append(item)

	item = ItemData.new()
	item.Id = "cons_protection_scroll"
	item.Name = "Свиток крит. силы"
	item.Description = "Дарует +50% к критическому урону на 60 секунд."
	item.Type = ItemData.ItemType.Consumable
	item.Rarity = ItemData.ItemRarity.Common
	item.MaxStack = 99
	item.SellValue = 8
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-backpack-2d.png"
	PredefinedConsumables.append(item)

	item = ItemData.new()
	item.Id = "cons_speed_potion"
	item.Name = "Зелье скорости"
	item.Description = "Временно ускоряет передвижение на 30%."
	item.Type = ItemData.ItemType.Consumable
	item.Rarity = ItemData.ItemRarity.Uncommon
	item.MaxStack = 99
	item.SellValue = 10
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-potion-2d.png"
	PredefinedConsumables.append(item)

	item = ItemData.new()
	item.Id = "cons_wrath_elixir"
	item.Name = "Эликсир ярости"
	item.Description = "Временно повышает урон и скорость атаки."
	item.Type = ItemData.ItemType.Consumable
	item.Rarity = ItemData.ItemRarity.Rare
	item.MaxStack = 99
	item.SellValue = 20
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-potion-2d.png"
	PredefinedConsumables.append(item)

	item = ItemData.new()
	item.Id = "cons_teleport_scroll"
	item.Name = "Свиток телепортации"
	item.Description = "Переносит в безопасное место."
	item.Type = ItemData.ItemType.Consumable
	item.Rarity = ItemData.ItemRarity.Rare
	item.MaxStack = 99
	item.SellValue = 15
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-backpack-2d.png"
	PredefinedConsumables.append(item)

	item = ItemData.new()
	item.Id = "cons_lucky_elixir"
	item.Name = "Эликсир удачи"
	item.Description = "Дарует +25% к шансу выпадения редкого лута на 10 врагов при использовании."
	item.Type = ItemData.ItemType.Consumable
	item.Rarity = ItemData.ItemRarity.Rare
	item.MaxStack = 99
	item.SellValue = 15
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-potion-2d.png"
	PredefinedConsumables.append(item)

	item = ItemData.new()
	item.Id = "cons_haste_scroll"
	item.Name = "Свиток ускорения"
	item.Description = "Сокращает время перезарядки призыва на 50% на 5 минут при использовании."
	item.Type = ItemData.ItemType.Consumable
	item.Rarity = ItemData.ItemRarity.Rare
	item.MaxStack = 99
	item.SellValue = 20
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-backpack-2d.png"
	PredefinedConsumables.append(item)

	# --- Equipment ---
	item = ItemData.new()
	item.Id = "equip_small_stone"
	item.Name = "Малый магический камень"
	item.Description = "Небольшой кристалл, слабо светящийся энергией."
	item.Type = ItemData.ItemType.Stone
	item.Rarity = ItemData.ItemRarity.Common
	item.ManaBonus = 5
	item.BaseDamage = 1
	item.SellValue = 4
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-gem-diamond-2d.png"
	PredefinedEquipment.append(item)

	item = ItemData.new()
	item.Id = "equip_ring_night"
	item.Name = "Кольцо ночи"
	item.Description = "Необычное кольцо, ускоряющее движения во тьме."
	item.Type = ItemData.ItemType.Amulet
	item.Rarity = ItemData.ItemRarity.Uncommon
	item.AttackSpeedBonus = 0.08
	item.SellValue = 12
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-ring-2d.png"
	PredefinedEquipment.append(item)

	item = ItemData.new()
	item.Id = "equip_swamp_staff"
	item.Name = "Посох болотной трясины"
	item.Description = "Тяжелый посох из болотной древесины. Увеличивает урон, но снижает скорость атаки."
	item.Type = ItemData.ItemType.Staff
	item.Rarity = ItemData.ItemRarity.Uncommon
	item.BaseDamage = 5
	item.AttackSpeedBonus = -0.05
	item.SellValue = 14
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-magic-staff-2d.png"
	PredefinedEquipment.append(item)

	item = ItemData.new()
	item.Id = "equip_amulet_endurance"
	item.Name = "Амулет выносливости"
	item.Description = "Увеличивает базовый урон (+1) и общую скорость атак (+5%)."
	item.Type = ItemData.ItemType.Amulet
	item.Rarity = ItemData.ItemRarity.Rare
	item.BaseDamage = 1
	item.AttackSpeedBonus = 0.05
	item.SellValue = 35
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-ring-2d.png"
	PredefinedEquipment.append(item)

	item = ItemData.new()
	item.Id = "equip_rat_luck"
	item.Name = "Амулет крысиной удачи"
	item.Description = "Необычный амулет. Привлекает блестящие монеты (+25% золота с врагов)."
	item.Type = ItemData.ItemType.Amulet
	item.Rarity = ItemData.ItemRarity.Uncommon
	item.SellValue = 15
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-ring-2d.png"
	PredefinedEquipment.append(item)

	item = ItemData.new()
	item.Id = "equip_small_staff"
	item.Name = "Малый посох"
	item.Description = "Простой посох для концентрации магии."
	item.Type = ItemData.ItemType.Staff
	item.Rarity = ItemData.ItemRarity.Common
	item.BaseDamage = 2
	item.SellValue = 4
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-magic-staff-2d.png"
	PredefinedEquipment.append(item)

	item = ItemData.new()
	item.Id = "equip_moonlight_staff"
	item.Name = "Посох лунного света"
	item.Description = "Редкий посох, благословленный светом луны. Значительно повышает шанс критического удара (+10%)."
	item.Type = ItemData.ItemType.Staff
	item.Rarity = ItemData.ItemRarity.Rare
	item.BaseDamage = 4
	item.CritChanceBonus = 0.10
	item.SellValue = 45
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-magic-staff-2d.png"
	PredefinedEquipment.append(item)

	item = ItemData.new()
	item.Id = "equip_elf_wisdom"
	item.Name = "Камень эльфийской мудрости"
	item.Description = "Эпический кристалл, дарующий мудрость древних (+30% опыта с врагов)."
	item.Type = ItemData.ItemType.Stone
	item.Rarity = ItemData.ItemRarity.Epic
	item.ManaBonus = 15
	item.SellValue = 90
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-gem-diamond-2d.png"
	PredefinedEquipment.append(item)

	item = ItemData.new()
	item.Id = "equip_royal_blood"
	item.Name = "Амулет королевской крови"
	item.Description = "Легендарное украшение, значительно повышающее скорость (+12% к скорости) и критический шанс (+8% к шансу крита)."
	item.Type = ItemData.ItemType.Amulet
	item.Rarity = ItemData.ItemRarity.Legendary
	item.AttackSpeedBonus = 0.12
	item.CritChanceBonus = 0.08
	item.SellValue = 250
	item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-ring-2d.png"
	PredefinedEquipment.append(item)

static func get_item(id: String, count: int = 1) -> ItemData:
	init_db()
	for i in PredefinedMaterials:
		if i.Id == id:
			var clone = i.duplicate_item()
			clone.StackCount = count
			return clone
	for i in PredefinedConsumables:
		if i.Id == id:
			var clone = i.duplicate_item()
			clone.StackCount = count
			return clone
	for i in PredefinedEquipment:
		if i.Id == id:
			var clone = i.duplicate_item()
			clone.StackCount = count
			return clone
	for i in PredefinedEpicsAndLegendaries:
		if i.Id == id:
			var clone = i.duplicate_item()
			clone.StackCount = count
			return clone
	return null

static func get_material(id: String, count: int = 1) -> ItemData:
	return get_item(id, count)

static func get_random_item(epic_chance: float = 0.10, legendary_chance: float = 0.03) -> ItemData:
	init_db()
	var roll = randf()

	if roll < legendary_chance:
		var legendaries: Array[ItemData] = []
		for i in PredefinedEpicsAndLegendaries:
			if i.Rarity == ItemData.ItemRarity.Legendary:
				legendaries.append(i)
		return legendaries[randi() % legendaries.size()].duplicate_item()
	elif roll < legendary_chance + epic_chance:
		var epics: Array[ItemData] = []
		for i in PredefinedEpicsAndLegendaries:
			if i.Rarity == ItemData.ItemRarity.Epic:
				epics.append(i)
		return epics[randi() % epics.size()].duplicate_item()
	else:
		var random_type = randi() % 3 as ItemData.ItemType # Staff, Stone, Amulet
		var rarity = ItemData.ItemRarity.Common

		var rarity_roll = randf()
		if rarity_roll < 0.15:
			rarity = ItemData.ItemRarity.Rare
		elif rarity_roll < 0.45:
			rarity = ItemData.ItemRarity.Uncommon

		return generate_procedural_item(random_type, rarity)

static func generate_procedural_item(type: ItemData.ItemType, rarity: ItemData.ItemRarity) -> ItemData:
	var stat_multiplier: float = 1.0
	if rarity == ItemData.ItemRarity.Uncommon:
		stat_multiplier = 1.5
	elif rarity == ItemData.ItemRarity.Rare:
		stat_multiplier = 2.2

	var rarity_prefix: String = "Простой"
	if rarity == ItemData.ItemRarity.Uncommon:
		rarity_prefix = "Необычный"
	elif rarity == ItemData.ItemRarity.Rare:
		rarity_prefix = "Редкий"

	var item = ItemData.new()
	item.Rarity = rarity
	item.Type = type
	item.MaxStack = 1
	item.StackCount = 1

	match type:
		ItemData.ItemType.Staff:
			item.Id = "proc_staff_" + str(rarity).to_lower()
			item.Name = rarity_prefix + " Посох"
			item.Description = "Посох, концентрирующий магический урон мага."
			item.BaseDamage = roundi(3.0 * stat_multiplier)
			item.AttackSpeedBonus = 0.05 * stat_multiplier
			if rarity == ItemData.ItemRarity.Uncommon:
				item.SellValue = 15
			elif rarity == ItemData.ItemRarity.Rare:
				item.SellValue = 40
			else:
				item.SellValue = 5
			item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-magic-staff-2d.png"

		ItemData.ItemType.Stone:
			item.Id = "proc_stone_" + str(rarity).to_lower()
			item.Name = rarity_prefix + " Магический камень"
			item.Description = "Повышает запас маны и магический потенциал."
			item.ManaBonus = roundi(10.0 * stat_multiplier)
			item.BaseDamage = roundi(1.0 * stat_multiplier)
			if rarity == ItemData.ItemRarity.Uncommon:
				item.SellValue = 15
			elif rarity == ItemData.ItemRarity.Rare:
				item.SellValue = 40
			else:
				item.SellValue = 5
			item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-gem-diamond-2d.png"

		ItemData.ItemType.Amulet:
			item.Id = "proc_amulet_" + str(rarity).to_lower()
			item.Name = rarity_prefix + " Амулет"
			item.Description = "Наделяет владельца пассивной защитной аурой."
			item.RegenBonus = 0.2 * stat_multiplier
			item.CritChanceBonus = 0.02 * stat_multiplier
			if rarity == ItemData.ItemRarity.Uncommon:
				item.SellValue = 15
			elif rarity == ItemData.ItemRarity.Rare:
				item.SellValue = 40
			else:
				item.SellValue = 5
			item.IconTexturePath = "res://external/icodot-png-v1.0/icodot-png/2d/fantasy/icon-ring-2d.png"

	return item

static func get_all_predefined_equipment() -> Array[ItemData]:
	init_db()
	var list: Array[ItemData] = []
	for i in PredefinedEquipment:
		list.append(i.duplicate_item())
	for i in PredefinedEpicsAndLegendaries:
		list.append(i.duplicate_item())
	return list

static func get_buy_price(item: ItemData) -> int:
	if item == null:
		return 0
	if item.Type == ItemData.ItemType.Consumable:
		if item.Id == "cons_wrath_elixir":
			return 100
		if item.Id == "cons_lucky_elixir":
			return 150
		if item.Id == "cons_haste_scroll":
			return 200
		return item.SellValue * 3

	match item.Rarity:
		ItemData.ItemRarity.Common:
			return item.SellValue * 8
		ItemData.ItemRarity.Uncommon:
			return item.SellValue * 12
		ItemData.ItemRarity.Rare:
			return item.SellValue * 15
		ItemData.ItemRarity.Epic:
			return item.SellValue * 18
		ItemData.ItemRarity.Legendary:
			return item.SellValue * 20
		_:
			return item.SellValue * 5
