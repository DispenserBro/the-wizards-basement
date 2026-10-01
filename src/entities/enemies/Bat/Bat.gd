class_name Bat
extends EnemyBase

func _ready() -> void:
	MaxHealth = 8
	Defense = 1
	GoldMin = 1
	GoldMax = 3
	ExperienceDrop = 8
	PatrolSpeed = 60.0 # Bats are a bit faster
	super._ready()

func _get_loot_drops(luck_multiplier: float) -> Dictionary:
	var droppedMaterials: Array[ItemData] = []
	var rolledEquipment: Array[ItemData] = []
	var droppedConsumables: Array[ItemData] = []

	if randf() < 0.80:
		droppedMaterials.append(ItemDatabase.get_item("mat_bat_claw", randi_range(1, 3)))
	if randf() < 0.40:
		droppedMaterials.append(ItemDatabase.get_item("mat_wing", randi_range(1, 3)))

	if randf() < 0.05 * luck_multiplier:
		rolledEquipment.append(ItemDatabase.get_item("equip_small_stone"))
	if randf() < 0.02 * luck_multiplier:
		rolledEquipment.append(ItemDatabase.get_item("equip_ring_night"))

	if randf() < 0.10:
		droppedConsumables.append(ItemDatabase.get_item("cons_minor_heal"))

	return {
		"materials": droppedMaterials,
		"equipment": rolledEquipment,
		"consumables": droppedConsumables
	}
