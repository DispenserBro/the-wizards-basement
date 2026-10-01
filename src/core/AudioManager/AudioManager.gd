class_name GameAudio
extends Node

## Общий менеджер коротких звуковых эффектов.
## Использует пул проигрывателей, чтобы частые эффекты не обрывали друг друга.

const UI_CLICK: StringName = &"ui_click"
const ATTACK: StringName = &"attack"
const HIT: StringName = &"hit"
const DEATH: StringName = &"death"
const SUMMON: StringName = &"summon"
const COIN: StringName = &"coin"
const POWER_UP: StringName = &"power_up"
const LEVEL_UP: StringName = &"level_up"
const BOSS_APPEAR: StringName = &"boss_appear"
const BOSS_FAILED: StringName = &"boss_failed"

const PLAYER_POOL_SIZE := 12
const CONNECTED_META: StringName = &"game_audio_connected"
const SFX_ROOT := "res://external/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/Mono/ogg/"

const SOUND_PATHS := {
	UI_CLICK: "res://external/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/Mono/ogg/JDSherbert - Pixel Game Essentials SFX Pack - Switch 1.ogg",
	ATTACK: "res://external/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/Mono/ogg/JDSherbert - Pixel Game Essentials SFX Pack - Shoot 1.ogg",
	HIT: "res://external/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/Mono/ogg/JDSherbert - Pixel Game Essentials SFX Pack - Damage 1.ogg",
	DEATH: "res://external/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/Mono/ogg/JDSherbert - Pixel Game Essentials SFX Pack - Die 1.ogg",
	SUMMON: "res://external/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/Mono/ogg/JDSherbert - Pixel Game Essentials SFX Pack - Shoot 2.ogg",
	COIN: "res://external/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/Mono/ogg/JDSherbert - Pixel Game Essentials SFX Pack - Coin 1.ogg",
	POWER_UP: "res://external/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/Mono/ogg/JDSherbert - Pixel Game Essentials SFX Pack - Powerup 1.ogg",
	LEVEL_UP: "res://external/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/Mono/ogg/JDSherbert - Pixel Game Essentials SFX Pack - Level Complete 1.ogg",
	BOSS_APPEAR: "res://external/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/Mono/ogg/JDSherbert - Pixel Game Essentials SFX Pack - Checkpoint 1.ogg",
	BOSS_FAILED: "res://external/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/JDSherbert - Pixel Game Essentials SFX Pack (FREE)/Mono/ogg/JDSherbert - Pixel Game Essentials SFX Pack - Level Fail 1.ogg",
}

const SOUND_VOLUMES := {
	UI_CLICK: -10.0,
	ATTACK: -7.0,
	HIT: -6.0,
	DEATH: -5.0,
	SUMMON: -7.0,
	COIN: -8.0,
	POWER_UP: -6.0,
	LEVEL_UP: -5.0,
	BOSS_APPEAR: -5.0,
	BOSS_FAILED: -5.0,
}

const MUSIC_TRACKS := [
	"res://src/sounds/music/track_1.mp3",
	"res://src/sounds/music/track_2.mp3",
	"res://src/sounds/music/track_3.mp3",
	"res://src/sounds/music/track_4.mp3"
]

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player_index: int = 0
var _random := RandomNumberGenerator.new()
var _music_players: Array[AudioStreamPlayer] = []
var _active_player_idx: int = 0
var _current_music_index: int = -1
var _fade_tween: Tween = null
var _music_queue: Array[int] = []
var _queue_index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_random.randomize()
	EnsureSfxBusExists()
	EnsureMusicBusExists()
	ApplySavedSfxVolume()
	ApplySavedMusicVolume()
	LoadStreams()
	CreatePlayerPool()
	CreateMusicPlayer()
	
	# Start playing music
	PlayNextTrack(1.5)

	get_tree().node_added.connect(OnNodeAdded)
	call_deferred("ConnectExistingButtons")

func _exit_tree() -> void:
	if get_tree() != null and get_tree().node_added.is_connected(OnNodeAdded):
		get_tree().node_added.disconnect(OnNodeAdded)

func EnsureSfxBusExists() -> void:
	if AudioServer.get_bus_index("SFX") != -1:
		return

	AudioServer.add_bus()
	var busIndex = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(busIndex, "SFX")
	AudioServer.set_bus_send(busIndex, "Master")

func EnsureMusicBusExists() -> void:
	if AudioServer.get_bus_index("Music") != -1:
		return

	AudioServer.add_bus()
	var busIndex = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(busIndex, "Music")
	AudioServer.set_bus_send(busIndex, "Master")

func ApplySavedSfxVolume() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return

	var sliderValue = float(config.get_value("Audio", "SfxVolume", 80.0))
	var busIndex = AudioServer.get_bus_index("SFX")
	if sliderValue <= 0.0:
		AudioServer.set_bus_mute(busIndex, true)
	else:
		AudioServer.set_bus_mute(busIndex, false)
		AudioServer.set_bus_volume_db(busIndex, linear_to_db(sliderValue / 100.0))

func ApplySavedMusicVolume() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return

	var sliderValue = float(config.get_value("Audio", "MusicVolume", 80.0))
	var busIndex = AudioServer.get_bus_index("Music")
	if busIndex != -1:
		if sliderValue <= 0.0:
			AudioServer.set_bus_mute(busIndex, true)
		else:
			AudioServer.set_bus_mute(busIndex, false)
			var linear = sliderValue / 100.0
			var db = -80.0 if linear <= 0.0 else 20.0 * log(linear) / log(10.0)
			AudioServer.set_bus_volume_db(busIndex, db)

