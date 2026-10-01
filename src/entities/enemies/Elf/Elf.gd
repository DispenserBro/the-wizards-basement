class_name Elf
extends EnemyBase

func _ready() -> void:
	MaxHealth = 15
	Defense = 2
	GoldMin = 3
	GoldMax = 6
	ExperienceDrop = 15
	PatrolSpeed = 45.0
	super._ready()

func PlayDeathAnimation() -> void:
	if Sprite == null:
		queue_free()
		return

	# Elf uses alternative centered death animation on row 9
	Sprite.play("death")

func _get_loot_drops(luck_multiplier: float) -> Dictionary:
	var droppedMaterials: Array[ItemData] = []
	var rolledEquipment: Array[ItemData] = []
	var droppedConsumables: Array[ItemData] = []

	if randf() < 0.70:
		droppedMaterials.append(ItemDatabase.get_item("mat_elf_dust", randi_range(1, 3)))
	if randf() < 0.25:
		droppedMaterials.append(ItemDatabase.get_item("mat_ancient_parchment", randi_range(1, 3)))

	if randf() < 0.08 * luck_multiplier:
		rolledEquipment.append(ItemDatabase.get_item("equip_moonlight_staff"))
	if randf() < 0.06 * luck_multiplier:
		rolledEquipment.append(ItemDatabase.get_item("equip_elf_wisdom"))
	if randf() < 0.02 * luck_multiplier:
		rolledEquipment.append(ItemDatabase.get_item("equip_royal_blood"))

	if randf() < 0.15:
		droppedConsumables.append(ItemDatabase.get_item("cons_wrath_elixir"))
	if randf() < 0.05:
		droppedConsumables.append(ItemDatabase.get_item("cons_teleport_scroll"))

	return {
		"materials": droppedMaterials,
		"equipment": rolledEquipment,
		"consumables": droppedConsumables
	}
