class_name BoonData
extends Resource
## Oferenda do Santuário.
##
## Uma oferenda e um conjunto de `StatModifier`. Ela nao contem logica: o
## `Player` aplica os modificadores no `StatSheet` e recalcula. E o mesmo
## mecanismo que os itens de run usarao na Fase 4.

enum Rarity { COMMON, UNCOMMON, RARE }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity: Rarity = Rarity.COMMON
@export var modifiers: Array[StatModifier] = []
@export var tags: Array[StringName] = []
@export var heal_on_pick: float = 0.0
@export var oil_on_pick: float = 0.0