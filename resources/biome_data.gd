class_name BiomeData
extends Resource
## Paleta de um bioma. A arena lê daqui em vez de decidir cor por `match`.

@export var id: StringName
@export var display_name: String
@export var base_color: Color = Color(0.030, 0.055, 0.068)
@export var tile_color: Color = Color(0.052, 0.090, 0.104)
@export var puddle_color: Color = Color(0.10, 0.20, 0.24)
@export var wall_color: Color = Color(0.020, 0.032, 0.040)
@export var edge_color: Color = Color(0.16, 0.27, 0.31)
@export var rim_color: Color = Color(0.30, 0.44, 0.48)