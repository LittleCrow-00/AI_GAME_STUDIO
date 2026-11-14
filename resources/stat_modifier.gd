class_name StatModifier
extends Resource
## Modificador de atributo. E o ladrilho de toda a sinergia de itens.
##
## Um item nunca contem logica propria para alterar um atributo: ele carrega
## uma lista de StatModifier. O StatSheet agrega todos e recalcula o valor final.

enum Mode {
	ADD, ## soma direta no valor base
	MULTIPLY, ## multiplica o acumulado (aplicado depois de todos os ADD)
}

@export var stat: StringName
@export var mode: Mode = Mode.ADD
@export var value: float = 0.0


func _init(p_stat: StringName = &"", p_mode: Mode = Mode.ADD, p_value: float = 0.0) -> void:
	stat = p_stat
	mode = p_mode
	value = p_value