func CreateMusicPlayer() -> void:
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.name = "MusicPlayer" + str(i + 1)
		player.bus = &"Music"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_music_players.append(player)
		player.finished.connect(OnMusicFinished)

func PlayMusicTrack(index: int, fade_duration: float = 1.5) -> void:
	if index < 0 or index >= MUSIC_TRACKS.size() or _music_players.size() < 2:
		return
	
	var active_player = _music_players[_active_player_idx]
	var next_player_idx = (_active_player_idx + 1) % 2
	var next_player = _music_players[next_player_idx]
	
	if _current_music_index == index and active_player.playing:
		return
		
	var stream = load(MUSIC_TRACKS[index]) as AudioStream
	if stream == null:
		push_warning("GameAudio: Failed to load music track: " + MUSIC_TRACKS[index])
		return
		
	if stream is AudioStreamMP3:
		stream.loop = false
		
	_current_music_index = index
	print("GameAudio: Playing music track ", index + 1, " (", MUSIC_TRACKS[index].get_file(), ") with crossfade")
	
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
		
	_fade_tween = create_tween().set_parallel(true)
	
	if active_player.playing:
		_fade_tween.tween_property(active_player, "volume_db", -80.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var temp_player = active_player
		_fade_tween.chain().tween_callback(temp_player.stop)
	
	next_player.stream = stream
	next_player.volume_db = -80.0
	next_player.play()
	_fade_tween.tween_property(next_player, "volume_db", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	_active_player_idx = next_player_idx

func RebuildMusicQueue() -> void:
	_music_queue = [0, 1, 2, 3]
	_music_queue.shuffle()
	
	# Avoid immediate repeating of the same track when queue is rebuilt
	if _current_music_index != -1 and _music_queue[0] == _current_music_index and _music_queue.size() > 1:
		var temp = _music_queue[0]
		_music_queue[0] = _music_queue[1]
		_music_queue[1] = temp
		
	_queue_index = 0
	print("GameAudio: Rebuilt shuffled music queue: ", _music_queue)

func PlayNextTrack(fade_duration: float = 1.5) -> void:
	if _music_queue.is_empty() or _queue_index >= _music_queue.size() or _queue_index < 0:
		RebuildMusicQueue()
		
	var next_track_idx = _music_queue[_queue_index]
	_queue_index += 1
	PlayMusicTrack(next_track_idx, fade_duration)

func OnMusicFinished() -> void:
	if _music_players.size() < 2:
		return
	var active_player = _music_players[_active_player_idx]
	if not active_player.playing:
		PlayNextTrack(2.0)

static func PlayMusic(index: int) -> void:
	var sceneTree = Engine.get_main_loop() as SceneTree
	if sceneTree == null:
		return

	var manager = sceneTree.root.get_node_or_null("GameAudioRuntime") as GameAudio
	if manager != null:
		manager.PlayMusicTrack(index)
		# Clear queue so that the next track will rebuild a new randomized order
		manager._music_queue.clear()
		manager._queue_index = -1

static func StopMusic() -> void:
	var sceneTree = Engine.get_main_loop() as SceneTree
	if sceneTree == null:
		return

	var manager = sceneTree.root.get_node_or_null("GameAudioRuntime") as GameAudio
	if manager != null:
		manager.StopMusicInstance()

func StopMusicInstance() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	for player in _music_players:
		player.stop()
	_current_music_index = -1
	_music_queue.clear()
	_queue_index = -1

func LoadStreams() -> void:
	for soundId in SOUND_PATHS:
		var stream = load(SOUND_PATHS[soundId]) as AudioStream
		if stream != null:
			_streams[soundId] = stream
		else:
			push_warning("Не удалось загрузить звуковой эффект: " + SOUND_PATHS[soundId])

func CreatePlayerPool() -> void:
	for i in range(PLAYER_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.name = "SfxPlayer" + str(i + 1)
		player.bus = &"SFX"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)

static func Play(soundId: StringName, pitchVariation: float = 0.0, volumeOffsetDb: float = 0.0) -> void:
	var sceneTree = Engine.get_main_loop() as SceneTree
	if sceneTree == null:
		return

	var manager = sceneTree.root.get_node_or_null("GameAudioRuntime") as GameAudio
	if manager != null:
		manager.PlaySound(soundId, pitchVariation, volumeOffsetDb)

func PlaySound(soundId: StringName, pitchVariation: float = 0.0, volumeOffsetDb: float = 0.0) -> void:
	var stream = _streams.get(soundId) as AudioStream
	if stream == null or _players.is_empty():
		return

	var player = FindAvailablePlayer()
	player.stream = stream
	player.pitch_scale = _random.randf_range(1.0 - pitchVariation, 1.0 + pitchVariation) if pitchVariation > 0.0 else 1.0
	player.volume_db = float(SOUND_VOLUMES.get(soundId, -6.0)) + volumeOffsetDb
	player.play()

func FindAvailablePlayer() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player

	var player = _players[_next_player_index]
	_next_player_index = (_next_player_index + 1) % _players.size()
	player.stop()
	return player

func ConnectExistingButtons() -> void:
	ConnectButtonsInBranch(get_tree().root)

func ConnectButtonsInBranch(node: Node) -> void:
	ConnectButton(node)
	for child in node.get_children():
		ConnectButtonsInBranch(child)

func OnNodeAdded(node: Node) -> void:
	ConnectButton(node)

func ConnectButton(node: Node) -> void:
	if not node is BaseButton or node.has_meta(CONNECTED_META):
		return

	node.set_meta(CONNECTED_META, true)
	node.pressed.connect(OnUiButtonPressed)

func OnUiButtonPressed() -> void:
	PlaySound(UI_CLICK, 0.025)
