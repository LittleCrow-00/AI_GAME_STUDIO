extends Node
## Teste de fumaca dos sistemas criticos da Fase 1.
##
## Executar:
##   godot --headless --path . res://tests/smoke_test.tscn
##
## Nao e um framework de teste: e um gate barato que impede regressao nos
## sistemas que sustentam a arquitetura (stats, pontuacao, morte, feixe).

const ENEMY_SCRIPT := preload("res://scripts/enemies/enemy_base.gd")

var _failures: int = 0
var _checks: int = 0


func _ready() -> void:
	await get_tree().process_frame

	_test_stat_sheet()
	_test_ressonancia()
	_test_enemy_death()
	await _test_beam_damage()
	await _test_arena_progression()

	var status := "OK" if _failures == 0 else "FAILED"
	print("SMOKE TEST: %s (%d checks, %d failures)" % [status, _checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _test_stat_sheet() -> void:
	var sheet := StatSheet.new()
	sheet.set_base(&"damage", 100.0)
	sheet.add(StatModifier.new(&"damage", StatModifier.Mode.ADD, 10.0))
	sheet.add(StatModifier.new(&"damage", StatModifier.Mode.ADD, 5.0))
	sheet.add(StatModifier.new(&"damage", StatModifier.Mode.MULTIPLY, 2.0))
	_check(is_equal_approx(sheet.get_stat(&"damage"), 230.0), "StatSheet: (100+10+5)*2 = 230")


func _test_ressonancia() -> void:
	var ressonancia := Ressonancia.new()
	add_child(ressonancia)
	ressonancia.register_hit(10.0)
	ressonancia.register_hit(10.0)
	_check(ressonancia.chain == 2, "Ressonancia: cadeia incrementa")
	_check(is_equal_approx(ressonancia.multiplier, 1.2), "Ressonancia: multiplicador 1.2")
	ressonancia.reset()
	_check(ressonancia.chain == 0, "Ressonancia: reset zera cadeia")


func _test_enemy_death() -> void:
	var enemy := ENEMY_SCRIPT.new() as Enemy
	add_child(enemy)
	enemy.max_health = 10.0
	enemy.health = 10.0

	var died := [false]
	SignalBus.enemy_died.connect(func(_e: Node, _p: Vector2) -> void: died[0] = true)
	enemy.take_damage(25.0, Vector2.ZERO)

	_check(died[0], "Enemy: morre e emite enemy_died")
	_check(enemy.health <= 0.0, "Enemy: vida vai a zero")


func _test_beam_damage() -> void:
	var holder := Node2D.new()
	add_child(holder)

	var beam := Beam.new()
	holder.add_child(beam)

	var enemy := ENEMY_SCRIPT.new() as Enemy
	add_child(enemy)
	enemy.max_health = 1000.0
	enemy.health = 1000.0
	enemy.position = Vector2(200.0, 0.0)

	await get_tree().physics_frame
	var before := enemy.health
	beam._apply_damage()
	_check(enemy.health < before, "Beam: acerta inimigo dentro do cone")

	enemy.position = Vector2(0.0, 600.0)
	await get_tree().physics_frame
	var after_far := enemy.health
	beam._apply_damage()
	_check(is_equal_approx(enemy.health, after_far), "Beam: ignora inimigo fora de alcance")


func _test_arena_progression() -> void:
	var arena := Arena.new()
	arena.setup(0)
	add_child(arena)

	var cleared := [false]
	arena.room_cleared.connect(func() -> void: cleared[0] = true)

	for _wave in range(3):
		await get_tree().physics_frame
		for node in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(node):
				(node as Enemy).take_damage(99999.0, Vector2.ZERO)
		await get_tree().create_timer(1.0).timeout

	_check(cleared[0], "Arena: limpa 3 ondas e emite room_cleared")
	arena.stop()
	arena.queue_free()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  PASS  %s" % label)
	else:
		_failures += 1
		printerr("  FAIL  %s" % label)