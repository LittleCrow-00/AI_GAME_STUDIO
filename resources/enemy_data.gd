class_name EnemyData
extends Resource
## Template de inimigo. O SpawnDirector instancia a cena e aplica os valores.

@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
@export var health: float = 30.0
@export var move_speed: float = 70.0
@export var contact_damage: float = 10.0
@export var oil_drop: float = 6.0
@export var cera_drop: int = 1
@export var body_color: Color = Color(0.34, 0.88, 0.85)
@export var cost: int = 1