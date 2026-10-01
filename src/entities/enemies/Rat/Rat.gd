class_name Rat
extends EnemyBase

func _ready() -> void:
	MaxHealth = 6
	Defense = 0
	GoldMin = 1
	GoldMax = 2
	ExperienceDrop = 6
	PatrolSpeed = 50.0
	super._ready()

func _get_loot_drops(luck_multiplier: float) -> Dictionary:
	var droppedMaterials: Array[ItemData] = []
	var rolledEquipment: Array[ItemData] = []
	var droppedConsumables: Array[ItemData] = []

	if randf() < 0.85:
		droppedMaterials.append(ItemDatabase.get_item("mat_rat_tail", randi_range(1, 3)))
	if randf() < 0.35:
		droppedMaterials.append(ItemDatabase.get_item("mat_rat_fang", randi_range(1, 3)))

	if randf() < 0.05 * luck_multiplier:
		rolledEquipment.append(ItemDatabase.get_item("equip_rat_luck"))
	if randf() < 0.03 * luck_multiplier:
		rolledEquipment.append(ItemDatabase.get_item("equip_small_staff"))

	if randf() < 0.12:
		droppedConsumables.append(ItemDatabase.get_item("cons_speed_potion"))

	return {
		"materials": droppedMaterials,
		"equipment": rolledEquipment,
		"consumables": droppedConsumables
	}
