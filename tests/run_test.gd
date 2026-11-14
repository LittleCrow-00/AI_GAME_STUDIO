extends Node
## Teste de fumaça da run completa (ponta a ponta).
##
## Executar:
##   godot --headless --path . res://tests/run_test.tscn
##
## Diferente do `smoke_test` (que testa peças isoladas), este dirige a `Main` de
## verdade: limpa as 4 salas, compra um item no Santuário, acende o Farol e
## verifica a vitória. É o gate que impede regressão no fluxo (pausa, loja,
## progressão de sala e fim de run).

const MAIN_SCENE: PackedScene = preload("res://scenes/main/main.tscn")

const STATE_COMBAT := 0
const STATE_SANCTUARY := 1
const STATE_DEAD := 2
const STATE_VICTORY := 3

var _failures: int = 0
var _checks: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	# Isola o save: o teste deposita cera de verdade, mas em arquivo temporário.
	var real_path := SaveSystem.path
	SaveSystem.path = "user://test_run_save.json"
	SaveSystem.reset()

	SaveSystem.total_cera = 100
	SaveSystem.purchase(&"oleo_frio")

	var main := MAIN_SCENE.instantiate() as Node
	main.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(main)
	await get_tree().process_frame

	var player_at_start := main.get("player") as Player
	_check(
		player_at_start != null and player_at_start.inventory.has(&"cera_velha"),
		"Run: desbloqueio vira item inicial",
	)

	var bought := false
	var deadline := Time.get_ticks_msec() + 120000
	var state: int = STATE_COMBAT

	while Time.get_ticks_msec() < deadline:
		state = int(main.get("_state"))
		if state == STATE_VICTORY or state == STATE_DEAD:
			break

		if state == STATE_SANCTUARY:
			var sanctuary := main.get("sanctuary") as Sanctuary
			if not bought:
				sanctuary._choose(0)
				bought = true
			else:
				sanctuary.close()
			await get_tree().process_frame
			continue

		var player := main.get("player") as Player
		if player != null:
			player.heal(99999.0)

		for node in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(node):
				(node as Enemy).take_damage(999999.0, Vector2.ZERO)

		_keep_player_at_farol(main, player)
		await get_tree().create_timer(0.1, true, false, true).timeout

	var final_state := int(main.get("_state"))
	_check(final_state == STATE_VICTORY, "Run: termina em vitória")
	_check(final_state != STATE_DEAD, "Run: jogador sobrevive à run de teste")
	_check(int(main.get("_rooms_cleared")) == 4, "Run: 4 salas limpas")
	_check(int(main.get("_kills")) > 0, "Run: abates registrados")
	_check(int(main.get("_cera")) > 0, "Run: cera acumulada")

	var player := main.get("player") as Player
	_check(player != null and player.inventory.count() >= 1, "Run: item aplicado no Santuário")

	main.queue_free()
	await get_tree().process_frame

	SaveSystem.reset()
	SaveSystem.path = real_path
	SaveSystem.load_game()

	var status := "OK" if _failures == 0 else "FAILED"
	print("RUN TEST: %s (%d checks, %d failures)" % [status, _checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


## Na sala do Farol, mantém o jogador dentro do círculo para acender.
func _keep_player_at_farol(main: Node, player: Player) -> void:
	if player == null:
		return
	var arena := main.get("_arena") as Arena
	if arena == null:
		return
	var farol := arena.get("_farol") as Farol
	if farol == null or farol.is_lit():
		return
	player.global_position = farol.global_position
	player.velocity = Vector2.ZERO


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  PASS  %s" % label)
	else:
		_failures += 1
		printerr("  FAIL  %s" % label)