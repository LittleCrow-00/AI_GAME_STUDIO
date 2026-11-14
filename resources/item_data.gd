class_name ItemData
extends Resource
## Item de run.
##
## Um item e dado + modificadores + (opcionalmente) um comportamento. Ele nunca
## contem logica: o `Inventory` le os modificadores e os comportamentos, e o
## `Player`/`Beam` executam. Adicionar item = criar um `.tres` + uma linha no
## `ItemDatabase`.
##
## Regra de design (docs/design.md): todo item deve mudar UMA DECISAO do
## jogador, nao apenas um numero. Item que so aumenta dano nao entra.

enum Rarity { COMMON, UNCOMMON, RARE, CURSED }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity: Rarity = Rarity.COMMON
@export var tags: Array[StringName] = []
@export var modifiers: Array[StatModifier] = []
@export var max_stacks: int = 3
@export var starting_item: bool = false
@export var heal_on_pick: float = 0.0
@export var oil_on_pick: float = 0.0

## Comportamentos suportados por `Inventory.rebuild()`:
##   &"refraction"  → value = feixes extras
##   &"oil_on_hit"  → value = óleo por acerto
##   &"nova"        → value = dano, value_2 = raio
##   &"pierce"      → value > 0 ignora paredes
@export var behavior_id: StringName = &""
@export var behavior_value: float = 0.0
@export var behavior_value_2: float = 0.0


func modifiers_for(stacks: int) -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	var safe_stacks := maxi(1, stacks)
	for modifier in modifiers:
		var copy := modifier.duplicate() as StatModifier
		if copy.mode == StatModifier.Mode.ADD:
			copy.value *= float(safe_stacks)
		else:
			copy.value = pow(copy.value, float(safe_stacks))
		result.append(copy)
	return result