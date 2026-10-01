class_name EnemySpawner
extends Node2D

@export var EnemyScenes: Array[PackedScene] = []
@export var SpawnInterval: float = 3.0
@export var MaxEnemies: int = 8
@export var AutoSpawn: bool = false

var _spawnPoints: Array[Marker2D] = []
var _spawnTimer: float = 0.0

func _ready() -> void:
	for child in get_children():
		if child is Marker2D:
			_spawnPoints.append(child)
			print("EnemySpawner: Registered spawn point at ", child.position)

	if _spawnPoints.size() == 0:
		push_warning("EnemySpawner: No Marker2D spawn points found under this node! Enemies will spawn at (0,0).")

func _process(delta: float) -> void:
	if AutoSpawn:
		_spawnTimer += delta
		if _spawnTimer >= SpawnInterval:
			_spawnTimer = 0.0
			TrySpawnEnemy()

func SpawnEnemyManually() -> void:
	TrySpawnEnemy()

func TrySpawnEnemy() -> void:
	if EnemyScenes.size() == 0:
		return

	var player = get_parent().get_node_or_null("Player")
	if player == null or not is_instance_valid(player):
		return

	var activeEnemies = get_tree().get_nodes_in_group("enemies")
	var aliveCount = 0
	for node in activeEnemies:
		if node is CharacterBody2D and is_instance_valid(node):
			var state = node.get("CurrentState")
			if state != EnemyBase.EnemyState.Dead and state != 3: # 3 is Dead enum value
				aliveCount += 1

	if player.WaveCount % 5 == 0:
		if player.IsBossActive:
			return
		SpawnBoss(player)
		return

	if aliveCount >= MaxEnemies:
		return

	var spawnPosition = Vector2.ZERO
	if _spawnPoints.size() > 0:
		var pointIdx = randi() % _spawnPoints.size()
		spawnPosition = _spawnPoints[pointIdx].global_position

	var selectedScene: PackedScene = null
	var canSpawnElf = player.WaveCount >= 5

	for i in range(15):
		var sceneIdx = randi() % EnemyScenes.size()
		var candidate = EnemyScenes[sceneIdx]
		if candidate != null:
			var pathLower = candidate.resource_path.to_lower()
			if pathLower.contains("elf") and not canSpawnElf:
				continue
			selectedScene = candidate
			break

	if selectedScene != null:
		var enemyInstance = selectedScene.instantiate() as CharacterBody2D
		if enemyInstance != null:
			enemyInstance.global_position = spawnPosition
			enemyInstance.add_to_group("enemies")
			enemyInstance.enemy_died.connect(OnEnemyDied)

			if player.WaveCount >= 10 and selectedScene.resource_path.to_lower().contains("elf") and randf() < 0.50:
				if enemyInstance.has_method("set"):
					enemyInstance.set("IsDarkElf", true)

			get_parent().add_child(enemyInstance)
			GameAudio.Play(GameAudio.SUMMON, 0.06)
			print("EnemySpawner: Spawned ", enemyInstance.name, " at ", spawnPosition)

func SpawnBoss(player: Node) -> void:
	if EnemyScenes.size() == 0:
		return

	var selectedScene: PackedScene = null
	var canSpawnElf = player.WaveCount >= 5

	for i in range(15):
		var sceneIdx = randi() % EnemyScenes.size()
		var candidate = EnemyScenes[sceneIdx]
		if candidate != null:
			var pathLower = candidate.resource_path.to_lower()
			if pathLower.contains("elf") and not canSpawnElf:
				continue
			selectedScene = candidate
			break

	if selectedScene == null:
		return

	var spawnPosition = Vector2.ZERO
	if _spawnPoints.size() > 0:
		var pointIdx = randi() % _spawnPoints.size()
		spawnPosition = _spawnPoints[pointIdx].global_position

	var bossInstance = selectedScene.instantiate() as CharacterBody2D
	if bossInstance != null:
		bossInstance.global_position = spawnPosition
		bossInstance.add_to_group("enemies")
		bossInstance.set("IsBoss", true)
		bossInstance.set("BossCustomName", GetRandomBossName())
		bossInstance.enemy_died.connect(OnEnemyDied)

		player.IsBossActive = true
		player.BossTimer = 30.0

		get_parent().add_child(bossInstance)
		GameAudio.Play(GameAudio.BOSS_APPEAR)
		print("EnemySpawner: SPAWNED BOSS ", bossInstance.get("BossCustomName"), " at ", spawnPosition)

	FloatingTextHelper.spawn(get_parent(), bossInstance.global_position + Vector2(0, -25), GameLocalization.Format("BOSS_NAME", {"name": bossInstance.get("BossCustomName")}), Color.ORANGE_RED, 12, 1.8)

func GetRandomBossName() -> String:
	var filePath = "res://src/entities/enemies/boss_names.txt"
	if FileAccess.file_exists(filePath):
		var file = FileAccess.open(filePath, FileAccess.READ)
		if file != null:
			var names: Array[String] = []
			while not file.eof_reached():
				var line = file.get_line().strip_edges()
				if not line.is_empty():
					names.append(line)
			if names.size() > 0:
				var randIdx = randi() % names.size()
				return names[randIdx]
	return tr("Супер Монстр")

func OnEnemyDied(gold: int, experience: int) -> void:
	var player = get_parent().get_node_or_null("Player")
	if player != null and is_instance_valid(player):
		GameAudio.Play(GameAudio.COIN, 0.06)
		player.Gold += gold
		player.GainExperience(experience)
		player.KillsCount += 1

		if player.IsBossActive:
			var bossStillAlive = false
			var activeEnemies = get_tree().get_nodes_in_group("enemies")
			for node in activeEnemies:
				if node is CharacterBody2D and is_instance_valid(node):
					if node.get("IsBoss") and node.get("Health") > 0:
						bossStillAlive = true
						break

			if not bossStillAlive:
				GameAudio.Play(GameAudio.LEVEL_UP)
				player.IsBossActive = false
				player.BossTimer = 0.0

				player.WaveCount += 1
				player.KillsOnCurrentWave = 0

				print("Boss defeated! Advancing to Wave ", player.WaveCount)
				FloatingTextHelper.spawn(get_parent(), player.global_position + Vector2(0, -25), GameLocalization.Format("VICTORY_WAVE", {"wave": player.WaveCount}), Color.GREEN, 12, 1.5)
				
				if get_node_or_null("/root/BridgeManager") != null:
					get_node("/root/BridgeManager").ShowInterstitial()
				
				player.OnWaveAdvanced()
				player.SaveSettings()
				return

		if player.WaveCount % 5 != 0:
			player.KillsOnCurrentWave += 1
			if player.KillsOnCurrentWave >= 20:
				GameAudio.Play(GameAudio.LEVEL_UP)
				player.WaveCount += 1
				player.KillsOnCurrentWave = 0
				print("Wave completed! Next wave: ", player.WaveCount)
				FloatingTextHelper.spawn(get_parent(), player.global_position + Vector2(0, -25), GameLocalization.Format("WAVE_STARTED", {"wave": player.WaveCount}), Color.YELLOW, 12, 1.5)
				player.OnWaveAdvanced()

		player.SaveSettings()
