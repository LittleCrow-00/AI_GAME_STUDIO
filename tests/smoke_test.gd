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
	await _test_thresholds()
	_test_enemy_death()
	await _test_beam_damage()
	await _test_hitstop()
	_test_light_well()
	_test_projectile_pool()
	_test_boss_exposure()
	_test_item_pool()
	_test_sanctuary_shop()
	_test_settings()
	_test_elite_and_palette()
	await _test_pause_menu()
	await _test_items_and_synergies()
	await _test_farol()
	await _test_arena_progression()
	await _test_stress()

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


func _test_thresholds() -> void:
	var crossed := ThresholdDatabase.crossed(9, 11)
	_check(crossed.size() == 1 and crossed[0].id == &"estopim", "Limiar: detecta passagem de 10")
	_check(ThresholdDatabase.crossed(10, 12).is_empty(), "Limiar: não dispara duas vezes")
	_check(ThresholdDatabase.next_after(0).at_chain == 10, "Limiar: próximo é 10")
	_check(ThresholdDatabase.next_after(50) == null, "Limiar: sem próximo após 50")

	var ressonancia := Ressonancia.new()
	add_child(ressonancia)
	var emitted := [false]
	SignalBus.threshold_reached.connect(func(_t: ThresholdData) -> void: emitted[0] = true)
	for i in range(10):
		ressonancia.register_hit(5.0)
	_check(emitted[0], "Ressonancia: emite threshold_reached ao cruzar 10")
	ressonancia.queue_free()

	var player := _spawn_player()
	await get_tree().process_frame
	player.remove_oil(50.0)
	var oil_before := player.oil
	player._on_threshold_reached(ThresholdDatabase.get_threshold(&"estopim"))
	_check(player.oil > oil_before, "Limiar: estopim devolve óleo")

	var range_before := player.stats.get_stat(&"beam_range")
	player._on_threshold_reached(ThresholdDatabase.get_threshold(&"alcance_longo"))
	_check(player.stats.get_stat(&"beam_range") > range_before, "Limiar: alcance_longo aumenta o alcance")
	player._tick_thresholds(7.0)
	_check(
		is_equal_approx(player.stats.get_stat(&"beam_range"), range_before),
		"Limiar: expira e restaura o alcance",
	)

	player.queue_free()
	await get_tree().process_frame


func _test_settings() -> void:
	var shake_before := Settings.reduce_shake
	var flash_before := Settings.reduce_flashes

	Settings.set_reduce_shake(true)
	_check(Settings.reduce_shake, "Settings: reduzir tremor é persistido")

	var camera := ScreenShake.new()
	camera.enabled = false
	add_child(camera)
	camera.add_trauma(0.5)
	var reduced := camera._trauma
	camera.queue_free()

	Settings.set_reduce_shake(false)
	var camera_normal := ScreenShake.new()
	camera_normal.enabled = false
	add_child(camera_normal)
	camera_normal.add_trauma(0.5)
	var normal := camera_normal._trauma
	camera_normal.queue_free()

	_check(reduced < normal, "Settings: tremor reduzido move menos a câmera")

	Settings.set_reduce_flashes(true)
	Settings.load_settings()
	_check(Settings.reduce_flashes, "Settings: recarrega as opções do disco")

	Settings.set_reduce_shake(shake_before)
	Settings.set_reduce_flashes(flash_before)
	await get_tree().process_frame


func _test_pause_menu() -> void:
	var menu := PauseMenu.new()
	add_child(menu)
	await get_tree().process_frame

	_check(not menu.is_open(), "Pause: começa fechado")
	menu._open_menu()
	_check(menu.is_open() and get_tree().paused, "Pause: abre e pausa a árvore")
	menu._close_menu()
	_check(not menu.is_open() and not get_tree().paused, "Pause: fecha e retoma a árvore")

	menu.queue_free()
	await get_tree().process_frame


func _test_elite_and_palette() -> void:
	var enemy := ENEMY_SCRIPT.new() as Enemy
	enemy.max_health = 30.0
	enemy.health = 30.0
	enemy.cera_drop = 1
	add_child(enemy)
	enemy.make_elite()
	_check(enemy.elite, "Elite: marca a variante")
	_check(enemy.max_health > 60.0, "Elite: aumenta a vida")
	_check(enemy.cera_drop >= 3, "Elite: rende mais cera")
	enemy.queue_free()

	var arena := Arena.new()
	arena.room_index = 0
	var shallow: Color = arena._palette()["base"]
	arena.room_index = 1
	var deeper: Color = arena._palette()["base"]
	_check(not shallow.is_equal_approx(deeper), "Arena: paleta muda por andar")
	arena.queue_free()

	await get_tree().process_frame


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


