class_name ItemData
extends Resource
## Item de run. E um arquivo .tres em res://data/items/.
##
## Regra de design (docs/design.md): todo item deve mudar UMA DECISAO do
## jogador, nao apenas um numero. Se o item so aumenta dano, ele nao entra.

enum Rarity { COMMON, UNCOMMON, RARE, CURSED }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity: Rarity = Rarity.COMMON
@export var tags: Array[StringName] = []
@export var modifiers: Array[StatModifier] = []
@export var starting_item: bool = false
@export var max_stacks: int = 1


func get_modifiers_for(stack: int) -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	for modifier in modifiers:
		var copy := modifier.duplicate() as StatModifier
		if copy.mode == StatModifier.Mode.ADD:
			copy.value *= float(stack)
		else:
			copy.value = pow(copy.value, float(stack))
		result.append(copy)
	return result