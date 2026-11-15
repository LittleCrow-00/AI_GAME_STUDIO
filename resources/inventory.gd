class_name Inventory
extends RefCounted
## Inventário de itens da run.
##
## Responsável por três coisas, e só por elas:
##   1. Guardar itens e stacks.
##   2. Transformar itens em modificadores de atributo.
##   3. Reconhecer SINERGIAS COMPOSTAS (combos de tags) e virar modificadores
##      e comportamentos.
##
## Nenhuma sinergia tem `if item == X` no Player. Tudo sai daqui como dado.

const TAG_LENTE := &"lente"
const TAG_OLEO := &"oleo"
const TAG_CORPO := &"corpo"
const TAG_RESSONANCIA := &"resonancia"
const TAG_MALDICAO := &"maldicao"

const SYNERGY_ESTADIO := &"luz_de_estadio"
const SYNERGY_CERA := &"cera_viva"
const SYNERGY_CASCO := &"casco"
const SYNERGY_BRASA := &"brasa_viva"

## Origem única usada pelo StatSheet para poder limpar tudo de uma vez.
const SOURCE := &"items"
const SYNERGY_SOURCE := &"synergies"

var _items: Array[ItemData] = []
var _stacks: Dictionary = {}
var _synergies: Array[StringName] = []


func add(item: ItemData) -> bool:
	if item == null:
		return false
	var current: int = _stacks.get(item.id, 0)
	if current >= item.max_stacks:
		return false
	_stacks[item.id] = current + 1
	if not _items.has(item):
		_items.append(item)
	SignalBus.item_collected.emit(item)
	return true


func has(item_id: StringName) -> bool:
	return _stacks.get(item_id, 0) > 0


func stacks_of(item_id: StringName) -> int:
	return int(_stacks.get(item_id, 0))


func count() -> int:
	var total := 0
	for item in _items:
		total += stacks_of(item.id)
	return total


func unique_count() -> int:
	return _items.size()


func item_list() -> Array[ItemData]:
	return _items.duplicate()


func stacks_map() -> Dictionary:
	return _stacks.duplicate()


func _tag_count(tag: StringName) -> int:
	var total := 0
	for item in _items:
		if item.tags.has(tag):
			total += 1
	return total


## Reconstrói tudo o que o inventário afeta.
##
## Retorna os modificadores (já com sinergias), os comportamentos agregados e a
## lista de sinergias ativas. O Player aplica; o inventário não conhece Player.
func rebuild() -> Dictionary:
	var modifiers: Array[StatModifier] = []

	for item in _items:
		var stacks := stacks_of(item.id)
		for modifier in item.modifiers_for(stacks):
			var copy := modifier.duplicate() as StatModifier
			copy.set_meta("source_id", SOURCE)
			modifiers.append(copy)

	var refraction := 0
	var oil_on_hit := 0.0
	var nova_damage := 0.0
	var nova_radius := 0.0
	var pierce := false

	for item in _items:
		var stacks := stacks_of(item.id)
		if item.behavior_id == &"":
			continue
		match item.behavior_id:
			&"refraction":
				refraction += int(item.behavior_value) * stacks
			&"oil_on_hit":
				oil_on_hit += item.behavior_value * float(stacks)
			&"nova":
				nova_damage = maxf(nova_damage, item.behavior_value * float(stacks))
				nova_radius = maxf(nova_radius, item.behavior_value_2 * float(stacks))
			&"pierce":
				if item.behavior_value > 0.0:
					pierce = true

	var synergies: Array[StringName] = []
	var oil_on_kill_bonus := 0.0

	if _tag_count(TAG_LENTE) >= 2 and refraction > 0:
		synergies.append(SYNERGY_ESTADIO)
		modifiers.append(_modifier(&"beam_damage", StatModifier.Mode.MULTIPLY, 1.1, SYNERGY_SOURCE))
		modifiers.append(_modifier(&"beam_range", StatModifier.Mode.MULTIPLY, 1.1, SYNERGY_SOURCE))

	if _tag_count(TAG_OLEO) >= 2 and oil_on_hit > 0.0:
		synergies.append(SYNERGY_CERA)
		oil_on_kill_bonus += 1.0

	if _tag_count(TAG_CORPO) >= 3:
		synergies.append(SYNERGY_CASCO)
		modifiers.append(_modifier(&"dash_charges_max", StatModifier.Mode.ADD, 1.0, SYNERGY_SOURCE))

	if _tag_count(TAG_RESSONANCIA) >= 2 and nova_damage > 0.0:
		synergies.append(SYNERGY_BRASA)
		nova_damage *= 1.5

	return {
		"modifiers": modifiers,
		"refraction": refraction,
		"oil_on_hit": oil_on_hit,
		"oil_on_kill_bonus": oil_on_kill_bonus,
		"nova_damage": nova_damage,
		"nova_radius": nova_radius,
		"pierce": pierce,
		"synergies": synergies,
	}

	if synergies != _synergies:
		_synergies = synergies
		SignalBus.synergy_changed.emit(synergies)


func _modifier(
	stat: StringName,
	mode: StatModifier.Mode,
	value: float,
	source: StringName,
) -> StatModifier:
	var modifier := StatModifier.new(stat, mode, value)
	modifier.set_meta("source_id", source)
	return modifier