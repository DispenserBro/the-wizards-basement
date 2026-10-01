class_name EnemyBase
extends CharacterBody2D

signal enemy_died(gold: int, experience: int)

enum EnemyState {
	Idle,
	Patrol,
	Hurt,
	Dead
}

@export var MaxHealth: int = 10
@export var Health: int = 10
@export var Defense: int = 0
@export var GoldMin: int = 1
@export var GoldMax: int = 5
@export var ExperienceDrop: int = 10
@export var LootTable: Array[LootItem] = []
@export var PatrolSpeed: float = 50.0
@export var AttackDamage: int = 3
@export var EnemyAttackCooldown: float = 1.5
@export var IsBoss: bool = false
@export var BossCustomName: String = ""
@export var IsDarkElf: bool = false

var _enemyAttackCooldownTimer: float = 0.0

var Sprite: AnimatedSprite2D
var CollisionShape: CollisionShape2D

var CurrentState: EnemyState = EnemyState.Idle
var FacingRight: bool = true

var _patrolDirection: Vector2 = Vector2.ZERO
var _stateTimer: float = 0.0
var _stateDuration: float = 0.0

func _ready() -> void:
	Sprite = get_node_or_null("sprite")
	CollisionShape = get_node_or_null("CollisionShape2D")

	var player = get_parent().get_node_or_null("Player")
	var wave = player.WaveCount if (player != null and is_instance_valid(player)) else 1

	var difficultyMultiplier: float = 1.0 + (wave - 1) * 0.15

	if IsDarkElf:
		difficultyMultiplier *= 2.0
		GoldMin *= 2
		GoldMax *= 2
		ExperienceDrop *= 2

		modulate = Color(0.4, 0.2, 0.6)
		scale = Vector2(1.2, 1.2)
		name = "Тёмный эльф"

	MaxHealth = roundi(MaxHealth * difficultyMultiplier)
	AttackDamage = roundi(AttackDamage * difficultyMultiplier)

	if IsBoss:
		MaxHealth *= 3
		GoldMin *= 3
		GoldMax *= 3
		ExperienceDrop *= 3

		if not BossCustomName.is_empty():
			name = BossCustomName

		modulate = Color(1.2, 1.0, 0.8)
		scale = Vector2(1.5, 1.5)

	Health = MaxHealth

	if Sprite != null:
		Sprite.animation_finished.connect(OnAnimationFinished)

	TransitionToIdle()

func _physics_process(delta: float) -> void:
	if CurrentState == EnemyState.Dead:
		return

	var player = get_parent().get_node_or_null("Player")
	if player != null and is_instance_valid(player) and player.is_talking:
		velocity = Vector2.ZERO
		move_and_slide()
		PlayIdleAnimation()
		return

	if _enemyAttackCooldownTimer > 0.0:
		_enemyAttackCooldownTimer -= delta

	if CurrentState == EnemyState.Hurt:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_stateTimer += delta
	if _stateTimer >= _stateDuration:
		if CurrentState == EnemyState.Idle:
			TransitionToPatrol()
		elif CurrentState == EnemyState.Patrol:
			TransitionToIdle()

	if CurrentState == EnemyState.Patrol:
		velocity = _patrolDirection * PatrolSpeed

		if move_and_slide() and is_on_wall():
			TransitionToIdle()

		if velocity.x > 0:
			FacingRight = true
		elif velocity.x < 0:
			FacingRight = false

		PlayWalkAnimation()
	elif CurrentState == EnemyState.Idle:
		velocity = Vector2.ZERO
		move_and_slide()
		PlayIdleAnimation()

func PlayWalkAnimation() -> void:
	if Sprite == null:
		return
	if FacingRight:
		Sprite.play("walk_right")
	else:
		Sprite.play("walk_left")

func PlayIdleAnimation() -> void:
	if Sprite == null:
		return
	if FacingRight:
		Sprite.play("walk_right")
		Sprite.stop()
	else:
		Sprite.play("walk_left")
		Sprite.stop()

func TransitionToIdle() -> void:
	CurrentState = EnemyState.Idle
	_stateTimer = 0.0
	_stateDuration = randf_range(0.5, 2.0)
	velocity = Vector2.ZERO

func TransitionToPatrol() -> void:
	CurrentState = EnemyState.Patrol
	_stateTimer = 0.0
	_stateDuration = randf_range(1.0, 3.0)

	var angle = randf_range(0.0, TAU)
	_patrolDirection = Vector2(cos(angle), sin(angle)).normalized()

func TakeDamage(amount: int, isCrit: bool = false) -> void:
	if CurrentState == EnemyState.Dead:
		return

	var damage = clampi(amount - Defense, 1, 999999)
	Health -= damage
	print(name, " took ", damage, " damage! Remaining Health: ", Health)

	if isCrit:
		FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -12), str(damage), Color.GOLD, 10, 1.2)
	else:
		FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -12), str(damage), Color.WHITE, 8, 1.0)

	if Health <= 0:
		Die()
	else:
		GameAudio.Play(GameAudio.HIT, 0.08)
		CurrentState = EnemyState.Hurt
		velocity = Vector2.ZERO
		PlayHurtAnimation()

func PlayHurtAnimation() -> void:
	if Sprite == null:
		return
	if FacingRight:
		Sprite.play("hurt_right")
	else:
		Sprite.play("hurt_left")

func Die() -> void:
	CurrentState = EnemyState.Dead
	velocity = Vector2.ZERO
	GameAudio.Play(GameAudio.DEATH, 0.06)

	if CollisionShape != null:
		CollisionShape.set_deferred("disabled", true)

	SpawnRewards()
	PlayDeathAnimation()

