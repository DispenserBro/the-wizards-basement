class_name Slime
extends EnemyBase

func _ready() -> void:
	MaxHealth = 12
	Defense = 0
	GoldMin = 2
	GoldMax = 4
	ExperienceDrop = 10
	PatrolSpeed = 35.0 # Slimes are slower
	super._ready()

func _get_loot_drops(luck_multiplier: float) -> Dictionary:
	var droppedMaterials: Array[ItemData] = []
	var rolledEquipment: Array[ItemData] = []
	var droppedConsumables: Array[ItemData] = []

	if randf() < 0.90:
		droppedMaterials.append(ItemDatabase.get_item("mat_slime", randi_range(1, 3)))
	if randf() < 0.30:
		droppedMaterials.append(ItemDatabase.get_item("mat_mana_clump", randi_range(1, 3)))

	if randf() < 0.04 * luck_multiplier:
		rolledEquipment.append(ItemDatabase.get_item("equip_swamp_staff"))
	if randf() < 0.03 * luck_multiplier:
		rolledEquipment.append(ItemDatabase.get_item("equip_amulet_endurance"))

	if randf() < 0.08:
		droppedConsumables.append(ItemDatabase.get_item("cons_protection_scroll"))

	return {
		"materials": droppedMaterials,
		"equipment": rolledEquipment,
		"consumables": droppedConsumables
	}
