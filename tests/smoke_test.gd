extends Node
## Teste de fumaça dos sistemas críticos.
##
## Executar:
##   godot --headless --path . res://tests/smoke_test.tscn
##
## Não é um framework: é um gate barato que impede regressão nos sistemas que
## sustentam a arquitetura (stats, pontuação, morte, feixe, tempo, poo,
## focos de luz e ciclo de sala).

const ENEMY_SCRIPT := preload("res://scripts/enemies/enemy_base.gd")

var _failures: int = 0
var _checks: int = 0


func _ready() -> void:
	await get_tree().process_frame

	_test_stat_sheet()
	_test_ressonancia()
	_test_enemy_death()
	await _test_beam_damage()
	await _test_hitstop()
	_test_light_well()
	_test_projectile_pool()
	_test_boss_exposure()
	await _test_boon_application()
	await _test_farol()
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


func _test_hitstop() -> void:
	TimeService.hitstop(60)
	_check(Engine.time_scale < 1.0, "TimeService: hitstop reduz o time_scale")
	await get_tree().create_timer(0.3, true, false, true).timeout
	_check(is_equal_approx(Engine.time_scale, 1.0), "TimeService: hitstop restaura o time_scale")


func _test_light_well() -> void:
	var well := LightWell.new()
	well.position = Vector2(100.0, 0.0)
	add_child(well)

	_check(well.contains_point(Vector2(150.0, 0.0)), "LightWell: contém ponto dentro do raio")
	_check(not well.contains_point(Vector2(400.0, 0.0)), "LightWell: rejeita ponto fora do raio")
	_check(well.oil_per_second > 0.0, "LightWell: regenera óleo")
	well.queue_free()


func _test_projectile_pool() -> void:
	var pool := ProjectilePool.new()
	add_child(pool)

	var projectile := pool.spawn(Vector2.ZERO, Vector2.RIGHT, 100.0, 5.0, 0.0, Color.WHITE)
	_check(projectile != null and projectile.active, "ProjectilePool: spawn ativa projétil")

	projectile.deactivate()
	_check(not projectile.active, "ProjectilePool: deactivate libera o projétil")

	pool.queue_free()


func _test_boss_exposure() -> void:
	var boss := CobraGrande.new()
	boss.max_health = 600.0
	boss.health = 600.0
	add_child(boss)

	boss.take_damage(100.0, Vector2.ZERO)
	_check(boss.health > 500.0, "Cobra Grande: blindada fora da luz")

	for i in range(25):
		boss._on_beam_hit(boss, 8.0)
	_check(boss.is_exposed(), "Cobra Grande: exposta após luz contínua")

	var before := boss.health
	boss.take_damage(100.0, Vector2.ZERO)
	_check(is_equal_approx(before - boss.health, 100.0), "Cobra Grande: dano cheio quando exposta")

	boss.queue_free()


func _test_boon_application() -> void:
	var player := _spawn_player()
	var before := player.max_oil
	player.apply_boon(BoonDatabase.ALL[8])
	_check(is_equal_approx(player.max_oil, before + 20.0), "Boon: aumenta óleo máximo")

	var dash_before := player.stats.get_stat(&"dash_charges_max")
	player.apply_boon(BoonDatabase.ALL[5])
	_check(player.stats.get_stat(&"dash_charges_max") > dash_before, "Boon: adiciona carga de dash")

	player.queue_free()
	await get_tree().process_frame


func _test_farol() -> void:
	var farol := Farol.new()
	farol.position = Vector2.ZERO
	farol.set_active(true)
	add_child(farol)

	var player := _spawn_player()
	player.position = Vector2.ZERO
	player.set_physics_process(false)

	await get_tree().create_timer(2.4, true, false, true).timeout
	_check(farol.is_lit(), "Farol: acende com o jogador dentro")

	player.queue_free()
	farol.queue_free()
	await get_tree().process_frame


func _spawn_player() -> Player:
	var scene := load("res://scenes/player/player.tscn") as PackedScene
	var player := scene.instantiate() as Player
	add_child(player)
	return player


func _test_arena_progression() -> void:
	var arena := Arena.new()
	arena.setup(0)
	add_child(arena)

	var cleared := [false]
	arena.room_cleared.connect(func() -> void: cleared[0] = true)

	var elapsed := 0.0
	while not cleared[0] and elapsed < 30.0:
		for node in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(node):
				(node as Enemy).take_damage(99999.0, Vector2.ZERO)
		await get_tree().create_timer(0.2, true, false, true).timeout
		elapsed += 0.2

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