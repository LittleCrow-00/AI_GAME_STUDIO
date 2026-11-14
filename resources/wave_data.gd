class_name WaveData
extends Resource
## Definicao de uma onda de inimigos, usada pelo SpawnDirector.

@export var enemies: Array[EnemyData] = []
@export var spawn_budget: int = 4
@export var spawn_interval: float = 0.35
@export var delay_before_next_wave: float = 1.2