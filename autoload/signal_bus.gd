extends Node
## Barramento global de eventos.
##
## Desacopla gameplay de apresentacao (HUD, audio, VFX). Nenhum subsistema
## deve consultar outro diretamente quando um sinal resolve: emita aqui e
## deixe quem se importa reagir. Ver docs/architecture.md.

# --- Combate ---
signal enemy_died(enemy: Node, position: Vector2)
signal enemy_killed(position: Vector2, oil_drop: float)
signal enemy_hit(enemy: Node, damage: float, position: Vector2)
signal damage_number_requested(amount: float, position: Vector2, is_critical: bool)
signal player_damaged(amount: float, position: Vector2)
signal player_died
signal shake_requested(amount: float)
signal projectile_fired(position: Vector2, direction: Vector2)
signal boss_spawned(boss: Node)
signal boss_health_changed(current: float, maximum: float)
signal boss_defeated

# --- Jogador / recursos ---
signal health_changed(current: float, maximum: float)
signal oil_changed(current: float, maximum: float)
signal oil_removed(amount: float)
signal dash_charges_changed(current: int, maximum: int)
signal beam_dried
signal light_well_entered(well: Node)
signal light_well_exited(well: Node)

# --- Feixe ---
signal beam_hit_enemy(enemy: Node, damage: float)

# --- Sala / run ---
signal wave_started(index: int, total: int)
signal enemies_remaining_changed(count: int)
signal room_cleared
signal run_state_changed(state: int)
signal message_requested(text: String, duration: float)

# --- Pontuacao (eixo Balatro) ---
signal ressonancia_changed(chain: int, multiplier: float)
signal score_changed(score: int)