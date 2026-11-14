class_name ThresholdData
extends Resource
## Recompensa de limiar da Ressonância.
##
## A cadeia sobe a cada acerto e cai se você parar de acertar. Cada limiar
## devolve algo à relação com a luz (óleo, alcance, estouro) — nunca dano puro,
## porque dano vem de itens (ver docs/design.md).
##
## Nada aqui tem lógica: o `Ressonancia` detecta a passagem, o `Player` aplica.

@export var id: StringName
@export var display_name: String
@export var description: String
@export var at_chain: int = 10

## 0 = instantâneo (só o gatilho de óleo/explosão).
@export var duration: float = 0.0
@export var modifiers: Array[StatModifier] = []

@export var oil_on_trigger: float = 0.0
@export var nova_on_trigger: bool = false
@export var nova_damage: float = 0.0
@export var nova_radius: float = 0.0


func modifiers_for() -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	for modifier in modifiers:
		var copy := modifier.duplicate() as StatModifier
		if copy != null:
			result.append(copy)
	return result