func _test_items_and_synergies() -> void:
	var player := _spawn_player()
	await get_tree().process_frame

	var cera := ItemDatabase.get_item(&"cera_velha")
	var oil_before := player.max_oil
	player.apply_item(cera)
	_check(is_equal_approx(player.max_oil, oil_before + 20.0), "Item: cera_velha aumenta óleo máximo")

	var dash_before := player.stats.get_stat(&"dash_charges_max")
	player.apply_item(ItemDatabase.get_item(&"folego"))
	_check(player.stats.get_stat(&"dash_charges_max") > dash_before, "Item: folego adiciona carga de dash")

	player.apply_item(ItemDatabase.get_item(&"fragmento"))
	_check(player.beam.refraction == 1, "Item: fragmento ativa refração no feixe")

	player.apply_item(ItemDatabase.get_item(&"olho_de_boto"))
	_check(player.beam.refraction == 3, "Item: refração acumula entre itens")
	_check(player._known_synergies.has(Inventory.SYNERGY_ESTADIO), "Sinergia: luz_de_estadio com 2 itens de lente")

	player.apply_item(ItemDatabase.get_item(&"sangue_quente"))
	_check(player._oil_on_kill_bonus > 0.0, "Sinergia: cera_viva com 2 itens de óleo")

	var casco_before := player.stats.get_stat(&"dash_charges_max")
	player.apply_item(ItemDatabase.get_item(&"amuleto_de_osso"))
	player.apply_item(ItemDatabase.get_item(&"casca_grossa"))
	_check(player.stats.get_stat(&"dash_charges_max") > casco_before, "Sinergia: casco com 3 itens de corpo")

	player.apply_item(ItemDatabase.get_item(&"furador"))
	_check(player.beam.pierce_walls, "Item: furador atravessa paredes")

	var stacks_before := player.inventory.stacks_of(&"fragmento")
	player.apply_item(ItemDatabase.get_item(&"fragmento"))
	_check(
		player.inventory.stacks_of(&"fragmento") == stacks_before
		or player.inventory.stacks_of(&"fragmento") == stacks_before + 1,
		"Item: respeita limite de stacks",
	)

	player.queue_free()
	await get_tree().process_frame


func _test_item_pool() -> void:
	_check(ItemDatabase.count() >= 25, "ItemDatabase: ao menos 25 itens")
	for item in ItemDatabase.draw(3, 0):
		_check(item.rarity != ItemData.Rarity.CURSED, "ItemDatabase: sala 0 não oferece maldição")


func _test_sanctuary_shop() -> void:
	var sanctuary := Sanctuary.new()
	add_child(sanctuary)
	await get_tree().process_frame

	var requests: Array = []
	sanctuary.purchase_requested.connect(
		func(item: ItemData, price: int) -> void: requests.append([item, price]),
	)

	sanctuary.open(ItemDatabase.draw(3, 1), 5, 10, true)
	sanctuary._choose(0)
	_check(requests.size() == 1 and int(requests[0][1]) == 0, "Loja: 1ª escolha é grátis")

	sanctuary._choose(1)
	_check(requests.size() == 1, "Loja: recusa compra sem cera")

	sanctuary.set_cera(20)
	sanctuary._choose(1)
	_check(requests.size() == 2 and int(requests[1][1]) == 10, "Loja: cobra cera na 2ª escolha")

	var enemy := ENEMY_SCRIPT.new() as Enemy
	var data := EnemyData.new()
	data.cera_drop = 7
	enemy.apply_data(data)
	_check(enemy.cera_drop == 7, "EnemyData: aplica cera_drop")

	sanctuary.close()
	_check(not sanctuary.is_open(), "Loja: fecha e emite closed")
	sanctuary.queue_free()
	enemy.queue_free()
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


func _test_stress() -> void:
	var player := _spawn_player()
	player.stats.set_base(&"max_health", 1.0e9)
	player._refresh_stats(false)
	player.position = Vector2.ZERO
	await get_tree().process_frame

	var spawned: Array[Enemy] = []
	for i in range(60):
		var enemy := ENEMY_SCRIPT.new() as Enemy
		enemy.max_health = 1.0e9
		enemy.health = 1.0e9
		enemy.move_speed = 60.0
		add_child(enemy)
		var angle := TAU * float(i) / 60.0
		enemy.position = Vector2.from_angle(angle) * 320.0
		spawned.append(enemy)

	for i in range(30):
		await get_tree().process_frame

	var frames := 120
	var start := Time.get_ticks_usec()
	for i in range(frames):
		await get_tree().process_frame
	var elapsed_ms := float(Time.get_ticks_usec() - start) / 1000.0
	var average := elapsed_ms / float(frames)
	print("  INFO  60 inimigos: %.2f ms/frame (headless, CPU)" % average)
	_check(average < 12.0, "Estresse: 60 inimigos abaixo de 12 ms/frame")

	for enemy in spawned:
		enemy.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  PASS  %s" % label)
	else:
		_failures += 1
		printerr("  FAIL  %s" % label)