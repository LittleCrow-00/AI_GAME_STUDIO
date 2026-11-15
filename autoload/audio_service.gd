extends Node
## Áudio do FAROLEIRO.
##
## Os WAVs são sintetizados por `tools/gen_audio.gd` (nada de sample de terceiro).
## Este serviço só escuta o `SignalBus` e toca — gameplay não sabe que existe som.

const SOUNDS := {
	&"hit": preload("res://assets/audio/hit.wav"),
	&"kill": preload("res://assets/audio/kill.wav"),
	&"pickup": preload("res://assets/audio/pickup.wav"),
	&"dash": preload("res://assets/audio/dash.wav"),
	&"hurt": preload("res://assets/audio/hurt.wav"),
	&"dry": preload("res://assets/audio/dry.wav"),
	&"farol": preload("res://assets/audio/farol.wav"),
	&"item": preload("res://assets/audio/item.wav"),
	&"synergy": preload("res://assets/audio/synergy.wav"),
	&"boss": preload("res://assets/audio/boss.wav"),
	&"death": preload("res://assets/audio/death.wav"),
	&"ui_move": preload("res://assets/audio/ui_move.wav"),
	&"ui_confirm": preload("res://assets/audio/ui_confirm.wav"),
	&"unlock": preload("res://assets/audio/unlock.wav"),
	&"drone": preload("res://assets/audio/drone.wav"),
}

const VOICES: int = 10
const HIT_COOLDOWN: float = 0.07

var _players: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _hit_cooldown: float = 0.0
var _last_dash_charges: int = 0
var _drone: AudioStreamPlayer
var _muted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_voices()
	_build_drone()

	SignalBus.beam_hit_enemy.connect(_on_beam_hit)
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.oil_pickup_collected.connect(_on_oil_pickup)
	SignalBus.player_damaged.connect(_on_player_damaged)
	SignalBus.beam_dried.connect(_on_beam_dried)
	SignalBus.dash_charges_changed.connect(_on_dash_charges_changed)
	SignalBus.threshold_reached.connect(_on_threshold_reached)
	SignalBus.farol_lit.connect(_on_farol_lit)
	SignalBus.boss_spawned.connect(_on_boss_spawned)
	SignalBus.boss_defeated.connect(_on_boss_defeated)
	SignalBus.player_died.connect(_on_player_died)
	SignalBus.item_collected.connect(_on_item_collected)
	SignalBus.synergy_changed.connect(_on_synergy_changed)
	set_muted(Settings.muted)


func _process(delta: float) -> void:
	_hit_cooldown = maxf(0.0, _hit_cooldown - delta)


func _build_voices() -> void:
	for i in range(VOICES):
		var player := AudioStreamPlayer.new()
		player.name = "Voice%d" % i
		add_child(player)
		_players.append(player)


func _build_drone() -> void:
	_drone = AudioStreamPlayer.new()
	_drone.name = "Drone"
	var stream := SOUNDS[&"drone"] as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	_drone.stream = stream
	_drone.volume_db = -20.0
	add_child(_drone)
	_drone.play()


func _play(id: StringName, volume_db: float = -6.0, pitch_variation: float = 0.0) -> void:
	if _muted or _players.is_empty():
		return
	var stream := SOUNDS.get(id) as AudioStream
	if stream == null:
		return
	var player := _players[_next_voice]
	_next_voice = (_next_voice + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


func play_ui(id: StringName) -> void:
	_play(id, -12.0)


func set_muted(value: bool) -> void:
	_muted = value
	if _drone != null:
		_drone.volume_db = -80.0 if value else -20.0


func is_muted() -> bool:
	return _muted


func _on_beam_hit(_enemy: Node, _damage: float) -> void:
	if _hit_cooldown > 0.0:
		return
	_hit_cooldown = HIT_COOLDOWN
	_play(&"hit", -13.0, 0.08)


func _on_enemy_killed(_position: Vector2, _oil: float) -> void:
	_play(&"kill", -9.0, 0.07)


func _on_oil_pickup(_amount: float) -> void:
	_play(&"pickup", -10.0, 0.10)


func _on_player_damaged(_amount: float, _position: Vector2) -> void:
	_play(&"hurt", -6.0)


func _on_beam_dried() -> void:
	_play(&"dry", -5.0)


func _on_dash_charges_changed(current: int, _maximum: int) -> void:
	if current < _last_dash_charges:
		_play(&"dash", -9.0, 0.08)
	_last_dash_charges = current


func _on_threshold_reached(_threshold: ThresholdData) -> void:
	_play(&"farol", -8.0)


func _on_farol_lit() -> void:
	_play(&"farol", -4.0)

func _on_boss_spawned(_boss: Node) -> void:
	_play(&"boss", -3.0)


func _on_boss_defeated() -> void:
	_play(&"kill", -2.0, 0.03)
	_play(&"farol", -6.0)


func _on_player_died() -> void:
	_play(&"death", -4.0)
	if _drone != null:
		_drone.volume_db = -34.0


func _on_item_collected(_item: ItemData) -> void:
	_play(&"item", -8.0, 0.05)


func _on_synergy_changed(synergies: Array) -> void:
	if synergies.is_empty():
		return
	_play(&"synergy", -6.0)
	_play(&"unlock", -10.0)