func PlayDeathAnimation() -> void:
	if Sprite == null:
		queue_free()
		return

	if FacingRight:
		Sprite.play("death_right")
	else:
		Sprite.play("death_left")

# To be overridden by subclasses. Returns a Dictionary:
# { "materials": Array[ItemData], "equipment": Array[ItemData], "consumables": Array[ItemData] }
func _get_loot_drops(_luck_multiplier: float) -> Dictionary:
	return {
		"materials": [],
		"equipment": [],
		"consumables": []
	}

func SpawnRewards() -> void:
	var gold = randi_range(GoldMin, GoldMax)
	var xp = ExperienceDrop

	var player = get_parent().get_node_or_null("Player")
	var gameUI = get_parent().get_node_or_null("UI")

	if player != null and is_instance_valid(player):
		gold = roundi(gold * player.GoldMultiplier)
		xp = roundi(xp * player.ExperienceMultiplier)

		if player.LuckyElixirEnemiesCount > 0:
			player.LuckyElixirEnemiesCount -= 1

	print("Enemy ", name, " died. Rewards: ", gold, " Gold, ", xp, " Experience.")
	enemy_died.emit(gold, xp)

	FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -16), GameLocalization.Format("GOLD_REWARD", {"amount": gold}), Color.GOLD, 7, 1.0, -25.0)
	FloatingTextHelper.spawn(get_parent(), global_position + Vector2(0, -16), GameLocalization.Format("EXPERIENCE_REWARD", {"amount": xp}), Color(0.2, 0.8, 1.0), 7, 1.0, 25.0)

	var luck_multiplier = player.EquipmentDropLuckMultiplier if player != null else 1.0
	var drops = _get_loot_drops(luck_multiplier)
	var droppedMaterials = drops.get("materials", [])
	var rolledEquipment = drops.get("equipment", [])
	var droppedConsumables = drops.get("consumables", [])

	if IsBoss:
		var allEquip = ItemDatabase.get_all_predefined_equipment()
		var rareEquip: Array[ItemData] = []
		for equipItem in allEquip:
			if equipItem.Rarity >= ItemData.ItemRarity.Rare:
				rareEquip.append(equipItem)
		if rareEquip.size() > 0:
			var randIdx = randi() % rareEquip.size()
			rolledEquipment.append(rareEquip[randIdx].duplicate_item())

	var maxAllowedRarity = ItemData.ItemRarity.Common
	if player != null and is_instance_valid(player):
		var hunterLvl = player.TreasureHunterSkillLevel
		if hunterLvl == 1:
			maxAllowedRarity = ItemData.ItemRarity.Uncommon
		elif hunterLvl == 2:
			maxAllowedRarity = ItemData.ItemRarity.Rare
		elif hunterLvl == 3:
			maxAllowedRarity = ItemData.ItemRarity.Epic
		elif hunterLvl >= 4:
			maxAllowedRarity = ItemData.ItemRarity.Legendary

	var filteredMaterials: Array[ItemData] = []
	for item in droppedMaterials:
		if item != null and item.Rarity <= maxAllowedRarity:
			filteredMaterials.append(item)

	var filteredEquipment: Array[ItemData] = []
	for item in rolledEquipment:
		if item != null and item.Rarity <= maxAllowedRarity:
			filteredEquipment.append(item)

	var filteredConsumables: Array[ItemData] = []
	for item in droppedConsumables:
		if item != null and item.Rarity <= maxAllowedRarity:
			filteredConsumables.append(item)

	if player != null and is_instance_valid(player) and not player.TutorialCompleted and filteredMaterials.size() == 0:
		var tutorialMaterial = ItemDatabase.get_item("mat_slime", 1)
		if tutorialMaterial != null:
			filteredMaterials.append(tutorialMaterial)

	var selectedEquip: ItemData = null
	if filteredEquipment.size() > 0:
		selectedEquip = filteredEquipment[0]
		for i in range(1, filteredEquipment.size()):
			if filteredEquipment[i].Rarity > selectedEquip.Rarity:
				selectedEquip = filteredEquipment[i]

	var finalLoot: Array[ItemData] = []
	finalLoot.append_array(filteredMaterials)
	finalLoot.append_array(filteredConsumables)
	if selectedEquip != null:
		finalLoot.append(selectedEquip)

	if gameUI != null and is_instance_valid(gameUI) and finalLoot.size() > 0:
		var screenPos = get_global_transform_with_canvas().origin
		for i in range(finalLoot.size()):
			gameUI.SpawnFlyingLoot(finalLoot[i], screenPos, i * 0.15)
	elif player != null and is_instance_valid(player):
		for item in finalLoot:
			player.AddToInventory(item)

	for item in LootTable:
		if item == null or item.ItemPath.is_empty():
			continue

		var roll = randf()
		if roll <= item.DropChance:
			SpawnLootItem(item.ItemPath)

func SpawnLootItem(path: String) -> void:
	if not ResourceLoader.exists(path):
		printerr("Loot item path does not exist: ", path)
		return

	var scene = load(path) as PackedScene
	if scene != null:
		var instance = scene.instantiate() as Node2D
		if instance != null:
			instance.global_position = global_position
			get_parent().add_child(instance)
			print("Spawned loot: ", instance.name, " at ", global_position)

func OnAnimationFinished() -> void:
	if CurrentState == EnemyState.Hurt:
		TransitionToIdle()
	elif CurrentState == EnemyState.Dead:
		queue_free()
