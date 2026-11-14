class_name DifficultyData
extends Resource
## Curva de dificuldade por andar.
##
## Antes os multiplicadores eram contas no `Arena` (`1 + 0.18 * sala`). Agora são
## dados: dá para calibrar sem tocar em lógica — e o teste só compara os números.

@export var id: StringName
@export var health_scale: float = 1.0
@export var damage_scale: float = 1.0
@export var speed_scale: float = 1.0
@export var budget_bonus: int = 0
@export var elite_chance: float = 0.0