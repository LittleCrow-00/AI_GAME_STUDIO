class_name StatSheet
extends RefCounted
## Agrega modificadores de atributos em um valor final, com cache.
##
## Ordem de resolucao (igual a todo ARPG que presta):
##   1. base
##   2. soma de todos os ADD
##   3. produto de todos os MULTIPLY
##
## Invalida o cache apenas quando um modificador entra ou sai. Consultar
## `get_stat` e O(1) depois do primeiro calculo.

var _base: Dictionary = {}
var _modifiers: Array[StatModifier] = []
var _cache: Dictionary = {}


func set_base(stat: StringName, value: float) -> void:
	_base[stat] = value
	_cache.erase(stat)


func add(modifier: StatModifier) -> void:
	if modifier == null or modifier.stat == StringName():
		return
	_modifiers.append(modifier)
	_cache.erase(modifier.stat)


func add_all(modifiers: Array) -> void:
	for modifier in modifiers:
		add(modifier as StatModifier)


func remove_source(source_id: StringName) -> void:
	var kept: Array[StatModifier] = []
	for modifier in _modifiers:
		if modifier.get_meta("source_id", StringName()) != source_id:
			kept.append(modifier)
	if kept.size() != _modifiers.size():
		_modifiers = kept
		_cache.clear()


func tag_source(modifier: StatModifier, source_id: StringName) -> StatModifier:
	modifier.set_meta("source_id", source_id)
	return modifier


func get_stat(stat: StringName) -> float:
	if _cache.has(stat):
		return _cache[stat] as float
	var value: float = _base.get(stat, 0.0)
	var multiplier := 1.0
	for modifier in _modifiers:
		if modifier.stat != stat:
			continue
		if modifier.mode == StatModifier.Mode.MULTIPLY:
			multiplier *= modifier.value
		else:
			value += modifier.value
	value *= multiplier
	_cache[stat] = value
	return value