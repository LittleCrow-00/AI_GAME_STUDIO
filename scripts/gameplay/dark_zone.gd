class_name DarkZone
extends Node2D
## Poça de escuridão da Caipora.
##
## Não bloqueia movimento nem tiro: **encolhe o feixe** de quem está dentro. É a
## mesma aura da Cuca, com origem própria, então várias zonas não se atropelam.

@export var radius: float = 95.0
@export var lifetime: float = 6.0
@export var beam_range_mult: float = 0.55

var _age: float = 0.0
var _player_inside: bool = false


func _ready() -> void:
	add_to_group("dark_zones")
	z_index = 1


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	_update_player()

	if _age >= lifetime:
		queue_free()


func _update_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return

	var inside := player.global_position.distance_to(global_position) <= radius
	if inside == _player_inside:
		return

	_player_inside = inside
	if inside:
		var modifier := StatModifier.new(&"beam_range", StatModifier.Mode.MULTIPLY, beam_range_mult)
		player.apply_aura(&"dark_zone", [modifier])
	else:
		_clear_aura(player)


func _exit_tree() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		_clear_aura(player)


## Só devolve a luz quando nenhuma outra zona ainda cobre o jogador.
func _clear_aura(player: Player) -> void:
	for node in get_tree().get_nodes_in_group("dark_zones"):
		if node == self or not is_instance_valid(node):
			continue
		var zone := node as DarkZone
		if zone != null and zone.covers(player.global_position):
			return
	player.apply_aura(&"dark_zone", [])


func covers(point: Vector2) -> bool:
	return point.distance_to(global_position) <= radius


func _draw() -> void:
	var fade := 1.0 - clampf(_age / maxf(0.01, lifetime), 0.0, 1.0) * 0.6
	draw_circle(Vector2.ZERO, radius, Color(0.02, 0.01, 0.06, 0.55 * fade))
	draw_circle(Vector2.ZERO, radius * 0.72, Color(0.05, 0.02, 0.10, 0.45 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 30, Color(0.45, 0.35, 0.75, 0.35 * fade), 2.0)